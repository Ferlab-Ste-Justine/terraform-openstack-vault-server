# About

This Terraform module provisions a virtual machine (VM) on OpenStack to be part of a HashiCorp Vault cluster. It configures the VM with cloud-init, sets up Vault, and optionally configures Chrony for NTP synchronization.

# Usage

## Input Variables

The module accepts the following input variables:

- **name**: Name to assign to the VM.
- **image_source**: Source of the VM's image, specified as either an `image_id` or a `volume_id`.
- **flavor_id**: ID of the VM flavor to determine the compute, memory, and storage capacity.
- **network_port**: Network port to assign to the VM. Should be of type `openstack_networking_port_v2`.
- **server_group**: Server group to assign to the VM. Should be of type `openstack_compute_servergroup_v2`.
- **keypair_name**: Name of the SSH keypair for admin access to the VM.
- **ssh_admin_user**: Username of the default sudo user in the image. Defaults to "ubuntu".
- **admin_user_password**: Optional password for the admin user. Note: This does not enable SSH password login.
- **ssh_admin_public_key**: Public SSH key for admin access.
- **chrony**: Optional chrony configuration for when you need a more fine-grained ntp setup on your vm. It is an object with the following fields:
  - **enabled**: If set to false (the default), chrony will not be installed and the vm ntp settings will be left to default.
  - **servers**: List of ntp servers to sync from with each entry containing two properties, **url** and **options** (see: https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#server)
  - **pools**: A list of ntp server pools to sync from with each entry containing two properties, **url** and **options** (see: https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#pool)
  - **makestep**: An object containing remedial instructions if the clock of the vm is significantly out of sync at startup. It is an object containing two properties, **threshold** and **limit** (see: https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#makestep)
- **install_dependencies**: Whether to install dependencies during cloud-init. Defaults to true.
- **release_version**: Vault release version to install. Defaults to "1.13.1".
- **tls**: Tls configuration for secure communication with vault. It has the following keys:
  - **ca_certificate**: Ca certificate to authentify the server.
  - **server_certificate**: Tls certificate to authentify the server.
  - **server_key**: Tls private key to authentify the server.
  - **client_auth**: Whether to turn on client authentication.
- **etcd_backend**: Client connection configuration for the etcd cluster to connect to as a storage backend. It has the following keys:
  - **key_prefix**: Prefix in etcd's keyspace to use to detect envoy's configuration. Note that the key containing the configuration is assumed to have envoy's node id appended to that prefix.
  - **urls**: Urls of the etcd cluster. Should be a comma-separated list.
  - **ca_certificate**: CA certificate that should be used to authentify the etcd cluster's server certificates.
  - **client**: Client authentication to etcd. It should have the following keys.
    - **certificate**: Client certificate to use to authentify against etcd. Can be empty if password authentication is used.
    - **key**: Client key to use to authentify against etcd. Can be empty is password authentication is used.
    - **username**: Username to use for password authentication. Can be empty if certificate authentication is used.
    - **password**: Password to use for password authentication. Can be empty is certificate authentication is used.

## Cloud-Init Templates

The module dynamically generates cloud-init configurations for the VM, including:

- Base configuration (`base.cfg`)
- Vault configuration (`vault.cfg`)
- Prometheus Node Exporter configuration (`node_exporter.cfg`)
- Chrony configuration (`chrony.cfg`) if enabled

## OpenStack Compute Instance

The `openstack_compute_instance_v2` resource is used to create the VM with the specified configurations. It includes settings for the image, flavor, key pair, user data, network, block devices, and lifecycle configurations.

## Modules

The module uses external Terraform modules for configuring Vault, Prometheus Node Exporter, and Chrony, sourced from `git::https://github.com/Ferlab-Ste-Justine/terraform-cloudinit-templates.git`.