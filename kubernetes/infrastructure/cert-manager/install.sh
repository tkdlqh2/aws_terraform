#!/bin/bash
# Install Cert-Manager using Helm

set -e

echo "Adding Jetstack Helm repository..."
helm repo add jetstack https://charts.jetstack.io
helm repo update

echo "Installing Cert-Manager..."
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --values values.yaml \
  --wait

echo "Waiting for Cert-Manager to be ready..."
kubectl wait --for=condition=Available --timeout=300s \
  deployment/cert-manager -n cert-manager
kubectl wait --for=condition=Available --timeout=300s \
  deployment/cert-manager-webhook -n cert-manager
kubectl wait --for=condition=Available --timeout=300s \
  deployment/cert-manager-cainjector -n cert-manager

echo "Creating ClusterIssuers..."
kubectl apply -f cluster-issuer.yaml

echo "Cert-Manager installed successfully!"
echo ""
echo "Check status with:"
echo "  kubectl get pods -n cert-manager"
echo "  kubectl get clusterissuer"