# Maven Roasters Sales Analysis

This project analyzes transactional sales data from **Maven Roasters**, a fictional coffee shop based in New York City with three store locations.

---

## 📌 Project Overview

The goal of this project was to transform raw transaction-level data into a structured analytical model using a **star schema** design. After building the data model, I performed business analysis to identify key revenue drivers, customer purchasing patterns, and performance differences across store locations.

The project combines SQL-based data modeling with practical business insights.

---

## Key Steps

- Data cleaning and validation  
- Building a star schema (fact and dimension tables)  
- Creating order-level metrics from line-level data  
- Revenue and Average Order Value (AOV) analysis  
- Time-based sales analysis (monthly, daily, hourly)  
- Store-level performance and behavior comparison  

---

## Main Insights

- Key sales patterns over time  
- Revenue comparison across store locations  
- Customer purchasing behavior analysis  
- Store-level performance differences   

---

## Tools Used

- SQL  
- Relational data modeling (Star Schema)  
- Data analysis techniques

---  

## 📂 Dataset Description

The dataset contains sales transaction data from three **Maven Roasters** shops in New York City.

Each row represents a product sold within a transaction, uniquely identified by a combination of transaction and product.

The dataset includes:

- Transaction date and time
- Store ID and location
- Product category, type, and detail
- Quantity sold
- Unit price

This structure allows aggregation at product, order, store, and time levels.

---

### Data Analysis Levels

The structure of the dataset allows analysis on different levels:

- **Product-level** analysis  
- **Order-level** analysis (using aggregation)  
- **Store-level** comparison  
- **Time-based** analysis (day, weekday vs. weekend, hour of day)  

---

### Data Source

Maven Analytics – Public training dataset
Available on Kaggle: https://www.kaggle.com/datasets/agungpambudi/trends-product-coffee-shop-sales-revenue-dataset

--- 

## Data Modeling Approach

The raw dataset was transformed into a star schema model to support structured analysis.

### Fact Table

The central table, `fact_sales`, was created at a product-level grain.  
Each row represents one product sold within a transaction.

The fact table contains:

- Transaction ID
- Transaction date and time
- Store ID
- Product ID    
- Quantity
- Unit price  
- Revenue (calculated as quantity × unit price)

### Dimension Tables

Two dimension tables were created:

- `dim_store` – store information (store ID, location)  
- `dim_product` – product attributes (category, type, detail)  

This structure separates descriptive attributes from transactional data and allows efficient aggregation across stores, products, and time.

### Order-Level Aggregation

The grain of `fact_sales` is one row per product sold (line-level).

The dataset does not explicitly store customer orders. Therefore, orders had to be reconstructed by grouping records using:

- `transaction_date`
- `transaction_time`
- `store_id`

Based on this logic, a SQL view (`v_orders`) was created to aggregate line-level records into order-level data.

This reconstruction assumes that transactions with the same date, time, and store belong to a single customer order.

Each row in `v_orders` represents one customer order and includes:

- total order revenue
- total units per order

This approach allows correct calculation of order-level metrics such as Average Order Value (AOV).

---

## Key Insights

- The business generated $698.8K in revenue from 116.8K orders, 
  with an average order value of ~$6 and fewer than two items per order.

- Revenue is evenly distributed across the three locations (~33% each), 
  but Lower Manhattan achieves the highest average order value 
  and the highest number of items per order.

- Coffee and Tea account for over two-thirds of total revenue, 
  driven primarily by high sales volume at moderate price levels.

- Sales show a strong and consistent morning peak (8–10 AM), 
  which remains significant even after controlling for daily variation.

- Weekend performance is consistent across locations, 
  with no meaningful difference between weekday and weekend sales.

- 62% of orders contain multiple items, indicating frequent 
  cross-product purchasing behavior.

- Store behavior differs by time dependence: 
  Hell’s Kitchen is the most morning-driven location, 
  while Astoria shows a more balanced daily distribution.

---

## Limitations & Assumptions

- Customer orders were reconstructed using transaction date, time, and store ID, as no explicit order identifier was available.
- The dataset covers a limited time period (January–June 2023), which may not capture full seasonal patterns.
- No customer-level data was available, limiting behavioral segmentation analysis.
- Revenue analysis assumes consistent pricing and no returns or refunds.
- External factors (promotions, holidays, weather) were not included in the analysis.

--- 

## How to Run

1. Create the database.
2. Import the CSV file.
3. Execute the SQL script in order.


