# **Welcome**
This is my **Management Kubernetes Cluster** running in my homelab.  

I have two additional Kubernetes clusters running in my **3-node Proxmox environment** (the nodes are called `pve`, `carlos`, and `jochen`). These clusters are managed by the **Management Cluster** described in this repository.

In this cluster, I have documented only **Rancher, Jenkins, Infisical, Prometheus, Grafana, Harbor, Authentik and my private Gitea instance**, which are automatically deployed using **FluxCD**. The other clusters are also managed via **FluxCD**, but they use the **Gitea instance from this Management Cluster** as their repository.

If you're interested in the **detailed setup**, feel free to reach out to me 😉.

This setup consists of **four main steps**:  
1. **Packer** creates an **Ubuntu 24.04** template.  
2. **Terraform** provisions additional VMs from that template.  
3. **Docker** sets up the Kubernetes cluster with the help of kubespray.
4. **Ansible** sets up FluxCD in the Kubernetes Cluster.

---

> [!NOTE]  
> You can set variables for Kubespray through the **variables.yaml**  

---

# **Requirements**  
You need to install the following packages for this project:  
- **Packer**  
- **Terraform**  
- **Ansible**  
- **Terragrunt** 
- **Kubectl**
- **SOPS**  
- **age**  
- **Docker**

Make sure to review all the configuration files, including **`terragrunt.hcl`**.  

You will also need an **encrypted `secret.yaml`** along with a **`.vault_pass`** file.  

The **`secret.yaml`** must include the API credentials for your Proxmox environment and your age-keys:  

```yaml
proxmox_api:
    url: "https://carlos.local.nickdann.net:8006/api2/json"
    token_id: "root@pam!packer"
    token_secret: "secret"

age:
  private: private
  public: public
```

Additionally, review the **`variables.yaml`** file for necessary configurations.

---

# **Start the Deployment**
```bash
terragrunt apply auto-approve
```