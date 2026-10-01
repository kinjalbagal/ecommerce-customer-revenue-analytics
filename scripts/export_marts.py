"""Export dashboard-ready mart tables to tableau/data as CSV.

Only aggregated, customer-level and order-level marts are exported. The raw events
table and the session-level fact are deliberately left out.
"""
from bq import REPO_ROOT, client, run_query

# table name -> column to sort by, so repeated exports produce identical files
EXPORTS = {
    "fct_orders": "order_id",
    "mart_monthly_revenue": "order_month",
    "mart_customer_rfm": "user_id",
    "mart_cohort_retention": "cohort_month, months_since_first_order",
    "mart_revenue_concentration": "customer_percentile",
    "mart_funnel_summary": "session_month, traffic_source, browser, department, category",
    "mart_category_metrics": "department, category",
    "mart_reorder_backtest": "recency_band_order, prior_order_group, prior_spend_tier",
    "mart_opportunity_scenarios": "relative_lift_in_reorder_rate, recency_band_order",
}


def main() -> None:
    output_dir = REPO_ROOT / "tableau" / "data"
    output_dir.mkdir(parents=True, exist_ok=True)
    bq_client = client()
    for table, sort_columns in EXPORTS.items():
        result = run_query(bq_client, f"select * from {table} order by {sort_columns}")
        path = output_dir / f"{table}.csv"
        result.round({c: 4 for c in result.select_dtypes("float").columns}).to_csv(path, index=False)
        print(f"{table}: {len(result)} rows, {path.stat().st_size / 1e6:.2f} MB")


if __name__ == "__main__":
    main()
