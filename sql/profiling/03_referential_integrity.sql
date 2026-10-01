-- Orphaned foreign keys between source tables.
select 'orders.user_id -> users.id' as relationship, count(*) as child_rows, countif(u.id is null) as orphans
from `bigquery-public-data.thelook_ecommerce.orders` o
left join `bigquery-public-data.thelook_ecommerce.users` u on o.user_id = u.id
union all
select 'order_items.order_id -> orders.order_id', count(*), countif(o.order_id is null)
from `bigquery-public-data.thelook_ecommerce.order_items` oi
left join `bigquery-public-data.thelook_ecommerce.orders` o on oi.order_id = o.order_id
union all
select 'order_items.product_id -> products.id', count(*), countif(p.id is null)
from `bigquery-public-data.thelook_ecommerce.order_items` oi
left join `bigquery-public-data.thelook_ecommerce.products` p on oi.product_id = p.id
union all
select 'order_items.user_id = orders.user_id', count(*), countif(oi.user_id != o.user_id)
from `bigquery-public-data.thelook_ecommerce.order_items` oi
join `bigquery-public-data.thelook_ecommerce.orders` o on oi.order_id = o.order_id
union all
select 'orders without order_items', count(*), countif(oi.order_id is null)
from `bigquery-public-data.thelook_ecommerce.orders` o
left join (select distinct order_id from `bigquery-public-data.thelook_ecommerce.order_items`) oi on o.order_id = oi.order_id
union all
select 'events.user_id -> users.id (non-null user_id)', count(*), countif(u.id is null)
from `bigquery-public-data.thelook_ecommerce.events` e
left join `bigquery-public-data.thelook_ecommerce.users` u on e.user_id = u.id
where e.user_id is not null
order by relationship;
