-- Cumulative revenue share by customer percentile (highest spenders first), for the concentration curve.
select
    customer_percentile,
    customers,
    round(revenue, 2) as revenue,
    round(cumulative_share_of_revenue, 4) as cumulative_share_of_revenue
from mart_revenue_concentration
order by customer_percentile;
