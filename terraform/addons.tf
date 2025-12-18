# VPC CNI Add-on
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "vpc-cni"
  addon_version            = var.vpc_cni_addon_version
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.vpc_cni.arn

  tags = var.default_tags

  depends_on = [
    aws_eks_node_group.main
  ]
}

# CoreDNS Add-on
resource "aws_eks_addon" "coredns" {
  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "coredns"
  addon_version     = var.coredns_addon_version
  resolve_conflicts = "OVERWRITE"

  tags = var.default_tags

  depends_on = [
    aws_eks_node_group.main
  ]
}

# kube-proxy Add-on
resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "kube-proxy"
  addon_version     = var.kube_proxy_addon_version
  resolve_conflicts = "OVERWRITE"

  tags = var.default_tags

  depends_on = [
    aws_eks_node_group.main
  ]
}

# EBS CSI Driver Add-on
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.ebs_csi_addon_version
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  tags = var.default_tags

  depends_on = [
    aws_eks_node_group.main
  ]
}

# AWS Load Balancer Controller (Deployed via Helm - requires manual installation)
# Note: The AWS Load Balancer Controller cannot be installed as an EKS add-on
# and must be installed via Helm chart after cluster creation.
#
# Installation commands:
# 1. Add the EKS Helm repo:
#    helm repo add eks https://aws.github.io/eks-charts
#    helm repo update
#
# 2. Install the AWS Load Balancer Controller:
#    helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
#      -n kube-system \
#      --set clusterName=${var.cluster_name} \
#      --set serviceAccount.create=true \
#      --set serviceAccount.name=aws-load-balancer-controller \
#      --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${aws_iam_role.aws_load_balancer_controller.arn}
#
# Alternatively, you can use the following Terraform resource with the Helm provider:

# Uncomment the following block if you want to install AWS Load Balancer Controller via Terraform
# You'll need to add the Helm provider to your versions.tf file

# resource "helm_release" "aws_load_balancer_controller" {
#   name       = "aws-load-balancer-controller"
#   repository = "https://aws.github.io/eks-charts"
#   chart      = "aws-load-balancer-controller"
#   namespace  = "kube-system"
#   version    = var.aws_load_balancer_controller_version
#
#   set {
#     name  = "clusterName"
#     value = var.cluster_name
#   }
#
#   set {
#     name  = "serviceAccount.create"
#     value = "true"
#   }
#
#   set {
#     name  = "serviceAccount.name"
#     value = "aws-load-balancer-controller"
#   }
#
#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = aws_iam_role.aws_load_balancer_controller.arn
#   }
#
#   depends_on = [
#     aws_eks_node_group.main,
#     aws_eks_addon.vpc_cni
#   ]
# }