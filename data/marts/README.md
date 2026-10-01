# Mart Exports

CSV exports of the dbt marts, written by `scripts/export_marts.py` and read by the Streamlit dashboard and the figure script. Snapshot of the source taken on 2026-09-30. No file contains raw events or personal fields. Float columns are rounded to six decimals.

| File | Grain | Rows | Size |
|---|---|---|---|
| `fct_orders.csv` | One row per order | 124,814 | 13 MB |
| `mart_monthly_revenue.csv` | One row per order month | 93 | < 0.1 MB |
| `mart_customer_rfm.csv` | One row per customer with a valid order | 65,969 | 6 MB |
| `mart_cohort_retention.csv` | One row per cohort month and months since first order | 4,371 | 0.2 MB |
| `mart_revenue_concentration.csv` | One row per customer percentile | 100 | < 0.1 MB |
| `mart_funnel_summary.csv` | One row per session month, traffic source, browser, department and category | 69,611 | 4 MB |
| `mart_category_metrics.csv` | One row per department and category | 36 | < 0.1 MB |
| `mart_reorder_backtest.csv` | One row per backtest window, recency band, prior order group and prior spend tier | 40 | < 0.1 MB |
| `mart_opportunity_scenarios.csv` | One row per backtest window, scenario and recency band | 30 | < 0.1 MB |

Revenue everywhere means value from orders with status Complete, Shipped or Processing. See `analysis/kpi_dictionary.md`.

## Columns

### fct_orders.csv

| Column | Description |
|---|---|
| `order_id` | Primary key |
| `user_id` | Customer who placed the order |
| `status` | Complete, Shipped, Processing, Cancelled or Returned |
| `ordered_at`, `order_date`, `order_month` | Order timestamp (UTC), date, and first day of month |
| `is_valid_order` | True when the status counts toward revenue |
| `item_count` | Units in the order |
| `gross_order_value` | Sum of item prices regardless of status |
| `net_revenue` | Revenue; 0 for cancelled and returned orders |
| `gross_margin` | Revenue less product cost; 0 for cancelled and returned orders |
| `customer_order_number` | Position among the customer's valid orders; empty for invalid orders |
| `customer_type` | New (first valid order) or Returning; empty for invalid orders |
| `days_since_previous_order` | Days since the customer's previous valid order; empty for first and invalid orders |

### mart_monthly_revenue.csv

| Column | Description |
|---|---|
| `order_month` | Primary key |
| `orders_placed` | All orders, any status |
| `orders`, `customers`, `revenue` | Valid orders, distinct customers with a valid order, revenue |
| `gross_order_value`, `cancelled_value`, `returned_value` | Value of all orders, and of cancelled and returned orders |
| `average_order_value` | Revenue per valid order |
| `new_customer_orders`, `returning_customer_orders` | Valid orders split by customer type |
| `new_customer_revenue`, `returning_customer_revenue` | Revenue split by customer type |

`customers` is a distinct count within the month and must not be summed across months. Use `fct_orders.csv` for customer counts over other periods.

### mart_customer_rfm.csv

| Column | Description |
|---|---|
| `user_id` | Primary key |
| `country`, `acquisition_source` | Customer attributes |
| `recency_days` | Days from last valid order to 2026-09-30 |
| `frequency` | Valid orders |
| `monetary` | Lifetime revenue |
| `average_order_value` | Lifetime revenue per valid order |
| `avg_days_between_orders` | Mean gap between valid orders; empty for one-time buyers |
| `last_order_at` | Timestamp of last valid order |
| `recency_score`, `monetary_score` | Quintile scores, 5 is best |
| `frequency_score` | Valid orders capped at 3 |
| `rfm_segment` | One of seven segments |

### mart_cohort_retention.csv

