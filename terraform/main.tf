locals {
  common_ecr_repos = [
    "core-service",
    "iot-service",
    "optical-worker",
    "radar-worker",
    "proximal-vision-worker",
  ]
}

# ---------------------------------------------------------------------------
# Red
# ---------------------------------------------------------------------------
module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  region       = var.aws_region
}

module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr
}

# ---------------------------------------------------------------------------
# Secretos (valores planos vienen de variables sensibles pasadas por el usuario)
# ---------------------------------------------------------------------------
module "secrets_manager" {
  source       = "./modules/secrets_manager"
  project_name = var.project_name
  secrets = {
    db-password        = var.db_password
    rabbitmq-password  = var.rabbitmq_password
    satellite-api-key  = var.satellite_api_key != "" ? var.satellite_api_key : "changeme"
  }
}

# ---------------------------------------------------------------------------
# Almacenamiento / Datos
# ---------------------------------------------------------------------------
module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
  repo_names   = local.common_ecr_repos
}

module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
  bucket_name  = var.satellite_images_bucket_name
}

module "rds" {
  source             = "./modules/rds"
  project_name       = var.project_name
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security.rds_sg_id
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  instance_class     = var.rds_instance_class
}

module "rabbitmq_ec2" {
  source             = "./modules/rabbitmq_ec2"
  project_name       = var.project_name
  private_subnet_id  = module.vpc.private_subnet_ids[0]
  security_group_id  = module.security.rabbitmq_sg_id
  instance_type      = var.rabbitmq_instance_type
  rabbitmq_user      = var.rabbitmq_user
  rabbitmq_password  = var.rabbitmq_password
  key_pair_name      = var.rabbitmq_key_pair_name
}

module "timestream" {
  source       = "./modules/timestream"
  project_name = var.project_name
}

# ---------------------------------------------------------------------------
# App Runner: core-service (Java/Spring) e iot-service (FastAPI)
# ---------------------------------------------------------------------------
module "apprunner_core_service" {
  source                            = "./modules/apprunner"
  project_name                      = var.project_name
  service_name                      = "core-service"
  ecr_repository_url                = module.ecr.repository_urls["core-service"]
  image_tag                         = var.image_tag
  port                              = var.core_service_port
  vpc_connector_subnet_ids          = module.vpc.private_subnet_ids
  vpc_connector_security_group_ids  = [module.security.apprunner_core_sg_id]
  secrets_manager_arns              = [module.secrets_manager.secret_arns["db-password"]]

  environment_variables = {
    R2DBC_URL     = "r2dbc:postgresql://${var.db_username}@${module.rds.endpoint}:${module.rds.port}/${module.rds.db_name}"
    POSTGRES_USER = var.db_username
    DB_HOST       = module.rds.endpoint
    DB_PORT       = tostring(module.rds.port)
    DB_NAME       = module.rds.db_name
    S3_BUCKET     = module.s3.bucket_name
    AWS_REGION    = var.aws_region
  }

  environment_secrets = {
    POSTGRES_PASSWORD = module.secrets_manager.secret_arns["db-password"]
  }

  extra_instance_policy_statements = [
    {
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      Resource = [module.s3.bucket_arn, "${module.s3.bucket_arn}/*"]
    }
  ]
}

module "apprunner_iot_service" {
  source                            = "./modules/apprunner"
  project_name                      = var.project_name
  service_name                      = "iot-service"
  ecr_repository_url                = module.ecr.repository_urls["iot-service"]
  image_tag                         = var.image_tag
  port                              = var.iot_service_port
  vpc_connector_subnet_ids          = module.vpc.private_subnet_ids
  vpc_connector_security_group_ids  = [module.security.apprunner_iot_sg_id]
  secrets_manager_arns = [
    module.secrets_manager.secret_arns["db-password"],
    module.secrets_manager.secret_arns["rabbitmq-password"],
  ]

