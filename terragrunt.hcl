locals {
  # YAML-Datei einlesen
  config = yamldecode(file("${get_repo_root()}/variables.yaml"))
  secret = yamldecode(run_cmd("/bin/bash", "-c", "ansible-vault view ${get_repo_root()}/secret.yaml --vault-password-file ${get_repo_root()}/.vault_pass"))
}

terraform {
  before_hook "install_ansible_requirements" {
    commands = ["init", "apply"]
    execute  = [
      "/bin/bash", "-c", <<-EOT
ansible-galaxy collection install cloud.terraform
EOT
    ]
  }

  before_hook "run_packer" {
    commands = ["init", "apply"]
    execute  = [
      "/bin/bash", "-c", <<-EOT
packer build \
-var "proxmox_api_url=${local.secret.proxmox_api.url}" \
-var "proxmox_api_token_id=${local.secret.proxmox_api.token_id}" \
-var "proxmox_api_token_secret=${local.secret.proxmox_api.token_secret}" \
-var "template_name=${local.config.vm_template.name}" \
-var "proxmox_node=${local.config.vm_template.node}" \
-var "vmid=${local.config.vm_template.vmid}" \
-var "tags=${local.config.vm_template.tags}" \
-var "template_description=${local.config.vm_template.description}" \
${get_repo_root()}/infrastructure/packer/proxmox-ubuntu2404/ubuntu-24.04.pkr.hcl || true
EOT
    ]
  }

  after_hook "ansible" {
    commands = ["apply"]
    execute  = [
      "/bin/bash", "-c", <<-EOT
echo 'plugin: cloud.terraform.terraform_provider' > ${get_working_dir()}/inventory.yaml
ansible-inventory -i ${get_working_dir()}/inventory.yaml --list

ansible-playbook -i ${get_working_dir()}/inventory.yaml ${get_repo_root()}/ansible-k8s/playbook.yaml
EOT
    ]
  }

  source = "${get_repo_root()}/infrastructure/terraform"
}

inputs = {
  proxmox_api_url = local.secret.proxmox_api.url
  proxmox_api_token_id = local.secret.proxmox_api.token_id
  proxmox_api_token_secret = local.secret.proxmox_api.token_secret

  vm_template = local.config.vm_template.vmid
  vm = local.config.vm
  kubernetes = local.config.kubernetes
}