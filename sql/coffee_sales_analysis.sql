/* =====================================================
   PROJECT: Maven Coffee Sales Analysis
   Author: Pavla Jirsíková Holubářová
   Tool: MySQL
   Description: SQL-based analysis of coffee shop sales data
===================================================== */


-- =====================================================
-- 1. DATABASE SETUP
-- =====================================================

CREATE DATABASE IF NOT EXISTS coffee_sales;
USE coffee_sales;


-- =====================================================
-- 2. DATA IMPORT & INITIAL INSPECTION
-- =====================================================

/* -------------------------------
   2.1 Create RAW table
---------------------------------- */

CREATE TABLE coffee_sales_raw (
    transaction_id TEXT,
    transaction_date TEXT,
    transaction_time TEXT,
    transaction_qty TEXT,
    store_id TEXT,
    store_location TEXT,
    product_id TEXT,
    unit_price TEXT,
    product_category TEXT,
    product_type TEXT,
    product_detail TEXT
);


/* -------------------------------
   2.2 Load CSV data
---------------------------------- */

-- IMPORTANT:
-- Update the file path in the LOAD DATA LOCAL INFILE statement
-- to match your local file location before running the script.
-- Alternatively, you can import the CSV file using
-- MySQL Workbench's Table Data Import Wizard.


LOAD DATA LOCAL INFILE 'path/to/coffee_sales.csv'
INTO TABLE coffee_sales_raw
FIELDS TERMINATED BY '|'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


/* -------------------------------
   2.3 Basic overview
---------------------------------- */

-- Total number of records
SELECT COUNT(*) 
FROM coffee_sales_raw;

-- Preview first 10 rows
SELECT *
FROM coffee_sales_raw
LIMIT 10;

-- Inspect table structure
DESCRIBE coffee_sales_raw;


/* -------------------------------
   2.4 Check uniqueness & dimensions
---------------------------------- */

-- Check if transaction_id is unique (Compare with total row count to confirm uniqueness)
SELECT COUNT(DISTINCT transaction_id) FROM coffee_sales_raw;

-- Number of stores
SELECT COUNT(DISTINCT store_id) FROM coffee_sales_raw;

-- Store locations overview
SELECT DISTINCT store_location FROM coffee_sales_raw;

-- Number of products
SELECT COUNT(DISTINCT product_id) FROM coffee_sales_raw;

-- Product categories overview
SELECT DISTINCT product_category FROM coffee_sales_raw;


/* -------------------------------
   2.5 Check value ranges (text-based, preliminary)
---------------------------------- */

-- Date range
SELECT 
    MIN(transaction_date),
    MAX(transaction_date)
FROM coffee_sales_raw;

-- Time range
SELECT 
    MIN(transaction_time),
    MAX(transaction_time)
FROM coffee_sales_raw;

-- Quantity range (text comparison, will validate after casting)
SELECT 
    MIN(transaction_qty),
    MAX(transaction_qty)
FROM coffee_sales_raw;

-- Unit price range (text comparison, will validate after casting)
SELECT 
    MIN(unit_price),
    MAX(unit_price)
FROM coffee_sales_raw;


/* -------------------------------
   2.6 Check missing values
---------------------------------- */

SELECT
    SUM(transaction_id IS NULL OR TRIM(transaction_id) = '') AS missing_transaction_id,
    SUM(transaction_date IS NULL OR TRIM(transaction_date) = '') AS missing_transaction_date,
    SUM(transaction_time IS NULL OR TRIM(transaction_time) = '') AS missing_transaction_time,
    SUM(transaction_qty IS NULL OR TRIM(transaction_qty) = '') AS missing_transaction_qty,
    SUM(store_id IS NULL OR TRIM(store_id) = '') AS missing_store_id,
    SUM(store_location IS NULL OR TRIM(store_location) = '') AS missing_store_location,
    SUM(product_id IS NULL OR TRIM(product_id) = '') AS missing_product_id,
    SUM(unit_price IS NULL OR TRIM(unit_price) = '') AS missing_unit_price,
    SUM(product_category IS NULL OR TRIM(product_category) = '') AS missing_product_category,
    SUM(product_type IS NULL OR TRIM(product_type) = '') AS missing_product_type,
    SUM(product_detail IS NULL OR TRIM(product_detail) = '') AS missing_product_detail
FROM coffee_sales_raw;


