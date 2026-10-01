-- Funnel conversion by traffic source, browser and department over the trailing 12 months.
with recent as (
    select *
    from mart_funnel_summary
    where session_month >= (select date_sub(max(session_month), interval 11 month) from mart_funnel_summary)
),

unpivoted as (
    select 'Traffic source' as dimension, traffic_source as segment, sessions, cart_sessions, purchase_sessions, cancel_sessions from recent
    union all
    select 'Browser', browser, sessions, cart_sessions, purchase_sessions, cancel_sessions from recent
    union all
    select 'Department', department, sessions, cart_sessions, purchase_sessions, cancel_sessions from recent
)

select
    dimension,
    segment,
    sum(sessions) as sessions,
    round(safe_divide(sum(cart_sessions), sum(sessions)), 4) as view_to_cart_rate,
    round(safe_divide(sum(purchase_sessions), sum(cart_sessions)), 4) as cart_to_purchase_rate,
    round(safe_divide(sum(purchase_sessions), sum(sessions)), 4) as overall_conversion_rate,
    round(safe_divide(sum(cancel_sessions), sum(cart_sessions)), 4) as cart_sessions_with_cancel_event
from unpivoted
group by 1, 2
order by 1, sessions desc;
