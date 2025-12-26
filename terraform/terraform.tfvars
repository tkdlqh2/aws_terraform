# AWS Configuration
aws_region = "ap-northeast-2"

# Default Tags
default_tags = {
  Terraform   = "true"
  Environment = "dev"
  Project     = "my-eks-cluster"
}

# VPC Configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]

# EKS Cluster Configuration
cluster_name                         = "my-eks-cluster"
kubernetes_version                   = "1.31"
cluster_endpoint_private_access      = true
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # Restrict this to your IP for production
cluster_enabled_log_types            = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

# Optional: KMS Key ARN for cluster encryption
# kms_key_arn = "arn:aws:kms:ap-northeast-2:123456789012:key/12345678-1234-1234-1234-123456789012"

# Node Group Configuration
node_group_desired_size  = 2
node_group_min_size      = 1
node_group_max_size      = 4
node_group_instance_types = ["t3.medium"]
node_group_capacity_type = "ON_DEMAND" # or "SPOT"
node_group_disk_size     = 20

# Optional: Node Group Labels
# node_group_labels = {
#   "environment" = "dev"
#   "workload"    = "general"
# }

# Optional: Node Group Taints
# node_group_taints = [
#   {
#     key    = "dedicated"
#     value  = "gpu"
#     effect = "NoSchedule"
#   }
# ]

# Optional: Bootstrap Extra Arguments
# bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"

# EKS Add-ons Configuration
# Leave as null to use the latest compatible version
vpc_cni_addon_version    = null
coredns_addon_version    = null
kube_proxy_addon_version = null
ebs_csi_addon_version    = null

# AWS Load Balancer Controller Helm Chart Version
aws_load_balancer_controller_version = "1.7.0"