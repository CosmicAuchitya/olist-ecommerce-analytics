# Project 1: Master Insights & Analytical Register
- **Project:** Olist Brazilian E-Commerce Analytics & Margin Optimization
- **Database:** MySQL 8.0 (ecommerce_analytics)
- **Scope:** 100K+ Orders, 112K+ Order Items, 99K+ Reviews, 96K+ Customers (2016–2018)
- **Author:** CosmicAuchitya

---

## Executive KPI Scorecard
| Business Metric | Discovered Value | Analytical Diagnosis |
| :--- | :--- | :--- |
| **Total Delivered Orders** | 96,478 | Stable volume across 20-month operating history |
| **Net Product GMV** | $13.59M | Healthy top-line expansion (8x run-rate growth) |
| **One-Time Buyers Share** | **96.9% (90,557)** | Severe leaky bucket (High CAC wastage) |
| **Repeat Buyers Share (2+)** | **3.1% (2,801)** | Low retention rate (lack of post-purchase engagement) |
| **Average Delivery Delay** | **12.4 Days** past SLA | Courier logistics partner failure |
| **1-Star Ratings from Delays** | **3,413 Customers ($635K)** | Direct delivery-caused customer destruction |
| **Top Freight Leakage Category** | **Electronics ($46.5K / 29.1%)** | Freight eroding gross margin |
| **Peak Revenue Month** | **Nov 2017 ($987.7K)** | Black Friday seasonality (+52.4% MoM) |

---

## Analytical Findings by Business Question

### 1. Revenue vs Freight Cost Leakage by Category
- **Objective:** Identify high-volume categories (>100 orders) where freight expenses exceed healthy thresholds (>20% of GMV).
- **Key Findings:**
  - `christmas_supplies`: Freight ratio = **36.69%** (bulky seasonal items).
  - `signaling_and_security`: Freight ratio = **30.26%**.
  - `food_drink`: Freight ratio = **29.70%**.
  - `electronics`: Freight ratio = **29.07%** ($160.2K sales with $46.5K shipping cost across 2,767 orders).
- **Financial Opportunity:** Establishing regional distribution hubs for top electronics SKUs can reduce long-distance interstate transit, saving an estimated **$716,000+** annually.

---

### 2. Delivery SLA Breaches vs Customer Review Scores (CSAT)
- **Objective:** Quantify the drop in customer satisfaction when deliveries miss promised dates.
- **Key Findings:**
  - **On-Time Orders (89,936):** Avg Rating = **4.29 / 5.0** | 1-Star = **6.63%** | 5-Star = **62.26%**.
  - **Delayed Orders (6,407):** Avg Rating = **2.27 / 5.0** | 1-Star = **53.74%** | 5-Star = **16.54%**.
- **Diagnosis:** Delivery delays trigger an **8x surge in 1-star reviews** and reduce 5-star ratings by **73%**.

---

### 3. Month-over-Month (MoM) Trajectory & Macro Shocks
- **Objective:** Track monthly revenue progression and evaluate external macro factors.
- **Key Findings:**
  - **Starting Run-Rate (Jan 2017):** $111,798 / month.
  - **Ending Run-Rate (Aug 2018):** $985,576 / month.
  - **Trajectory:** **~8x expansion** in monthly sales over 20 months.
  - **Peak Revenue Spike:** Nov 2017 reached **$987,765** (+52.4% MoM) driven by Black Friday.
  - **Post-Peak Correction:** Dec 2017 saw a **-26.5% dip** following the holiday rush.
  - **Macro Triangulation (June 2018):** A **-12.4% MoM drop** coincided with the nationwide 11-day Brazilian truck drivers' strike (*Greve dos Caminhoneiros*), which paralyzed logistics across federal highways.

---

### 4. Customer Retention & The Discount Myth
- **Objective:** Understand why 96.9% of customers only bought once. Were they deal-seekers, or did operational issues drive them away?
- **Finding 1 (Discount Myth Debunked):**
  - **96.28%** of 1-time buyers paid **full price** (zero vouchers used).
  - Customers were not bargain-hunters; they showed healthy willingness to pay.
- **Finding 2 (1-Star Review Autopsy):**
  - **3,413 customers ($635K GMV)** gave 1-star reviews directly due to delivery delays (avg 12.4 days late).
  - **5,864 customers ($1.18M GMV)** gave 1-star reviews due to product quality issues despite on-time delivery.
- **Finding 3 (Untapped Retention Base):**
  - **53,136 one-time buyers (57.6%) gave a 5-star review** on their sole order.
  - They were satisfied with their initial experience, but never returned due to the lack of automated lifecycle and re-engagement marketing.

---

### 5. Supply Chain Sourcing Monopoly & Regional Logistics
- **Objective:** Quantify the impact of seller geographic concentration on shipping costs and delays.
- **Key Findings:**
  - **São Paulo Monopoly:** **71.32% of all shipments originated from SP**.
  - **Intra-State (Local SP):** Avg delivery time **7.9 days** | Freight **$13.45** | Delay rate **4.45%**.
  - **Inter-State (Cross-Border):** Avg delivery time **15.0 days** | Freight **$23.63 (+75% cost)** | Delay rate **7.81%**.
  - **Northeast Friction:** Customers in Maranhão (`MA`: 21.6 days, 18.0% delays) and Bahia (`BA`: 19.2 days, 11.9% delays) face extreme delivery friction due to long highway routes and interstate tax checkpoints (*Postos Fiscais / ICMS DIFAL*).

---

## Strategic Recommendations
1. **Enforce Carrier SLAs:** Implement contractual penalties on delivery partners exceeding a 5-day delay threshold.
2. **Automated Lifecycle Marketing:** Target the 53,000+ satisfied 5-star buyers with automated re-engagement campaigns within 30–45 days. Converting 5% of this group unlocks **$375,000+ in incremental GMV** at near-zero CAC.
3. **Regional 3PL Warehouses:** Establish fulfillment partnerships in the Northeast (Recife/Salvador) for high-velocity categories, targeting **$716,000 in freight savings**.
4. **Dynamic SLA Buffering:** Pad delivery estimates for remote Northeast regions by +4 to +6 business days to avoid false expectations and prevent 1-star rage reviews.
