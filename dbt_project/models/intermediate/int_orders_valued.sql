-- Order-level value rolled up from items. One row per order.
select
    orders.order_id,
    orders.user_id,
    orders.status,
    orders.ordered_at,
    {{ is_revenue_status('orders.status') }} as is_valid_order,
    count(*) as item_count,
    sum(items.gross_item_value) as gross_order_value,
    sum(items.net_revenue) as net_revenue,
    sum(items.gross_margin) as gross_margin
from {{ ref('stg_orders') }} as orders
inner join {{ ref('int_order_items_enriched') }} as items
    on orders.order_id = items.order_id
group by 1, 2, 3, 4, 5
