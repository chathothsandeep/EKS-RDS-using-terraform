output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.test_dev_vpc.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private_subnets[*].id
}

output "bastion_host_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion_host.public_ip
}

 output "rds_endpoint" {
   description = "RDS instance endpoint"
   value       = aws_db_instance.test_dev_db_instance.endpoint
 }

output "eks_cluster_endpoint" {
  description = "EKS Cluster API endpoint"
  value       = aws_eks_cluster.test_dev_eks_cluster.endpoint
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.test_dev_ecr_repository.repository_url
}

output "lb_sg_id" {
  description = "Security Group ID for Load Balancer"
  value       = aws_security_group.lb_sg.id
}

