terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# Generate unique bucket suffix based on current timestamp
# This ensures the bucket name is globally unique
locals {
  account_id                   = data.aws_caller_identity.current.account_id
  s3_data_lake_bucket          = "data-mentoring-${local.account_id}-data-lake-${var.name_suffix}"
  bucket_name                  = var.s3_bucket_name != "" ? var.s3_bucket_name : local.s3_data_lake_bucket
  quicksight_service_role_name = "aws-quicksight-service-role-v0"
}

# Get current AWS account ID for use in resource names
data "aws_caller_identity" "current" {}

# ============================================================================
# S3 Data Lake Bucket
# ============================================================================

resource "aws_s3_bucket" "data_lake" {
  bucket        = local.bucket_name
  force_destroy = true

  tags = {
    Name = local.s3_data_lake_bucket
  }
}

# Enable versioning for data protection
resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Suspended"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Upload CSV file to S3 - Create directory first
resource "aws_s3_object" "sales_data" {
  bucket        = aws_s3_bucket.data_lake.id
  key           = "raw/sales/sales.csv"
  source        = var.csv_file_path
  etag          = filemd5(var.csv_file_path)
  storage_class = "STANDARD"

  depends_on = [
    aws_s3_bucket.data_lake,
    aws_s3_bucket_versioning.data_lake,
    aws_s3_bucket_public_access_block.data_lake,
    aws_s3_bucket_server_side_encryption_configuration.data_lake
  ]

  tags = {
    Name = "sales-raw-data-${var.name_suffix}"
  }
}

# ============================================================================
# IAM Role for Glue
# ============================================================================

resource "aws_iam_role" "glue_service_role" {
  name = "${var.project_name}-glue-role-${var.name_suffix}"

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
    Name = "${var.project_name}-glue-service-role-${var.name_suffix}"
  }
}

# Attach AWS managed Glue service role policy
resource "aws_iam_role_policy_attachment" "glue_service_policy" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Create inline policy for S3 access
resource "aws_iam_role_policy" "glue_s3_access" {
  name = "${var.project_name}-glue-s3-${var.name_suffix}"
  role = aws_iam_role.glue_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.data_lake.arn}/*"
      },
      {
        Sid    = "S3BucketList"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.data_lake.arn
      }
    ]
  })
}

# ============================================================================
# AWS Glue Database
# ============================================================================

resource "aws_glue_catalog_database" "sales_db" {
  name        = "${var.glue_database_name}-${var.name_suffix}"
  description = "Sales data analytics database for data lake"
  catalog_id  = data.aws_caller_identity.current.account_id

  tags = {
    Name = "${var.project_name}-glue-database-${var.name_suffix}"
  }
}

# ============================================================================
# AWS Glue Table
# ============================================================================

resource "aws_glue_catalog_table" "sales_table" {
  name          = "${var.glue_table_name}-${var.name_suffix}"
  database_name = aws_glue_catalog_database.sales_db.name
  catalog_id    = data.aws_caller_identity.current.account_id
  table_type    = "EXTERNAL_TABLE"
  description   = "Sales transactions data from CSV"

  # Define table parameters
  parameters = {
    EXTERNAL                 = "TRUE"
    "skip.header.line.count" = "1"
  }

  # Storage descriptor (schema and location)
  storage_descriptor {
    location      = "s3://${aws_s3_bucket.data_lake.id}/raw/sales/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim" = ","
      }
    }

    # Column definitions matching the CSV schema
    columns {
      name    = "order_id"
      type    = "bigint"
      comment = "Unique order identifier"
    }
    columns {
      name    = "order_date"
      type    = "string"
      comment = "Date of the order (YYYY-MM-DD)"
    }
    columns {
      name    = "product"
      type    = "string"
      comment = "Product name"
    }
    columns {
      name    = "category"
      type    = "string"
      comment = "Product category"
    }
    columns {
      name    = "region"
      type    = "string"
      comment = "Geographic region (US, EU, APAC, LATAM, MENA)"
    }
    columns {
      name    = "quantity"
      type    = "int"
      comment = "Quantity of items ordered"
    }
    columns {
      name    = "unit_price"
      type    = "double"
      comment = "Price per unit"
    }
    columns {
      name    = "total_amount"
      type    = "double"
      comment = "Total order amount (quantity * unit_price)"
    }
  }

}

# ============================================================================
# QuickSight Access
# ============================================================================

# Use the default QuickSight service role that AWS creates during QuickSight setup.
resource "aws_iam_role_policy_attachment" "quicksight_athena_access" {
  role       = local.quicksight_service_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSQuicksightAthenaAccess"
}

resource "aws_iam_role_policy_attachment" "quicksight_iam_access" {
  role       = local.quicksight_service_role_name
  policy_arn = "arn:aws:iam::${local.account_id}:policy/service-role/AWSQuickSightIAMPolicy"
}
