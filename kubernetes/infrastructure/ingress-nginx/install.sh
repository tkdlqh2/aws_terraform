#!/bin/bash
# Install Ingress NGINX using Helm

set -e

echo "Adding Ingress NGINX Helm repository..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

echo "Installing Ingress NGINX..."
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --values values.yaml \
  --wait

echo "Ingress NGINX installed successfully!"
echo ""
echo "Check status with:"
echo "  kubectl get pods -n ingress-nginx"
echo "  kubectl get svc -n ingress-nginx"