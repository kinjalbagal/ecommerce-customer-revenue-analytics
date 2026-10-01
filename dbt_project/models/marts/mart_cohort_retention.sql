-- Monthly acquisition cohorts: customers active (valid order placed) and revenue
-- in each month since their first valid order. One row per cohort month and month offset.
with customer_months as (
    select
        orders.user_id,
        customers.cohort_month,
        date_diff(orders.order_month, customers.cohort_month, month) as months_since_first_order,
        sum(orders.net_revenue) as revenue,
        count(*) as orders
    from {{ ref('fct_orders') }} as orders
    inner join {{ ref('dim_customers') }} as customers
        on orders.user_id = customers.user_id
    where orders.is_valid_order
    group by 1, 2, 3
),

cohort_sizes as (
    select cohort_month, count(*) as cohort_size
    from {{ ref('dim_customers') }}
    where cohort_month is not null
    group by cohort_month
),

as_of as (
    select max(order_month) as last_month from {{ ref('fct_orders') }}
),

-- Every cohort gets a row for every month it could have been observed,
-- so months with no returning customers appear as zero rather than missing.
grid as (
    select
        cohort_sizes.cohort_month,
        cohort_sizes.cohort_size,
        month_offset as months_since_first_order
    from cohort_sizes
    cross join as_of
    cross join unnest(generate_array(0, date_diff(as_of.last_month, cohort_sizes.cohort_month, month))) as month_offset
),

activity as (
    select
        cohort_month,
        months_since_first_order,
        count(distinct user_id) as active_customers,
        sum(orders) as orders,
        sum(revenue) as revenue
    from customer_months
    group by 1, 2
)

select
    grid.cohort_month,
    grid.months_since_first_order,
    grid.cohort_size,
    coalesce(activity.active_customers, 0) as active_customers,
    safe_divide(coalesce(activity.active_customers, 0), grid.cohort_size) as retention_rate,
    coalesce(activity.orders, 0) as orders,
    coalesce(activity.revenue, 0) as revenue
from grid
left join activity
    on grid.cohort_month = activity.cohort_month
    and grid.months_since_first_order = activity.months_since_first_order
