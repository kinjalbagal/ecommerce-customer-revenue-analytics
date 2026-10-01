"""E-commerce Customer & Revenue Analytics dashboard.

Run from the repository root:  streamlit run dashboard/app.py
"""
import streamlit as st

from views import customers, executive, funnel, opportunity

st.set_page_config(page_title="E-commerce Customer & Revenue Analytics", layout="wide")

pages = [
    st.Page(executive.render, title="Executive Overview", url_path="executive", default=True),
    st.Page(customers.render, title="Customer & Retention", url_path="customers"),
    st.Page(funnel.render, title="Funnel & Product Performance", url_path="funnel"),
    st.Page(opportunity.render, title="Revenue Opportunity", url_path="opportunity"),
]
page = st.navigation(pages)

st.sidebar.caption("Source: TheLook eCommerce (synthetic), snapshot of 2026-09-30.")
page.run()
