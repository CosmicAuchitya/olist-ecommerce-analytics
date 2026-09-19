-- ==============================================================================
-- OLIST E-COMMERCE ANALYTICS PIPELINE
-- SCRIPT 01: DATABASE SCHEMA DEFINITION & ETL DATA LOADING
-- Database Engine: MySQL 8.0 / Compatible with PostgreSQL & SQLite
-- Author: Lead Data Analyst (CosmicAuchitya)
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS ecommerce_analytics;
USE ecommerce_analytics;

-- ------------------------------------------------------------------------------
-- 1. ORDERS TABLE (Core Transactional Header)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    order_purchase_timestamp DATETIME NOT NULL,
    order_approved_at DATETIME NULL,
    order_delivered_carrier_date DATETIME NULL,
    order_delivered_customer_date DATETIME NULL,
    order_estimated_delivery_date DATETIME NOT NULL,
    INDEX idx_orders_customer (customer_id),
    INDEX idx_orders_purchase (order_purchase_timestamp),
    INDEX idx_orders_delivered (order_delivered_customer_date)
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

-- ------------------------------------------------------------------------------
-- 2. CATEGORY TRANSLATION TABLE (Portuguese to English)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS category_translation;
CREATE TABLE category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100) NOT NULL
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ------------------------------------------------------------------------------
-- 3. PRODUCTS TABLE (Product Dimensions & Categorization)
-- ------------------------------------------------------------------------------
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
    product_width_cm INT NULL,
    INDEX idx_products_category (product_category_name)
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

-- ------------------------------------------------------------------------------
-- 4. ORDER ITEMS TABLE (Granular Line-Item & Sourcing Records)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    INDEX idx_items_product (product_id),
    INDEX idx_items_seller (seller_id)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ------------------------------------------------------------------------------
-- 5. CUSTOMERS TABLE (Customer Mapping: Surrogate Key vs Persistent Human ID)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(5),
    INDEX idx_customers_unique (customer_unique_id),
    INDEX idx_customers_state (customer_state)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ------------------------------------------------------------------------------
-- 6. SELLERS TABLE (Merchant Geographic Origins)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS sellers;
CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(5),
    INDEX idx_sellers_state (seller_state)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sellers.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ------------------------------------------------------------------------------
-- 7. ORDER REVIEWS TABLE (Customer Satisfaction & Review Feedback)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS order_reviews;
CREATE TABLE order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    INDEX idx_reviews_order (order_id),
    INDEX idx_reviews_score (review_score)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_reviews.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ------------------------------------------------------------------------------
-- 8. ORDER PAYMENTS TABLE (Payment Instruments, Value & Installments)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS order_payments;
CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10,2),
    INDEX idx_payments_order (order_id),
    INDEX idx_payments_type (payment_type)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_payments.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ------------------------------------------------------------------------------
-- DATA AUDIT / VERIFICATION COUNT
-- ------------------------------------------------------------------------------
SELECT 'orders' AS table_name, COUNT(*) AS record_count FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'category_translation', COUNT(*) FROM category_translation;
