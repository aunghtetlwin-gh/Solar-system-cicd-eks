variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS will be created."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR used for control plane security group rules."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the EKS control plane."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for worker nodes."
  type        = list(string)
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the public EKS API endpoint."
  type        = list(string)
}

variable "node_group_name" {
  description = "EKS managed node group name."
  type        = string
}

variable "node_group_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
}

variable "node_group_disk_size" {
  description = "Root volume size in GB for worker nodes."
  type        = number
}
