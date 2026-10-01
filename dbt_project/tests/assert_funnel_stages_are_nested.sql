-- A later funnel stage can never have more sessions than the stage before it.
select *
from {{ ref('mart_funnel_summary') }}
where purchase_sessions > cart_sessions
    or cart_sessions > product_view_sessions
    or product_view_sessions > sessions
