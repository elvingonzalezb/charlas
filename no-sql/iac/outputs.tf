output "orders_command_table_name" {
  description = "Name of the DynamoDB table for write operations"
  value       = aws_dynamodb_table.orders_command.name
}

output "orders_query_table_name" {
  description = "Name of the DynamoDB table for read operations"
  value       = aws_dynamodb_table.orders_query.name
}

output "orders_command_stream_arn" {
  description = "ARN of the DynamoDB stream for write table"
  value       = aws_dynamodb_table.orders_command.stream_arn
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_url" {
  description = "URL of the load balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "write_service_url" {
  description = "URL for write service"
  value       = "http://${aws_lb.main.dns_name}/write"
}

output "read_service_url" {
  description = "URL for read service"
  value       = "http://${aws_lb.main.dns_name}/read"
}

output "ecr_write_repository_url" {
  description = "URL of the ECR repository for write service"
  value       = aws_ecr_repository.write_service.repository_url
}

output "ecr_read_repository_url" {
  description = "URL of the ECR repository for read service"
  value       = aws_ecr_repository.read_service.repository_url
}

output "ecr_sync_repository_url" {
  description = "URL of the ECR repository for sync service"
  value       = aws_ecr_repository.sync_service.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}