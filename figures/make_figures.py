"""Build the project's Plotly figures from the mart exports and analysis outputs.

Reads CSVs produced by scripts/export_marts.py and scripts/run_sql.py; no
transformation logic is re-implemented here. Writes a PNG to images/ and an HTML
file to figures/html/ for each figure.
"""
from pathlib import Path

import pandas as pd
import plotly.graph_objects as go

REPO_ROOT = Path(__file__).resolve().parents[1]
MARTS = REPO_ROOT / "data" / "marts"
OUTPUTS = REPO_ROOT / "analysis" / "outputs"
PNG_DIR = REPO_ROOT / "images"
HTML_DIR = REPO_ROOT / "figures" / "html"

BLUE = "#2F5D8A"
LIGHT_BLUE = "#9DB8D2"
ORANGE = "#D9822B"

# The opportunity analysis uses the backtest window that leaves out the final-month
# spike in orders; the original window is shown alongside it in the sensitivity figure.
PRIMARY_WINDOW = "excluding_final_month"
WINDOW_LABELS = {
    "original": "Original window (ends 2026-09-30)",
    "excluding_final_month": "Adjusted window (ends 2026-08-31)",
}
GREY = "#8C8C8C"
LIGHT_GREY = "#D0D0D0"


def save(fig: go.Figure, name: str, title: str, height: int = 520) -> None:
    fig.update_layout(
        title=dict(text=title, x=0.01, xanchor="left", font=dict(size=18)),
        template="simple_white",
        font=dict(family="Helvetica, Arial, sans-serif", size=13, color="#222222"),
        width=1000,
        height=height,
        margin=dict(l=80, r=40, t=90, b=70),
        legend=dict(orientation="h", yanchor="bottom", y=1.0, xanchor="right", x=1),
    )
    fig.write_image(PNG_DIR / f"{name}.png", scale=2)
    fig.write_html(HTML_DIR / f"{name}.html", include_plotlyjs="cdn", div_id=name)
    print(f"wrote {name}")


def monthly_revenue() -> None:
    monthly = pd.read_csv(MARTS / "mart_monthly_revenue.csv", parse_dates=["order_month"])
    latest = monthly.iloc[-12:]
    returning_share = latest["returning_customer_revenue"].sum() / latest["revenue"].sum()
    fig = go.Figure()
    fig.add_bar(x=monthly["order_month"], y=monthly["new_customer_revenue"], name="New customers", marker_color=LIGHT_BLUE)
    fig.add_bar(x=monthly["order_month"], y=monthly["returning_customer_revenue"], name="Returning customers", marker_color=BLUE)
    fig.update_layout(barmode="stack")
    fig.update_xaxes(title_text="Order month")
    fig.update_yaxes(title_text="Revenue (USD)", tickprefix="$", tickformat=",.0f")
    save(fig, "01_monthly_revenue_new_vs_returning",
         f"Revenue growth is driven by first-time orders; returning customers were {returning_share:.0%} of revenue in the last 12 months")


def revenue_leakage() -> None:
    status = pd.read_csv(OUTPUTS / "02_revenue_leakage_by_status.csv")
    status = status[status["period"] == "Trailing 12 months"].sort_values("gross_order_value")
    lost_share = status.loc[~status["counts_toward_revenue"], "share_of_gross_order_value"].sum()
    colors = [BLUE if kept else ORANGE for kept in status["counts_toward_revenue"]]
    fig = go.Figure(go.Bar(
        x=status["gross_order_value"], y=status["status"], orientation="h", marker_color=colors,
        text=[f"${v:,.0f} ({s:.1%})" for v, s in zip(status["gross_order_value"], status["share_of_gross_order_value"])],
        textposition="outside", cliponaxis=False,
    ))
    fig.update_xaxes(title_text="Gross order value, trailing 12 months (USD)", tickprefix="$", tickformat=",.0f",
                     range=[0, status["gross_order_value"].max() * 1.25])
    fig.update_yaxes(title_text="Order status")
    save(fig, "02_gross_order_value_by_status",
         f"Cancelled and returned orders remove {lost_share:.1%} of gross order value", height=420)


