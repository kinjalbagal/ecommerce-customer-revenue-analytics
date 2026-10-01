-- Event types: volume, session coverage, logged-in share, and typical position in a session.
select
    event_type,
    count(*) as events,
    count(distinct session_id) as sessions,
    countif(user_id is null) as events_without_user,
    round(avg(sequence_number), 2) as avg_sequence_number,
    min(sequence_number) as min_sequence_number,
    max(sequence_number) as max_sequence_number
from `bigquery-public-data.thelook_ecommerce.events`
group by event_type
order by events desc;
