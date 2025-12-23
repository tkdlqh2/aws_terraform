#!/bin/bash
# Install AWS Load Balancer Controller using Helm

set -e

# Get cluster name from context or environment
CLUSTER_NAME=${CLUSTER_NAME:-$(kubectl config current-context | cut -d'/' -f2)}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=${AWS_REGION:-ap-northeast-2}

echo "Cluster Name: $CLUSTER_NAME"
echo "AWS Account ID: $ACCOUNT_ID"
echo "AWS Region: $REGION"

# Get IAM role ARN from Terraform output
if [ -d "../../terraform" ]; then
  cd ../../terraform
  IAM_ROLE_ARN=$(terraform output -raw aws_load_balancer_controller_iam_role_arn 2>/dev/null || echo "")
  cd -
fi

if [ -z "$IAM_ROLE_ARN" ]; then
  IAM_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${CLUSTER_NAME}-aws-load-balancer-controller"
  echo "Warning: Could not get IAM role from Terraform output, using default: $IAM_ROLE_ARN"
fi

echo "IAM Role ARN: $IAM_ROLE_ARN"

echo "Adding EKS Helm repository..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

echo "Installing AWS Load Balancer Controller..."
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$IAM_ROLE_ARN \
  --set region=$REGION \
  --set replicaCount=2 \
  --wait

echo "AWS Load Balancer Controller installed successfully!"
echo ""
echo "Check status with:"
echo "  kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller"
echo "  kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller"