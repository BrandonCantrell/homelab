# ApplicationSets for Homelab

This directory contains ApplicationSets for managing applications in the homelab Kubernetes cluster using ArgoCD.

## Structure

- **charts-appset.yaml**: ApplicationSet for applications that use custom Helm charts stored in this repository.
  - homeassistant
  - homepage
  - stash

- **manifests-appset.yaml**: ApplicationSet for applications that use raw Kubernetes manifests stored in this repository.
  - argocd
  - longhorn
  - metallb

- **external-helm-appset.yaml**: ApplicationSet for applications that use external Helm charts with custom values.
  - cert-manager (from https://charts.jetstack.io)
  - loki (from https://grafana.github.io/helm-charts)
  - grafana (from https://grafana.github.io/helm-charts)
  - prometheus (from https://prometheus-community.github.io/helm-charts)

## Usage

These ApplicationSets are managed by ArgoCD itself through the `applicationsets` Application defined in `k3s-cluster/kube-apps/applications/applicationsets.yaml`.

To add a new application:

1. For applications using custom charts in this repository:
   - Add the application to `charts-appset.yaml`
   - Create the chart in `k3s-cluster/kube-apps/charts/<app-name>/`

2. For applications using raw manifests:
   - Add the application to `manifests-appset.yaml`
   - Create the manifests in `k3s-cluster/kube-apps/manifests/<app-name>/`

3. For applications using external Helm charts:
   - Add the application to `external-helm-appset.yaml`
   - Create a values file in `k3s-cluster/kube-apps/values/<app-name>-values.yaml`

## Observability Stack

The homelab includes a complete observability stack:

- **cert-manager**: For managing TLS certificates
- **Prometheus**: For metrics collection and alerting
- **Loki**: For log aggregation
- **Grafana**: For visualization of metrics and logs

These components are configured to work together out of the box, with Grafana pre-configured with dashboards for monitoring the Kubernetes cluster.