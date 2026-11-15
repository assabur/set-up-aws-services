# Overview
- Provisions a Redshift Serverless namespace and workgroup with Terraform.
- Creates an S3 bucket for staging data.
- Uses a dedicated IAM role for Redshift to access S3.

# Architecture
Redshift Serverless loads data from the staging bucket.
```
┌──────────────────────────────┐
│   S3 Staging Bucket           │
│ data-mentoring-<account-id>-staging-<name-suffix> │
└──────────────┬────────────────┘
               │
               ▼
┌──────────────────────────────┐
│   Redshift Serverless         │
│   workgroup + namespace       │
└──────────────┬────────────────┘
```

# Folder Structure
```
redshift/
├── README.md          # Lab instructions
├── main.tf            # AWS resources
├── variables.tf       # Input variables
└── outputs.tf         # Output values
```

# Naming Conventions
- S3 bucket pattern: `data-mentoring-<account-id>-<purpose>-<name-suffix>`
- `name_suffix` defaults to `aag` should be changed by students
- All resource names and Name tags end with `-<name-suffix>`

# Region
Default region is `us-east-1` and can be overridden with `aws_region`.

# Prerequisites
- AWS credentials configured
- Terraform installed
- AWS CLI installed (for optional validation steps)
- Default VPC available in the target region

# Deploy
Before you apply, update the default `name_suffix = "aag"` in `variables.tf`, or override it with a `terraform.tfvars` file.

Example `terraform.tfvars`:
```hcl
name_suffix = "yourinitials"
```

```bash
cd redshift/
terraform init
terraform plan
terraform apply
```

You can also override it on the command line:
```bash
terraform apply -var="name_suffix=yourinitials"
```

# Validate
- Staging bucket: `s3://data-mentoring-<account-id>-staging-<name-suffix>/`
- Sample CSV object: `s3://data-mentoring-<account-id>-staging-<name-suffix>/sales/sales_sample.csv`



# Connect To Database
In the Redshift query editor, connect to the `sales_analytics` database (this is created by the namespace).
Use the namespace-managed admin secret from:
```bash
terraform output redshift_admin_secret_arn
```

# Create Table
Run this in the Redshift query editor (or your SQL client):
```sql
CREATE TABLE IF NOT EXISTS public.sales (
  sale_date date,
  order_id int,
  customer_id varchar(10),
  product_sku varchar(20),
  product_name varchar(100),
  category varchar(50),
  region varchar(20),
  quantity int,
  unit_price decimal(10,2),
  discount decimal(10,2),
  total_amount decimal(10,2)
);
```

# COPY Command
Replace `<account-id>` with your AWS account ID and `<name-suffix>` with your configured suffix.
```sql
COPY public.sales
FROM 's3://data-mentoring-<account-id>-staging-<name-suffix>/sales/sales_sample.csv'
IAM_ROLE 'arn:aws:iam::<account-id>:role/redshift_s3_access_role-<name-suffix>'
CSV
IGNOREHEADER 1;
```

If `COPY` fails with `UnauthorizedException`, check:
- the IAM role is attached to the namespace
- the role trust policy includes both `redshift-serverless.amazonaws.com` and `redshift.amazonaws.com`
- your Redshift user has `ASSUMEROLE` for `COPY`

# Validate Load
```sql
SELECT COUNT(*) AS row_count FROM public.sales;
SELECT * FROM public.sales ORDER BY sale_date, order_id;
```

# Destroy
```bash
cd redshift/
terraform destroy
```
Buckets are force-destroyed.
