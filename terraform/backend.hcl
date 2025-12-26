# Terraform Backend Configuration
# Copy this file to backend.hcl and update the values
# Usage: terraform init -backend-config=backend.hcl

bucket = "invoice-demo-project-state"
key    = "terraform/eks/terraform.tfstate"
region = "ap-northeast-2"