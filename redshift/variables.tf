variable "aws_region" {
  description = "AWS region to deploy the lab"
  type        = string
  default     = "us-east-1"
}

variable "allowed_cidr" {
  description = "CIDR allowed to access Redshift Serverless"
  type        = string
  default     = "0.0.0.0/0"
}

variable "name_suffix" {
  description = "Suffix appended to resource names so students can personalize this lab"
  type        = string
  default     = "aag"
}

variable "catalog_kms_key_arn" {
  description = "Optional KMS key ARN for Glue Data Catalog table data stored in S3 when catalog-backed tables use SSE-KMS"
  type        = string
  default     = null
}
