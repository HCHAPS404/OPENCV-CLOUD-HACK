resource "aws_timestreamwrite_database" "telemetry" {
  database_name = "${replace(var.project_name, "-", "_")}_rover_telemetry"

  tags = { Name = "${var.project_name}-timestream-db" }
}

resource "aws_timestreamwrite_table" "rover_telemetry" {
  database_name = aws_timestreamwrite_database.telemetry.database_name
  table_name    = "rover_telemetry"

  retention_properties {
    memory_store_retention_period_in_hours  = 24
    magnetic_store_retention_period_in_days = 365
  }

  tags = { Name = "${var.project_name}-rover-telemetry-table" }
}
