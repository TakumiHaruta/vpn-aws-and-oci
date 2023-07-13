# aws
data "aws_vpc" "main" {
  id = var.aws_vpc_main_id
}
data "aws_subnet" "main" {
  id = var.aws_subnet_main_id
}
data "aws_subnet" "dummy" {
  id = var.aws_subnet_dummy_id
}
data "aws_internet_gateway" "main" {
  internet_gateway_id = var.aws_internet_gateway_main_id
}
data "aws_security_group" "main" {
  id = var.aws_security_group_main_id
}

# oci

data "oci_core_vcn" "main" {
  vcn_id = var.oci_core_vcn_main_id
}
data "oci_core_subnet" "main" {
  subnet_id = var.oci_core_subnet_main_subnet_id
}


