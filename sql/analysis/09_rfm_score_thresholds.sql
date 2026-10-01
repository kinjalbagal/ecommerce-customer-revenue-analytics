-- Value ranges behind each RFM score, taken from the scored customers.
select 'recency_days' as dimension, recency_score as score, count(*) as customers,
    cast(min(recency_days) as float64) as min_value, cast(max(recency_days) as float64) as max_value
from mart_customer_rfm
group by 2
union all
select 'monetary_usd', monetary_score, count(*), round(min(monetary), 2), round(max(monetary), 2)
from mart_customer_rfm
group by 2
union all
select 'frequency_orders', frequency_score, count(*), min(frequency), max(frequency)
from mart_customer_rfm
group by 2
order by dimension, score;
