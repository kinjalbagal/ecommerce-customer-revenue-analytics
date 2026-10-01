-- order_items.created_at differs from orders.created_at by up to several days in
-- either direction, so the order timestamp is always taken from stg_orders.
select
    id as order_item_id,
    order_id,
    user_id,
    product_id,
    status,
    sale_price
from {{ source('thelook', 'order_items') }}
