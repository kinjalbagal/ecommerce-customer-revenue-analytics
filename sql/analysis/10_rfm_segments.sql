-- Size and value of each RFM segment.
with customers as (
    select
        *,
        -- Exact median; approx_quantiles can differ between runs.
        percentile_cont(recency_days, 0.5) over (partition by rfm_segment) as segment_median_recency_days
    from mart_customer_rfm
)

select
    rfm_segment,
    count(*) as customers,
    round(count(*) / sum(count(*)) over (), 4) as share_of_customers,
    round(sum(monetary), 2) as revenue,
    round(sum(monetary) / sum(sum(monetary)) over (), 4) as share_of_revenue,
    round(safe_divide(sum(monetary), sum(frequency)), 2) as average_order_value,
    round(avg(frequency), 2) as avg_orders,
    round(avg(monetary), 2) as avg_lifetime_revenue,
    any_value(segment_median_recency_days) as median_recency_days
from customers
group by 1
order by revenue desc;
