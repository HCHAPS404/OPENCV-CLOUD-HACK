variable "project_name" {
  type = string
}

variable "username" {
  type        = string
  description = "Usuario administrador de InfluxDB"
  default     = "admin"
}

variable "password" {
  type        = string
  description = "Password del administrador de InfluxDB (usar var.rabbitmq_password-style: pasar desde secrets/variables sensibles)"
  sensitive   = true
}

variable "organization" {
  type        = string
  description = "Nombre de la organización InfluxDB (namespace lógico, no confundir con AWS Org)"
  default     = "krop"
}

variable "bucket" {
  type        = string
  description = "Bucket InfluxDB (equivalente a 'base de datos' dentro de la org) donde se guarda la telemetría"
  default     = "rover_telemetry"
}

variable "vpc_subnet_ids" {
  type        = list(string)
  description = "Subnets privadas donde se despliega la instancia (necesita al menos 1; 2+ si usas multi_az)"
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "Security groups a asociar a la instancia InfluxDB"
}

variable "db_instance_type" {
  type        = string
  description = "Tamaño de instancia InfluxDB"
  default     = "db.influx.medium"
}

variable "allocated_storage" {
  type        = number
  description = "Almacenamiento en GiB"
  default     = 20
}

variable "log_bucket_name" {
  type        = string
  description = "Bucket S3 donde se entregan los logs del motor InfluxDB (puedes reusar tu bucket de S3 existente con un prefix, o crear uno dedicado)"
}

variable "publicly_accessible" {
  type    = bool
  default = false
}
