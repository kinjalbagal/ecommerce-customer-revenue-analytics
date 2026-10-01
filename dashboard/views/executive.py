import plotly.graph_objects as go
import streamlit as st

import data
from theme import BLUE, LIGHT_BLUE, ORANGE, pct, show, usd


def render() -> None:
    st.title("Executive Overview")
    st.caption(
        "Revenue counts orders with status Complete, Shipped or Processing. "
        "Cancelled and Returned orders are excluded."
    )

    orders = data.orders()
    first_date, last_date = orders["order_date"].min().date(), orders["order_date"].max().date()
    selected = st.sidebar.date_input(
        "Order date range", value=(first_date, last_date), min_value=first_date, max_value=last_date
    )
    if len(selected) != 2:
        st.info("Select an end date to continue.")
        return
    start, end = selected
    in_period = orders[orders["order_date"].dt.date.between(start, end)]
    valid = in_period[in_period["is_valid_order"]]
    if valid.empty:
        st.warning("No valid orders in the selected period.")
        return

    revenue = valid["net_revenue"].sum()
    order_count = len(valid)
    # A customer counts as repeat once they have placed a second valid order by the end of the period.
    highest_order_number = valid.groupby("user_id")["customer_order_number"].max()
    customers = len(highest_order_number)

    tiles = st.columns(5)
    tiles[0].metric("Revenue", usd(revenue))
    tiles[1].metric("Orders", f"{order_count:,}")
    tiles[2].metric("Customers", f"{customers:,}")
    tiles[3].metric("Average order value", f"${revenue / order_count:,.2f}")
    tiles[4].metric(
        "Repeat purchase rate",
        pct((highest_order_number >= 2).mean()),
        help="Share of customers in the period who had placed two or more valid orders by their latest order in it.",
    )

    st.subheader("Monthly revenue: new and returning customers")
    monthly = valid.pivot_table(index="order_month", columns="customer_type", values="net_revenue", aggfunc="sum").fillna(0)
    fig = go.Figure()
    for customer_type, color in [("New", LIGHT_BLUE), ("Returning", BLUE)]:
        if customer_type in monthly:
            fig.add_bar(x=monthly.index, y=monthly[customer_type], name=f"{customer_type} customers", marker_color=color)
    fig.update_layout(barmode="stack")
    fig.update_xaxes(title_text="Order month")
    fig.update_yaxes(title_text="Revenue (USD)", tickprefix="$", tickformat=",.0f")
    show(fig)

    left, right = st.columns(2)
    with left:
        st.subheader("Gross order value by status")
        by_status = in_period.groupby("status")["gross_order_value"].sum().sort_values()
        lost = by_status.index.isin(["Cancelled", "Returned"])
        fig = go.Figure(go.Bar(
            x=by_status.values, y=by_status.index, orientation="h",
            marker_color=[ORANGE if is_lost else BLUE for is_lost in lost],
            text=[f"{usd(value)} ({pct(value / by_status.sum())})" for value in by_status.values],
            textposition="outside", cliponaxis=False,
        ))
        fig.update_xaxes(title_text="Gross order value (USD)", tickprefix="$", tickformat=",.0f",
                         range=[0, by_status.max() * 1.45])
        show(fig, height=340)
        st.caption(f"{pct(by_status[lost].sum() / by_status.sum())} of gross order value in the period was cancelled or returned.")
    with right:
        st.subheader("Returning-customer share of revenue")
        share = (monthly["Returning"] / monthly.sum(axis=1)) if "Returning" in monthly else monthly.sum(axis=1) * 0
        fig = go.Figure(go.Scatter(x=share.index, y=share.values, mode="lines", line=dict(color=BLUE, width=2.5)))
        fig.update_xaxes(title_text="Order month")
        fig.update_yaxes(title_text="Share of revenue", tickformat=".0%", rangemode="tozero")
        show(fig, height=340)

    st.caption(
        "Order volume in September 2026 is well above earlier months. This is a property of the synthetic "
        "source data and is not interpreted as a commercial event."
    )
