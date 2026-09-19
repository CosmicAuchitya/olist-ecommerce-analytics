# 📊 PROJECT 1: MASTER INSIGHTS & ANALYTICAL REGISTER
**Project Name:** Olist Brazilian E-Commerce End-to-End Analytics & Margin Optimization  
**Database:** MySQL (ecommerce_analytics)  
**Scope:** 100K+ Orders, 112K+ Order Items, 99K+ Reviews, 99K+ Customers (2016-2018)  
**Maintained by:** Lead Analyst & Pair Programming AI  

---

## 🧭 EXECUTIVE KPI SCORECARD (CURRENT BASELINE)
| Core Business Metric | Value Discovered | Business Diagnosis |
| :--- | :--- | :--- |
| **Total Delivered Orders** | 96,478 | Stable volume |
| **Net Product GMV** | .59M | Strong top-line revenue |
| **1-Time Buyers Share** | **97.00% (90,557)** | 🚨 Severe leaky bucket (High CAC wastage) |
| **Repeat Buyers Share (2+)** | **3.00% (2,801)** | 🚨 Virtually zero retention marketing |
| **Average Delivery Delay** | **12.4 Days** past SLA | 🚨 Courier partner failure |
| **1-Star Ratings from Delays** | **3,413 Customers ()** | Direct delivery-caused customer destruction |
| **Top Freight Leakage Category** | **Electronics (.5K / 29.1%)** | Freight eating gross margin |
| **Peak Revenue Month** | **Nov 2017 (.7K)** | Black Friday/Cyber Monday seasonality (+52.4% MoM) |

---

## 🔬 DETAILED MISSION INVESTIGATION LOGS

### 📍 MISSION #1: Revenue vs Freight Cost Leakage
- **Business Problem:** Which product categories have freight expenses exceeding healthy thresholds (>20%)?
- **Key Finding:**
  - christmas_supplies: Freight ratio = **36.69%** (Bulky/seasonal items).
  - signaling_and_security: Freight ratio = **30.26%**.
  - ood_drink: Freight ratio = **29.70%**.
  - electronics: Freight ratio = **29.07%** on **.2K sales (.5K shipping cost across 2,767 orders)**.
- **Financial Opportunity Sizing:** Establishing regional distribution hubs for top electronics SKUs can reduce long-distance interstate transit, saving an estimated ** annually**.

---

### 📍 MISSION #2: Delivery Delays vs Customer Review Scores
- **Business Problem:** Does delivering past the estimated delivery date destroy customer satisfaction?
- **Key Finding:**
  - **On-Time Orders (89,936):** Avg Rating = **4.29 / 5.0** | 1-Star = **6.63%** | 5-Star = **62.26%**.
  - **Delayed Orders (6,407):** Avg Rating = **2.27 / 5.0** | 1-Star = **53.74%** | 5-Star = **16.54%**.
- **Core Diagnosis:** Delivery delays trigger an **8x surge in 1-star reviews** and reduce 5-star reviews by **75%**.

---

### 📍 MISSION #3: Month-over-Month (MoM) Revenue Growth & Trajectory
- **Business Problem:** How did monthly revenue progress, and where were the peak growth and contraction periods?
- **Key Finding:**
  - **Starting Run-Rate (Jan 2017):** ,798.36 / month.
  - **Ending Run-Rate (Aug 2018):** ,576.64 / month (Consistently  - ).
  - **Overall Trajectory:** Company grew **~8x in monthly revenue** over 20 months.
  - **Peak Revenue Spike:** 2017-11 reached **,765.37** (+52.37% MoM growth) driven by Black Friday.
  - **Post-Peak Hangover:** 2017-12 saw a **-26.50% dip** as holiday orders completed.

---

### 📍 MISSION #4: Customer Retention, Discount Dependency & 1-Star Autopsy
- **Business Problem:** Why are 97% of buyers 1-time purchasers? Did they come only for discounts, or did service failure drive them away?
- **Key Finding 1 (The Discount Myth Debunked):**
  - **96.28%** of 1-time buyers paid **FULL PRICE (Zero discounts/vouchers)**.
  - **92.15%** of repeat buyers also paid **FULL PRICE**.
  - **Conclusion:** Customers are NOT "discount hunters". They are willing to pay standard prices.
- **Key Finding 2 (The 1-Star Autopsy & Financial Loss):**
  - Out of 1-time buyers, **8,837 customers gave 1-star reviews** on their very first purchase.
  - **3,413 customers (,017 in order GMV)** gave 1-star specifically due to **DELIVERY DELAYS** (average delay of **12.4 days** past promised date!).
  - **5,864 customers (.18M in GMV)** gave 1-star due to product/seller quality defects despite on-time delivery.
- **Key Finding 3 (The Untapped Goldmine):**
  - **53,136 one-time buyers (59.01%) gave a 5-STAR REVIEW**!
  - They were completely happy, yet never purchased again because Olist had **zero automated lifecycle / retention marketing** (no post-purchase recommendations, re-engagement emails, or category cross-selling).

---

## 🎯 STRATEGIC RECOMMENDATIONS FOR LEADERSHIP
1. **Courier Partner SLA Enforcement:** Contractually enforce financial penalties on carriers exceeding a 5-day delay threshold (recouping part of the  brand damage).
2. **Automated Lifecycle Email Campaigns:** Target the 53,000+ 5-star single buyers with category cross-sell discounts within 30-45 days of initial purchase. Converting even 5% of these happy users would yield **2,650 new repeat orders (~ incremental GMV)** with zero paid advertising spend.
3. **Regional Warehousing for High-Weight Electronics:** Move top 20 electronics SKUs closer to consumption centers to drop the 29.1% freight ratio.


---

