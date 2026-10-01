-- One row per web session with funnel stage flags and the product viewed.
select
    sessions.session_id,
    sessions.user_id,
    sessions.user_id is not null as is_identified_user,
    sessions.session_started_at,
    date_trunc(date(sessions.session_started_at), month) as session_month,
    sessions.traffic_source,
    sessions.browser,
    sessions.product_id,
    products.department,
    products.category,
    sessions.event_count,
    sessions.has_cancel_event,
    sessions.reached_product_view,
    coalesce(sessions.reached_cart, false) as reached_cart,
    coalesce(sessions.reached_purchase, false) as reached_purchase
from {{ ref('int_session_funnel') }} as sessions
left join {{ ref('stg_products') }} as products
    on sessions.product_id = products.product_id
