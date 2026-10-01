# E-commerce Customer & Revenue Analytics

An end-to-end analysis of an online apparel retailer's orders, customers and web sessions, built on Google's public TheLook eCommerce dataset with BigQuery, dbt and SQL.

## Business Problem

Where is e-commerce revenue being lost, which customer segments represent the largest opportunity to increase repeat revenue, and what actions should the business prioritise?

The data covers 124,814 orders from 100,000 registered users between January 2019 and September 2026, with 2.4 million web events. TheLook is a synthetic dataset; the limitations that follow from that are listed at the end.

## Key Findings

All figures are calculated from the data. Detail and sources are in [analysis/findings.md](analysis/findings.md).

- **24.7% of gross order value is lost to cancellations (15.1%) and returns (9.6%)**: $1,085,610 in the trailing 12 months against $3,306,214 of revenue. The rates barely move by year or by product category.
- **69.9% of customers have bought once.** The 30.1% who returned generate 50.4% of revenue at the same $86 average order value.
- **Repeat orders are slow**: the median gap between a customer's orders is 240 days.
- **Revenue is moderately concentrated**: the top 20% of customers account for 52.5% of revenue, not 80%.
- **Recency predicts a reorder; past spend does not.** In a 12-month backtest the reorder rate fell from 24.2% (last order within 90 days) to 11.4% (over two years ago), while high and low past spenders reordered at 17.1% and 15.8% with nearly identical order values.
- **The funnel loses 37% of sessions before cart and 58% of carts before purchase** (all time), with no difference between traffic sources, browsers or categories.

![Reorder rate by recency and prior spend](images/11_reorder_rate_by_recency_and_spend.png)

## Business Recommendation

1. Run a second-purchase programme for one-time buyers, selected by recency and not by past spend. Start with the 18,636 whose only order was in the last 365 days, and reach new buyers within 90 days of their first order.
2. Measure the lift with a control group before scaling.
3. Start recording why orders are cancelled and returned. It is the largest loss in the data and cannot currently be diagnosed.

The lapsed high-spend segment that an RFM table would usually point to holds 24.9% of historical revenue, but the backtest shows those customers are no more likely to return and spend no more when they do. The full argument is in [docs/executive_summary.md](docs/executive_summary.md).

## Analytics Architecture

```mermaid
flowchart LR
    A[TheLook eCommerce] --> B[BigQuery]
    B --> C[dbt]
    C --> D[Analytics marts]
    D --> E[SQL analysis]
    E --> F[Plotly figures +<br/>Tableau-ready exports]
    F --> G[Business recommendation]
```

dbt builds staging, intermediate and mart layers in BigQuery. Analysis queries read only the marts. Figures are generated from the query outputs and mart exports, with no transformation logic of their own. See [docs/architecture.md](docs/architecture.md).

## Data Model

```mermaid
erDiagram
    dim_customers ||--o{ fct_orders : places
    fct_orders ||--|{ fct_order_items : contains
    dim_products ||--o{ fct_order_items : "sold as"
    dim_customers |o--o{ fct_sessions : "identified in"
    dim_products ||--o{ fct_sessions : "viewed in"
```

| Model | Grain |
|---|---|
| `fct_orders` | One row per order |
| `fct_order_items` | One row per order item (one unit) |
| `fct_sessions` | One row per web session |
| `dim_customers` | One row per registered user |
| `dim_products` | One row per product |

Eight reporting marts sit on top of these: monthly revenue, cohort retention, RFM, revenue concentration, funnel summary, category metrics, a reorder backtest and the opportunity scenarios. The project has 21 models, one seed and 83 data tests, including a test that revenue is identical at item, order, customer, month and category grain.

## KPI Definitions

Revenue counts orders with status Complete, Shipped or Processing; Cancelled and Returned orders are excluded. The rule is defined once in a dbt macro and used everywhere. A customer is a user with at least one such order. All metric definitions, with SQL logic, grain and assumptions, are in [analysis/kpi_dictionary.md](analysis/kpi_dictionary.md).

## Customer & Retention Analysis

Customers are assigned to the month of their first valid order. Monthly retention is in the low single digits and flat within a cohort. The share of a cohort placing a second order within a year rises from 8.3% (2019) to 22.5% (2025), though part of that reflects how the dataset concentrates orders near its end date.

![Cohort retention](images/04_cohort_retention_heatmap.png)

RFM scores use quintiles for recency and monetary value and the raw order count for frequency, since no customer has more than four orders. Seven segments are defined; High-Value At Risk and Champions each hold about a quarter of historical revenue.

![RFM segments](images/06_rfm_segments.png)

## Funnel Analysis