-- =====================================================
-- 3. DATA CLEANING
-- =====================================================

/* -------------------------------
   3.1 Create Clean Table
---------------------------------- */

CREATE TABLE coffee_sales_clean (
    transaction_id   INT,
    transaction_date DATE,
    transaction_time TIME,
    transaction_qty  INT,
    unit_price       DECIMAL(10,2),
    store_id         INT,
    store_location   VARCHAR(100),
    product_id       INT,
    product_category VARCHAR(100),
    product_type     VARCHAR(100),
    product_detail   VARCHAR(255)
);


/* -------------------------------
   3.2 Insert transformed data
---------------------------------- */

INSERT INTO coffee_sales_clean (
    transaction_id,
    transaction_date,
    transaction_time,
    transaction_qty,
    unit_price,
    store_id,
    store_location,
    product_id,
    product_category,
    product_type,
    product_detail
)
SELECT
    CAST(transaction_id AS UNSIGNED),
    CAST(transaction_date AS DATE),
    CAST(transaction_time AS TIME),
    CAST(transaction_qty AS UNSIGNED),
    CAST(unit_price AS DECIMAL(10,2)),
    CAST(store_id AS UNSIGNED),
    TRIM(store_location),
    CAST(product_id AS UNSIGNED),
    TRIM(product_category),
    TRIM(product_type),
    TRIM(product_detail)
FROM coffee_sales_raw;


/* -------------------------------
   3.3 Data Validation
---------------------------------- */

-- Validate row counts
SELECT COUNT(*) FROM coffee_sales_raw;
SELECT COUNT(*) FROM coffee_sales_clean;

-- Check for potential NULL values after conversion
SELECT 
    COUNT(*) AS total_rows,
    SUM(transaction_id IS NULL)   AS null_transaction_id,
    SUM(transaction_date IS NULL) AS null_transaction_date,
    SUM(transaction_qty IS NULL)  AS null_transaction_qty,
    SUM(unit_price IS NULL)       AS null_unit_price,
    SUM(store_id IS NULL)         AS null_store_id,
    SUM(product_id IS NULL)       AS null_product_id
FROM coffee_sales_clean;

-- Quick preview of cleaned data
SELECT *
FROM coffee_sales_clean
LIMIT 10;

-- Numeric range check
SELECT 
    MIN(transaction_qty) AS min_qty,
    MAX(transaction_qty) AS max_qty,
    MIN(unit_price)      AS min_price,
    MAX(unit_price)      AS max_price
FROM coffee_sales_clean;


-- =====================================================
-- 4. FEATURE ENGINEERING
-- =====================================================

/* -------------------------------
   4.1 Create dimension table: dim_store
---------------------------------- */

-- Confirm store_id uniquely determines store_location
SELECT store_id
FROM coffee_sales_clean
GROUP BY store_id
HAVING COUNT(DISTINCT store_location) > 1;

-- Create a store dimension table with unique store records
CREATE TABLE dim_store AS
SELECT DISTINCT
    store_id,
    store_location
FROM coffee_sales_clean;

-- Define primary key
ALTER TABLE dim_store
ADD PRIMARY KEY (store_id);

-- Confirm no duplicate store_id exists in dim_store
SELECT store_id, COUNT(*) AS cnt
FROM dim_store
GROUP BY store_id
HAVING COUNT(*) > 1;

-- Verify number of unique stores
SELECT COUNT(*) AS total_stores
FROM dim_store;


/* -------------------------------
   4.2 Create dimension table: dim_product
---------------------------------- */

-- Confirm product_id uniquely determines its attributes
SELECT product_id
FROM coffee_sales_clean
GROUP BY product_id
HAVING COUNT(DISTINCT product_category) > 1
    OR COUNT(DISTINCT product_type) > 1
    OR COUNT(DISTINCT product_detail) > 1;
    
-- Create product dimension with unique product records
CREATE TABLE dim_product AS
SELECT DISTINCT
    product_id,
    product_category,
    product_type,
    product_detail
FROM coffee_sales_clean;

-- Define primary key
ALTER TABLE dim_product
ADD PRIMARY KEY (product_id);

-- Confirm no duplicate product_id exists
SELECT product_id, COUNT(*) AS cnt
FROM dim_product
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Verify total number of unique products
SELECT COUNT(*) AS total_products
FROM dim_product;


/* -------------------------------
   4.3 Create fact table: fact_sales
---------------------------------- */

