-- Distribution of days between consecutive valid orders, and how quickly repeat orders arrive.
with gaps as (
    select
        days_since_previous_order,
        -- Exact percentiles; approx_quantiles can differ between runs.
        percentile_cont(days_since_previous_order, 0.25) over () as p25_days,
        percentile_cont(days_since_previous_order, 0.5) over () as median_days,
        percentile_cont(days_since_previous_order, 0.75) over () as p75_days,
        percentile_cont(days_since_previous_order, 0.9) over () as p90_days
    from fct_orders
    where customer_order_number > 1
)

select
    count(*) as repeat_orders,
    round(avg(days_since_previous_order), 1) as mean_days,
    any_value(p25_days) as p25_days,
    any_value(median_days) as median_days,
    any_value(p75_days) as p75_days,
    any_value(p90_days) as p90_days,
    round(countif(days_since_previous_order <= 30) / count(*), 4) as share_within_30_days,
    round(countif(days_since_previous_order <= 90) / count(*), 4) as share_within_90_days,
    round(countif(days_since_previous_order <= 180) / count(*), 4) as share_within_180_days,
    round(countif(days_since_previous_order <= 365) / count(*), 4) as share_within_365_days
from gaps;
