-- 01_business_questions_mysql.sql
-- Business Questions — ENIAC × Magist (MySQL 8+)

-- =========================
-- Q1) Does Magist have a strong tech ecosystem?
-- =========================

-- Q1.1 Tech vs Non-Tech products
SELECT
  CASE WHEN is_tech = 1 THEN 'Tech' ELSE 'Non-Tech' END AS segment,
  COUNT(*) AS products,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_products
FROM v_products_tech
GROUP BY segment
ORDER BY products DESC;

-- Q1.2 Tech vs Non-Tech sellers (tech seller if sold at least 1 tech item)
WITH seller_flag AS (
  SELECT
    oi.seller_id,
    MAX(pt.is_tech) AS is_tech_seller
  FROM order_items oi
  JOIN v_products_tech pt ON oi.product_id = pt.product_id
  GROUP BY oi.seller_id
)
SELECT
  CASE WHEN is_tech_seller = 1 THEN 'Tech sellers' ELSE 'Non-Tech sellers' END AS segment,
  COUNT(*) AS sellers,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_sellers
FROM seller_flag
GROUP BY segment
ORDER BY sellers DESC;

-- Q1.3 Tech vs Non-Tech customers (tech customer if bought at least 1 tech item)
WITH customer_flag AS (
  SELECT
    om.customer_id,
    MAX(pt.is_tech) AS is_tech_customer
  FROM v_orders_month om
  JOIN order_items oi ON om.order_id = oi.order_id
  JOIN v_products_tech pt ON oi.product_id = pt.product_id
  GROUP BY om.customer_id
)
SELECT
  CASE WHEN is_tech_customer = 1 THEN 'Tech customers' ELSE 'Non-Tech customers' END AS segment,
  COUNT(*) AS customers,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_customers
FROM customer_flag
GROUP BY segment
ORDER BY customers DESC;


-- =========================
-- Q2) Is customer demand for tech products sufficient?
-- =========================

-- Q2.1 Monthly unique customers (All vs Tech)
WITH all_cust AS (
  SELECT order_month, customer_id
  FROM v_orders_month
  GROUP BY order_month, customer_id
),
tech_cust AS (
  SELECT
    om.order_month,
    om.customer_id
  FROM v_orders_month om
  JOIN order_items oi ON om.order_id = oi.order_id
  JOIN v_products_tech pt ON oi.product_id = pt.product_id
  WHERE pt.is_tech = 1
  GROUP BY om.order_month, om.customer_id
)
SELECT
  a.order_month,
  COUNT(DISTINCT a.customer_id) AS all_customers,
  COUNT(DISTINCT t.customer_id) AS tech_customers
FROM all_cust a
LEFT JOIN tech_cust t
  ON a.order_month = t.order_month
GROUP BY a.order_month
ORDER BY a.order_month;


-- =========================
-- Q3) Is Magist aligned with ENIAC’s premium pricing?
-- =========================

-- Q3.1 Tech price level on Magist (mean, median approx, min, max)
-- MySQL median exact requires window functions; we use an approximate median via percentile-like method:
WITH tech_prices AS (
  SELECT oi.price
  FROM order_items oi
  JOIN v_products_tech pt ON oi.product_id = pt.product_id
  WHERE pt.is_tech = 1
),
ranked AS (
  SELECT
    price,
    ROW_NUMBER() OVER (ORDER BY price) AS rn,
    COUNT(*) OVER () AS cnt
  FROM tech_prices
)
SELECT
  ROUND(AVG(price), 2) AS avg_tech_price,
  -- exact median using row numbers
  ROUND(AVG(price), 2) AS median_tech_price,
  ROUND(MIN(price), 2) AS min_tech_price,
  ROUND(MAX(price), 2) AS max_tech_price
FROM ranked
WHERE rn IN (FLOOR((cnt + 1) / 2), FLOOR((cnt + 2) / 2));

-- Note: ENIAC average price (~€540) is an external benchmark from ENIAC’s catalog.


-- =========================
-- Q4) Can Magist meet operational expectations (delivery & satisfaction)?
-- =========================

-- Q4.1 On-time delivery rate
SELECT
  ROUND(
    100 * SUM(CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 ELSE 0 END)
    / NULLIF(COUNT(*), 0),
    1
  ) AS on_time_delivery_pct
FROM orders o
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL;

-- Q4.2 Customer satisfaction (review score)
SELECT
  ROUND(AVG(r.review_score), 2) AS avg_review_score,
  ROUND(
    100 * SUM(CASE WHEN r.review_score >= 4 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
    1
  ) AS pct_positive_reviews
FROM reviews r;
