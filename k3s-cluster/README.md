# K3s Cluster Operations Guide

This guide covers day-to-day operations and management of the homelab K3s cluster.

## Cluster Overview

**Cluster Information:**
- **Nodes**: pi5-1 (control plane + worker), pi5-2 (worker)
- **K3s Version**: v1.32.3+k3s1
- **Network**: 192.168.4.0/24 (Static IPs: .10, .11)
- **Load Balancer Range**: 192.168.4.20-30 (MetalLB)
- **Domain**: opsguy.io (with wildcard TLS certificate)

**Access Points:**
- **ArgoCD**: https://argo.opsguy.io
- **Homepage**: https://home.opsguy.io
- **Longhorn UI**: https://longhorn.opsguy.io
- **Grafana**: https://grafana.opsguy.io
- **Prometheus**: https://prometheus.opsguy.io

## Daily Operations

### Cluster Health Checks

```bash
# Check node status
kubectl get nodes -o wide

# Check all pods across namespaces
kubectl get pods --all-namespaces

# Check ArgoCD application sync status
kubectl get applications -n argocd

# Check ingress resources
kubectl get ingress --all-namespaces

# Check certificate status
kubectl get certificates --all-namespaces
```

### Application Management

#### Sync Applications
```bash
# Sync all applications via ArgoCD CLI
argocd app sync --all

# Sync specific application
argocd app sync <application-name>

# Check application health
argocd app get <application-name>
```

#### Managing ApplicationSets
```bash
# View ApplicationSets
kubectl get applicationsets -n argocd

# Check ApplicationSet status
kubectl describe applicationset <appset-name> -n argocd
```

### Storage Operations

#### Longhorn Management
```bash
# Check Longhorn system status
kubectl get pods -n longhorn-system

# View persistent volumes
kubectl get pv

# Check storage classes
kubectl get storageclass
```

#### Storage Troubleshooting
- Access Longhorn UI at https://longhorn.opsguy.io
- Monitor volume health and replica status
- Check node disk usage with `df -h` on each node

### Certificate Management

#### Certificate Status
```bash
# Check all certificates
kubectl get certificates --all-namespaces

# Check certificate details
kubectl describe certificate <cert-name> -n <namespace>

# Check Let's Encrypt rate limits
kubectl logs -n cert-manager deployment/cert-manager
```

#### Certificate Troubleshooting
- Verify DNS records for domains point to load balancer IP
- Check Let's Encrypt rate limits if certificate requests fail
- Ensure Route53 credentials are valid in cert-manager namespace

### Network Operations

#### MetalLB Status
```bash
# Check MetalLB pods
kubectl get pods -n metallb-system

# View IP address pools
kubectl get ipaddresspools -n metallb-system

# Check LoadBalancer services
kubectl get services --all-namespaces -o wide | grep LoadBalancer
```

#### Ingress Troubleshooting
```bash
# Check NGINX Ingress Controller
kubectl get pods -n ingress-nginx

# View ingress resources
kubectl get ingress --all-namespaces

# Check ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

## Maintenance Procedures

### Node Maintenance

#### Drain and Restore Nodes
```bash
# Drain node for maintenance (excludes DaemonSets)
kubectl drain pi5-2 --ignore-daemonsets --delete-emptydir-data

# Restore node after maintenance
kubectl uncordon pi5-2
```

#### Node Reboot Procedure
1. Drain the node: `kubectl drain <node-name> --ignore-daemonsets`
2. SSH to node: `ssh pi@<node-ip>`
3. Reboot: `sudo reboot`
4. Wait for node to come back online
5. Uncordon: `kubectl uncordon <node-name>`

### Cluster Updates

#### Update K3s
```bash
# Check current version
k3s --version

# Update via Ansible (recommended)
cd /path/to/homelab/k3s-cluster
ansible-playbook -i inventories/prod playbooks/install_k3s.yml
```

#### Update Applications
1. Update Helm chart versions in `vendor-charts.sh`
2. Run `./vendor-charts.sh` to pull new chart versions
3. Update values files if needed
4. Commit changes - ArgoCD will auto-sync

### Backup Procedures

#### Critical Data Backup
- **ArgoCD Configuration**: All configs are in Git (this repo)
- **Persistent Volumes**: Use Longhorn backup features
- **Secrets**: Document procedure for recreating secrets
- **Certificates**: Let's Encrypt auto-renewal handles certificate lifecycle

#### Disaster Recovery
1. Rebuild nodes using Ansible playbooks
2. Restore Longhorn volumes from backups
3. ArgoCD will restore all applications from Git
4. Manually recreate secrets that aren't in Git

## Monitoring and Observability

### Prometheus Queries
Access Prometheus at https://prometheus.opsguy.io

**Useful Queries:**
```promql
# Node memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Pod CPU usage
rate(container_cpu_usage_seconds_total[5m]) * 100

# Disk usage by node
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100

# ArgoCD application sync status
argocd_app_info{sync_status!="Synced"}
```

### Log Analysis
Access logs via Grafana at https://grafana.opsguy.io

**Common Log Queries:**
```logql
# ArgoCD application sync errors
{namespace="argocd"} |= "error" |= "sync"

# Certificate manager issues
{namespace="cert-manager"} |= "error"

# Ingress controller errors
{namespace="ingress-nginx"} |= "error"

# Application pod logs
{namespace="homepage"} | json
```

## Troubleshooting

### Common Issues

#### ArgoCD Out of Sync
```bash
# Force hard refresh
argocd app sync <app-name> --force

# Check for resource differences
argocd app diff <app-name>
```

#### Pod Stuck in Pending
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl top nodes

# Check storage availability
kubectl get pv
```

#### Certificate Not Working
```bash
# Check certificate status
kubectl describe certificate <cert-name> -n <namespace>

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Manually trigger certificate renewal
kubectl delete secret <cert-secret> -n <namespace>
```

#### Service Not Accessible
1. Check pod status: `kubectl get pods -n <namespace>`
2. Check service: `kubectl get svc -n <namespace>`
3. Check ingress: `kubectl get ingress -n <namespace>`
4. Check DNS resolution
5. Check MetalLB IP assignment

### Emergency Procedures

#### Complete Cluster Reset
```bash
# Stop K3s on all nodes
sudo systemctl stop k3s
sudo systemctl stop k3s-agent

# Clean up K3s installation
sudo /usr/local/bin/k3s-uninstall.sh  # on server
sudo /usr/local/bin/k3s-agent-uninstall.sh  # on agents

# Reinstall via Ansible
ansible-playbook -i inventories/prod playbooks/install_k3s.yml
```

#### Emergency Access
- **Direct Pod Access**: `kubectl exec -it <pod-name> -n <namespace> -- /bin/sh`
- **Port Forwarding**: `kubectl port-forward -n <namespace> <pod-name> 8080:8080`
- **Node Access**: SSH directly to nodes using static IPs

## Performance Tuning

### Resource Monitoring
- Monitor CPU/Memory usage via Grafana dashboards
- Set resource requests/limits for applications
- Use HPA (Horizontal Pod Autoscaler) for scalable workloads

### Storage Optimization
- Monitor Longhorn volume usage and replica health
- Configure appropriate storage classes for different workload types
- Regular cleanup of unused PVs

### Network Optimization
- Monitor ingress controller performance
- Optimize MetalLB configuration for service discovery
- Consider implementing network policies for security

---

*For architecture overview and component details, see the main [README.md](../README.md)*