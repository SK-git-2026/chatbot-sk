provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "sk-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "sk-vpc"
  }
}

resource "aws_subnet" "sk-subnet" {
    count = 2
    vpc_id = aws_vpc.sk-vpc.id
    cidr_block = cidrsubnet(aws_vpc.sk-vpc.cidr_block, 8, count.index)
    availability_zone = element(["us-east-1a","us-east-1b"],count.index)
    map_public_ip_on_launch = true

    tags = {
        Name = "sk-subent"
    }

}

resource "aws_internet_gateway" "sk_igw" {

     vpc_id = aws_vpc.sk-vpc.id

     tags = {
       Name = "sk-igw"
     }
  
}
resource "aws_route_table" "sk-route_table" {

    vpc_id = aws_vpc.sk-vpc.id

    route = {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.sk_igw.id
    }

    tags = {
        Name = "sk-route_table"
    } 
  
}

resource "aws_route_table_association" "Sk_rt" {

    count = 2
    subnet_id = aws_subnet.sk-subnet[count.index].id
    route_table_id = aws_route_table.sk-route_table.id
  
}


resource "aws_security_group" "sk_clusture_sg" {
  name        = "sk_clusture_sg"
  description = "Security group for cluster"
  vpc_id      = aws_vpc.sk-vpc.id

  ingress {
    description = "Allow HTTPS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sk_clusture_sg"
  }

  
}

resource "aws_security_group" "sk_node_sg" {
  name        = "sk_node_sg"
  description = "Security group for nodes"
  vpc_id      = aws_vpc.sk-vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow NodePort range"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sk_node_sg"
  }
}

# IAM Role - EKS Cluster
############################
resource "aws_iam_role" "sk_eks_cluster_role" {
  name = "sk_eks_cluster_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.sk_eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

############################
# IAM Role - Worker Nodes
############################
resource "aws_iam_role" "sk_eks_node_role" {
  name = "sk_eks_node_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Worker node required policies
resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.sk_eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.sk_eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_registry_policy" {
  role       = aws_iam_role.sk_eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

############################
# EKS Cluster
############################
resource "aws_eks_cluster" "sk" {
  name     = "sk-cluster"
  role_arn = aws_iam_role.sk_eks_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.sk_subnet[*].id
    security_group_ids = [aws_security_group.sk_cluster_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}

############################
# EKS Node Group
############################
resource "aws_eks_node_group" "sk" {
  cluster_name    = aws_eks_cluster.sk.name
  node_group_name = "sk-node-group"
  node_role_arn   = aws_iam_role.sk_eks_node_role.arn

  subnet_ids = aws_subnet.sk_subnet[*].id

  scaling_config {
    desired_size = 2
    max_size     = 100
    min_size     = 2
  }

  instance_types = ["t3.micro"]

  remote_access {
    ec2_ssh_key               = var.ssh_key_name
    source_security_group_ids = [aws_security_group.sk_node_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_registry_policy
  ]
}