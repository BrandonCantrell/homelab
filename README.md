# Homelab Architecture Documentation

## Overview

This repository implements a modern, GitOps-driven homelab infrastructure built on Raspberry Pi 5 hardware. The architecture combines infrastructure-as-code, configuration management, and Kubernetes to create a scalable and maintainable home infrastructure platform.

## Core Architecture Components

### Hardware Layer
- **Compute**: Raspberry Pi 5 (4GB) devices (2-node cluster)
- **Storage**: SSD-based storage for improved reliability over SD cards
- **Network**: Static IP addressing in the 192.168.4.x range with MetalLB providing virtual IPs

### Infrastructure Provisioning Layer
- **Ansible**: Automated system configuration and Kubernetes deployment
  - Bootstrap system configurations
  - User management
  - Raspberry Pi optimizations (cgroups, swap, etc.)
  - K3s installation and configuration

### Container Orchestration Layer
- **K3s**: Lightweight Kubernetes distribution optimized for Raspberry Pi
  - Control plane on primary node (pi5-1)
  - Worker node configuration (pi5-2)
- **Storage**: Longhorn distributed block storage system
- **Networking**: NGINX Ingress + MetalLB for load balancing

### Platform Services
- **Argo CD**: GitOps continuous delivery platform
  - Self-managed via ApplicationSets
  - Custom application deployment strategies
- **Cert-Manager**: Automated TLS certificate management
- **Observability Stack**:
  - Prometheus: Metrics collection and storage
  - Loki: Log aggregation
  - Promtail: Log collection agent
  - Grafana: Visualization dashboard

### Application Layer
- **Home Assistant**: Home automation platform
- **Homepage**: Dashboard for service discovery

## Architectural Patterns

### GitOps Workflow
The entire infrastructure follows a GitOps pattern where:
1. All configuration is version-controlled in this repository
2. Changes are made through pull requests and commits
3. Argo CD detects changes and reconciles the actual state with the desired state
4. Applications are deployed in a declarative manner

### Multi-Tier Application Management
Applications are managed in three distinct patterns:
1. **External Helm Charts**: Third-party applications with customized values
2. **Custom Chart Applications**: Our own applications with Helm-based packaging
3. **Raw Manifest Applications**: Kubernetes resources defined directly as YAML

### Networking Architecture
- **Ingress Control**: NGINX Ingress Controller for HTTP/HTTPS traffic routing
- **Load Balancing**: MetalLB providing IP allocation for LoadBalancer services (192.168.4.20-30 range)
- **TLS Termination**: Cert-Manager for automated certificate management
- **Name Resolution**: External home router with static DNS assignments

### Storage Architecture
- **Distributed Storage**: Longhorn providing persistent volumes with replication
- **Default Storage Class**: Longhorn configured as the default storage provider
- **Data Persistence**: Applications configured to use PersistentVolumeClaims

### Observability Architecture
The homelab implements a complete observability stack:
- **Metrics Collection**: Prometheus with node-exporter for hardware and service metrics
- **Log Aggregation**: Loki and Promtail for centralized logging
- **Visualization**: Grafana dashboards for metrics, logs, and system status
- **Service Health**: Alert Manager for monitoring and notification

## Key System Components

### Infrastructure Management
- **Ansible Playbooks**:
  - `bootstrap.yml`: System preparation and user setup
  - `users.yml`: User account management
  - `install_k3s.yml`: K3s cluster deployment
  - `site.yml`: Complete setup workflow

- **Ansible Roles**:
  - `pi_system_prep`: Raspberry Pi-specific optimizations
  - `users`: User management and SSH key configuration

### Kubernetes Platform Services

#### Core Services
- **K3s**: Lightweight Kubernetes optimized for edge computing
  - Version: v1.32.3+k3s1
  - Control plane on pi5-1 (192.168.4.10)
  - Worker node on pi5-2 (192.168.4.11)

#### Argo CD
- Deployed as the GitOps engine for the entire cluster
- Self-manages through ApplicationSets
- Configured applications divided into:
  - External Helm charts with custom values
  - Custom Helm charts
  - Raw Kubernetes manifests

#### Cert-Manager
- Provides automated TLS certificate management
- Version: 1.13.2
- Configured with cluster-wide issuers
- Secures ingress resources automatically

