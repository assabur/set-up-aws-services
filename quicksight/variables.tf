variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "name_suffix" {
  description = "Suffix appended to resource names so students can personalize this lab"
  type        = string
  default     = "aag"
}

variable "project_name" {
  description = "Project name to use for naming resources"
  type        = string
  default     = "data-lake"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "s3_bucket_name" {
  description = "Name of S3 bucket for data lake (must be globally unique)"
  type        = string
  default     = ""
  validation {
    condition     = var.s3_bucket_name != "" ? can(regex("^[a-z0-9-]{3,63}$", var.s3_bucket_name)) : true
    error_message = "S3 bucket name must be between 3-63 characters and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "csv_file_path" {
  description = "Local path to the CSV file to upload"
  type        = string
  default     = "./data/sales.csv"
}

variable "glue_database_name" {
  description = "Name of the Glue database"
  type        = string
  default     = "quicksight_sales_db"
}

variable "glue_table_name" {
  description = "Name of the Glue table"
  type        = string
  default     = "sales"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Serverless Data Lake"
    ManagedBy   = "Terraform"
    Environment = "Development"
  }
}
