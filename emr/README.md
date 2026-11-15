# Overview
- Provisions an EMR cluster with Terraform and runs a PySpark aggregation step.
- Reads `hr-salary-data.csv` from S3 and writes Parquet outputs for Athena.
- Stores PySpark + EMR step shell scripts in a dedicated S3 scripts bucket.
- Demonstrates EMR + S3 + Athena integration with Parquet outputs.
- Produces analytics-ready data in a separate S3 bucket.

# Architecture
EMR reads raw CSV from S3, runs Spark, and writes Parquet to the analytics bucket for Athena.
```
┌──────────────────────┐    ┌──────────────────────┐
│   Local Data/        │    │   S3 Raw Bucket     │
│ hr-salary-data.csv   │───▶│   (CSV Input)        │
│                      │    │ data-mentoring-<account-id>-raw-aag │
└──────────────────────┘    └─────────┬────────────┘
                                   │
                                   ▼
                          ┌──────────────────────┐    ┌──────────────────────────┐
                          │   EMR Cluster        │───▶│   S3 Analytics Bucket   │
                          │   (Spark / PySpark)  │    │   (Parquet Output)      │
                          │   + Bootstrap        │    │ data-mentoring-<account-id>-analytics-aag │
                          └──────────────────────┘    └────────────┬─────────────┘
                                                             │
                                                             ▼
                                                    ┌──────────────────────────┐
                                                    │   Amazon Athena          │
                                                    │   (SQL Queries)          │
                                                    │   (SQL Queries)          │
                                                    └──────────────────────────┘
```

# Folder Structure
```
emr/
├── README.md          # Lab instructions
├── main.tf            # AWS resources and EMR step
├── variables.tf       # Input variables
├── outputs.tf         # Output values
├── bootstrap/         # EMR bootstrap script
├── scripts/           # PySpark job + EMR step shell scripts
└── data/              # Sample CSV input
```

# Naming Conventions
- S3 bucket pattern: `data-mentoring-<account-id>-<purpose>-aag`
- All bucket names end with `-aag`
Ensures global uniqueness across accounts and avoids collisions in shared environments.

# Prerequisites
- AWS credentials configured
- Terraform installed
- Default VPC available in the target region

# Deploy
```bash
cd emr/
terraform init
terraform plan
terraform apply
```

# Validate
- Raw data: `s3://data-mentoring-<account-id>-raw-aag/hr-salary-data.csv`
- Scripts bucket: `s3://data-mentoring-<account-id>-scripts-aag/`
- Analytics output: `s3://data-mentoring-<account-id>-analytics-aag/output/`
- Athena setup and query (department averages):
```sql
-- Create a database for the lab
CREATE DATABASE IF NOT EXISTS salary_analysis;

-- Register Parquet output as an external table
CREATE EXTERNAL TABLE IF NOT EXISTS salary_analysis.avg_salary_by_department (
  Department STRING,
  employee_count INT,
  avg_gross_salary DOUBLE,
  avg_net_salary DOUBLE
)
STORED AS PARQUET
LOCATION 's3://data-mentoring-<account-id>-analytics-aag/output/dept_averages/';

-- Sample query
SELECT * FROM salary_analysis.avg_salary_by_department LIMIT 10;
```

# Destroy
```bash
cd emr/
terraform destroy
```
Buckets are force-destroyed.

# Notes
- `force_destroy = true` deletes all objects in the buckets on destroy.
- Stop the cluster promptly to control costs.
