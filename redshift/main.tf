terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  account_id = data.aws_caller_identity.current.account_id

  s3_staging_bucket = "data-mentoring-${local.account_id}-staging-${var.name_suffix}"

  redshift_namespace_name = "redshift-sales-analytics-namespace-${var.name_suffix}"
  redshift_workgroup_name = "redshift-sales-analytics-workgroup-${var.name_suffix}"

  redshift_s3_role_name   = "redshift_s3_access_role-${var.name_suffix}"
  redshift_s3_policy_name = "redshift_s3_access_policy-${var.name_suffix}"

  redshift_sg_name = "redshift_workgroup_sg-${var.name_suffix}"
}

resource "aws_s3_bucket" "redshift_staging_bucket_aag" {
  bucket        = local.s3_staging_bucket
  force_destroy = true

  tags = {
    Name = local.s3_staging_bucket
  }
}

resource "aws_s3_bucket_public_access_block" "redshift_staging_bucket_aag" {
  bucket                  = aws_s3_bucket.redshift_staging_bucket_aag.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "sales_sample_csv" {
  bucket = aws_s3_bucket.redshift_staging_bucket_aag.id
  key    = "sales/sales_sample.csv"

  source       = "${path.module}/data/sales_sample.csv"
  content_type = "text/csv"

  depends_on = [aws_s3_bucket_public_access_block.redshift_staging_bucket_aag]
}

resource "aws_iam_role" "redshift_s3_access_role_aag" {
  name = local.redshift_s3_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        # Serverless COPY can fail to fetch credentials unless both
        # Redshift service principals are trusted by the IAM role.
        Principal = {
          Service = [
            "redshift-serverless.amazonaws.com",
            "redshift.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = local.redshift_s3_role_name
  }
}

resource "aws_iam_policy" "redshift_s3_access_policy_aag" {
  name        = local.redshift_s3_policy_name
  description = "Allow Redshift Serverless to access all S3 buckets and read Glue Data Catalog metadata"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:*"]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = ["glue:Get*"]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${local.account_id}:secret:redshift!*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:ListSecrets"]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_policy" "redshift_catalog_query_aag" {
  count       = var.catalog_kms_key_arn == null ? 0 : 1
  name        = "redshift_catalog_query_kms_access-${var.name_suffix}"
  description = "Allow Redshift Serverless to decrypt KMS-encrypted data lake objects when querying catalog tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [var.catalog_kms_key_arn]
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "redshift_s3_access_role_aag" {
  role       = aws_iam_role.redshift_s3_access_role_aag.name
  policy_arn = aws_iam_policy.redshift_s3_access_policy_aag.arn
}

resource "aws_iam_role_policy_attachment" "redshift_catalog_query_aag" {
  count      = var.catalog_kms_key_arn == null ? 0 : 1
  role       = aws_iam_role.redshift_s3_access_role_aag.name
  policy_arn = aws_iam_policy.redshift_catalog_query_aag[0].arn
}

resource "aws_security_group" "redshift_workgroup_sg_aag" {
  name        = local.redshift_sg_name
  description = "Redshift Serverless access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Redshift access"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.redshift_sg_name
  }
}

resource "aws_redshiftserverless_namespace" "redshift_sales_analytics_namespace_aag" {
  namespace_name        = local.redshift_namespace_name
  db_name               = "sales_analytics"
  admin_username        = "admin"
  manage_admin_password = true

  iam_roles = [aws_iam_role.redshift_s3_access_role_aag.arn]

  tags = {
    Name = local.redshift_namespace_name
  }
}

resource "aws_redshiftserverless_workgroup" "redshift_sales_analytics_workgroup_aag" {
  workgroup_name = local.redshift_workgroup_name
  namespace_name = aws_redshiftserverless_namespace.redshift_sales_analytics_namespace_aag.namespace_name

  base_capacity = 8

  subnet_ids         = data.aws_subnets.default.ids
  security_group_ids = [aws_security_group.redshift_workgroup_sg_aag.id]

  tags = {
    Name = local.redshift_workgroup_name
  }
}
