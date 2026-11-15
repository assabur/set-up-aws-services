# Create the S3 bucket
resource "aws_s3_bucket" "data_mentoring_bucket" {
  bucket        = "data-mentoring-dev-landing-bucket" # must be globally unique

  force_destroy = true                        # allows bucket deletion even with objects/versions

  # Add a tag
  tags = {
    team = "data"
  }
}

# Enable default server-side encryption with AWS-managed KMS key
resource "aws_s3_bucket_server_side_encryption_configuration" "my_bucket_encryption" {
  bucket = aws_s3_bucket.data_mentoring_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = "alias/aws/s3"
      sse_algorithm     = "aws:kms"
    }
  }
}

# Block all forms of public access
resource "aws_s3_bucket_public_access_block" "my_bucket_block" {
  bucket = aws_s3_bucket.data_mentoring_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
