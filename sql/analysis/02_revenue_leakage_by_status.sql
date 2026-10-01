-- Where gross order value goes: kept as revenue, cancelled, or returned.
with periods as (
    select 'All time' as period, date '1900-01-01' as start_date
    union all
    select 'Trailing 12 months', date_sub(max(order_date), interval 365 day)
    from fct_orders
)

select
    periods.period,
    orders.status,
    orders.is_valid_order as counts_toward_revenue,
    count(*) as orders,
    round(sum(orders.gross_order_value), 2) as gross_order_value,
    round(count(*) / sum(count(*)) over (partition by periods.period), 4) as share_of_orders,
    round(sum(orders.gross_order_value) / sum(sum(orders.gross_order_value)) over (partition by periods.period), 4) as share_of_gross_order_value
from fct_orders as orders
inner join periods
    on orders.order_date > periods.start_date
group by 1, 2, 3
order by 1, gross_order_value desc;
