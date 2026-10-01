-- Estimated incremental revenue from lifting the reorder rate of one-time buyers.
-- Everything here except the eligible customer count, baseline rate and expected order
-- value is an assumption taken from the scenario_assumptions seed.
-- One row per backtest window, scenario and recency band.
with eligible as (
    select
        {{ recency_band('days_since_last_order') }} as recency_band,
        count(*) as eligible_customers
    from {{ ref('dim_customers') }}
    where valid_orders = 1
    group by 1
),

baseline as (
    select
        backtest_window,
        recency_band,
        min(recency_band_order) as recency_band_order,
        safe_divide(sum(customers_who_reordered), sum(customers)) as baseline_reorder_rate
    from {{ ref('mart_reorder_backtest') }}
    where prior_order_group = '1 order'
    group by 1, 2
),

-- Past spend did not predict the value of the next order in the backtest,
-- so one expected order value is used for every band.
expected_value as (
    select
        backtest_window,
        safe_divide(sum(revenue_next_12m), sum(orders_next_12m)) as expected_order_value
    from {{ ref('mart_reorder_backtest') }}
    where prior_order_group = '1 order'
    group by 1
)

select
    baseline.backtest_window,
    scenarios.scenario,
    scenarios.relative_lift_in_reorder_rate,
    eligible.recency_band,
    baseline.recency_band_order,
    eligible.eligible_customers,
    baseline.baseline_reorder_rate,
    expected_value.expected_order_value,
    eligible.eligible_customers
        * baseline.baseline_reorder_rate
        * scenarios.relative_lift_in_reorder_rate as estimated_incremental_customers,
    eligible.eligible_customers
        * baseline.baseline_reorder_rate
        * scenarios.relative_lift_in_reorder_rate
        * expected_value.expected_order_value as estimated_incremental_revenue
from eligible
inner join baseline
    on eligible.recency_band = baseline.recency_band
inner join expected_value
    on baseline.backtest_window = expected_value.backtest_window
cross join {{ ref('scenario_assumptions') }} as scenarios
