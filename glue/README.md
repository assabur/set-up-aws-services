# AWS Glue ETL Job with Terraform

This project demonstrates how to create and deploy an AWS Glue ETL job using Terraform. The Glue job processes salary data from an S3 bucket, performs aggregations by gender and department, and stores the results in a data lake architecture.

## 📋 Prerequisites

Before you begin, ensure you have the following:

1. **AWS CLI** installed and configured with appropriate credentials
   ```bash
   aws configure
   ```

2. **Terraform** installed (version >= 1.0)
   ```bash
   # Install via Homebrew (macOS)
   brew install terraform
   
   # Or download from https://www.terraform.io/downloads.html
   ```

3. **AWS Account** with permissions to create:
   - IAM roles and policies
   - S3 buckets and objects
   - Glue jobs and catalog databases

4. **Source Data**: Ensure your source data is available in the S3 bucket specified in the variables (default: `data-mentoring-dev-bucket`)

## 🏗️ Architecture

The Terraform configuration creates the following resources:

- **IAM Role**: Service role for the Glue job with necessary permissions
- **IAM Policies**: Custom policies for S3 access and Glue catalog operations
- **S3 Bucket**: For storing Glue ETL scripts
- **Glue Catalog Database**: For organizing metadata
- **Glue Job**: The ETL job with minimal worker configuration (2 workers)

## 📁 Project Structure

```
glue/
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable definitions
├── outputs.tf           # Output definitions
├── terraform.tf         # Backend configuration
├── demo-glue-etl.py     # Glue ETL script
└── README.md            # This file
```

## 🚀 Step-by-Step Deployment

### Step 1: Navigate to the Project Directory

```bash
cd /Users/aarigoni/aws-data-engineering/glue
```

### Step 2: Verify Your Data Setup

Ensure your source data is available:
- **Source file**: `s3://data-mentoring-dev-bucket/salary-data.csv`
- **Output path**: `s3://data-mentoring-dev-bucket/gold/`

### Step 3: Initialize Terraform

```bash
terraform init
```

This command downloads the required providers and initializes the working directory.

### Step 4: Review the Configuration

The configuration is already set up for your specific data paths. You can review it:

```bash
# View the planned deployment
terraform plan
```

The default configuration includes:
- Source: `s3://data-mentoring-dev-bucket/salary-data.csv`
- Output: `s3://data-mentoring-dev-bucket/gold/`
- Workers: 2 (G.1X type = 2 DPUs total)
- Database: `human_resources`

### Step 5: Deploy the Configuration

```bash
# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

Type `yes` when prompted to confirm the deployment. This process typically takes 2-5 minutes.

### Step 6: Verify the Deployment

After successful deployment, you can verify the resources:

```bash
# View all outputs
terraform output

# Check the Glue job
aws glue get-job --job-name $(terraform output -raw glue_job_name)

# List Glue jobs
aws glue list-jobs
```

## 🔧 Configuration Options

### Key Variables

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `aws_region` | AWS region for resources | `us-east-1` | `us-west-2` |
| `project_name` | Project name for resource naming | `glue-etl-demo` | `my-project` |
| `environment` | Environment name | `dev` | `prod` |
| `s3_bucket_name` | Source data S3 bucket | `data-mentoring-dev-bucket` | `my-data-bucket` |
| `number_of_workers` | Number of Glue workers | `2` | `5` |
| `worker_type` | Worker type (Standard/G.1X/G.2X) | `G.1X` | `G.2X` |
| `job_timeout` | Job timeout in minutes | `60` | `120` |

### Worker Configuration

The configuration uses minimal resources suitable for demo purposes:
- **Worker Type**: `G.1X` (1 DPU per worker)
- **Number of Workers**: `2` (2 DPUs total)
- **Total DPUs**: 2 (cost-effective for small datasets)

For production workloads, consider:
- Increasing `number_of_workers` for larger datasets
- Using `G.2X` worker type for memory-intensive operations
- Adjusting `job_timeout` based on expected processing time

## 🎯 Running the Glue Job

### Option 1: AWS Console

1. Navigate to AWS Glue Console
2. Go to "Jobs" in the left sidebar
3. Find your job: `{project_name}-etl-job`
4. Click "Run job"

### Option 2: AWS CLI

```bash
# Get the job name from Terraform output
JOB_NAME=$(terraform output -raw glue_job_name)

# Start the job
aws glue start-job-run --job-name $JOB_NAME

# Monitor job status
aws glue get-job-runs --job-name $JOB_NAME
```

### Option 3: Terraform (Trigger Job)

Add this to your `main.tf` to trigger the job:

```hcl
resource "aws_glue_job_run" "etl_job_run" {
  job_name = aws_glue_job.etl_job.name
  
  # Uncomment to auto-trigger on deployment
  # depends_on = [aws_glue_job.etl_job]
}
```

## 📊 Monitoring and Logs

### CloudWatch Logs

The job is configured to send logs to CloudWatch:
- Log Group: `/aws-glue/jobs/logs-v2`
- Log Stream: `{job_name}/{job_run_id}`

### CloudWatch Metrics

Monitor key metrics:
- `glue.driver.aggregate.numCompletedTasks`
- `glue.driver.aggregate.numFailedTasks`
- `glue.driver.aggregate.executorRunTime`

## 🗑️ Cleanup

To remove all created resources:

```bash
terraform destroy
```

Type `yes` when prompted. This will delete:
- Glue job
- Glue catalog database
- S3 bucket and objects
- IAM roles and policies

## 🔍 Troubleshooting

### Common Issues

1. **Permission Denied Errors**
   - Ensure your AWS credentials have sufficient permissions
   - Check IAM policies for S3 and Glue access

2. **S3 Bucket Not Found**
   - Verify the source data bucket exists
   - Update `s3_bucket_name` variable if needed

3. **Job Fails with Script Errors**
   - Check CloudWatch logs for detailed error messages
   - Verify the ETL script syntax and dependencies

4. **Resource Already Exists**
   - Use `terraform import` to import existing resources
   - Or modify resource names in variables

### Useful Commands

```bash
# Check Terraform state
terraform state list

# Show specific resource details
terraform state show aws_glue_job.etl_job

# Refresh state
terraform refresh

# Validate configuration
terraform validate

# Format configuration files
terraform fmt
```

## 📈 Next Steps

1. **Scale Up**: Increase worker count for larger datasets
2. **Add Triggers**: Set up CloudWatch Events or S3 triggers
3. **Data Validation**: Add data quality checks
4. **Monitoring**: Set up CloudWatch alarms
5. **CI/CD**: Integrate with GitHub Actions or AWS CodePipeline

## 🔗 Additional Resources

- [AWS Glue Documentation](https://docs.aws.amazon.com/glue/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Glue Pricing](https://aws.amazon.com/glue/pricing/)
- [Best Practices for AWS Glue](https://docs.aws.amazon.com/glue/latest/dg/best-practices.html)

## 📝 License

This project is provided as-is for educational and demonstration purposes.
