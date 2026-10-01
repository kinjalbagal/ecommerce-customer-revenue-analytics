-- Backtest of organic reorder behaviour. Customers are described as they stood one year
-- before the end of the data, then followed for the next 365 days.
-- One row per recency band, prior order count group and prior spend tier.
with snapshot as (
    select date_sub(max(order_date), interval 365 day) as snapshot_date
    from {{ ref('fct_orders') }}
),

before_snapshot as (
    select
        orders.user_id,
        date_diff(any_value(snapshot.snapshot_date), max(orders.order_date), day) as recency_days,
        count(*) as prior_orders,
        sum(orders.net_revenue) as prior_revenue
    from {{ ref('fct_orders') }} as orders
    cross join snapshot
    where orders.is_valid_order
        and orders.order_date <= snapshot.snapshot_date
    group by orders.user_id
),

after_snapshot as (
    select
        orders.user_id,
        count(*) as orders_next_12m,
        sum(orders.net_revenue) as revenue_next_12m
    from {{ ref('fct_orders') }} as orders
    cross join snapshot
    where orders.is_valid_order
        and orders.order_date > snapshot.snapshot_date
    group by orders.user_id
),

customers as (
    select
        before_snapshot.*,
        ntile(5) over (order by before_snapshot.prior_revenue, before_snapshot.user_id) as prior_spend_quintile,
        coalesce(after_snapshot.orders_next_12m, 0) as orders_next_12m,
        coalesce(after_snapshot.revenue_next_12m, 0) as revenue_next_12m
    from before_snapshot
    left join after_snapshot
        on before_snapshot.user_id = after_snapshot.user_id
)

select
    {{ recency_band('recency_days') }} as recency_band,
    min(recency_days) as recency_band_order,
    if(prior_orders = 1, '1 order', '2+ orders') as prior_order_group,
    if(prior_spend_quintile >= 4, 'Top 40% by prior spend', 'Bottom 60% by prior spend') as prior_spend_tier,
    count(*) as customers,
    countif(orders_next_12m > 0) as customers_who_reordered,
    sum(orders_next_12m) as orders_next_12m,
    sum(revenue_next_12m) as revenue_next_12m,
    avg(prior_revenue) as avg_prior_revenue
from customers
group by 1, 3, 4
