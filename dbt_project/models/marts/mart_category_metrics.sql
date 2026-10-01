-- Category performance. One row per department and category.
with items as (
    select * from {{ ref('fct_order_items') }}
),

category_totals as (
    select
        department,
        category,
        count(*) as units_ordered,
        countif(is_revenue_item) as units_sold,
        countif(status = 'Cancelled') as units_cancelled,
        countif(status = 'Returned') as units_returned,
        count(distinct if(is_revenue_item, order_id, null)) as orders,
        count(distinct if(is_revenue_item, user_id, null)) as customers,
        sum(gross_item_value) as gross_item_value,
        sum(net_revenue) as revenue,
        sum(gross_margin) as gross_margin
    from items
    group by 1, 2
),

-- Of the customers whose first valid order included the category, how many ordered again.
first_order_categories as (
    select distinct
        items.department,
        items.category,
        items.user_id
    from items
    inner join {{ ref('fct_orders') }} as orders
        on items.order_id = orders.order_id
    where orders.customer_order_number = 1
),

repeat_behaviour as (
    select
        first_order_categories.department,
        first_order_categories.category,
        count(*) as first_order_customers,
        countif(customers.valid_orders >= 2) as first_order_customers_who_repeated
    from first_order_categories
    inner join {{ ref('dim_customers') }} as customers
        on first_order_categories.user_id = customers.user_id
    group by 1, 2
)

select
    category_totals.*,
    safe_divide(category_totals.units_cancelled, category_totals.units_ordered) as cancellation_rate,
    safe_divide(category_totals.units_returned, category_totals.units_ordered) as return_rate,
    safe_divide(category_totals.revenue, category_totals.units_sold) as average_unit_revenue,
    safe_divide(category_totals.gross_margin, category_totals.revenue) as gross_margin_rate,
    repeat_behaviour.first_order_customers,
    repeat_behaviour.first_order_customers_who_repeated,
    safe_divide(
        repeat_behaviour.first_order_customers_who_repeated,
        repeat_behaviour.first_order_customers
    ) as first_order_repeat_rate
from category_totals
left join repeat_behaviour
    on category_totals.department = repeat_behaviour.department
    and category_totals.category = repeat_behaviour.category
