# Tableau Dashboard Specification

Four dashboards built from the CSV files in `tableau/data`. Connect each file as its own data source; no joins or relationships are needed. Column definitions are in `tableau/data/README.md`.

Conventions:

- Revenue means orders with status Complete, Shipped or Processing. Use the `net_revenue` / `revenue` columns as exported; do not recompute from status.
- Set the default number format of currency fields to `$#,##0` and of rates to `0.0%`.
- Colours: one blue for primary measures, a lighter blue for the comparison measure, orange only for lost value and for the highlighted scenario. No other colours.
- Titles state what the sheet shows. Numbers quoted in titles should be dynamic (insert the field) or omitted.

---

## Dashboard 1: Executive Overview

Question: how large is the business, how is it growing, and how much comes from returning customers?

### Layout

```
+---------------------------------------------------------------+
| Filter: Order Date (range)                                    |
+------------+------------+------------+-----------+------------+
| Revenue    | Orders     | Customers  | AOV       | Repeat     |
| (1.1)      | (1.1)      | (1.1)      | (1.1)     | Rate (1.1) |
+------------+------------+------------+-----------+------------+
| Monthly revenue, new vs returning (1.2)                       |
+-------------------------------+-------------------------------+
| Gross order value by status   | Returning share of revenue    |
| (1.3)                         | by month (1.4)                |
+-------------------------------+-------------------------------+
```

### Calculated fields (data source: `fct_orders.csv`)

| Name | Formula |
|---|---|
| Revenue | `SUM([Net Revenue])` |
| Orders | `SUM(IIF([Is Valid Order], 1, 0))` |
| Customers | `COUNTD(IIF([Is Valid Order], [User Id], NULL))` |
| AOV | `SUM([Net Revenue]) / SUM(IIF([Is Valid Order], 1, 0))` |
| Repeat Customer Flag | `{ FIXED [User Id] : SUM(IIF([Is Valid Order], 1, 0)) } >= 2` |
| Repeat Purchase Rate | `COUNTD(IIF([Is Valid Order] AND [Repeat Customer Flag], [User Id], NULL)) / COUNTD(IIF([Is Valid Order], [User Id], NULL))` |
| Counts Toward Revenue | `IIF([Is Valid Order], "Revenue", "Lost")` |
| Returning Revenue Share | `SUM(IIF([Customer Type] = "Returning", [Net Revenue], 0)) / SUM([Net Revenue])` |

`Repeat Customer Flag` uses FIXED, so it reflects lifetime orders and is not narrowed by the date filter unless the filter is added to context. Leave it out of context so the rate matches the KPI dictionary.

### Sheets

**1.1 KPI tiles** (five sheets, one per measure)
- Source: `fct_orders.csv`
- Chart type: text
- Marks: Text = `Revenue`, `Orders`, `Customers`, `AOV`, `Repeat Purchase Rate` respectively
- Filters: `Order Date`
- Answers: what is the current scale of the business?

**1.2 Monthly revenue, new vs returning**
- Source: `fct_orders.csv`
- Chart type: stacked bar
- Columns: `MONTH([Order Date])` (continuous)
- Rows: `Revenue`
- Marks: Color = `Customer Type`
- Filters: `Order Date`; `Is Valid Order` = True
- Answers: is growth coming from new or returning customers?

**1.3 Gross order value by status**
- Source: `fct_orders.csv`
- Chart type: horizontal bar
- Rows: `Status`, sorted by value descending
- Columns: `SUM([Gross Order Value])`
- Marks: Color = `Counts Toward Revenue`; Label = `SUM([Gross Order Value])` and a percent-of-total quick table calculation
- Filters: `Order Date`
- Answers: how much of what customers order is lost to cancellations and returns?

**1.4 Returning share of revenue by month**
- Source: `fct_orders.csv`
- Chart type: line
- Columns: `MONTH([Order Date])` (continuous)
- Rows: `Returning Revenue Share`
- Filters: `Order Date`; `Is Valid Order` = True
- Answers: is the business becoming more or less dependent on acquisition?

---

## Dashboard 2: Customer & Retention

Question: how do customers behave after their first order, and where is customer value concentrated?

### Layout

```
+-------------------------------+-------------------------------+
| Cohort retention heatmap (2.1)                                |
+-------------------------------+-------------------------------+
| RFM segments: customers and   | Segment revenue and AOV       |
| revenue share (2.2)           | table (2.3)                   |
+-------------------------------+-------------------------------+
| Revenue concentration curve   | Orders per customer (2.5)     |
| (2.4)                         |                               |
+-------------------------------+-------------------------------+
```

