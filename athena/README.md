# AWS Data Engineering - Query CSV file from Athena 

This project demonstrates how to upload salary data to an S3 bucket and create a database and table in Amazon Athena for data analysis.


## Overview

The workflow involves:
1. Uploading salary data CSV files to an S3 bucket
2. Creating a database in Amazon Athena
3. Creating an external table that references the S3 data
4. Querying the data for analysis

## S3 Bucket Structure

The S3 bucket is organized with the following folder structure:
```
s3://data-mentoring-dev-athena-bucket/
├── data/                    # Salary data CSV files
└── athena-query-results/    # Athena query results
```

Upload your salary data CSV files to the following S3 location:
```
s3://data-mentoring-dev-athena-bucket/data/
```

### Creating S3 Folders with Terraform

The S3 bucket and folders are created using Terraform. In S3, folders are created automatically when you upload objects with path prefixes, or you can create them explicitly using placeholder objects.

The Terraform configuration creates two folders:
- `data/` - For salary data CSV files
- `athena-query-results/` - For Athena query results

To add additional folders, add a new `aws_s3_object` resource to your `main.tf`:

```hcl
# Create a new folder
resource "aws_s3_object" "new_folder" {
  bucket = aws_s3_bucket.dev_bucket.id
  key    = "new-folder/"
  content = ""
}
```

**Note:** The trailing slash (`/`) in the key makes it appear as a folder in the AWS console.

### Expected Data Format

The salary data should be in CSV format with the following columns:
- `EmpID` (STRING) - Employee ID
- `Name` (STRING) - Employee name
- `Gender` (STRING) - Employee gender
- `DateOfBirth` (STRING) - Date of birth
- `Age` (INT) - Employee age
- `JoinDate` (STRING) - Date of joining
- `TenureInOrgInMonths` (INT) - Tenure in months
- `GrossPay` (DOUBLE) - Gross salary
- `NetPay` (DOUBLE) - Net salary
- `Deduction` (DOUBLE) - Deduction amount
- `DeductionPercentage` (DOUBLE) - Deduction percentage
- `JobTitle` (STRING) - Job title
- `Department` (STRING) - Department

**Important Notes:**
- The CSV file should have a header row (it will be skipped during table creation)
- Use comma (`,`) as the separator
- Use double quotes (`"`) for text fields that may contain commas

## Database and Table Creation

### Step 1: Create Database
Run the following query in Amazon Athena to create the database:
```sql
CREATE DATABASE IF NOT EXISTS human_resources;
```

### Step 2: Create External Table
Run the complete query from `athena-query.sql` to create the external table that references your S3 data:

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS human_resources.salary_data (
    EmpID                  STRING,
    Name                   STRING,
    Gender                 STRING,
    DateOfBirth            STRING,
    Age                    INT,
    JoinDate               STRING,
    TenureInOrgInMonths    INT,
    GrossPay               DOUBLE,
    NetPay                 DOUBLE,
    Deduction              DOUBLE,
    DeductionPercentage    DOUBLE,
    JobTitle               STRING,
    Department             STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    "separatorChar" = ',',
    "quoteChar"     = '"'
)
STORED AS TEXTFILE
LOCATION 's3://data-mentoring-dev-athena-bucket/data/'
TBLPROPERTIES ('skip.header.line.count'='1');
```

## Prerequisites

- AWS Account with appropriate permissions
- Amazon S3 bucket: `data-mentoring-dev-athena-bucket` (created by Terraform)
- Amazon Athena service access
- Salary data in CSV format matching the expected schema

## File Structure

```
athena/
├── README.md                    # This file
└── athena-query.sql            # SQL queries for database and table creation
```

## Complete Workflow

### Step 1: Create Infrastructure
```bash
# Navigate to the athena directory
cd athena/

# Initialize and apply Terraform
terraform init
terraform plan
terraform apply
```

### Step 2: Upload Salary Data
```bash
# Upload your salary data CSV file to the data folder
aws s3 cp salary-data.csv s3://data-mentoring-dev-athena-bucket/data/

# Verify the upload
aws s3 ls s3://data-mentoring-dev-athena-bucket/data/
```

### Step 3: Configure Athena Query Results Location
1. Open Amazon Athena in the AWS Console
2. Go to **Settings** (gear icon in the top right)
3. Set the **Query result location** to:
   ```
   s3://data-mentoring-dev-athena-bucket/athena-query-results/
   ```
4. Click **Save**

### Step 4: Create Database in Athena
1. Run the database creation query:
   ```sql
   CREATE DATABASE IF NOT EXISTS human_resources;
   ```

### Step 5: Create Table in Athena
1. Run the table creation query from `athena-query.sql`
2. Verify the table was created successfully

### Step 6: Test with Sample Queries
Try these sample queries to test your setup:

**Query 1: View all data**
```sql
SELECT * FROM human_resources.salary_data LIMIT 10;
```

**Query 2: Count total records**
```sql
SELECT COUNT(*) as total_employees FROM human_resources.salary_data;
```

**Query 3: Analyze by department**
```sql
SELECT 
    Department,
    COUNT(*) as employee_count,
    AVG(GrossPay) as avg_gross_pay
FROM human_resources.salary_data
GROUP BY Department
ORDER BY avg_gross_pay DESC;
```

