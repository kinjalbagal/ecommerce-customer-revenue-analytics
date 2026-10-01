"""Shared chart styling and number formatting."""
import plotly.graph_objects as go
import streamlit as st

BLUE = "#2F5D8A"
LIGHT_BLUE = "#9DB8D2"
ORANGE = "#D9822B"
GREY = "#8C8C8C"


def usd(value: float) -> str:
    return f"${value:,.0f}"


def pct(value: float, decimals: int = 1) -> str:
    return f"{value:.{decimals}%}"


def show(fig: go.Figure, height: int = 420) -> None:
    fig.update_layout(
        template="simple_white",
        height=height,
        margin=dict(l=10, r=10, t=30, b=10),
        font=dict(size=13),
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="left", x=0),
    )
    st.plotly_chart(fig, width="stretch")
