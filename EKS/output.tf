output "cluster_id" {
  value = aws_eks_cluster.sk
}

output "node_group_id" {
  value = aws_eks_node_group.sk.id
}

output "vpc_id" {
  value = aws_vpc.sk-vpc.id
}

output "subnet_id" {
  value = aws_subnet.sk_subnet[*].id
}