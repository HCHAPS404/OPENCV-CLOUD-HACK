variable "project_name" {
  type = string
}

variable "repo_names" {
  type        = list(string)
  description = "Nombres de servicios que necesitan su propio repo ECR"
}
