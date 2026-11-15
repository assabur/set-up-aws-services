output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.emr_job_manager.arn
}

output "state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = aws_sfn_state_machine.emr_job_manager.name
}

output "state_machine_id" {
  description = "ID of the Step Functions state machine"
  value       = aws_sfn_state_machine.emr_job_manager.id
}

output "emr_logs_bucket" {
  description = "S3 bucket for EMR cluster logs"
  value       = aws_s3_bucket.emr_logs.bucket
}

output "emr_logs_uri" {
  description = "S3 URI for EMR cluster logs"
  value       = "s3://${aws_s3_bucket.emr_logs.bucket}/logs/"
}

output "schedule_enabled" {
  description = "Whether the daily EventBridge schedule is enabled"
  value       = var.enable_schedule
}

output "schedule_cron" {
  description = "Cron expression for the daily trigger"
  value       = var.enable_schedule ? var.schedule_cron : "Disabled"
}
