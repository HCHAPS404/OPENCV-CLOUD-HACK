variable "project_name" { type = string }
variable "service_name" { type = string }
variable "ecr_repository_url" { type = string }
variable "image_tag" {
  type    = string
  default = "latest"
}
variable "port" {
  type    = string
  default = "8080"
}
variable "cpu" {
  type    = string
  default = "1024"
}
variable "memory" {
  type    = string
  default = "2048"
}
variable "environment_variables" {
  type    = map(string)
  default = {}
}
variable "environment_secrets" {
  type        = map(string)
  description = "map(nombre_env_var => ARN de Secrets Manager)"
  default     = {}
}
variable "vpc_connector_subnet_ids" { type = list(string) }
variable "vpc_connector_security_group_ids" { type = list(string) }
variable "secrets_manager_arns" {
  type        = list(string)
  description = "ARNs a los que el instance role necesita acceso (GetSecretValue)"
  default     = []
}
variable "extra_instance_policy_statements" {
  type        = list(any)
  description = "Statements IAM adicionales para el instance role (ej. S3, Timestream, IoT)"
  default     = []
}
variable "min_size" {
  type    = number
  default = 1
}
variable "max_size" {
  type    = number
  default = 3
}
