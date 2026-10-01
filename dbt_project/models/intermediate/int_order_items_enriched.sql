-- Order items joined to their order and product, with the revenue rule applied once.
select
    order_items.order_item_id,
    order_items.order_id,
    order_items.user_id,
    order_items.product_id,
    orders.status,
    orders.ordered_at,
    products.category,
    products.department,
    products.brand,
    order_items.sale_price as gross_item_value,
    {{ is_revenue_status('orders.status') }} as is_revenue_item,
    if({{ is_revenue_status('orders.status') }}, order_items.sale_price, 0) as net_revenue,
    if({{ is_revenue_status('orders.status') }}, order_items.sale_price - products.cost, 0) as gross_margin
from {{ ref('stg_order_items') }} as order_items
inner join {{ ref('stg_orders') }} as orders
    on order_items.order_id = orders.order_id
inner join {{ ref('stg_products') }} as products
    on order_items.product_id = products.product_id
