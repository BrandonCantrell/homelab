# Helm Chart Values for Homelab

This directory contains custom values files for external Helm charts used in the homelab Kubernetes cluster.

## Structure

- **cert-manager-values.yaml**: Custom values for the cert-manager Helm chart
- **loki-values.yaml**: Custom values for the Loki Helm chart
- **grafana-values.yaml**: Custom values for the Grafana Helm chart
- **prometheus-values.yaml**: Custom values for the Prometheus Helm chart
- **longhorn-values.yaml**: Custom values for the Longhorn Helm chart
- **metallb-values.yaml**: Custom values for the MetalLB Helm chart
- **homepage-values.yaml**: Custom values for the Homepage Helm chart
- **homeassistant-values.yaml**: Custom values for the Home Assistant Helm chart

## Usage

These values files are referenced by the ApplicationSet defined in `k3s-cluster/kube-apps/applicationsets/external-helm-appset.yaml`.

To modify the configuration of an application:

1. Edit the corresponding values file in this directory
2. Commit and push the changes to the repository
3. ArgoCD will automatically detect the changes and update the application

## Adding New Values Files

To add a new values file for an external Helm chart:

1. Create a new values file in this directory with the naming convention `<app-name>-values.yaml`
2. Add the application to the ApplicationSet in `k3s-cluster/kube-apps/applicationsets/external-helm-appset.yaml`
3. Commit and push the changes to the repository

## Observability Stack Configuration

The values files in this directory are configured to work together to provide a complete observability stack:

- **cert-manager**: Configured to automatically provision TLS certificates
- **Prometheus**: Configured to scrape metrics from all components in the cluster
- **Loki**: Configured to collect logs from all pods in the cluster
- **Grafana**: Pre-configured with dashboards for monitoring the Kubernetes cluster and with data sources for Prometheus and Loki

The observability stack is configured to use Longhorn for persistent storage, ensuring that metrics and logs are preserved across pod restarts.