-- Distribution of order value, basket size and orders per customer, to spot outliers.
with order_values as (
    select order_id, user_id, count(*) as items, sum(sale_price) as order_value
    from `bigquery-public-data.thelook_ecommerce.order_items`
    group by order_id, user_id
),

customer_orders as (
    select user_id, count(*) as orders
    from order_values
    group by user_id
)

select
    'order_value_usd' as measure,
    round(min(order_value), 2) as min_value,
    round(approx_quantiles(order_value, 100)[offset(50)], 2) as p50,
    round(approx_quantiles(order_value, 100)[offset(90)], 2) as p90,
    round(approx_quantiles(order_value, 100)[offset(99)], 2) as p99,
    round(max(order_value), 2) as max_value
from order_values
union all
select 'items_per_order', min(items), approx_quantiles(items, 100)[offset(50)], approx_quantiles(items, 100)[offset(90)],
    approx_quantiles(items, 100)[offset(99)], max(items)
from order_values
union all
select 'orders_per_customer', min(orders), approx_quantiles(orders, 100)[offset(50)], approx_quantiles(orders, 100)[offset(90)],
    approx_quantiles(orders, 100)[offset(99)], max(orders)
from customer_orders
union all
select 'item_sale_price_usd', round(min(sale_price), 2), round(approx_quantiles(sale_price, 100)[offset(50)], 2),
    round(approx_quantiles(sale_price, 100)[offset(90)], 2), round(approx_quantiles(sale_price, 100)[offset(99)], 2), round(max(sale_price), 2)
from `bigquery-public-data.thelook_ecommerce.order_items`;
