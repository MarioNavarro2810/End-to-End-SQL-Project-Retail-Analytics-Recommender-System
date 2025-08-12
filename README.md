# AdventurePro-Retail---SQL-Analytics-Recommendation-System
End-to-end SQL project on a synthetic multichannel retail dataset. Includes DB design, data cleaning, KPIs, advanced analytics (channels, margins, portfolio, segmentation) and a pure SQL item–item recommendation system using CTEs, window functions, joins, and indexing.

🎯 Objective
Using a synthetic dataset that simulates realistic multichannel retail sales (2015–2018), this project:

Builds a clean, normalized relational schema.

Prepares and integrates data for analysis.

Generates KPIs and advanced business analytics.

Implements a pure SQL item–item recommendation system.

📦 Dataset
All data is synthetically generated to mimic real-world sales, products, channels, and stores, avoiding any sensitive information.

🏗️ Modeling & Preparation
Integration & Cleaning

Created aggregated sales table (sales_agg) with calculated revenue (SUM(quantity * offer_price)), standardized date formats, and normalized keys.

Data Governance

Primary and foreign keys, constraints, and indexing for performance.

Operational Views

Order-level view to simplify analysis and reporting.

📊 Business Analysis
Channel performance ranking and revenue trends.

Top stores and quarterly revenue by country.

Margin and discount outlier detection (P90) with window functions.

Portfolio contribution analysis (top products = 90% revenue).

Detection of trending products.

Customer segmentation (2×2 matrix by orders/revenue).

Inactive customer detection for reactivation campaigns.

🤖 Recommendation System
Built using an item–item co-occurrence matrix.

Suggests products not yet purchased by each store.

Implemented fully in SQL without external tools.

🧪 SQL Techniques Used
CTEs, subqueries, window functions (ROW_NUMBER, PERCENT_RANK, CUME_DIST, LAG), complex joins, views, constraints, indexing, and performance optimization.

🚀 How to Run
Create the database and import initial tables (sales, products, channels, stores).

Run setup.sql to prepare aggregated tables, keys, and views.

Run analysis.sql for business KPIs and analytics.

Run recommendation.sql to generate product recommendations.
