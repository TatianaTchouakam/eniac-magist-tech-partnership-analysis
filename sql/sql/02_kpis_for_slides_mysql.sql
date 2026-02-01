-- 02_kpis_for_slides_mysql.sql
-- KPIs for slides (MySQL 8+)

-- Slide 3: Tech share (Products / Sellers / Customers)
WITH
prod AS (
  SELECT ROUND(100 * AVG(is_tech), 1) AS tech_products_pct
  FROM v_products_tech
),
seller AS (
  WITH seller_flag AS (
    SELECT oi.seller_id, MAX(pt.is_tech) AS is_tech_seller
    FROM order_items oi
    JOIN v_products_tech pt ON oi.product_id = pt.product_id
    GROUP BY oi.seller_id
  )
  SELECT ROUND(100 * AVG(is_tech_seller), 1) AS tech_sellers_pct
  FROM seller_flag
),
cust AS (
  WITH customer_flag AS (
    SELECT om.customer_id, MAX(pt.is_tech) AS is_tech_customer
    FROM v_orders_month om
    JOIN order_items oi ON om.order_id = oi.order_id
    JOIN v_products_tech pt ON oi.product_id = pt.product_id
    GROUP BY om.customer_id
  )
  SELECT ROUND(100 * AVG(is_tech_customer), 1) AS tech_customers_pct
  FROM customer_flag
)
SELECT
  tech_products_pct,
  tech_sellers_pct,
  tech_customers_pct
FROM prod, seller, cust;

-- Slide 5: Ops KPIs (on-time + satisfaction)
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

SELECT
  ROUND(AVG(r.review_score), 2) AS avg_review_score,
  ROUND(
    100 * SUM(CASE WHEN r.review_score >= 4 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
    1
  ) AS pct_positive_reviews
FROM reviews r;
