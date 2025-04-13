locals {
  varfile = get_env("TERRAGRUNT_VARFILE", "variables.yaml")
  
  # YAML-Datei einlesen
  config = yamldecode(file("${get_repo_root()}/${local.varfile}"))
  vm_template = yamldecode(file("${get_repo_root()}/variables-vm_template.yaml"))
  secret = yamldecode(run_cmd("/bin/bash", "-c", "ansible-vault view ${get_repo_root()}/secret.yaml --vault-password-file ${get_repo_root()}/.vault_pass"))
}

remote_state {
  backend = "local"
  config = {
    path = "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/${local.config.name}/terraform.tfstate"
  }

  generate = {
    path = "backend.tf"
    if_exists = "overwrite"
  }
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
packer init ${get_repo_root()}/infrastructure/packer/proxmox-ubuntu2404/
  
packer build \
-var "proxmox_api_url=${local.secret.proxmox_api.url}" \
-var "proxmox_api_token_id=${local.secret.proxmox_api.token_id}" \
-var "proxmox_api_token_secret=${local.secret.proxmox_api.token_secret}" \
-var "template_name=${local.vm_template.name}" \
-var "proxmox_node=${local.vm_template.node}" \
-var "vmid=${local.vm_template.vmid}" \
-var "tags=${local.vm_template.tags}" \
-var "template_description=${local.vm_template.description}" \
${get_repo_root()}/infrastructure/packer/proxmox-ubuntu2404/ubuntu-24.04.pkr.hcl || true
EOT
    ]
  }

  after_hook "after" {
    commands = ["apply"]
    execute  = [
      "/bin/bash", "-c", <<-EOT
echo '${yamlencode(local.config.kubespray_extra_vars)}' > ${get_working_dir()}/inventory/extra_vars.yaml

sudo docker run --rm --mount type=bind,source=${get_working_dir()}/inventory,dst=/inventory \
--mount type=bind,source=/home/$(whoami)/.ssh/id_ed25519,dst=/root/.ssh/id_ed25519 \
quay.io/kubespray/kubespray:v2.27.0 \
ansible-playbook -i /inventory/inventory.ini --private-key /root/.ssh/id_ed25519 cluster.yml --extra-vars "@/inventory/extra_vars.yaml" --become --become-user=root

echo '${yamlencode(local.config.cilium)}' > ${get_repo_root()}/cilium-values.yaml
echo '${yamlencode(local.config.flux)}' > ${get_repo_root()}/flux-values.yaml

ansible-playbook -i ${get_working_dir()}/inventory/inventory.ini ${get_repo_root()}/ansible-k8s/playbook.yaml --vault-password-file ${get_repo_root()}/.vault_pass

kubectl --kubeconfig ${get_repo_root()}/kubeconfig get node -o custom-columns='NAME:.metadata.name' --no-headers | while read line; do 
  kubectl --kubeconfig ${get_repo_root()}/kubeconfig label node $line node.kubernetes.io/exclude-from-external-load-balancers-
done

if [[ '${local.config.kubespray_extra_vars.kube_vip_enabled}' == 'true' ]]; then
  sed -i 's+server:.*+server: https://${local.config.kubespray_extra_vars.kube_vip_address}:6443+g' ${get_repo_root()}/kubeconfig
fi
EOT
    ]
  }

  source = "${get_repo_root()}/infrastructure/terraform"
}

inputs = {
  proxmox_api_url = local.secret.proxmox_api.url
  proxmox_api_token_id = local.secret.proxmox_api.token_id
  proxmox_api_token_secret = local.secret.proxmox_api.token_secret

  vm_template = local.vm_template.vmid
  vm = local.config.vm
}
