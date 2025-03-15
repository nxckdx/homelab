variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type      = string
  sensitive = true
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "vm_template" {
  type = number
}

variable "vm" {
  type = list(object({
    vmid = number
    name = string
    cpu = object({
      cores = number
      sockets = number
      type = string
    })
    memory = number
    tags = string
    node = string
    disk = object({
      storage = string
      size = string
    })
    network = object({
      bridge = string
      ip = string
      gateway = string
      nameserver = string
      searchdomain = string
    })
  }))
}

variable "kubernetes" {
  type = object({
    cluster = list(object({
      name  = string
      nodes = map(list(string))
    }))
  })
}