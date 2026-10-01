{#
    Single definition of which order statuses count toward revenue.
    Cancelled orders were never fulfilled and Returned orders were refunded,
    so neither is counted. Processing and Shipped orders are counted because
    they are committed sales that have not been reversed.
#}
{% macro is_revenue_status(status_column) -%}
    {{ status_column }} not in ('Cancelled', 'Returned')
{%- endmacro %}
