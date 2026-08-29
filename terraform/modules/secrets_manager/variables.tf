variable "project_name" { type = string }

variable "secrets" {
  type        = map(string)
  description = "map(nombre_logico => valor). Se crea un secreto por cada entrada."
  sensitive   = true
}
