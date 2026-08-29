"""
satellite-check
Disparada por EventBridge todos los días a las 2 AM.
Consulta al proveedor satelital por tiles nuevos y, si encuentra,
publica un mensaje en RabbitMQ para que los workers Fargate
(optical / radar / proximal-vision) lo procesen.

Reemplazar la lógica de negocio real; esto es un esqueleto funcional.
"""
import json
import os
import boto3

RABBITMQ_HOST = os.environ.get("RABBITMQ_HOST")
RABBITMQ_SECRET_ARN = os.environ.get("RABBITMQ_SECRET_ARN")
SATELLITE_API_URL = os.environ.get("SATELLITE_API_URL")
SATELLITE_API_KEY_SECRET_ARN = os.environ.get("SATELLITE_API_KEY_SECRET_ARN")

secrets_client = boto3.client("secretsmanager")


def get_secret(secret_arn):
    if not secret_arn:
        return None
    return secrets_client.get_secret_value(SecretId=secret_arn)["SecretString"]


def lambda_handler(event, context):
    rabbitmq_password = get_secret(RABBITMQ_SECRET_ARN)
    satellite_api_key = get_secret(SATELLITE_API_KEY_SECRET_ARN)

    # TODO: llamar a SATELLITE_API_URL con satellite_api_key,
    # comparar con la última imagen ya obtenida (guardar cursor en DynamoDB/S3),
    # y si hay tiles nuevos, publicar en RabbitMQ (routing keys:
    # "tiles.optical", "tiles.radar") usando pika o kombu.

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "satellite-check ejecutado"}),
    }
