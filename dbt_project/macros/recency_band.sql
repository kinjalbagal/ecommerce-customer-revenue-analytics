{# Recency bands shared by the reorder backtest and the opportunity scenarios. #}
{% macro recency_band(days_column) -%}
    case
        when {{ days_column }} <= 90 then '0-90 days'
        when {{ days_column }} <= 180 then '91-180 days'
        when {{ days_column }} <= 365 then '181-365 days'
        when {{ days_column }} <= 730 then '366-730 days'
        else 'Over 730 days'
    end
{%- endmacro %}
