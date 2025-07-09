import sys
from datetime import datetime
from pyspark.sql.functions import col, current_timestamp, to_date, year, month, dayofmonth, date_format
from pyspark.sql.types import *

from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from awsglue.job import Job
from pyspark.context import SparkContext

# -----------------------
# Job Args
# -----------------------
args = getResolvedOptions(
    sys.argv, ['JOB_NAME', 'raw_bucket', 'processed_bucket', 'ingest_date']
)

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

raw_bucket = args['raw_bucket']
processed_bucket = args['processed_bucket']
# The ingest_date is used to construct the S3 path for raw CSVs.
# Ensure your raw data is partitioned by date in the format YYYY_MM_DD.
ingest_date = datetime.strptime(args['ingest_date'], '%Y-%m-%d').strftime('%Y_%m_%d')

# -----------------------
# Load Raw CSVs
# -----------------------
def load_csv(table_name, schema):
    """
    Loads CSV data from S3 into a Spark DataFrame.
    Assumes data is partitioned by date in S3: s3://{raw_bucket}/{table_name}/{ingest_date}/*.csv
    """
    path = f"s3://{raw_bucket}/{table_name}/{ingest_date}/*.csv"
    print(f"Loading CSV from path: {path}") # Debugging: Print the path being loaded
    return spark.read.option("header", "true").schema(schema).csv(path)

# -----------------------
# Define Schemas
# Updated schemas based on provided DDLs for 'orders' and 'order_items'
# -----------------------
product_schema = StructType([
    StructField("product_id", StringType()),
    StructField("name", StringType()),
    StructField("price", DoubleType()),
    StructField("category", StringType()),
    StructField("created_at", TimestampType()),
    StructField("stock", IntegerType()),
    StructField("description", StringType()),
    StructField("ingestion_timestamp", TimestampType()) # Assuming this is added by your ingestion process
])

customer_schema = StructType([
    StructField("customer_id", StringType()),
    StructField("name", StringType()),
    StructField("email", StringType()),
    StructField("created_at", TimestampType()),
    StructField("address", StringType()),
    StructField("phone", StringType()),
    StructField("ingestion_timestamp", TimestampType()) # Assuming this is added by your ingestion process
])

# Schema for the 'orders' table (order-level details)
orders_raw_schema = StructType([
    StructField("order_id", StringType()), # Changed to StringType for consistency with other IDs
    StructField("customer_id", StringType()), # Changed to StringType for consistency with other IDs
    StructField("order_date", TimestampType()), # Assuming your 'order_date' string can be cast to Timestamp
    StructField("total_amount", DoubleType()),
    StructField("status", StringType()),
    StructField("created_at", TimestampType()), # Assuming this is added by your ingestion process
    StructField("updated_at", TimestampType()) # Assuming this is added by your ingestion process
])

# Schema for the 'order_items' table (line-item details)
order_items_raw_schema = StructType([
    StructField("order_item_id", StringType()), # Changed to StringType for consistency with other IDs
    StructField("order_id", StringType()), # Changed to StringType for consistency with other IDs
    StructField("product_id", StringType()), # Changed to StringType for consistency with other IDs
    StructField("quantity", IntegerType()), # Changed to IntegerType as per common usage
    StructField("item_price", DoubleType()),
    StructField("created_at", TimestampType()) # Assuming this is added by your ingestion process
])


# -----------------------
# Load Tables
# -----------------------
df_products = load_csv("products", product_schema)
df_customers = load_csv("customers", customer_schema)
# Load both orders and order_items
df_orders_raw = load_csv("orders", orders_raw_schema)
df_order_items_raw = load_csv("order_items", order_items_raw_schema)

# Debugging: Print initial DataFrame counts
print(f"DEBUG: df_products count: {df_products.count()}")
print(f"DEBUG: df_customers count: {df_customers.count()}")
print(f"DEBUG: df_orders_raw count: {df_orders_raw.count()}")
print(f"DEBUG: df_order_items_raw count: {df_order_items_raw.count()}")


# -----------------------
# Create Fact Table (Fact_Orders) by joining orders and order_items
# -----------------------
# Join orders and order_items to create the fact_orders DataFrame
df_fact_orders = df_order_items_raw.join(
    df_orders_raw,
    on="order_id",
    how="inner" # Use inner join to ensure only matching orders and items are included
) \
.select(
    df_orders_raw["order_id"],
    df_orders_raw["customer_id"],
    df_order_items_raw["product_id"],
    df_order_items_raw["quantity"],
    df_order_items_raw["item_price"].alias("unit_price"), # Rename item_price to unit_price
    (df_order_items_raw["quantity"] * df_order_items_raw["item_price"]).alias("item_total"), # Calculate item_total
    df_orders_raw["order_date"], # Keep original order_date for date_key derivation
    df_orders_raw["status"],
    current_timestamp().alias("ingestion_timestamp") # Add a new ingestion timestamp for the fact table
)

# Derive date_key from order_date
df_fact_orders = df_fact_orders.withColumn("date_key", date_format("order_date", "yyyyMMdd")) \
    .select(
        "order_id", "customer_id", "product_id", "quantity", "unit_price", "item_total",
        "date_key", "status", "ingestion_timestamp"
    )

# Debugging: Print count of the final fact_orders DataFrame
print(f"DEBUG: df_fact_orders count after join and transformation: {df_fact_orders.count()}")


# -----------------------
# Create Dimension Tables
# -----------------------

# Date Dimension (still derived from orders, but ensuring full_date is correct)
df_dim_date = df_orders_raw \
    .select("order_date") \
    .withColumn("date_key", date_format("order_date", "yyyyMMdd")) \
    .withColumn("day", dayofmonth("order_date")) \
    .withColumn("month", month("order_date")) \
    .withColumn("year", year("order_date")) \
    .withColumn("full_date", to_date("order_date")) \
    .dropDuplicates(["date_key"])

# Customer Dimension
df_dim_customers = df_customers.select(
    "customer_id", "name", "email", "address", "phone", "created_at"
).dropDuplicates(["customer_id"])

# Product Dimension
df_dim_products = df_products.select(
    "product_id", "name", "category", "price", "stock", "description", "created_at"
).dropDuplicates(["product_id"])

# Debugging: Print counts of dimension DataFrames
print(f"DEBUG: df_dim_date count: {df_dim_date.count()}")
print(f"DEBUG: df_dim_customers count: {df_dim_customers.count()}")
print(f"DEBUG: df_dim_products count: {df_dim_products.count()}")


# -----------------------
# Write Star Schema to S3 (Parquet)
# -----------------------
def write_parquet(df, name):
    """
    Writes a Spark DataFrame to S3 as Parquet, overwriting existing data.
    """
    output_path = f"s3://{processed_bucket}/{name}/"
    print(f"Writing {name} to: {output_path}") # Debugging: Print output path
    df.write.mode("overwrite").parquet(output_path)

write_parquet(df_fact_orders, "fact_orders")
write_parquet(df_dim_customers, "dim_customers")
write_parquet(df_dim_products, "dim_products")
write_parquet(df_dim_date, "dim_date")

# -----------------------
# Commit Job
# -----------------------
job.commit()



     