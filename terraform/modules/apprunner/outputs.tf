output "service_url" {
  value = "https://${aws_apprunner_service.this.service_url}"
}

output "service_arn" {
  value = aws_apprunner_service.this.arn
}

output "instance_role_arn" {
  value = aws_iam_role.instance_role.arn
}
