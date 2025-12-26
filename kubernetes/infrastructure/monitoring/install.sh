#!/bin/bash
# Install Prometheus Stack using Helm

set -e

echo "Adding Prometheus Community Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "Installing Kube-Prometheus-Stack..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values values.yaml \
  --wait \
  --timeout 10m

echo "Prometheus Stack installed successfully!"
echo ""
echo "Access Grafana:"
echo "  Default username: admin"
echo "  Default password: admin (change this in values.yaml)"
echo ""
echo "Check status with:"
echo "  kubectl get pods -n monitoring"
echo "  kubectl get svc -n monitoring"
echo ""
echo "Port-forward Grafana (if ingress not configured):"
echo "  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"