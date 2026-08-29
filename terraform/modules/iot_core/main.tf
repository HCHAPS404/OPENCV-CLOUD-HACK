# --- Thing Type para los rovers ---
resource "aws_iot_thing_type" "rover" {
  name = "${var.project_name}-rover"
}

# --- Política IoT: cada rover solo puede publicar/suscribirse a su propio topic ---
resource "aws_iot_policy" "rover_policy" {
  name = "${var.project_name}-rover-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["iot:Connect"]
        Resource = "arn:aws:iot:*:*:client/$${iot:Connection.Thing.ThingName}"
      },
      {
        Effect   = "Allow"
        Action   = ["iot:Publish", "iot:Receive"]
        Resource = "arn:aws:iot:*:*:topic/rovers/$${iot:Connection.Thing.ThingName}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["iot:Subscribe"]
        Resource = "arn:aws:iot:*:*:topicfilter/rovers/$${iot:Connection.Thing.ThingName}/*"
      }
    ]
  })
}

# --- Topic Rule: reenvía telemetría MQTT -> iot-service (App Runner) vía HTTPS ---
# NOTA: la primera vez que se crea esta regla, AWS IoT envía un challenge de
# confirmación al endpoint HTTPS. El iot-service debe responder al header
# `X-Amz-IoT-Confirmation-Token` en la ruta /confirm antes de que la regla
# quede activa (documentado en el README).
resource "aws_iot_topic_rule" "telemetry_to_iot_service" {
  name        = "${replace(var.project_name, "-", "_")}_telemetry_forward"
  description = "Reenvia telemetria de rovers/+/telemetry al iot-service"
  enabled     = true
  sql         = "SELECT * FROM 'rovers/+/telemetry'"
  sql_version = "2016-03-23"

  http {
    url = var.iot_service_https_endpoint
  }

  error_action {
    cloudwatch_logs {
      log_group_name = aws_cloudwatch_log_group.iot_errors.name
      role_arn       = aws_iam_role.iot_rule_role.arn
    }
  }
}

resource "aws_cloudwatch_log_group" "iot_errors" {
  name              = "/aws/iot/${var.project_name}/rule-errors"
  retention_in_days = 30
}

resource "aws_iam_role" "iot_rule_role" {
  name = "${var.project_name}-iot-rule-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "iot.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "iot_rule_logs" {
  name = "${var.project_name}-iot-rule-logs-policy"
  role = aws_iam_role.iot_rule_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.iot_errors.arn}:*"
    }]
  })
}

data "aws_iot_endpoint" "this" {
  endpoint_type = "iot:Data-ATS"
}