  environment_variables = {
    DB_HOST                = module.rds.endpoint
    DB_PORT                = tostring(module.rds.port)
    DB_NAME                = module.rds.db_name
    POSTGRES_USER          = var.db_username
    RABBITMQ_HOST          = module.rabbitmq_ec2.private_ip
    RABBITMQ_PORT          = "5672"
    RABBITMQ_USER          = var.rabbitmq_user
    S3_BUCKET              = module.s3.bucket_name
    AWS_REGION             = var.aws_region
    TIMESTREAM_DB          = module.timestream.database_name
    TIMESTREAM_TABLE       = module.timestream.table_name
  }

  environment_secrets = {
    POSTGRES_PASSWORD  = module.secrets_manager.secret_arns["db-password"]
    RABBITMQ_PASSWORD  = module.secrets_manager.secret_arns["rabbitmq-password"]
  }

  extra_instance_policy_statements = [
  {
    Effect   = "Allow"
    Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    Resource = [
      module.s3.bucket_arn,
      "${module.s3.bucket_arn}/*"
    ]
  },
  {
    Effect   = "Allow"
    Action   = ["timestream:WriteRecords", "timestream:DescribeEndpoints"]
    Resource = [
      module.timestream.table_arn,
      module.timestream.database_arn
    ]
  },
  {
    Effect   = "Allow"
    Action   = ["iot:Publish", "iot:Connect"]
    Resource = ["*"]
  }
]

}

# ---------------------------------------------------------------------------
# AWS IoT Core (rovers/ESP32) — depende de la URL del iot-service
# ---------------------------------------------------------------------------
module "iot_core" {
  source                      = "./modules/iot_core"
  project_name                = var.project_name
  iot_service_https_endpoint  = "${module.apprunner_iot_service.service_url}/telemetry"
}

# ---------------------------------------------------------------------------
# ECS Fargate: cluster + 3 workers de procesamiento satelital
# ---------------------------------------------------------------------------
resource "aws_ecs_cluster" "workers" {
  name = "${var.project_name}-workers-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "${var.project_name}-workers-cluster" }
}

