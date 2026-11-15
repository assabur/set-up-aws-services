variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "emr-job-manager"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "emr_release_label" {
  description = "EMR release label"
  type        = string
  default     = "emr-6.15.0"
}

variable "cluster_name" {
  description = "Name for the EMR cluster"
  type        = string
  default     = "stepfunction-cluster-terraform"
}

variable "master_instance_type" {
  description = "EC2 instance type for the EMR master node"
  type        = string
  default     = "m5.large"
}

variable "core_instance_type" {
  description = "EC2 instance type for the EMR core nodes"
  type        = string
  default     = "m5.large"
}

variable "salary_input_s3_uri" {
  description = "S3 URI for the salary CSV file (uploaded from athena/salary-data.csv)"
  type        = string
  default     = "s3://data-mentoring-dev-athena-bucket/data/salary-data.csv"
}

variable "salary_input_bucket" {
  description = "S3 bucket name that stores the input salary CSV file"
  type        = string
  default     = "data-mentoring-dev-athena-bucket"
}

variable "salary_output_s3_uri" {
  description = "S3 URI where Spark writes aggregated results"
  type        = string
  default     = ""
}

variable "salary_output_bucket" {
  description = "S3 bucket name where Spark writes aggregated results (optional override if not using EMR logs bucket)"
  type        = string
  default     = ""
}

variable "schedule_cron" {
  description = "EventBridge cron expression for daily execution (default: 5 AM UTC)"
  type        = string
  default     = "cron(0 5 * * ? *)"
}

variable "enable_schedule" {
  description = "Enable EventBridge rule to trigger state machine on schedule"
  type        = bool
  default     = true
}

variable "personal_suffix" {
  description = "Personal suffix to add to resource names (e.g., -aag)"
  type        = string
  default     = "-aag"
}

variable "force_destroy_s3" {
  description = "Force destroy S3 bucket even if it contains objects"
  type        = bool
  default     = false
}
