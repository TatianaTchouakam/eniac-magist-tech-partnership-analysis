-- 00_setup_mysql.sql
-- Helper views for ENIAC × Magist (MySQL 8+)

-- Tech classification view (based on translated category name)
CREATE OR REPLACE VIEW v_products_tech AS
SELECT
  p.product_id,
  p.product_category_name,
  COALESCE(t.product_category_name_english, p.product_category_name) AS category_en,
  CASE
    WHEN LOWER(COALESCE(t.product_category_name_english, p.product_category_name)) LIKE '%computer%' THEN 1
    WHEN LOWER(COALESCE(t.product_category_name_english, p.product_category_name)) LIKE '%electronic%' THEN 1
    WHEN LOWER(COALESCE(t.product_category_name_english, p.product_category_name)) LIKE '%telephony%' THEN 1
    WHEN LOWER(COALESCE(t.product_category_name_english, p.product_category_name)) LIKE '%audio%' THEN 1
    WHEN LOWER(COALESCE(t.product_category_name_english, p.product_category_name)) LIKE '%video%' THEN 1
    WHEN LOWER(COALESCE(t.product_category_name_english, p.product_category_name)) LIKE '%tablet%' THEN 1
    WHEN LOWER(COALESCE(t.product_category_name_english, p.product_category_name)) LIKE '%laptop%' THEN 1
    WHEN LOWER(COALESCE(t.product_category_name_english, p.product_category_name)) LIKE '%notebook%' THEN 1
    WHEN LOWER(COALESCE(t.product_category_name_english, p.product_category_name)) LIKE '%accessor%' THEN 1
    WHEN LOWER(COALESCE(t.product_category_name_english, p.product_category_name)) LIKE '%camera%' THEN 1
    WHEN LOWER(COALESCE(t.product_category_name_english, p.product_category_name)) LIKE '%console%' THEN 1
    ELSE 0
  END AS is_tech
FROM products p
LEFT JOIN product_category_name_translation t
  ON p.product_category_name = t.product_category_name;

-- Orders with month key (YYYY-MM)
CREATE OR REPLACE VIEW v_orders_month AS
SELECT
  o.order_id,
  o.customer_id,
  o.order_status,
  o.order_purchase_timestamp,
  DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month
FROM orders o;