resource "aws_ecs_cluster_capacity_providers" "workers" {
  cluster_name       = aws_ecs_cluster.workers.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

locals {
  worker_common_env = {
    DB_HOST       = module.rds.endpoint
    DB_PORT       = tostring(module.rds.port)
    DB_NAME       = module.rds.db_name
    POSTGRES_USER = var.db_username
    RABBITMQ_HOST = module.rabbitmq_ec2.private_ip
    RABBITMQ_PORT = "5672"
    RABBITMQ_USER = var.rabbitmq_user
    S3_BUCKET     = module.s3.bucket_name
    AWS_REGION    = var.aws_region
  }

  worker_common_secrets = {
    POSTGRES_PASSWORD = module.secrets_manager.secret_arns["db-password"]
    RABBITMQ_PASSWORD = module.secrets_manager.secret_arns["rabbitmq-password"]
  }

  worker_secrets_manager_arns = [
    module.secrets_manager.secret_arns["db-password"],
    module.secrets_manager.secret_arns["rabbitmq-password"],
  ]
}

module "worker_optical" {
  source                = "./modules/ecs_fargate_worker"
  project_name          = var.project_name
  worker_name           = "optical-worker"
  cluster_id            = aws_ecs_cluster.workers.id
  cluster_name          = aws_ecs_cluster.workers.name
  ecr_repository_url    = module.ecr.repository_urls["optical-worker"]
  image_tag             = var.image_tag
  private_subnet_ids    = module.vpc.private_subnet_ids
  security_group_id     = module.security.ecs_workers_sg_id
  environment_variables = local.worker_common_env
  secrets               = local.worker_common_secrets
  secrets_manager_arns  = local.worker_secrets_manager_arns
  s3_bucket_arn         = module.s3.bucket_arn
}

module "worker_radar" {
  source                = "./modules/ecs_fargate_worker"
  project_name          = var.project_name
  worker_name           = "radar-worker"
  cluster_id            = aws_ecs_cluster.workers.id
  cluster_name          = aws_ecs_cluster.workers.name
  ecr_repository_url    = module.ecr.repository_urls["radar-worker"]
  image_tag             = var.image_tag
  private_subnet_ids    = module.vpc.private_subnet_ids
  security_group_id     = module.security.ecs_workers_sg_id
  environment_variables = local.worker_common_env
  secrets               = local.worker_common_secrets
  secrets_manager_arns  = local.worker_secrets_manager_arns
  s3_bucket_arn         = module.s3.bucket_arn
}

module "worker_proximal_vision" {
  source                = "./modules/ecs_fargate_worker"
  project_name          = var.project_name
  worker_name           = "proximal-vision-worker"
  cluster_id            = aws_ecs_cluster.workers.id
  cluster_name          = aws_ecs_cluster.workers.name
  ecr_repository_url    = module.ecr.repository_urls["proximal-vision-worker"]
  image_tag             = var.image_tag
  private_subnet_ids    = module.vpc.private_subnet_ids
  security_group_id     = module.security.ecs_workers_sg_id
  environment_variables = local.worker_common_env
  secrets               = local.worker_common_secrets
  secrets_manager_arns  = local.worker_secrets_manager_arns
  s3_bucket_arn         = module.s3.bucket_arn
}

# ---------------------------------------------------------------------------
# Lambdas + EventBridge (cron diario 2 AM) + análisis on-demand
# ---------------------------------------------------------------------------
module "lambda_satellite_check" {
  source         = "./modules/lambda"
  project_name   = var.project_name
  function_name  = "satellite-check"
  source_dir     = "${path.module}/lambda_src/satellite_check"
  timeout        = 120
  memory_size    = 256
  vpc_subnet_ids          = module.vpc.private_subnet_ids
  vpc_security_group_ids  = [module.security.lambda_sg_id]

  environment_variables = {
    RABBITMQ_HOST                 = module.rabbitmq_ec2.private_ip
    RABBITMQ_PORT                 = "5672"
    RABBITMQ_USER                 = var.rabbitmq_user
    RABBITMQ_SECRET_ARN           = module.secrets_manager.secret_arns["rabbitmq-password"]
    SATELLITE_API_URL             = var.satellite_api_url
    SATELLITE_API_KEY_SECRET_ARN  = module.secrets_manager.secret_arns["satellite-api-key"]
  }

  extra_policy_statements = [
    {
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [
        module.secrets_manager.secret_arns["rabbitmq-password"],
        module.secrets_manager.secret_arns["satellite-api-key"],
      ]
    }
  ]
}

module "eventbridge_satellite_check" {
  source                = "./modules/eventbridge"
  project_name          = var.project_name
  lambda_function_name  = module.lambda_satellite_check.function_name
  lambda_function_arn   = module.lambda_satellite_check.function_arn
  schedule_expression   = "cron(0 2 * * ? *)"
}

module "lambda_on_demand_analysis" {
  source         = "./modules/lambda"
  project_name   = var.project_name
  function_name  = "on-demand-analysis"
  source_dir     = "${path.module}/lambda_src/on_demand_analysis"
  timeout        = 60
  memory_size    = 256
  vpc_subnet_ids          = module.vpc.private_subnet_ids
  vpc_security_group_ids  = [module.security.lambda_sg_id]

  environment_variables = {
    ANALYSIS_DEBOUNCE_DAYS  = tostring(var.analysis_debounce_days)
    DB_HOST                 = module.rds.endpoint
    DB_PORT                 = tostring(module.rds.port)
    DB_NAME                 = module.rds.db_name
    POSTGRES_USER           = var.db_username
    DB_PASSWORD_SECRET_ARN  = module.secrets_manager.secret_arns["db-password"]
  }

  extra_policy_statements = [
    {
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [module.secrets_manager.secret_arns["db-password"]]
    }
  ]
}
