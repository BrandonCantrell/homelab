# Infrastructure Management with Ansible

This directory contains Ansible playbooks for managing the homelab infrastructure, including system preparation, user management, and K3s cluster deployment.

## Playbook Overview

### **Core Playbooks**

| Playbook | Purpose | Target Hosts |
|----------|---------|--------------|
| `bootstrap.yml` | Complete cluster bootstrap from scratch | `k3s_cluster` |
| `install_k3s.yml` | K3s installation and configuration | `k3s_cluster` |
| `users.yml` | User account and SSH key management | `all` |
| `site.yml` | Complete site deployment (runs all playbooks) | `all` |

### **Utility Playbooks**

| Playbook | Purpose | Usage |
|----------|---------|-------|
| `debug.yml` | System information gathering and debugging | As needed |

## Inventory Structure

```
inventories/prod/
├── inventory.yml          # Host definitions and groups
└── group_vars/
    └── all.yml           # Variables for all hosts
```

### **Host Groups**
- **`k3s_cluster`**: All Kubernetes nodes
- **`master`**: Control plane nodes (pi5-1)
- **`worker`**: Worker nodes (pi5-2)

## Ansible Roles

### **`pi_system_prep`**
Prepares Raspberry Pi systems for K3s deployment.

**Tasks:**
- Configure cgroups for container runtime
- Set up swap configuration
- Install required system packages
- Configure system optimizations
- Set up log rotation

### **`users`**
Manages user accounts and SSH access.

**Tasks:**
- Create user accounts
- Deploy SSH public keys
- Configure sudo access
- Set up user environment

## Usage Examples

### **Complete Infrastructure Bootstrap**
```bash
# Deploy entire infrastructure from scratch
ansible-playbook -i inventories/prod playbooks/site.yml

# Or use the bootstrap playbook specifically
ansible-playbook -i inventories/prod playbooks/bootstrap.yml
```

### **K3s Cluster Management**
```bash
# Install/upgrade K3s cluster
ansible-playbook -i inventories/prod playbooks/install_k3s.yml

# Install K3s on specific nodes
ansible-playbook -i inventories/prod playbooks/install_k3s.yml --limit pi5-1

# Dry run (check mode)
ansible-playbook -i inventories/prod playbooks/install_k3s.yml --check
```

### **User Management**
```bash
# Update user accounts and SSH keys
ansible-playbook -i inventories/prod playbooks/users.yml

# Add new user to specific host
ansible-playbook -i inventories/prod playbooks/users.yml --limit pi5-1
```

### **System Debugging**
```bash
# Gather system information
ansible-playbook -i inventories/prod playbooks/debug.yml

# Debug specific host
ansible-playbook -i inventories/prod playbooks/debug.yml --limit pi5-2
```

## Configuration Management

### **Key Variables** (`group_vars/all.yml`)

#### **K3s Configuration**
```yaml
k3s_version: "v1.32.3+k3s1"
k3s_server_location: "/usr/local/bin/k3s"
systemd_dir: "/etc/systemd/system"
k3s_server_ip: "192.168.4.10"  # pi5-1 control plane
```

#### **Network Configuration**
```yaml
# MetalLB configuration
metallb_ip_range: "192.168.4.20-192.168.4.30"

# Node IP addresses
k3s_node_ip:
  pi5-1: "192.168.4.10"
  pi5-2: "192.168.4.11"
```

#### **Storage Configuration**
```yaml
# Longhorn storage settings
longhorn_default_replica_count: 1  # Due to 2-node limitation
longhorn_storage_path: "/opt/longhorn"
```

### **Host-Specific Variables**
```yaml
# In inventory.yml
all:
  children:
    k3s_cluster:
      children:
        master:
          hosts:
            pi5-1:
              ansible_host: 192.168.4.10
              k3s_control_node: true
        worker:
          hosts:
            pi5-2:
              ansible_host: 192.168.4.11
              k3s_control_node: false
```

## Detailed Playbook Descriptions

### **`bootstrap.yml` - Complete Bootstrap**

**Purpose:** Full infrastructure deployment from bare Raspberry Pi OS

**Flow:**
1. System preparation (`pi_system_prep` role)
2. User management (`users` role)  
3. K3s installation (`install_k3s.yml`)
4. ArgoCD deployment
5. Initial application deployment

**When to use:** 
- New cluster deployment
- Disaster recovery
- Complete infrastructure rebuild

### **`install_k3s.yml` - K3s Management**

**Purpose:** K3s cluster installation and configuration

**Tasks:**
- Download and install K3s binary
- Configure systemd service
- Set up kubeconfig
- Join worker nodes to cluster
- Configure cluster networking
- Install ArgoCD

**When to use:**
- Initial K3s deployment
- K3s version upgrades
- Cluster configuration changes
- Adding/removing nodes

### **`users.yml` - User Management**

**Purpose:** User account and SSH key management

**Tasks:**
- Create system users
- Deploy SSH public keys
- Configure sudo permissions
- Set up shell environment

**When to use:**
- Adding new users
- Updating SSH keys
- Changing user permissions
- Regular security maintenance

### **`site.yml` - Complete Site Deployment**

**Purpose:** Execute all playbooks in correct order

**Flow:**
1. User management
2. System preparation  
3. K3s installation
4. Verification tasks

