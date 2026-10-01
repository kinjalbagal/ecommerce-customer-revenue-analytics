-- Candidate primary keys: null and duplicate counts.
select 'users.id' as key_column, count(*) as row_count, countif(id is null) as null_keys, count(*) - count(distinct id) as duplicate_keys
from `bigquery-public-data.thelook_ecommerce.users`
union all
select 'users.email', count(*), countif(email is null), count(*) - count(distinct email)
from `bigquery-public-data.thelook_ecommerce.users`
union all
select 'orders.order_id', count(*), countif(order_id is null), count(*) - count(distinct order_id)
from `bigquery-public-data.thelook_ecommerce.orders`
union all
select 'order_items.id', count(*), countif(id is null), count(*) - count(distinct id)
from `bigquery-public-data.thelook_ecommerce.order_items`
union all
select 'order_items.inventory_item_id', count(*), countif(inventory_item_id is null), count(*) - count(distinct inventory_item_id)
from `bigquery-public-data.thelook_ecommerce.order_items`
union all
select 'products.id', count(*), countif(id is null), count(*) - count(distinct id)
from `bigquery-public-data.thelook_ecommerce.products`
union all
select 'events.id', count(*), countif(id is null), count(*) - count(distinct id)
from `bigquery-public-data.thelook_ecommerce.events`
union all
select 'events.(session_id, sequence_number)', count(*), countif(session_id is null or sequence_number is null),
    count(*) - count(distinct concat(session_id, '-', cast(sequence_number as string)))
from `bigquery-public-data.thelook_ecommerce.events`
order by key_column;
