# Ubuntu Server Noble Numbat
# ---
# Packer Template to create an Ubuntu Server 24.04 LTS (Noble Numbat) on Proxmox

# Resource Definiation for the VM Template

packer {
  required_plugins {
    name = {
      version = "1.2.1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "template_name" {
  type = string
}

variable "proxmox_node" {
  type = string
}

variable "vmid" {
  type = string
}

variable "tags" {
  type = string
}

variable "template_description" {
  type = string
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type = string
  sensitive = true
}

source "proxmox-iso" "ubuntu-server-noble-numbat" {
 
    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"

    # (Optional) Skip TLS Verification
    insecure_skip_tls_verify = true
    
    # VM General Settings
    node = "${var.proxmox_node}"
    vm_id = "${var.vmid}"
    vm_name = "ubuntu-server-noble-numbat"
    template_description = "${var.template_description}"
    tags = "${var.tags}"

    boot_iso {
        # VM OS Settings
        # (Option 1) Local ISO File
        # iso_file = "local:iso/ubuntu-24.04.2-live-server-amd64.iso"
        # - or -
        # (Option 2) Download ISO
        iso_url = "https://ftp.halifax.rwth-aachen.de/ubuntu-releases/noble/ubuntu-24.04.2-live-server-amd64.iso"
        iso_checksum = "d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
        iso_storage_pool = "local"
        iso_download_pve = true
        unmount = true
    }

    template_name        = "${var.template_name}"

    # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-single"

    disks {
        disk_size = "32G"
        format = "raw"
        storage_pool = "ssd"
        type = "scsi"
    }

    # VM CPU Settings
    cores = "1"
    cpu_type = "x86-64-v2-AES"
    
    # VM Memory Settings
    memory = "2048" 

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "false"
    } 

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "ssd"

    # PACKER Boot Commands
    boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",
        "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
        "<f10><wait>"
    ]
    boot = "c"
    boot_wait = "10s"
    communicator = "ssh"

    # PACKER Autoinstall Settings
    http_directory = "${path.root}/http" 
    #http_bind_address = "10.1.149.166"
    # (Optional) Bind IP Address and Port
    # http_port_min = 8802
    # http_port_max = 8802

    ssh_username = "nick"

    # (Option 1) Add your Password here
    # ssh_password = "ubuntu"
    # - or -
    # (Option 2) Add your Private SSH KEY file here
    ssh_private_key_file = "~/.ssh/id_ed25519"

    # Raise the timeout, when installation takes longer
    ssh_timeout = "20m"
    ssh_pty = true
}

# Build Definition to create the VM Template
build {

    name = "ubuntu-server-noble-numbat"
    sources = ["proxmox-iso.ubuntu-server-noble-numbat"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt update -y",
            "sudo apt upgrade -y",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo rm -f /etc/netplan/00-installer-config.yaml",
            "sudo sync"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        source = "${path.root}/files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }

}