#### Ingress & Load Balancing
- **NGINX Ingress Controller**:
  - Version: 4.12.1
  - Default ingress class
  - TLS termination
- **MetalLB**:
  - Version: 0.14.6
  - L2 advertisement mode
  - IP range: 192.168.4.20-30

#### Storage
- **Longhorn**:
  - Version: 1.8.1
  - Default storage class
  - Replica count: 1 (due to 2-node limitation)
  - Web UI exposed via ingress

#### Observability
- **Prometheus**:
  - Version: 22.6.7
  - Configured for scraping Kubernetes APIs, nodes, and services
  - Retention period: 15 days
  - Persistent storage using Longhorn
- **Loki**:
  - Version: 2.9.10
  - Log retention: 30 days
  - Persistent storage using Longhorn
- **Grafana**:
  - Version: 11.0.0
  - Pre-configured dashboards for Kubernetes, nodes, and logs
  - Multiple data sources (Prometheus, Loki)
  - Persistent storage using Longhorn
- **Promtail**:
  - Version: 6.15.0
  - Collects logs from all pods and system components
  - Configured to add contextual labels for better filtering

### Application Layer
- **Home Assistant**:
  - Version: latest (pulled from ghcr.io/home-assistant/home-assistant)
  - Host networking for device discovery
  - Persistent storage
  - Exposed via ingress at homeassistant.homelab
- **Homepage**:
  - Version: latest
  - Services dashboard with links to all homelab resources
  - Exposed via ingress at home.homelab
- **Stash**:
  - Backup solution for cluster data
  - Custom chart implementation

### Chart Vendoring System
This architecture employs a chart vendoring approach where specific versions of Helm charts are pulled and stored locally in the repository. Benefits include:

- **Consistency**: All chart versions are pinned and tracked in Git
- **Offline Development**: Allows development without internet access
- **Modification**: Charts can be customized as needed
- **Auditing**: Changes to charts are visible in Git history

The vendoring system is implemented through a `vendor-charts.sh` script that:
- Checks for version mismatches between desired and local charts
- Downloads and extracts missing or outdated charts
- Cleans up temporary files
- Makes charts available for Argo CD ApplicationSets

Vendored charts include:
- ingress-nginx (4.12.1)
- longhorn (1.8.1)
- metallb (0.14.6)
- homepage (2.0.2)
- home-assistant (0.2.117)
- cert-manager (1.13.2)
- loki-stack (2.9.10)
- grafana (6.58.8)
- prometheus (22.6.7)
- promtail (6.15.0)

## Directory Structure Overview

```text
homelab/
│
├── .github/                    # CI/CD workflows
│
└── k3s-cluster/                # Production Kubernetes environment
    │
    ├── ansible.cfg             # Ansible configuration
    │
    ├── files/                  # SSH keys and other static files
    │
    ├── inventories/            # Environment-specific inventories
    │   └── prod/               # Production environment
    │
    ├── kube-apps/              # Kubernetes applications
    │   ├── applications/       # Individual Argo CD Applications
    │   ├── applicationsets/    # Argo CD ApplicationSets
    │   ├── charts/             # Helm charts (vendored)
    │   ├── manifests/          # Raw Kubernetes manifests
    │   └── values/             # Helm chart values
    │
    ├── playbooks/              # Ansible playbooks
    │
    ├── roles/                  # Ansible roles
    │
    └── vendor-charts.sh        # Script for vendoring Helm charts
```


## Evolution and Scaling

This architecture supports horizontal scaling by adding additional Raspberry Pi nodes to the cluster, with the underlying K3s and MetalLB handling the orchestration and load balancing. The GitOps approach ensures consistency across all environments and simplified operational management.

The system is designed to be resilient, with Longhorn providing distributed storage, replicated across nodes, ensuring data persists even if a node fails.

## Future Architecture Plans

The architecture is being extended to include:
- **Service Mesh**: Implementation of Istio for advanced microservice management
- **API Gateway**: Migration to Kubernetes Gateway API for modern ingress control
- **Additional Home Services**: Pi-hole, media servers, and other utilities
- **Database Services**: PostgreSQL with operator-based management
- **Integration**: Connections with external cloud services where appropriate

---

*Last updated: May 2025*
