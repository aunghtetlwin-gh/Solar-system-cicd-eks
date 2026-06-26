# Reads the AWS account ID used by this Terraform run.
data "aws_caller_identity" "current" {}

# Creates the VPC, public/private subnets, NAT, and routing.
module "vpc" {
  source = "./modules/vpc"

  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
}

# Creates the EKS cluster, node group, addons, and Kubernetes AWS IAM roles.
module "eks" {
  source = "./modules/eks"

  cluster_name                         = var.cluster_name
  cluster_version                      = var.cluster_version
  vpc_id                               = module.vpc.vpc_id
  vpc_cidr                             = var.vpc_cidr
  public_subnet_ids                    = module.vpc.public_subnet_ids
  private_subnet_ids                   = module.vpc.private_subnet_ids
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  node_group_name                      = var.node_group_name
  node_group_instance_types            = var.node_group_instance_types
  node_group_desired_size              = var.node_group_desired_size
  node_group_min_size                  = var.node_group_min_size
  node_group_max_size                  = var.node_group_max_size
  node_group_disk_size                 = var.node_group_disk_size
}

# Creates GitHub Actions OIDC access to the EKS cluster.
module "iam" {
  source = "./modules/iam"

  project_name         = var.project_name
  cluster_name         = module.eks.cluster_name
  cluster_arn          = module.eks.cluster_arn
  github_repository    = var.github_repository
  github_deploy_branch = var.github_deploy_branch
}

# Creates Route 53, ACM, and dev/prod DNS alias records.
module "dns" {
  source = "./modules/dns"

  project_name      = var.project_name
  root_domain_name  = var.root_domain_name
  app_subdomain     = var.app_subdomain
  prod_alb_dns_name = var.prod_alb_dns_name
  dev_alb_dns_name  = var.dev_alb_dns_name
  alb_zone_id       = var.alb_zone_id
}
