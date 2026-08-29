variable "project_name" { type = string }

variable "iot_service_https_endpoint" {
  type        = string
  description = "URL pública del iot-service (App Runner) + path, ej: https://xxxx.awsapprunner.com/telemetry"
}
