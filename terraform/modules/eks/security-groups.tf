# Creates an additional security group for the EKS control plane.
resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Additional security group for the EKS control plane"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.cluster_name}-cluster-sg"
  }
}

# Allows HTTPS access to the EKS control plane from inside the VPC.
resource "aws_security_group_rule" "cluster_https_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.cluster.id
  description       = "Allow HTTPS traffic to the EKS control plane security group"

  protocol    = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_blocks = [var.vpc_cidr]
}

# Allows all outbound traffic from the EKS control plane security group.
resource "aws_security_group_rule" "cluster_all_egress" {
  type              = "egress"
  security_group_id = aws_security_group.cluster.id
  description       = "Allow all outbound traffic from the EKS control plane security group"

  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
}
