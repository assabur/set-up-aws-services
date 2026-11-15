output "s3_bucket_name" {
  description = "Name of the S3 data lake bucket"
  value       = aws_s3_bucket.data_lake.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 data lake bucket"
  value       = aws_s3_bucket.data_lake.arn
}

output "s3_data_location" {
  description = "S3 location where the raw sales data is stored"
  value       = "s3://${aws_s3_bucket.data_lake.id}/raw/sales/"
}

output "glue_database_name" {
  description = "Name of the Glue database"
  value       = aws_glue_catalog_database.sales_db.name
}

output "glue_table_name" {
  description = "Name of the Glue table"
  value       = aws_glue_catalog_table.sales_table.name
}

output "glue_table_arn" {
  description = "ARN of the Glue table"
  value       = "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${aws_glue_catalog_database.sales_db.name}/${aws_glue_catalog_table.sales_table.name}"
}

output "glue_service_role_arn" {
  description = "ARN of the IAM role used by Glue"
  value       = aws_iam_role.glue_service_role.arn
}

output "quicksight_service_role_arn" {
  description = "ARN of the IAM role used by QuickSight"
  value       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/aws-quicksight-service-role-v0"
}

output "aws_account_id" {
  description = "AWS Account ID where resources are deployed"
  value       = data.aws_caller_identity.current.account_id
}

output "next_steps" {
  description = "Suggested next steps after Terraform deployment"
  value       = <<-EOT
    ✅ Terraform deployment complete!

    📊 Next Steps:

    1. Query data with Amazon Athena:
       - Go to AWS Athena Console
       - Select database: ${aws_glue_catalog_database.sales_db.name}
       - Run SQL: SELECT * FROM ${aws_glue_catalog_table.sales_table.name} LIMIT 10;

    2. Set up Athena query results location:
       - S3 path: s3://${aws_s3_bucket.data_lake.id}/athena-results/

    3. Create a Glue Crawler (optional):
       - To automatically detect schema changes
       - Point to: s3://${aws_s3_bucket.data_lake.id}/raw/sales/

    4. Connect QuickSight to Athena:
       - Create a new dataset from Athena
       - Build your first dashboard!

    5. Convert to Parquet format:
       - Use Glue Jobs for better performance
       - Path: s3://${aws_s3_bucket.data_lake.id}/processed/sales/

    🎯 Data Lake Location:
       S3: s3://${aws_s3_bucket.data_lake.id}/raw/sales/
       Glue DB: ${aws_glue_catalog_database.sales_db.name}
       Glue Table: ${aws_glue_catalog_table.sales_table.name}
  EOT
}
