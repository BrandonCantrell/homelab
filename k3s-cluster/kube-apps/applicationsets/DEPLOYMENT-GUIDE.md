# Deployment Guide for ApplicationSets and Gateway API Migration

This guide covers two major improvements to your homelab Kubernetes setup:
1. Migrating individual applications to ApplicationSets
2. Optionally migrating from Nginx Ingress to Kubernetes Gateway API

## Part 1: Deploying ApplicationSets

### Prerequisites

- Access to your ArgoCD instance
- Git access to your homelab repository

### Deployment Steps

#### 1. Verify ApplicationSets Configuration

Ensure that the ApplicationSets are correctly configured with the right applications, charts, versions, and values files:

- `external-helm-appset.yaml`: Contains configurations for external Helm charts
- `charts-appset.yaml`: Contains configurations for local charts
- `manifests-appset.yaml`: Contains configurations for raw Kubernetes manifests

#### 2. Commit and Push Changes

Commit all the changes we've made to your repository and push them to GitHub:

```bash
git add .
git commit -m "Migrate applications to ApplicationSets"
git push
```

#### 3. Deploy the ApplicationSets Application

The ApplicationSets are managed by ArgoCD through the `applicationsets` Application defined in `k3s-cluster/kube-apps/applications/applicationsets.yaml`. This application should already be deployed in your cluster.

ArgoCD should automatically detect the changes to the ApplicationSets and apply them. You can verify this in the ArgoCD UI by checking the `applicationsets` application.

#### 4. Verify Generated Applications

After the ApplicationSets are applied, verify that the applications are correctly generated in ArgoCD:

1. Check the ArgoCD UI to ensure all applications are created
2. Verify that the applications are synced and healthy
3. Confirm that the applications are using the correct values files

#### 4.5. Handle Additional Resources

Some applications require additional resources that may not be directly supported by their Helm charts. We've adopted a hybrid approach:

##### Longhorn

For Longhorn, we're using the community Helm chart with all necessary values in the `longhorn-values.yaml` file. The Helm chart supports the ingress configuration directly, so no additional resources are needed.

##### MetalLB

For MetalLB, we're using a hybrid approach:
1. The main MetalLB application is deployed using the community Helm chart via `external-helm-appset.yaml`
2. The MetalLB configuration (IPAddressPool and L2Advertisement) is deployed using the manifests via `manifests-appset.yaml`

This approach ensures that the MetalLB configuration is applied correctly while still taking advantage of the community Helm chart for the main application.

#### 5. Remove Individual Application Files

Once you've confirmed that the ApplicationSets are working correctly, you can safely remove the individual application files:

```bash
git rm k3s-cluster/kube-apps/applications/longhorn.yaml
git rm k3s-cluster/kube-apps/applications/metallb.yaml
git rm k3s-cluster/kube-apps/applications/homepage/homepage.yaml
git rm k3s-cluster/kube-apps/applications/homeassistant/homeassistant.yaml
git rm k3s-cluster/kube-apps/applications/metallb-config.yaml
git commit -m "Remove individual application files migrated to ApplicationSets"
git push
```

**Note**: If you want to keep the individual application files for any reason, you can do so, but be aware that they may conflict with the ApplicationSet-generated applications if they have the same names.

## Part 2: Migrating to Gateway API (Optional)

If you want to move away from Nginx Ingress to the more modern Kubernetes Gateway API, follow these steps:

### 1. Choose a Gateway API Implementation

Several implementations are available:

- **Contour**: Lightweight, Envoy-based implementation
- **Istio**: Full service mesh with Gateway API support
- **Kong**: API gateway with Gateway API support
- **Cilium**: Network-layer implementation

For a homelab, Contour is often a good choice due to its simplicity and low resource usage.

### 2. Install Gateway API CRDs

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v0.8.0/standard-install.yaml
```

### 3. Create a Values File for the Gateway API Implementation

```yaml
# k3s-cluster/kube-apps/values/contour-values.yaml
# Example values for Contour
deployment:
  replicas: 2

