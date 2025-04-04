locals {
  # YAML-Datei einlesen
  config = yamldecode(file("${get_repo_root()}/variables.yaml"))
  secret = yamldecode(run_cmd("/bin/bash", "-c", "ansible-vault view ${get_repo_root()}/secret.yaml --vault-password-file ${get_repo_root()}/.vault_pass"))
}

terraform {
  before_hook "requirements" {
    commands = ["init", "apply"]
    execute  = [
      "/bin/bash", "-c", <<-EOT
mkdir -p ${get_working_dir()}/inventory
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
echo '${yamlencode(local.config.kubespray_extra_vars)}' > ${get_working_dir()}/inventory/extra_vars.yaml

sudo docker run --rm --mount type=bind,source=${get_working_dir()}/inventory,dst=/inventory \
--mount type=bind,source=/home/$(whoami)/.ssh/id_ed25519,dst=/root/.ssh/id_ed25519 \
quay.io/kubespray/kubespray:v2.27.0 \
ansible-playbook -i /inventory/inventory.ini --private-key /root/.ssh/id_ed25519 cluster.yml --extra-vars "@/inventory/extra_vars.yaml" --become --become-user=root

ansible-playbook -i ${get_working_dir()}/inventory/inventory.ini ${get_repo_root()}/ansible-k8s/playbook.yaml --vault-password-file ${get_repo_root()}/.vault_pass
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
}