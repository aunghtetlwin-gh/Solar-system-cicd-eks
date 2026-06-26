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
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Kubernetes API endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  description = "EKS OIDC issuer URL."
  value       = module.eks.cluster_oidc_issuer_url
}

output "node_group_name" {
  description = "EKS managed node group name."
  value       = module.eks.node_group_name
}

output "node_group_role_arn" {
  description = "IAM role ARN used by EKS worker nodes."
  value       = module.eks.node_group_role_arn
}

output "ebs_csi_driver_role_arn" {
  description = "IAM role ARN used by the EBS CSI driver service account."
  value       = module.eks.ebs_csi_driver_role_arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN used by AWS Load Balancer Controller."
  value       = module.eks.aws_load_balancer_controller_role_arn
}

output "github_actions_deploy_role_arn" {
  description = "IAM role ARN that GitHub Actions assumes through OIDC to deploy to EKS."
  value       = module.iam.github_actions_deploy_role_arn
}

output "vpc_id" {
  description = "VPC ID used by the EKS cluster."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "update_kubeconfig_command" {
  description = "Command to configure kubectl for this EKS cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name} --profile ${var.aws_profile}"
}

output "app_domain_name" {
  description = "Application DNS name managed by the delegated Route 53 hosted zone."
  value       = module.dns.app_domain_name
}

output "app_route53_zone_id" {
  description = "Route 53 hosted zone ID for the delegated application subdomain."
  value       = module.dns.app_route53_zone_id
}

output "app_route53_name_servers" {
  description = "Nameservers to add as NS records in Cloudflare for the delegated subdomain."
  value       = module.dns.app_route53_name_servers
}

output "app_acm_certificate_arn" {
  description = "ACM certificate ARN for the application domain. Use this in the ALB Ingress after ACM is issued."
  value       = module.dns.app_acm_certificate_arn
}

output "app_acm_validation_records" {
  description = "ACM DNS validation records created in the delegated Route 53 hosted zone."
  value       = module.dns.app_acm_validation_records
}

output "app_dns_alias_record" {
  description = "Route 53 alias record for the prod app domain, if ALB variables are set."
  value       = module.dns.app_dns_alias_record
}

output "dev_app_dns_alias_record" {
  description = "Route 53 alias record for the dev app domain, if ALB variables are set."
  value       = module.dns.dev_app_dns_alias_record
}
