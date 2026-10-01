-- Composite-key uniqueness for marts without a single-column primary key.
select 'mart_cohort_retention' as model, cast(cohort_month as string) as key_1, cast(months_since_first_order as string) as key_2, count(*) as n
from {{ ref('mart_cohort_retention') }}
group by 1, 2, 3
having count(*) > 1
union all
select 'mart_category_metrics', department, category, count(*)
from {{ ref('mart_category_metrics') }}
group by 1, 2, 3
having count(*) > 1
union all
select 'mart_opportunity_scenarios', scenario, recency_band, count(*)
from {{ ref('mart_opportunity_scenarios') }}
group by 1, 2, 3
having count(*) > 1
