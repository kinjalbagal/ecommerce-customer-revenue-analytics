-- Eligible one-time buyers, observed baseline and base-scenario estimate by recency band,
-- for both backtest windows.
select
    backtest_window,
    recency_band,
    eligible_customers,
    round(baseline_reorder_rate, 4) as baseline_reorder_rate,
    round(expected_order_value, 2) as expected_order_value,
    round(estimated_incremental_customers, 1) as estimated_incremental_customers,
    round(estimated_incremental_revenue, 2) as estimated_incremental_revenue
from mart_opportunity_scenarios
where scenario = 'Base'
order by backtest_window, recency_band_order;
