provider "aws" {
  region = var.aws_region
}



# Create VPC
resource "aws_vpc" "test_dev_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "testdevVPC"
    Environment = "dev"
  }
}

# Create public subnets (multi AZ)
resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidr_blocks)

  vpc_id                  = aws_vpc.test_dev_vpc.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = var.aws_availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "test-dev-public-subnet-${count.index + 1}"
    Environment = "dev"
    Tier        = "public"
  }
}

# Create private subnets (multi AZ)
resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id                  = aws_vpc.test_dev_vpc.id
  cidr_block              = var.private_subnet_cidr_blocks[count.index]
  availability_zone       = var.aws_availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name        = "test-dev-private-subnet-${count.index + 1}"
    Environment = "dev"
    Tier        = "private"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.test_dev_vpc.id

  tags = {
    Name        = "test-dev-igw"
    Environment = "dev"
  }
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.test_dev_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "test-dev-public-rt"
    Environment = "dev"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public_rt_assoc" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  
  tags = {
    Name        = "test-dev-nat-eip"
    Environment = "dev"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name        = "test-dev-nat-gateway"
    Environment = "dev"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.test_dev_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name        = "test-dev-private-rt"
    Environment = "dev"
  }
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private_rt_assoc" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# Bastion Host Security Group
resource "aws_security_group" "bastion_sg" {
  name        = "test-dev-bastion-sg"
  description = "Allow SSH to Bastion Host"
  vpc_id      = aws_vpc.test_dev_vpc.id

  ingress {
    description = "SSH from allowed IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "test-dev-bastion-sg"
    Environment = "dev"
  }
}

# Bastion Host EC2 Instance
resource "aws_instance" "bastion_host" {
  ami                         = var.bastion_ami_id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnets[0].id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                    = var.bastion_ssh_key_name

  tags = {
    Name        = "test-dev-bastion-host"
    Environment = "dev"
  }
}

# Security Group for EKS Nodes
resource "aws_security_group" "eks_nodes_sg" {
  name        = "test-dev-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.test_dev_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "test-dev-eks-nodes-sg"
    Environment = "dev"
  }
}

# Allow EKS pods to connect to RDS
resource "aws_security_group_rule" "eks_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id  # Attach to RDS SG
  source_security_group_id = aws_security_group.eks_nodes_sg.id  # Allow EKS nodes
  description              = "Allow EKS pods to connect to RDS"
}


# Security Group for RDS (accessible from Bastion and EKS)
resource "aws_security_group" "rds_sg" {
  name        = "test-dev-rds-sg"
  description = "Allow PostgreSQL from Bastion and EKS"
  vpc_id      = aws_vpc.test_dev_vpc.id

  ingress {
    description     = "PostgreSQL from Bastion"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    description = "Allow PostgreSQL from EKS node subnets"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = aws_subnet.private_subnets[*].cidr_block 
}


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "test-dev-rds-sg"
    Environment = "dev"
  }
}



# DB Subnet Group
resource "aws_db_subnet_group" "test_dev_db_subnet_group" {
  name       = "test-dev-db-subnet-group"
  subnet_ids = aws_subnet.private_subnets[*].id

  tags = {
    Name        = "test-dev-db-subnet-group"
    Environment = "dev"
  }
}

# RDS Instance (private)
 resource "aws_db_instance" "test_dev_db_instance" {
   identifier              = var.db_instance_identifier
   engine                  = "postgres"
   engine_version          = var.db_engine_version 
   instance_class          = var.db_instance_class
   allocated_storage       = var.db_allocated_storage
   username                = var.db_instance_username
   password                = var.db_instance_password
   publicly_accessible     = false
   skip_final_snapshot     = true
   vpc_security_group_ids  = [aws_security_group.rds_sg.id]
   db_subnet_group_name    = aws_db_subnet_group.test_dev_db_subnet_group.name
   backup_retention_period = 7
   storage_encrypted       = true

   tags = {
     Name        = var.db_instance_identifier
     Environment = "dev"
   }
 }

# IAM Roles and EKS Cluster setup
resource "aws_iam_role" "eks_cluster" {
  name = "test-dev-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })

  tags = {
    Environment = "dev"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_eks_cluster" "test_dev_eks_cluster" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_k8s_version

  vpc_config {
    subnet_ids              = aws_subnet.private_subnets[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_nodes_sg.id]
  }

  tags = {
    Name        = var.eks_cluster_name
    Environment = "dev"
  }
}

resource "aws_iam_role" "eks_node_group_role" {
  name = "test-dev-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Environment = "dev"
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_eks_node_group" "test_dev_node_group" {
  cluster_name    = aws_eks_cluster.test_dev_eks_cluster.name
  node_group_name = "${var.eks_cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = aws_subnet.private_subnets[*].id
  ami_type        = var.eks_node_ami_type 
  disk_size       = var.eks_node_disk_size
  instance_types  = [var.eks_instance_type]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }

   remote_access {
     ec2_ssh_key               = var.bastion_ssh_key_name
     source_security_group_ids = [aws_security_group.bastion_sg.id]
   }

  tags = {
    Name        = "${var.eks_cluster_name}-node-group"
    Environment = "dev"
  }

  # Ensure the EKS nodes can communicate with the cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only,
  ]
}

# ECR
resource "aws_ecr_repository" "test_dev_ecr_repository" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = var.ecr_repository_name
    Environment = "dev"
  }
}

# I am Policy for AWS LB Ccontroller.
resource "aws_iam_policy" "aws_lb_controller_policy" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/iam_policy.json")
}
# IAM Role for the Controller
resource "aws_iam_role" "aws_lb_controller_role" {
  name = "aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Environment = "dev"
  }
}

#Attach IAM policy to the role
resource "aws_iam_role_policy_attachment" "attach_lb_controller_policy" {
  policy_arn = aws_iam_policy.aws_lb_controller_policy.arn
  role       = aws_iam_role.aws_lb_controller_role.name
}

#Security group for AWS LB
resource "aws_security_group" "lb_sg" {
  name        = "test-dev-lb-sg"
  description = "Allow HTTP for LoadBalancer"
  vpc_id      = aws_vpc.test_dev_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "test-dev-lb-sg"


    Environment = "dev"
  }
}