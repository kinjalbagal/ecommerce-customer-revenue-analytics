-- Cumulative revenue share by customer percentile, highest spenders first.
-- One row per percentile (1 = top 1% of customers by lifetime revenue).
with ranked as (
    select
        lifetime_revenue,
        ntile(100) over (order by lifetime_revenue desc, user_id) as customer_percentile
    from {{ ref('dim_customers') }}
    where valid_orders > 0
),

by_percentile as (
    select
        customer_percentile,
        count(*) as customers,
        sum(lifetime_revenue) as revenue
    from ranked
    group by 1
)

select
    customer_percentile,
    customers,
    revenue,
    sum(revenue) over (order by customer_percentile) / sum(revenue) over () as cumulative_share_of_revenue
from by_percentile
