

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Glue Connection for RDS
resource "aws_glue_connection" "rds_connection" {
  name = "${var.project_name}-${var.environment}-rds-connection"

  connection_type = "JDBC"  # REQUIRED

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:mysql://${var.rds_host}:${var.rds_port}/${var.rds_db_name}"
    SECRET_ID           = var.rds_password  # should be the full ARN of the secret
  }

  physical_connection_requirements {
    availability_zone      = "us-east-1b"      # e.g., "us-east-1a"
    subnet_id              = var.subnet_ids[2]
    security_group_id_list = [var.rds_security_group_id]
  }


}


# Glue Catalog Database
resource "aws_glue_catalog_database" "ecommerce" {
  name = "${var.project_name}_${var.environment}"
  
}

# Glue Job for ETL Processing
resource "aws_glue_job" "extarct_job" {
  name     = "${var.project_name}-${var.environment}-etl-job"
  role_arn = aws_iam_role.glue_role.arn
  connections = [aws_glue_connection.rds_connection.name]

  command {
    script_location = "s3://${var.glue_artifacts_bucket}/glue/scripts/extract_data.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"        = "python"
    "--enable-metrics"      = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--ingest_date"         = "2025-06-30"
    "--data_lake_bucket"       = var.raw_bucket
    "--rds_db_name" = var.rds_db_name
    "--rds_connection" = aws_glue_connection.rds_connection.name
    
  }

  execution_property {
    max_concurrent_runs = 2
  }

  number_of_workers = 2
  worker_type       = "G.1X"
  timeout           = 5

  glue_version = var.glue_version

}

resource "aws_glue_job" "transform_job" {
  name     = "${var.project_name}-${var.environment}-transform-job"
  role_arn = aws_iam_role.glue_role.arn

  command {
    script_location = "s3://${var.glue_artifacts_bucket}/glue/scripts/transform_data.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"        = "python"
    "--enable-metrics"      = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--raw_bucket"          = var.raw_bucket
    "--processed_bucket"    = var.processed_bucket
    "--ingest_date"         = "2025-06-30" # default; can override via CLI
  }

  execution_property {
    max_concurrent_runs = 2
  }

  number_of_workers = 2
  worker_type       = "G.1X"
  timeout           = 5

  glue_version = var.glue_version

}

# Glue Crawler for Raw Data
resource "aws_glue_crawler" "raw_data_crawler" {
  database_name = aws_glue_catalog_database.ecommerce.name
  name          = "${var.project_name}-${var.environment}-raw-crawler"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${var.raw_bucket}/"
  }

  schedule = "cron(0 0 * * ? *)"  # Run daily at midnight

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      Tables = { AddOrUpdateBehavior = "MergeNewColumns" }
    }
  })

}

# Glue Crawler for Processed Data
resource "aws_glue_crawler" "processed_data_crawler" {
  database_name = aws_glue_catalog_database.ecommerce.name
  name          = "${var.project_name}-${var.environment}-processed-crawler"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${var.processed_bucket}/"
  }

  schedule = "cron(0 2 * * ? *)"  # Run daily at 2 AM (after ETL job)

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      Tables = { AddOrUpdateBehavior = "MergeNewColumns" }
    }
  })

}



