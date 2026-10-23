-- Pampa Gear: SQL analysis
-- Author: Jeronimo Gomez Vara · 2026-10-22
-- Engine: SQLite. Revenue counts delivered orders only: quantity * unit_price * (1 - discount).

-- q1 · Explore the product catalog
select *
from products;

-- q2 · Products over $60, most expensive first
select product_name, unit_price
from products
where unit_price > 60 
order by unit_price desc;

-- q3 · Protection and footwear between $20 and $100
select product_name, category, unit_price from products
where category in ('Protection', 'Footwear')
and unit_price between 20 and 100;

-- q4 · Customers whose name ends in RFC
SELECT customer_name, state
FROM customers
WHERE customer_name LIKE '%RFC';

-- q5 · Customers per state
SELECT state, COUNT(*)
FROM customers
GROUP BY state;

-- q6 · States with more than 10 customers
SELECT state, COUNT (*)
FROM customers
GROUP BY state
HAVING COUNT (*) > 10
ORDER BY COUNT(*) desc;

-- q7 · Customers missing an email
SELECT COUNT(*) 
FROM customers
WHERE email IS NULL;

-- q8 · Orders by status and share of total
SELECT status, 
        COUNT (*) AS orders,
        ROUND (100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 1) AS pct
FROM orders
GROUP BY status;

-- q9 · Total delivered revenue
SELECT ROUND(SUM(i.quantity * i.unit_price * (1 - i.discount)), 2) as revenue
FROM order_items i
JOIN orders o 
ON o.order_id = i.order_id
WHERE o.status = 'Delivered';

-- q10 · Revenue by category
SELECT p.category,
       ROUND(SUM(i.quantity * i.unit_price * (1 - i.discount)), 2) AS revenue
FROM order_items i
JOIN orders o ON o.order_id = i.order_id
JOIN products p ON p.product_id = i. product_id
WHERE o.status = 'Delivered'
GROUP BY p.category
ORDER BY revenue DESC;

-- q11 · Top 5 customers by revenue
SELECT c.customer_name AS Customer,
       ROUND(SUM(i.quantity * i.unit_price * (1 - i.discount)), 2) AS revenue
FROM order_items i
JOIN orders o ON o.order_id = i.order_id
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'Delivered'
GROUP BY c.customer_id, c.customer_name
ORDER BY 2 DESC LIMIT 5;

-- q12 · Customers who never ordered
SELECT c.customer_id, c.customer_name
FROM customers c 
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- q13 · Customer tiers by total spend
WITH spend AS (
  SELECT o.customer_id, SUM(i.quantity * i.unit_price * (1 - i.discount)) AS total
  FROM order_items i
  JOIN orders o ON o.order_id = i.order_id
  WHERE o.status = 'Delivered'
  GROUP BY o.customer_id
)
SELECT CASE WHEN total >= 5000 THEN 'Alto'
            WHEN total >= 1000 THEN 'Medio'
            ELSE 'Bajo' END AS tier,
       COUNT(*) AS customers
FROM spend
GROUP BY tier;

-- q14 · Orders by year and channel
SELECT strftime('%Y', order_date) AS year, channel, 
        COUNT (*)
FROM orders
GROUP BY year, channel;

-- q15 · Products priced above average
SELECT product_name, unit_price
FROM products 
WHERE unit_price > (SELECT AVG(unit_price)
                    FROM products)
ORDER BY unit_price asc;

-- q16 · Late shipment rate by carrier
SELECT s.shipper_name,
       COUNT (*) AS shipped,
       SUM(CASE WHEN o.ship_date > o.required_date THEN 1 ELSE 0 END) AS late,
       ROUND(100.0 * SUM (CASE WHEN o.ship_date > o.required_date THEN 1 ELSE 0 END) / COUNT(*), 1) AS perct_late
FROM orders o 
JOIN shippers s ON s.shipper_id = o.shipper_id
WHERE o.ship_date IS NOT NULL
GROUP BY s.shipper_name
ORDER BY perct_late DESC;

-- q17 · Monthly revenue and month-over-month change
WITH monthly AS (
  SELECT strftime('%Y-%m', o.order_date) AS month,
          SUM(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
  FROM order_items i 
  JOIN orders o ON o.order_id = i.order_id
  WHERE status = 'Delivered'
  GROUP BY month
)
SELECT month, 
       ROUND(revenue, 2) AS revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
            / LAG(revenue) OVER (ORDER BY month), 1) AS perct_change
FROM monthly
ORDER BY month;

