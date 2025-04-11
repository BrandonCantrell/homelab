# Ansible K3s Cluster (Prod) — Raspberry Pi 5

This repository provisions and configures a **production-ready** [K3s](https://k3s.io) Kubernetes cluster using **Ansible** on **Raspberry Pi 5** devices running **Ubuntu 22.04 Server**.

It includes:
- Bootstrap playbooks to set up the system, users, and packages
- A dedicated role to prepare Raspberry Pi for Kubernetes (`pi_system_prep`)
- K3s installation using the [xanmanning.k3s](https://galaxy.ansible.com/xanmanning/k3s) role
- Clean YAML-based inventory for environment management

---

## 📦 Requirements

- Raspberry Pi 5 running Ubuntu 22.04 Server (64-bit)
- SSH access with a privileged `ansible` user (created via bootstrap)
- Your public key saved as `files/ansible.pub`
- Ansible 2.12+ installed on your control machine (Linux/macOS/WSL)
- Python 3.8+ on your control machine

Install the required Ansible Galaxy roles:

```bash
ansible-galaxy install -r requirements.yml
```

---

## 📁 Directory Structure

```
ansible-k3s/
├── inventories/
│   └── prod/
│       ├── inventory.yml
│       └── group_vars/
│           └── all.yml
├── playbooks/
│   ├── bootstrap.yml
│   ├── install_k3s.yml
│   └── site.yml
├── roles/
│   └── pi_system_prep/     # System tuning for Pi
│       ├── tasks/
│       └── handlers/
├── files/
│   └── ansible.pub
├── requirements.yml
├── ansible.cfg
└── README.md
```

---

## 🧪 How to Use

### 1. Bootstrap the Raspberry Pi Nodes

This step:
- Creates an `ansible` user
- Installs system updates and core packages
- Configures `cmdline.txt` with cgroup flags
- Disables swap
- Sets the hostname
- Adds your SSH key

Run:

```bash
ansible-playbook playbooks/bootstrap.yml --ask-become-pass
```

You can then SSH into a node like this:

```bash
ssh ansible@<raspberry-pi-ip>
```

### 2. Install the K3s Cluster

This sets up K3s on the master and agent Pi nodes:

```bash
ansible-playbook playbooks/install_k3s.yml
```

### 3. Run the Full Flow (Bootstrap + K3s)

```bash
ansible-playbook playbooks/site.yml --ask-become-pass
```

---

## 🔧 Customization

Edit these files to configure your setup:

- `inventories/prod/inventory.yml` — define your Raspberry Pi hostnames and IPs
- `inventories/prod/group_vars/all.yml` — tweak K3s options like disabling Traefik, setting TLS SANs, etc.
- `roles/pi_system_prep/tasks/main.yml` — modify Raspberry Pi system prep logic if needed

---

## 🧹 Uninstall K3s (Optional)

To uninstall K3s manually from a Pi node:

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

For agent nodes, use:

```bash
sudo /usr/local/bin/k3s-agent-uninstall.sh
```

You can also write a teardown playbook if needed.

---

## 🚨 Raspberry Pi-Specific Notes

- Use **64-bit Ubuntu 22.04 Server**, not the desktop edition.
- Ensure your image is flashed to a reliable **SSD** (recommended over SD card).
- Static IPs or DHCP reservations are strongly recommended.
- SSH key-based login is required — the bootstrap process installs your public key into the `ansible` user account.

---

## 🔐 Security Notes

- Do **not** commit your private SSH keys.
- Only include the public key in `files/ansible.pub`.
- Consider using `ansible-vault` for any secrets or credentials.

---

## 📚 References

- [K3s Documentation](https://docs.k3s.io)
- [Ansible Galaxy Role: xanmanning.k3s](https://galaxy.ansible.com/xanmanning/k3s)
- [Raspberry Pi 5 Documentation](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html)

---

Happy clustering with Raspberry Pi! 🥧🚀
