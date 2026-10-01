-- Funnel conversion by year, split into sessions with and without a user_id.
-- Shows that the upward trend in conversion comes from the mix of the two session types.
select
    extract(year from session_month) as session_year,
    count(*) as sessions,
    countif(is_identified_user) as identified_sessions,
    countif(not is_identified_user) as anonymous_sessions,
    round(countif(reached_purchase) / count(*), 4) as overall_conversion_rate,
    round(safe_divide(countif(reached_purchase and is_identified_user), countif(is_identified_user)), 4) as identified_conversion_rate,
    round(safe_divide(countif(reached_purchase and not is_identified_user), countif(not is_identified_user)), 4) as anonymous_conversion_rate
from fct_sessions
group by 1
order by 1;
