select
    id as product_id,
    coalesce(name, 'Unknown') as product_name,
    coalesce(brand, 'Unknown') as brand,
    category,
    department,
    cost,
    retail_price
from {{ source('thelook', 'products') }}
