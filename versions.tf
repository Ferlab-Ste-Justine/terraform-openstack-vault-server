terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "= 1.49.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "= 2.2.0"
    }
  }
  required_version = ">= 1.0.0"
}