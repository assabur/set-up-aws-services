# AWS Serverless Data Lake with QuickSight

Build a serverless analytics pipeline: **S3 → Glue → Athena → QuickSight**

## Overview

- Provisions S3 data lake bucket with versioning and encryption
- Creates AWS Glue database and table for data catalog
- Uploads sample CSV data (500 sales records) to S3
- Enables querying with Amazon Athena (SQL on S3)
- Connects to Amazon QuickSight for interactive dashboards
- Uses SPICE for fast, in-memory analytics

## Naming Conventions

This lab uses `name_suffix` for personalization (default: `aag`)

Resource names include your suffix:
- S3 bucket: `data-mentoring-ACCOUNT-ID-data-lake-aag`
- Glue database: `quicksight_sales_db-aag`
- Glue table: `sales-aag`
- IAM role: `data-lake-glue-role-aag-...`

To customize, edit `variables.tf` or run:
```bash
terraform apply -var="name_suffix=yourname"
```

## Folder Structure

```text
quicksight/
├── README.md                    # This file
├── main.tf                      # S3, Glue, IAM resources
├── variables.tf                 # Configuration variables
├── outputs.tf                   # Terraform outputs
├── .gitignore                   # Git ignore rules
├── data/
│   └── sales.csv                # 500 sample records
└── .terraform/                  # Terraform working directory (auto-generated)
```

## Architecture

Data flows from raw CSV in S3 through Glue catalog to Athena queries and QuickSight dashboards.

```
┌──────────────────────────────┐
│   Amazon S3                  │
│   Raw CSV data storage       │
│   (500 sales records)        │
└──────────────┬────────────────┘
               │
               ▼
┌──────────────────────────────┐
│   AWS Glue Catalog           │
│   Metadata & schema          │
│   (1 database, 1 table)      │
└──────────────┬────────────────┘
               │
               ▼
┌──────────────────────────────┐
│   Amazon Athena              │
│   SQL queries on S3          │
│   (pay per TB scanned)       │
└──────────────┬────────────────┘
               │
               ▼
┌──────────────────────────────┐
│   Amazon QuickSight          │
│   Interactive dashboards     │
│   (SPICE: fast, in-memory)   │
└──────────────────────────────┘
```

---

## Quick Start

## Important

⚠️ Before deploying or connecting QuickSight, check **Lake Formation → Catalog settings** and confirm both of these are set to `Yes`:
- `Use only IAM access control for new databases`
- `Use only IAM access control for new tables in new databases`

If those are not enabled, Lake Formation can override IAM-based Glue/Athena access and QuickSight may not be able to list your tables.

### 1. Prerequisites

- AWS Account with credentials configured
- Terraform installed
- QuickSight enabled (free tier available)

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review resources to be created
terraform plan

# Deploy (creates S3, Glue database/table, IAM role)
terraform apply
```

After deployment, note these outputs:
- `s3_bucket_name`: Your data lake bucket
- `glue_database_name`: Database for Athena
- `glue_table_name`: Table with sales data

### 3. Verify Deployment

```bash
# Check S3 bucket
aws s3 ls s3://$(terraform output -raw s3_bucket_name)/raw/sales/ \
  --region us-east-1

# Check Glue database
aws glue get-database \
  --name $(terraform output -raw glue_database_name) \
  --region us-east-1
```

---

## 4. Query Data with Athena

1. Open **AWS Athena console**
2. Select database: `quicksight_sales_db-aag` (or your suffix)
3. Run this query:

```sql
SELECT
   category,
   region,
   COUNT(*) as order_count,
   ROUND(SUM(total_amount), 2) as total_sales,
   ROUND(AVG(total_amount), 2) as avg_order
