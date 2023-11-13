variable "name" {
  description = "Name to give to the vm."
  type        = string
}

variable "network_port" {
  description = "Network port to assign to the node. Should be of type openstack_networking_port_v2"
  type        = any
}

variable "server_group" {
  description = "Server group to assign to the node. Should be of type openstack_compute_servergroup_v2"
  type        = any
}

variable "image_source" {
  description = "Source of the vm's image"
  type = object({
    image_id  = string
    volume_id = string
  })

  validation {
    condition     = (var.image_source.image_id != "" && var.image_source.volume_id == "") || (var.image_source.image_id == "" && var.image_source.volume_id != "")
    error_message = "You must provide either an image_id or a volume_id, but not both."
  }
}

variable "flavor_id" {
  description = "ID of the VM flavor"
  type        = string
}


variable "cloud_init_volume_pool" {
  description = "Name of the volume pool that will contain the cloud init volume"
  type        = string
}

variable "cloud_init_volume_name" {
  description = "Name of the cloud init volume"
  type        = string
  default     = ""
}

variable "ssh_admin_user" { 
  description = "Pre-existing ssh admin user of the image"
  type        = string
  default     = "ubuntu"
}

variable "admin_user_password" { 
  description = "Optional password for admin user"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssh_admin_public_key" {
  description = "Public ssh part of the ssh key the admin will be able to login as"
  type        = string
}

variable "keypair_name" {
  description = "Name of the keypair that will be used by admins to ssh to the node"
  type        = string
}

variable "chrony" {
  description = "Chrony configuration for ntp. If enabled, chrony is installed and configured, else the default image ntp settings are kept"
  type        = object({
    enabled = bool,
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#server
    servers = list(object({
      url     = string,
      options = list(string)
    })),
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#pool
    pools = list(object({
      url     = string,
      options = list(string)
    })),
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#makestep
    makestep = object({
      threshold = number,
      limit     = number
    })
  })
  default = {
    enabled  = false
    servers  = []
    pools    = []
    makestep = {
      threshold  = 0,
      limit      = 0
    }
  }
}

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type        = bool
  default     = true
}

variable "release_version" {
  description = "Vault release version to install"
  type        = string
  default     = "1.13.1"
}

variable "tls" {
  description = "Configuration for a secure vault communication over tls"
  type        = object({
    ca_certificate     = string
    server_certificate = string
    server_key         = string
    client_auth        = bool
  })
  default = {
    ca_certificate     = ""
    server_certificate = ""
    server_key         = ""
    client_auth        = false
  }
}

variable "etcd_backend" {
  description = "Parameters for the etcd backend"
  type        = object({
    key_prefix     = string
    urls           = string
    ca_certificate = string
    client         = object({
      certificate = string
      key         = string
      username    = string
      password    = string
    })
  })
  default = {
    key_prefix     = ""
    urls           = ""
    ca_certificate = ""
    client         = {
      certificate = ""
      key         = ""
      username    = ""
      password    = ""
    }
  }
}