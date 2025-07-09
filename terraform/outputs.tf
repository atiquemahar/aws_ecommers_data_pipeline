# S3 Storage Outpu

# IAM Outputs
output "glue_service_role_arn" {
  description = "ARN of the IAM role for AWS Glue"
  value       = aws_iam_role.glue_role.arn
}

# Glue Outputs
output "glue_job_extract_name" {
  description = "Name of the Glue Extract ETL job"
  value       = aws_glue_job.extarct_job.name
}

output "glue_job_transform_name" {
  description = "Name of the Glue Transform ETL job"
  value       = aws_glue_job.transform_job.name
}

output "glue_database_name" {
  description = "Name of the Glue catalog database"
  value       = aws_glue_catalog_database.ecommerce.name
}

output "raw_data_crawler_name" {
  description = "Name of the raw data crawler"
  value       = aws_glue_crawler.raw_data_crawler.name
}

output "processed_data_crawler_name" {
  description = "Name of the processed data crawler"
  value       = aws_glue_crawler.processed_data_crawler.name
}