FROM "quicksight_sales_db-aag"."sales-aag"
GROUP BY category, region
ORDER BY total_sales DESC;
```

✅ If you see results, your data pipeline is working!

---

## 5. Build a Dashboard in QuickSight

⚠️ **WARNING: QuickSight charges per user (not per query)**
- Author Edition: **$18/month** per user
- **Always delete your QuickSight account after testing to avoid unnecessary charges**
- You can re-enable it later if needed

### What is QuickSight?

**Amazon QuickSight** is a fast, cloud-native business intelligence (BI) service that:
- 📊 Connects to multiple data sources (Athena, Redshift, RDS, S3, etc.)
- 🎨 Creates interactive dashboards with drag-and-drop
- ⚡ Uses SPICE for lightning-fast queries
- 💰 Charges per user, not per query
- 🔄 Supports real-time data refresh

### What is SPICE?

**SPICE** = **Super-fast, Parallel, In-memory Calculation Engine**

**Benefits:**
- ⚡ **10-100x faster** than querying raw data
- 💾 **In-memory storage**: Data lives in SPICE, not S3
- 🔒 **Data isolation**: Encrypted at rest
- 📈 **Scales automatically**: Handle millions of rows
- 💰 **Predictable costs**: Pay for GB stored, not queries run

**How it works:**
```
Athena (queries S3) → SPICE (caches in memory) → QuickSight (instant dashboards)
```

**When to use SPICE:**
- ✅ Dashboards accessed frequently
- ✅ Data under 25 GB (free tier: 10 GB SPICE capacity)
- ✅ Sub-second query response needed

**When to use Direct Query:**
- ✅ Large datasets (> 100 GB)
- ✅ Infrequent access
- ✅ Real-time data (updates constantly)

---

## 6. Step-by-Step: Create Your First Dashboard

### Step 1: Enable QuickSight (if not already)

1. Go to **AWS QuickSight console**
2. Click **Sign up for QuickSight**
3. Choose **Standard Edition** (free tier available)
4. Complete setup

### Step 2: Create Athena Data Source

1. In QuickSight, go to **Manage data**
2. Click **New dataset**
3. Choose **Athena**
4. Name it: `Sales Analytics`
5. Select:
   - Database: `quicksight_sales_db-aag`
   - Table: `sales-aag`
6. Click **Create dataset**

### Step 3: Choose SPICE or Direct Query

A dialog appears asking about query mode:

```
┌─────────────────────────────────────┐
│ Directly query your data (Athena)?  │
│                                     │
│ ☑ Import to SPICE for faster query │
│ ☐ Use Direct Query                  │
└─────────────────────────────────────┘
```

**For this tutorial: Select "Import to SPICE"**
- Faster queries
- Better for dashboards
- Free tier includes 10 GB SPICE

Click **Edit/Preview data** → **Save & visualize**

### Step 4: Create Your First Visualization

**Chart 1: Sales by Category (Bar Chart)**

1. Under **Fields**, drag:
   - `category` → X-axis
   - `total_amount` → Value (aggregated as Sum)

2. In the visual settings:
   - Click **Format visual**
   - Title: "Total Sales by Category"
   - Rotate X-axis labels 45°

3. Visual appears with bars showing sales per category

**Chart 2: Sales by Region (Pie Chart)**

1. Click **+ Add** (new visual)
2. Change chart type to **Pie chart**
3. Drag:
   - `region` → Group/Color
   - `total_amount` → Value

4. Title: "Sales Distribution by Region"

**Chart 3: Orders Over Time (Line Chart)**

1. Click **+ Add** (new visual)
2. Change chart type to **Line chart**
3. Drag:
   - `order_date` → X-axis
   - `order_id` → Value (count)

4. Title: "Orders by Day"

**Chart 4: Key Metrics (KPI)**

1. Click **+ Add** (new visual)
2. Change chart type to **KPI**
3. Drag:
   - `total_amount` → Value (sum)

4. Title: "Total Revenue"

### Step 5: Arrange and Publish Dashboard

1. Resize and rearrange charts on canvas
2. Click **Save** (top right)
3. Name: `Sales Analytics Dashboard`
4. Choose **Save as new dashboard**
5. Click **Publish** to share with team

---

## 10. Key Learnings

✅ **Infrastructure as Code**: Define AWS resources in Terraform
✅ **Data Lake Architecture**: Raw data (S3) → Metadata (Glue) → Queries (Athena)
✅ **SPICE Cache**: In-memory analytics engine for fast dashboards
✅ **QuickSight Dashboards**: Visual storytelling with data
✅ **Serverless**: No servers to manage, pay only for what you use

---

## 11. Cost Estimate

### AWS Free Tier Coverage

| Service | Free Tier | Monthly Cost |
|---------|-----------|-------------|
| **S3** | 5 GB storage + 20K GET | ~$0 (under limits) |
| **Glue Catalog** | 1 million objects | **FREE** ✅ |
| **Athena** | First 1 TB scanned/month | **FREE** ✅ (after ~$5) |
| **IAM** | Unlimited users/roles | **FREE** ✅ |

### Full Cost Breakdown (if over free tier)

| Service | Usage | Cost | Free Tier? |
|---------|-------|------|-----------|
| **S3 Storage** | 50 GB | ~$1.15/month | Yes (5GB free) |
| **S3 Data Transfer** | 100 GB out | ~$0.50* | No |
| **Glue Catalog** | 1M objects | **$0** | Yes ✅ |
| **Athena Queries** | 1 TB scanned | ~$5/month | Partial (1TB free) |
| **QuickSight** | 1 Standard user | **$9-18/month** | **NO - PAID** ⚠️ |
| **SPICE** | 10 GB | **Included** | Yes ✅ |
| **TOTAL (with QuickSight)** | | **~$15-25/month** | |
| **TOTAL (without QuickSight)** | | **~$5-8/month** | |

*Data transfer varies; often free within AWS/same region

### Cost Optimization Tips

1. **Use AWS Free Tier**: New accounts get free tier for 12 months
2. **Delete QuickSight when done**: Unsubscribe immediately after testing
3. **Keep data under free tier limits**:
   - S3: < 5 GB
   - Athena: < 1 TB/month
   - Glue: < 1 million objects
4. **Use SPICE**: Included in free tier, reduces Athena scans

---

## 12. Cleanup

Delete all resources when done:

```bash
# Remove QuickSight datasets/dashboards manually first
# Then destroy infrastructure (automatically deletes all S3 objects):
terraform destroy