## 🕵️‍♂️ FORENSIC CASE FILE: BRAZIL LOGISTICS & MACRO-ECONOMIC BREAKDOWN (2017-2018)
*Methodology: Human-Directed Business Hypothesis + AI-Augmented Investigative SQL Analysis*

### 📌 Exhibit A: Geopolitical Origin-to-Destination Disparity
- **Severe Seller Concentration:** **71.32% of all seller shipments originated from a single state: São Paulo (SP)**. Top 5 South/Southeast states (SP, MG, PR, RJ, SC) account for **94.76%** of all national e-commerce supply.
- **Intra-State vs Inter-State Friction:**
  - **Intra-State (Local SP):** Average delivery time was **7.9 Days**, Freight = **.45**, Delay rate = **4.45%**.
  - **Inter-State (Cross-Border):** Average delivery time was **15.0 Days (2x slower)**, Freight = **.63 (75% higher)**, Delay rate = **7.81%**.
- **The Northeast Regional Crisis:**
  - MA (Maranhão): **18.00% Delay Rate**, **21.6 Days average delivery time** (over 3 weeks!), Freight = **.49**!
  - CE (Ceará): **13.60% Delay Rate**, **20.9 Days delivery time**.
  - PI (Piauí): **13.58% Delay Rate**, **19.3 Days delivery time**.
  - BA (Bahia): **11.89% Delay Rate**, **19.2 Days delivery time**.

### 📌 Exhibit B: Macro-Economic & Legal Realities
1. **May 2018 Nationwide Truck Drivers' Strike (*Greve dos Caminhoneiros*):**
   - **Event:** An 11-day total shutdown of Brazilian federal highways in May 2018 due to diesel price surges.
   - **Data Proof in Mission #3:** Explains the sudden **-12.43% MoM revenue dip in June 2018**, when 71.9% of virtual e-commerce stores suffered severe delivery paralysis.
2. **2017 & 2018 National Postal Strikes (*Greve dos Correios*):**
   - **Event:** Recurrent strikes by the state postal monopoly (*Correios*), which marketplace sellers relied on, stranding parcels in sorting hubs for weeks.
3. **Brazilian Interstate Tax Bottlenecks (*ICMS DIFAL - EC 87/2015*):**
   - **Event:** Federal law required GNRE tax stamps per interstate parcel. E-commerce trucks traveling from São Paulo to the Northeast were detained for days at State Border Fiscal Checkpoints (*Postos Fiscais*) for manual tax validation.

### 📌 Exhibit C: Strategic Sourcing Recommendations
- **Regional 3PL Hubs in Northeast (Recife/Salvador):** Bypass interstate ICMS fiscal checkpoints and postal strikes by holding forward-deployed inventory in the Northeast.
- **Dynamic Delivery Estimates:** Auto-adjust estimated delivery dates for MA/CE/BA from 14 days to 24 days to prevent false SLA promises and eliminate the 1-star rage review penalty.


---

## 🎯 30-MINUTE INTERVIEW PREPARATION FLASHCARDS
*(Use this quick-sheet before entering any interview to refresh memory and never slip!)*

### Q1: "Walk me through this project in 60 seconds."
- **Model Answer:** *"I conducted a unit economics and supply chain diagnostic on Olist (100K+ Brazilian e-commerce orders) to investigate why net margins were declining despite strong GMV growth. I discovered that 71.3% of seller supply was concentrated in São Paulo, forcing cross-state transit to destinations like Rio and the Northeast. This interstate friction caused an average 12.4-day delivery delay, driving an 8x surge in 1-star reviews and directly causing  in churned customer revenue. Furthermore, cross-state freight created a  margin leakage, which I modeled can be mitigated via regional fulfillment centers."*

### Q2: "Why did you choose customer_unique_id instead of customer_id?"
- **Model Answer:** *"In Olist's relational architecture, customer_id is an order-level surrogate key generated per transaction. To track real human customer repeat behavior across multiple years, customer_unique_id is the true persistent identifier. Using customer_id would falsely show a 100% 1-time buyer rate."*

### Q3: "Explain your Month-over-Month (MoM) revenue query."
- **Model Answer:** *"I used a Common Table Expression (CTE) to aggregate monthly net sales using SUBSTRING(timestamp, 1, 7) and SUM(price). Then, I leveraged the LAG(sales, 1) OVER (ORDER BY sales_month) window function to pull the previous month's revenue onto the current row without an expensive self-join, computing percentage growth via ((Current - Prev) / Prev) * 100."*

### Q4: "Why was there a sudden drop in June 2018 sales?"
- **Model Answer:** *"Historical triangulation revealed that between May 21 and May 31, 2018, Brazil suffered the nationwide 'Greve dos Caminhoneiros' (Truck Drivers' Strike), shutting down federal highway logistics for 11 days. The e-commerce sector lost R$ 407M in sales, directly explaining our data's -12.43% MoM contraction in June 2018."*

### Q5: "How did you prove that local sourcing would save money?"
- **Model Answer:** *"I grouped sales by product category and compared average freight for intra-state vs inter-state routes. For heavy categories like Office Furniture, inter-state shipping carried an extra .76 freight penalty and +9 days delay. Across 70,328 interstate orders, the theoretical gap between local (.45) and cross-border (.63) freight represents a  margin recovery opportunity."*

### Q6: "Why did 97% of customers churn if they weren't discount hunters?"
- **Model Answer:** *"My query showed 96.3% of 1-time buyers paid full price, ruling out discount-seeking behavior. While 3,413 customers churned due to severe 12-day delivery delays, over 53,000 one-time buyers actually gave 5-star ratings. They never returned because Olist operated as an open marketplace with zero post-purchase retention marketing, customer lifecycle triggers, or cross-selling mechanisms."*
