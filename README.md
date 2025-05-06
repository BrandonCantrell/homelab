# Homelab Architecture

## Overview

This repository implements a modern, GitOps-driven homelab infrastructure built on Raspberry Pi 5 hardware. The architecture combines infrastructure-as-code, configuration management, and Kubernetes to create a scalable and maintainable home infrastructure platform.

## Core Architecture Components

### Hardware Layer
- **Compute**: Raspberry Pi 5 (8GB) devices
- **Storage**: SSD-based storage for improved reliability over SD cards
- **Network**: Static IP addressing in the 192.168.4.x range

### Infrastructure Provisioning Layer
- **Ansible**: Automated system configuration and Kubernetes deployment

### Container Orchestration Layer
- **K3s**: Lightweight Kubernetes distribution optimized for Raspberry Pi
- **Longhorn**: Distributed block storage for persistent volumes
- **MetalLB**: Bare metal load balancer implementation

### Application Deployment Layer
- **Argo CD**: GitOps continuous delivery for Kubernetes
- **ApplicationSets**: Scalable application definitions
- **Helm**: Package management for Kubernetes applications

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
- Ingress through NGINX Ingress Controller
- Service mesh capabilities through MetalLB
- DNS through external home router with static assignments

## System Components

### Infrastructure Management
- **Ansible Playbooks**: Bootstrap system, prepare Raspberry Pi, deploy K3s
- **Ansible Roles**: Specialized configurations for Raspberry Pi and user management

### Kubernetes Platform Components
- **Core Services**: K3s, Argo CD, MetalLB, NGINX Ingress
- **Storage**: Longhorn providing replicated storage
- **Observability**: Prometheus, Grafana, Loki for monitoring and logging

### Application Layer
- **Home Automation**: Home Assistant
- **Dashboard**: Homepage for service discovery
- **Backup**: Stash for data protection

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

Vendored charts include core infrastructure (NGINX Ingress, MetalLB, Longhorn), observability stack (Prometheus, Grafana, Loki), and applications (Home Assistant, Homepage).

## Directory Structure Overview

homelab/
├── .github/                    # CI/CD workflows
└── k3s-cluster/                # Production Kubernetes environment
    ├── ansible.cfg            # Ansible configuration
    ├── files/                 # SSH keys and other static files
    ├── inventories/           # Environment-specific inventories
    │   └── prod/              # Production environment
    ├── kube-apps/             # Kubernetes applications
    │   ├── applications/      # Individual Argo CD Applications
    │   ├── applicationsets/   # Argo CD ApplicationSets
    │   ├── charts/           # Helm charts (vendored)
    │   ├── manifests/        # Raw Kubernetes manifests
    │   └── values/           # Helm chart values
    ├── playbooks/            # Ansible playbooks
    ├── roles/                # Ansible roles
    └── vendor-charts.sh      # Script for vendoring Helm charts

## Evolution and Scaling

This architecture supports horizontal scaling by adding additional Raspberry Pi nodes to the cluster, with the underlying K3s and MetalLB handling the orchestration and load balancing. The GitOps approach ensures consistency across all environments and simplified operational management.

The system is designed to be resilient, with Longhorn providing distributed storage, replicated across nodes, ensuring data persists even if a node fails.

## Future Architecture Plans

The architecture is being extended to include:
- **Service Mesh & API Gateway**: Migration to Kubernetes Gateway API and Istio for advanced traffic management, security, and observability
- Enhanced observability with Prometheus/Grafana dashboards
- Additional home services like Pi-hole, media servers
- Database services with PostgreSQL and operator-based management
- Integration with external cloud services where appropriate

---

*Last updated: May 2025*