| Column | Description |
|---|---|
| `cohort_month` | Month of the customer's first valid order |
| `months_since_first_order` | 0 is the cohort month |
| `cohort_size` | Customers in the cohort (repeated on every row of the cohort) |
| `active_customers` | Cohort customers with a valid order in that month |
| `retention_rate` | `active_customers / cohort_size` |
| `orders`, `revenue` | Valid orders and revenue from the cohort in that month |

Only observed months are present, so later cohorts have fewer rows.

### mart_revenue_concentration.csv

| Column | Description |
|---|---|
| `customer_percentile` | 1 is the top 1% of customers by lifetime revenue |
| `customers`, `revenue` | Customers and revenue in the percentile |
| `cumulative_share_of_revenue` | Share of revenue from this and all higher-spending percentiles |

### mart_funnel_summary.csv

| Column | Description |
|---|---|
| `session_month`, `traffic_source`, `browser`, `department`, `category` | Grain. Department and category are those of the product viewed |
| `sessions` | Sessions |
| `product_view_sessions` | Sessions with a product view (equal to `sessions` in this data) |
| `cart_sessions` | Sessions with a cart event after a product view |
| `purchase_sessions` | Sessions with a purchase event after a cart event |
| `cancel_sessions` | Sessions containing a cancel event |

All columns are additive. Compute rates as ratios of sums.

### mart_category_metrics.csv

| Column | Description |
|---|---|
| `department`, `category` | Grain |
| `units_ordered`, `units_sold`, `units_cancelled`, `units_returned` | Unit counts; sold means in a valid order |
| `orders`, `customers` | Valid orders and customers including the category. Not additive across rows |
| `gross_item_value`, `revenue`, `gross_margin` | Value of all units ordered, revenue, and revenue less cost |
| `cancellation_rate`, `return_rate` | Share of units ordered |
| `average_unit_revenue`, `gross_margin_rate` | Revenue per unit sold; margin as a share of revenue |
| `first_order_customers` | Customers whose first valid order included the category |
| `first_order_customers_who_repeated`, `first_order_repeat_rate` | Of those, the number and share with a second valid order |

### mart_reorder_backtest.csv

Customers as they stood at a snapshot date, followed for 365 days. Two windows are included: `excluding_final_month` (snapshot 2025-08-31, used for the headline results) and `original` (snapshot 2025-09-30).

| Column | Description |
|---|---|
| `backtest_window` | `excluding_final_month` or `original` |
| `snapshot_date`, `outcome_end_date` | Start and end of the 365-day outcome window |
| `recency_band`, `recency_band_order` | Days since last order at the snapshot, and a sort key |
| `prior_order_group` | 1 order or 2+ orders before the snapshot |
| `prior_spend_tier` | Top 40% or bottom 60% of customers by revenue before the snapshot |
| `customers` | Customers in the group |
| `customers_who_reordered` | Customers with a valid order in the following 365 days |
| `orders_next_12m`, `revenue_next_12m` | Their valid orders and revenue in that window |
| `avg_prior_revenue` | Mean revenue per customer before the snapshot |

### mart_opportunity_scenarios.csv

Estimates built on assumptions. Not realized revenue.

| Column | Description | Type |
|---|---|---|
| `backtest_window` | Backtest window that supplied the baseline; filter to one value before summing | |
| `scenario` | Conservative, Base or Optimistic | |
| `relative_lift_in_reorder_rate` | Assumed relative increase in the reorder rate | Assumption |
| `recency_band`, `recency_band_order` | Days since the customer's only order, and a sort key | |
| `eligible_customers` | Customers with exactly one valid order | Observed |
| `baseline_reorder_rate` | 12-month reorder rate of one-order customers in the band, from the backtest | Observed |
| `expected_order_value` | Average value of orders placed by one-order customers in the backtest window | Observed |
| `estimated_incremental_customers` | `eligible_customers x baseline_reorder_rate x lift` | Estimate |
| `estimated_incremental_revenue` | `estimated_incremental_customers x expected_order_value` | Estimate |
