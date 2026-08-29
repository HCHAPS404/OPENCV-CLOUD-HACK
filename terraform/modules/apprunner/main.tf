# --- Rol para que App Runner pueda hacer pull de la imagen desde ECR ---
resource "aws_iam_role" "ecr_access" {
  name = "${var.project_name}-${var.service_name}-apprunner-ecr-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "build.apprunner.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.ecr_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# --- Rol de instancia: permisos que usa la app en tiempo de ejecución ---
resource "aws_iam_role" "instance_role" {
  name = "${var.project_name}-${var.service_name}-apprunner-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "tasks.apprunner.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "instance_policy" {
  name = "${var.project_name}-${var.service_name}-apprunner-instance-policy"
  role = aws_iam_role.instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = length(var.secrets_manager_arns) > 0 ? var.secrets_manager_arns : ["*"]
      }
      ], var.extra_instance_policy_statements
    )
  })
}

# --- VPC Connector: para hablar con RDS/RabbitMQ que viven en subnets privadas ---
resource "aws_apprunner_vpc_connector" "this" {
  vpc_connector_name = "${var.project_name}-${var.service_name}-connector"
  subnets             = var.vpc_connector_subnet_ids
  security_groups     = var.vpc_connector_security_group_ids
}

resource "aws_apprunner_auto_scaling_configuration_version" "this" {
  auto_scaling_configuration_name = "${var.project_name}-${var.service_name}-asc"
  min_size                        = var.min_size
  max_size                        = var.max_size
  max_concurrency                 = 100
}

resource "aws_apprunner_service" "this" {
  service_name = "${var.project_name}-${var.service_name}"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.ecr_access.arn
    }

    image_repository {
      image_identifier      = "${var.ecr_repository_url}:${var.image_tag}"
      image_repository_type = "ECR"

      image_configuration {
        port                          = var.port
        runtime_environment_variables = var.environment_variables
        runtime_environment_secrets   = var.environment_secrets
      }
    }

    auto_deployments_enabled = true
  }

  instance_configuration {
    cpu               = var.cpu
    memory            = var.memory
    instance_role_arn = aws_iam_role.instance_role.arn
  }

  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.this.arn
    }
  }

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.this.arn

  health_check_configuration {
    protocol = "TCP"
    interval = 10
    timeout  = 5
  }

  tags = {
    Name = "${var.project_name}-${var.service_name}"
  }
}