-- Fact table containing transactional sales data.
-- Each row represents one product sold within a transaction.
-- Revenue is calculated as quantity × unit price.

CREATE TABLE fact_sales AS
SELECT
    transaction_id,
    transaction_date,
    transaction_time,
    store_id,
    product_id,
    transaction_qty,
    unit_price,
    transaction_qty * unit_price AS revenue
FROM coffee_sales_clean;

-- Validate consistency of derived metric (revenue)
SELECT *
FROM fact_sales
WHERE revenue <> transaction_qty * unit_price;

-- Check that transaction_id is unique
SELECT transaction_id, COUNT(*) AS cnt
FROM fact_sales
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- Set transaction_id as primary key
ALTER TABLE fact_sales
ADD PRIMARY KEY (transaction_id);

-- Add foreign key constraints
ALTER TABLE fact_sales
ADD CONSTRAINT fk_store
FOREIGN KEY (store_id)
REFERENCES dim_store(store_id);

ALTER TABLE fact_sales
ADD CONSTRAINT fk_product
FOREIGN KEY (product_id)
REFERENCES dim_product(product_id);

-- Check for missing foreign keys
SELECT *
FROM fact_sales
WHERE store_id IS NULL
   OR product_id IS NULL;


-- =====================================================
-- 5. DATA MODEL VALIDATION
-- =====================================================

/* -------------------------------
   5.1 Verify Transaction Grain
---------------------------------- */

-- The dataset documentation describes transaction_id
-- as a unique identifier for each transaction.


-- Check whether multiple rows share the same timestamp and store
SELECT 
    transaction_date,
    transaction_time,
    store_id,
    COUNT(*) AS items_per_timestamp
FROM fact_sales
GROUP BY 
    transaction_date,
    transaction_time,
    store_id
HAVING COUNT(*) > 1;


-- Finding:
-- Multiple rows share the same timestamp and store,
-- indicating that each row represents one product sold
-- rather than a complete customer order.


/* -------------------------------
   5.2 Order-Level Consideration
---------------------------------- */

-- Since the data is stored at product level,
-- order-level metrics (e.g., Average Order Value)
-- require aggregation by transaction_date,
-- transaction_time, and store_id.


-- =====================================================
-- 6. SALES OVERVIEW
-- =====================================================

-- Objective:
-- Analyze overall sales performance, including
-- core business metrics and performance by store and product.

/* -------------------------------
   6.1 Create Order-Level View
---------------------------------- */

-- Reconstruct customer orders by aggregating line-level records.
-- Each row represents one customer order
CREATE VIEW v_orders AS
SELECT 
    transaction_date,
    transaction_time,
    store_id,
    SUM(revenue) AS order_revenue,
    SUM(transaction_qty) AS order_units
FROM fact_sales
GROUP BY 
    transaction_date,
    transaction_time,
    store_id;


/* -------------------------------
   6.2 Base Business Metrics
---------------------------------- */

-- Key performance indicators (KPIs) overview


-- Total Revenue
SELECT SUM(revenue) AS total_revenue
FROM fact_sales;

-- Total Units Sold
SELECT SUM(transaction_qty) AS total_units_sold
FROM fact_sales;

-- Average Price per Unit (weighted)
SELECT 
    ROUND(SUM(revenue) / SUM(transaction_qty), 2) AS avg_price_per_unit
FROM fact_sales;

-- Total Orders
SELECT COUNT(*) AS total_orders
FROM v_orders;

-- Average Order Value (AOV)
SELECT ROUND(AVG(order_revenue), 2) AS avg_order_value
FROM v_orders;

-- Average Units per Order
SELECT ROUND(AVG(order_units),2) AS avg_units_per_order
FROM v_orders;


-- Observation:
-- The business generates a high number of orders,
-- but the average order value is relatively low (~6).
-- Customers typically purchase fewer than two items per order.


/* -------------------------------
   6.3 Sales by Store
---------------------------------- */

-- Business Question:
-- How does each store contribute to total revenue?
-- Is revenue driven by order volume or higher order value?


-- Store Performance Overview
SELECT 
    ds.store_location,
    SUM(vo.order_revenue) AS total_revenue,
    ROUND(
        SUM(vo.order_revenue) /
        (SELECT SUM(order_revenue) FROM v_orders) * 100,
        2
    ) AS revenue_share_pct,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) /
        (SELECT COUNT(*) FROM v_orders) * 100,
        2
    ) AS order_share_pct,
    ROUND(AVG(vo.order_revenue), 2) AS avg_order_value
