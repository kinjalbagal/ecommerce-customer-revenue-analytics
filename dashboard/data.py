"""Cached loaders for the mart exports the dashboard reads.

The dashboard works from the CSVs in data/marts, which are exports of the dbt marts.
It needs no BigQuery connection and contains no transformation logic beyond filtering
and aggregating prepared columns.
"""
from pathlib import Path

import pandas as pd
import streamlit as st

MARTS = Path(__file__).resolve().parents[1] / "data" / "marts"


@st.cache_data
def load(table: str, date_columns: tuple[str, ...] = ()) -> pd.DataFrame:
    return pd.read_csv(MARTS / f"{table}.csv", parse_dates=list(date_columns))


def orders() -> pd.DataFrame:
    return load("fct_orders", ("order_date", "order_month"))


def monthly_revenue() -> pd.DataFrame:
    return load("mart_monthly_revenue", ("order_month",))


def customer_rfm() -> pd.DataFrame:
    return load("mart_customer_rfm")


def cohort_retention() -> pd.DataFrame:
    return load("mart_cohort_retention", ("cohort_month",))


def revenue_concentration() -> pd.DataFrame:
    return load("mart_revenue_concentration")


def funnel_summary() -> pd.DataFrame:
    return load("mart_funnel_summary", ("session_month",))


def category_metrics() -> pd.DataFrame:
    return load("mart_category_metrics")


def reorder_backtest() -> pd.DataFrame:
    return load("mart_reorder_backtest", ("snapshot_date", "outcome_end_date"))


def opportunity_scenarios() -> pd.DataFrame:
    return load("mart_opportunity_scenarios")
