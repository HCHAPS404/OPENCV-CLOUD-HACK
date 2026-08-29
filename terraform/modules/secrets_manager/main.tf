resource "aws_secretsmanager_secret" "this" {
  # `for_each` requires non-sensitive keys. The actual secret values remain sensitive.
  for_each = nonsensitive(var.secrets)
  name     = "${var.project_name}/${each.key}"

  tags = { Name = "${var.project_name}-secret-${each.key}" }
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each      = nonsensitive(var.secrets)
  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = each.value
}
