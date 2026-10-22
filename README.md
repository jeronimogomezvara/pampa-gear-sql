# SQL analysis: 26 business questions

**Tools:** SQL

## What I did

I answered 26 business questions with SQL on a two-year e-commerce database, using joins, CTEs, CASE and window functions.

## Findings

1. Delivery Issue: Prairie Express ships 40% of orders late, almost 4x more than FastFreight (10%). Moving volume away from it is the fastest way to improve delivery times.
2. Billing gaps: 46 delivered orders were never paid, leaving $43.9K uncollected, and 23 orders were charged twice for a total of $19.5K that should be refunded.
3. Top-tier customers: 62 high-value customers, those who spent $5,000 or more, generate 95% of delivered revenue.
4. Retention: 66% of the customers who first bought in 2024 came back and bought again in 2025.
5. Category performance: Training is the top category with 30% of delivered revenue, just ahead of Footwear (29%).

## What I learned

The hardest part was not the syntax but the grain: after a join, COUNT(*) counts order lines, not orders.

---

Part of my data analyst training with Pampa Gear, a fictional US online store selling rugby equipment (2024 to 2025 data).
