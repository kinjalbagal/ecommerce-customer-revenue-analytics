-- Headline KPIs over the full history and the trailing 12 months.
with periods as (
    select 'All time' as period, date '1900-01-01' as start_date
    union all
    select 'Trailing 12 months', date_sub(max(order_date), interval 365 day)
    from fct_orders
)

select
    periods.period,
    min(orders.order_date) as first_order_date,
    max(orders.order_date) as last_order_date,
    count(*) as orders_placed,
    countif(orders.is_valid_order) as orders,
    count(distinct if(orders.is_valid_order, orders.user_id, null)) as customers,
    round(sum(orders.gross_order_value), 2) as gross_order_value,
    round(sum(orders.net_revenue), 2) as revenue,
    round(safe_divide(sum(orders.net_revenue), countif(orders.is_valid_order)), 2) as average_order_value,
    round(safe_divide(sum(if(orders.is_valid_order, orders.item_count, 0)), countif(orders.is_valid_order)), 3) as items_per_order,
    round(safe_divide(countif(orders.is_valid_order), count(distinct if(orders.is_valid_order, orders.user_id, null))), 3) as purchase_frequency,
    round(safe_divide(sum(if(orders.customer_type = 'Returning', orders.net_revenue, 0)), sum(orders.net_revenue)), 4) as returning_customer_revenue_share
from fct_orders as orders
inner join periods
    on orders.order_date > periods.start_date
group by periods.period
order by periods.period;
