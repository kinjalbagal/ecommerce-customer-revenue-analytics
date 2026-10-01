-- Composite-key uniqueness for marts without a single-column primary key.
select 'mart_cohort_retention' as model, concat(cast(cohort_month as string), '|', cast(months_since_first_order as string)) as grain_key, count(*) as row_count
from {{ ref('mart_cohort_retention') }}
group by 2
having count(*) > 1
union all
select 'mart_category_metrics', concat(department, '|', category), count(*)
from {{ ref('mart_category_metrics') }}
group by 2
having count(*) > 1
union all
select 'mart_funnel_summary', concat(cast(session_month as string), '|', traffic_source, '|', browser, '|', department, '|', category), count(*)
from {{ ref('mart_funnel_summary') }}
group by 2
having count(*) > 1
union all
select 'mart_reorder_backtest', concat(backtest_window, '|', recency_band, '|', prior_order_group, '|', prior_spend_tier), count(*)
from {{ ref('mart_reorder_backtest') }}
group by 2
having count(*) > 1
union all
select 'mart_opportunity_scenarios', concat(backtest_window, '|', scenario, '|', recency_band), count(*)
from {{ ref('mart_opportunity_scenarios') }}
group by 2
having count(*) > 1
