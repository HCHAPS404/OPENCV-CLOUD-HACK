variable "project_name" { type = string }
variable "worker_name" { type = string }
variable "cluster_id" { type = string }
variable "cluster_name" { type = string }
variable "ecr_repository_url" { type = string }
variable "image_tag" {
  type    = string
  default = "latest"
}
variable "cpu" {
  type    = string
  default = "512"
}
variable "memory" {
  type    = string
  default = "1024"
}
variable "desired_count" {
  type        = number
  default     = 1
  description = "Servicio Fargate persistente y liviano que escucha RabbitMQ; procesa solo cuando llegan mensajes (tiles nuevos), pero se mantiene arriba."
}
variable "private_subnet_ids" { type = list(string) }
variable "security_group_id" { type = string }
variable "environment_variables" {
  type    = map(string)
  default = {}
}
variable "secrets" {
  type        = map(string)
  description = "map(nombre_env_var => ARN de Secrets Manager)"
  default     = {}
}
variable "secrets_manager_arns" {
  type    = list(string)
  default = []
}
variable "s3_bucket_arn" {
  type    = string
  default = ""
}
