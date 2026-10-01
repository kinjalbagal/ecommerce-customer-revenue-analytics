-- Category revenue, pricing, margin, leakage and repeat behaviour, with department rolled together.
select
    category,
    round(sum(revenue), 2) as revenue,
    round(sum(revenue) / sum(sum(revenue)) over (), 4) as share_of_revenue,
    sum(units_sold) as units_sold,
    round(sum(units_sold) / sum(sum(units_sold)) over (), 4) as share_of_units,
    round(safe_divide(sum(revenue), sum(units_sold)), 2) as average_unit_revenue,
    round(sum(gross_margin), 2) as gross_margin,
    round(safe_divide(sum(gross_margin), sum(revenue)), 4) as gross_margin_rate,
    round(safe_divide(sum(units_cancelled), sum(units_ordered)), 4) as cancellation_rate,
    round(safe_divide(sum(units_returned), sum(units_ordered)), 4) as return_rate,
    round(sum(gross_item_value) - sum(revenue), 2) as cancelled_and_returned_value,
    round(safe_divide(sum(first_order_customers_who_repeated), sum(first_order_customers)), 4) as first_order_repeat_rate
from mart_category_metrics
group by 1
order by revenue desc;
