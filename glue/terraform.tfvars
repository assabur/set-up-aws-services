# Terraform variables for AWS Glue ETL Demo
# Configuration specific to your data setup

# AWS Configuration
aws_region = "us-east-1"

# Project Configuration
project_name = "glue-etl-demo"
environment  = "dev"

# Data Source Configuration
s3_bucket_name     = "data-mentoring-dev-bucket"
source_data_path   = "s3://data-mentoring-dev-bucket/salary-data.csv"
output_data_path   = "s3://data-mentoring-dev-bucket/gold/"

# Glue Catalog Configuration
catalog_database_name = "human_resources"

# Glue Job Configuration - Minimal setup for demo
glue_version      = "5.0"
worker_type       = "G.1X"    # 1 DPU per worker
number_of_workers = 2         # Total: 2 DPUs (cost-effective for demo)
job_timeout       = 60        # 1 hour timeout
