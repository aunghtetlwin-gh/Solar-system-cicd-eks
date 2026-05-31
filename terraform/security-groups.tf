resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Additional security group for the EKS control plane"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.cluster_name}-cluster-sg"
  }
}

resource "aws_security_group_ingress_rule" "cluster_https" {
  security_group_id = aws_security_group.cluster.id
  description       = "Allow HTTPS traffic to the EKS control plane security group"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = var.vpc_cidr
}

resource "aws_security_group_egress_rule" "cluster_all" {
  security_group_id = aws_security_group.cluster.id
  description       = "Allow all outbound traffic from the EKS control plane security group"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}