The events support a product view, add to cart, purchase funnel measured per session. Conversion is flat across every available dimension. The gap between all-time and recent conversion is a mix effect: anonymous sessions, which never purchase, are constant over time while purchasing sessions grow.

![Session funnel](images/08_session_funnel.png)

## Revenue Opportunity

These are scenario estimates built on an assumed lift. They are not realised revenue.

Estimated incremental revenue = eligible one-time buyers (46,097, observed) x baseline 12-month reorder rate (15.6%, observed) x relative lift (assumed) x expected order value ($85.78, observed).

| Scenario | Assumed relative lift | Estimated incremental revenue, 12 months |
|---|---|---|
| Conservative | 5% | $30,840 |
| Base | 10% | $61,681 |
| Optimistic | 20% | $123,361 |

Assumptions are in [dbt_project/seeds/scenario_assumptions.csv](dbt_project/seeds/scenario_assumptions.csv); changing them and rebuilding recalculates the scenarios.

## Visualizations

Twelve Plotly figures are in [images/](images) as PNG and [figures/html/](figures/html) as interactive HTML.

| Figure | Question it answers |
|---|---|
| 01 Monthly revenue, new vs returning | Is growth coming from new or returning customers? |
| 02 Gross order value by status | How much is lost to cancellations and returns? |
| 03 Orders per customer | How much revenue depends on repeat customers? |
| 04 Cohort retention heatmap | Do customers come back, and does it differ by cohort? |
| 05 Second-order rate by cohort | How quickly do cohorts place a second order? |
| 06 RFM segments | Which segments hold more revenue than their headcount? |
| 07 Revenue concentration | How concentrated is revenue among top customers? |
| 08 Session funnel | Where do sessions drop out? |
| 09 Conversion by segment | Does conversion differ by traffic source or browser? |
| 10 Category revenue vs units | Which categories earn more than their volume suggests? |
| 11 Reorder rate by recency and spend | What predicts a reorder? |
| 12 Opportunity scenarios | What could a second-purchase programme be worth? |

Mart tables for a Tableau Public dashboard are exported to [tableau/data/](tableau/data), with a four-dashboard build specification in [tableau/dashboard_spec.md](tableau/dashboard_spec.md).

## Tech Stack

- Google BigQuery (public dataset `bigquery-public-data.thelook_ecommerce`)
- dbt Core with the BigQuery adapter
- SQL
- Python: pandas, Plotly, kaleido, google-cloud-bigquery

## Repository Structure

```
.
├── README.md
├── requirements.txt
├── dbt_project/
│   ├── models/            staging, intermediate, marts
│   ├── macros/            revenue rule, recency bands
│   ├── seeds/             scenario assumptions
│   └── tests/             singular data tests
├── sql/
│   ├── profiling/         source data profiling queries
│   └── analysis/          analysis queries against the marts
├── scripts/               query runner and CSV export
├── analysis/
│   ├── findings.md
│   ├── kpi_dictionary.md
│   ├── data_quality.md
│   └── outputs/           one CSV per query
├── figures/
│   ├── make_figures.py
│   └── html/
├── images/                PNG figures
├── tableau/
│   ├── data/              mart exports
│   └── dashboard_spec.md
└── docs/
    ├── executive_summary.md
    ├── architecture.md
    └── interview_guide.md
```

## Reproducing the Analysis

Requires Python 3.10+, the Google Cloud CLI, a Google Cloud project with BigQuery enabled (the free sandbox is enough), and Chrome for PNG export.

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

gcloud auth application-default login
export GCP_PROJECT_ID=your-project-id

cd dbt_project
cp profiles.example.yml profiles.yml
dbt build --profiles-dir .
cd ..

python scripts/run_sql.py
python scripts/export_tableau_data.py
python figures/make_figures.py
```

TheLook is regenerated daily, so a rebuild will produce different numbers from those documented here, which describe the snapshot of 2026-09-30. The committed CSVs in `analysis/outputs` and `tableau/data` are that snapshot.

## Limitations

- The dataset is synthetic. Behaviour is uniform across channels, categories and countries in ways real data would not be.
- Order volume is concentrated near the end of the data, which raises any rate measured over the most recent 12 months, including the reorder baseline.
- The opportunity scenarios rest on an assumed lift. No campaign or experiment data exists to validate it.
- Revenue includes Processing and Shipped orders, some of which will later be cancelled or returned.
- There is no cost, discount, or cancellation and return reason data.
- Purchase sessions correspond to order items, not orders, and identified sessions always convert, so the funnel cannot be split by customer type or reconciled to orders.
- The recommendations are what the analysis suggests. Nothing was implemented or tested in a real business.

Data quality observations are documented in [analysis/data_quality.md](analysis/data_quality.md).