# Confirm by typing 'yes'
```

**What gets destroyed:**
1. ✅ S3 bucket (and all objects inside - `force_destroy = true`)
2. ✅ Glue database and table
3. ✅ IAM role and policies
4. ⚠️ QuickSight must be manually deleted (see below)

**Manual cleanup required:**
1. **QuickSight** → Manage data → Delete all datasets
2. **QuickSight** → Dashboards → Delete all dashboards
3. **QuickSight** → Account settings → Unsubscribe from service
4. Then run `terraform destroy`

---

## 13. Troubleshooting

**Athena shows no data:**
```bash
# Verify CSV is in S3
aws s3 ls s3://$(terraform output -raw s3_bucket_name)/raw/sales/

# Verify Glue table schema
aws glue get-table \
  --database-name $(terraform output -raw glue_database_name) \
  --name $(terraform output -raw glue_table_name) \
  --region us-east-1
```

**QuickSight: "Access Denied" to Athena:**
1. Go to **QuickSight → Account settings → Account overview**
2. Click **Manage QuickSight access**
3. Enable **Athena** permission
4. Click **Update**

**SPICE import fails:**
1. Check data size (< 2 GB for free tier)
2. Wait a few minutes and retry
3. Consider using Direct Query instead

---

## Next Steps

🚀 **After this lab:**
- Connect QuickSight to other data sources (Redshift, RDS)
- Create row-level security for multi-user dashboards
- Set up automated data refresh schedules
- Use QuickSight Q for natural language queries

---

## Resources

- [QuickSight Documentation](https://docs.aws.amazon.com/quicksight/)
- [SPICE Pricing](https://aws.amazon.com/quicksight/pricing/)
- [Athena SQL Reference](https://docs.aws.amazon.com/athena/latest/ug/querying-supported-statements.html)

---

*Last updated: March 2026*
*Difficulty: Beginner → Intermediate*
