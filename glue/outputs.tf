output "glue_job_name" {
  description = "Name of the created Glue job"
  value       = aws_glue_job.etl_job.name
}

output "glue_job_arn" {
  description = "ARN of the created Glue job"
  value       = aws_glue_job.etl_job.arn
}

output "glue_job_role_arn" {
  description = "ARN of the IAM role used by the Glue job"
  value       = aws_iam_role.glue_job_role.arn
}

output "glue_catalog_database_name" {
  description = "Name of the created Glue catalog database"
  value       = aws_glue_catalog_database.hr_database.name
}

output "glue_scripts_bucket_name" {
  description = "Name of the S3 bucket containing Glue scripts"
  value       = aws_s3_bucket.glue_scripts_bucket.bucket
}

output "glue_scripts_bucket_arn" {
  description = "ARN of the S3 bucket containing Glue scripts"
  value       = aws_s3_bucket.glue_scripts_bucket.arn
}

output "glue_script_s3_key" {
  description = "S3 key of the uploaded Glue ETL script"
  value       = aws_s3_object.glue_script.key
}

output "glue_script_s3_url" {
  description = "S3 URL of the uploaded Glue ETL script"
  value       = "s3://${aws_s3_bucket.glue_scripts_bucket.bucket}/${aws_s3_object.glue_script.key}"
}

output "aws_region" {
  description = "AWS region where resources were created"
  value       = var.aws_region
}

output "project_name" {
  description = "Project name used for resource naming"
  value       = var.project_name
}

output "source_data_path" {
  description = "S3 path to the source data file"
  value       = var.source_data_path
}

output "output_data_path" {
  description = "S3 path for the output data"
  value       = var.output_data_path
}