FROM v_orders vo
JOIN dim_store ds
    ON vo.store_id = ds.store_id
GROUP BY ds.store_location
ORDER BY total_revenue DESC;


-- Observation:
-- Revenue is evenly distributed across all stores (~33% each).
-- Lower Manhattan has fewer orders but the highest
-- average order value, suggesting higher spending per transaction.


/* -------------------------------
   6.4 Sales by Product
---------------------------------- */

-- Business Question:
-- Which product categories drive revenue?
-- Are top-performing products driven by volume or pricing?


-- Category Performance Overview
SELECT 
    dp.product_category,
    SUM(fs.revenue) AS total_revenue,
    ROUND(
        SUM(fs.revenue) /
        (SELECT SUM(revenue) FROM fact_sales) * 100,
        2
    ) AS revenue_share_pct,
    SUM(fs.transaction_qty) AS total_units,
    ROUND(
        SUM(fs.revenue) / SUM(fs.transaction_qty),
        2
    ) AS avg_price_per_unit
FROM fact_sales fs
JOIN dim_product dp
    ON fs.product_id = dp.product_id
GROUP BY dp.product_category
ORDER BY total_revenue DESC;


-- Observation:
-- Coffee and Tea together account for the majority of revenue,
-- driven primarily by high sales volume.


-- Top 10 Products by Revenue
SELECT 
    dp.product_detail,
    dp.product_type,
    SUM(fs.revenue) AS total_revenue,
    SUM(fs.transaction_qty) AS total_units,
    ROUND(
        SUM(fs.revenue) / SUM(fs.transaction_qty),
        2
    ) AS avg_price_per_unit
FROM fact_sales fs
JOIN dim_product dp
    ON fs.product_id = dp.product_id
GROUP BY 
    dp.product_detail,
    dp.product_type
ORDER BY total_revenue DESC
LIMIT 10;


-- Observation:
-- Top-performing products are primarily beverages.
-- Revenue is driven by strong volume at moderate price levels.


-- =====================================================
-- 7. TIME ANALYSIS
-- =====================================================

-- Objective:
-- Analyze sales performance across different time dimensions.

/* -------------------------------
   7.1 Monthly Performance Overview
---------------------------------- */

-- Business Question:
-- How does revenue change over time?


SELECT 
    DATE_FORMAT(transaction_date, '%Y-%m') AS sales_month,
    SUM(order_revenue) AS total_revenue,
    COUNT(*) AS total_orders,
    ROUND(AVG(order_revenue), 2) AS avg_order_value
FROM v_orders
GROUP BY DATE_FORMAT(transaction_date, '%Y-%m')
ORDER BY sales_month;


-- Observation:
-- Sales steadily increase over the period,
-- driven by higher order volume rather than higher spending per order.


/* -------------------------------
   7.2 Performance by Day of Week
---------------------------------- */

-- Business Question:
-- Are certain days stronger than others?


SELECT 
    DAYNAME(transaction_date) AS weekday,
    SUM(order_revenue) AS total_revenue,
    COUNT(*) AS total_orders,
    ROUND(AVG(order_revenue), 2) AS avg_order_value
FROM v_orders
GROUP BY 
    DAYNAME(transaction_date),
    WEEKDAY(transaction_date)
ORDER BY 
    WEEKDAY(transaction_date);
    
    
-- Observation:
-- Sales performance is relatively consistent across all days of the week,
-- with no strong weekday or weekend effect.    
    
    
/* -------------------------------
   7.3 Weekday vs Weekend Comparison
   Comparing average daily performance
---------------------------------- */

-- Business Question:
-- Does performance differ between weekdays and weekends?


-- Classify dates as Weekday or Weekend
-- and calculate average daily revenue and orders
SELECT 
    CASE 
        WHEN WEEKDAY(transaction_date) >= 5 THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    COUNT(DISTINCT transaction_date) AS number_of_days,
    SUM(order_revenue) AS total_revenue,
    ROUND(
        SUM(order_revenue) / COUNT(DISTINCT transaction_date),
        2
    ) AS avg_revenue_per_day,
    ROUND(
        COUNT(*) / COUNT(DISTINCT transaction_date),
        2
    ) AS avg_orders_per_day

