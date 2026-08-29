# Todos los Security Groups viven en un solo módulo para evitar
# dependencias circulares entre módulos (apprunner <-> rds <-> rabbitmq, etc).

resource "aws_security_group" "apprunner_core" {
  name        = "${var.project_name}-sg-apprunner-core"
  description = "VPC connector - core-service (App Runner)"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-apprunner-core" }
}

resource "aws_security_group" "apprunner_iot" {
  name        = "${var.project_name}-sg-apprunner-iot"
  description = "VPC connector - iot-service (App Runner FastAPI)"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-apprunner-iot" }
}

resource "aws_security_group" "ecs_workers" {
  name        = "${var.project_name}-sg-ecs-workers"
  description = "ECS Fargate workers (optical/radar/proximal-vision)"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-ecs-workers" }
}

resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-sg-lambda"
  description = "Lambdas dentro de la VPC (satellite-check, on-demand-analysis)"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-lambda" }
}

resource "aws_security_group" "rabbitmq" {
  name        = "${var.project_name}-sg-rabbitmq"
  description = "RabbitMQ EC2 - AMQP desde core-service, iot-service, workers y lambdas"
  vpc_id      = var.vpc_id

  ingress {
    description     = "AMQP desde core-service"
    from_port       = 5672
    to_port         = 5672
    protocol        = "tcp"
    security_groups = [aws_security_group.apprunner_core.id]
  }

  ingress {
    description     = "AMQP desde iot-service"
    from_port       = 5672
    to_port         = 5672
    protocol        = "tcp"
    security_groups = [aws_security_group.apprunner_iot.id]
  }

  ingress {
    description     = "AMQP desde workers ECS"
    from_port       = 5672
    to_port         = 5672
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_workers.id]
  }

  ingress {
    description     = "AMQP desde lambdas"
    from_port       = 5672
    to_port         = 5672
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  ingress {
    description = "Management UI dentro de la VPC"
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "SSH dentro de la VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-rabbitmq"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-sg-rds"
  description = "RDS Postgres/PostGIS - solo desde App Runner y Lambda"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres desde core-service"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.apprunner_core.id]
  }

  ingress {
    description     = "Postgres desde iot-service"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.apprunner_iot.id]
  }

  ingress {
    description     = "Postgres desde workers ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_workers.id]
  }

  ingress {
    description     = "Postgres desde lambdas"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-rds" }
}
