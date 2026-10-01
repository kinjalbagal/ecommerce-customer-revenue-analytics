-- One row per session with the first sequence position of each funnel stage.
-- A stage only counts as reached if it happens after the previous stage.
with session_events as (
    select
        session_id,
        any_value(user_id) as user_id,
        any_value(traffic_source) as traffic_source,
        any_value(browser) as browser,
        min(event_at) as session_started_at,
        count(*) as event_count,
        min(if(event_type = 'product', sequence_number, null)) as first_product_seq,
        min(if(event_type = 'cart', sequence_number, null)) as first_cart_seq,
        max(if(event_type = 'purchase', sequence_number, null)) as purchase_seq,
        logical_or(event_type = 'cancel') as has_cancel_event,
        -- Each session views a single product, so any non-null value is that product.
        any_value(product_id) as product_id,
        count(distinct product_id) as distinct_products_viewed
    from {{ ref('stg_events') }}
    group by session_id
    -- Order items, and the purchase sessions generated from them, can be stamped a few
    -- days after the latest order. Sessions running past that point are dropped whole
    -- so that every model shares the same end date and no session is cut short.
    having max(event_at) <= (select max(ordered_at) from {{ ref('stg_orders') }})
)

select
    session_id,
    user_id,
    traffic_source,
    browser,
    session_started_at,
    event_count,
    product_id,
    distinct_products_viewed,
    has_cancel_event,
    first_product_seq is not null as reached_product_view,
    first_cart_seq > first_product_seq as reached_cart,
    purchase_seq > first_cart_seq and first_cart_seq > first_product_seq as reached_purchase
from session_events
