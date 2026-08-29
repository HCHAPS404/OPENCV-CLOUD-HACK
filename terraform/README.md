# Krop — Infraestructura AWS (Terraform)

Infraestructura modularizada para:

- **App Runner ×2**: `core-service` (Java/Spring) e `iot-service` (FastAPI)
- **ECS Fargate ×3**: `optical-worker`, `radar-worker`, `proximal-vision-worker`
- **AWS IoT Core**: broker MQTT para rovers/ESP32, con regla que reenvía telemetría a `iot-service`
- **EC2**: RabbitMQ (self-managed, Docker)
- **RDS**: PostgreSQL + PostGIS
- **Timestream**: telemetría de series de tiempo
- **S3**: imágenes satelitales
- **ECR**: un repo por servicio (core, iot, y 3 workers)
- **EventBridge**: cron diario 2 AM → Lambda `satellite-check`
- **Lambda ×2**: `satellite-check` (busca tiles nuevos y publica en RabbitMQ) y `on-demand-analysis` (con debounce de 8 días, estado guardado en una tabla del mismo RDS Postgres)
- **CloudWatch**: log groups en cada servicio
- Todo dentro de una **VPC** con subnets públicas/privadas y NAT Gateway

## Estructura

```
terraform/
├── main.tf              # conecta todos los módulos
├── variables.tf
├── outputs.tf
├── versions.tf
├── terraform.tfvars.example
├── lambda_src/
│   ├── satellite_check/handler.py
│   └── on_demand_analysis/handler.py
└── modules/
    ├── vpc/
    ├── security/          # todos los Security Groups en un solo módulo
    ├── ecr/
    ├── s3/
    ├── rds/
    ├── rabbitmq_ec2/
    ├── timestream/
    ├── iot_core/
    ├── apprunner/          # genérico, usado 2x (core-service, iot-service)
    ├── ecs_fargate_worker/ # genérico, usado 3x (los 3 workers)
    ├── lambda/             # genérico, usado 2x
    ├── eventbridge/
    └── secrets_manager/
```

## Cómo correrlo

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # completa tus valores/passwords
terraform init
terraform plan
terraform apply
```

## Cosas importantes a tener en cuenta

1. **Primer apply — ECR vacío**: los repos ECR quedan vacíos hasta que tu CI/CD (GitFlow) haga el primer `docker push`. App Runner y las tareas ECS fallarán en bucle hasta ese momento — es esperado, no un bug. Sube al menos una imagen a cada repo antes o justo después del `apply`.

2. **PostGIS + tabla de debounce**: RDS no permite crear extensiones vía Terraform. Después del primer apply, conéctate y ejecuta una vez:
   ```sql
   CREATE EXTENSION IF NOT EXISTS postgis;

   CREATE TABLE IF NOT EXISTS analysis_state (
       entity_id     TEXT PRIMARY KEY,
       last_analysis TIMESTAMPTZ NOT NULL
   );
   ```
   Esta tabla es la que usa la lambda `on-demand-analysis` para el debounce de 8 días (antes proponía DynamoDB para esto, pero no estaba en tu lista de servicios, así que quedó dentro del mismo Postgres).

3. **Confirmación del endpoint HTTPS de IoT Core**: la regla de IoT (`iot_core` módulo) reenvía telemetría al `iot-service` vía una acción HTTPS. La primera vez, AWS IoT envía un *confirmation token* a ese endpoint; `iot-service` debe implementar la ruta que responde ese challenge (`X-Amz-IoT-Confirmation-Token`) antes de que la regla quede activa. Si no la implementas, la regla se crea pero no entregará mensajes hasta que confirmes el endpoint manualmente desde la consola de IoT Core.

4. **Workers Fargate en modo "siempre prendido, procesan poco"**: dado que el procesamiento satelital dura ~1h cada ~10 días, los 3 servicios ECS quedan con `desired_count = 1` (livianos, escuchando RabbitMQ) en vez de escalar a 0/N automáticamente. Si prefieres escalar a 0 cuando no hay trabajo y activarlos solo cuando `satellite-check` publica un mensaje, se puede agregar un Application Auto Scaling con una métrica personalizada de profundidad de cola de RabbitMQ (no incluido en este esqueleto).

5. **RabbitMQ en EC2**: es self-managed (no Amazon MQ), levantado con Docker vía `user_data`. No tiene alta disponibilidad — si necesitas resiliencia real, considera un ASG con EFS para el volumen de datos, o migrar a Amazon MQ más adelante.

6. **Secrets Manager**: `db-password`, `rabbitmq-password` y `satellite-api-key` se guardan ahí. App Runner e ECS los inyectan como variables de entorno nativas (`runtime_environment_secrets` / `secrets` en la task definition) — nunca quedan hardcodeados ni en el state en texto plano dentro de los recursos de cómputo.

7. **Lambdas dentro de la VPC**: ambas lambdas tienen `vpc_config` para poder hablar con RDS/RabbitMQ (privados). Esto significa que necesitan el NAT Gateway para salir a internet (ej. `satellite-check` llamando a la API del proveedor satelital) — ya está contemplado en el módulo `vpc`.

8. **Nombre de bucket S3**: debe ser único a nivel global en AWS. Cambia `satellite_images_bucket_name` en tu `tfvars`.

## Variables sensibles

Todas las que llevan contraseñas o API keys están marcadas `sensitive = true`. Pásalas por `terraform.tfvars` (que está en `.gitignore`) o por variables de entorno `TF_VAR_db_password`, etc. — nunca las subas al repo.
