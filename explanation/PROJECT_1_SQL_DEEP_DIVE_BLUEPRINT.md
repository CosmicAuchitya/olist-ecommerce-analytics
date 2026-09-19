# 📘 Project 1: SQL Blueprint & Interview Defense Manual
**Project:** Olist Brazilian E-Commerce Analytics  
**Target Role:** Insight Analyst / Commercial Data Analyst  
**Author:** CosmicAuchitya

---

## 🎯 Welcome & How to Use This Blueprint

Is manual ka maqsad aapko SQL queries "ratna" nahi, balki **SQL Architect ki tarah sochna** sikhana hai. 
Har query ko 3 layers mein toda gaya hai:
1. **🧠 Business Mindset (Hinglish):** Business problem kya thi aur dimaag mein pehla sawaal kya aaya?
2. **🔬 Line-by-Line Blueprint:** Query ki har line kyu likhi gayi, us line par dimaag mein kya sawaal tha, aur usne database mein kya kaam kiya.
3. **🗣️ English Interview Script:** Interviewer ke saamne bina hichkichaye fluent, professional English mein kaise explain karna hai.

---

## Table of Contents
1. [Core Architectural Concept: `customer_id` vs `customer_unique_id`](#0-the-core-relational-trap-customer_id-vs-customer_unique_id)
2. [Query 1: Category Margin Leakage (Freight-to-Price Ratio > 20%)](#query-1-category-margin-leakage-freight-to-price-ratio--20)
3. [Query 2: Delivery SLA Breach vs Customer CSAT Crash](#query-2-delivery-sla-breach-vs-customer-csat-crash)
4. [Query 3: Month-over-Month (MoM) Growth & Truckers' Strike Triangulation](#query-3-month-over-month-mom-growth--macro-shocks)
5. [Query 4: Customer Retention Cohorts (The 97% Leaky Bucket)](#query-4-customer-retention-cohorts-the-97-leaky-bucket)
6. [Query 5: Debunking the Discount Hunter Myth](#query-5-debunking-the-discount-hunter-myth)
7. [Query 6: 1-Star Review Autopsy (Carrier Failure vs Merchant Defect)](#query-6-1-star-review-autopsy-carrier-failure-vs-merchant-defect)
8. [Query 7: São Paulo Seller Geographic Monopoly](#query-7-são-paulo-seller-geographic-monopoly)
9. [Query 8: Intra-State vs Inter-State Logistics Friction](#query-8-intra-state-vs-inter-state-logistics-friction)
10. [Query 9: Regional Warehousing Opportunity Sizing ($716K Arbitrage)](#query-9-regional-warehousing-opportunity-sizing-716k-arbitrage)

---

## 0. The Core Relational Trap: `customer_id` vs `customer_unique_id`

### 🧠 1. Business Mindset & Context (Hinglish)
Olist ke relational schema mein do columns hain: `customer_id` aur `customer_unique_id`.
Agar aap kisi beginner analyst ko bologe ki "Customer repeat rate nikalo", wo `customer_id` par `COUNT(order_id)` chala dega aur result aayega: **0% repeat buyers! Sab 1-time buyers!**
Kyun? Kyunki Olist har baar jab koi checkout karta hai, ek naya `customer_id` generate karta hai (surrogate order token). Lekin real human buyer ka permanent aadhaar card / PAN card jaisa identifier `customer_unique_id` hai.

### 🗣️ English Interview Script
> *"In Olist's relational architecture, `customer_id` is merely an order-level surrogate key generated per transaction. If you group by `customer_id`, your repeat rate calculates to 0%. To analyze true human repeat behavior, lifetime value, and cohort retention across multi-year cycles, you must join on `customer_unique_id`, which represents the persistent human entity."*

---

## Query 1: Category Margin Leakage (Freight-to-Price Ratio > 20%)

### 🧠 1. Business Mindset (Hinglish)
- **Problem:** Marketplace ka GMV $13.5M pahunch gaya, lekin net profit kam kyu ho raha hai?
- **Hypothesis:** Kuch categories mein shipping cost itni zyada hai ki product ki price ka 20-30% sirf delivery mein chala ja raha hai. Agar product ₹1,000 ka hai aur delivery ₹350 le rahi hai, to customer ya seller ka margin khatam ho jayega.
- **Goal:** Wo high-volume categories dhoondo jahan order volume 100 se zyada ho aur freight cost total sales ka 20% se zyada khaa rahi ho.

### 📝 2. Line-by-Line Blueprint

```sql
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
```

#### Step-by-Step Breakdown:

1. **`FROM order_items oi`**
   - *Dimaag mein sawaal:* Mujhe product price aur freight cost kahan milegi?
   - *Logic:* `order_items` table line-item level par hai, jahan har item ka `price` aur `freight_value` recorded hai. Isliye base table `order_items` bani.

2. **`JOIN products p ON oi.product_id = p.product_id`**
   - *Dimaag mein sawaal:* Lekin `order_items` mein product ki category ka naam nahi hai, sirf `product_id` hai. Main category kaise lau?
   - *Logic:* `products` table ko `product_id` par join kiya taaki category name access ho sake.

3. **`JOIN category_translation t ON p.product_category_name = t.product_category_name`**
   - *Dimaag mein sawaal:* Raw category Portuguese mein hai (jaise *artigos_de_natal*), executive dashboard mein English kaise dikhegi?
   - *Logic:* `category_translation` table ko join kiya taaki English name (`product_category_name_english`) mil sake.

4. **`GROUP BY t.product_category_name_english`**
   - *Dimaag mein sawaal:* Mujhe aggregate calculation kis level par karni hai?
   - *Logic:* Har category ke liye alag calculation chahiye, isliye category ke naam se group kar diya.

5. **`SELECT ...`**
   - `COUNT(oi.order_id) AS total_orders`: Is category mein kitne order aaye?
   - `ROUND(SUM(oi.price), 2) AS total_sales_value`: Total kitne dollar ka maal bika? `ROUND(..., 2)` paise/cents ke 2 decimals clean karne ke liye.
   - `ROUND(SUM(oi.freight_value), 2) AS total_freight_cost`: Total kitna courier charge laga?
   - `ROUND((SUM(oi.freight_value) / SUM(oi.price)) * 100, 2) AS freight_to_price_ratio`: **Core KPI!** Freight sales ka kitna percentage hai?

6. **`HAVING COUNT(oi.order_id) >= 100 AND freight_to_price_ratio > 20`**
   - *Dimaag mein sawaal:* Agar kisi category mein sirf 2 order aaye aur freight 50% nikla to kya wo business priority hai?
   - *Logic:* Nahi! Wo sample bias ho sakta hai. Isliye `HAVING COUNT >= 100` lagaya taaki statistical significance ho, aur `ratio > 20%` lagaya kyunki 20% e-commerce unit economics ki red-line hoti hai. *(Note: `HAVING` isliye use kiya kyunki aggregate function par filter lagana tha, `WHERE` aggregates par kaam nahi karta).*

7. **`ORDER BY freight_to_price_ratio DESC LIMIT 10;`**
   - *Logic:* Sabse zyada bleeding category ko top par dikhana aur top 10 worst offenders nikalna.

### 🗣️ 3. English Interview Script
> *"To diagnose unit margin erosion, I wrote a query against `order_items` joined with `products` and `category_translation`. I calculated the aggregate freight-to-price ratio by dividing `SUM(freight_value)` by `SUM(price)`. Using a `HAVING` clause, I filtered for statistically significant categories with at least 100 orders where freight exceeded a 20% margin threshold. This uncovered that categories like Christmas Supplies and Electronics were bleeding up to 36.7% and 29.1% in freight costs alone across $160K+ in sales."*

---

## Query 2: Delivery SLA Breach vs Customer CSAT Crash

### 🧠 1. Business Mindset (Hinglish)
- **Problem:** Marketplace par 1-star reviews bahut zyada aa rahe the. Kya ye product kharab hone ki wajah se tha ya late delivery ki wajah se?
- **Hypothesis:** Customer delivery date promise (SLA) se bahut sensitive hota hai. Agar delivery late hui to customer seedha 1-star deta hai.
- **Goal:** Measure karo ki On-Time delivery par average rating kya hai vs Late delivery par rating kitni girti hai aur 1-star ka percentage kitna surge hota hai.

### 📝 2. Line-by-Line Blueprint

```sql
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
```

#### Step-by-Step Breakdown:

1. **`FROM orders o JOIN order_reviews r ON o.order_id = r.order_id`**
   - *Dimaag mein sawaal:* Delivery dates aur review scores kahan hain?
   - *Logic:* Delivery dates `orders` table mein hain, aur ratings `order_reviews` table mein hain. Dono ko `order_id` par join kiya.

2. **`WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL`**
   - *Dimaag mein sawaal:* Agar order abhi raste mein hai ya cancel ho gaya to kya uska delivery delay calculate kar sakte hain?
   - *Logic:* Nahi! Cancelled ya ongoing orders ko filter out kiya taaki sirf un orders ka analysis ho jo actually customer ke ghar deliver ho chuke hain.

3. **`CASE WHEN DATEDIFF(delivered_date, estimated_date) > 0 THEN 'Delayed' ELSE 'On-Time' END`**
   - *Dimaag mein sawaal:* Pata kaise chalega ki order late tha ya on-time?
   - *Logic:* `DATEDIFF(actual_delivery, promised_estimate)` nikala. Agar difference > 0 hai, matlab promise se baad mein deliver hua (`Delayed`). Warna (`On-Time`).

4. **`SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id)`**
   - *Dimaag mein sawaal:* Delayed orders mein se kitne percent logon ne 1-star diya?
   - *Logic:* Conditional aggregation! Agar `review_score = 1` hai to 1 gino, warna 0. Use total orders se divide karke 100 se multiply kiya to exact percentage mil gaya.

### 🗣️ 3. English Interview Script
> *"I investigated the direct relationship between logistics SLA compliance and customer satisfaction. By joining `orders` and `order_reviews`, I used a `CASE` statement with `DATEDIFF` to classify delivered orders into 'On-Time' versus 'Delayed' relative to the promised estimated delivery date. The query revealed that on-time orders maintain a 4.29 CSAT with only 6.6% 1-star reviews, whereas delayed orders experience a catastrophic CSAT collapse to 2.27, with 1-star rage reviews surging by 8x to 53.7%."*

---

## Query 3: Month-over-Month (MoM) Growth & Macro Shocks

### 🧠 1. Business Mindset (Hinglish)
- **Problem:** Company 2017 se 2018 ke beech kaise grow kar rahi thi? Aur kya beech mein koi achanak girawat (crash) aayi thi?
- **Hypothesis:** June 2018 mein sales achanak drop hui thi. Kya wo normal seasonal dip tha ya koi external event tha?
- **Goal:** Har mahine ka total sales nikalo, pichle mahine ki sales ke saath compare karo, aur MoM growth % calculate karo using Window Functions.

### 📝 2. Line-by-Line Blueprint

```sql
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
```

#### Step-by-Step Breakdown:

1. **`WITH monthly_sales AS (...)` (Common Table Expression - CTE)**
   - *Dimaag mein sawaal:* Kya main ek hi query mein group bhi kar lu aur saath mein window function bhi chala du?
   - *Logic:* CTE use karne se code modular aur clean banta hai. CTE pehle har mahine ki total sales calculate karke ek temporary table bana deti hai.

2. **`SUBSTRING(o.order_purchase_timestamp, 1, 7) AS sales_month`**
   - *Dimaag mein sawaal:* Timestamp `2017-11-24 14:22:00` format mein hai, mujhe sirf saal aur mahina chahiye (`2017-11`).
   - *Logic:* `SUBSTRING(..., 1, 7)` pehle 7 characters (`YYYY-MM`) extract karta hai.

3. **`LAG(current_month_sales, 1) OVER (ORDER BY sales_month)`**
   - *Dimaag mein sawaal:* Current row par khade hokar pichle row ki sales value kaise laaye bina complex self-join ke?
   - *Logic:* `LAG(col, 1)` window function pichli row ki value khinch kar current row ke bagal mein rakh deta hai.

4. **`((Current - Prev) / Prev) * 100`**
   - *Logic:* Standard corporate growth formula jo MoM percentage batata hai.

### 🗣️ 3. English Interview Script
> *"I tracked the platform's revenue trajectory using a CTE paired with the `LAG()` window function. First, I aggregated net delivered sales by month (`YYYY-MM`). In the outer query, `LAG(current_month_sales, 1) OVER (ORDER BY sales_month)` retrieved the prior month's sales without an expensive self-join. This proved an 8x run-rate expansion from $111K to $900K+, pinpointed the Black Friday peak in Nov 2017 (+52.4% MoM), and explained the sudden -12.4% MoM contraction in June 2018 through macro triangulation with the nationwide Brazilian truckers' strike."*

---

## Query 4: Customer Retention Cohorts (The 97% Leaky Bucket)

### 🧠 1. Business Mindset (Hinglish)
- **Problem:** E-commerce mein naya customer lana (Customer Acquisition Cost - CAC) bahut mehenga hota hai. Profit tab banta hai jab customer dobara kharidari kare. Olist ka repeat rate kya hai?
- **Goal:** Har unique customer ke total orders count karo aur dekho ki kitne percent log 1-time buyer hain vs repeat buyer hain.

### 📝 2. Line-by-Line Blueprint

```sql
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
```

#### Step-by-Step Breakdown:

1. **`GROUP BY c.customer_unique_id`**
   - *Critical Decision:* Yahan `customer_id` nahi, balki `customer_unique_id` use kiya taaki real human identity track ho.

2. **`SELECT COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_order_counts)`**
   - *Logic:* Subquery use karke grand total nikala aur har cohort ka percentage share calculate kiya. Result: **96.9% one-time buyers, only 3.1% repeat buyers!**

### 🗣️ 3. English Interview Script
> *"To assess customer retention, I built a cohort aggregation grouped by `customer_unique_id`. By counting delivered orders per human entity and bucketing them using a `CASE` statement, I discovered a severe 'leaky bucket' phenomenon: 96.9% of customers (over 90,000 buyers) never returned after their initial purchase, while repeat buyers accounted for only 3.1%."*

---

## Query 5: Debunking the Discount Hunter Myth

### 🧠 1. Business Mindset (Hinglish)
- **Executive Myth:** Marketing team ne bola: *"Sir, 97% log isliye chale gaye kyunki wo discount seekers/coupon hunters the. Ek baar discount mila, kharida aur chale gaye."*
- **Investigative Mindset:** Kya ye baat sach hai ya sirf ek assumption hai? Chalo data se verify karte hain!
- **Goal:** Check karo ki 1-time buyers mein se kitne percent logon ne Voucher / Coupon use kiya tha aur kitne logon ne FULL PRICE pay kiya tha!

### 📝 2. Line-by-Line Blueprint

```sql
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
```

#### Step-by-Step Breakdown:

1. **`LEFT JOIN order_payments p ON o.order_id = p.order_id`**
   - *Logic:* `LEFT JOIN` use kiya taaki agar kisi order ka payment record missing ho tab bhi order drop na ho.

2. **`SUM(CASE WHEN p.payment_type = 'voucher' THEN 1 ELSE 0 END) AS voucher_count`**
   - *Logic:* Agar payment type 'voucher' hai to count badhao. Agar count = 0 hai, matlab customer ne 100% full cash/credit card diya.

3. **Key Finding:**
   - **96.28% of 1-time buyers paid FULL PRICE.**
   - Unhone koi discount nahi maanga tha! Unke paas purchase power thi. Churn ki wajah coupon na milna nahi, balki post-purchase marketing na hona thi!

### 🗣️ 3. English Interview Script
> *"I tested executive assumptions regarding whether churn was driven by price-sensitive coupon hunters. By joining customer cohorts with `order_payments` and aggregating voucher utilization, the data conclusively debunked the myth: 96.28% of one-time buyers paid full price without applying vouchers. This proved that customers had strong initial willingness to pay, and their failure to return stemmed from lack of lifecycle marketing and fulfillment delays, not discount sensitivity."*

---

## Query 6: 1-Star Review Autopsy (Carrier Failure vs Merchant Defect)

### 🧠 1. Business Mindset (Hinglish)
- **Problem:** Hamare 9,000 se zyada 1-star reviews hain. GMV ka lakho dollar risk par hai. Isme kiski galti hai: **Courier Partner (Logistics)** ki ya **Merchant / Seller (Product Quality)** ki?
- **Logic:**
  - Agar order late pahuncha aur 1-star mila -> **Courier Partner Failure**.
  - Agar order time par pahunch gaya tha, fir bhi 1-star mila -> **Merchant / Defective Product Failure**.

### 📝 2. Line-by-Line Blueprint

```sql
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
```

#### Step-by-Step Breakdown:

1. **Subquery for Payments:**
   - *Trap Avoided:* Ek order mein multiple payments ho sakti hain (jaise credit card + voucher). Direct join karne se duplicate rows ban jaati hain. Isliye pehle subquery se order-level total nikala: `(SELECT order_id, SUM(payment_value) ... GROUP BY order_id)`.

2. **Root Cause Segmentation:**
   - `3,413 customers ($635,017 GMV)`: Delivery late hone ki wajah se 1-star mila (average delay = 12.4 days!).
   - `5,864 customers ($1.18M GMV)`: Delivery on-time thi, lekin item defective ya wrong nikla.

### 🗣️ 3. English Interview Script
> *"I performed an autopsy on 1-star negative reviews to separate logistics failure from merchant product quality issues. By joining review scores with delivery lead-time variance and order payments, I determined that 3,413 buyers ($635K in GMV) were destroyed purely by carrier delays averaging 12.4 days past SLA, while 5,864 buyers ($1.18M in GMV) received damaged or wrong items despite on-time delivery. This gave management two distinct remediation roadmaps: carrier penalty enforcement and merchant catalog quality audits."*

---

## Query 7: São Paulo Seller Geographic Monopoly

### 🧠 1. Business Mindset (Hinglish)
- **Problem:** Saare orders delay kyu ho rahe hain? Poore desh ka supply network kahan baitha hai?
- **Goal:** Har seller ka state check karo aur dekho ki national shipments mein kis state ka kitna percent share hai.

### 📝 2. Line-by-Line Blueprint

```sql
SELECT 
    s.seller_state,
    COUNT(oi.order_id) AS items_shipped,
    ROUND(COUNT(oi.order_id) * 100.0 / (SELECT COUNT(*) FROM order_items), 2) AS seller_concentration_pct
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_state
ORDER BY items_shipped DESC
LIMIT 5;
```

#### Step-by-Step Breakdown:
- `ROUND(COUNT(oi.order_id) * 100.0 / (SELECT COUNT(*) FROM order_items), 2)`: Subquery total order items nikal kar concentration percentage calculate karti hai.
- **Finding:** **São Paulo (SP) akela 71.32% shipments originate karta hai!** Poora e-commerce ek hi state par nirbhar hai.

### 🗣️ 3. English Interview Script
> *"I quantified supplier origin concentration by joining `sellers` with `order_items`. The query proved that 71.32% of all national marketplace shipments originated from a single geographic hub: São Paulo (SP). This massive supply centralization forced long-distance cross-border transit across Brazil, directly generating delivery bottlenecks in outer regions."*

---

## Query 8: Intra-State vs Inter-State Logistics Friction

### 🧠 1. Business Mindset (Hinglish)
- **Problem:** Jab SP ka seller SP ke hi customer ko bhejta hai (Intra-state), tab kitna kharcha aur time lagta hai? Aur jab SP ka seller doosre state (Inter-state) bhejta hai, tab kitna penalty lagta hai?
- **Goal:** Same-state vs Cross-state ka direct comparison karo on Freight, Delivery Days, aur Delay Rate.

### 📝 2. Line-by-Line Blueprint

```sql
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
```

#### Step-by-Step Breakdown:
- `CASE WHEN s.seller_state = c.customer_state`: Intra-state vs Inter-state routing flag.
- **Results:**
  - **Intra-State:** $13.45 Freight | 7.9 Days Lead Time | 4.45% Delay Rate.
  - **Inter-State:** $23.63 Freight (**+75% Cost Penalty!**) | 15.0 Days (**2x Slower!**) | 7.81% Delay Rate.

### 🗣️ 3. English Interview Script
> *"I modeled the logistical penalty of inter-state commerce by comparing orders where `seller_state = customer_state` against cross-border routes. Intra-state shipments cost $13.45 and took 7.9 days with a 4.45% delay rate. In contrast, inter-state shipments suffered a +75% freight cost surge to $23.63, doubled delivery transit to 15.0 days, and saw SLA delay rates jump to 7.81%."*

---

## Query 9: Regional Warehousing Opportunity Sizing ($716K Arbitrage)

### 🧠 1. Business Mindset (Hinglish)
- **C-Suite Pitch:** CFO ne poocha: *"Agar hum Northeast ya doosre states mein 3PL warehouses bana lein, to company ko actual kitne dollar ki bachat hogi?"*
- **Math Logic:** 70,328 inter-state orders hain. Inter-state freight ($23.63) aur local freight ($13.45) ke beech ka gap hai **$10.18 per order**. Agar high-volume items ko local warehouse se ship karein, to ye freight penalty direct company ki gross margin ban jayegi!

### 📝 2. Line-by-Line Blueprint

```sql
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
```

#### Step-by-Step Breakdown:
- Category level par local vs interstate freight ka differential nikala (`interstate_freight - local_freight`).
- Office Furniture aur heavy electronics par freight penalty $10 se $18 per order nikli.
- Model ne prove kiya ki top SKUs ko regional fulfillment hubs par shift karne se **$716,000+ annual gross margin recovery** possible hai.

### 🗣️ 3. English Interview Script
> *"To present a commercially viable solution to leadership, I sized the financial opportunity of establishing regional 3PL fulfillment hubs. By computing the variance between local and inter-state freight across high-velocity categories, I demonstrated a freight penalty of $10.18 per order. Across 70,328 cross-border transactions, transitioning top SKUs to regional hubs represents over $716,000 in gross margin recovery, while slashing transit times from 15 days to under 8 days."*

---

## 🏁 Quick Interview Checklist (Golden Rules)
1. **Never say "I just ran a query":** Always frame it as *"I was investigating [Business Problem]..."*
2. **Always quote the financial metric:** Mention **$13.59M GMV, $1.09M EBITDA opportunity, $716K margin recovery, 96.9% churn rate**.
3. **Highlight the B.Com advantage:** Explain how commercial accounting principles helped you connect SQL metrics to gross profit and customer acquisition cost (CAC).
