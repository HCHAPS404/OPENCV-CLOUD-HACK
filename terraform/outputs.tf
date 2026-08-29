output "core_service_url" {
  value = module.apprunner_core_service.service_url
}

output "iot_service_url" {
  value = module.apprunner_iot_service.service_url
}

output "iot_data_endpoint" {
  description = "Endpoint MQTT que deben usar los rovers/ESP32"
  value       = module.iot_core.iot_data_endpoint
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "rabbitmq_private_ip" {
  value = module.rabbitmq_ec2.private_ip
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.workers.name
}

output "timestream_database_name" {
  value = module.timestream.database_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
