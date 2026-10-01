-- Reorder rate and next-order value by recency band and prior spend tier, for both backtest
-- windows. Checks whether lapsed high spenders behave differently from other lapsed customers.
select
    backtest_window,
    recency_band,
    prior_spend_tier,
    sum(customers) as customers,
    round(safe_divide(sum(avg_prior_revenue * customers), sum(customers)), 2) as avg_prior_revenue,
    round(safe_divide(sum(customers_who_reordered), sum(customers)), 4) as reorder_rate_12m,
    round(safe_divide(sum(revenue_next_12m), sum(orders_next_12m)), 2) as next_order_value
from mart_reorder_backtest
group by 1, 2, 3
order by backtest_window, min(recency_band_order), prior_spend_tier desc;
