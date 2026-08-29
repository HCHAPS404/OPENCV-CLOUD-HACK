resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.project_name}/${var.worker_name}"
  retention_in_days = 30
}

resource "aws_iam_role" "execution_role" {
  name = "${var.project_name}-${var.worker_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution_role_managed" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_role_secrets" {
  count = length(var.secrets_manager_arns) > 0 ? 1 : 0
  name  = "${var.project_name}-${var.worker_name}-secrets-policy"
  role  = aws_iam_role.execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = var.secrets_manager_arns
    }]
  })
}

resource "aws_iam_role" "task_role" {
  name = "${var.project_name}-${var.worker_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "task_role_s3" {
  name = "${var.project_name}-${var.worker_name}-s3-policy"
  role = aws_iam_role.task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      Resource = [var.s3_bucket_arn, "${var.s3_bucket_arn}/*"]
    }]
  })
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project_name}-${var.worker_name}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = var.worker_name
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true
      environment = [
        for k, v in var.environment_variables : { name = k, value = v }
      ]
      secrets = [
        for k, arn in var.secrets : { name = k, valueFrom = arn }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = var.worker_name
        }
      }
    }
  ])

  tags = { Name = "${var.project_name}-${var.worker_name}" }
}

data "aws_region" "current" {}

resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-${var.worker_name}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = false
  }

  tags = { Name = "${var.project_name}-${var.worker_name}" }
}