FROM v_orders
GROUP BY 
	 CASE 
        WHEN WEEKDAY(transaction_date) >= 5 THEN 'Weekend'
        ELSE 'Weekday'
    END;


-- Observation:
-- No significant difference is observed between weekday
-- and weekend performance.


/* -------------------------------
   7.4 Performance by Hour of Day
---------------------------------- */

-- Business Question:
-- At what time of day is sales performance the strongest?


SELECT 
    HOUR(transaction_time) AS order_hour,
    SUM(order_revenue) AS total_revenue,
    COUNT(*) AS total_orders,
    ROUND(AVG(order_revenue), 2) AS avg_order_value
FROM v_orders
GROUP BY HOUR(transaction_time)
ORDER BY order_hour;


-- Observation:
-- Revenue and order volume peak during morning hours (8–10 AM),
-- indicating a strong morning demand pattern.
-- Performance declines steadily after 10 AM.


/* -------------------------------
   7.5 Average Hourly Performance per Day
---------------------------------- */

-- Business Question:
-- What is the average hourly performance per day?


-- Average hourly performance per day
-- (normalizing across individual dates)
SELECT 
    order_hour,
    ROUND(AVG(hourly_revenue), 2) AS avg_revenue_per_hour,
    ROUND(AVG(hourly_orders), 2) AS avg_orders_per_hour,
    ROUND(AVG(hourly_revenue) / AVG(hourly_orders), 2) AS avg_order_value
FROM (
    SELECT 
        transaction_date,
        HOUR(transaction_time) AS order_hour,
        SUM(order_revenue) AS hourly_revenue,
        COUNT(*) AS hourly_orders
    FROM v_orders
    GROUP BY 
        transaction_date,
        HOUR(transaction_time)
) t
GROUP BY order_hour
ORDER BY order_hour;


-- Observation:
-- The morning peak remains consistent
-- even when accounting for day-to-day differences.


/* -------------------------------
   7.6 Hourly Revenue by Store (Pivot)
---------------------------------- */

-- Business Question:
-- How does hourly performance differ across store locations?


SELECT 
    HOUR(vo.transaction_time) AS order_hour,

    SUM(CASE 
            WHEN ds.store_location = 'Lower Manhattan' 
            THEN vo.order_revenue 
            ELSE 0 
        END) AS lower_manhattan_revenue,

    SUM(CASE 
            WHEN ds.store_location = 'Astoria' 
            THEN vo.order_revenue 
            ELSE 0 
        END) AS astoria_revenue,

    SUM(CASE 
            WHEN ds.store_location = 'Hell''s Kitchen' 
            THEN vo.order_revenue 
            ELSE 0 
        END) AS hells_kitchen_revenue

FROM v_orders vo
JOIN dim_store ds
    ON vo.store_id = ds.store_id

GROUP BY order_hour
ORDER BY order_hour;


-- Observation:
-- While all stores peak in the morning, Lower Manhattan
-- is significantly more morning-driven, whereas Astoria
-- shows stronger performance later in the day.


/* -------------------------------
   7.7 Hourly Orders by Store (Pivot)
---------------------------------- */

-- Business Question:
-- Does order volume follow the same hourly pattern
-- across store locations?


SELECT 
    HOUR(vo.transaction_time) AS order_hour,

    SUM(CASE 
            WHEN ds.store_location = 'Lower Manhattan' 
            THEN 1 
            ELSE 0 
        END) AS lower_manhattan_orders,

    SUM(CASE 
            WHEN ds.store_location = 'Astoria' 
            THEN 1 
            ELSE 0 
        END) AS astoria_orders,

    SUM(CASE 
            WHEN ds.store_location = 'Hell''s Kitchen' 
            THEN 1 
            ELSE 0 
        END) AS hells_kitchen_orders

FROM v_orders vo
JOIN dim_store ds
    ON vo.store_id = ds.store_id

GROUP BY order_hour
ORDER BY order_hour;


-- Observation:
-- All stores peak in the morning.
-- Lower Manhattan declines sharply in the evening,
-- while Astoria maintains stronger late-day demand.


/*=====================================================
  8. STORE BEHAVIOR PROFILES
  =====================================================*/

-- Objective:
-- Analyze how store locations differ
-- in sales patterns and customer behavior.

/* -------------------------------
   8.1 Average Order Metrics by Store
---------------------------------- */

