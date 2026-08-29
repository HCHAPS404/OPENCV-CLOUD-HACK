output "database_name" {
  value = aws_timestreamwrite_database.telemetry.database_name
}

output "table_name" {
  value = aws_timestreamwrite_table.rover_telemetry.table_name
}

output "database_arn" {
  value = aws_timestreamwrite_database.telemetry.arn
}

output "table_arn" {
  value = aws_timestreamwrite_table.rover_telemetry.arn
}
