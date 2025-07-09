# AWS Configuration
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ecommerce-etl-pipeline"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# RDS Configuration (Free Tier Optimized)
variable "rds_db_name" {
  description = "Name of the RDS database"
  type        = string
}

variable "rds_username" {
  description = "Master username for RDS"
  type        = string
  default     = "admin"
}

variable "rds_port" {
  description = "rds port"
  type        = number
  default     = 3306
}

variable "rds_host" {
  description = "rds host"
  type        = string
}

variable "rds_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
}

variable "rds_instance_class" {
  description = "RDS instance class (Free Tier: db.t3.micro)"
  type        = string
  default     = "db.t3.micro"  # Free Tier eligible
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB (Free Tier: 20GB)"
  type        = number
  default     = 20  # Free Tier limit
}

variable "rds_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0.35"
}

# Network Configuration
variable "vpc_id" {
  description = "VPC ID for RDS"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for RDS subnet group"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access RDS"
  type        = list(string)
}

# Glue Configuration (Free Tier Optimized)
variable "glue_version" {
  description = "Glue version"
  type        = string
  default     = "4.0"
}
 

variable "rds_security_group_id" {
  description = "rds security grroup id"
  type        = string
  default     = true
}

variable "raw_bucket" {
  description = "s3 bucket for raw data"
  type        = string
}

variable "processed_bucket" {
  description = "s3 bucket for transformed data"
  type        = string
}

variable "glue_artifacts_bucket" {
  description = "s3 bucket for glue scripts"
  type        = string
}

variable "s3_bucket_arns" {
  description = "s3 buckets arns"
  type        = list(string)
}