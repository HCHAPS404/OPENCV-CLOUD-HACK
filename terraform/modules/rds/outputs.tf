output "endpoint" {
  value = aws_db_instance.postgis.address
}

output "port" {
  value = aws_db_instance.postgis.port
}

output "db_name" {
  value = aws_db_instance.postgis.db_name
}