-- q18 · Top product in each category
WITH by_product AS (
     SELECT p.category, p.product_name, SUM(i.quantity * i.unit_price * (1-i.discount)) AS revenue
     FROM order_items i
     JOIN orders o ON o.order_id = i.order_id
     JOIN products p On p.product_id = i.product_id
     WHERE o.status = 'Delivered'
     GROUP BY p.category, p.product_name
), ranked AS (
   SELECT *, RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rank
   FROM by_product
)
SELECT category, product_name, ROUND(revenue, 2) AS revenue
FROM ranked
WHERE rank = 1;

-- q19 · 2025 running revenue total
WITH monthly AS (
  SELECT strftime('%Y-%m', o.order_date) AS month,
          SUM(i.quantity * i.unit_price * (1 - i.discount)) AS revenue
  FROM order_items i 
  JOIN orders o ON o.order_id = i.order_id
  WHERE status = 'Delivered' 
        AND o.order_date >= '2025-01-01'
  GROUP BY month
)
SELECT month,
       ROUND(revenue, 2)AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month), 2)AS running_total
FROM monthly
ORDER BY month;

-- q20 · Revenue share by category
WITH cat AS( 
  SELECT p.category,
       ROUND(SUM(i.quantity * i.unit_price * (1 - i.discount)), 2) AS revenue
  FROM order_items i
  JOIN orders o ON o.order_id = i.order_id
  JOIN products p ON p.product_id = i. product_id
  WHERE o.status = 'Delivered'
  GROUP BY p.category
)
SELECT Category, 
  ROUND(100.0 * revenue / SUM(revenue) OVER (), 1)AS category_perct_of_total
FROM cat
ORDER BY category_perct_of_total DESC;

-- q21 · First and last order per customer
SELECT customer_id,
       MIN(order_date) AS first_order,
       MAX(order_date) AS last_order,
       CAST(julianday(MAX(order_date)) - julianday (MIN(order_date)) AS INTEGER) AS days_between
FROM orders
GROUP BY customer_id;

-- q22 · Second most expensive product per category
WITH r as (SELECT category, product_name, unit_price,
                  DENSE_RANK() OVER(PARTITION BY category ORDER BY unit_price DESC) AS rk
           FROM products
           )
SELECT category, product_name, unit_price
FROM r 
WHERE rk = 2;

-- q23 · Duplicate payments
SELECT order_id, COUNT(*) AS payments, ROUND(SUM(amount),2) AS Total_paid
FROM payments
GROUP BY order_id
HAVING COUNT (*) >1;

-- q24 · Billing vs. payments reconciliation
WITH billed AS (
    SELECT o.order_id, SUM(i.quantity * i.unit_price * (1-i.discount)) AS billed
    FROM order_items i
    JOIN orders o ON o.order_id = i.order_id
    WHERE o.status = 'Delivered'
    GROUP BY o.order_id),
     paid AS (
   SELECT order_id, SUM(amount) AS paid, COUNT(*) AS n
   FROM payments
   GROUP BY order_id
)        
SELECT b.order_id,
       ROUND(b.billed, 2) AS billed,
       ROUND(COALESCE(p.paid, 0), 2) AS paid,
       CASE WHEN p.order_id IS NULL THEN 'Sin pago'
            WHEN p.n > 1 THEN 'Cobro duplicado'
            ELSE 'Monto distinto' END AS issue
FROM billed b
LEFT JOIN paid p ON p.order_id = b.order_id
WHERE p.order_id IS NULL OR p.n > 1 OR ABS(ROUND(b.billed, 2) - p.paid) > 0.01;

-- q25 · 2024 cohort retention in 2025
WITH firsts AS (
  SELECT customer_id, MIN(order_date) AS first_order
  FROM orders
  GROUP BY customer_id
), c2024 AS (
  SELECT customer_id FROM firsts WHERE first_order < '2025-01-01'
), b2025 AS (
  SELECT DISTINCT customer_id FROM orders WHERE order_date >= '2025-01-01'
)
SELECT COUNT(*) AS cohort,
       COUNT(b.customer_id) AS retained,
       ROUND(100.0 * COUNT(b.customer_id) / COUNT(*), 1) AS pct_retained
FROM c2024 c
LEFT JOIN b2025 b ON b.customer_id = c.customer_id;

-- q26 · Average order value by segment and channel
WITH per_order AS(
  SELECT o.order_id, c.segment, o.channel, SUM(i.quantity * i.unit_price * (1 - i.discount))AS total
  FROM order_items i
  JOIN orders o ON o.order_id = i.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.status = 'Delivered'
  GROUP BY o.order_id, c.segment, o.channel
)
SELECT segment, channel, COUNT(*) AS orders, ROUND(AVG(total), 2) AS avg_ticket
FROM per_order
GROUP BY segment, channel;
