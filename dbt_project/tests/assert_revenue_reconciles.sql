-- Revenue must be identical at item, order, customer and month grain. Returns a row when it is not.
with totals as (
    select
        (select sum(net_revenue) from {{ ref('fct_order_items') }}) as item_revenue,
        (select sum(net_revenue) from {{ ref('fct_orders') }}) as order_revenue,
        (select sum(lifetime_revenue) from {{ ref('dim_customers') }}) as customer_revenue,
        (select sum(revenue) from {{ ref('mart_monthly_revenue') }}) as monthly_revenue,
        (select sum(revenue) from {{ ref('mart_category_metrics') }}) as category_revenue
)

select *
from totals
where abs(item_revenue - order_revenue) > 0.01
    or abs(item_revenue - customer_revenue) > 0.01
    or abs(item_revenue - monthly_revenue) > 0.01
    or abs(item_revenue - category_revenue) > 0.01
