-- Share of each yearly cohort placing a second valid order within 90, 180 and 365 days
-- of their first. Limited to customers with a full 365 days of follow-up so cohorts are comparable.
with first_orders as (
    select user_id, order_date as first_order_date
    from fct_orders
    where customer_order_number = 1
),

second_orders as (
    select user_id, order_date as second_order_date
    from fct_orders
    where customer_order_number = 2
),

as_of as (
    select max(order_date) as as_of_date from fct_orders
)

select
    extract(year from first_orders.first_order_date) as cohort_year,
    count(*) as customers,
    round(countif(date_diff(second_orders.second_order_date, first_orders.first_order_date, day) <= 90) / count(*), 4) as repeat_within_90_days,
    round(countif(date_diff(second_orders.second_order_date, first_orders.first_order_date, day) <= 180) / count(*), 4) as repeat_within_180_days,
    round(countif(date_diff(second_orders.second_order_date, first_orders.first_order_date, day) <= 365) / count(*), 4) as repeat_within_365_days
from first_orders
cross join as_of
left join second_orders
    on first_orders.user_id = second_orders.user_id
where first_orders.first_order_date <= date_sub(as_of.as_of_date, interval 365 day)
group by 1
order by 1;