def orders_per_customer() -> None:
    orders = pd.read_csv(OUTPUTS / "05_orders_per_customer.csv")
    labels = orders["valid_orders"].astype(str) + orders["valid_orders"].map(lambda n: " order" if n == 1 else " orders")
    one_time = orders.loc[orders["valid_orders"] == 1].iloc[0]
    fig = go.Figure()
    fig.add_bar(x=labels, y=orders["share_of_customers"], name="Share of customers", marker_color=LIGHT_BLUE,
                text=[f"{v:.1%}" for v in orders["share_of_customers"]], textposition="outside")
    fig.add_bar(x=labels, y=orders["share_of_revenue"], name="Share of revenue", marker_color=BLUE,
                text=[f"{v:.1%}" for v in orders["share_of_revenue"]], textposition="outside")
    fig.update_layout(barmode="group")
    fig.update_xaxes(title_text="Valid orders per customer")
    fig.update_yaxes(title_text="Share of total", tickformat=".0%", range=[0, 0.8])
    save(fig, "03_orders_per_customer",
         f"{one_time['share_of_customers']:.0%} of customers bought once; the {1 - one_time['share_of_customers']:.0%} who returned generate {1 - one_time['share_of_revenue']:.0%} of revenue")


def cohort_heatmap() -> None:
    cohorts = pd.read_csv(MARTS / "mart_cohort_retention.csv", parse_dates=["cohort_month"])
    last_cohort = cohorts["cohort_month"].max()
    recent = cohorts[
        (cohorts["cohort_month"] > last_cohort - pd.DateOffset(months=24))
        & cohorts["months_since_first_order"].between(1, 12)
    ]
    matrix = recent.pivot(index="cohort_month", columns="months_since_first_order", values="retention_rate")
    fig = go.Figure(go.Heatmap(
        z=matrix.values * 100, x=matrix.columns, y=matrix.index.strftime("%Y-%m"),
        colorscale="Blues", colorbar=dict(title="Retention (%)"),
        text=[[("" if pd.isna(v) else f"{v * 100:.1f}") for v in row] for row in matrix.values],
        texttemplate="%{text}", textfont=dict(size=10), hoverongaps=False,
    ))
    fig.update_xaxes(title_text="Months since first order", dtick=1)
    fig.update_yaxes(title_text="First-order cohort", autorange="reversed")
    save(fig, "04_cohort_retention_heatmap",
         "Monthly retention stays in low single digits; newer cohorts return more often than older ones", height=760)


def cohort_repeat_rates() -> None:
    repeat = pd.read_csv(OUTPUTS / "08_cohort_repeat_within_12_months.csv")
    first, last = repeat.iloc[0], repeat.iloc[-1]
    fig = go.Figure()
    for column, label, color in [
        ("repeat_within_90_days", "Within 90 days", LIGHT_BLUE),
        ("repeat_within_180_days", "Within 180 days", BLUE),
        ("repeat_within_365_days", "Within 365 days", ORANGE),
    ]:
        fig.add_scatter(x=repeat["cohort_year"], y=repeat[column], name=label, mode="lines+markers", line=dict(color=color, width=2.5))
    fig.update_xaxes(title_text="Year of first order (customers with 365 days of follow-up)", dtick=1)
    fig.update_yaxes(title_text="Share placing a second order", tickformat=".0%", rangemode="tozero")
    save(fig, "05_second_order_rate_by_cohort",
         f"12-month second-order rate rose from {first['repeat_within_365_days']:.0%} ({int(first['cohort_year'])} cohort) to {last['repeat_within_365_days']:.0%} ({int(last['cohort_year'])} cohort)")


def rfm_segments() -> None:
    segments = pd.read_csv(OUTPUTS / "10_rfm_segments.csv").sort_values("share_of_revenue")
    fig = go.Figure()
    fig.add_bar(y=segments["rfm_segment"], x=segments["share_of_customers"], name="Share of customers", orientation="h", marker_color=LIGHT_BLUE,
                text=[f"{v:.1%}" for v in segments["share_of_customers"]], textposition="outside")
    fig.add_bar(y=segments["rfm_segment"], x=segments["share_of_revenue"], name="Share of revenue", orientation="h", marker_color=BLUE,
                text=[f"{v:.1%}" for v in segments["share_of_revenue"]], textposition="outside")
    fig.update_layout(barmode="group")
    fig.update_xaxes(title_text="Share of total", tickformat=".0%", range=[0, 0.32])
    fig.update_yaxes(title_text="")
    top_two = segments.sort_values("share_of_revenue", ascending=False).head(2)
    save(fig, "06_rfm_segments",
         f"{top_two.iloc[0]['rfm_segment']} and {top_two.iloc[1]['rfm_segment']} hold {top_two['share_of_revenue'].sum():.0%} of historical revenue from {top_two['share_of_customers'].sum():.0%} of customers",
         height=560)


