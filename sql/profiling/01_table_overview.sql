-- Row counts and date coverage for each source table.
select 'users' as table_name, count(*) as row_count, min(created_at) as min_created_at, max(created_at) as max_created_at
from `bigquery-public-data.thelook_ecommerce.users`
union all
select 'orders', count(*), min(created_at), max(created_at)
from `bigquery-public-data.thelook_ecommerce.orders`
union all
select 'order_items', count(*), min(created_at), max(created_at)
from `bigquery-public-data.thelook_ecommerce.order_items`
union all
select 'events', count(*), min(created_at), max(created_at)
from `bigquery-public-data.thelook_ecommerce.events`
union all
select 'inventory_items', count(*), min(created_at), max(created_at)
from `bigquery-public-data.thelook_ecommerce.inventory_items`
union all
select 'products', count(*), null, null
from `bigquery-public-data.thelook_ecommerce.products`
union all
select 'distribution_centers', count(*), null, null
from `bigquery-public-data.thelook_ecommerce.distribution_centers`
order by table_name;
