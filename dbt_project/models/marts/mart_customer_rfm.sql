-- RFM scores and segments for customers with at least one valid order.
-- Recency and monetary are scored by quintile. Frequency is scored on the actual
-- order count because the maximum is four orders, so quintiles would be meaningless.
with customers as (
    select
        user_id,
        country,
        acquisition_source,
        days_since_last_order as recency_days,
        valid_orders as frequency,
        lifetime_revenue as monetary,
        average_order_value,
        avg_days_between_orders,
        last_order_at
    from {{ ref('dim_customers') }}
    where valid_orders > 0
),

scored as (
    select
        *,
        ntile(5) over (order by recency_days desc, user_id) as recency_score,
        ntile(5) over (order by monetary, user_id) as monetary_score,
        least(frequency, 3) as frequency_score
    from customers
)

select
    *,
    case
        when frequency >= 2 and recency_score >= 4 and monetary_score >= 4 then 'Champions'
        when frequency >= 2 and recency_score >= 3 then 'Loyal'
        when recency_score <= 2 and monetary_score >= 4 then 'High-Value At Risk'
        when recency_score <= 2 and frequency >= 2 then 'At Risk'
        when recency_score = 5 then 'New Customers'
        when recency_score >= 3 then 'Potential Loyalists'
        else 'Lapsed'
    end as rfm_segment
from scored
