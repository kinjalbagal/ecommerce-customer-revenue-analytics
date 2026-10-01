-- Every customer is active in their own cohort month by definition.
select *
from {{ ref('mart_cohort_retention') }}
where months_since_first_order = 0
    and active_customers != cohort_size
