# ---------------------------------------------------------------------------
# Terraform configuration for deploying a NixOS VM.Standard.A1.Flex instance
# on Oracle Cloud Infrastructure (Always Free-eligible).
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }

  # State is stored in OCI Object Storage via the S3-compatible API.
  # The remaining keys (endpoint, bucket, access_key, secret_key, region, key)
  # are passed at init time via -backend-config flags in the GitHub workflow.
  backend "s3" {
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    force_path_style            = true
  }
}

# ---------------------------------------------------------------------------
# Provider
# ---------------------------------------------------------------------------

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.api_key_fingerprint
  private_key_path = var.api_key_path
  region           = var.region
}

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------

variable "tenancy_ocid" {
  type        = string
  description = "OCID of the OCI tenancy"
}

variable "user_ocid" {
  type        = string
  description = "OCID of the OCI user"
}

variable "api_key_fingerprint" {
  type        = string
  description = "Fingerprint of the API signing key"
}

variable "api_key_path" {
  type        = string
  description = "Path to the PEM-formatted API private key"
}

variable "region" {
  type        = string
  description = "OCI region (e.g. us-ashburn-1)"
}

variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment for all resources"
}

variable "availability_domain" {
  type        = string
  description = "Availability domain (e.g. zXrW:US-ASHBURN-AD-1)"
}

variable "instance_name" {
  type        = string
  description = "Display name for the compute instance"
}

variable "image_id" {
  type        = string
  description = "OCID of the custom image to boot from"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key to authorize on the instance"
}

variable "ocpus" {
  type        = number
  description = "Number of OCPUs (1-4 for A1.Flex Always Free)"
}

variable "memory_in_gbs" {
  type        = number
  description = "Memory in GB (1-24 for A1.Flex Always Free)"
}

variable "boot_volume_size_in_gbs" {
  type        = number
  description = "Boot volume size in GB"
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "${var.instance_name}-vcn"
  dns_label      = "nixosvcn"
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.instance_name}-igw"
  enabled        = true
}

resource "oci_core_route_table" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.instance_name}-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

resource "oci_core_security_list" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.instance_name}-sl"

  # Allow all egress
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  # Allow SSH from anywhere
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_subnet" "main" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.main.id
  cidr_block        = "10.0.1.0/24"
  display_name      = "${var.instance_name}-subnet"
  dns_label         = "nixossub"
  route_table_id    = oci_core_route_table.main.id
  security_list_ids = [oci_core_security_list.main.id]
}

# ---------------------------------------------------------------------------
# Compute instance
# ---------------------------------------------------------------------------

resource "oci_core_instance" "main" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = var.instance_name
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = var.image_id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  create_vnic_details {
    subnet_id = oci_core_subnet.main.id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "instance_public_ip" {
  value       = oci_core_instance.main.public_ip
  description = "Public IP address of the deployed instance"
}

output "instance_ocid" {
  value       = oci_core_instance.main.id
  description = "OCID of the deployed instance"
}
