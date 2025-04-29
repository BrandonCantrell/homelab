# Migrating from Nginx Ingress to Kubernetes Gateway API

This guide outlines how to migrate your homelab from Nginx Ingress to the Kubernetes Gateway API, which is a more modern and flexible approach to ingress traffic management.

## What is the Gateway API?

The Gateway API is a collection of resources that provide a more powerful and flexible way to manage ingress traffic:

1. **Gateway**: Defines a load balancer or proxy that accepts connections
2. **GatewayClass**: Defines the implementation type (similar to IngressClass)
3. **HTTPRoute**: Defines HTTP routing rules (replacing Ingress resources)
4. **TCPRoute**, **UDPRoute**, **TLSRoute**: Support for additional protocols

## Benefits of Gateway API over Nginx Ingress

- Clearer separation of concerns
- Support for more protocols (not just HTTP)
- More complex routing scenarios
- More extensible and future-proof
- Native Kubernetes resource (not dependent on a specific implementation)

## Implementation Steps

### 1. Choose a Gateway API Implementation

Several implementations are available:

- **Contour**: Lightweight, Envoy-based implementation
- **Istio**: Full service mesh with Gateway API support
- **Kong**: API gateway with Gateway API support
- **Cilium**: Network-layer implementation

For a homelab, Contour is often a good choice due to its simplicity and low resource usage.

### 2. Create a Values File for the Gateway API Implementation

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

### 3. Add the Gateway API Implementation to External Helm ApplicationSet

```yaml
# Add to k3s-cluster/kube-apps/applicationsets/external-helm-appset.yaml
- name: contour
  namespace: contour-system
  chart: contour
  repo: https://charts.bitnami.com/bitnami
  version: 12.1.0  # Check for the latest version
  valuesPath: k3s-cluster/kube-apps/values/contour-values.yaml
```

### 4. Create a GatewayClass and Gateway

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

### 5. Add Gateway API Manifests to the Manifests ApplicationSet

```yaml
# Add to k3s-cluster/kube-apps/applicationsets/manifests-appset.yaml
- name: gateway-api
  namespace: default
  path: k3s-cluster/kube-apps/manifests/gateway-api
```

### 6. Update Application Values to Use HTTPRoute Instead of Ingress

For each application, you'll need to update the values to use HTTPRoute instead of Ingress. Here's an example for homepage:

```yaml
# k3s-cluster/kube-apps/values/homepage-gateway-values.yaml
# This would replace or supplement your existing homepage-values.yaml

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

### 7. Migration Strategy

1. **Deploy the Gateway API CRDs**:
   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v0.8.0/standard-install.yaml
   ```

2. **Deploy the Gateway API implementation** (Contour in this example) using the ApplicationSet

3. **Create the GatewayClass and Gateway resources** using the manifests ApplicationSet

4. **Migrate one application at a time**:
   - Update the application's values file to include HTTPRoute configuration
   - Verify that the application is accessible through the Gateway
   - Once confirmed, disable the Ingress for that application

5. **Remove Nginx Ingress** after all applications have been migrated:
   ```bash
   # Remove from your external-helm-appset.yaml if it's there
   # Or delete the individual application
   kubectl delete -n ingress-nginx deployment,service nginx-ingress-controller
   ```

## Example: Migrating Homepage Application

1. **Update homepage-values.yaml**:
   ```yaml
   # Disable the existing ingress
   ingress:
     main:
       enabled: false
   
   # Add HTTPRoute configuration as an additional manifest
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

2. **Apply the changes** through ArgoCD

3. **Verify** that Homepage is accessible through the Gateway

4. **Repeat** for other applications

## Conclusion

Migrating from Nginx Ingress to the Gateway API provides a more modern and flexible approach to ingress traffic management. While it requires some upfront work to migrate, the benefits in terms of flexibility, extensibility, and native Kubernetes support make it worthwhile for a homelab environment.

The Gateway API is still evolving, but it represents the future direction of Kubernetes ingress traffic management and is worth adopting for new and existing projects.