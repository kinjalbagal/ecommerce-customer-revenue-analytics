-- Funnel conversion by product category over the trailing 12 months.
select
    category,
    sum(sessions) as sessions,
    round(safe_divide(sum(cart_sessions), sum(sessions)), 4) as view_to_cart_rate,
    round(safe_divide(sum(purchase_sessions), sum(cart_sessions)), 4) as cart_to_purchase_rate,
    round(safe_divide(sum(purchase_sessions), sum(sessions)), 4) as overall_conversion_rate
from mart_funnel_summary
where session_month >= (select date_sub(max(session_month), interval 11 month) from mart_funnel_summary)
group by 1
order by overall_conversion_rate desc;
