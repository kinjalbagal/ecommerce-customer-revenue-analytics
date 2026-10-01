-- Personal fields (name, email, street address) are not needed for analysis and are left out.
select
    id as user_id,
    age,
    gender,
    -- The source spells Spain two ways.
    case country when 'España' then 'Spain' else country end as country,
    state,
    city,
    traffic_source as acquisition_source,
    created_at as signed_up_at
from {{ source('thelook', 'users') }}
