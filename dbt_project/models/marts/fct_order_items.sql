-- One row per order item with product attributes and revenue flags.
select
    order_item_id,
    order_id,
    user_id,
    product_id,
    status,
    ordered_at,
    date_trunc(date(ordered_at), month) as order_month,
    category,
    department,
    brand,
    gross_item_value,
    is_revenue_item,
    net_revenue,
    gross_margin
from {{ ref('int_order_items_enriched') }}
