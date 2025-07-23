# Homelab Services Directory

This document provides a comprehensive overview of all services running in the homelab cluster.

## Service Access URLs

### **Core Platform Services**

| Service | URL | Purpose | Namespace |
|---------|-----|---------|-----------|
| **ArgoCD** | https://argo.opsguy.io | GitOps deployment platform | `argocd` |
| **Homepage** | https://home.opsguy.io | Service dashboard and homepage | `homepage` |
| **Grafana** | https://grafana.opsguy.io | Metrics and log visualization | `grafana` |
| **Prometheus** | https://prometheus.opsguy.io | Metrics collection and monitoring | `prometheus` |
| **Longhorn** | https://longhorn.opsguy.io | Distributed storage management | `longhorn-system` |

### **Home Automation**

| Service | URL | Purpose | Namespace |
|---------|-----|---------|-----------|
| **Home Assistant** | https://homeassistant.opsguy.io | Home automation platform | `home-assistant` |
| **Homebridge** | https://homebridge.opsguy.io | HomeKit bridge for non-native devices | `homebridge` |

### **Infrastructure Services**

| Service | Internal Access | Purpose | Namespace |
|---------|-----------------|---------|-----------|
| **Loki** | Internal only | Log aggregation | `loki` |
| **Promtail** | DaemonSet | Log collection agent | `promtail` |
| **MetalLB** | L2 Advertisement | Load balancer (IPs: 192.168.4.20-30) | `metallb-system` |
| **NGINX Ingress** | LoadBalancer: 192.168.4.20 | HTTP/HTTPS ingress controller | `ingress-nginx` |
| **cert-manager** | Internal only | TLS certificate management | `cert-manager` |

## Service Architecture Overview

### **GitOps & Deployment**
- **ArgoCD**: Central deployment engine managing all applications via GitOps
  - **Self-managing**: ArgoCD deploys itself via ApplicationSets
  - **Multi-pattern**: Supports Helm charts, raw manifests, and external charts
  - **Automatic sync**: Monitors Git repository for changes

### **Observability Stack**
- **Prometheus**: Scrapes metrics from Kubernetes API, nodes, and applications
- **Loki**: Aggregates logs from all pods and system components
- **Promtail**: DaemonSet collecting logs across all nodes
- **Grafana**: Pre-configured dashboards for cluster monitoring and application metrics
- **AlertManager**: (Future) Integrated with Prometheus for alerting

### **Storage & Infrastructure**
- **Longhorn**: Distributed block storage providing persistent volumes
  - **Replication**: Currently replica count 1 (2-node limitation)
  - **Backup**: Supports snapshots and cross-cluster backups
- **MetalLB**: Layer 2 load balancer providing virtual IPs for services
- **cert-manager**: Automated certificate provisioning via Let's Encrypt DNS-01 challenges

### **Application Layer**
- **Homepage**: Centralized dashboard showing all service links and status
- **Home Assistant**: Comprehensive home automation with device integration
- **Homebridge**: Bridges non-HomeKit devices to Apple's ecosystem

## Service Dependencies

### **Critical Path Dependencies**
```
K3s Cluster
├── MetalLB (LoadBalancer IPs)
├── NGINX Ingress (HTTP routing)
├── cert-manager (TLS certificates)
│   └── Route53 DNS (Let's Encrypt validation)
├── Longhorn (Storage)
│   └── Node disk space
└── ArgoCD (Application deployment)
    └── Git repository access
```

### **Application Dependencies**
- **All web services** → NGINX Ingress → MetalLB → DNS resolution
- **Persistent data services** → Longhorn → Node storage
- **Monitoring** → Prometheus → Service discovery → Kubernetes API
- **Logging** → Promtail → Loki → Log storage
- **Home automation** → Home Assistant → Network access to IoT devices

## Service Health Monitoring

### **Health Check Commands**
```bash
# Platform services status
kubectl get pods -n argocd
kubectl get pods -n ingress-nginx
kubectl get pods -n cert-manager
kubectl get pods -n longhorn-system
kubectl get pods -n metallb-system

# Application services status
kubectl get pods -n homepage
kubectl get pods -n home-assistant
kubectl get pods -n homebridge

# Observability services status
kubectl get pods -n prometheus
kubectl get pods -n grafana
kubectl get pods -n loki
```

