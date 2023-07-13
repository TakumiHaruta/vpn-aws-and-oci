terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
    oci = {
      version = "~> 5.2.1"
    }
  }
  required_version = "~> 1.4.6"
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

provider "oci" {
  tenancy_ocid     = var.oci_tenancy_ocid
  user_ocid        = var.oci_user_ocid
  fingerprint      = var.oci_fingerprint
  private_key_path = var.oci_private_key_path
  region           = var.oci_region
}

module "aws_oci" {
  source = "./modules/aws_oci"

  # aws
  aws_vpc_main_id              = var.aws_vpc_main_id
  aws_subnet_main_id           = var.aws_subnet_main_id
  aws_subnet_dummy_id          = var.aws_subnet_dummy_id
  aws_internet_gateway_main_id = var.aws_internet_gateway_main_id
  aws_security_group_main_id   = var.aws_security_group_main_id

  # oci
  compartment_id                 = var.oci_compartment_id
  oci_core_vcn_main_id           = var.oci_core_vcn_main_id
  oci_core_subnet_main_subnet_id = var.oci_core_subnet_main_subnet_id
}

# Required variables

variable "aws_profile" {}
variable "aws_region" {}
variable "oci_tenancy_ocid" {}
variable "oci_user_ocid" {}
variable "oci_fingerprint" {}
variable "oci_private_key_path" {}
variable "oci_region" {}
