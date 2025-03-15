# Welcome
This is my Management Kubernetes Cluster in my Homelab.

I have two additional Kubernetes clusters running in my 3-node Proxmox environment. These clusters are managed by the Management Cluster described in this repository.

In this cluster, I have only documented Rancher, Jenkins, and my private GitLab instance, which are automatically deployed using FluxCD. The other clusters are also managed via FluxCD, but they use the GitLab instance from this Management Cluster as their repository.

If you're interested in how I set this up in detail, feel free to reach out to me. I don’t share this information voluntarily 😉.