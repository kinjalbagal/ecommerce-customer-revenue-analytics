-- Sensitivity of the reorder backtest and the opportunity estimates to the final-month
-- spike in order volume. Compares the original outcome window with one that ends a month earlier.
with windows as (
    select distinct backtest_window, snapshot_date, outcome_end_date
    from mart_reorder_backtest
),

backtest as (
    select
        backtest_window,
        sum(customers) as customers,
        safe_divide(sum(customers_who_reordered), sum(customers)) as reorder_rate_all_customers,
        safe_divide(sum(if(prior_order_group = '1 order', customers_who_reordered, 0)),
            sum(if(prior_order_group = '1 order', customers, 0))) as reorder_rate_one_order_customers,
        safe_divide(sum(if(recency_band = '0-90 days', customers_who_reordered, 0)),
            sum(if(recency_band = '0-90 days', customers, 0))) as reorder_rate_0_90_days,
        safe_divide(sum(if(recency_band = 'Over 730 days', customers_who_reordered, 0)),
            sum(if(recency_band = 'Over 730 days', customers, 0))) as reorder_rate_over_730_days,
        safe_divide(sum(if(prior_spend_tier like 'Top%', customers_who_reordered, 0)),
            sum(if(prior_spend_tier like 'Top%', customers, 0))) as reorder_rate_top_spend_tier,
        safe_divide(sum(if(prior_spend_tier like 'Bottom%', customers_who_reordered, 0)),
            sum(if(prior_spend_tier like 'Bottom%', customers, 0))) as reorder_rate_bottom_spend_tier,
        safe_divide(sum(if(prior_spend_tier like 'Top%', revenue_next_12m, 0)),
            sum(if(prior_spend_tier like 'Top%', orders_next_12m, 0))) as next_order_value_top_spend_tier,
        safe_divide(sum(if(prior_spend_tier like 'Bottom%', revenue_next_12m, 0)),
            sum(if(prior_spend_tier like 'Bottom%', orders_next_12m, 0))) as next_order_value_bottom_spend_tier
    from mart_reorder_backtest
    group by 1
),

scenarios as (
    select
        backtest_window,
        safe_divide(sum(if(scenario = 'Base', eligible_customers * baseline_reorder_rate, 0)),
            sum(if(scenario = 'Base', eligible_customers, 0))) as weighted_baseline_one_time_buyers,
        any_value(expected_order_value) as expected_order_value,
        sum(if(scenario = 'Conservative', estimated_incremental_revenue, 0)) as estimate_conservative,
        sum(if(scenario = 'Base', estimated_incremental_revenue, 0)) as estimate_base,
        sum(if(scenario = 'Optimistic', estimated_incremental_revenue, 0)) as estimate_optimistic
    from mart_opportunity_scenarios
    group by 1
)

select
    windows.backtest_window,
    windows.snapshot_date,
    windows.outcome_end_date,
    backtest.customers,
    round(backtest.reorder_rate_all_customers, 4) as reorder_rate_all_customers,
    round(backtest.reorder_rate_one_order_customers, 4) as reorder_rate_one_order_customers,
    round(backtest.reorder_rate_0_90_days, 4) as reorder_rate_0_90_days,
    round(backtest.reorder_rate_over_730_days, 4) as reorder_rate_over_730_days,
    round(backtest.reorder_rate_top_spend_tier, 4) as reorder_rate_top_spend_tier,
    round(backtest.reorder_rate_bottom_spend_tier, 4) as reorder_rate_bottom_spend_tier,
    round(backtest.next_order_value_top_spend_tier, 2) as next_order_value_top_spend_tier,
    round(backtest.next_order_value_bottom_spend_tier, 2) as next_order_value_bottom_spend_tier,
    round(scenarios.weighted_baseline_one_time_buyers, 4) as weighted_baseline_one_time_buyers,
    round(scenarios.expected_order_value, 2) as expected_order_value,
    round(scenarios.estimate_conservative, 2) as estimate_conservative,
    round(scenarios.estimate_base, 2) as estimate_base,
    round(scenarios.estimate_optimistic, 2) as estimate_optimistic
from windows
inner join backtest on windows.backtest_window = backtest.backtest_window
inner join scenarios on windows.backtest_window = scenarios.backtest_window
order by windows.backtest_window desc;
