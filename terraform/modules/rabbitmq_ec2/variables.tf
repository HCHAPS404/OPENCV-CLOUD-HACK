variable "project_name" { type = string }
variable "private_subnet_id" { type = string }
variable "security_group_id" { type = string }
variable "instance_type" {
  type    = string
  default = "t3.small"
}
variable "rabbitmq_user" { type = string }
variable "rabbitmq_password" {
  type      = string
  sensitive = true
}
variable "key_pair_name" {
  type        = string
  description = "Nombre de un Key Pair EC2 existente (para acceso SSM/SSH de emergencia). Puede ir vacío si solo se usará SSM."
  default     = ""
}
