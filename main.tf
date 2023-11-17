locals {
  block_devices = var.image_source.volume_id != "" ? [{
    uuid                  = var.image_source.volume_id
    source_type           = "volume"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = false
  }] : []
  cloudinit_templates = concat([
      {
        filename     = "base.cfg"
        content_type = "text/cloud-config"
        content      = templatefile(
          "${path.module}/files/user_data.yaml.tpl", 
          {
            hostname             = var.name
            install_dependencies = var.install_dependencies
          }
        )
      },
      {
        filename     = "vault.cfg"
        content_type = "text/cloud-config"
        content      = module.vault_configs.configuration
      },
      {
        filename     = "node_exporter.cfg"
        content_type = "text/cloud-config"
        content      = module.prometheus_node_exporter_configs.configuration
      }
    ],
    var.fluentbit.enabled ? [{
      filename     = "fluent_bit.cfg"
      content_type = "text/cloud-config"
      content      = module.fluentbit_configs.configuration
    }] : [],
    var.chrony.enabled ? [{
      filename     = "chrony.cfg"
      content_type = "text/cloud-config"
      content      = module.chrony_configs.configuration
    }] : [],
  )
}

module "vault_configs" {
  source               = "git::https://github.com/Ferlab-Ste-Justine/terraform-cloudinit-templates.git//vault?ref=v0.15.0"
  install_dependencies = var.install_dependencies
  hostname             = var.name
  release_version      = var.release_version
  tls                  = var.tls
  etcd_backend         = var.etcd_backend
}

module "prometheus_node_exporter_configs" {
  source               = "git::https://github.com/Ferlab-Ste-Justine/terraform-cloudinit-templates.git//prometheus-node-exporter?ref=v0.15.0"
  install_dependencies = var.install_dependencies
}

module "chrony_configs" {
  source               = "git::https://github.com/Ferlab-Ste-Justine/terraform-cloudinit-templates.git//chrony?ref=v0.15.0"
  install_dependencies = var.install_dependencies
  chrony               = {
    servers  = var.chrony.servers
    pools    = var.chrony.pools
    makestep = var.chrony.makestep
  }
}

module "fluentbit_configs" {
  source               = "git::https://github.com/Ferlab-Ste-Justine/terraform-cloudinit-templates.git//fluent-bit?ref=v0.15.0"
  install_dependencies = true
  fluentbit = {
    metrics          = var.fluentbit.metrics
    systemd_services = concat(
      var.fluentbit.etcd_tag != "" ? [{
        tag     = var.fluentbit.etcd_tag
        service = "etcd.service"
      }] : [],
      [
        {
          tag     = var.fluentbit.containerd_tag
          service = "containerd.service"
        },
        {
          tag     = var.fluentbit.kubelet_tag
          service = "kubelet.service"
        },
        {
          tag     = var.fluentbit.node_exporter_tag
          service = "node-exporter.service"
        }
      ]
    )
    forward = var.fluentbit.forward
  }
}

data "template_cloudinit_config" "user_data" {
  gzip          = true
  base64_encode = true
  dynamic "part" {
    for_each = local.cloudinit_templates
    content {
      filename     = part.value["filename"]
      content_type = part.value["content_type"]
      content      = part.value["content"]
    }
  }
}

resource "openstack_compute_instance_v2" "vault_node" {
  name      = var.name
  image_id  = var.image_source.image_id != "" ? var.image_source.image_id : null
  flavor_id = var.flavor_id
  key_pair  = var.keypair_name

  user_data = data.template_cloudinit_config.user_data.rendered

  network {
    port = var.network_port.id
  }

  scheduler_hints {
    group = var.server_group.id
  }

  dynamic "block_device" {
    for_each = local.block_devices
    content {
      uuid                  = block_device.value["uuid"]
      source_type           = block_device.value["source_type"]
      boot_index            = block_device.value["boot_index"]
      destination_type      = block_device.value["destination_type"]
      delete_on_termination = block_device.value["delete_on_termination"]
    }
  }


  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }
}