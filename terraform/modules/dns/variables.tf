variable "project_name" {
  description = "Project name used in Route 53 hosted zone comments."
  type        = string
}

variable "root_domain_name" {
  description = "Root domain registered in Cloudflare."
  type        = string
}

variable "app_subdomain" {
  description = "Subdomain delegated to Route 53 for the app."
  type        = string
}

variable "prod_alb_dns_name" {
  description = "DNS name of the prod ALB created by AWS Load Balancer Controller."
  type        = string
  default     = ""
}

variable "dev_alb_dns_name" {
  description = "DNS name of the dev ALB created by AWS Load Balancer Controller."
  type        = string
  default     = ""
}

variable "alb_zone_id" {
  description = "Canonical hosted zone ID of the ALBs created by AWS Load Balancer Controller."
  type        = string
  default     = ""
}
