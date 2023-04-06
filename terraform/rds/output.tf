output "db_address" {
  description = "RDS address to form connection"
  value       = aws_db_instance.mysql_db_instance.address
}
