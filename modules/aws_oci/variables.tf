# common
variable "oci_bgp_asn" {
  default = 31898
}
variable "aws_bgp_asn" {
  default = 64512
}
resource "random_password" "pre_shared_key" {
  length      = 64
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

# aws
variable "aws_vpc_main_id" {}
variable "aws_subnet_main_id" {}
variable "aws_subnet_dummy_id" {}
variable "aws_internet_gateway_main_id" {}
variable "aws_security_group_main_id" {}

# oci
variable "compartment_id" {}
variable "oci_core_vcn_main_id" {}
variable "oci_core_subnet_main_subnet_id" {}
variable "adb_domain" {
  default = "adb.ap-tokyo-1.oraclecloud.com"
}
