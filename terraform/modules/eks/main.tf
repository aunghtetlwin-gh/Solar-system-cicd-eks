# Creates the EKS control plane.
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids = concat(
      var.public_subnet_ids,
      var.private_subnet_ids
    )
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = false
    endpoint_public_access  = true
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  kubernetes_network_config {
    ip_family = "ipv4"
  }

  tags = {
    Name = var.cluster_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController
  ]
}

# Defines EC2 launch settings for managed worker nodes.
resource "aws_launch_template" "node_group" {
  name_prefix = "${var.cluster_name}-${var.node_group_name}-"
  description = "Launch template for the ${var.cluster_name} EKS managed node group"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.node_group_disk_size
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  vpc_security_group_ids = [aws_eks_cluster.main.vpc_config[0].cluster_security_group_id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.cluster_name}-${var.node_group_name}-node"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "${var.cluster_name}-${var.node_group_name}-node"
    }
  }

  tags = {
    Name = "${var.cluster_name}-${var.node_group_name}-lt"
  }
}

# Creates the managed node group in private subnets.
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnet_ids

  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"
  instance_types = var.node_group_instance_types

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  launch_template {
    id      = aws_launch_template.node_group.id
    version = aws_launch_template.node_group.latest_version
  }

  labels = {
    workload = "general"
  }

  tags = {
    Name = "${var.cluster_name}-${var.node_group_name}"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryPullOnly,
    aws_iam_role_policy_attachment.node_group_AmazonSSMManagedInstanceCore
  ]
}

# Installs or manages the Amazon VPC CNI EKS addon.
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]
}

# Installs or manages the kube-proxy EKS addon.
resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]
}

# Installs or manages the CoreDNS EKS addon.
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]
}

# Installs or manages the EBS CSI driver EKS addon.
resource "aws_eks_addon" "aws_ebs_csi_driver" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.ebs_csi_driver.arn

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi_driver_AmazonEBSCSIDriverPolicy
  ]
}

# Installs or manages Metrics Server for HPA metrics.
resource "aws_eks_addon" "metrics_server" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "metrics-server"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]
}
