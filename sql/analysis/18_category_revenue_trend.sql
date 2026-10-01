-- Category revenue in the trailing 12 months against the 12 months before, to find categories
-- growing slower or faster than the business as a whole.
with bounds as (
    select max(order_month) as last_month from fct_order_items
),

windowed as (
    select
        items.category,
        sum(if(items.order_month > date_sub(bounds.last_month, interval 12 month), items.net_revenue, 0)) as revenue_trailing_12m,
        sum(if(items.order_month <= date_sub(bounds.last_month, interval 12 month)
            and items.order_month > date_sub(bounds.last_month, interval 24 month), items.net_revenue, 0)) as revenue_prior_12m
    from fct_order_items as items
    cross join bounds
    group by 1
)

select
    category,
    round(revenue_trailing_12m, 2) as revenue_trailing_12m,
    round(revenue_prior_12m, 2) as revenue_prior_12m,
    round(safe_divide(revenue_trailing_12m, revenue_prior_12m) - 1, 4) as revenue_growth,
    round(safe_divide(sum(revenue_trailing_12m) over (), sum(revenue_prior_12m) over ()) - 1, 4) as total_revenue_growth
from windowed
order by revenue_growth desc;
