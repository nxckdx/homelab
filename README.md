# 🏡 Homelab: Management Kubernetes Cluster
Welcome to my Homelab project!

This repository documents my **Management Kubernetes Cluster**, which runs on a 3-node Proxmox environment (`pve`, `carlos` and `jochen`).

This Management Cluster controls two additional Kubernetes clusters and automatically deploys essential infrastructure components usind **FluxCD**, including:
- **Rancher**
- **Jenkins**
- **Infisical**
- **Prometheus**
- **Grafana**
- **Loki**
- **Harbor**
- **Authentik**
- **Gitea**

The other clusters are also managed by **FluxCD**, using the **Gitea instance from this Management Cluster** as their repository. 

Feel free to reach out if you're curious about the details or want to replicate something similar in your own setup. 😉

## 🧱 Architecture Overview
The entire setup is fully automated and built in **four** main steps:
1. **Packer** creates a base **Ubuntu 24.04** image template.
2. **Terraform** provisions VMs using that image.
3. **Kubespray** (via Docker) bootstraps the Kubernetes Cluster.
4. **Ansible** installs **Cilium** and **FluxCD** into the cluster, along with custom playbooks.

All of this orchestrated using a single `terragrunt.hcl` file that wraps and coordinates each tool.

## 🧰 Requirements
Make sure the following tools are installed:
- **Packer**
- **Terraform**
- **Terragrunt**
- **Ansible**
- **Kubectl**
- **Docker**
- **SOPS**
- **age**

## 🧩 Configuration
This project uses multiple `variables*.yaml` files to manage configurations for different stages and cluster types. These variable files are loaded dynamically using the `TERRAGRUNT_VARFILE` environment variable.

### Available Variable Files
- `variables-vm_template.yaml` 
  - Contains configurations for the **Ubuntu 24.04 VM template**
- `variables.yaml`
  - The **default variable file**, used when no custom file is specified. Defines the **Management Cluster** and its core components.
- `variables.*.yaml`
  - Additional files (e.g. `variables-private-cluster.yaml`, `variables-public-cluster.yaml`, etc.) define other clusters and are used when explicity passed via `TERRAGRUNT_VARFILE`.

### Switching Variable Files
If you want to deployor manage a different cluster, use the corresponding variable file and **reinitialize** Terragrunt before applying:
```bash
TERRAGRUNT_VARFILE=variables-private-cluster.yaml terragrunt init -reconfigure
TERRAGRUNT_VARFILE=variables-private-cluster.yaml terragrunt plan
TERRAGRUNT_VARFILE=variables-private-cluster.yaml terragrunt apply -auto-approve
```
If no `TERRAGRUNT_VARFILE` is specified, the default `variables.yaml` will be used automatically.

## 🔐 Secrets
Secrets are stored in an encrypted `secret.yaml` file and decrypted using `ansible-vault`.

A `.vault_pass` file is required for decryption.

Example `secret.yaml` structure:
```yaml
proxmox_api:
  url: "https://carlos.local.nickdann.net:8006/api2/json"
  token_id: "root@pam!packer"
  token_secret: "secret"

age:
  private: private
  public: public
```

## 🚀 Deploying the Cluster
To start the full deployment process, simply run:
```bash
terragrunt apply -auto-approve
```
Or, when using a custom variable file:
```bash
TERRAGRUNT_VARFILE=variables-private-cluster.yaml terragrunt init -reconfigure
TERRAGRUNT_VARFILE=variables-private-cluster.yaml terragrunt apply -auto-approve
```