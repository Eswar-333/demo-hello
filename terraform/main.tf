#Eks cluster with Terraform 

###############################################################################
# TERRAFORM + AWS PROVIDER
###############################################################################

terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.59"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


###############################################################################
# VARIABLES
###############################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "terraform-eks"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.36"
}


###############################################################################
# VPC
###############################################################################

module "vpc" {

  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.cluster_name}-vpc"

  cidr = "10.0.0.0/16"

  # EKS requires subnets in at least 2 AZs
  azs = [
    "${var.aws_region}a",
    "${var.aws_region}b"
  ]

  # Private subnets for EKS worker nodes
  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  # Public subnets
  public_subnets = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]

  # Internet access for private subnets
  enable_nat_gateway = true

  # One NAT Gateway to reduce cost
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


###############################################################################
# EKS CLUSTER
###############################################################################

module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name = var.cluster_name

  kubernetes_version = var.cluster_version

  # Allow kubectl access from local machine
  endpoint_public_access = true

  # Give cluster creator admin access
  enable_cluster_creator_admin_permissions = true


  ###########################################################################
  # EKS ADDONS
  ###########################################################################

  addons = {

    coredns = {}

    eks-pod-identity-agent = {
      before_compute = true
    }

    kube-proxy = {}

    vpc-cni = {
      before_compute = true
    }
  }


  ###########################################################################
  # NETWORKING
  ###########################################################################

  vpc_id = module.vpc.vpc_id

  # Worker nodes in private subnets
  subnet_ids = module.vpc.private_subnets


  ###########################################################################
  # MANAGED NODE GROUP
  ###########################################################################

  eks_managed_node_groups = {

    general = {

      name = "general-node-group"


      #######################################################################
      # INSTANCE TYPE
      #######################################################################

      # Small instance for learning/testing
      instance_types = ["t3.small"]


      #######################################################################
      # AMI
      #######################################################################

      # IMPORTANT:
      # ami_type is NOT an AMI ID.
      # Use a supported EKS AMI type.
      ami_type = "AL2023_x86_64_STANDARD"


      #######################################################################
      # NODE SCALING
      #######################################################################

      # Start with 2 nodes so CoreDNS and other system pods
      # have enough pod capacity.
      min_size     = 1
      desired_size = 2
      max_size     = 3


      #######################################################################
      # STORAGE
      #######################################################################

      disk_size = 20


      #######################################################################
      # CAPACITY TYPE
      #######################################################################

      capacity_type = "ON_DEMAND"


      #######################################################################
      # NODE LABELS
      #######################################################################

      labels = {
        Environment = "dev"
        NodeGroup   = "general"
      }


      #######################################################################
      # NODE TAGS
      #######################################################################

      tags = {
        Name        = "${var.cluster_name}-worker"
        Environment = "dev"
        Terraform   = "true"
      }

    }

  }


  ###########################################################################
  # EKS TAGS
  ###########################################################################

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }

}


###############################################################################
# OUTPUTS
###############################################################################

output "cluster_name" {

  description = "EKS cluster name"

  value = module.eks.cluster_name
}


output "cluster_endpoint" {

  description = "EKS API endpoint"

  value = module.eks.cluster_endpoint
}


output "cluster_version" {

  description = "Kubernetes version"

  value = module.eks.cluster_version
}


output "vpc_id" {

  description = "VPC ID"

  value = module.vpc.vpc_id
}


output "private_subnets" {

  description = "Private subnet IDs"

  value = module.vpc.private_subnets
}


output "node_group" {

  description = "EKS managed node group"

  value = module.eks.eks_managed_node_groups
}