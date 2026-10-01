-- Session funnel counts aggregated for reporting.
-- One row per month, traffic source, browser, department and category.
select
    session_month,
    traffic_source,
    browser,
    department,
    category,
    count(*) as sessions,
    countif(reached_product_view) as product_view_sessions,
    countif(reached_cart) as cart_sessions,
    countif(reached_purchase) as purchase_sessions,
    countif(has_cancel_event) as cancel_sessions
from {{ ref('fct_sessions') }}
group by 1, 2, 3, 4, 5
