# vpn

resource "oci_core_cpe" "vpn_aws" {
  #Required
  compartment_id = var.compartment_id
  ip_address     = tolist(aws_vpn_connection.main.vgw_telemetry)[0].outside_ip_address

  #Optional
  display_name = "${terraform.workspace}-vpn-aws-cpe"
}

resource "oci_core_drg" "main" {
  #Required
  compartment_id = var.compartment_id

  #Optional
  display_name = "${terraform.workspace}-vpn-aws-drg"
}

resource "oci_core_drg_attachment" "main" {
  #Required
  drg_id = oci_core_drg.main.id
  #Optional
  display_name = "${terraform.workspace}-vpn-aws-drg-attachment"
  network_details {
    #Required
    id   = data.oci_core_vcn.main.id
    type = "VCN"
  }
}

resource "oci_core_default_security_list" "main" {
  #Required
  manage_default_resource_id = data.oci_core_vcn.main.default_security_list_id

  egress_security_rules {
    #Required
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
  ingress_security_rules {
    #Required
    protocol = "all"
    source   = data.aws_vpc.main.cidr_block
  }
  ingress_security_rules {
    #Required
    protocol = "all"
    source   = data.oci_core_vcn.main.cidr_block
  }
}

resource "oci_core_ipsec" "main" {
  #Required
  compartment_id = var.compartment_id
  cpe_id         = oci_core_cpe.vpn_aws.id
  drg_id         = oci_core_drg.main.id
  static_routes  = ["0.0.0.0/0"]

  #Optional
  display_name = "${terraform.workspace}-ipsec"
}

data "oci_core_ipsec_connection_tunnels" "main" {
  #Required
  ipsec_id = oci_core_ipsec.main.id

  depends_on = [
    oci_core_ipsec.main,
  ]
}

resource "oci_core_ipsec_connection_tunnel_management" "main" {
  #Required
  ipsec_id  = oci_core_ipsec.main.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.main.ip_sec_connection_tunnels[0].id
  routing   = "BGP"

  bgp_session_info {
    customer_bgp_asn      = var.aws_bgp_asn
    customer_interface_ip = "${aws_vpn_connection.main.tunnel1_vgw_inside_address}/30"
    oracle_interface_ip   = "${aws_vpn_connection.main.tunnel1_cgw_inside_address}/30"
  }
  display_name  = "${terraform.workspace}-vpn-aws-ipsec-connection"
  shared_secret = random_password.pre_shared_key.result
  ike_version   = "V2"
}

# resolver

data "oci_core_vcn_dns_resolver_association" "main" {
  #Required
  vcn_id = data.oci_core_vcn.main.id
}

resource "oci_dns_resolver_endpoint" "main" {
  #Required
  is_forwarding     = false
  is_listening      = true
  name              = "${terraform.workspace}_vpn_aws_listening"
  resolver_id       = data.oci_core_vcn_dns_resolver_association.main.dns_resolver_id
  subnet_id         = data.oci_core_subnet.main.id
  scope             = "PRIVATE"
  listening_address = cidrhost(data.oci_core_subnet.main.cidr_block, 254)
}

resource "oci_core_default_route_table" "main" {
  #Required
  manage_default_resource_id = data.oci_core_vcn.main.default_route_table_id

  route_rules {
    #Required
    network_entity_id = oci_core_drg.main.id

    #Optional
    destination      = data.aws_vpc.main.cidr_block
    destination_type = "CIDR_BLOCK"
  }
}

data "oci_dns_views" "main" {
  #Required
  compartment_id = var.compartment_id
  scope          = "PRIVATE"

  #Optional
  display_name = data.oci_core_vcn.main.display_name
}

resource "oci_dns_resolver" "main" {
  #Required
  resolver_id = data.oci_core_vcn_dns_resolver_association.main.dns_resolver_id

  #Optional
  scope = "PRIVATE"
  attached_views {
    #Required
    view_id = data.oci_dns_views.main.views[0].id
  }
}