**When to use:**
- Complete infrastructure deployment
- Regular maintenance runs
- Ensuring consistent configuration

## Prerequisites

### **Control Machine Requirements**
```bash
# Install Ansible
pip install ansible

# Install required collections
ansible-galaxy collection install kubernetes.core
ansible-galaxy collection install community.general
```

### **Target Host Requirements**
- Raspberry Pi OS (64-bit recommended)
- SSH access configured
- User with sudo privileges
- Python3 installed

### **SSH Key Setup**
```bash
# Generate SSH key pair (if not exists)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy public key to files/
cp ~/.ssh/id_ed25519.pub files/your_username.pub

# Update users role configuration
# Edit roles/users/vars/main.yml
```

## Troubleshooting

### **Common Issues**

#### **SSH Connection Problems**
```bash
# Test SSH connectivity
ansible all -i inventories/prod -m ping

# Check SSH key authentication
ssh -v pi@192.168.4.10

# Update SSH known_hosts if needed
ssh-keyscan 192.168.4.10 >> ~/.ssh/known_hosts
```

#### **K3s Installation Failures**
```bash
# Check if K3s is already running
ansible k3s_cluster -i inventories/prod -m shell -a "systemctl status k3s"

# Clean up failed installation
ansible k3s_cluster -i inventories/prod -m shell -a "/usr/local/bin/k3s-uninstall.sh"

# Reinstall from scratch
ansible-playbook -i inventories/prod playbooks/install_k3s.yml
```

#### **Permission Errors**
```bash
# Check sudo access
ansible all -i inventories/prod -m shell -a "sudo whoami" --become

# Update user permissions
ansible-playbook -i inventories/prod playbooks/users.yml
```

#### **Disk Space Issues**
```bash
# Check disk usage on all nodes
ansible k3s_cluster -i inventories/prod -m shell -a "df -h"

# Clean up Docker images
ansible k3s_cluster -i inventories/prod -m shell -a "k3s crictl rmi --prune"
```

### **Debugging Playbook Execution**
```bash
# Run with verbose output
ansible-playbook -i inventories/prod playbooks/install_k3s.yml -v

# Use debug mode
ansible-playbook -i inventories/prod playbooks/install_k3s.yml --step

# Check specific task
ansible-playbook -i inventories/prod playbooks/install_k3s.yml --start-at-task "Install K3s"
```

## Maintenance Procedures

### **Regular Maintenance Tasks**
```bash
# Weekly: Update system packages
ansible k3s_cluster -i inventories/prod -m apt -a "upgrade=yes update_cache=yes" --become

# Monthly: Run complete site playbook
ansible-playbook -i inventories/prod playbooks/site.yml

# As needed: Update SSH keys
ansible-playbook -i inventories/prod playbooks/users.yml
```

### **K3s Updates**
```bash
# Update K3s version in group_vars/all.yml
# k3s_version: "v1.32.4+k3s1"

# Apply update
ansible-playbook -i inventories/prod playbooks/install_k3s.yml

# Verify cluster health
kubectl get nodes
kubectl get pods --all-namespaces
```

### **Node Addition**
```bash
# Add new node to inventory.yml
# Update group_vars if needed

# Bootstrap new node
ansible-playbook -i inventories/prod playbooks/bootstrap.yml --limit new-node

# Verify cluster membership
kubectl get nodes
```

### **Backup Procedures**
```bash
# Backup critical configurations
ansible k3s_cluster -i inventories/prod -m fetch \
  -a "src=/etc/rancher/k3s/k3s.yaml dest=./backups/"

# Backup etcd (if using embedded etcd)
ansible master -i inventories/prod -m shell \
  -a "k3s etcd-snapshot save /tmp/snapshot-$(date +%Y%m%d-%H%M%S).db"
```

## Security Considerations

### **Access Control**
- Use SSH key authentication (disable password auth)
- Regular SSH key rotation
- Principle of least privilege for user accounts
- Regular security updates via Ansible

### **Network Security**
- Configure firewall rules if needed
- Use VPN for remote access to cluster
- Regular security scanning of nodes

### **Secrets Management**
- Never commit sensitive data to Git
- Use Ansible Vault for secrets
- Regular password/key rotation
- Monitor for exposed credentials

## Advanced Usage

### **Ansible Vault**
```bash
# Encrypt sensitive variables
ansible-vault encrypt group_vars/all.yml

# Run playbook with vault password
ansible-playbook -i inventories/prod playbooks/site.yml --ask-vault-pass

# Use vault password file
ansible-playbook -i inventories/prod playbooks/site.yml --vault-password-file .vault_pass
```

### **Custom Roles**
```bash
# Create new role
ansible-galaxy init roles/my_custom_role

# Use role in playbook
- hosts: all
  roles:
    - my_custom_role
```

### **Tags and Limits**
```bash
# Run specific tagged tasks
ansible-playbook -i inventories/prod playbooks/site.yml --tags "k3s,users"

# Skip specific tags
ansible-playbook -i inventories/prod playbooks/site.yml --skip-tags "slow_tasks"

# Run on specific hosts
ansible-playbook -i inventories/prod playbooks/site.yml --limit "pi5-1,pi5-2"
```

---

*For cluster operations after deployment, see [../README.md](../README.md)*
*For application management, see [../kube-apps/README.md](../kube-apps/README.md)*