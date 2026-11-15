# S3 bucket for EMR logs
resource "aws_s3_bucket" "emr_logs" {
  bucket              = "${var.project_name}-emr-logs-${data.aws_caller_identity.current.account_id}-${var.aws_region}${local.name_suffix}${var.personal_suffix}"
  force_destroy = true 

  tags = {
    Name        = "${var.project_name}-emr-logs${local.name_suffix}${var.personal_suffix}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "emr_logs" {
  bucket = aws_s3_bucket.emr_logs.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "emr_logs" {
  bucket                  = aws_s3_bucket.emr_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "emr_logs" {
  bucket = aws_s3_bucket.emr_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "emr_spark_script" {
  bucket = aws_s3_bucket.emr_logs.id
  key    = local.spark_script_key
  source = "${path.module}/scripts/salary_aggregations.py"
  etag   = filemd5("${path.module}/scripts/salary_aggregations.py")
}

# EMR Service Role - allows EMR to call AWS services on your behalf
resource "aws_iam_role" "emr_service" {
  name = "${var.project_name}-emr-service-role${local.name_suffix}"

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

  tags = {
    Name        = "${var.project_name}-emr-service-role${local.name_suffix}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "emr_service" {
  role       = aws_iam_role.emr_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEMRServicePolicy_v2"
}

# Supplementary EC2 permissions for EMR service role - v2 policy requires tagged resources;
# this allows provisioning when default VPC/subnets may not have tags
resource "aws_iam_role_policy" "emr_service_ec2" {
  name = "${var.project_name}-emr-service-ec2${local.name_suffix}"
  role = aws_iam_role.emr_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateLaunchTemplateVersion",
          "ec2:CreateNetworkInterface",
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteNetworkInterface",
          "ec2:ModifyInstanceAttribute",
          "ec2:TerminateInstances",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:CreatePlacementGroup",
          "ec2:DeletePlacementGroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = aws_iam_role.emr_ec2.arn
        Condition = {
          StringLike = {
            "iam:PassedToService" = "ec2.amazonaws.com*"
          }
        }
      }
    ]
  })
}

# EMR EC2 Instance Profile - used by cluster EC2 instances
resource "aws_iam_role" "emr_ec2" {
  name = "${var.project_name}-emr-ec2-role${local.name_suffix}"

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

  tags = {
    Name        = "${var.project_name}-emr-ec2-role${local.name_suffix}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "emr_ec2" {
  role       = aws_iam_role.emr_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

resource "aws_iam_instance_profile" "emr_ec2" {
  name = "${var.project_name}-emr-instance-profile${local.name_suffix}"
  role = aws_iam_role.emr_ec2.name
}

# Allow EMR EC2 instances to access the logs bucket
resource "aws_iam_role_policy" "emr_ec2_s3" {
  name = "${var.project_name}-emr-ec2-s3${local.name_suffix}"
  role = aws_iam_role.emr_ec2.id

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
          aws_s3_bucket.emr_logs.arn,
          "${aws_s3_bucket.emr_logs.arn}/*"
        ]
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

# Default VPC and subnets - must be tagged for EMR v2 policy
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Tag default VPC and subnets for EMR ServicePolicy_v2 (required for EC2 permissions)
resource "aws_ec2_tag" "default_vpc_emr" {
  resource_id = data.aws_vpc.default.id
  key         = "for-use-with-amazon-emr-managed-policies"
  value       = "true"
}

resource "aws_ec2_tag" "default_subnets_emr" {
  for_each    = toset(data.aws_subnets.default.ids)
  resource_id = each.value
  key         = "for-use-with-amazon-emr-managed-policies"
  value       = "true"
}

locals {
  name_suffix = "-terraform"
}

# Step Functions Execution Role
resource "aws_iam_role" "stepfunctions" {
  name = "${var.project_name}-stepfunctions-role${local.name_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.${var.aws_region}.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-stepfunctions-role${local.name_suffix}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Step Functions needs to call EMR and pass roles to it
resource "aws_iam_role_policy" "stepfunctions_emr" {
  name = "${var.project_name}-stepfunctions-emr${local.name_suffix}"
  role = aws_iam_role.stepfunctions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "elasticmapreduce:CreateCluster"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "elasticmapreduce:RunJobFlow"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "elasticmapreduce:AddJobFlowSteps"
        Resource = "arn:aws:elasticmapreduce:*:*:cluster/*"
      },
      {
        Effect   = "Allow"
        Action   = "elasticmapreduce:TerminateJobFlows"
        Resource = "arn:aws:elasticmapreduce:*:*:cluster/*"
      },
      {
        Effect   = "Allow"
        Action   = "elasticmapreduce:DescribeCluster"
        Resource = "arn:aws:elasticmapreduce:*:*:cluster/*"
      },
      {
        Effect   = "Allow"
        Action   = "elasticmapreduce:DescribeStep"
        Resource = "arn:aws:elasticmapreduce:*:*:cluster/*"
      },
      {
        Effect   = "Allow"
        Action   = "elasticmapreduce:ListSteps"
        Resource = "arn:aws:elasticmapreduce:*:*:cluster/*"
      },
      {
        Effect   = "Allow"
        Action   = "elasticmapreduce:AddTags"
        Resource = "arn:aws:elasticmapreduce:*:*:cluster/*"
      },
      {
        Effect   = "Allow"
        Action   = "elasticmapreduce:RemoveTags"
        Resource = "arn:aws:elasticmapreduce:*:*:cluster/*"
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          aws_iam_role.emr_service.arn,
          aws_iam_role.emr_ec2.arn
        ]
      }
    ]
  })
}

