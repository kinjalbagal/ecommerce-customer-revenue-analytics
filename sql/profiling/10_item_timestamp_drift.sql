-- How far order_items.created_at drifts from the parent order's created_at.
select
    countif(items.created_at < orders.created_at) as items_stamped_before_order,
    countif(items.created_at = orders.created_at) as items_stamped_with_order,
    countif(items.created_at > orders.created_at) as items_stamped_after_order,
    min(timestamp_diff(items.created_at, orders.created_at, hour)) as min_difference_hours,
    max(timestamp_diff(items.created_at, orders.created_at, hour)) as max_difference_hours
from `bigquery-public-data.thelook_ecommerce.order_items` as items
inner join `bigquery-public-data.thelook_ecommerce.orders` as orders
    on items.order_id = orders.order_id;
