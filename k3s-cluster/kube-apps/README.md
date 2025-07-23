# Application Management Guide

This guide covers the management of applications deployed in the homelab Kubernetes cluster using ArgoCD and GitOps principles.

## Application Architecture Overview

The homelab uses a **multi-pattern application deployment strategy** managed by ArgoCD ApplicationSets:

### **Deployment Patterns**

1. **External Helm Charts** (`external-helm-appset.yaml`)
   - Third-party charts from public repositories
   - Custom values files for configuration
   - Examples: cert-manager, prometheus, grafana, longhorn

2. **Custom Helm Charts** (`charts-appset.yaml`)
   - Internal charts developed for homelab-specific needs
   - Complete chart structure with templates and values
   - Examples: custom applications not available as external charts

3. **Raw Kubernetes Manifests** (`manifests-appset.yaml`)
   - Direct YAML resource definitions
   - Best for simple applications or custom configurations
   - Examples: argocd self-management, metallb config, homebridge

## Directory Structure

```
kube-apps/
├── applicationsets/          # ArgoCD ApplicationSets
│   ├── external-helm-appset.yaml
│   ├── charts-appset.yaml
│   └── manifests-appset.yaml
├── applications/             # Individual ArgoCD Applications
├── charts/                   # Custom Helm charts (vendored)
├── manifests/                # Raw Kubernetes manifests
└── values/                   # Helm values files for external charts
```

## Adding New Applications

### **External Helm Chart Application**

1. **Add chart to vendor script**:
   ```bash
   # Edit vendor-charts.sh
   # Add new chart entry with repo URL and version
   ```

2. **Create values file**:
   ```bash
   # Create values/<app-name>-values.yaml
   # Configure chart-specific settings
   ```

3. **Add to ApplicationSet**:
   ```yaml
   # Edit applicationsets/external-helm-appset.yaml
   # Add new entry in generators list
   ```

4. **Deploy**:
   ```bash
   # Vendor the chart
   ./vendor-charts.sh
   
   # Commit changes
   git add . && git commit -m "add <app-name> application"
   
   # ArgoCD will automatically sync
   ```

### **Raw Manifest Application**

1. **Create manifest directory**:
   ```bash
   mkdir -p manifests/<app-name>
   ```

2. **Add Kubernetes resources**:
   ```bash
   # Create YAML files in manifests/<app-name>/
   # Example: namespace.yaml, deployment.yaml, service.yaml, ingress.yaml
   ```

3. **Add to ApplicationSet**:
   ```yaml
   # Edit applicationsets/manifests-appset.yaml
   # Add new entry in generators list
   ```

4. **Deploy**:
   ```bash
   git add . && git commit -m "add <app-name> manifests"
   # ArgoCD will automatically sync
   ```

### **Custom Helm Chart Application**

1. **Create chart structure**:
   ```bash
   mkdir -p charts/<app-name>
   cd charts/<app-name>
   helm create .
   # Customize templates and values.yaml
   ```

2. **Add to ApplicationSet**:
   ```yaml
   # Edit applicationsets/charts-appset.yaml
   # Add new entry in generators list
   ```

3. **Deploy**:
   ```bash
   git add . && git commit -m "add <app-name> chart"
   ```

## Application Configuration Patterns

### **Ingress Configuration**
All web-accessible services follow this ingress pattern:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <app-name>
  namespace: <app-namespace>
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - <app-name>.opsguy.io
    secretName: opsguy-io-tls
  rules:
  - host: <app-name>.opsguy.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: <app-name>
            port:
              number: <port>
```

### **Certificate Management**
Applications use individual Certificate resources per namespace:
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: <app-name>-opsguy-io-tls
  namespace: <app-namespace>
spec:
  secretName: opsguy-io-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - <app-name>.opsguy.io
```

### **Storage Configuration**
Applications requiring persistent storage use Longhorn:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: <app-name>-storage
  namespace: <app-namespace>
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: <size>
```

### **RBAC Configuration**
Applications needing Kubernetes API access:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: <app-name>
  namespace: <app-namespace>
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: <app-name>
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: <app-name>
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: <app-name>
subjects:
- kind: ServiceAccount
  name: <app-name>
  namespace: <app-namespace>
```

