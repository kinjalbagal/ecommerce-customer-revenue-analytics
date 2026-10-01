-- Monthly revenue and order KPIs. One row per calendar month.
select
    order_month,
    count(*) as orders_placed,
    countif(is_valid_order) as orders,
    count(distinct if(is_valid_order, user_id, null)) as customers,
    sum(net_revenue) as revenue,
    sum(gross_order_value) as gross_order_value,
    sum(if(status = 'Cancelled', gross_order_value, 0)) as cancelled_value,
    sum(if(status = 'Returned', gross_order_value, 0)) as returned_value,
    safe_divide(sum(net_revenue), countif(is_valid_order)) as average_order_value,
    countif(customer_type = 'New') as new_customer_orders,
    countif(customer_type = 'Returning') as returning_customer_orders,
    sum(if(customer_type = 'New', net_revenue, 0)) as new_customer_revenue,
    sum(if(customer_type = 'Returning', net_revenue, 0)) as returning_customer_revenue
from {{ ref('fct_orders') }}
group by order_month
