variable "aws_region" {
  description = "AWS region where the EKS infrastructure will be created."
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "Local AWS CLI profile Terraform should use."
  type        = string
  default     = "master-programmatic-admin"
}

variable "project_name" {
  description = "Project name used for AWS resource tags."
  type        = string
  default     = "solar-system"
}

variable "environment" {
  description = "Environment name used for tags and naming."
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "solar-system-eks"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.33"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.40.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones used for public and private subnets."
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.40.0.0/20", "10.40.16.0/20", "10.40.32.0/20"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.40.48.0/20", "10.40.64.0/20", "10.40.80.0/20"]
}

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway so private nodes can pull images and reach AWS APIs."
  type        = bool
  default     = true
}

variable "node_group_name" {
  description = "EKS managed node group name."
  type        = string
  default     = "general"
}

variable "node_group_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}

variable "node_group_disk_size" {
  description = "Root volume size in GB for worker nodes."
  type        = number
  default     = 30
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the public EKS API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
