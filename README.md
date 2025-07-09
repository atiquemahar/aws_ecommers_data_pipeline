Ecommerce ETL Pipeline
A modular, scalable, and cost-effective ecommerce data pipeline built with AWS services. This pipeline extracts data from RDS MySQL, transforms it into a star schema, and loads it into S3 for analytics with Athena.

🏗️ Architecture
RDS MySQL → AWS Glue ETL → S3 (Parquet) → Athena Queries




Components
RDS MySQL: Source database with ecommerce data (can be created via AWS Console or Terraform)

AWS Glue: ETL processing with PySpark

S3: Data lake storage (raw and processed data, can be created via AWS Console or Terraform)

Athena: Serverless query service for analytics

IAM: Secure access management

Secrets Manager: Secure credential storage

📊 Data Model
Star Schema Design
Fact Table: fact_orders - Sales transactions

Dimension Tables:

dim_customer - Customer information

dim_product - Product catalog

dim_date - Date/time dimensions

Sample Athena Queries
After running the ETL job, you can query your data using Athena:

-- Top selling products
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

-- Customer lifetime value
SELECT
    c.name,
    COUNT(DISTINCT f.order_id) as total_orders,
    SUM(f.item_total) as total_spent
FROM fact_orders f
JOIN dim_customers c ON f.customer_id = c.customer_id
GROUP BY c.name
ORDER BY total_spent DESC;

-- Monthly sales trend
SELECT
    d.year,
    d.month,
    SUM(f.item_total) as monthly_revenue,
    COUNT(DISTINCT f.order_id) as total_orders
FROM fact_orders f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month
ORDER BY d.year, d.month;




🚀 Quick Start
Prerequisites
AWS CLI configured

Terraform installed (optional for IAM/Glue)

VPC with subnets configured

RDS and S3 can be created via AWS Console or Terraform

Deployment
Provision RDS and S3:

You can create your RDS MySQL instance and S3 buckets via the AWS Console.

Note the RDS endpoint, database name, username, and password, as well as S3 bucket names.

If you use Terraform for these, follow the original steps below.

Clone and configure:

git clone <your-repository-url>
cd ecommerce_etl_pipeline/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values (e.g., RDS password, S3 bucket names)
# If you created RDS/S3 manually, update variables to reference those resources




Deploy infrastructure (IAM, Glue, etc.):

terraform init
terraform plan
terraform apply




Upload ETL script:

If you created the Glue artifacts S3 bucket manually, upload the script there:

aws s3 cp ../glue/scripts/ecommerce_etl.py s3://<your-glue-artifacts-bucket>/scripts/




If using Terraform, the S3 bucket for Glue artifacts will be an output variable.

Run ETL job:

Start the Glue job via the AWS Console or CLI, referencing the correct job name and S3 locations.

Query with Athena:

Open AWS Console → Athena

Create a database pointing to your S3 processed data bucket

Run the sample queries (refer to ATHENA_SETUP_GUIDE.md for detailed steps)

📁 Project Structure
ecommerce_etl_pipeline/
├── 📄 README.md
├── 📄 ATHENA_SETUP_GUIDE.md
├── 📄 PROJECT_STRUCTURE.md
├── 📄 requirements.txt
├── 🏗️ terraform/
│   ├── 📄 main.tf
│   ├── 📄 variables.tf
│   ├── 📄 outputs.tf
│   ├── 📄 providers.tf
│   ├── 📄 terraform.tfvars.example # Added .example for clarity
└── 🔧 glue/
    └── 📁 scripts/
        └── 📄 extract_data.py
        └── 📄 transform_data.py




🔧 Configuration
Using Manually Created Resources
If you create RDS and S3 via the AWS Console, update your Glue job and Athena configuration to use the correct endpoints, bucket names, and credentials.

Ensure your RDS security group allows inbound MySQL (3306) from the Glue security group.

You can still use Terraform for IAM roles, Glue jobs, and other resources.

Required Variables (if using Terraform)
# Network
vpc_id = "vpc-your-vpc-id" # Replace with your VPC ID
subnet_ids = ["subnet-id-1", "subnet-id-2"] # Replace with your subnet IDs

# Database
rds_master_password = "your-secure-password" # Replace with a strong password

# Security
allowed_cidr_blocks = ["your-ip-range"] # Replace with your IP range (e.g., "0.0.0.0/0" for public access, or your specific IP)




🔒 Security
Encryption: All data encrypted at rest and in transit

IAM: Least privilege access policies

Secrets Manager: Secure credential storage

VPC: Network isolation for RDS

S3: Bucket policies and versioning

📈 Monitoring
CloudWatch Logs
Glue job execution logs

RDS performance metrics

S3 access logs

🛠️ Troubleshooting
Common Issues
RDS Connection Failed

Check security group rules

Verify VPC and subnet configuration

Ensure RDS instance is available

Glue Job Failed

Check CloudWatch logs

Verify IAM permissions

Check S3 bucket access

Athena Query Errors

Verify data format (Parquet)

Check table schema

Ensure proper S3 permissions

Debug Commands
# Check RDS status
aws rds describe-db-instances

# Monitor Glue job
aws glue get-job-runs --job-name your-job-name

# Check S3 data
aws s3 ls s3://your-processed-bucket --recursive


💰 Cost Optimization
Resource Sizing: Use appropriate instance types

Scheduling: Run ETL jobs during off-peak hours

Lifecycle: Implement S3 lifecycle policies

Monitoring: Set up cost alerts

🔄 Data Pipeline Flow
Extract: Glue reads from RDS MySQL

Transform: PySpark creates star schema

Load: Data saved to S3 as Parquet files

Query: Athena provides SQL access to data

Analyze: Business intelligence and reporting

📚 Additional Resources
Athena Setup Guide

Project Structure

AWS Glue Documentation

Amazon Athena Documentation

This project supports both fully automated (Terraform) and hybrid (manual + Terraform) workflows.