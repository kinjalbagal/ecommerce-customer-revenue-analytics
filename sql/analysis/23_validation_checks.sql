-- Independent recalculation of headline figures straight from the staging tables,
-- compared with the marts. Every difference should be zero.
with source_side as (
    select
        (select sum(items.sale_price)
            from stg_order_items as items
            inner join stg_orders as orders on items.order_id = orders.order_id
            where orders.status in ('Complete', 'Shipped', 'Processing')) as revenue,
        (select count(*) from stg_orders where status in ('Complete', 'Shipped', 'Processing')) as orders,
        (select count(distinct user_id) from stg_orders where status in ('Complete', 'Shipped', 'Processing')) as customers,
        (select count(*) from (
            select user_id from stg_orders
            where status in ('Complete', 'Shipped', 'Processing')
            group by user_id having count(*) >= 2)) as repeat_customers,
        (select count(distinct session_id) from stg_events
            where event_type = 'purchase'
                and event_at <= (select max(ordered_at) from stg_orders)) as purchase_sessions
),

mart_side as (
    select
        (select sum(net_revenue) from fct_orders) as revenue,
        (select countif(is_valid_order) from fct_orders) as orders,
        (select countif(valid_orders > 0) from dim_customers) as customers,
        (select countif(valid_orders >= 2) from dim_customers) as repeat_customers,
        (select countif(reached_purchase) from fct_sessions) as purchase_sessions,
        (select sum(cohort_size) from mart_cohort_retention where months_since_first_order = 0) as cohort_customers,
        (select count(*) from mart_customer_rfm) as rfm_customers,
        (select sum(revenue) from mart_cohort_retention) as cohort_revenue
)

select 'revenue' as metric, round(source_side.revenue, 2) as recalculated, round(mart_side.revenue, 2) as mart_value,
    round(source_side.revenue - mart_side.revenue, 2) as difference
from source_side, mart_side
union all
select 'orders', source_side.orders, mart_side.orders, source_side.orders - mart_side.orders from source_side, mart_side
union all
select 'customers', source_side.customers, mart_side.customers, source_side.customers - mart_side.customers from source_side, mart_side
union all
select 'repeat customers', source_side.repeat_customers, mart_side.repeat_customers, source_side.repeat_customers - mart_side.repeat_customers from source_side, mart_side
union all
select 'purchase sessions', source_side.purchase_sessions, mart_side.purchase_sessions, source_side.purchase_sessions - mart_side.purchase_sessions from source_side, mart_side
union all
select 'customers in cohorts', mart_side.customers, mart_side.cohort_customers, mart_side.customers - mart_side.cohort_customers from mart_side
union all
select 'customers in RFM', mart_side.customers, mart_side.rfm_customers, mart_side.customers - mart_side.rfm_customers from mart_side
union all
select 'revenue in cohorts', round(mart_side.revenue, 2), round(mart_side.cohort_revenue, 2), round(mart_side.revenue - mart_side.cohort_revenue, 2) from mart_side;
