output "apprunner_core_sg_id" { value = aws_security_group.apprunner_core.id }
output "apprunner_iot_sg_id" { value = aws_security_group.apprunner_iot.id }
output "ecs_workers_sg_id" { value = aws_security_group.ecs_workers.id }
output "lambda_sg_id" { value = aws_security_group.lambda.id }
output "rds_sg_id" { value = aws_security_group.rds.id }
output "rabbitmq_sg_id" { value = aws_security_group.rabbitmq.id }
