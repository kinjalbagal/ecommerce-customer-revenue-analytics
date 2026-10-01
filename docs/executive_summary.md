# Executive Summary

## Business Problem

An online apparel retailer wants to know where revenue is being lost, which customers offer the largest opportunity to increase repeat revenue, and what to prioritize. The analysis uses Google's public TheLook eCommerce dataset (synthetic), covering 124,814 orders from 100,000 registered users between January 2019 and September 2026.

**Revenue definition.** Complete, Shipped and Processing orders count toward revenue. Cancelled and Returned orders do not. Processing and Shipped orders are included because they are committed sales that have not been reversed; some of them may subsequently be cancelled or returned.

## Key Findings

All figures are observed results from the analysis outputs.

1. **A quarter of what customers order never becomes revenue.** In the trailing 12 months, 15.1% of gross order value was cancelled and 9.6% returned: $1,085,610 lost against $3,306,214 of revenue. The rates are almost identical in every year and every product category.
2. **Most customers buy once.** 69.9% of the 65,969 customers have a single valid order. The 30.1% who came back generate 50.4% of revenue, at the same average order value ($86).
3. **Repeat orders are slow.** The median gap between orders is 240 days. Monthly cohort retention is in the low single digits.
4. **Revenue is not concentrated in a small elite.** The top 20% of customers account for 52.5% of revenue, and no customer has more than four orders.
5. **Recency predicts a reorder; past spend does not.** In a 12-month backtest, customers who had bought in the previous 90 days reordered at 23.1%, falling to 11.4% for those inactive over two years. High and low past spenders reordered at nearly the same rate (16.8% and 15.7%) and at the same order value ($86).
6. **The funnel loses sessions evenly.** 37% of sessions never add to cart and 58% of carts do not purchase (all time), but conversion is the same across traffic sources, browsers and categories, so the funnel does not point to a specific fix.

## Interpretation

Revenue growth has come from acquiring first-time buyers, not from customers returning. Order value is stable at about $86, so a customer's value is determined almost entirely by how many times they order.

The usual reactivation target, lapsed customers with high historical spend, holds 24.9% of historical revenue but does not behave differently from other lapsed customers going forward. Their high spend reflects one expensive purchase, not a habit. Targeting by past spend would direct effort at customers who are no more likely to return and no more valuable when they do.

What does matter is time since the last order. The probability of a reorder falls steadily as a customer goes quiet, and a customer who places a second order is more likely to place a third (19.7% against 15.1%).

## Recommendation

1. **Run a second-purchase program for one-time buyers, prioritized by recency.** Start with the 18,636 customers whose only order was in the last 365 days, and contact new buyers within the first 90 days after their order, when the reorder rate is highest. Select on recency, not on past spend.
2. **Test before scaling.** Hold out a control group so the lift is measured, not assumed. The scenario below depends entirely on an assumed lift that this dataset cannot validate.
3. **Start capturing why orders are cancelled and returned.** This is the largest loss in the data and currently cannot be diagnosed: there is no reason field and no variation by category, channel or time. Each percentage point of gross order value is worth about $43,900 a year, the same order of magnitude as the whole base repeat-purchase scenario.
4. **Do not prioritize funnel work by channel or category on this evidence.** Conversion is flat across every available dimension.

## Estimated Opportunity

These are scenario estimates, not realized results.

Estimated incremental revenue over 12 months = eligible one-time buyers x observed baseline reorder rate x assumed relative lift x observed expected order value.

| Scenario | Assumed relative lift in reorder rate | Estimated incremental revenue | From buyers active in the last 365 days |
|---|---|---|---|
| Conservative | 5% | $30,622 | $16,401 |
| Base | 10% | $61,245 | $32,801 |
| Optimistic | 20% | $122,489 | $65,603 |

Observed inputs: 46,097 eligible customers, a baseline 12-month reorder rate of 15.4% (10.8% to 22.4% by recency band), and an expected order value of $86.34. Assumptions: the lift percentages, and one additional order per reactivated customer. The base estimate equals 1.9% of trailing-12-month revenue.

The estimate excludes program costs, any discount given, and the follow-on value of a customer who goes on to a third order.

### Sensitivity to the September 2026 spike

September 2026 has 9,956 orders against 5,621 in August, a property of the synthetic data. Because a spike at the end of the outcome window could inflate the reorder baseline, the backtest was run twice: once with the outcome window ending 2026-09-30 and once ending 2026-08-31. The figures above use the second, which leaves the spike out.

| | Window ending 2026-09-30 | Window ending 2026-08-31 (used) |
|---|---|---|
| Baseline reorder rate, one-time buyers | 15.6% | 15.4% |
| Expected order value | $85.78 | $86.34 |
| Conservative / Base / Optimistic | $30,840 / $61,681 / $123,361 | $30,622 / $61,245 / $122,489 |

The estimates fall by 0.7%. Recency remains the strongest predictor and past spend remains uninformative in both windows, so the recommendation does not change.

## Limitations

- **Synthetic data.** TheLook is generated, not recorded. Behavior is uniform across segments in ways real data would not be, which is why channel, category and geography show no differences.
- **Order volume grows steeply toward the end of the data.** Excluding the final month removes the September spike, but the months before it are also rising quickly, so reorder rates measured over the most recent year are likely higher than a steady-state business would show.
- **The lift is assumed.** No campaign or experiment data exists. The scenarios show what a given lift would be worth, not what lift is achievable.
- **Revenue includes orders still in progress.** Processing and Shipped orders count as revenue, and some may subsequently be cancelled or returned.
- **No cost, discount or reason data.** Profitability of a program, price sensitivity, and the causes of cancellations and returns cannot be assessed.
- **The funnel is limited.** Purchase sessions map to order items, not orders, and identified sessions always convert, so the funnel cannot be split by customer type or tied to orders.
- **Hypothetical context.** The recommendations are what the analysis suggests for a business with this data. Nothing here was implemented or tested in a real company.
