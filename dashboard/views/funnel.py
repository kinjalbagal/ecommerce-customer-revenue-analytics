import plotly.graph_objects as go
import streamlit as st

import data
from theme import BLUE, LIGHT_BLUE, ORANGE, pct, show

STAGES = [("product_view_sessions", "Product view"), ("cart_sessions", "Add to cart"), ("purchase_sessions", "Purchase")]
BREAKDOWNS = {"Traffic source": "traffic_source", "Browser": "browser", "Department": "department", "Category": "category"}


def render() -> None:
    st.title("Funnel & Product Performance")
    funnel_section()
    st.divider()
    category_section()


def funnel_section() -> None:
    funnel = data.funnel_summary()
    months = sorted(funnel["session_month"].unique())
    st.sidebar.subheader("Funnel filters")
    # Default to the trailing 12 months: all-time conversion is pulled down by anonymous
    # sessions, which are constant over time while purchasing sessions grow.
    start, end = st.sidebar.select_slider(
        "Session month", options=months, value=(months[-12], months[-1]), format_func=lambda month: f"{month:%b %Y}"
    )
    selections = {
        column: st.sidebar.multiselect(label, sorted(funnel[column].unique()), placeholder=f"All {label.lower()}s")
        for label, column in list(BREAKDOWNS.items())[:3]
    }
    filtered = funnel[funnel["session_month"].between(start, end)]
    for column, chosen in selections.items():
        if chosen:
            filtered = filtered[filtered[column].isin(chosen)]
    if filtered.empty:
        st.warning("No sessions match the selected filters.")
        return

    totals = filtered[["sessions", "cart_sessions", "purchase_sessions", "product_view_sessions"]].sum()
    tiles = st.columns(4)
    tiles[0].metric("Sessions", f"{totals['sessions']:,}")
    tiles[1].metric("View to cart", pct(totals["cart_sessions"] / totals["product_view_sessions"]))
    tiles[2].metric("Cart to purchase", pct(totals["purchase_sessions"] / totals["cart_sessions"]))
    tiles[3].metric("Overall conversion", pct(totals["purchase_sessions"] / totals["sessions"]))

    left, right = st.columns(2)
    with left:
        st.subheader("Session funnel")
        counts = [totals[column] for column, _ in STAGES]
        labels = []
        for position, count in enumerate(counts):
            label = f"{count:,} sessions<br>{pct(count / counts[0])} of sessions"
            if position > 0:
                label += f"<br>{pct(1 - count / counts[position - 1])} drop-off"
            labels.append(label)
        fig = go.Figure(go.Bar(x=[name for _, name in STAGES], y=counts, marker_color=[LIGHT_BLUE, BLUE, ORANGE],
                               text=labels, textposition="outside", cliponaxis=False))
        fig.update_xaxes(title_text="Funnel stage")
        fig.update_yaxes(title_text="Sessions", tickformat=",.0f", range=[0, counts[0] * 1.3])
        show(fig, height=440)
    with right:
        st.subheader("Conversion by segment")
        label = st.selectbox("Break down by", list(BREAKDOWNS))
        by_segment = filtered.groupby(BREAKDOWNS[label])[["sessions", "purchase_sessions"]].sum()
        by_segment["conversion"] = by_segment["purchase_sessions"] / by_segment["sessions"]
        by_segment = by_segment.sort_values("conversion")
        fig = go.Figure(go.Bar(x=by_segment["conversion"], y=by_segment.index, orientation="h", marker_color=BLUE,
                               text=[pct(value) for value in by_segment["conversion"]], textposition="outside", cliponaxis=False))
        fig.update_xaxes(title_text="Session-to-purchase conversion", tickformat=".0%", range=[0, max(by_segment["conversion"].max() * 1.2, 0.05)])
        show(fig, height=max(360, 24 * len(by_segment) + 120))

    st.caption(
        "Grain is the session. A stage counts only if it follows the previous one. One purchase session corresponds "
        "to one order item, so these rates do not reconcile to order counts. Sessions without a user never purchase "
        "and are constant over time, so conversion over long periods is lower purely through session mix."
    )


def category_section() -> None:
    st.subheader("Category performance")
    categories = data.category_metrics()
    departments = st.multiselect("Department", sorted(categories["department"].unique()), placeholder="All departments")
    if departments:
        categories = categories[categories["department"].isin(departments)]

    summed = categories.groupby("category")[
        ["revenue", "units_sold", "units_ordered", "units_cancelled", "units_returned", "gross_margin", "gross_item_value"]
    ].sum()
    summed["share_of_revenue"] = summed["revenue"] / summed["revenue"].sum()
    summed["share_of_units"] = summed["units_sold"] / summed["units_sold"].sum()
    summed["average_unit_revenue"] = summed["revenue"] / summed["units_sold"]
    summed["cancellation_rate"] = summed["units_cancelled"] / summed["units_ordered"]
    summed["return_rate"] = summed["units_returned"] / summed["units_ordered"]
    summed["gross_margin_rate"] = summed["gross_margin"] / summed["revenue"]
    summed["lost_value"] = summed["gross_item_value"] - summed["revenue"]
    summed = summed.sort_values("revenue", ascending=False)

    left, right = st.columns([2, 3])
    with left:
        limit = max(summed["share_of_units"].max(), summed["share_of_revenue"].max()) * 1.1
        fig = go.Figure()
        fig.add_scatter(x=[0, limit], y=[0, limit], mode="lines", name="Revenue share equals unit share", line=dict(color="#D0D0D0", dash="dash"))
        fig.add_scatter(x=summed["share_of_units"], y=summed["share_of_revenue"], mode="markers", name="Category",
                        marker=dict(color=BLUE, size=10), text=summed.index,
                        hovertemplate="%{text}<br>Units %{x:.1%}<br>Revenue %{y:.1%}<extra></extra>")
        fig.update_xaxes(title_text="Share of units sold", tickformat=".0%", range=[0, limit])
        fig.update_yaxes(title_text="Share of revenue", tickformat=".0%", range=[0, limit])
        show(fig, height=460)
        st.caption("Categories above the line earn more revenue than their unit volume; hover for names.")
    with right:
        table = summed[["revenue", "average_unit_revenue", "gross_margin_rate", "cancellation_rate", "return_rate", "lost_value"]]
        table.index.name = "Category"
        table.columns = ["Revenue", "Per unit", "Margin", "Cancelled", "Returned", "Lost value"]
        st.dataframe(
            table.style.format({
                "Revenue": "${:,.0f}", "Per unit": "${:,.2f}", "Margin": "{:.1%}",
                "Cancelled": "{:.1%}", "Returned": "{:.1%}", "Lost value": "${:,.0f}",
            }),
            height=495,
            width="stretch",
        )
        st.caption("Cancelled and Returned are shares of units ordered. Lost value is the value of cancelled and returned units.")
