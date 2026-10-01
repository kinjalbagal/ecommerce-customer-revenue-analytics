# Interview Guide

A walkthrough of the project and the questions it is likely to raise. Answers reflect what was actually built and found.

## The project in one pass

**Problem.** Where is revenue being lost, which customer segments offer the largest opportunity to increase repeat revenue, and what should be prioritized?

**Data.** Google's public TheLook eCommerce dataset in BigQuery: 100,000 users, 124,814 orders, 180,771 order items, 29,120 products and 2.4 million web events, January 2019 to September 2026. It is synthetic and regenerated daily; the analysis uses the snapshot of 2026-09-30.

**Modeling.** A dbt project with three layers. Staging has one model per source table. Intermediate holds shared logic: the revenue rule applied to order items, order value, and session funnel flags. Marts hold three facts (orders, order items, sessions), two dimensions (customers, products) and eight reporting marts. 21 models, one seed, 96 data tests.

**Analysis.** 25 SQL queries against the marts covering KPIs, revenue leakage, cohorts, RFM, concentration, the funnel, categories, a reorder backtest, scenarios and a sensitivity test. Each writes a CSV; figures are drawn from those CSVs, and a four-page Streamlit dashboard reads the mart exports.

**Finding.** A quarter of gross order value is cancelled or returned, uniformly. 69.9% of customers buy once, and the 30.1% who return generate 50.4% of revenue. Recency predicts a reorder (23.1% falling to 11.4%); past spend does not.

**Recommendation.** A second-purchase program for one-time buyers, selected by recency, tested with a control group. Separately, start capturing cancellation and return reasons.

**Estimated opportunity.** $30,622, $61,245 and $122,489 over 12 months for 5%, 10% and 20% relative lifts in the reorder rate of 46,097 one-time buyers. These are estimates on an assumed lift. The baseline excludes September 2026, whose order volume is anomalous; including it gives $30,840, $61,681 and $123,361.

**Limitations.** Synthetic data with uniform behavior, order volume concentrated near the end date, an assumed lift, no cost or reason data, and a funnel that cannot be tied to orders.

## Questions and answers

### dbt

**Why three layers?**
Staging isolates the source: renames, type-safe parsing, dropping personal fields. If the source changes, only staging changes. Intermediate holds logic used by more than one mart, so it is written once; the revenue rule is applied in `int_order_items_enriched` and nowhere else. Marts are what analysts and BI tools query.

**Why is staging materialized as tables rather than views?**
Two reasons specific to this source. TheLook is regenerated daily, so views would let different models read different versions of the data within one analysis. And the events table is the only large one; a table means it is scanned once per build rather than by every downstream query.

**How is the revenue definition kept consistent?**
A macro, `is_revenue_status`, returns `status not in ('Cancelled', 'Returned')`. It is called in the intermediate layer to produce `is_valid_order` and `net_revenue`. Every mart, query and figure reads those columns. A singular test checks that revenue is identical at item, order, customer, month and category grain.

**What is the seed for?**
`scenario_assumptions.csv` holds the assumed lift for each scenario. Keeping assumptions in a seed separates them from observed data, makes them visible in version control, and means changing a number and running `dbt build` recalculates the scenarios.

**Which tests did you write and why?**
Generic tests on every primary key (`unique`, `not_null`), `relationships` between facts and dimensions, and `accepted_values` on status and other categorical fields that business rules depend on. Five singular tests cover things generic tests cannot: revenue reconciliation across grains, funnel stages never increasing, one product per session (the category funnel depends on it), composite-key uniqueness, and cohort month zero equal to cohort size.

**Did any test tell you something?**
The one-product-per-session test encodes a property found during profiling. If a future refresh broke it, the category funnel would silently become wrong, so the build fails instead.

### BigQuery

**How did you control cost?**
Staging selects only the columns used; from events that leaves out IP address, city, state and postal code. Everything downstream reads the materialized staging tables. Both the dbt profile and the Python client set `maximum_bytes_billed` to 5 GB per query. The whole project runs in the free sandbox.