### Sheets

**2.1 Cohort retention heatmap**
- Source: `mart_cohort_retention.csv`
- Chart type: highlight table
- Columns: `Months Since First Order` (discrete)
- Rows: `MONTH([Cohort Month])` (discrete, month-year)
- Marks: Square; Color = `Cohort Retention`; Label = `Cohort Retention`
- Calculated field: `Cohort Retention` = `SUM([Active Customers]) / SUM([Cohort Size])`
- Filters: `Months Since First Order` between 1 and 12 (month 0 is always 100% and would wash out the colour scale); `Cohort Month` range, default last 24 months
- Answers: do customers come back, and does it differ by cohort?
- Note: because the calculation is a ratio of sums, changing Rows to `YEAR([Cohort Month])` gives a correctly pooled yearly view.

**2.2 RFM segments: share of customers and revenue**
- Source: `mart_customer_rfm.csv`
- Chart type: side-by-side horizontal bars
- Rows: `Rfm Segment`, sorted by revenue share
- Columns: `Measure Values` with `Share of Customers` and `Share of Revenue`
- Marks: Color = `Measure Names`
- Calculated fields:
  - `Share of Customers` = `COUNTD([User Id]) / TOTAL(COUNTD([User Id]))`
  - `Share of Revenue` = `SUM([Monetary]) / TOTAL(SUM([Monetary]))`
- Filters: `Country`, `Acquisition Source` (optional)
- Answers: which segments hold more revenue than their headcount?

**2.3 Segment detail table**
- Source: `mart_customer_rfm.csv`
- Chart type: text table
- Rows: `Rfm Segment`
- Measures: `COUNTD([User Id])`, `SUM([Monetary])`, `Segment AOV`, `AVG([Frequency])`, `MEDIAN([Recency Days])`
- Calculated field: `Segment AOV` = `SUM([Monetary]) / SUM([Frequency])`
- Filters: same as 2.2
- Answers: what does each segment look like?

**2.4 Revenue concentration curve**
- Source: `mart_revenue_concentration.csv`
- Chart type: line
- Columns: `Customer Percentile` (continuous dimension)
- Rows: `SUM([Cumulative Share Of Revenue])`
- Reference lines: constant at percentile 20; optional diagonal using calculated field `Equal Share` = `AVG([Customer Percentile]) / 100` on a dual axis
- Answers: how concentrated is revenue among top customers?

**2.5 Orders per customer**
- Source: `mart_customer_rfm.csv`
- Chart type: side-by-side bars
- Columns: `Frequency` (discrete)
- Rows: `Share of Customers`, `Share of Revenue` (from 2.2)
- Answers: how much revenue depends on repeat customers?

---

## Dashboard 3: Funnel & Product

Question: where do sessions drop out, and which categories drive revenue and loss?

### Layout

```
+---------------------------------------------------------------+
| Filters: Session Month (range), Traffic Source, Browser       |
+-------------------------------+-------------------------------+
| Funnel (3.1)                  | Conversion by traffic source  |
|                               | (3.2)                         |
+-------------------------------+-------------------------------+
| Category revenue share vs     | Category table: revenue,      |
| unit share (3.3)              | cancel and return rate (3.4)  |
+-------------------------------+-------------------------------+
```

### Calculated fields (data source: `mart_funnel_summary.csv`)

| Name | Formula |
|---|---|
| View to Cart Rate | `SUM([Cart Sessions]) / SUM([Product View Sessions])` |
| Cart to Purchase Rate | `SUM([Purchase Sessions]) / SUM([Cart Sessions])` |
| Overall Conversion | `SUM([Purchase Sessions]) / SUM([Sessions])` |
| Cart Drop-off | `1 - [Cart to Purchase Rate]` |

### Sheets

**3.1 Funnel**
- Source: `mart_funnel_summary.csv`
- Chart type: bar
- Columns: `Measure Names` (Product View Sessions, Cart Sessions, Purchase Sessions, in that order)
- Rows: `Measure Values`
- Marks: Label = value and percent of the first bar (table calculation: percent from first)
- Filters: `Session Month`, `Traffic Source`, `Browser`
- Answers: how many sessions reach each stage?
- Caption to include: "A purchase session corresponds to one order item. All-time conversion is lowered by anonymous sessions that are constant over time; use the Session Month filter to look at a recent period."

