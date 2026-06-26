output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "EKS Kubernetes API endpoint."
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_oidc_issuer_url" {
  description = "EKS OIDC issuer URL."
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "node_group_name" {
  description = "EKS managed node group name."
  value       = aws_eks_node_group.main.node_group_name
}

output "node_group_role_arn" {
  description = "IAM role ARN used by EKS worker nodes."
  value       = aws_iam_role.node_group.arn
}

output "ebs_csi_driver_role_arn" {
  description = "IAM role ARN used by the EBS CSI driver service account."
  value       = aws_iam_role.ebs_csi_driver.arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN used by AWS Load Balancer Controller."
  value       = aws_iam_role.aws_load_balancer_controller.arn
}
