import plotly.graph_objects as go
import streamlit as st

import data
from theme import BLUE, LIGHT_BLUE, ORANGE, pct, show, usd

WINDOWS = {
    "excluding_final_month": "Adjusted: outcome window ends 2026-08-31 (excludes the September 2026 spike)",
    "original": "Original: outcome window ends 2026-09-30",
}
SCENARIO_COLORS = {"Conservative": LIGHT_BLUE, "Base": BLUE, "Optimistic": ORANGE}


def render() -> None:
    st.title("Revenue Opportunity")
    st.markdown(
        "**Opportunity:** encourage one-time buyers to place a second order. "
        "Values marked *observed* are calculated from the data. Values marked *estimate* depend on an assumed "
        "lift and are not realized revenue."
    )

    st.sidebar.subheader("Opportunity settings")
    window = st.sidebar.radio("Backtest window", list(WINDOWS), format_func=lambda key: WINDOWS[key].split(":")[0])
    st.sidebar.caption(WINDOWS[window])

    scenarios = data.opportunity_scenarios()
    scenarios = scenarios[scenarios["backtest_window"] == window]
    backtest = data.reorder_backtest()
    backtest = backtest[backtest["backtest_window"] == window]

    # One row per recency band; the observed inputs repeat on every scenario row.
    bands = scenarios[scenarios["scenario"] == "Base"].sort_values("recency_band_order")
    default_lifts = scenarios.groupby("scenario")["relative_lift_in_reorder_rate"].first()

    st.sidebar.markdown("**Assumed relative lift in reorder rate**")
    lifts = {
        name: st.sidebar.slider(name, 0, 50, int(round(default_lifts[name] * 100)), format="%d%%") / 100
        for name in ["Conservative", "Base", "Optimistic"]
    }
    chosen_bands = st.sidebar.multiselect("Days since only order", bands["recency_band"].tolist(), placeholder="All recency bands")
    targeted = bands[bands["recency_band"].isin(chosen_bands)] if chosen_bands else bands

    # The mart already holds customers and revenue per scenario. Dividing by the scenario's
    # lift gives the value of a 100% lift, which is then scaled by the lift chosen here.
    eligible = targeted["eligible_customers"].sum()
    baseline_reorders = (targeted["estimated_incremental_customers"] / targeted["relative_lift_in_reorder_rate"]).sum()
    revenue_per_unit_lift = (targeted["estimated_incremental_revenue"] / targeted["relative_lift_in_reorder_rate"]).sum()
    expected_order_value = targeted["expected_order_value"].iloc[0]

    st.subheader("Observed inputs")
    tiles = st.columns(3)
    tiles[0].metric("Eligible one-time buyers", f"{eligible:,}", help="Observed. Customers with exactly one valid order.")
    tiles[1].metric("Baseline 12-month reorder rate", pct(baseline_reorders / eligible),
                    help="Observed in the backtest for customers with one prior order, weighted by the eligible population.")
    tiles[2].metric("Expected order value", f"${expected_order_value:,.2f}",
                    help="Observed. Average value of orders placed by one-order customers in the backtest window.")

    left, right = st.columns(2)
    with left:
        st.markdown("**Observed reorder rate by recency and prior spend**")
        by_band = backtest.groupby(["recency_band", "prior_spend_tier"]).agg(
            order=("recency_band_order", "min"), customers=("customers", "sum"), reordered=("customers_who_reordered", "sum")
        ).reset_index()
        by_band["rate"] = by_band["reordered"] / by_band["customers"]
        band_order = by_band.groupby("recency_band")["order"].min().sort_values().index.tolist()
        fig = go.Figure()
        for tier, color in [("Top 40% by prior spend", BLUE), ("Bottom 60% by prior spend", LIGHT_BLUE)]:
            subset = by_band[by_band["prior_spend_tier"] == tier].set_index("recency_band").loc[band_order]
            fig.add_bar(x=band_order, y=subset["rate"], name=tier, marker_color=color,
                        text=[pct(value) for value in subset["rate"]], textposition="outside", textfont=dict(size=10))
        fig.update_layout(barmode="group", uniformtext=dict(minsize=10, mode="show"))
        fig.update_xaxes(title_text="Days since last order at the snapshot date")
        fig.update_yaxes(title_text="Share reordering in 12 months", tickformat=".0%", range=[0, 0.3])
        show(fig, height=400)
        st.caption("Recency predicts a reorder. Customers with high and low past spend reorder at nearly the same rate.")
    with right:
        st.markdown("**Eligible one-time buyers and their observed baseline**")
        short_labels = bands["recency_band"].str.replace(" days", "")
        fig = go.Figure()
        fig.add_bar(x=short_labels, y=bands["eligible_customers"], name="Eligible customers",
                    marker_color=[BLUE if band in targeted["recency_band"].values else "#D0D0D0" for band in bands["recency_band"]],
                    text=[f"{value:,}" for value in bands["eligible_customers"]], textposition="inside", insidetextanchor="start")
        fig.add_scatter(x=short_labels, y=bands["baseline_reorder_rate"], name="Baseline reorder rate",
                        mode="lines+markers", line=dict(color=ORANGE, width=2.5), yaxis="y2")
        fig.update_layout(
            yaxis=dict(title="Eligible customers", tickformat=",.0f", range=[0, bands["eligible_customers"].max() * 1.2]),
            yaxis2=dict(title="Baseline reorder rate", overlaying="y", side="right", tickformat=".0%", range=[0, 0.3], showgrid=False),
        )
        fig.update_xaxes(title_text="Days since only order", tickangle=0)
        show(fig, height=400)
        st.caption("Blue bars are included in the estimate; use the sidebar to restrict the target population.")

    st.subheader("Scenario estimates")
    st.markdown(
        "Estimated incremental revenue over 12 months = eligible customers × baseline reorder rate × "
        "assumed relative lift × expected order value. One additional order per reactivated customer is assumed."
    )
    estimates = {name: revenue_per_unit_lift * lift for name, lift in lifts.items()}
    tiles = st.columns(3)
    for tile, (name, estimate) in zip(tiles, estimates.items()):
        tile.metric(f"{name} estimate (+{lifts[name]:.0%} lift)", usd(estimate),
                    help=f"Estimate. About {baseline_reorders * lifts[name]:,.0f} additional customers reordering.")

    fig = go.Figure(go.Bar(
        x=list(estimates), y=list(estimates.values()), marker_color=[SCENARIO_COLORS[name] for name in estimates],
        text=[usd(value) for value in estimates.values()], textposition="outside",
    ))
    fig.update_xaxes(title_text="Scenario")
    fig.update_yaxes(title_text="Estimated incremental revenue, 12 months (USD)", tickprefix="$", tickformat=",.0f",
                     range=[0, max(max(estimates.values()) * 1.2, 1)])
    show(fig, height=380)
    st.caption("Estimates exclude program costs, any discount offered, and the value of later orders. The lift is an assumption and has not been tested.")

    st.subheader("Recommended action")
    st.markdown(
        "- Run a second-purchase program for one-time buyers, selected by how recently they bought and not by how much they spent.\n"
        "- Start with customers whose only order was in the last 365 days, and contact new buyers within 90 days of their first order.\n"
        "- Hold out a control group so the lift is measured before the program is scaled."
    )
