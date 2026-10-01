select
    product_id,
    product_name,
    brand,
    category,
    department,
    cost,
    retail_price
from {{ ref('stg_products') }}
