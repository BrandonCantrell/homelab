# ApplicationSet Migration Summary

## Changes Made

1. **Created Values Files for External Helm Charts**:
   - `longhorn-values.yaml`: Extracted from inline values in longhorn.yaml and additional ingress configuration from manifests/longhorn/ingress.yaml
   - `metallb-values.yaml`: Extracted from inline values in metallb.yaml and additional custom resources from manifests/metallb/config.yaml
   - `homepage-values.yaml`: Extracted from inline values in homepage/homepage.yaml
   - `homeassistant-values.yaml`: Extracted from inline values in homeassistant/homeassistant.yaml

2. **Updated External Helm ApplicationSet**:
   - Added longhorn (from https://charts.longhorn.io)
   - Added metallb (from https://metallb.github.io/metallb)
   - Added homepage (from https://jameswynn.github.io/helm-charts)
   - Added homeassistant (from http://pajikos.github.io/home-assistant-helm-chart)

3. **Updated README Files**:
   - Updated applicationsets/README.md to reflect the new applications
   - Updated values/README.md to include the new values files

## Next Steps

1. **Remove Individual Application Files**:
   These files are now redundant as they've been migrated to applicationsets:
   - `k3s-cluster/kube-apps/applications/longhorn.yaml`
   - `k3s-cluster/kube-apps/applications/metallb.yaml`
   - `k3s-cluster/kube-apps/applications/homepage/homepage.yaml`
   - `k3s-cluster/kube-apps/applications/homeassistant/homeassistant.yaml`
   - `k3s-cluster/kube-apps/applications/metallb-config.yaml` (now handled by metallb-config in manifests-appset)

2. **Apply Changes to ArgoCD**:
   ArgoCD should automatically detect the changes and deploy the applications using the applicationsets.

## Hybrid Approach for MetalLB

For MetalLB, we've adopted a hybrid approach:

1. The main MetalLB application is deployed using the community Helm chart via `external-helm-appset.yaml`
2. The MetalLB configuration (IPAddressPool and L2Advertisement) is deployed using the manifests via `manifests-appset.yaml`

This approach ensures that the MetalLB configuration is applied correctly while still taking advantage of the community Helm chart for the main application.

## Benefits of This Migration

1. **Consistency**: All applications now follow the same pattern, making the repository more maintainable
2. **Separation of Concerns**: Helm values are now stored in separate files, making them easier to manage
3. **Reduced Duplication**: Using applicationsets reduces duplication and makes it easier to add new applications
4. **Best Practices**: The repository now follows best practices for organizing Kubernetes applications
5. **Flexibility**: The hybrid approach for MetalLB demonstrates how to handle complex scenarios

## Repository Organization

The repository now follows this structure:

- `k3s-cluster/kube-apps/applicationsets/`: Contains ApplicationSet definitions
  - `charts-appset.yaml`: For applications using local charts
  - `external-helm-appset.yaml`: For applications using external Helm charts
  - `manifests-appset.yaml`: For applications using Kubernetes manifests

- `k3s-cluster/kube-apps/charts/`: Contains local Helm charts
  - `stash/`: Custom chart for Stash

- `k3s-cluster/kube-apps/manifests/`: Contains Kubernetes manifests
  - `argocd/`: Manifests for ArgoCD
  - `longhorn/`: Manifests for Longhorn
  - `metallb/`: Manifests for MetalLB configuration

- `k3s-cluster/kube-apps/values/`: Contains values files for external Helm charts
  - `cert-manager-values.yaml`
  - `grafana-values.yaml`
  - `homeassistant-values.yaml`
  - `homepage-values.yaml`
  - `loki-values.yaml`
  - `longhorn-values.yaml`
  - `metallb-values.yaml`
  - `prometheus-values.yaml`