**How do the analysis queries find the tables?**
The runner sets a default dataset on the query job, so the SQL files use unqualified names like `fct_orders` and stay portable across projects.

**Any BigQuery-specific SQL?**
`countif`, `safe_divide`, `percentile_cont` for exact medians, `generate_array` with `unnest` to build the cohort grid, `date_trunc` and `date_diff` for cohort offsets, and `regexp_extract` to parse the product id from the event URI.

### Dimensional modeling, facts and dimensions, grain

**What are the facts and dimensions?**
`fct_orders` (one row per order), `fct_order_items` (one row per unit) and `fct_sessions` (one row per session) record events. `dim_customers` and `dim_products` describe the entities involved. Facts hold measures and foreign keys; dimensions hold attributes to filter and group by.

**Why two order facts?**
Different grains answer different questions. Order grain is needed for AOV, order counts and purchase sequence. Item grain is needed for category and product analysis. Aggregating the item fact by category and then counting orders would double count orders with items in several categories, so each question uses the fact at the right grain.

**`dim_customers` has lifetime revenue on it. Is that still a dimension?**
It is a dimension with aggregate attributes. Lifetime order count and revenue describe the customer and are used to segment. They are not additive across other dimensions and are not summed alongside the order fact.

**Why can't sessions be joined to orders?**
The source has no key between them. Profiling showed there is one purchase session per order item, and item timestamps differ from order timestamps by up to four days, so a join on user and time is unreliable. The funnel is kept as its own fact and reported as a session-level rate.

**How do you state the grain of a model?**
One sentence in the model description and a uniqueness test on the key that defines it. For composite grains, such as cohort month by month offset, a singular test checks uniqueness.

### SQL decisions

**How is a customer's order sequence calculated?**
`row_number()` over valid orders partitioned by user and ordered by timestamp, with order id as a tie-breaker so the result is deterministic. Cancelled and returned orders are excluded from the sequence, so a customer whose first order was cancelled is "New" on their first valid order.

**How do you avoid double counting?**
Revenue is computed at item grain and rolled up; joins from orders to items are never summed back at order grain without grouping. Marts with distinct counts (customers per month, customers per category) are documented as non-additive. The reconciliation test would catch a fan-out.

**Why `ntile` for RFM and not fixed thresholds?**
Quintiles adapt to the actual distribution and give equal-sized groups. A tie-breaker on `user_id` makes the assignment deterministic. The resulting boundaries are reported so the scores can be interpreted.

### Data quality

**What did profiling find?**
Keys and relationships are clean. The material findings were behavioral: item timestamps drift from order timestamps; purchase sessions map to order items; identified sessions always purchase and anonymous ones never do; anonymous traffic is constant over time while orders grow; and order volume is concentrated in the final months. Each one changed a modeling or interpretation decision. They are listed in `analysis/data_quality.md`.

**How did you handle the events dated after the last order?**
1,843 purchase sessions belong to items stamped after the latest order. Dropping only the late events would have left those sessions looking like abandoned carts, so the whole sessions are excluded in `int_session_funnel`.

**What did you not test?**
Checks with no decision attached. For example, product name nulls (2 rows) are filled in staging and not tested, because nothing depends on the name.

### Metric definitions

**Which statuses count as revenue and why?**
Complete, Shipped and Processing. Cancelled orders were never fulfilled and Returned orders were refunded. Processing and Shipped are included because excluding them would drop about half of recent orders; the cost is that recent revenue is slightly overstated, since some will later be cancelled or returned. That is stated as a limitation.

**What is the repeat purchase rate?**
Customers with two or more valid orders divided by customers with at least one: 19,872 of 65,969, or 30.1%. It is a lifetime measure, so recent customers pull it down.

**Why is the return rate denominator all units ordered?**
For consistency with the cancellation rate, so the two add up to the share of ordered value that is lost. A returns team would more likely use delivered units; the dictionary states which is used.

