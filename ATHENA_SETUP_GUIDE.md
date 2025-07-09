Athena Setup Guide for Ecommerce ETL Pipeline
🎯 Overview
This guide shows you how to set up Amazon Athena to query the processed data from your ecommerce ETL pipeline. Athena provides serverless SQL querying capabilities directly on your S3 data.

📋 Prerequisites 
✅ ETL pipeline deployed and running

✅ Data processed and stored in S3 (Parquet format)

✅ AWS Console access

✅ IAM permissions for Athena and S3

🚀 Step-by-Step Setup
Step 1: Access Athena Console
Open AWS Console

Navigate to Amazon Athena

Click Get Started (if first time)

Step 2: Set Up Query Result Location
In Athena console, click Settings

Set Query result location to your processed data bucket. Replace your-athena-query-results-bucket with your actual S3 bucket name for Athena query results.

s3://your-athena-query-results-bucket/

Click Save

Step 3: Create Database (If not already created by Glue Crawler)
If you are using a Glue Crawler to create your tables, the database will likely be created automatically. If not, run this in the Query Editor:

CREATE DATABASE ecommerce_analytics
LOCATION 's3://your-processed-data-bucket/' -- Replace with your processed data bucket

Step 4: Create Tables (Typically handled by Glue Crawler)
Your Glue Crawler should automatically create these table definitions in the Glue Data Catalog. If you need to manually create them (e.g., if you're not using a crawler or for reference), here are the DDL statements. Remember to replace your-processed-data-bucket with your actual S3 bucket name.

Customer Dimension Table
CREATE EXTERNAL TABLE dim_customer (
    customer_id INT,
    name STRING,
    email STRING,
    address STRING,
    processed_at TIMESTAMP
)
PARTITIONED BY (customer_id STRING)
STORED AS PARQUET
LOCATION 's3://your-processed-data-bucket/dimensions/customers/'
TBLPROPERTIES ('parquet.compression'='SNAPPY');

Product Dimension Table
CREATE EXTERNAL TABLE dim_product (
    product_id INT,
    name STRING,
    category STRING,
    price double,
    stock int,
    description STRING,
    created_at TIMESTAMP
)
PARTITIONED BY (product_id STRING)
STORED AS PARQUET
LOCATION 's3://your-processed-data-bucket/dimensions/products/'
TBLPROPERTIES ('parquet.compression'='SNAPPY');

Date Dimension Table
CREATE EXTERNAL TABLE dim_date (
    date_key INT,
    full_date DATE,
    day_of_week STRING,
    day_of_month INT,
    month INT,
    month_name STRING,
    quarter INT,
    year INT,
    is_weekend BOOLEAN,
    etl_processed_at TIMESTAMP,
)
PARTITIONED BY (date_key STRING)
STORED AS PARQUET
LOCATION 's3://your-processed-data-bucket/dimensions/dates/'
TBLPROPERTIES ('parquet.compression'='SNAPPY');

Sales Fact Table
CREATE EXTERNAL TABLE fact_orders (
    order_id INT,
    customer_id BIGINT,
    product_id BIGINT,
    date_key INT,
    quantity INT,
    unit_price DOUBLE,
    item_total DOUBLE,
    status STRING
)
PARTITIONED BY (order_id STRING)
STORED AS PARQUET
LOCATION 's3://your-processed-data-bucket/facts/sales/'
TBLPROPERTIES ('parquet.compression'='SNAPPY');

Step 5: Load Partitions (If using manual tables or after new data loads)
If your Glue Crawler is set up correctly, it will handle partition discovery. However, if you manually create tables or if new data arrives and the crawler isn't scheduled, you might need to run MSCK REPAIR TABLE to load new partitions:

-- Load partitions for all tables
MSCK REPAIR TABLE dim_customer;
MSCK REPAIR TABLE dim_product;
MSCK REPAIR TABLE dim_date;
MSCK REPAIR TABLE fact_sales;

📊 Sample Queries
1. Top Selling Products
SELECT
    p.name,
    p.category,
    SUM(f.quantity) as total_quantity,
    SUM(f.item_total) as total_revenue
FROM fact_orders f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.name, p.category
ORDER BY total_revenue DESC
LIMIT 10;

2. Customer Analysis
SELECT
    c.name,
    COUNT(DISTINCT f.order_id) as total_orders,
    SUM(f.item_total) as total_spent
FROM fact_orders f
JOIN dim_customers c ON f.customer_id = c.customer_id
GROUP BY c.name
ORDER BY total_spent DESC;

3. Monthly Sales Trend
SELECT
    d.year,
    d.month,
    SUM(f.item_total) as monthly_revenue,
    COUNT(DISTINCT f.order_id) as total_orders
FROM fact_orders f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month
ORDER BY d.year, d.month;


🔧 Optimization Tips
1. Partition Pruning
Always include partition columns in WHERE clauses:

SELECT * FROM fact_orders
WHERE order_id = '20241201_120000'
  AND date_key >= 20241201;

2. Column Projection
Only select needed columns:

-- Good
SELECT product_name, category FROM dim_product;

-- Avoid
SELECT * FROM dim_product;

3. Use Appropriate Data Types
Use INT for IDs and counts

Use DOUBLE for monetary values

Use STRING for text fields

4. Compression
Parquet with Snappy compression is already configured for optimal performance.

💰 Cost Optimization
Free Tier Limits
1TB data scanned/month included

$5 per TB after free tier

Cost-Saving Strategies
Use partitions to scan less data

Optimize queries to read only needed columns

Cache results for repeated queries

Use appropriate file sizes (64MB-1GB per file)

Monitor Costs
-- Check data scanned
SELECT
    data_scanned_in_bytes / 1024 / 1024 / 1024 as gb_scanned
FROM information_schema.query_history
WHERE query_text LIKE '%fact_orders%'
ORDER BY start_time DESC
LIMIT 10;

🛠️ Troubleshooting
Common Issues
1. Table Not Found
-- Check if table exists
SHOW TABLES IN ecommerce_analytics;

-- Check table structure
DESCRIBE dim_customer;

2. No Data Returned
-- Check if partitions are loaded
SHOW PARTITIONS fact_sales;

-- Check S3 location
SELECT COUNT(*) FROM fact_sales LIMIT 1;

3. Permission Denied
Verify IAM permissions for S3 and Athena

Check bucket policies

Ensure query result location is accessible

4. Slow Queries
Use partitions in WHERE clauses

Limit data scanned with date filters

Use appropriate file formats (Parquet)

🔄 Data Refresh
When new data is processed by your ETL pipeline:

New partitions are automatically created

Run MSCK REPAIR to load new partitions:

MSCK REPAIR TABLE fact_sales;
MSCK REPAIR TABLE dim_customer;
MSCK REPAIR TABLE dim_product;
MSCK REPAIR TABLE dim_date;

Happy querying! 🎉

Athena provides a powerful, serverless way to analyze your ecommerce data without managing any infrastructure. 