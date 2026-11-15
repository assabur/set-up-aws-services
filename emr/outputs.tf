output "emr_cluster_id" {
  description = "EMR Cluster ID"
  value       = aws_emr_cluster.salary_analysis_cluster.id
}

output "emr_cluster_name" {
  description = "EMR Cluster Name"
  value       = aws_emr_cluster.salary_analysis_cluster.name
}

output "emr_cluster_master_public_dns" {
  description = "EMR Master Node Public DNS"
  value       = aws_emr_cluster.salary_analysis_cluster.master_public_dns
}

output "raw_bucket_name" {
  description = "S3 Raw Bucket Name for CSV input data"
  value       = aws_s3_bucket.raw_bucket.id
}

output "raw_bucket_arn" {
  description = "S3 Raw Bucket ARN"
  value       = aws_s3_bucket.raw_bucket.arn
}

output "analytics_bucket_name" {
  description = "S3 Analytics Bucket Name for Parquet output"
  value       = aws_s3_bucket.analytics_bucket.id
}

output "analytics_bucket_arn" {
  description = "S3 Analytics Bucket ARN"
  value       = aws_s3_bucket.analytics_bucket.arn
}

output "raw_data_path" {
  description = "S3 path for raw CSV data"
  value       = "s3://${aws_s3_bucket.raw_bucket.id}/hr-salary-data.csv"
}

output "analytics_output_path" {
  description = "S3 path for analytics output"
  value       = "s3://${aws_s3_bucket.analytics_bucket.id}/output/"
}

output "emr_logs_path" {
  description = "S3 path for EMR logs"
  value       = "s3://${aws_s3_bucket.raw_bucket.id}/logs/"
}

output "bucket_naming_convention" {
  description = "Bucket naming convention used"
  value       = "data-mentoring-${data.aws_caller_identity.current.account_id}-{purpose}-aag"
}

output "scripts_bucket_name" {
  description = "S3 Scripts Bucket Name for bootstrap and job scripts"
  value       = aws_s3_bucket.scripts_bucket.id
}

output "scripts_bucket_arn" {
  description = "S3 Scripts Bucket ARN"
  value       = aws_s3_bucket.scripts_bucket.arn
}