## Application Lifecycle Management

### **Updates and Upgrades**

#### **External Helm Charts**
```bash
# Update chart version in vendor-charts.sh
./vendor-charts.sh

# Update values if needed
# Edit values/<app-name>-values.yaml

# Commit and let ArgoCD sync
git add . && git commit -m "upgrade <app-name> to version X.Y.Z"
```

#### **Raw Manifests**
```bash
# Update YAML files in manifests/<app-name>/
# Commit changes
git add . && git commit -m "update <app-name> configuration"
```

#### **Custom Charts**
```bash
# Update chart version in Chart.yaml
# Update templates and values as needed
git add . && git commit -m "update <app-name> chart to version X.Y.Z"
```

### **Rollbacks**
```bash
# Via ArgoCD CLI
argocd app rollback <app-name> <revision-id>

# Via Git
git revert <commit-hash>
git push
# ArgoCD will automatically rollback
```

### **Monitoring Deployments**
```bash
# Check application status
argocd app get <app-name>

# Watch application sync
argocd app sync <app-name> --watch

# Check pod status
kubectl get pods -n <app-namespace>

# View application logs
kubectl logs -n <app-namespace> -l app=<app-name>
```

## ApplicationSet Management

### **ApplicationSet Structure**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: <appset-name>
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - name: <app-name>
        namespace: <app-namespace>
        # Additional parameters...
  template:
    metadata:
      name: '{{name}}'
    spec:
      project: default
      source:
        # Source configuration...
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{namespace}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

### **Common ApplicationSet Operations**
```bash
# View all ApplicationSets
kubectl get applicationsets -n argocd

# Check ApplicationSet status
kubectl describe applicationset <appset-name> -n argocd

# Force ApplicationSet refresh
kubectl annotate applicationset <appset-name> -n argocd \
  argocd.argoproj.io/refresh=true --overwrite
```

## Troubleshooting Applications

### **Common Issues**

#### **Application Stuck in Sync**
```bash
# Force hard refresh
argocd app sync <app-name> --force

# Check resource differences
argocd app diff <app-name>

# Manual resource cleanup
kubectl delete <resource-type> <resource-name> -n <namespace>
```

#### **Pod Not Starting**
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check resource constraints
kubectl top pods -n <namespace>

# Check storage availability
kubectl get pv
kubectl get pvc -n <namespace>
```

#### **Ingress Not Working**
```bash
# Check ingress resource
kubectl describe ingress <ingress-name> -n <namespace>

# Check certificate status
kubectl describe certificate <cert-name> -n <namespace>

# Check NGINX ingress logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

#### **Chart Vendoring Issues**
```bash
# Clean and re-vendor charts
rm -rf charts/<chart-name>
./vendor-charts.sh

# Check chart dependencies
helm dependency update charts/<chart-name>
```

### **ArgoCD Application Recovery**
```bash
# Delete and recreate application
argocd app delete <app-name>
# ApplicationSet will recreate it automatically

# Force sync with prune
argocd app sync <app-name> --prune --force
```

## Security Considerations

### **RBAC Best Practices**
- Grant minimal required permissions
- Use namespace-scoped roles when possible
- Regularly audit service account permissions

### **Secret Management**
- Never commit secrets to Git
- Use Kubernetes secrets for sensitive data
- Consider external secret management solutions

### **Network Policies**
- Implement network policies for sensitive applications
- Restrict cross-namespace communication
- Monitor network traffic patterns

### **Image Security**
- Use specific image tags, avoid `:latest`
- Regularly update base images
- Scan images for vulnerabilities

## Performance Optimization

### **Resource Management**
```yaml
# Always set resource requests and limits
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### **Storage Optimization**
- Choose appropriate storage classes
- Set reasonable PVC sizes
- Monitor storage usage and growth patterns

### **Scaling Strategies**
```yaml
# Use Horizontal Pod Autoscaler for scalable apps
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: <app-name>-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: <app-name>
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

---

*For cluster operations and troubleshooting, see [k3s-cluster/README.md](../README.md)*
*For service details and access URLs, see [SERVICES.md](../../SERVICES.md)*