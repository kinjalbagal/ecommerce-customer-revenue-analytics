-- Distributions of the categorical fields used for segmentation.
select 'users.traffic_source' as field, traffic_source as value, count(*) as row_count
from `bigquery-public-data.thelook_ecommerce.users` group by 2
union all
select 'users.gender', gender, count(*)
from `bigquery-public-data.thelook_ecommerce.users` group by 2
union all
select 'users.country', country, count(*)
from `bigquery-public-data.thelook_ecommerce.users` group by 2
union all
select 'events.traffic_source', traffic_source, count(*)
from `bigquery-public-data.thelook_ecommerce.events` group by 2
union all
select 'events.browser', browser, count(*)
from `bigquery-public-data.thelook_ecommerce.events` group by 2
union all
select 'products.department', department, count(*)
from `bigquery-public-data.thelook_ecommerce.products` group by 2
union all
select 'products.category', category, count(*)
from `bigquery-public-data.thelook_ecommerce.products` group by 2
order by field, row_count desc;
