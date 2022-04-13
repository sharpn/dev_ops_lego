output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.vpc.id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private_subnet[*].id
}

output "public_cidr_blocks" {
  value = var.public.subnets
}

output "private_cidr_blocks" {
  value = var.private.subnets
}
