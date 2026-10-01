-- Backtest of organic reorder behavior. Customers are described as they stood at a
-- snapshot date, then followed for the next 365 days.
--
-- Two outcome windows are produced. Order volume in the final month of the data is far
-- above the months before it, which raises any rate measured over a window that
-- includes it. The 'excluding_final_month' window ends on the last day of the previous
-- month and is the one used for the opportunity scenarios; 'original' ends on the last
-- order date and is kept for comparison.
--
-- One row per backtest window, recency band, prior order group and prior spend tier.
with last_order as (
    select max(order_date) as last_order_date
    from {{ ref('fct_orders') }}
),

windows as (
    select
        'original' as backtest_window,
        date_sub(last_order_date, interval 365 day) as snapshot_date,
        last_order_date as outcome_end_date
    from last_order
    union all
    select
        'excluding_final_month',
        date_sub(date_sub(date_trunc(last_order_date, month), interval 1 day), interval 365 day),
        date_sub(date_trunc(last_order_date, month), interval 1 day)
    from last_order
),

before_snapshot as (
    select
        windows.backtest_window,
        orders.user_id,
        date_diff(any_value(windows.snapshot_date), max(orders.order_date), day) as recency_days,
        count(*) as prior_orders,
        sum(orders.net_revenue) as prior_revenue
    from {{ ref('fct_orders') }} as orders
    cross join windows
    where orders.is_valid_order
        and orders.order_date <= windows.snapshot_date
    group by 1, 2
),

after_snapshot as (
    select
        windows.backtest_window,
        orders.user_id,
        count(*) as orders_next_12m,
        sum(orders.net_revenue) as revenue_next_12m
    from {{ ref('fct_orders') }} as orders
    cross join windows
    where orders.is_valid_order
        and orders.order_date > windows.snapshot_date
        and orders.order_date <= windows.outcome_end_date
    group by 1, 2
),

customers as (
    select
        before_snapshot.*,
        ntile(5) over (
            partition by before_snapshot.backtest_window
            order by before_snapshot.prior_revenue, before_snapshot.user_id
        ) as prior_spend_quintile,
        coalesce(after_snapshot.orders_next_12m, 0) as orders_next_12m,
        coalesce(after_snapshot.revenue_next_12m, 0) as revenue_next_12m
    from before_snapshot
    left join after_snapshot
        on before_snapshot.backtest_window = after_snapshot.backtest_window
        and before_snapshot.user_id = after_snapshot.user_id
)

select
    customers.backtest_window,
    any_value(windows.snapshot_date) as snapshot_date,
    any_value(windows.outcome_end_date) as outcome_end_date,
    {{ recency_band('customers.recency_days') }} as recency_band,
    min(customers.recency_days) as recency_band_order,
    if(customers.prior_orders = 1, '1 order', '2+ orders') as prior_order_group,
    if(customers.prior_spend_quintile >= 4, 'Top 40% by prior spend', 'Bottom 60% by prior spend') as prior_spend_tier,
    count(*) as customers,
    countif(customers.orders_next_12m > 0) as customers_who_reordered,
    sum(customers.orders_next_12m) as orders_next_12m,
    sum(customers.revenue_next_12m) as revenue_next_12m,
    avg(customers.prior_revenue) as avg_prior_revenue
from customers
inner join windows
    on customers.backtest_window = windows.backtest_window
group by 1, 4, 6, 7
