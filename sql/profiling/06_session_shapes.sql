-- Sessions grouped by the ordered path of event types they contain.
-- Shows which funnel stages the event data actually supports.
with session_paths as (
    select
        session_id,
        string_agg(event_type, ' > ' order by sequence_number) as event_path,
        count(*) as events,
        count(distinct user_id) as distinct_users,
        logical_or(user_id is null) as has_anonymous_event,
        count(distinct traffic_source) as distinct_traffic_sources
    from `bigquery-public-data.thelook_ecommerce.events`
    group by session_id
)

select
    regexp_replace(event_path, r'(product > cart > )+', '(product > cart)+ > ') as path_shape,
    count(*) as sessions,
    round(100 * count(*) / sum(count(*)) over (), 2) as pct_sessions,
    min(events) as min_events,
    max(events) as max_events,
    countif(has_anonymous_event) as anonymous_sessions,
    countif(distinct_users > 1) as multi_user_sessions,
    countif(distinct_traffic_sources > 1) as multi_source_sessions
from session_paths
group by path_shape
order by sessions desc
limit 25;
