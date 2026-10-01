-- Yearly revenue, order and mix trend. 2026 is a partial year.
select
    extract(year from order_month) as order_year,
    count(*) as months_observed,
    round(sum(revenue), 2) as revenue,
    sum(orders) as orders,
    round(safe_divide(sum(revenue), sum(orders)), 2) as average_order_value,
    round(safe_divide(sum(returning_customer_revenue), sum(revenue)), 4) as returning_customer_revenue_share,
    round(safe_divide(sum(cancelled_value), sum(gross_order_value)), 4) as cancelled_value_share,
    round(safe_divide(sum(returned_value), sum(gross_order_value)), 4) as returned_value_share
from mart_monthly_revenue
group by 1
order by 1;
