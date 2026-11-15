# Create the S3 bucket
resource "aws_s3_bucket" "dev_bucket" {
  bucket        = "data-mentoring-dev-athena-bucket" # must be globally unique

  force_destroy = true                        # allows bucket deletion even with objects/versions

  # Add a tag
  tags = {
    team = "data"
  }
}


# Enable default server-side encryption with AWS-managed KMS key
resource "aws_s3_bucket_server_side_encryption_configuration" "my_bucket_encryption" {
  bucket = aws_s3_bucket.dev_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = "alias/aws/s3"
      sse_algorithm     = "aws:kms"
    }
  }
}

# Block all forms of public access
resource "aws_s3_bucket_public_access_block" "my_bucket_block" {
  bucket = aws_s3_bucket.dev_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}



# Create athena-query-results folder
resource "aws_s3_object" "athena_query_results_folder" {
  bucket = aws_s3_bucket.dev_bucket.id
  key    = "athena-query-results/"
  content = ""
}

# Create data folder for salary data
resource "aws_s3_object" "data_folder" {
  bucket = aws_s3_bucket.dev_bucket.id
  key    = "data/"
  content = ""
}