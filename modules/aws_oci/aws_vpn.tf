# vpn

resource "aws_vpn_gateway" "main" {
  vpc_id = data.aws_vpc.main.id
  tags = {
    Name = "${terraform.workspace}-vgw"
  }
}

resource "aws_vpn_gateway_route_propagation" "main" {
  vpn_gateway_id = aws_vpn_gateway.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_customer_gateway" "oci_vpn_dummy" {
  bgp_asn    = var.oci_bgp_asn
  ip_address = "1.1.1.1"
  type       = "ipsec.1"

  tags = {
    Name = "${terraform.workspace}-cgw-dummy"
  }
}

resource "aws_customer_gateway" "oci_vpn" {
  bgp_asn    = var.oci_bgp_asn
  ip_address = oci_core_ipsec_connection_tunnel_management.main.vpn_ip
  type       = "ipsec.1"

  tags = {
    Name = "${terraform.workspace}-cgw"
  }
}

# NOTE: Switch customer gateway from dummy to actual one on AWS console due to cycle reference
resource "aws_vpn_connection" "main" {
  vpn_gateway_id        = aws_vpn_gateway.main.id
  customer_gateway_id   = aws_customer_gateway.oci_vpn_dummy.id
  type                  = "ipsec.1"
  tunnel1_ike_versions  = ["ikev2"]
  tunnel1_preshared_key = random_password.pre_shared_key.result

  tags = {
    Name = "${terraform.workspace}-connection"
  }
}

resource "aws_route_table" "main" {
  vpc_id = data.aws_vpc.main.id

  route {
    cidr_block = data.oci_core_vcn.main.cidr_block
    gateway_id = aws_vpn_gateway.main.id
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.main.internet_gateway_id
  }

  tags = {
    Name = "${terraform.workspace}-vpn-oci-ig"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = data.aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# resolver

resource "aws_route53_resolver_endpoint" "outbound" {
  name      = "${terraform.workspace}-vpn-oci-outbound"
  direction = "OUTBOUND"

  security_group_ids = [
    data.aws_security_group.main.id,
  ]
  ip_address {
    subnet_id = data.aws_subnet.main.id
  }
  ip_address {
    subnet_id = data.aws_subnet.dummy.id
  }
}

resource "aws_route53_resolver_rule" "main" {
  domain_name          = var.adb_domain
  name                 = "${terraform.workspace}-vpn-oci-outbound-rule"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id

  target_ip {
    ip   = oci_dns_resolver_endpoint.main.listening_address
    port = 53
  }
}

resource "aws_route53_resolver_rule_association" "main" {
  resolver_rule_id = aws_route53_resolver_rule.main.id
  vpc_id           = data.aws_vpc.main.id
}

# existing resource

# resource "aws_security_group_rule" "main" {
#   type      = "ingress"
#   from_port = 0
#   to_port   = 65535
#   protocol  = "-1"
#   cidr_blocks = [
#     data.oci_core_vcn.main.cidr_block,
#   ]
#   security_group_id = data.aws_security_group.main.id
# }
