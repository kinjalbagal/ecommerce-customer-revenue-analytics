-- Distribution of valid orders per customer. Repeat Purchase Rate is the share with two or more.
select
    valid_orders,
    count(*) as customers,
    round(count(*) / sum(count(*)) over (), 4) as share_of_customers,
    round(sum(lifetime_revenue), 2) as revenue,
    round(sum(lifetime_revenue) / sum(sum(lifetime_revenue)) over (), 4) as share_of_revenue
from dim_customers
where valid_orders > 0
group by 1
order by 1;
