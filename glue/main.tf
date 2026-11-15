# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# IAM Role for Glue Job
resource "aws_iam_role" "glue_job_role" {
  name = "${var.project_name}-glue-job-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-glue-job-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Policy for Glue Job
resource "aws_iam_role_policy" "glue_job_policy" {
  name = "${var.project_name}-glue-job-policy"
  role = aws_iam_role.glue_job_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.glue_scripts_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.glue_scripts_bucket.bucket}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetTable",
          "glue:GetTableVersion",
          "glue:GetTableVersions",
          "glue:CreateTable",
          "glue:UpdateTable",
          "glue:DeleteTable",
          "glue:GetDatabase",
          "glue:CreateDatabase",
          "glue:UpdateDatabase",
          "glue:DeleteDatabase",
          "glue:GetPartitions",
          "glue:BatchCreatePartition",
          "glue:BatchDeletePartition",
          "glue:BatchGetPartition",
          "glue:GetPartition"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach AWS managed policy for Glue service role
resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_job_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Glue Catalog Database - Import existing database
# Run: terraform import aws_glue_catalog_database.hr_database human_resources
resource "aws_glue_catalog_database" "hr_database" {
  name        = var.catalog_database_name
  description = "Database for human resources data"

  tags = {
    Name        = var.catalog_database_name
    Environment = var.environment
    Project     = var.project_name
  }
}

# S3 Bucket for Glue Job Scripts
resource "aws_s3_bucket" "glue_scripts_bucket" {
  bucket = "${var.project_name}-glue-scripts-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "${var.project_name}-glue-scripts"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Random string for bucket suffix
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Upload the Glue ETL script to S3
resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.glue_scripts_bucket.id
  key    = "scripts/demo-glue-etl.py"
  source = "demo-glue-etl.py"
  etag   = filemd5("demo-glue-etl.py")

  tags = {
    Name        = "glue-etl-script"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Glue Job
resource "aws_glue_job" "etl_job" {
  name         = "${var.project_name}-etl-job"
  role_arn     = aws_iam_role.glue_job_role.arn
  description  = "ETL job for processing salary data"
  
  # Command block for Glue job
  command {
    script_location = "s3://${aws_s3_bucket.glue_scripts_bucket.bucket}/${aws_s3_object.glue_script.key}"
    python_version  = "3"
  }
  
  # Glue version
  glue_version = var.glue_version
  
  # Worker configuration
  worker_type       = var.worker_type
  number_of_workers = var.number_of_workers
  
  # Job timeout in minutes
  timeout = var.job_timeout
  
  # Job parameters
  default_arguments = {
    "--job-language"           = "python"
    "--job-bookmark-option"    = "job-bookmark-disable"
    "--enable-metrics"         = ""
    "--enable-continuous-cloudwatch-log" = "true"
    "--additional-python-modules" = "pyspark"
  }

  # Tags
  tags = {
    Name        = "${var.project_name}-etl-job"
    Environment = var.environment
    Project     = var.project_name
  }
}
