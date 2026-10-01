-- One row per registered user, with lifetime purchase metrics based on valid orders.
with order_summary as (
    select
        user_id,
        count(*) as total_orders_placed,
        countif(is_valid_order) as valid_orders,
        countif(status = 'Cancelled') as cancelled_orders,
        countif(status = 'Returned') as returned_orders,
        sum(net_revenue) as lifetime_revenue,
        sum(gross_order_value) as lifetime_gross_order_value,
        min(if(is_valid_order, ordered_at, null)) as first_order_at,
        max(if(is_valid_order, ordered_at, null)) as last_order_at,
        avg(days_since_previous_order) as avg_days_between_orders
    from {{ ref('fct_orders') }}
    group by user_id
),

as_of as (
    select max(date(ordered_at)) as as_of_date from {{ ref('fct_orders') }}
)

select
    users.user_id,
    users.age,
    users.gender,
    users.country,
    users.acquisition_source,
    users.signed_up_at,
    coalesce(order_summary.total_orders_placed, 0) as total_orders_placed,
    coalesce(order_summary.valid_orders, 0) as valid_orders,
    coalesce(order_summary.cancelled_orders, 0) as cancelled_orders,
    coalesce(order_summary.returned_orders, 0) as returned_orders,
    coalesce(order_summary.lifetime_revenue, 0) as lifetime_revenue,
    coalesce(order_summary.lifetime_gross_order_value, 0) as lifetime_gross_order_value,
    safe_divide(order_summary.lifetime_revenue, order_summary.valid_orders) as average_order_value,
    order_summary.first_order_at,
    order_summary.last_order_at,
    date_trunc(date(order_summary.first_order_at), month) as cohort_month,
    date_diff(as_of.as_of_date, date(order_summary.last_order_at), day) as days_since_last_order,
    order_summary.avg_days_between_orders,
    case
        when coalesce(order_summary.valid_orders, 0) = 0 then 'No valid order'
        when order_summary.valid_orders = 1 then 'One-time'
        else 'Repeat'
    end as purchase_group
from {{ ref('stg_users') }} as users
cross join as_of
left join order_summary
    on users.user_id = order_summary.user_id
