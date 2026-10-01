-- Order status distribution, and consistency between order-level and item-level fields.
with item_rollup as (
    select
        order_id,
        count(*) as item_rows,
        count(distinct status) as distinct_item_statuses,
        any_value(status) as item_status,
        min(created_at) as first_item_created_at,
        sum(sale_price) as item_revenue
    from `bigquery-public-data.thelook_ecommerce.order_items`
    group by order_id
)

select
    o.status,
    count(*) as orders,
    round(100 * count(*) / sum(count(*)) over (), 2) as pct_orders,
    round(sum(r.item_revenue), 2) as gross_item_value,
    countif(o.num_of_item != r.item_rows) as num_of_item_mismatch,
    countif(r.distinct_item_statuses > 1) as mixed_item_status_orders,
    countif(r.item_status != o.status) as item_status_differs_from_order,
    countif(o.shipped_at is null) as null_shipped_at,
    countif(o.delivered_at is null) as null_delivered_at,
    countif(o.returned_at is null) as null_returned_at,
    countif(o.shipped_at < o.created_at) as shipped_before_created,
    countif(o.delivered_at < o.shipped_at) as delivered_before_shipped,
    countif(o.returned_at < o.delivered_at) as returned_before_delivered
from `bigquery-public-data.thelook_ecommerce.orders` o
join item_rollup r on o.order_id = r.order_id
group by o.status
order by orders desc;
