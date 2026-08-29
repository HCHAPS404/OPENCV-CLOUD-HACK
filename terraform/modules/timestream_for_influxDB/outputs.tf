output "instance_id" {
  value = aws_timestreaminfluxdb_db_instance.this.id
}

output "instance_endpoint" {
  description = "Endpoint HTTP(S) para escribir/leer con la API v2 de InfluxDB"
  value       = aws_timestreaminfluxdb_db_instance.this.endpoint
}

output "influx_auth_parameters_secret_arn" {
  description = "ARN del secreto en Secrets Manager que AWS crea automáticamente con organization, bucket, username y password"
  value       = aws_timestreaminfluxdb_db_instance.this.influx_auth_parameters_secret_arn
}

output "arn" {
  value = aws_timestreaminfluxdb_db_instance.this.arn
}
