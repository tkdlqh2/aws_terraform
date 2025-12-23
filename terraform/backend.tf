# Terraform S3 Backend Configuration
# Backend block cannot use variable interpolation
# Use partial configuration with backend.hcl file
terraform {
  backend "s3" {
    # These values will be provided via backend.hcl or -backend-config flags
    # bucket = "your-terraform-state-bucket"
    # key    = "terraform/eks/terraform.tfstate"
    # region = "ap-northeast-2"
    encrypt = true
  }
}