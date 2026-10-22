# Pampa Gear · SQL Analysis

I answered 26 business questions with SQL on two years of data from Pampa Gear, a fictional US online store that sells rugby equipment to consumers, clubs and schools.

**Tools:** SQL (SQLite) · joins, CTEs, CASE, subqueries and window functions (RANK, DENSE_RANK, LAG, running totals)

## Key findings

### Late deliveries: Prairie Express at 40%
Prairie Express ships 40% of orders late, almost 4x more than FastFreight (10%). Moving volume away from it is the fastest way to improve delivery times. *(q16)*

### Billing gaps: $43.9K uncollected, $19.5K overcharged
46 delivered orders were never paid, leaving $43.9K uncollected, and 23 orders were charged twice for a total of $19.5K that should be refunded. *(q24)*

### Customer concentration: top 62 customers = 95% of revenue
62 high-value customers, those who spent $5,000 or more, generate 95% of delivered revenue. *(q13)*

### Retention: 66% of the 2024 cohort repurchased
66% of the customers who first bought in 2024 came back and bought again in 2025. *(q25)*

### Category mix: Training 30%, Footwear 29%
Training is the top category with 30% of delivered revenue, just ahead of Footwear (29%). *(q20)*

## Data

| Table | Rows | What it contains |
|---|---:|---|
| `customers` | 160 | Consumers, clubs and schools in 13 US states |
| `orders` | 2,071 | Orders from 2024 and 2025 with status, channel, carrier and dates |
| `order_items` | 4,166 | Order lines: quantity, price and discount |
| `products` | 30 | 5 categories, with price and cost |
| `shippers` | 3 | Carriers |
| `payments` | 1,841 | Payments received, including missing and duplicate ones |

Revenue counts delivered orders only: `quantity * unit_price * (1 - discount)`.

## Featured query: billing vs. payments reconciliation

I compared what was billed with what was collected for every delivered order and flagged three types of issues.

```sql
WITH billed AS (
  SELECT o.order_id, SUM(i.quantity * i.unit_price * (1 - i.discount)) AS billed
  FROM order_items i
  JOIN orders o ON o.order_id = i.order_id
  WHERE o.status = 'Delivered'
  GROUP BY o.order_id
), paid AS (
  SELECT order_id, SUM(amount) AS paid, COUNT(*) AS n
  FROM payments
  GROUP BY order_id
)
SELECT b.order_id,
       ROUND(b.billed, 2) AS billed,
       ROUND(COALESCE(p.paid, 0), 2) AS paid,
       CASE WHEN p.order_id IS NULL THEN 'No payment'
            WHEN p.n > 1 THEN 'Duplicate charge'
            ELSE 'Amount mismatch' END AS issue
FROM billed b
LEFT JOIN paid p ON p.order_id = b.order_id
WHERE p.order_id IS NULL OR p.n > 1 OR ABS(ROUND(b.billed, 2) - p.paid) > 0.01;
```

## All 26 queries

Every query is in [`pampa-gear-analysis.sql`](pampa-gear-analysis.sql), from basic filters to window functions:

| | Business question |
|---|---|
| q1–q8 | Catalog, customers by state, missing emails, order status mix |
| q9–q16 | Revenue by category and customer, customers who never ordered, spend tiers, late deliveries by carrier |
| q17–q22 | Month-over-month change, best product per category, running totals, category share, second most expensive product |
| q23–q26 | Duplicate payments, billing reconciliation, 2024 cohort retention, average order value by segment and channel |

## What I learned

The hardest part was not the syntax but the grain: after joining orders with order lines, `COUNT(*)` counts lines, not orders. I used `COUNT(DISTINCT order_id)` or aggregated per order first in a CTE.
