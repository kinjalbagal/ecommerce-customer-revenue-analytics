-- The only full scan of the events table. Columns not used downstream
-- (ip address, city, state, postal code) are not selected.
select
    id as event_id,
    session_id,
    sequence_number,
    user_id,
    created_at as event_at,
    event_type,
    traffic_source,
    browser,
    safe_cast(regexp_extract(uri, r'^/product/(\d+)') as int64) as product_id
from {{ source('thelook', 'events') }}
-- A small number of events are stamped after the latest order; they are excluded
-- so that every model shares the same end date.
where created_at <= (select max(created_at) from {{ source('thelook', 'orders') }})
