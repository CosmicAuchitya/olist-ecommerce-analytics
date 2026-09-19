CREATE DATABASE ecommerce_analytics;
USE ecommerce_analytics;

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME NULL,
    order_delivered_carrier_date DATETIME NULL,
    order_delivered_customer_date DATETIME NULL,
    order_estimated_delivery_date DATETIME
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, 
 @purchase_ts, @approved_at, @carrier_date, @customer_date, @estimated_date)
SET 
 order_purchase_timestamp      = NULLIF(@purchase_ts, ''),
 order_approved_at             = NULLIF(@approved_at, ''),
 order_delivered_carrier_date  = NULLIF(@carrier_date, ''),
 order_delivered_customer_date = NULLIF(@customer_date, ''),
 order_estimated_delivery_date = NULLIF(@estimated_date, '');
 
 SELECT COUNT(*) FROM orders;

USE ecommerce_analytics;

-- 1. CATEGORY TRANSLATION TABLE
DROP TABLE IF EXISTS category_translation;
CREATE TABLE category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- 2. PRODUCTS TABLE
DROP TABLE IF EXISTS products;
CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100) NULL,
    product_name_length INT NULL,
    product_description_length INT NULL,
    product_photos_qty INT NULL,
    product_weight_g INT NULL,
    product_length_cm INT NULL,
    product_height_cm INT NULL,
    product_width_cm INT NULL
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, @cat, @n_len, @d_len, @photos, @weight, @len, @h, @w)
SET 
 product_category_name = NULLIF(@cat, ''),
 product_name_length = NULLIF(@n_len, ''),
 product_description_length = NULLIF(@d_len, ''),
 product_photos_qty = NULLIF(@photos, ''),
 product_weight_g = NULLIF(@weight, ''),
 product_length_cm = NULLIF(@len, ''),
 product_height_cm = NULLIF(@h, ''),
 product_width_cm = NULLIF(@w, '');


-- 3. ORDER ITEMS TABLE (1.12 Lakh Rows)
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT 'orders' AS tbl, COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'category_translation', COUNT(*) FROM category_translation;

