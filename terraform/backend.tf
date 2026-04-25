# ---------------------------------------------------------------
# Remote Backend — LocalStack S3 + DynamoDB for state locking
#
# TEACHING POINT: This is what prevents two people from running
# terraform apply at the same time and corrupting the state.
#
# For real AWS --> change the endpoint to the real AWS S3/DynamoDB.
# ---------------------------------------------------------------

terraform {
  backend "s3" {
    bucket         = "lab-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"

    # LocalStack-specific overrides — remove these for real AWS
    access_key                  = "test"
    secret_key                  = "test"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    force_path_style            = true
    endpoint                    = "http://localhost:4566"

    # DynamoDB for state locking
    dynamodb_table              = "terraform-lock"
    dynamodb_endpoint           = "http://localhost:4566"

    encrypt = true
  }
}
