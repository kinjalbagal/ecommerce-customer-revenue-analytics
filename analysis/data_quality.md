# Data Profiling and Quality Notes

Source: `bigquery-public-data.thelook_ecommerce`, profiled on 2026-09-30. Queries are in `sql/profiling` and their results in `analysis/outputs/profiling`. The dataset is synthetic and is regenerated daily, so row counts and values change from day to day; the figures below describe the snapshot used for this analysis.

## Tables used

| Table | Rows | Primary key | Date range (`created_at`) |
|---|---|---|---|
| users | 100,000 | `id` | 2019-01-02 to 2026-09-29 |
| orders | 124,814 | `order_id` | 2019-01-11 to 2026-09-30 |
| order_items | 180,771 | `id` | 2019-01-11 to 2026-10-04 |
| products | 29,120 | `id` | not dated |
| events | 2,419,854 | `id`; also (`session_id`, `sequence_number`) | 2019-01-02 to 2026-10-04 |

`inventory_items` and `distribution_centers` were inspected but are not needed for the business question and are not modeled.

Relationships: `orders.user_id` to `users.id`, `order_items.order_id` to `orders.order_id`, `order_items.product_id` to `products.id`, `events.user_id` to `users.id` (nullable).

## What is clean

- Every candidate primary key is unique and non-null.
- No orphaned foreign keys in any of the relationships above. Every order has at least one item, and `order_items.user_id` always matches the order's user.
- `orders.num_of_item` equals the count of item rows for every order.
- Item status always equals order status; no order has mixed item statuses.
- Status timestamps are consistent: cancelled and processing orders have no shipped date, only returned orders have a returned date, and no timestamp precedes the one before it.
- No null, zero or negative sale prices. No product costs more than its retail price.

## Observations that affect the analysis

**1. A quarter of orders do not become revenue.** 15.2% of orders are `Cancelled` and 10.1% are `Returned`. The revenue definition excludes both (see `kpi_dictionary.md`).

**2. Item timestamps drift from order timestamps.** `order_items.created_at` ranges from 3 hours before to 96 hours after `orders.created_at`, and matches it exactly for only 4 of 180,771 items. The order timestamp is used for all order dating.

**3. 1,843 order items and their purchase events are stamped after the latest order.** Because of the drift above, some items and the sessions generated from them run to 2026-10-04. Those 1,843 sessions are excluded whole from `fct_sessions` so that sessions and orders share one end date.

**4. Purchase sessions correspond to order items, not orders.** There are 180,771 purchase events in 180,771 sessions, the same as the number of order items, and each user's count of purchase sessions equals their count of order items. Each session views exactly one product, and that product is always among the user's order items. Purchase events are generated for cancelled and returned items too. Funnel conversion is therefore a session-level rate and cannot be reconciled to order counts.

**5. Identified and anonymous sessions do not overlap in outcome.** Every session with a `user_id` ends in a purchase, and no session without one does. A funnel split by customer type would show 100% and 0%, so it is not produced. For the same reason the funnel cannot be linked to new versus returning customers.

**6. Anonymous traffic is flat while purchases grow.** Anonymous sessions number about 64,000 to 65,000 in every full year, while purchasing sessions grow from 1,444 in 2019 to 59,282 in 2026. Blended conversion therefore rises from 2.2% to 55.3% purely through this mix. The trend is a property of how the data is generated and is not interpreted as an improvement.

**7. Order volume is concentrated near the present.** Users sign up at an even rate of about 12,500 a year, but orders grow from 1,013 in 2019 to 42,028 in the first nine months of 2026, and September 2026 alone has 9,956 orders against 5,621 in August. The median gap between signup and an order is 502 days. Metrics measured over recent windows, including recent-cohort retention and the reorder backtest, are raised by this. The reorder backtest was therefore run with and without September 2026 in its outcome window; the effect on the baseline is small (15.6% against 15.4%) and the version without it is used. See section 7 of `findings.md`.

**8. Session traffic source and user acquisition source are different fields.** `events.traffic_source` takes the values Email, Adwords, YouTube, Facebook and Organic; `users.traffic_source` takes Search, Organic, Facebook, Email and Display. They agree for only 6,342 of 180,771 identified sessions. They are kept as separate dimensions (`traffic_source` on sessions, `acquisition_source` on customers).

**9. No discounting.** `sale_price` equals the product's `retail_price` for every item, so price and promotion effects cannot be studied.

**10. Purchase depth is shallow.** No customer has more than four orders and no order has more than four items; the median for both is one. Frequency in the RFM model is scored on the raw count for this reason.

**11. Minor items.** `users.email` is not unique (16,212 duplicate values), so `user_id` is the only customer identifier and email is not carried into the models. Spain appears as both `Spain` and `España` and is merged in staging. 2 products have no name and 24 have no brand; both are filled with `Unknown`. 19,966 users have never placed an order.

## How these checks are enforced

The dbt project carries the checks that the models depend on: uniqueness and non-null tests on every key, relationship tests between facts and dimensions, accepted-value tests on order status, event type and traffic source, and singular tests for revenue reconciliation across grains, funnel stage nesting, one product per session, composite-key uniqueness, and full retention in cohort month zero.
