-- Size of the cancellation and return leak in the trailing 12 months, and what one
-- percentage point of gross order value is worth. The one-point figure is a
-- sensitivity, not a forecast.
select
    round(sum(gross_order_value), 2) as gross_order_value,
    round(sum(if(status = 'Cancelled', gross_order_value, 0)), 2) as cancelled_value,
    round(sum(if(status = 'Returned', gross_order_value, 0)), 2) as returned_value,
    round(safe_divide(sum(if(status = 'Cancelled', gross_order_value, 0)), sum(gross_order_value)), 4) as cancelled_value_share,
    round(safe_divide(sum(if(status = 'Returned', gross_order_value, 0)), sum(gross_order_value)), 4) as returned_value_share,
    round(sum(gross_order_value) * 0.01, 2) as value_of_one_point_of_gross_order_value
from fct_orders
where order_date > (select date_sub(max(order_date), interval 365 day) from fct_orders);
