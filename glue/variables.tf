variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "glue-etl-demo"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket containing the source data"
  type        = string
  default     = "data-mentoring-dev-bucket"
}

variable "source_data_path" {
  description = "S3 path to the source data file"
  type        = string
  default     = "s3://data-mentoring-dev-bucket/salary-data.csv"
}

variable "output_data_path" {
  description = "S3 path for the output data"
  type        = string
  default     = "s3://data-mentoring-dev-bucket/gold/"
}

variable "catalog_database_name" {
  description = "Name of the Glue catalog database"
  type        = string
  default     = "human_resources"
}

variable "glue_version" {
  description = "Glue version to use for the job"
  type        = string
  default     = "5.0"
}

variable "worker_type" {
  description = "Type of worker for the Glue job"
  type        = string
  default     = "G.1X"
  
  validation {
    condition     = contains(["Standard", "G.1X", "G.2X"], var.worker_type)
    error_message = "Worker type must be one of: Standard, G.1X, G.2X."
  }
}

variable "number_of_workers" {
  description = "Number of workers for the Glue job"
  type        = number
  default     = 2
  
  validation {
    condition     = var.number_of_workers >= 2 && var.number_of_workers <= 10
    error_message = "Number of workers must be between 2 and 10."
  }
}

variable "job_timeout" {
  description = "Job timeout in minutes"
  type        = number
  default     = 60
  
  validation {
    condition     = var.job_timeout >= 1 && var.job_timeout <= 2880
    error_message = "Job timeout must be between 1 and 2880 minutes."
  }
}
