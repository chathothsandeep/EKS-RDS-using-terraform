variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_blocks" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidr_blocks" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}


variable "aws_availability_zones" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b"]
}


variable "allowed_ssh_cidr_block" {
  description = "CIDR block allowed for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "bastion_ami_id" {
  description = "AMI ID for Bastion Host"
  type        = string
}

variable "bastion_ssh_key_name" {
  description = "SSH key name for Bastion Host"
  type        = string
}

 variable "db_instance_identifier" {
   description = "RDS DB instance identifier"
   type        = string
   default     = "test-dev-db"
 }

 variable "db_engine_version" {
   description = "Postgres engine version for RDS"
   type        = string
   default     = "16"
 }

 variable "db_instance_class" {
   description = "RDS instance class"
   type        = string
   default     = "db.t3.medium"
 }

 variable "db_allocated_storage" {
   description = "Allocated storage size in GB for the RDS instance"
   type        = number
   default     = 50
 }

 variable "db_instance_username" {
   description = "RDS master username"
   type        = string
   default     = "test_user"
 }

 variable "db_instance_password" {
   description = "RDS master password"
   type        = string
   sensitive   = true
 }

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "test-dev-eks"
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "test-dev-ecr"
}

variable "eks_instance_type" {
  description = "Instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "eks_node_disk_size" {
  description = "Disk size (in GB) for EKS worker nodes"
  type        = number
  default     = 80
}

variable "eks_node_ami_type" {
  description = "AMI type for EKS worker nodes"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "eks_k8s_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.33"  
}


