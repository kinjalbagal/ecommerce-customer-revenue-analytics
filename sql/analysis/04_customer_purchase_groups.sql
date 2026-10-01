-- Registered users by purchase behaviour, and the revenue each group accounts for.
select
    purchase_group,
    count(*) as users,
    round(count(*) / sum(count(*)) over (), 4) as share_of_users,
    round(sum(lifetime_revenue), 2) as revenue,
    round(sum(lifetime_revenue) / sum(sum(lifetime_revenue)) over (), 4) as share_of_revenue,
    round(safe_divide(sum(lifetime_revenue), sum(valid_orders)), 2) as average_order_value,
    round(safe_divide(sum(lifetime_revenue), count(*)), 2) as revenue_per_user,
    countif(total_orders_placed = 0) as users_who_never_ordered,
    countif(total_orders_placed > 0 and valid_orders = 0) as users_with_only_cancelled_or_returned_orders
from dim_customers
group by 1
order by 1;
