output "redshift_workgroup_name" {
  value = aws_redshiftserverless_workgroup.redshift_sales_analytics_workgroup_aag.workgroup_name
}

output "redshift_namespace_name" {
  value = aws_redshiftserverless_namespace.redshift_sales_analytics_namespace_aag.namespace_name
}

output "s3_staging_bucket" {
  value = aws_s3_bucket.redshift_staging_bucket_aag.bucket
}

output "redshift_admin_secret_arn" {
  value = aws_redshiftserverless_namespace.redshift_sales_analytics_namespace_aag.admin_password_secret_arn
}
