# KPI Dictionary

All metrics are calculated from the dbt marts in `dbt_project/models/marts`. The same definitions are used in the dbt models, the queries in `sql/analysis`, the figures and the dashboard.

## Rules that apply to every metric

**Valid order.** An order counts toward revenue when its status is `Complete`, `Shipped` or `Processing`. `Cancelled` orders were never fulfilled and `Returned` orders were refunded, so both are excluded. The rule lives in one place, the `is_revenue_status` macro, and is exposed as `fct_orders.is_valid_order`. `Processing` and `Shipped` orders are included because they are committed sales that have not been reversed; some of them will later be cancelled or returned, so recent revenue is slightly overstated relative to its final value.

**Order date.** `orders.created_at`. The item-level timestamp drifts from it by between 3 hours before and 96 hours after, so it is not used.

**Customer.** A registered user (`user_id`) with at least one valid order. Users whose only orders were cancelled or returned are not customers.

**As-of date.** The latest order date in the data, 2026-09-30. "Trailing 12 months" means order dates from 2025-10-01 to 2026-09-30.

**Currency.** USD, taken from `order_items.sale_price`. There are no discounts, taxes or shipping charges in the source.

## Metrics

| Metric | Business definition | SQL logic | Grain | Assumptions |
|---|---|---|---|---|
| Revenue | Value of items in valid orders | `sum(net_revenue)` from `fct_orders` or `fct_order_items` | Order item, summable to any level | Cancelled and returned orders contribute 0 |
| Gross Order Value | Value of items in all orders placed | `sum(gross_order_value)` from `fct_orders` | Order | Used only as the denominator for leakage |
| Orders | Number of valid orders | `countif(is_valid_order)` from `fct_orders` | Order | |
| Customers | Users with at least one valid order | `count(distinct user_id)` over valid orders, or `countif(valid_orders > 0)` from `dim_customers` | Customer | Period counts use orders in the period |
| Average Order Value | Revenue per valid order | `sum(net_revenue) / countif(is_valid_order)` | Order | |
| Items per Order | Units per valid order | `sum(item_count) / count(*)` over valid orders | Order | Each order item row is one unit |
| New Customers | Customers placing their first valid order | `customer_type = 'New'` (`customer_order_number = 1`) | Order | Sequence ignores cancelled and returned orders |
| Returning Customers | Customers placing a second or later valid order | `customer_type = 'Returning'` | Order | |
| Repeat Purchase Rate | Share of customers with two or more valid orders | `countif(valid_orders >= 2) / countif(valid_orders >= 1)` from `dim_customers` | Customer | Lifetime measure; recent customers have had less time to repeat |
| Customer Lifetime Revenue | Revenue from a customer to date | `dim_customers.lifetime_revenue` | Customer | Historical, not a prediction |
| Purchase Frequency | Valid orders per customer | `orders / customers` | Customer | |
| Days Between Purchases | Days from one valid order to the customer's next | `fct_orders.days_since_previous_order` | Order (second and later) | Only defined for repeat orders |
| Cohort Retention Rate | Share of a first-order cohort placing a valid order N months later | `active_customers / cohort_size` in `mart_cohort_retention` | Cohort month x month offset | Month 0 is 100% by definition; a customer is active in a month if they placed any valid order in it |
| Funnel Conversion Rate | Share of sessions that reach purchase | `purchase_sessions / sessions` from `mart_funnel_summary` | Session | One purchase session corresponds to one order item, not one order |
| Stage Conversion Rate | Share of sessions at one stage that reach the next | `cart_sessions / product_view_sessions`, `purchase_sessions / cart_sessions` | Session | A stage counts only if it occurs after the previous one in sequence |
| Product / Category Revenue | Revenue from items in a product or category | `sum(net_revenue)` grouped by product or category in `fct_order_items` | Order item | |
| Cancellation Rate | Share of ordered units (or gross value) that was cancelled | `units_cancelled / units_ordered`; value version `cancelled_value / gross_order_value` | Order item / order | |
| Return Rate | Share of ordered units (or gross value) that was returned | `units_returned / units_ordered`; value version `returned_value / gross_order_value` | Order item / order | Denominator is all units ordered, not units delivered |
| 12-month Reorder Rate | Share of existing customers placing a valid order in the following 365 days | `customers_who_reordered / customers` in `mart_reorder_backtest` | Customer at snapshot date | Reported for the outcome window ending 2026-08-31 (snapshot 2025-08-31), which excludes the final-month spike in orders. The window ending 2026-09-30 is kept for comparison |

## RFM scoring

Calculated in `mart_customer_rfm` for customers with at least one valid order.

- **Recency** is days from the last valid order to the as-of date, scored 1 to 5 by quintile (5 is the most recent fifth).
- **Monetary** is lifetime revenue, scored 1 to 5 by quintile (5 is the highest-spending fifth).
- **Frequency** is the number of valid orders, capped at 3. The maximum in the data is four orders and 70% of customers have one, so quintiles would put identical customers in different bins.

Observed score boundaries (`analysis/outputs/09_rfm_score_thresholds.csv`):

| Score | Recency (days since last order) | Monetary (lifetime revenue) |
|---|---|---|
| 5 | 0 to 96 | $189.49 and above |
| 4 | 96 to 287 | $104.99 to $189.49 |
| 3 | 287 to 585 | $59.99 to $104.98 |
| 2 | 585 to 1,089 | $31.99 to $59.99 |
| 1 | 1,089 and above | below $31.99 |

Segments are assigned in this order, so each customer falls into exactly one:

| Segment | Rule |
|---|---|
| Champions | 2+ orders, recency score 4-5, monetary score 4-5 |
| Loyal | 2+ orders, recency score 3-5 (not Champions) |
| High-Value At Risk | recency score 1-2, monetary score 4-5 |
| At Risk | recency score 1-2, 2+ orders (not High-Value At Risk) |
| New Customers | 1 order, recency score 5 |
| Potential Loyalists | 1 order, recency score 3-4 |
| Lapsed | 1 order, recency score 1-2, monetary score 1-3 |
