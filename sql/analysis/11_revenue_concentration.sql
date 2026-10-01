-- Share of revenue contributed by the top N% of customers ranked by lifetime revenue.
with ranked as (
    select
        lifetime_revenue,
        row_number() over (order by lifetime_revenue desc, user_id) as revenue_rank,
        count(*) over () as customers
    from dim_customers
    where valid_orders > 0
)

select
    top_percent,
    countif(revenue_rank <= ceil(customers * top_percent / 100)) as customers_in_group,
    round(sum(if(revenue_rank <= ceil(customers * top_percent / 100), lifetime_revenue, 0)), 2) as revenue,
    round(sum(if(revenue_rank <= ceil(customers * top_percent / 100), lifetime_revenue, 0)) / sum(lifetime_revenue), 4) as share_of_revenue,
    round(min(if(revenue_rank <= ceil(customers * top_percent / 100), lifetime_revenue, null)), 2) as min_lifetime_revenue_in_group
from ranked
cross join unnest([1, 5, 10, 20, 50]) as top_percent
group by 1
order by 1;
