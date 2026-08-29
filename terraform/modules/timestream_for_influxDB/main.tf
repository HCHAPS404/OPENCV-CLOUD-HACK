resource "aws_timestreaminfluxdb_db_instance" "this" {
  name              = "${var.project_name}-influxdb"
  username          = var.username
  password          = var.password
  organization      = var.organization
  bucket            = var.bucket
  db_instance_type  = var.db_instance_type
  allocated_storage = var.allocated_storage

  vpc_subnet_ids          = var.vpc_subnet_ids
  vpc_security_group_ids  = var.vpc_security_group_ids
  publicly_accessible     = var.publicly_accessible

  s3_configuration {
    bucket_name = var.log_bucket_name
    enabled     = true
  }

  tags = {
    Name = "${var.project_name}-influxdb"
  }
}
