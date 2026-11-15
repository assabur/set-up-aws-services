# Terraform AWS S3 Bucket Setup

This Terraform configuration creates a secure S3 bucket with proper security configurations for an AWS data engineering project.

## What This Creates

**S3 Bucket:** `data-mentoring-dev-bucket` (globally unique name)

**Security Features:**
- Server-side encryption with AWS-managed KMS key
- Versioning disabled (suspended)
- All public access blocked

**Tags**: Team = "data"

## Prerequisites
Before running this Terraform code ensure you have: 

1. **Terraform installed** (version >= 1.12)
   
   ```bash
   # check if Terraform is installed
   terraform version

   # if not installed, download from: https://www.terraform.io/downloads
   ```

2. **AWS CLI configured** with appropriate credentials
   ```bash
   # check if AWS CLI is configured
   aws sts get-caller-identity
   
   # if not configured, run:
    aws configure
   ```
3. **AWS Permissions**: IAM user with S3 permissions (or AdministratorAccess for simplicity)
## Quick Start

1. Clone or navigate to this directory

```bash
cd /learn-terraform-get-started-aws
```
2. Initialize Terraform

```bash
terraform init
```
3. Review the execution plan 

```bash
terraform plan
```
4. Apply configuration

```bash
terraform apply
```

5. Verify the bucket was created

```bash
aws s3 ls | grep data-mentoring-dev-bucket
```

## Commands Reference

### Initialize Terraform

```bash
terraform init
```
Downloads the AWS provider and initializes the working directory.

### Plan Changes

```bash
terraform plan
```
Shows what terraform will do without making changes.


### Apply Changes

```bash
terraform apply
```
Creates the S3 bucket and applies all configurations.

### Destroy  Resources

```bash
terraform destroy
```
> **⚠️ Warning:** This will delete the S3 bucket and all its contents! 

### Check Status

```bash
terraform show
```
Displays the current state of your infrastructure.

## Configuration Details

### AWS Provider
- **Region**: us-east-1
- **Provider** Version: >= 6.0

### S3 Bucket Configuration

- **Bucket Name**: `data-mentoring-dev-bucket`
- **Versioning**: Suspended (disabled)
- **Encryption**: AWS KMS with `alias/aws/s3`
- **Public Access**: Completely blocked

## Troubleshooting

### Common Issues 

1. Bucket name already exists
 ```bash
Error: BucketAlreadyExists
```
- S3 bucket names must be globally unique
- Change the bucket name in `main.tf` line 3

2. Insufficient permissions
 ```bash
Error: AccessDenied
```
- Ensure your AWS credentials have the required S3 permissions
- Check your AWS IAM permissions

3. Region mismatch
 ```bash
Error: InvalidBucket Region
```
- Ensure your AWS CLI default region matches the provider region (us-east-1)

### Getting Help 

- Check terraform logs: `TF_LOG=DEBUG terraform apply`
- Verify AWS credentials: `aws sts get-caller-identity` 
- List existing buckets `aws s3 ls`

## Uploading Sample Data
This repository includes a sample log file (`sample_logs.txt`) with dummy data engineering pipeline logs that you can upload to your S3 bucket

#### Upload to logs folder

1. Upload the sample logs file to a logs folder 

```bash

aws s3 cp sample_logs.txt  s3://data-mentoring-dev-bucket/logs/
```

2. Verify the upload

```bash

aws s3 ls s3://data-mentoring-dev-bucket/logs/
```
3. Delete the bucket  and all files

**Note**: Even with `force_destroy=true`, S3 buckets with versioning or delete markers may still fail to delete automatically.

```bash
# Method 1: Try terraform destroy first (works if force_destroy is properly applied )
terraform destroy

# Method 2: If that fails, manually clean up first
# check for any object versions or delete markers 

aws s3api list-object-versions --bucket data-mentoring-dev-bucket

#Remove all delete markers and versions (run this for each object found)
aws s3api delete-object --bucket  data-mentoring-dev-bucket --key "logs/sample_logs.txt" --version-id "null"

# Then destroy the bucket 
terraform destroy

```


