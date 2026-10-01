-- Distribution of days between consecutive valid orders, and how quickly second orders arrive.
with gaps as (
    select customer_order_number, days_since_previous_order
    from fct_orders
    where customer_order_number > 1
)

select
    count(*) as repeat_orders,
    round(avg(days_since_previous_order), 1) as mean_days,
    approx_quantiles(days_since_previous_order, 100)[offset(25)] as p25_days,
    approx_quantiles(days_since_previous_order, 100)[offset(50)] as median_days,
    approx_quantiles(days_since_previous_order, 100)[offset(75)] as p75_days,
    approx_quantiles(days_since_previous_order, 100)[offset(90)] as p90_days,
    round(countif(days_since_previous_order <= 30) / count(*), 4) as share_within_30_days,
    round(countif(days_since_previous_order <= 90) / count(*), 4) as share_within_90_days,
    round(countif(days_since_previous_order <= 180) / count(*), 4) as share_within_180_days,
    round(countif(days_since_previous_order <= 365) / count(*), 4) as share_within_365_days
from gaps;
