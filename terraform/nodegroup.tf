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

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = aws_subnet.private[*].id

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
