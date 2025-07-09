# Ecommerce ETL Pipeline

A modular, scalable, and cost-effective ecommerce data pipeline built with AWS services. This pipeline extracts data from RDS MySQL, transforms it into a star schema, and loads it into S3 for analytics with Athena.

## 🏗️ Architecture

```
RDS MySQL → AWS Glue ETL → S3 (Parquet) → Athena Queries
```

### Components
- **RDS MySQL**: Source database with ecommerce data (can be created via AWS Console or Terraform)
- **AWS Glue**: ETL processing with PySpark
- **S3**: Data lake storage (raw and processed data, can be created via AWS Console or Terraform)
- **Athena**: Serverless query service for analytics
- **IAM**: Secure access management
- **Secrets Manager**: Secure credential storage

## 📊 Data Model

### Star Schema Design
- **Fact Table**: `fact_sales` - Sales transactions
- **Dimension Tables**:
  - `dim_customer` - Customer information
  - `dim_product` - Product catalog
  - `dim_date` - Date/time dimensions

### Sample Athena Queries

After running the ETL job, you can query your data using Athena:

```sql
-- Top selling products
SELECT 
    p.product_name,
    p.category,
    SUM(f.quantity_sold) as total_quantity,
    SUM(f.item_sales_amount) as total_revenue
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.product_name, p.category
ORDER BY total_revenue DESC
LIMIT 10;

-- Customer lifetime value
SELECT 
    c.first_name,
    c.last_name,
    c.loyalty_status,
    COUNT(DISTINCT f.order_id) as total_orders,
    SUM(f.item_sales_amount) as total_spent
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.first_name, c.last_name, c.loyalty_status
ORDER BY total_spent DESC;

-- Monthly sales trend
SELECT 
    d.year,
    d.month,
    d.month_name,
    SUM(f.item_sales_amount) as monthly_revenue,
    COUNT(DISTINCT f.order_id) as total_orders
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;
```

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured
- Terraform installed (optional for IAM/Glue)
- VPC with subnets configured
- **RDS and S3 can be created via AWS Console or Terraform**

### Deployment

1. **Provision RDS and S3**:
   - You can create your RDS MySQL instance and S3 buckets via the AWS Console.
   - Note the RDS endpoint, database name, username, and password, as well as S3 bucket names.
   - If you use Terraform for these, follow the original steps below.

2. **Clone and configure**:
```bash
git clone <repository>
cd ecommerce_etl_pipeline/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
# If you created RDS/S3 manually, update variables to reference those resources
```

3. **Deploy infrastructure (IAM, Glue, etc.)**:
```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

4. **Upload ETL script**:
   - If you created the Glue artifacts S3 bucket manually, upload the script there:
```bash
aws s3 cp ../glue/scripts/ecommerce_etl.py s3://<your-glue-artifacts-bucket>/scripts/
```
   - If using Terraform, you can use the output variable as before.

5. **Run ETL job**:
   - Start the Glue job via the AWS Console or CLI, referencing the correct job name and S3 locations.

6. **Query with Athena**:
   - Open AWS Console → Athena
   - Create a database pointing to your S3 processed data bucket
   - Run the sample queries

## 📁 Project Structure

```
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
│   ├── 📄 terraform.tfvars
└── 🔧 glue/
    └── 📁 scripts/
        └── 📄 ecommerce_etl.py
```

## 🔧 Configuration

### Using Manually Created Resources
- If you create RDS and S3 via the AWS Console, update your Glue job and Athena configuration to use the correct endpoints, bucket names, and credentials.
- Ensure your RDS security group allows inbound MySQL (3306) from the Glue security group.
- You can still use Terraform for IAM roles, Glue jobs, and other resources.

### Required Variables (if using Terraform)
```hcl
# Network
vpc_id = "vpc-your-vpc-id"
subnet_ids = ["subnet-id-1", "subnet-id-2"]

# Database
rds_master_password = "your-secure-password"

# Security
allowed_cidr_blocks = ["your-ip-range/32"]
```

## 🔒 Security

- **Encryption**: All data encrypted at rest and in transit
- **IAM**: Least privilege access policies
- **Secrets Manager**: Secure credential storage
- **VPC**: Network isolation for RDS
- **S3**: Bucket policies and versioning

## 📈 Monitoring

### CloudWatch Logs
- Glue job execution logs
- RDS performance metrics
- S3 access logs


## 🛠️ Troubleshooting

### Common Issues

1. **RDS Connection Failed**
   - Check security group rules
   - Verify VPC and subnet configuration
   - Ensure RDS instance is available

2. **Glue Job Failed**
   - Check CloudWatch logs
   - Verify IAM permissions
   - Check S3 bucket access

3. **Athena Query Errors**
   - Verify data format (Parquet)
   - Check table schema
   - Ensure proper S3 permissions

### Debug Commands
```bash
# Check RDS status
aws rds describe-db-instances

# Monitor Glue job
aws glue get-job-runs --job-name your-job-name

# Check S3 data
aws s3 ls s3://your-processed-bucket --recursive
```

## 💰 Cost Optimization

- **Resource Sizing**: Use appropriate instance types
- **Scheduling**: Run ETL jobs during off-peak hours
- **Lifecycle**: Implement S3 lifecycle policies
- **Monitoring**: Set up cost alerts

## 🔄 Data Pipeline Flow

1. **Extract**: Glue reads from RDS MySQL
2. **Transform**: PySpark creates star schema
3. **Load**: Data saved to S3 as Parquet files
4. **Query**: Athena provides SQL access to data
5. **Analyze**: Business intelligence and reporting

## 📚 Additional Resources

- [Athena Setup Guide](ATHENA_SETUP_GUIDE.md)
- [Project Structure](PROJECT_STRUCTURE.md)
- [AWS Glue Documentation](https://docs.aws.amazon.com/glue/)
- [Amazon Athena Documentation](https://docs.aws.amazon.com/athena/)

---

**This project supports both fully automated (Terraform) and hybrid (manual + Terraform) workflows.** 

    








