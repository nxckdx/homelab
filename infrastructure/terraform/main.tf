terraform {
  required_version = ">= 1.10.4"

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc6"
    }
    ansible = {
      source = "ansible/ansible"
      version = "1.3.0"
    }
  }
}

locals {
  vm_map = { for vm_instance in var.vm : vm_instance.name => vm_instance }

  # Kubernetes Cluster Mapping in eine flache Liste umwandeln
  cluster_map = flatten([
    for cluster in var.kubernetes.cluster : [
      for role, hosts in cluster.nodes : [
        for host in hosts : {
          name  = host
          group = role
        }
      ]
    ]
  ])
}

resource "proxmox_vm_qemu" "vm" {
    for_each = local.vm_map

    name        = each.value.name
    target_node = each.value.node
    clone_id    = var.vm_template
    agent       = 1
    qemu_os     = "l26"
    memory      = each.value.memory
    cores       = each.value.cpu.cores
    sockets     = each.value.cpu.sockets
    cpu_type    = each.value.cpu.type
    vmid        = each.value.vmid
    bios        = "seabios"
    tags        = each.value.tags
    scsihw      = "virtio-scsi-pci"

    network {
        id      = 0
        bridge  = each.value.network.bridge
        model   = "virtio"
    }

    disks {
        ide {
            ide3 {
                cloudinit {
                    storage = each.value.disk.storage
                }
            }
        }
        scsi {
            scsi0 {
                disk {
                    backup = true
                    storage = each.value.disk.storage
                    size    = each.value.disk.size
                    emulatessd=true
                    discard = true
                    cache = "none"
                    replicate = false
                }
            }
        }
    }

    os_type     = "cloud-init"
    ipconfig0   = "ip=${each.value.network.ip},gw=${each.value.network.gateway}"
    nameserver  = each.value.network.nameserver
    searchdomain= each.value.network.searchdomain

    skip_ipv6   = true
}

resource "ansible_host" "host" {
  for_each = { for entry in local.cluster_map : entry.name => entry }

  name   = each.value.name
  groups = [each.value.group]

  variables = {
    ansible_user = "nick"
    ansible_host = split("/", local.vm_map[each.value.name].network.ip)[0]
    ansible_ssh_common_args = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  }
}