-- One row per order, with the customer's purchase sequence among valid orders.
with orders as (
    select * from {{ ref('int_orders_valued') }}
),

valid_sequence as (
    select
        order_id,
        row_number() over (partition by user_id order by ordered_at, order_id) as customer_order_number,
        lag(ordered_at) over (partition by user_id order by ordered_at, order_id) as previous_ordered_at
    from orders
    where is_valid_order
)

select
    orders.order_id,
    orders.user_id,
    orders.status,
    orders.ordered_at,
    date(orders.ordered_at) as order_date,
    date_trunc(date(orders.ordered_at), month) as order_month,
    orders.is_valid_order,
    orders.item_count,
    orders.gross_order_value,
    orders.net_revenue,
    orders.gross_margin,
    -- Null for cancelled and returned orders, which are not part of the purchase sequence.
    valid_sequence.customer_order_number,
    case
        when valid_sequence.customer_order_number = 1 then 'New'
        when valid_sequence.customer_order_number > 1 then 'Returning'
    end as customer_type,
    date_diff(date(orders.ordered_at), date(valid_sequence.previous_ordered_at), day) as days_since_previous_order
from orders
left join valid_sequence
    on orders.order_id = valid_sequence.order_id
