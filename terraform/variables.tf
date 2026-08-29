variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "krop"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

# --- Base de datos ---
variable "db_name" {
  type    = string
  default = "krop"
}

variable "db_username" {
  type    = string
  default = "krop_admin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.micro"
}

# --- RabbitMQ (EC2) ---
variable "rabbitmq_user" {
  type    = string
  default = "krop"
}

variable "rabbitmq_password" {
  type      = string
  sensitive = true
}

variable "rabbitmq_instance_type" {
  type    = string
  default = "t3.small"
}

variable "rabbitmq_key_pair_name" {
  type    = string
  default = ""
}

# --- S3 ---
variable "satellite_images_bucket_name" {
  type        = string
  description = "Debe ser un nombre único globalmente, ej: krop-satellite-images-<tu-cuenta>"
}

# --- ECR / imágenes docker ---
variable "image_tag" {
  type    = string
  default = "latest"
}

# --- App Runner ---
variable "core_service_port" {
  type    = string
  default = "8080"
}

variable "iot_service_port" {
  type    = string
  default = "8000"
}

# --- Satélite (Lambda satellite-check) ---
variable "satellite_api_url" {
  type        = string
  description = "URL del proveedor de imágenes satelitales (ej. Copernicus/Sentinel Hub)"
  default     = ""
}

variable "satellite_api_key" {
  type      = string
  sensitive = true
  default   = ""
}

# --- On-demand analysis ---
variable "analysis_debounce_days" {
  type    = number
  default = 8
}