-- Business Question:
-- Do stores differ in average order value
-- and average number of items per order?


SELECT 
    ds.store_location,
    ROUND(AVG(vo.order_revenue), 2) AS avg_order_value,
    ROUND(AVG(vo.order_units), 2) AS avg_units_per_order
FROM v_orders vo
JOIN dim_store ds
    ON vo.store_id = ds.store_id
GROUP BY ds.store_location
ORDER BY avg_order_value DESC;


-- Observation:
-- Lower Manhattan shows the highest average order value
-- and average number of items per order, indicating higher spending
-- per transaction compared to other locations.


/* -------------------------------
   8.2 Morning Peak Revenue Share by Store (8–10)
---------------------------------- */

-- Business Question:
-- How dependent is each store on morning revenue?


-- Calculate the share of total revenue generated
-- between 8 AM and 10 AM
SELECT 
    ds.store_location,

    SUM(CASE 
            WHEN HOUR(vo.transaction_time) BETWEEN 8 AND 10 
            THEN vo.order_revenue 
            ELSE 0 
        END) AS morning_revenue,

    SUM(vo.order_revenue) AS total_revenue,

    ROUND(
        SUM(CASE 
                WHEN HOUR(vo.transaction_time) BETWEEN 8 AND 10 
                THEN vo.order_revenue 
                ELSE 0 
            END)
        / SUM(vo.order_revenue) * 100,
        2
    ) AS morning_share_pct

FROM v_orders vo
JOIN dim_store ds
    ON vo.store_id = ds.store_id

GROUP BY ds.store_location
ORDER BY morning_share_pct DESC;


-- Observation:
-- Hell’s Kitchen relies most heavily on morning revenue,
-- while Astoria is less dependent on the 8–10 AM window.


/* -------------------------------
   8.3 Weekend Revenue Share by Store
---------------------------------- */

-- Business Question:
-- How dependent is each store on weekend revenue?


-- Calculate the percentage of total revenue
-- generated during weekends
SELECT 
    ds.store_location,

    ROUND(
        SUM(CASE 
                WHEN WEEKDAY(vo.transaction_date) >= 5 
                THEN vo.order_revenue 
                ELSE 0 
            END)
        / SUM(vo.order_revenue) * 100,
        2
    ) AS weekend_share_pct

FROM v_orders vo
JOIN dim_store ds
    ON vo.store_id = ds.store_id

GROUP BY ds.store_location
ORDER BY weekend_share_pct ASC;


-- Observation:
-- Weekend dependence is consistent across all locations.


/* -------------------------------
   8.4 Basket Size Distribution
---------------------------------- */

-- Business Question:
-- What proportion of orders contain a single item
-- versus multiple items?


-- Classify orders by number of items
-- and calculate their overall share
SELECT 
    CASE 
        WHEN order_units = 1 THEN 'Single Item'
        ELSE 'Multiple Items'
    END AS basket_type,
    
    COUNT(*) AS total_orders,
    
    ROUND(
        COUNT(*) / (SELECT COUNT(*) FROM v_orders) * 100,
        2
    ) AS order_share_pct

FROM v_orders

GROUP BY basket_type;


-- Observation:
-- The majority of orders contain multiple items,
-- indicating that customers frequently purchase
-- more than one product per transaction.


/* -------------------------------
   8.5 Best-Selling Product per Store
---------------------------------- */

-- Business Question:
-- What are the top revenue-generating products
-- in each store location?


-- Rank products by revenue within each store
-- and select the top 3 per location
SELECT 
    store_location,
    product_type,
    product_detail,
    total_revenue
FROM (
    SELECT 
        ds.store_location,
        dp.product_type,
        dp.product_detail,
        SUM(fs.revenue) AS total_revenue,
        
        RANK() OVER (
            PARTITION BY ds.store_location
            ORDER BY SUM(fs.revenue) DESC
        ) AS revenue_rank
        
    FROM fact_sales fs
    JOIN dim_store ds
        ON fs.store_id = ds.store_id
    JOIN dim_product dp
        ON fs.product_id = dp.product_id
        
    GROUP BY 
        ds.store_location,
        dp.product_type,
        dp.product_detail
) ranked_products

WHERE revenue_rank <= 3;


-- Observation:
-- Hot chocolate products are the primary revenue drivers
-- across all stores. Hell’s Kitchen stands out,
-- with premium beans ranking among its top sellers.

