# Manifest Applications Guide

This directory contains Kubernetes applications deployed as raw YAML manifests, managed by the `manifests-appset.yaml` ApplicationSet.

## Current Manifest Applications

### **ArgoCD** (`argocd/`)
ArgoCD self-management configuration - the GitOps engine managing itself.

**Components:**
- `argocd-cm.yaml` - Server configuration and user accounts
- `argocd-rbac-cm.yaml` - Role-based access control policies  
- `ingress.yaml` - HTTPS ingress for ArgoCD UI
- `repositories/homelab-repo.yaml` - Git repository configuration

**Access:** https://argo.opsguy.io

### **Certificate Manager Config** (`cert-manager-config/`)
Global certificate management configuration for the cluster.

**Components:**
- `cluster-issuer.yaml` - Let's Encrypt ClusterIssuer with Route53 DNS-01 challenge
- `wildcard-certificate.yaml` - Wildcard certificate for *.opsguy.io domain

**Features:**
- Automated certificate provisioning and renewal
- DNS-01 challenge for internal services
- Route53 integration for domain validation

### **Homebridge** (`homebridge/`)
HomeKit bridge for non-native smart home devices.

**Components:**
- `namespace.yaml` - Dedicated namespace
- `deployment.yaml` - Homebridge application
- `service.yaml` - ClusterIP service  
- `ingress.yaml` - HTTPS ingress
- `persistentvolumeclaim.yaml` - Configuration storage

**Access:** https://homebridge.opsguy.io

### **Homepage** (`homepage/`)
Service dashboard and homelab homepage.

**Components:**
- `namespace.yaml` - Dedicated namespace
- `serviceaccount.yaml` - Service account for Kubernetes API access
- `rbac.yaml` - ClusterRole and binding for service discovery
- `configmap.yaml` - Homepage configuration and service definitions
- `deployment.yaml` - Homepage application with individual file mounts
- `service.yaml` - ClusterIP service
- `ingress.yaml` - HTTPS ingress

**Access:** https://home.opsguy.io

### **MetalLB Config** (`metallb-config/`)
Load balancer IP pool configuration.

**Components:**
- `config.yaml` - IPAddressPool defining available IPs (192.168.4.20-30)

## Adding New Manifest Applications

### **1. Create Application Directory**
```bash
mkdir -p manifests/<app-name>
cd manifests/<app-name>
```

### **2. Create Kubernetes Resources**

#### **Namespace** (recommended)
```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: <app-name>
  labels:
    app.kubernetes.io/name: <app-name>
```

#### **Deployment**
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <app-name>
  namespace: <app-name>
  labels:
    app.kubernetes.io/name: <app-name>
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: <app-name>
  template:
    metadata:
      labels:
        app.kubernetes.io/name: <app-name>
    spec:
      containers:
      - name: <app-name>
        image: <image>:<tag>
        ports:
        - containerPort: <port>
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"  
            cpu: "500m"
```

#### **Service**
```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: <app-name>
  namespace: <app-name>
  labels:
    app.kubernetes.io/name: <app-name>
spec:
  type: ClusterIP
  ports:
  - name: http
    port: <port>
    targetPort: <target-port>
    protocol: TCP
  selector:
    app.kubernetes.io/name: <app-name>
```

#### **Ingress** (if web-accessible)
```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <app-name>
  namespace: <app-name>
  labels:
    app.kubernetes.io/name: <app-name>
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

#### **Certificate** (for TLS)
```yaml
# certificate.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: <app-name>-opsguy-io-tls
  namespace: <app-name>
spec:
  secretName: opsguy-io-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - <app-name>.opsguy.io
```

### **3. Add to ApplicationSet**

Edit `../applicationsets/manifests-appset.yaml`:
```yaml
generators:
- list:
    elements:
    # ... existing applications ...
    - name: <app-name>
      namespace: <app-name>
```

### **4. Deploy**
```bash
git add .
git commit -m "add <app-name> manifest application"
git push
```

ArgoCD will automatically detect and deploy the new application.

## Configuration Patterns

### **ConfigMaps for Application Configuration**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: <app-name>-config
  namespace: <app-name>
data:
  config.yaml: |
    # Application configuration
    key: value
```

### **Secrets for Sensitive Data**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: <app-name>-secret
  namespace: <app-name>
type: Opaque
stringData:
  username: <username>
  password: <password>
```

### **Persistent Storage**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: <app-name>-storage
  namespace: <app-name>
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 1Gi
```

### **RBAC for Kubernetes API Access**
```yaml
# serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: <app-name>
  namespace: <app-name>

---
# rbac.yaml
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
  namespace: <app-name>
```

## Best Practices

### **Resource Organization**
- One resource per file when possible
- Use consistent file naming (e.g., `deployment.yaml`, `service.yaml`)
- Group related resources logically
- Use meaningful labels and annotations

### **Namespace Strategy**
- Create dedicated namespace for each application
- Use namespace-scoped resources when possible
- Apply resource quotas and limits per namespace

### **Configuration Management**
- Use ConfigMaps for non-sensitive configuration
- Use Secrets for sensitive data (don't commit to Git)
- Externalize environment-specific settings
- Use consistent configuration patterns

### **Security**
- Apply least-privilege RBAC principles
- Use non-root containers when possible
- Set security contexts appropriately
- Regularly update base images

### **Monitoring**
- Add Prometheus metrics annotations
- Configure proper health checks
- Set up logging for troubleshooting
- Monitor resource usage patterns

## Troubleshooting

### **Application Not Deploying**
```bash
# Check ApplicationSet status
kubectl describe applicationset manifests-applications -n argocd

# Check ArgoCD application
argocd app get <app-name>

# Check resource events
kubectl get events -n <app-namespace> --sort-by='.lastTimestamp'
```

### **Pod Issues**
```bash
# Check pod status and events
kubectl describe pod <pod-name> -n <namespace>

# Check pod logs
kubectl logs <pod-name> -n <namespace>

# Check resource constraints
kubectl top pod <pod-name> -n <namespace>
```

### **Ingress/Certificate Issues**
```bash
# Check ingress status
kubectl describe ingress <ingress-name> -n <namespace>

# Check certificate status
kubectl describe certificate <cert-name> -n <namespace>

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager
```

### **Storage Issues**
```bash
# Check PVC status
kubectl describe pvc <pvc-name> -n <namespace>

# Check available storage
kubectl get pv

# Check Longhorn status
kubectl get pods -n longhorn-system
```

## Migration from Helm

If migrating an application from Helm to raw manifests:

1. **Extract resources**: `helm get manifest <release-name>`
2. **Clean up resources**: Remove Helm-specific annotations and labels
3. **Organize files**: Split into logical resource files
4. **Update ApplicationSet**: Move from external-helm to manifests
5. **Test deployment**: Verify all resources deploy correctly

---

*For general application management, see [../README.md](../README.md)*
*For cluster operations, see [../../README.md](../../README.md)*