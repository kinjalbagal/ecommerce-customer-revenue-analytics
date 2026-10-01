-- Size and value of each RFM segment.
select
    rfm_segment,
    count(*) as customers,
    round(count(*) / sum(count(*)) over (), 4) as share_of_customers,
    round(sum(monetary), 2) as revenue,
    round(sum(monetary) / sum(sum(monetary)) over (), 4) as share_of_revenue,
    round(safe_divide(sum(monetary), sum(frequency)), 2) as average_order_value,
    round(avg(frequency), 2) as avg_orders,
    round(avg(monetary), 2) as avg_lifetime_revenue,
    approx_quantiles(recency_days, 2)[offset(1)] as median_recency_days
from mart_customer_rfm
group by 1
order by revenue desc;
