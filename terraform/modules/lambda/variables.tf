variable "project_name" { type = string }
variable "function_name" { type = string }
variable "runtime" {
  type    = string
  default = "python3.12"
}
variable "handler" {
  type    = string
  default = "handler.lambda_handler"
}
variable "timeout" {
  type    = number
  default = 60
}
variable "memory_size" {
  type    = number
  default = 256
}
variable "source_dir" {
  type        = string
  description = "Carpeta local con el código fuente de la lambda (se empaqueta automáticamente en un zip)"
}
variable "environment_variables" {
  type    = map(string)
  default = {}
}
variable "vpc_subnet_ids" {
  type    = list(string)
  default = []
}
variable "vpc_security_group_ids" {
  type    = list(string)
  default = []
}
variable "extra_policy_statements" {
  type    = list(any)
  default = []
}
