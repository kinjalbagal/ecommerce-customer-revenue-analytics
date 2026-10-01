-- Monthly retention at selected month offsets, pooled by cohort year.
-- Only cohorts that have reached the offset contribute to it.
select
    extract(year from cohort_month) as cohort_year,
    months_since_first_order,
    count(*) as cohorts_observed,
    sum(cohort_size) as cohort_customers,
    sum(active_customers) as active_customers,
    round(safe_divide(sum(active_customers), sum(cohort_size)), 4) as retention_rate,
    round(safe_divide(sum(revenue), sum(cohort_size)), 2) as revenue_per_cohort_customer
from mart_cohort_retention
where months_since_first_order in (1, 3, 6, 12, 24)
group by 1, 2
order by 2, 1;
