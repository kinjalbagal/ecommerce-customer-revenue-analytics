-- Observed 12-month reorder rate and next-order value, by how the customer looked a year before
-- the end of the data. Tests whether recency, order count or past spend predicts a reorder.
select 'Recency' as dimension, recency_band as segment, min(recency_band_order) as sort_order,
    sum(customers) as customers,
    round(safe_divide(sum(customers_who_reordered), sum(customers)), 4) as reorder_rate_12m,
    round(safe_divide(sum(revenue_next_12m), sum(orders_next_12m)), 2) as next_order_value,
    round(safe_divide(sum(revenue_next_12m), sum(customers)), 2) as revenue_per_customer_12m
from mart_reorder_backtest
group by 2
union all
select 'Prior orders', prior_order_group, if(prior_order_group = '1 order', 1, 2),
    sum(customers),
    round(safe_divide(sum(customers_who_reordered), sum(customers)), 4),
    round(safe_divide(sum(revenue_next_12m), sum(orders_next_12m)), 2),
    round(safe_divide(sum(revenue_next_12m), sum(customers)), 2)
from mart_reorder_backtest
group by 2
union all
select 'Prior spend', prior_spend_tier, if(prior_spend_tier like 'Top%', 1, 2),
    sum(customers),
    round(safe_divide(sum(customers_who_reordered), sum(customers)), 4),
    round(safe_divide(sum(revenue_next_12m), sum(orders_next_12m)), 2),
    round(safe_divide(sum(revenue_next_12m), sum(customers)), 2)
from mart_reorder_backtest
group by 2
union all
select 'All customers', 'All customers', 1,
    sum(customers),
    round(safe_divide(sum(customers_who_reordered), sum(customers)), 4),
    round(safe_divide(sum(revenue_next_12m), sum(orders_next_12m)), 2),
    round(safe_divide(sum(revenue_next_12m), sum(customers)), 2)
from mart_reorder_backtest
order by dimension, sort_order;