SELECT 
    t.product_category_name_english AS category,
    COUNT(oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_sales_value,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_cost,
    ROUND((SUM(oi.freight_value) / SUM(oi.price)) * 100, 2) AS freight_to_price_ratio
FROM order_items oi
JOIN products p 
    ON oi.product_id = p.product_id
JOIN category_translation t 
    ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
HAVING COUNT(oi.order_id) >= 100 
   AND freight_to_price_ratio > 20
ORDER BY freight_to_price_ratio DESC
LIMIT 5;



SELECT 
    CASE 
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) > 0 THEN 'Delayed'
        ELSE 'On-Time'
    END AS delivery_status,
    COUNT(o.order_id) AS total_orders,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    ROUND(SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS pct_1_star_reviews,
    ROUND(SUM(CASE WHEN r.review_score = 5 THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS pct_5_star_reviews
FROM orders o
JOIN order_reviews r 
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;



WITH monthly_sales AS (
    SELECT 
        SUBSTRING(o.order_purchase_timestamp, 1, 7) AS sales_month,
        ROUND(SUM(oi.price), 2) AS current_month_sales
    FROM orders o
    JOIN order_items oi 
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
    GROUP BY sales_month
)
SELECT 
    sales_month,
    current_month_sales,
    LAG(current_month_sales, 1) OVER (ORDER BY sales_month) AS previous_month_sales,
    ROUND(
        ((current_month_sales - LAG(current_month_sales, 1) OVER (ORDER BY sales_month)) 
        / LAG(current_month_sales, 1) OVER (ORDER BY sales_month)) * 100, 
        2
    ) AS mom_growth_pct
FROM monthly_sales;



WITH customer_order_counts AS (
    SELECT 
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders
    FROM customers c
    JOIN orders o 
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    CASE 
        WHEN total_orders = 1 THEN '1-Time Buyer'
        ELSE 'Repeat Buyer (2+ Orders)'
    END AS customer_type,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_order_counts), 2) AS percentage_share
FROM customer_order_counts
GROUP BY customer_type;


WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(CASE WHEN p.payment_type = 'voucher' THEN 1 ELSE 0 END) AS voucher_count
    FROM customers c
    JOIN orders o 
        ON c.customer_id = o.customer_id
    LEFT JOIN order_payments p 
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    CASE 
        WHEN total_orders = 1 THEN '1-Time Buyer' 
        ELSE 'Repeat Buyer (2+ Orders)' 
    END AS customer_type,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN voucher_count > 0 THEN 1 ELSE 0 END) AS used_discount_customers,
    ROUND(SUM(CASE WHEN voucher_count > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_used_discount,
    SUM(CASE WHEN voucher_count = 0 THEN 1 ELSE 0 END) AS no_discount_customers,
    ROUND(SUM(CASE WHEN voucher_count = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_no_discount
FROM customer_orders
GROUP BY customer_type;




WITH customer_summary AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o 
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    CASE 
        WHEN cs.total_orders = 1 THEN '1-Time Buyer' 
        ELSE 'Repeat Buyer' 
    END AS customer_type,
    COUNT(r.review_score) AS total_reviews,
    ROUND(AVG(r.review_score), 2) AS avg_rating,
    SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) AS count_1_star,
    ROUND(SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(r.review_score), 2) AS pct_1_star,
    SUM(CASE WHEN r.review_score = 5 THEN 1 ELSE 0 END) AS count_5_star,
    ROUND(SUM(CASE WHEN r.review_score = 5 THEN 1 ELSE 0 END) * 100.0 / COUNT(r.review_score), 2) AS pct_5_star
FROM customer_summary cs
JOIN customers c 
    ON cs.customer_unique_id = c.customer_unique_id
JOIN orders o 
    ON c.customer_id = o.customer_id
JOIN order_reviews r 
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY customer_type;


WITH customer_order_reviews AS (
    SELECT 
        c.customer_unique_id,
        o.order_id,
        r.review_score,
        DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS delay_days,
        p.payment_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_reviews r ON o.order_id = r.order_id
    JOIN (
        SELECT order_id, SUM(payment_value) AS payment_value 
        FROM order_payments 
        GROUP BY order_id
    ) p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT 
    CASE 
        WHEN delay_days > 0 THEN 'Delayed (Delivery Failure)' 
        ELSE 'On-Time (Product/Seller Issue)' 
    END AS failure_reason,
    COUNT(DISTINCT customer_unique_id) AS lost_1_star_customers,
    ROUND(SUM(payment_value), 2) AS immediate_order_revenue,
    ROUND(AVG(payment_value), 2) AS avg_order_value,
    ROUND(AVG(CASE WHEN delay_days > 0 THEN delay_days ELSE NULL END), 1) AS avg_days_delayed
FROM customer_order_reviews
WHERE review_score = 1
GROUP BY failure_reason;


SELECT 
    payment_type,
    COUNT(order_id) AS total_transactions,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(payment_value), 2) AS avg_transaction_value,
    ROUND(AVG(payment_installments), 1) AS avg_installments,
    ROUND(SUM(payment_value) * 100.0 / (SELECT SUM(payment_value) FROM order_payments WHERE payment_type != 'not_defined'), 2) AS revenue_share_pct
FROM order_payments
WHERE payment_type != 'not_defined'
GROUP BY payment_type
ORDER BY total_payment_value DESC;

-- Origin Concentration 
SELECT 
    s.seller_state,
    COUNT(oi.order_id) AS items_shipped,
    ROUND(COUNT(oi.order_id) * 100.0 / (SELECT COUNT(*) FROM order_items), 2) AS seller_concentration_pct
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_state
ORDER BY items_shipped DESC
LIMIT 5;
-- Same-State vs Inter-State
SELECT 
    CASE 
        WHEN s.seller_state = c.customer_state THEN 'Same-State (Intra-state)' 
        ELSE 'Inter-state (Cross-state)' 
    END AS transit_type,
    COUNT(oi.order_id) AS total_items,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_delivery_days,
    ROUND(SUM(CASE WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(oi.order_id), 2) AS delay_pct
FROM order_items oi
JOIN sellers s ON oi.seller_id = s.seller_id
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY transit_type;

-- The Northeast Delivery Disaster (Destination States)
SELECT 
    c.customer_state,
    COUNT(oi.order_id) AS items_received,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_days_to_deliver,
    ROUND(SUM(CASE WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(oi.order_id), 2) AS delay_pct
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING items_received >= 500
ORDER BY delay_pct DESC
LIMIT 5;

-- Local vs interstate Freight
SELECT 
    t.product_category_name_english AS category,
    COUNT(*) AS total_sales_count,
    ROUND(AVG(CASE WHEN s.seller_state = c.customer_state THEN oi.freight_value END), 2) AS local_freight,
    ROUND(AVG(CASE WHEN s.seller_state != c.customer_state THEN oi.freight_value END), 2) AS interstate_freight,
    ROUND(AVG(CASE WHEN s.seller_state != c.customer_state THEN oi.freight_value END) - 
          AVG(CASE WHEN s.seller_state = c.customer_state THEN oi.freight_value END), 2) AS freight_penalty_per_order,
    ROUND(AVG(CASE WHEN s.seller_state = c.customer_state THEN DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) END), 1) AS local_delivery_days,
    ROUND(AVG(CASE WHEN s.seller_state != c.customer_state THEN DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) END), 1) AS interstate_delivery_days
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN category_translation t ON p.product_category_name = t.product_category_name
JOIN sellers s ON oi.seller_id = s.seller_id
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY category
HAVING COUNT(*) >= 1000
   AND local_freight IS NOT NULL
   AND interstate_freight IS NOT NULL
ORDER BY freight_penalty_per_order DESC
LIMIT 8;


SELECT 
    c.customer_state,
    COUNT(oi.order_id) AS total_items_bought,
    ROUND(SUM(CASE WHEN s.seller_state = c.customer_state THEN 1 ELSE 0 END) * 100.0 / COUNT(oi.order_id), 2) AS pct_bought_locally,
    ROUND(SUM(CASE WHEN s.seller_state = 'SP' AND c.customer_state != 'SP' THEN 1 ELSE 0 END) * 100.0 / COUNT(oi.order_id), 2) AS pct_forced_from_SP
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
  AND c.customer_state IN ('RJ', 'MG', 'BA', 'PR', 'RS')
GROUP BY c.customer_state
ORDER BY total_items_bought DESC;