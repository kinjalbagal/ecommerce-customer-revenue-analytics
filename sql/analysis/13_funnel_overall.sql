-- Session funnel: entrants per stage, stage-to-stage conversion, drop-off and overall conversion.
with periods as (
    select 'All time' as period, date '1900-01-01' as start_month
    union all
    select 'Trailing 12 months', date_sub(max(session_month), interval 11 month)
    from mart_funnel_summary
),

totals as (
    select
        periods.period,
        sum(sessions) as sessions,
        sum(product_view_sessions) as product_view_sessions,
        sum(cart_sessions) as cart_sessions,
        sum(purchase_sessions) as purchase_sessions,
        sum(cancel_sessions) as cancel_sessions
    from mart_funnel_summary
    inner join periods
        on mart_funnel_summary.session_month >= periods.start_month
    group by 1
),

stages as (
    select period, 1 as stage_order, 'Session' as stage, sessions as entrants, cast(null as int64) as previous_stage_entrants, sessions from totals
    union all
    select period, 2, 'Product view', product_view_sessions, sessions, sessions from totals
    union all
    select period, 3, 'Add to cart', cart_sessions, product_view_sessions, sessions from totals
    union all
    select period, 4, 'Purchase', purchase_sessions, cart_sessions, sessions from totals
)

select
    period,
    stage_order,
    stage,
    entrants,
    round(safe_divide(entrants, previous_stage_entrants), 4) as stage_conversion_rate,
    round(1 - safe_divide(entrants, previous_stage_entrants), 4) as stage_drop_off_rate,
    previous_stage_entrants - entrants as sessions_lost,
    round(safe_divide(entrants, sessions), 4) as conversion_from_session
from stages
order by period, stage_order;
