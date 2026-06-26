variable "project_name" {
  description = "Project name used for AWS resource tags."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_arn" {
  description = "EKS cluster ARN."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the deployment role, in owner/repository format."
  type        = string
}

variable "github_deploy_branch" {
  description = "GitHub branch allowed to assume the deployment role."
  type        = string
}
