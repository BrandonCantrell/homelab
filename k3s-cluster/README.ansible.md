# README.ansible.md

# Ansible Automation for Raspberry Pi 5 Cluster Setup

This repository contains Ansible playbooks and roles for preparing Raspberry Pi 5 nodes to run a K3s Kubernetes cluster. It automates the initial setup of users, SSH, system updates, kernel flags, and other prerequisites needed before installing K3s.

> **Note:** This setup is written specifically for my own homelab implementation and is not intended as a general-purpose or reusable solution without modification. Assumptions about usernames, SSH keys, and host setup may not apply to your environment.

## Features

- SSH-based provisioning using a dedicated `ansible` user
- System updates and package installation
- Swap disablement and cgroup setup for Kubernetes
- Hostname assignment
- SSH public key injection
- Custom role: `pi_system_prep`

## Requirements

- Raspberry Pi 5 running **Ubuntu 22.04 Server (64-bit)**
- SSH access to each Pi using an initial user (e.g., `pi`, `ubuntu`, or a user created during setup)
- Public key saved at `files/ansible.pub`
- Control machine with:
  - Ansible 2.12+
  - Python 3.8+

> **First Run Note:** The `bootstrap.yml` playbook must be run as the Pi's initial default user, which will not yet have the `ansible` user or SSH key installed. In my case, this is the `bcant` user. You should replace it with the correct initial username for your device (commonly `pi`, `ubuntu`, etc.).

Install required roles:

```bash
ansible-galaxy install -r requirements.yml
```

## Directory Overview

```
k3s-cluster/
├── inventories/
│   └── prod/
│       ├── inventory.yml
│       └── group_vars/
├── playbooks/
│   ├── bootstrap.yml
│   └── site.yml
├── roles/
│   └── pi_system_prep/
├── files/
│   └── ansible.pub
```

## Usage

### Bootstrap Raspberry Pi Nodes

This configures users, SSH access, hostnames, swap, and system packages:

```bash
ansible-playbook -u <initial-user> playbooks/bootstrap.yml --ask-become-pass
```

Use `site.yml` to run the full flow including K3s install:

```bash
ansible-playbook playbooks/site.yml --ask-become-pass
```

## Customization

- Modify `inventories/prod/inventory.yml` to define your nodes
- Adjust system prep behavior in `roles/pi_system_prep/tasks/main.yml`
- SSH public key must be stored in `files/ansible.pub`

## Security Notes

- Do **not** commit private SSH keys
- Use `ansible-vault` for any secrets