def revenue_concentration() -> None:
    curve = pd.read_csv(MARTS / "mart_revenue_concentration.csv")
    points = pd.read_csv(OUTPUTS / "11_revenue_concentration.csv")
    top_20 = points.loc[points["top_percent"] == 20, "share_of_revenue"].iloc[0]
    fig = go.Figure()
    fig.add_scatter(x=[0] + curve["customer_percentile"].tolist(), y=[0] + curve["cumulative_share_of_revenue"].tolist(),
                    mode="lines", name="Observed", line=dict(color=BLUE, width=3))
    fig.add_scatter(x=[0, 100], y=[0, 1], mode="lines", name="Equal spend per customer", line=dict(color=GREY, dash="dash"))
    marked = points[points["top_percent"].isin([1, 5, 10, 20])]
    fig.add_scatter(x=marked["top_percent"], y=marked["share_of_revenue"], mode="markers+text", showlegend=False,
                    marker=dict(color=ORANGE, size=9),
                    text=[f"Top {p}%: {s:.1%}" for p, s in zip(marked["top_percent"], marked["share_of_revenue"])],
                    textposition="middle right")
    fig.update_xaxes(title_text="Customers ranked by lifetime revenue, highest first (cumulative %)", ticksuffix="%")
    fig.update_yaxes(title_text="Cumulative share of revenue", tickformat=".0%")
    save(fig, "07_revenue_concentration",
         f"Revenue is moderately concentrated: the top 20% of customers account for {top_20:.0%}, not 80%")


def funnel() -> None:
    stages = pd.read_csv(OUTPUTS / "13_funnel_overall.csv")
    stages = stages[stages["stage"] != "Session"]
    fig = go.Figure()
    for period, color in [("All time", LIGHT_BLUE), ("Trailing 12 months", BLUE)]:
        subset = stages[stages["period"] == period]
        fig.add_bar(x=subset["stage"], y=subset["conversion_from_session"], name=period, marker_color=color,
                    text=[f"{share:.1%}<br>{count:,} sessions" for share, count in zip(subset["conversion_from_session"], subset["entrants"])],
                    textposition="outside")
    fig.update_layout(barmode="group")
    all_time = stages[stages["period"] == "All time"].set_index("stage")
    fig.update_xaxes(title_text="Funnel stage")
    fig.update_yaxes(title_text="Share of sessions reaching the stage", tickformat=".0%", range=[0, 1.18])
    save(fig, "08_session_funnel",
         f"All-time, {all_time.loc['Add to cart', 'stage_drop_off_rate']:.0%} of sessions drop before cart and {all_time.loc['Purchase', 'stage_drop_off_rate']:.0%} of carts do not purchase")


def funnel_by_segment() -> None:
    segments = pd.read_csv(OUTPUTS / "14_funnel_by_segment.csv")
    segments = segments[segments["dimension"].isin(["Traffic source", "Browser"])]
    spread = segments["overall_conversion_rate"].max() - segments["overall_conversion_rate"].min()
    colors = [BLUE if d == "Traffic source" else ORANGE for d in segments["dimension"]]
    fig = go.Figure(go.Bar(
        x=segments["dimension"] + ": " + segments["segment"], y=segments["overall_conversion_rate"], marker_color=colors,
        text=[f"{v:.1%}" for v in segments["overall_conversion_rate"]], textposition="outside",
    ))
    fig.update_xaxes(title_text="Session segment (trailing 12 months)", tickangle=-35)
    fig.update_yaxes(title_text="Session-to-purchase conversion", tickformat=".0%", range=[0, 0.7])
    save(fig, "09_funnel_conversion_by_segment",
         f"Conversion is nearly identical across traffic sources and browsers (range {spread * 100:.1f} points)")


def category_mix() -> None:
    categories = pd.read_csv(OUTPUTS / "17_category_performance.csv")
    top = categories.iloc[0]
    limit = max(categories["share_of_units"].max(), categories["share_of_revenue"].max()) * 1.1
    labeled = categories[(categories["share_of_revenue"] - categories["share_of_units"]).abs() > 0.02]
    fig = go.Figure()
    fig.add_scatter(x=[0, limit], y=[0, limit], mode="lines", line=dict(color=LIGHT_GREY, dash="dash"), name="Revenue share equals unit share")
    fig.add_scatter(x=categories["share_of_units"], y=categories["share_of_revenue"], mode="markers", marker=dict(color=BLUE, size=10),
                    name="Category", text=categories["category"], hovertemplate="%{text}<br>Units %{x:.1%}<br>Revenue %{y:.1%}<extra></extra>")
    fig.add_scatter(x=labeled["share_of_units"], y=labeled["share_of_revenue"], mode="text", text=labeled["category"],
                    textposition="top center", showlegend=False, textfont=dict(size=11))
    fig.update_xaxes(title_text="Share of units sold", tickformat=".0%", range=[0, limit])
    fig.update_yaxes(title_text="Share of revenue", tickformat=".0%", range=[0, limit])
    save(fig, "10_category_revenue_vs_units",
         f"{top['category']} earns {top['share_of_revenue']:.0%} of revenue from {top['share_of_units']:.0%} of units; price, not volume, separates categories",
         height=640)


