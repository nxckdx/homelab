FROM mcr.microsoft.com/devcontainers/python:1-3.12-bullseye

RUN apt-get update -y && \
    apt-get install -y gnupg software-properties-common curl wget ca-certificates sudo apt-transport-https

# Python Apps
RUN pip install --upgrade pip && \
    pip install ansible-lint

# Install Terraform and Packer
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update -y && \
    apt-get install -y terraform packer

# Install Terragrunt
RUN wget "https://github.com/gruntwork-io/terragrunt/releases/download/v0.76.3/terragrunt_linux_amd64" -O /usr/local/bin/terragrunt && \
    chmod +x /usr/local/bin/terragrunt

# Install age
RUN apt-get install -y age

# Install sops
RUN curl -LO https://github.com/getsops/sops/releases/download/v3.9.4/sops-v3.9.4.linux.amd64 && \
    mv sops-v3.9.4.linux.amd64 /usr/local/bin/sops && \
    chmod +x /usr/local/bin/sops

# Install Ansible
# RUN wget -O- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg && \
#     echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu jammy main" > /etc/apt/sources.list.d/ansible.list && \
#     apt-get update -y && \
#     apt-get install -y ansible
RUN pip install ansible

# Install Kubectl
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' > /etc/apt/sources.list.d/kubernetes.list && \
    chmod 644 /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update -y && \
    apt-get install -y kubectl