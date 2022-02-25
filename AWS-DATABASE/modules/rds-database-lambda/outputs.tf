output "postgres_address" {
  description = "DB Address"
  value       = aws_db_instance.medium-pg.address
}

output "postgres_port" {
  description = "DB port"
  value       = aws_db_instance.medium-pg.port
}

output "postgres_name" {
  description = "DB name"
  value       = aws_db_instance.medium-pg.name
}

output "rds_sg" {
  description = "RDS Security group"
  value = module.rds_security_group.security_group_id
}