**3.2 Conversion by traffic source**
- Source: `mart_funnel_summary.csv`
- Chart type: bar
- Columns: `Traffic Source`
- Rows: `Overall Conversion`
- Marks: Label = `Overall Conversion`
- Filters: `Session Month`, `Browser`. A parameter can swap the column dimension between `Traffic Source`, `Browser` and `Category`.
- Answers: does conversion differ by segment?

**3.3 Category revenue share vs unit share**
- Source: `mart_category_metrics.csv`
- Chart type: scatter
- Columns: `Share of Units` = `SUM([Units Sold]) / TOTAL(SUM([Units Sold]))`
- Rows: `Share of Revenue` = `SUM([Revenue]) / TOTAL(SUM([Revenue]))`
- Marks: Detail = `Category`; Label = `Category`
- Filters: `Department`
- Answers: which categories earn more or less revenue than their volume suggests?

**3.4 Category table**
- Source: `mart_category_metrics.csv`
- Chart type: text table with bars on revenue
- Rows: `Category`, sorted by revenue
- Measures: `SUM([Revenue])`, `Cancellation Rate`, `Return Rate`, `Margin Rate`, `Lost Value`
- Calculated fields:
  - `Cancellation Rate` = `SUM([Units Cancelled]) / SUM([Units Ordered])`
  - `Return Rate` = `SUM([Units Returned]) / SUM([Units Ordered])`
  - `Margin Rate` = `SUM([Gross Margin]) / SUM([Revenue])`
  - `Lost Value` = `SUM([Gross Item Value]) - SUM([Revenue])`
- Filters: `Department`
- Answers: where is value lost by category, and how profitable is each?

---

## Dashboard 4: Revenue Opportunity

Question: which customers should a repeat-purchase programme target, and what could it be worth?

Every dollar figure on this dashboard except historical revenue is an estimate. Put "Estimated, based on assumed lift. Not realised revenue." in the dashboard subtitle.

### Layout

```
+---------------------------------------------------------------+
| Parameter: Scenario (Conservative / Base / Optimistic)        |
+-------------------------------+-------------------------------+
| Reorder rate by recency and   | Eligible one-time buyers by   |
| prior spend (4.1)             | recency band (4.2)            |
+-------------------------------+-------------------------------+
| Scenario estimates (4.3)      | Assumptions and recommended   |
|                               | action (4.4, text)            |
+-------------------------------+-------------------------------+
```

### Sheets

**4.1 Observed reorder rate by recency and prior spend**
- Source: `mart_reorder_backtest.csv`
- Chart type: side-by-side bars
- Columns: `Recency Band`, sorted by `MIN([Recency Band Order])`
- Rows: `Reorder Rate` = `SUM([Customers Who Reordered]) / SUM([Customers])`
- Marks: Color = `Prior Spend Tier`
- Filters: `Prior Order Group` (optional)
- Answers: what predicts a reorder: recency or past spend?

**4.2 Eligible one-time buyers by recency band**
- Source: `mart_opportunity_scenarios.csv`
- Chart type: bar with a line on a dual axis
- Columns: `Recency Band`, sorted by `MIN([Recency Band Order])`
- Rows: `SUM([Eligible Customers])` (bar), `AVG([Baseline Reorder Rate])` (line)
- Filters: `Scenario` = parameter value (eligible customers repeat on every scenario row, so exactly one scenario must be selected)
- Answers: how large is the target population and what is its observed baseline?

**4.3 Scenario estimates**
- Source: `mart_opportunity_scenarios.csv`
- Chart type: bar
- Columns: `Scenario`, sorted by `MIN([Relative Lift In Reorder Rate])`
- Rows: `SUM([Estimated Incremental Revenue])`
- Marks: Color highlights the scenario selected by the parameter; Label = `SUM([Estimated Incremental Revenue])`
- Filters: `Recency Band` (to restrict to recent buyers)
- Optional what-if: add a float parameter `Lift` and a calculated field `Custom Estimate` = `SUM([Eligible Customers] * [Baseline Reorder Rate] * [Expected Order Value]) * [Lift]`, applied with the `Scenario` filter set to a single scenario
- Answers: what would a given lift be worth?

**4.4 Assumptions and recommended action**
- Text object, not a sheet.
- Content: the model formula (`eligible customers x baseline reorder rate x relative lift x expected order value`); which inputs are observed (eligible customers, baseline rate, expected order value) and which are assumed (lift, one extra order per customer); the recommendation to target one-time buyers by recency and to test with a control group; a pointer to `docs/executive_summary.md`.
