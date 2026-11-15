terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Scripts Bucket - for bootstrap, step shell scripts, and PySpark jobs
resource "aws_s3_bucket" "scripts_bucket" {
  bucket        = "data-mentoring-${data.aws_caller_identity.current.account_id}-scripts-aag"
  force_destroy = true

  tags = merge(var.tags, {
    Name    = "${var.project_name}-scripts-bucket"
    Purpose = "EMR Bootstrap + Step Scripts"
  })
}

# Block all public access to scripts bucket
resource "aws_s3_bucket_public_access_block" "scripts_bucket_block" {
  bucket = aws_s3_bucket.scripts_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "scripts_bucket_versioning" {
  bucket = aws_s3_bucket.scripts_bucket.id
  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "scripts_bucket_encryption" {
  bucket = aws_s3_bucket.scripts_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Raw Data Bucket - for CSV input files
resource "aws_s3_bucket" "raw_bucket" {
  bucket        = "data-mentoring-${data.aws_caller_identity.current.account_id}-raw-aag"
  force_destroy = true

  tags = merge(var.tags, {
    Name    = "${var.project_name}-raw-bucket"
    Purpose = "Raw CSV Data Input"
  })
}

# Block all public access to raw bucket
resource "aws_s3_bucket_public_access_block" "raw_bucket_block" {
  bucket = aws_s3_bucket.raw_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "raw_bucket_versioning" {
  bucket = aws_s3_bucket.raw_bucket.id
  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw_bucket_encryption" {
  bucket = aws_s3_bucket.raw_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Analytics Bucket - for processed Parquet output (Athena-queryable)
resource "aws_s3_bucket" "analytics_bucket" {
  bucket        = "data-mentoring-${data.aws_caller_identity.current.account_id}-analytics-aag"
  force_destroy = true

  tags = merge(var.tags, {
    Name    = "${var.project_name}-analytics-bucket"
    Purpose = "Processed Parquet Data for Athena"
  })
}

# Block all public access to analytics bucket
resource "aws_s3_bucket_public_access_block" "analytics_bucket_block" {
  bucket = aws_s3_bucket.analytics_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "analytics_bucket_versioning" {
  bucket = aws_s3_bucket.analytics_bucket.id
  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analytics_bucket_encryption" {
  bucket = aws_s3_bucket.analytics_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Upload salary data to raw bucket
resource "aws_s3_object" "salary_data" {
  bucket = aws_s3_bucket.raw_bucket.id
  key    = "hr-salary-data.csv"
  source = "${path.root}/data/hr-salary-data.csv"

  tags = var.tags
}

# Upload PySpark job script to scripts bucket (for execution)
resource "aws_s3_object" "pyspark_job" {
  bucket = aws_s3_bucket.scripts_bucket.id
  key    = "scripts/salary_aggregations.py"
  source = "${path.root}/scripts/salary_aggregations.py"

  tags = var.tags
}

# Upload bootstrap script to scripts bucket
resource "aws_s3_object" "bootstrap_script" {
  bucket = aws_s3_bucket.scripts_bucket.id
  key    = "bootstrap/bootstrap.sh"
  source = "${path.root}/bootstrap/bootstrap.sh"

  tags = var.tags
}

# Upload EMR step shell script to scripts bucket
resource "aws_s3_object" "emr_step_script" {
  bucket = aws_s3_bucket.scripts_bucket.id
  key    = "steps/list_and_env.sh"
  source = "${path.root}/scripts/list_and_env.sh"

  tags = var.tags
}

# IAM Role for EMR Service
resource "aws_iam_role" "emr_service_role" {
  name = "${var.project_name}-emr-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticmapreduce.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "emr_service_role_policy" {
  role       = aws_iam_role.emr_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

# IAM Role for EMR EC2 Instances
resource "aws_iam_role" "emr_instance_profile_role" {
  name = "${var.project_name}-emr-instance-profile-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "emr_instance_profile_role_policy" {
  role       = aws_iam_role.emr_instance_profile_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

# S3 access policy for EMR instances
resource "aws_iam_role_policy" "emr_s3_access" {
  name = "${var.project_name}-emr-s3-access"
  role = aws_iam_role.emr_instance_profile_role.id

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
          aws_s3_bucket.raw_bucket.arn,
          "${aws_s3_bucket.raw_bucket.arn}/*",
          aws_s3_bucket.analytics_bucket.arn,
          "${aws_s3_bucket.analytics_bucket.arn}/*",
          aws_s3_bucket.scripts_bucket.arn,
          "${aws_s3_bucket.scripts_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Instance Profile
resource "aws_iam_instance_profile" "emr_instance_profile" {
  name = "${var.project_name}-emr-instance-profile"
  role = aws_iam_role.emr_instance_profile_role.name
}

# Security Group for EMR
resource "aws_security_group" "emr_security_group" {
  name        = "${var.project_name}-emr-sg"
  description = "Security group for EMR cluster"
  vpc_id      = data.aws_vpc.default.id

  # Allow SSH from anywhere (if key pair is provided)
  dynamic "ingress" {
    for_each = var.key_pair_name != "" ? [1] : []
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# EMR Cluster
resource "aws_emr_cluster" "salary_analysis_cluster" {
  name          = "${var.project_name}-cluster"
  release_label = var.emr_release_label
  applications  = ["Spark", "Hadoop"]

  service_role = aws_iam_role.emr_service_role.arn

  termination_protection            = false
  keep_job_flow_alive_when_no_steps = false

  ec2_attributes {
    key_name                          = var.key_pair_name
    subnet_id                         = data.aws_subnets.default.ids[0]
    emr_managed_master_security_group = aws_security_group.emr_security_group.id
    emr_managed_slave_security_group  = aws_security_group.emr_security_group.id
    instance_profile                  = aws_iam_instance_profile.emr_instance_profile.name
  }

  master_instance_group {
    instance_type  = var.emr_master_instance_type
    instance_count = 1
  }

  core_instance_group {
    instance_type  = var.emr_core_instance_type
    instance_count = var.emr_core_instance_count

    bid_price = "" # Use on-demand instances for reliability
  }

  # Bootstrap action
  bootstrap_action {
    path = "s3://${aws_s3_bucket.scripts_bucket.id}/bootstrap/bootstrap.sh"
    args = []
    name = "Configure Spark Environment"
  }

  # Log configuration - store in raw bucket
  log_uri = "s3://${aws_s3_bucket.raw_bucket.id}/logs/"

  # EMR Step 1: Shell script (ls + env) from scripts bucket
  step {
    name              = "List and Env Check"
    action_on_failure = "CONTINUE"

    hadoop_jar_step {
      jar = "s3://elasticmapreduce/libs/script-runner/script-runner.jar"
      args = [
        "s3://${aws_s3_bucket.scripts_bucket.id}/steps/list_and_env.sh"
      ]
    }
  }

  # EMR Step 2: Run PySpark directly via command-runner
  step {
    name              = "Run Salary Aggregations"
    action_on_failure = "CONTINUE"

    hadoop_jar_step {
      jar = "command-runner.jar"
      args = [
        "spark-submit",
        "--deploy-mode",
        "cluster",
        "--master",
        "yarn",
        "s3://${aws_s3_bucket.scripts_bucket.id}/scripts/salary_aggregations.py",
        "s3://${aws_s3_bucket.raw_bucket.id}/hr-salary-data.csv",
        "s3://${aws_s3_bucket.analytics_bucket.id}/output/"
      ]
    }
  }

  tags = var.tags

  # Ensure data is uploaded before cluster creation
  depends_on = [
    aws_s3_object.salary_data,
    aws_s3_object.pyspark_job,
    aws_s3_object.bootstrap_script,
    aws_s3_object.emr_step_script
  ]
}
