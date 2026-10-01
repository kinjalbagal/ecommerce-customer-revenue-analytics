-- Value-range and missing-value checks on fields used in the analysis.
select 'order_items.sale_price <= 0 or null' as check_name, countif(sale_price is null or sale_price <= 0) as failing_rows, count(*) as total_rows
from `bigquery-public-data.thelook_ecommerce.order_items`
union all
select 'order_items.sale_price != products.retail_price', countif(abs(oi.sale_price - p.retail_price) > 0.005), count(*)
from `bigquery-public-data.thelook_ecommerce.order_items` oi
join `bigquery-public-data.thelook_ecommerce.products` p on oi.product_id = p.id
union all
select 'products.cost >= retail_price', countif(cost >= retail_price), count(*)
from `bigquery-public-data.thelook_ecommerce.products`
union all
select 'products.name is null', countif(name is null), count(*)
from `bigquery-public-data.thelook_ecommerce.products`
union all
select 'products.brand is null', countif(brand is null), count(*)
from `bigquery-public-data.thelook_ecommerce.products`
union all
select 'users.age outside 12-70', countif(age < 12 or age > 70), count(*)
from `bigquery-public-data.thelook_ecommerce.users`
union all
select 'users.city is null', countif(city is null), count(*)
from `bigquery-public-data.thelook_ecommerce.users`
union all
select 'users.created_at in the future', countif(created_at > current_timestamp()), count(*)
from `bigquery-public-data.thelook_ecommerce.users`
union all
select 'orders.created_at in the future', countif(created_at > current_timestamp()), count(*)
from `bigquery-public-data.thelook_ecommerce.orders`
union all
select 'orders.created_at before users.created_at', countif(o.created_at < u.created_at), count(*)
from `bigquery-public-data.thelook_ecommerce.orders` o
join `bigquery-public-data.thelook_ecommerce.users` u on o.user_id = u.id
union all
select 'events.created_at in the future', countif(created_at > current_timestamp()), count(*)
from `bigquery-public-data.thelook_ecommerce.events`
union all
select 'users with zero orders', countif(o.user_id is null), count(*)
from `bigquery-public-data.thelook_ecommerce.users` u
left join (select distinct user_id from `bigquery-public-data.thelook_ecommerce.orders`) o on u.id = o.user_id
order by check_name;
