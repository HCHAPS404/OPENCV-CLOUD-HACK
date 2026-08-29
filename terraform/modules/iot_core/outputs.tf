output "iot_data_endpoint" {
  value       = data.aws_iot_endpoint.this.endpoint_address
  description = "Endpoint MQTT que deben usar los rovers/ESP32 para conectarse"
}

output "rover_policy_name" {
  value = aws_iot_policy.rover_policy.name
}

output "thing_type_name" {
  value = aws_iot_thing_type.rover.name
}