### **Service-Specific Health Indicators**

#### **ArgoCD**
- Applications should show "Synced" and "Healthy" status
- Check: `kubectl get applications -n argocd`

#### **Certificate Manager**
- All certificates should have "Ready" status
- Check: `kubectl get certificates --all-namespaces`

#### **Longhorn**
- All volumes should show "Attached" status
- Web UI accessible at https://longhorn.opsguy.io

#### **MetalLB**
- LoadBalancer services should have external IPs assigned
- Check: `kubectl get svc --all-namespaces | grep LoadBalancer`

#### **Ingress Services**
- All ingress resources should have host rules configured
- TLS certificates should be properly referenced
- Check: `kubectl get ingress --all-namespaces`

## Resource Usage Profiles

### **High Resource Services**
- **Home Assistant**: 1-2GB RAM, moderate CPU
- **Grafana**: 500MB-1GB RAM with dashboard rendering
- **Prometheus**: 1-2GB RAM for metrics storage
- **Longhorn**: Disk I/O intensive, 200-500MB RAM per node

### **Low Resource Services**
- **Homepage**: <100MB RAM, minimal CPU
- **ArgoCD**: 200-500MB RAM, low CPU
- **cert-manager**: <100MB RAM, periodic CPU spikes
- **Ingress Controller**: 100-200MB RAM, moderate CPU

### **Resource Scaling Considerations**
- **Prometheus retention**: Currently 15 days, impacts storage requirements
- **Loki retention**: Currently 30 days, impacts log storage
- **Longhorn replicas**: Set to 1 due to 2-node cluster limitation
- **Node capacity**: Monitor CPU/Memory usage via Grafana dashboards

## Network Access Patterns

### **External Access (Internet-facing)**
```
Internet → Home Router → MetalLB (192.168.4.20) → NGINX Ingress → Services
```

### **Internal Service Communication**
- **ArgoCD** → Git repository (GitHub)
- **cert-manager** → Let's Encrypt ACME + Route53 API
- **Home Assistant** → IoT devices (local network)
- **Promtail** → Loki (internal cluster communication)
- **Grafana** → Prometheus + Loki (internal cluster communication)

### **Service Mesh Considerations**
- Currently using basic Kubernetes networking
- Future: Consider Istio for advanced traffic management
- mTLS between services not currently implemented

## Backup and Recovery

### **Stateful Services Data**
| Service | Data Location | Backup Strategy |
|---------|---------------|-----------------|
| **Home Assistant** | Longhorn PV | Longhorn snapshots |
| **Grafana** | Longhorn PV | Dashboard exports + Longhorn snapshots |
| **Prometheus** | Longhorn PV | Configuration in Git, data via Longhorn snapshots |
| **Loki** | Longhorn PV | Logs are ephemeral, configuration in Git |
| **ArgoCD** | Kubernetes secrets | Configuration in Git, regenerate secrets |

### **Configuration Backup**
- **All application configurations**: Stored in Git repository
- **Kubernetes secrets**: Need manual backup/recreation procedure
- **TLS certificates**: Auto-renewed via Let's Encrypt
- **Infrastructure as Code**: Complete cluster reproducible via Ansible

## Performance Optimization

### **Current Optimizations**
- **Resource requests/limits**: Set for all production services
- **Storage classes**: Longhorn configured for different performance needs
- **Ingress optimization**: NGINX configured for homelab scale
- **Log rotation**: Configured retention periods for logs and metrics

### **Monitoring Points**
- **CPU/Memory usage**: Via Prometheus and Grafana dashboards
- **Storage usage**: Longhorn UI and Prometheus metrics  
- **Network traffic**: Ingress controller metrics
- **Certificate expiration**: cert-manager Prometheus metrics

### **Scaling Triggers**
- **Add nodes**: When CPU consistently >70% or memory >80%
- **Increase storage**: When Longhorn usage >80%
- **Optimize retention**: When storage growth impacts performance

---

*Last updated: December 2025*
*For operational procedures, see [k3s-cluster/README.md](k3s-cluster/README.md)*