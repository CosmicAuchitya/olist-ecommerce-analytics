-- Olist E-Commerce Analytics Pipeline
-- Script 02: Business Diagnostics & Investigative SQL Queries
-- Target: MySQL 8.0 (Compatible with SQLite / PostgreSQL)
-- Author: CosmicAuchitya

USE ecommerce_analytics;

-- 1. Category Margin Leakage: High freight-to-price ratio (>20%)
-- Identifies categories where shipping costs eat away product margins.
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
LIMIT 10;

-- Key Findings:
-- christmas_supplies: 36.69% freight ratio
-- signaling_and_security: 30.26%
-- food_drink: 29.70%
-- electronics: 29.07% ($160.2K sales with $46.5K freight across 2,767 orders)


-- 2. Delivery SLA Breach vs Customer CSAT (Review Scores)
-- Measures review score drop when delivery misses the estimated date.
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

-- Key Findings:
-- On-time: 4.29 avg rating | 6.63% 1-star | 62.26% 5-star
-- Delayed: 2.27 avg rating | 53.74% 1-star (8x increase) | 16.54% 5-star


-- 3. Month-over-Month (MoM) Revenue Trajectory & Macro Shocks
-- Tracks monthly growth and correlates dips with historical macro events.
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

-- Key Findings:
-- 8x revenue expansion from Jan 2017 ($111K) to 2018 run-rate ($900K+)
-- Black Friday peak in Nov 2017: $987.7K (+52.4% MoM)
-- June 2018 contraction: -12.4% MoM dip caused by the 11-day nationwide truckers' strike


-- 4. Customer Retention: One-Time vs Repeat Buyers
-- Evaluates retention using the persistent human customer ID.
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


-- 5. Discount Dependency Audit (Voucher Utilization)
-- Verifies whether 1-time customers left because they were coupon hunters.
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

-- Key Findings:
-- 96.28% of 1-time buyers paid full price (zero vouchers applied).
-- Churn was driven by lack of lifecycle marketing and delivery issues, not price sensitivity.


-- 6. 1-Star Review Root Cause: Delivery Delay vs Merchant Quality
-- Separates operational logistics failures from merchant product defects.
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
        WHEN delay_days > 0 THEN 'Delayed (Carrier Failure)' 
        ELSE 'On-Time (Merchant / Quality Defect)' 
    END AS failure_reason,
    COUNT(DISTINCT customer_unique_id) AS lost_1_star_customers,
    ROUND(SUM(payment_value), 2) AS immediate_order_revenue,
    ROUND(AVG(payment_value), 2) AS avg_order_value,
    ROUND(AVG(CASE WHEN delay_days > 0 THEN delay_days ELSE NULL END), 1) AS avg_days_delayed
FROM customer_order_reviews
WHERE review_score = 1
GROUP BY failure_reason;

-- Key Findings:
-- 3,413 customers ($635K GMV) gave 1-star strictly due to late delivery (avg 12.4 days late).
-- 5,864 customers ($1.18M GMV) gave 1-star due to merchant/product defects despite on-time delivery.


-- 7. Geographic Seller Concentration (São Paulo Logistics Bottleneck)
-- Checks top origin states to assess seller concentration risks.
SELECT 
    s.seller_state,
    COUNT(oi.order_id) AS items_shipped,
    ROUND(COUNT(oi.order_id) * 100.0 / (SELECT COUNT(*) FROM order_items), 2) AS seller_concentration_pct
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_state
ORDER BY items_shipped DESC
LIMIT 5;

-- Key Finding:
-- São Paulo (SP) alone accounts for 71.32% of all seller shipments.


-- 8. Intra-State vs Inter-State Logistics Performance
-- Compares freight cost, transit lead time, and delay rates for local vs cross-border orders.
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

-- Key Findings:
-- Intra-State: $13.45 avg freight | 7.9 delivery days | 4.45% delay rate
-- Inter-State: $23.63 avg freight (+75% cost) | 15.0 days (2x slower) | 7.81% delay rate


-- 9. Regional Warehousing Opportunity Sizing (Freight Arbitrage)
-- Calculates freight differential and lead time penalty by category for interstate orders.
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

-- Across 70,328 interstate orders, the theoretical gap between local ($13.45) 
-- and cross-border ($23.63) freight represents a $716,000+ margin recovery opportunity.
