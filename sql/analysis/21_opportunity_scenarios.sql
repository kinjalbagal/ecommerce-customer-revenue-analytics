-- Estimated incremental revenue per scenario. Estimates, not realised revenue.
select
    scenario,
    relative_lift_in_reorder_rate,
    sum(eligible_customers) as eligible_customers,
    round(sum(eligible_customers * baseline_reorder_rate) / sum(eligible_customers), 4) as baseline_reorder_rate,
    round(any_value(expected_order_value), 2) as expected_order_value,
    round(sum(estimated_incremental_customers)) as estimated_incremental_customers,
    round(sum(estimated_incremental_revenue), 2) as estimated_incremental_revenue,
    round(sum(if(recency_band_order <= 365, estimated_incremental_revenue, 0)), 2) as estimated_incremental_revenue_last_365_days_only
from mart_opportunity_scenarios
group by 1, 2
order by relative_lift_in_reorder_rate;
