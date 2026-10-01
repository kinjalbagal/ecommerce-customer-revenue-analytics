import pandas as pd
import plotly.graph_objects as go
import streamlit as st

import data
from theme import BLUE, GREY, LIGHT_BLUE, ORANGE, pct, show, usd


def render() -> None:
    st.title("Customer & Retention")
    st.caption("Customers are users with at least one valid order. Cohorts are defined by the month of the first valid order.")

    cohort_heatmap()
    rfm_segments()

    left, right = st.columns(2)
    with left:
        revenue_concentration()
    with right:
        repeat_behavior()


def cohort_heatmap() -> None:
    st.subheader("Cohort retention")
    cohorts = data.cohort_retention()
    controls = st.columns(2)
    cohort_count = controls[0].slider("Most recent cohorts to show", 6, 48, 24)
    max_offset = controls[1].slider("Months since first order", 3, 24, 12)

    latest = cohorts["cohort_month"].max()
    recent = cohorts[
        (cohorts["cohort_month"] > latest - pd.DateOffset(months=cohort_count))
        & cohorts["months_since_first_order"].between(1, max_offset)
    ]
    matrix = recent.pivot(index="cohort_month", columns="months_since_first_order", values="retention_rate")
    show_labels = cohort_count <= 24 and max_offset <= 12
    fig = go.Figure(go.Heatmap(
        z=matrix.values * 100, x=matrix.columns, y=matrix.index.strftime("%Y-%m"),
        colorscale="Blues", colorbar=dict(title="Retention (%)"), hoverongaps=False,
        text=[["" if pd.isna(value) else f"{value * 100:.1f}" for value in row] for row in matrix.values],
        texttemplate="%{text}" if show_labels else None,
        hovertemplate="Cohort %{y}<br>Month %{x}<br>Retention %{z:.1f}%<extra></extra>",
    ))
    fig.update_xaxes(title_text="Months since first order", dtick=1)
    fig.update_yaxes(title_text="First-order cohort", autorange="reversed", type="category")
    show(fig, height=max(360, 22 * cohort_count + 120))
    st.caption(
        "Share of each cohort placing a valid order in the month. Month 0 is 100% by definition and is left out. "
        "Recent cohorts are raised by the concentration of orders near the end of the data."
    )


def rfm_segments() -> None:
    st.subheader("RFM segments")
    rfm = data.customer_rfm()
    sources = st.multiselect("Acquisition source", sorted(rfm["acquisition_source"].unique()), placeholder="All sources")
    if sources:
        rfm = rfm[rfm["acquisition_source"].isin(sources)]

    segments = rfm.groupby("rfm_segment").agg(
        customers=("user_id", "count"),
        revenue=("monetary", "sum"),
        orders=("frequency", "sum"),
        median_recency_days=("recency_days", "median"),
    )
    segments["share_of_customers"] = segments["customers"] / segments["customers"].sum()
    segments["share_of_revenue"] = segments["revenue"] / segments["revenue"].sum()
    segments["average_order_value"] = segments["revenue"] / segments["orders"]
    segments["avg_orders"] = segments["orders"] / segments["customers"]
    segments = segments.sort_values("share_of_revenue")

    fig = go.Figure()
    for column, label, color in [("share_of_customers", "Share of customers", LIGHT_BLUE), ("share_of_revenue", "Share of revenue", BLUE)]:
        fig.add_bar(y=segments.index, x=segments[column], name=label, orientation="h", marker_color=color,
                    text=[pct(value) for value in segments[column]], textposition="outside", cliponaxis=False)
    fig.update_layout(barmode="group")
    fig.update_xaxes(title_text="Share of total", tickformat=".0%", range=[0, segments[["share_of_customers", "share_of_revenue"]].max().max() * 1.2])
    show(fig, height=460)
    table = segments.sort_values("revenue", ascending=False)[
        ["customers", "revenue", "average_order_value", "avg_orders", "median_recency_days"]
    ]
    table.index.name = "Segment"
    table.columns = ["Customers", "Revenue", "AOV", "Avg orders", "Median days since last order"]
    st.dataframe(
        table.style.format({
            "Customers": "{:,.0f}", "Revenue": "${:,.0f}", "AOV": "${:,.2f}",
            "Avg orders": "{:.2f}", "Median days since last order": "{:,.0f}",
        }),
        width="stretch",
    )
    st.caption(
        "Recency and monetary value are scored by quintile; frequency uses the order count. "
        "Segments describe past value. The Revenue Opportunity page shows that past spend did not predict reordering."
    )


def revenue_concentration() -> None:
    st.subheader("Revenue concentration")
    curve = data.revenue_concentration()
    marked = curve[curve["customer_percentile"].isin([1, 5, 10, 20])]
    fig = go.Figure()
    fig.add_scatter(x=[0] + curve["customer_percentile"].tolist(), y=[0] + curve["cumulative_share_of_revenue"].tolist(),
                    mode="lines", name="Observed", line=dict(color=BLUE, width=3))
    fig.add_scatter(x=[0, 100], y=[0, 1], mode="lines", name="Equal spend per customer", line=dict(color=GREY, dash="dash"))
    fig.add_scatter(x=marked["customer_percentile"], y=marked["cumulative_share_of_revenue"], mode="markers+text", showlegend=False,
                    marker=dict(color=ORANGE, size=9),
                    text=[f"Top {percentile}%: {pct(share)}" if percentile >= 10 else "" for percentile, share in zip(marked["customer_percentile"], marked["cumulative_share_of_revenue"])],
                    textposition="bottom right")
    fig.update_xaxes(title_text="Customers ranked by lifetime revenue (cumulative %)", ticksuffix="%", range=[0, 101], dtick=20)
    fig.update_yaxes(title_text="Cumulative share of revenue", tickformat=".0%")
    show(fig)
    shares = marked.set_index("customer_percentile")["cumulative_share_of_revenue"]
    st.caption("Share of revenue from the top customers: " + ", ".join(f"top {percentile}% {pct(share)}" for percentile, share in shares.items()) + ".")


def repeat_behavior() -> None:
    st.subheader("Orders per customer")
    rfm = data.customer_rfm()
    by_orders = rfm.groupby("frequency").agg(customers=("user_id", "count"), revenue=("monetary", "sum"))
    by_orders["share_of_customers"] = by_orders["customers"] / by_orders["customers"].sum()
    by_orders["share_of_revenue"] = by_orders["revenue"] / by_orders["revenue"].sum()
    labels = [f"{count} order" if count == 1 else f"{count} orders" for count in by_orders.index]
    fig = go.Figure()
    for column, label, color in [("share_of_customers", "Share of customers", LIGHT_BLUE), ("share_of_revenue", "Share of revenue", BLUE)]:
        fig.add_bar(x=labels, y=by_orders[column], name=label, marker_color=color,
                    text=[pct(value) for value in by_orders[column]], textposition="outside")
    fig.update_layout(barmode="group")
    fig.update_xaxes(title_text="Valid orders per customer")
    fig.update_yaxes(title_text="Share of total", tickformat=".0%", range=[0, 0.85])
    show(fig)
    repeat_rate = 1 - by_orders.loc[1, "share_of_customers"]
    st.caption(f"Repeat purchase rate: {pct(repeat_rate)} of customers have two or more valid orders ({usd(by_orders.loc[2:, 'revenue'].sum())} of revenue).")
