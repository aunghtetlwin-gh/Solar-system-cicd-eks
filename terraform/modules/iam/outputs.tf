output "github_actions_deploy_role_arn" {
  description = "IAM role ARN that GitHub Actions assumes through OIDC to deploy to EKS."
  value       = aws_iam_role.github_actions_eks_deploy.arn
}