# Step Functions State Machine
resource "aws_sfn_state_machine" "emr_job_manager" {
  name     = "${var.project_name}-state-machine${local.name_suffix}"
  role_arn = aws_iam_role.stepfunctions.arn

  definition = templatefile("${path.module}/state-machine-definition.json.tpl", {
    cluster_name              = var.cluster_name
    emr_release_label         = var.emr_release_label
    emr_service_role_name     = aws_iam_role.emr_service.name
    emr_instance_profile_name = aws_iam_instance_profile.emr_ec2.name
    emr_log_uri               = "s3://${aws_s3_bucket.emr_logs.bucket}/logs/"
    master_instance_type      = var.master_instance_type
    core_instance_type        = var.core_instance_type
  })

  tags = {
    Name        = "${var.project_name}-state-machine${local.name_suffix}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# EventBridge rule to trigger state machine daily at 5 AM
resource "aws_cloudwatch_event_rule" "daily_trigger" {
  count               = var.enable_schedule ? 1 : 0
  name                = "${var.project_name}-daily-trigger${local.name_suffix}"
  description         = "Trigger EMR job manager state machine daily"
  schedule_expression = var.schedule_cron

  tags = {
    Name        = "${var.project_name}-daily-trigger${local.name_suffix}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_event_target" "stepfunctions" {
  count     = var.enable_schedule ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_trigger[0].name
  target_id = "StartStepFunction${local.name_suffix}"
  arn       = aws_sfn_state_machine.emr_job_manager.arn
  role_arn  = aws_iam_role.eventbridge[0].arn
}

# IAM role for EventBridge to start Step Functions executions
resource "aws_iam_role" "eventbridge" {
  count = var.enable_schedule ? 1 : 0

  name = "${var.project_name}-eventbridge-role${local.name_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-eventbridge-role${local.name_suffix}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "eventbridge_stepfunctions" {
  count = var.enable_schedule ? 1 : 0

  name = "${var.project_name}-eventbridge-stepfunctions${local.name_suffix}"
  role = aws_iam_role.eventbridge[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "states:StartExecution"
        Resource = aws_sfn_state_machine.emr_job_manager.arn
      }
    ]
  })
}
