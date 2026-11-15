variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "emr-salary-analysis-aag"
}

variable "bucket_suffix" {
  description = "Deprecated. Bucket names are fixed to data-mentoring-<account-id>-<purpose>-aag"
  type        = string
  default     = "aag"
}

variable "emr_release_label" {
  description = "EMR release label"
  type        = string
  default     = "emr-7.12.0"
}

variable "emr_master_instance_type" {
  description = "EC2 instance type for EMR master node"
  type        = string
  default     = "m5.xlarge"
}

variable "emr_core_instance_type" {
  description = "EC2 instance type for EMR core node"
  type        = string
  default     = "m5.xlarge"
}

variable "emr_core_instance_count" {
  description = "Number of EMR core nodes"
  type        = number
  default     = 1
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for EMR instances (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    Purpose     = "EMR Salary Analysis"
  }
}