### Cohort retention

**How are cohorts defined?**
By the month of a customer's first valid order. Retention at month N is the share of the cohort with a valid order in the calendar month N months later.

**How do you handle cohorts that have not been observed for long?**
The mart only generates month offsets up to the last month in the data, so unobserved cells are absent, not zero. When comparing cohorts on "second order within 365 days", only customers with a full 365 days of follow-up are included.

**What did the cohorts show?**
Retention is low and flat, about 1% a month for early cohorts and 2 to 3% for 2025 cohorts, with no early peak. The 12-month second-order rate rises from 8.3% for 2019 to 22.5% for 2025.

**Is the improvement real?**
Partly an artefact. Orders are concentrated near the end of the data, so any cohort whose window overlaps 2026 picks up more orders. The direction is reported; it is not presented as the business improving.

### RFM

**How were thresholds chosen?**
Recency and monetary by quintile of the observed distributions. Frequency by raw order count capped at 3, because 70% of customers have one order and the maximum is four; quintiles would split identical customers arbitrarily.

**How are segments assigned?**
An ordered `case` expression, so the segments are mutually exclusive and exhaustive. An `accepted_values` and a `not_null` test confirm every customer gets exactly one of the seven.

**What did RFM get wrong?**
It ranks High-Value At Risk as the top reactivation target. The backtest showed past spend does not predict either reorder probability or next order value in this data. RFM describes history; it needed to be checked against outcomes before acting on it.

### Funnel methodology

**How was the funnel defined?**
From the observed session paths. Every session has a product view; `home` and `department` are optional; `cancel` is an exit. So the stages are product view, add to cart, purchase. A stage counts only if it happens after the previous one, using sequence numbers.

**Users or sessions?**
Sessions. Anonymous sessions have no user id, so a user-level funnel would exclude 500,000 of 680,000 sessions.

**What is the denominator?**
For stage conversion, sessions that reached the previous stage. For overall conversion, all sessions. Rates are always ratios of summed counts, never averages of rates.

**Why does conversion go from 26% all-time to 53% recently?**
Mix. Anonymous sessions never purchase and are constant at about 64,000 a year. Identified sessions always purchase and grow with orders. Blended conversion rises mechanically. This is shown in `16_funnel_by_year.csv` and reported as an artefact.

**What could the funnel not tell you?**
Which segment to fix, because conversion is the same across traffic source, browser and category, and whether new or returning customers convert differently, because only purchasers are identified.

### Revenue concentration

**Does the data follow 80/20?**
No. The top 20% of customers account for 52.5% of revenue, the top 10% for 33.9%, the top 1% for 6.4%. It takes about half the customers to reach 80%.

**Why is concentration low?**
No customer has more than four orders and order values sit in a narrow range, so there are no very large accounts.

**How was it calculated?**
Customers ranked by lifetime revenue with `row_number()`, with the top N% defined as rank at or below `ceil(customers x N / 100)`. The curve uses `ntile(100)` and a running sum.

### Scenario analysis

**How was the opportunity chosen?**
By testing the obvious candidate first. The reorder backtest took customers as they stood at a snapshot date (2025-08-31) and followed them for a year. Recency predicted reordering; past spend did not. One-time buyers are 70% of customers, and a second order raises the chance of a third from 15.1% to 19.7%, so they are the larger and better-supported target.

**What is observed and what is assumed?**
Observed: 46,097 eligible customers, a baseline reorder rate by recency band, and an expected order value of $86.34. Assumed: the relative lift (5%, 10%, 20%) and one extra order per reactivated customer.

**Why a relative lift rather than percentage points?**
It keeps the estimate proportional to each band's baseline, so recently active customers, who are more likely to respond, contribute more. It also avoids implying that a long-lapsed group could gain the same absolute uplift as a recent one.

