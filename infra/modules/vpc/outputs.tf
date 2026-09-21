output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "public_route_table_ids" {
  description = "IDs of the public route tables"
  value       = module.vpc.public_route_table_ids
}