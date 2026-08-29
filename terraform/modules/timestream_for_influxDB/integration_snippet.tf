# # ---------------------------------------------------------------------------
# # TIMESTREAM FOR INFLUXDB (reemplazo de LiveAnalytics, cerrado a cuentas nuevas)
# # ---------------------------------------------------------------------------
# module "timestream_influxdb" {
#   source                  = "./modules/timestream_influxdb"
#   project_name            = var.project_name
#   username                = "admin"
#   password                = var.rabbitmq_password # o crea var.influxdb_password dedicada
#   organization            = "krop"
#   bucket                  = "rover_telemetry"
#   vpc_subnet_ids          = module.vpc.private_subnet_ids
#   vpc_security_group_ids  = [module.security.timestream_sg_id] # crea este SG en tu módulo security
#   log_bucket_name         = module.s3.bucket_name              # reusa tu bucket existente
# }

# # --- En apprunner_iot_service, reemplaza las env vars TIMESTREAM_DB/TABLE por: ---
# #   INFLUXDB_URL          = "https://${module.timestream_influxdb.instance_endpoint}"
# #   INFLUXDB_ORG          = "krop"
# #   INFLUXDB_BUCKET       = "rover_telemetry"
# #
# # --- Y agrega a environment_secrets: ---
# #   INFLUXDB_TOKEN_SECRET_ARN = module.timestream_influxdb.influx_auth_parameters_secret_arn
# #
# # --- Agrega este permiso a extra_instance_policy_statements: ---
# #   {
# #     Effect   = "Allow"
# #     Action   = ["secretsmanager:GetSecretValue"]
# #     Resource = [module.timestream_influxdb.influx_auth_parameters_secret_arn]
# #   }

# # --- Output nuevo en outputs.tf raíz: ---
# # output "influxdb_endpoint" {
# #   value = module.timestream_influxdb.instance_endpoint
# # }