envoy:
  service:
    type: LoadBalancer
    annotations:
      metallb.universe.tf/loadBalancerIPs: "192.168.4.20"  # Use your MetalLB IP range

gateway:
  enabled: true
```

### 4. Add the Gateway API Implementation to External Helm ApplicationSet

```yaml
# Add to k3s-cluster/kube-apps/applicationsets/external-helm-appset.yaml
- name: contour
  namespace: contour-system
  chart: contour
  repo: https://charts.bitnami.com/bitnami
  version: 12.1.0  # Check for the latest version
  valuesPath: k3s-cluster/kube-apps/values/contour-values.yaml
```

### 5. Create Gateway API Resources

```yaml
# k3s-cluster/kube-apps/manifests/gateway-api/gateway.yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: contour
spec:
  controllerName: projectcontour.io/gateway-controller

---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: homelab-gateway
  namespace: default
spec:
  gatewayClassName: contour
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
  - name: https
    port: 443
    protocol: HTTPS
    allowedRoutes:
      namespaces:
        from: All
    tls:
      mode: Terminate
      certificateRefs:
      - name: homelab-tls
        kind: Secret
```

### 6. Add Gateway API Manifests to the Manifests ApplicationSet

```yaml
# Add to k3s-cluster/kube-apps/applicationsets/manifests-appset.yaml
- name: gateway-api
  namespace: default
  path: k3s-cluster/kube-apps/manifests/gateway-api
```

### 7. Migrate Applications One by One

For each application, update the values file to use HTTPRoute instead of Ingress:

```yaml
# Example for homepage-values.yaml
# Disable the existing ingress
ingress:
  main:
    enabled: false

# Add HTTPRoute configuration
additionalManifests:
  - apiVersion: gateway.networking.k8s.io/v1beta1
    kind: HTTPRoute
    metadata:
      name: homepage
      namespace: homepage
    spec:
      parentRefs:
      - name: homelab-gateway
        namespace: default
      hostnames:
      - "home.homelab"
      rules:
      - matches:
        - path:
            type: PathPrefix
            value: /
        backendRefs:
        - name: homepage
          port: 3000
```

### 8. Remove Nginx Ingress

After all applications have been migrated to Gateway API, you can remove Nginx Ingress:

```bash
# If using Helm/ApplicationSet
# Remove from your external-helm-appset.yaml

# Or delete the individual application
kubectl delete -n ingress-nginx deployment,service nginx-ingress-controller
```

## Troubleshooting

### ApplicationSet Issues

If you encounter issues with ApplicationSets:

1. Check the ArgoCD logs for error messages
2. Verify that the application names in the ApplicationSets don't conflict with existing applications
3. If necessary, manually delete the conflicting applications in ArgoCD and let the ApplicationSets regenerate them

### Gateway API Issues

If you encounter issues with Gateway API:

1. Verify that the Gateway API CRDs are installed correctly
2. Check that the Gateway implementation (e.g., Contour) is running properly
3. Examine the HTTPRoute resources to ensure they're correctly configured
4. Check the logs of the Gateway implementation for any errors

## Rollback Plan

### Rolling Back ApplicationSets

If you need to roll back the ApplicationSet changes:

1. Revert the commits that removed the individual application files:
   ```bash
   git revert <commit-hash>
   git push
   ```

2. If necessary, manually delete the ApplicationSet-generated applications in ArgoCD to avoid conflicts with the restored individual applications.

### Rolling Back Gateway API Migration

If you need to roll back the Gateway API migration:

1. Re-enable the Ingress resources in your application values files
2. Verify that the applications are accessible through Nginx Ingress
3. Remove the Gateway API resources:
   ```bash
   kubectl delete gateway homelab-gateway
   kubectl delete gatewayclass contour
   ```

4. If necessary, reinstall Nginx Ingress if you've removed it