# README.k3s.md

# K3s Kubernetes Cluster on Raspberry Pi 5

This setup uses Ansible to install and configure [K3s](https://k3s.io) on Raspberry Pi 5 devices. It supports single-node or multi-node clusters and is compatible with GitOps workflows using Argo CD and Helm.

## Features

- Lightweight Kubernetes using K3s
- Server and agent role assignment via Ansible inventory
- Uses the `xanmanning.k3s` Ansible role
- Compatible with MetalLB, Longhorn, Argo CD, and other GitOps tools

## Requirements

- Raspberry Pi 5 nodes with Ubuntu 22.04 Server (64-bit)
- Bootstrap completed (via Ansible)
- Static IPs or DHCP reservations recommended
- SSH access to each node

## Installation

Install K3s using:

```bash
ansible-playbook playbooks/install_k3s.yml
```

Or run full setup including system prep:

```bash
ansible-playbook playbooks/site.yml --ask-become-pass
```

## Configuration

- Define nodes in: `inventories/prod/inventory.yml`
- Configure K3s options in: `inventories/prod/group_vars/all.yml`
  - Disable Traefik
  - Set TLS SANs
  - Enable or disable agent-only nodes

## Uninstall

To remove K3s:

```bash
sudo /usr/local/bin/k3s-uninstall.sh        # On server
sudo /usr/local/bin/k3s-agent-uninstall.sh  # On agent
```

## Additional Tools

This setup is compatible with:

- [MetalLB](https://metallb.universe.tf) for LoadBalancer services
- [Longhorn](https://longhorn.io) for persistent storage
- [Argo CD](https://argo-cd.readthedocs.io) for GitOps deployments
- [Helm](https://helm.sh) for package management

Install and manage these via Argo CD and community Helm charts.

## References

- [K3s Documentation](https://docs.k3s.io)
- [xanmanning.k3s Role](https://galaxy.ansible.com/xanmanning/k3s)
