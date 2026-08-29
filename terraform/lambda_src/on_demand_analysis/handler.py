"""
on-demand-analysis
Invocada bajo demanda (ej. desde iot-service o core-service).
Aplica un debounce: si ya se analizó la misma entidad (parcela/campo) hace
menos de ANALYSIS_DEBOUNCE_DAYS días, no vuelve a analizar.

El estado del último análisis se guarda en una tabla dentro del mismo
RDS Postgres (no se usa ningún servicio adicional para esto).

Requiere agregar `psycopg2-binary` como dependencia empaquetada junto al
handler (ej. vía Lambda Layer o incluida en el zip de build).

Tabla esperada (crear una vez, junto con la extensión postgis):

    CREATE TABLE IF NOT EXISTS analysis_state (
        entity_id      TEXT PRIMARY KEY,
        last_analysis  TIMESTAMPTZ NOT NULL
    );
"""
import json
import os
import datetime
import boto3
import psycopg2

DB_HOST = os.environ.get("DB_HOST")
DB_PORT = os.environ.get("DB_PORT", "5432")
DB_NAME = os.environ.get("DB_NAME")
DB_USER = os.environ.get("POSTGRES_USER")
DB_PASSWORD_SECRET_ARN = os.environ.get("DB_PASSWORD_SECRET_ARN")
DEBOUNCE_DAYS = int(os.environ.get("ANALYSIS_DEBOUNCE_DAYS", "8"))

secrets_client = boto3.client("secretsmanager")


def get_db_password():
    return secrets_client.get_secret_value(SecretId=DB_PASSWORD_SECRET_ARN)["SecretString"]


def get_connection():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=get_db_password(),
    )


def lambda_handler(event, context):
    entity_id = event.get("entity_id")
    if not entity_id:
        return {"statusCode": 400, "body": json.dumps({"error": "entity_id requerido"})}

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT last_analysis FROM analysis_state WHERE entity_id = %s",
                (entity_id,),
            )
            row = cur.fetchone()

            now = datetime.datetime.now(datetime.timezone.utc)
            if row:
                last_analysis = row[0]
                elapsed_days = (now - last_analysis).total_seconds() / 86400
                if elapsed_days < DEBOUNCE_DAYS:
                    return {
                        "statusCode": 429,
                        "body": json.dumps({
                            "message": f"Ya se analizó hace {elapsed_days:.1f} días; "
                                       f"espera a completar {DEBOUNCE_DAYS} días.",
                        }),
                    }

            # TODO: lógica real de análisis (leer PostGIS/Timestream/S3, generar resultado)

            cur.execute(
                """
                INSERT INTO analysis_state (entity_id, last_analysis)
                VALUES (%s, %s)
                ON CONFLICT (entity_id) DO UPDATE SET last_analysis = EXCLUDED.last_analysis
                """,
                (entity_id, now),
            )
            conn.commit()
    finally:
        conn.close()

    return {"statusCode": 200, "body": json.dumps({"message": "Análisis ejecutado"})}
