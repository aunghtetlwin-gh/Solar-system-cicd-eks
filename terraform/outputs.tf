output "aws_account_id" {
  description = "AWS account ID used by Terraform."
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS region where the cluster was created."
  value       = var.aws_region
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.main.name
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

output "github_actions_deploy_role_arn" {
  description = "IAM role ARN that GitHub Actions assumes through OIDC to deploy to EKS."
  value       = aws_iam_role.github_actions_eks_deploy.arn
}

output "vpc_id" {
  description = "VPC ID used by the EKS cluster."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = aws_subnet.private[*].id
}

output "update_kubeconfig_command" {
  description = "Command to configure kubectl for this EKS cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name} --profile ${var.aws_profile}"
}

output "app_domain_name" {
  description = "Application DNS name managed by the delegated Route 53 hosted zone."
  value       = local.app_domain_name
}

output "app_route53_zone_id" {
  description = "Route 53 hosted zone ID for the delegated application subdomain."
  value       = aws_route53_zone.app.zone_id
}

output "app_route53_name_servers" {
  description = "Nameservers to add as NS records in Cloudflare for the delegated subdomain."
  value       = aws_route53_zone.app.name_servers
}

output "app_acm_certificate_arn" {
  description = "ACM certificate ARN for the application domain. Use this in the ALB Ingress after ACM is issued."
  value       = aws_acm_certificate.app.arn
}

output "app_acm_validation_records" {
  description = "ACM DNS validation records created in the delegated Route 53 hosted zone."
  value = [
    for record in aws_route53_record.app_certificate_validation : {
      name    = record.name
      type    = record.type
      records = record.records
    }
  ]
}

output "app_dns_alias_record" {
  description = "Route 53 alias record for the prod app domain, if ALB variables are set."
  value       = length(aws_route53_record.app_alias) > 0 ? aws_route53_record.app_alias[0].fqdn : null
}

output "dev_app_dns_alias_record" {
  description = "Route 53 alias record for the dev app domain, if ALB variables are set."
  value       = length(aws_route53_record.dev_app_alias) > 0 ? aws_route53_record.dev_app_alias[0].fqdn : null
}
