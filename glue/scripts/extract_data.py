"""
Ecommerce ETL Pipeline - Modular and Idempotent Glue Job
Extracts data from RDS MySQL, transforms into star schema, and loads to S3
"""

import sys
import logging
from datetime import datetime
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import DataFrame
from pyspark.sql.functions import col

# -----------------------
# Job Argument Parsing
# -----------------------
args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "rds_connection",           # AWS Glue connection name to MySQL RDS
        "rds_db_name",              # Name of RDS database
        "data_lake_bucket",         # S3 target bucket
        "ingest_date"               # Date passed like: 2025-06-26
    ],
)

# -----------------------
# Job Context Initialization
# -----------------------
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# -----------------------
# Read Job Parameters
# -----------------------
rds_connection = args["rds_connection"]
rds_db_name = args["rds_db_name"]
data_lake_bucket = args["data_lake_bucket"]
ingest_date_str = args["ingest_date"]
ingest_date = datetime.strptime(ingest_date_str, "%Y-%m-%d")
current_date_partition = ingest_date.strftime("%Y_%m_%d")

# -----------------------
# Logger Setup
# -----------------------
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# -----------------------
# Helper Functions
# -----------------------

def extract_table(table: str) -> DataFrame:
    """Reads a table from RDS using Glue connection"""
    logger.info(f"Reading table: {table}")
    df = glueContext.create_dynamic_frame.from_options(
        connection_type="mysql",
        connection_options={
            "useConnectionProperties": "true",
            "dbtable": f"{rds_db_name}.{table}",
            "connectionName": rds_connection,
        }
    ).toDF()
    return df

def validate_dataframe(df: DataFrame, table: str, pk: str) -> bool:
    """Validates DataFrame by checking for nulls in primary key"""
    total = df.count()
    nulls = df.filter(col(pk).isNull()).count()
    logger.info(f"Table '{table}': total={total}, nulls_in_{pk}={nulls}")
    return nulls == 0


# Write as CSV Function
# -----------------------
def write_to_s3(df: DataFrame, table_name: str):
    output_path = f"s3://{raw_bucket}/{table_name}/{date_partition}/"
    df.coalesce(1).write.mode("overwrite").option("header", "true").csv(output_path)
    logger.info(f"Wrote {table_name} as CSV to {output_path}")

# -----------------------
# ETL Tables
# -----------------------
tables = [
    ("customers", "customer_id"),
    ("products", "product_id"),
    ("orders", "order_id"),
    ("order_items", "order_item_id"),
]

# -----------------------
# Run ETL for each table
# -----------------------
for table_name, pk_col in tables:
    df = extract_table(table_name)
    if not validate_dataframe(df, table_name, pk_col):
        raise Exception(f"Validation failed for {table_name}: nulls in {pk_col}")
    write_to_s3(df, table_name)

# -----------------------
# Commit Glue Job
# -----------------------
job.commit()
 