def reorder_backtest() -> None:
    backtest = pd.read_csv(OUTPUTS / "20_reorder_backtest_recency_by_spend.csv")
    backtest = backtest[backtest["backtest_window"] == PRIMARY_WINDOW]
    bands = list(dict.fromkeys(backtest["recency_band"]))
    pooled = pd.read_csv(OUTPUTS / "19_reorder_backtest.csv")
    recency = pooled[(pooled["dimension"] == "Recency") & (pooled["backtest_window"] == PRIMARY_WINDOW)]
    fig = go.Figure()
    for tier, color in [("Top 40% by prior spend", BLUE), ("Bottom 60% by prior spend", LIGHT_BLUE)]:
        subset = backtest[backtest["prior_spend_tier"] == tier].set_index("recency_band").loc[bands]
        fig.add_bar(x=bands, y=subset["reorder_rate_12m"], name=tier, marker_color=color,
                    text=[f"{v:.1%}" for v in subset["reorder_rate_12m"]], textposition="outside")
    fig.update_layout(barmode="group")
    fig.update_xaxes(title_text="Days since last order at the snapshot date (2025-08-31)")
    fig.update_yaxes(title_text="Share reordering in the next 12 months", tickformat=".0%", range=[0, 0.3])
    save(fig, "11_reorder_rate_by_recency_and_spend",
         f"Recency predicts a reorder ({recency['reorder_rate_12m'].iloc[0]:.0%} falling to {recency['reorder_rate_12m'].iloc[-1]:.0%}); past spend does not")


def opportunity_scenarios() -> None:
    scenarios = pd.read_csv(OUTPUTS / "21_opportunity_scenarios.csv")
    scenarios = scenarios[scenarios["backtest_window"] == PRIMARY_WINDOW]
    fig = go.Figure(go.Bar(
        x=scenarios["scenario"], y=scenarios["estimated_incremental_revenue"], marker_color=[LIGHT_BLUE, BLUE, ORANGE],
        text=[f"${v:,.0f}<br>(+{lift:.0%} relative lift)" for v, lift in zip(scenarios["estimated_incremental_revenue"], scenarios["relative_lift_in_reorder_rate"])],
        textposition="outside",
    ))
    eligible = int(scenarios["eligible_customers"].iloc[0])
    fig.update_xaxes(title_text="Scenario (assumed lift in 12-month reorder rate of one-time buyers)")
    fig.update_yaxes(title_text="Estimated incremental revenue over 12 months (USD)", tickprefix="$", tickformat=",.0f",
                     range=[0, scenarios["estimated_incremental_revenue"].max() * 1.25])
    save(fig, "12_opportunity_scenarios",
         f"Estimated opportunity from lifting the reorder rate of {eligible:,} one-time buyers (not realized revenue)")


def final_month_sensitivity() -> None:
    pooled = pd.read_csv(OUTPUTS / "19_reorder_backtest.csv")
    recency = pooled[pooled["dimension"] == "Recency"]
    largest_gap = (
        recency.pivot(index="segment", columns="backtest_window", values="reorder_rate_12m")
        .pipe(lambda rates: (rates["original"] - rates["excluding_final_month"]).abs().max())
    )
    fig = go.Figure()
    for window, color in [("original", LIGHT_BLUE), ("excluding_final_month", BLUE)]:
        subset = recency[recency["backtest_window"] == window].sort_values("sort_order")
        fig.add_bar(x=subset["segment"], y=subset["reorder_rate_12m"], name=WINDOW_LABELS[window], marker_color=color,
                    text=[f"{v:.1%}" for v in subset["reorder_rate_12m"]], textposition="outside")
    fig.update_layout(barmode="group")
    fig.update_xaxes(title_text="Days since last order at the snapshot date")
    fig.update_yaxes(title_text="Share reordering in the next 12 months", tickformat=".0%", range=[0, 0.3])
    save(fig, "13_final_month_sensitivity",
         f"Leaving September 2026 out of the outcome window moves reorder rates by at most {largest_gap * 100:.1f} points")


def main() -> None:
    PNG_DIR.mkdir(exist_ok=True)
    HTML_DIR.mkdir(parents=True, exist_ok=True)
    monthly_revenue()
    revenue_leakage()
    orders_per_customer()
    cohort_heatmap()
    cohort_repeat_rates()
    rfm_segments()
    revenue_concentration()
    funnel()
    funnel_by_segment()
    category_mix()
    reorder_backtest()
    opportunity_scenarios()
    final_month_sensitivity()


if __name__ == "__main__":
    main()
