resource "aws_cloudwatch_event_rule" "daily_satellite_check" {
  name                = "${var.project_name}-daily-satellite-check"
  description         = "Dispara satellite-check todos los días a las 2 AM UTC"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_satellite_check.name
  target_id = "${var.project_name}-satellite-check-target"
  arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_satellite_check.arn
}