**Why is the estimate small?**
The base case is 1.9% of trailing-12-month revenue. A 10% relative lift on a 15.4% baseline is about 1.5 points across 46,097 customers at $86 an order. The analysis does not inflate it. It also shows that one point of cancellations is worth about $43,900, a similar size.

**What would make the estimate wrong?**
The lift is unvalidated. The baseline may still be above a steady-state level, because order volume rises steeply through the whole final year and not only in September. Costs and discounts are excluded. Follow-on orders are excluded, which works in the other direction.

**What did you do about the September 2026 spike?**
September has 9,956 orders against 5,621 in August, so a backtest ending on 2026-09-30 could count an anomalous month as reorders. The backtest mart produces two windows: the original, and one shifted back a month to end on 2026-08-31, still 365 days long. The baseline for one-time buyers moves from 15.6% to 15.4% and the estimates fall by 0.7%. The recency gradient and the absence of a spend effect are the same in both. The adjusted window is the one reported, and the original is kept in the mart and the findings for comparison.

**How would you validate it?**
A randomized holdout: withhold the program from a control group of eligible one-time buyers and compare 12-month reorder rates.

### Dashboard

**How is the dashboard built?**
A Streamlit app with four pages (Executive Overview, Customer & Retention, Funnel & Product Performance, Revenue Opportunity) using Plotly charts. It reads the mart CSVs in `data/marts`, so it runs without a database connection.

**Where does the business logic live?**
In dbt. The app filters and aggregates prepared columns such as `net_revenue`, `is_valid_order` and the funnel stage counts. It does not redefine revenue, re-derive funnel stages or rescore RFM. The lift sliders on the opportunity page rescale the estimates that `mart_opportunity_scenarios` already computed.

**How does the repeat purchase rate respond to the date filter?**
It is the share of customers with a valid order in the selected period who had placed two or more valid orders by their latest order in it. With no filter this equals the lifetime figure of 30.1%.

**Why does the funnel page default to the last 12 months?**
All-time conversion is dominated by the mix of anonymous and identified sessions. A recent window is closer to a like-for-like view, and the caption explains the mix effect.

### Visualization choices

| Figure | Chart type | Why |
|---|---|---|
| Monthly revenue, new vs returning | Stacked bar over time | Shows total and composition together; two categories stack cleanly |
| Gross order value by status | Horizontal bar, sorted | Five categories compared on one measure; color separates kept from lost |
| Orders per customer | Grouped bar | Puts share of customers next to share of revenue for each order count |
| Cohort retention | Heatmap | The standard way to read a cohort by period matrix; month 0 is excluded so color is not dominated by 100% |
| Second-order rate by cohort | Line | A trend across ordered cohorts for three windows |
| RFM segments | Grouped horizontal bar | Long segment names; compares headcount share with revenue share |
| Revenue concentration | Cumulative curve with a diagonal | Shows the whole distribution and distance from equal spend, with the top-N points marked |
| Session funnel | Grouped bar by stage | Stage values with exact labels; avoids the distorted areas of a funnel shape |
| Conversion by segment | Bar | The point is that the bars are the same height |
| Category revenue vs units | Scatter with a diagonal | Two shares per category; distance from the line shows price effect |
| Reorder rate by recency and spend | Grouped bar | Shows the slope across recency and the lack of a gap between spend tiers |
| Opportunity scenarios | Bar | Three scenario values, labeled with the assumption |
| Final-month sensitivity | Grouped bar | Original and adjusted reorder rates side by side for each recency band |

Each title states the takeaway and takes its numbers from the data at run time, so titles cannot drift from the figures.

### Questions about judgment

**What would you do differently with real data?**
Check whether the flat results hold; in real data channel and category usually differ. Use a survival model for time to second order. Define revenue with a settled-order window. Bring in cost data so the recommendation can be stated in margin.

**What is the single most important thing you learned from the data?**
That the segment an RFM table points to was not supported when tested against outcomes. Checking a descriptive segmentation against what customers went on to do changed the recommendation.
