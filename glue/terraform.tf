# Terraform backend configuration
# Uncomment and modify the following block if you want to use remote state storage

# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "glue-etl/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }

# For this demo, we'll use local state storage
# In production, consider using remote state storage with S3 backend
