-- The category funnel relies on each session viewing exactly one product.
select *
from {{ ref('int_session_funnel') }}
where distinct_products_viewed != 1
