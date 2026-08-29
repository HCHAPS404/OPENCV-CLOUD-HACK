resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "${var.project_name}-db-subnet-group" }
}

#Dato y es que esto no instala postgis automaticamente, hay que instalarlo manualmente en la base de datos una vez creada.
resource "aws_db_instance" "postgis" {
  identifier     = "${var.project_name}-postgis"
  engine         = "postgres"
  engine_version = var.engine_version # 16.4 por defecto

  instance_class    = var.instance_class # 'db.t3.micro' por defecto
  allocated_storage = var.allocated_storage # 20 (GB) por defecto
  storage_type      = "gp3" # gp3 significa SSD de propósito general, más rápido y más barato que gp2
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]

  multi_az                = false
  publicly_accessible     = false
  backup_retention_period = 7 # Backups automáticos durante 7 días
  skip_final_snapshot     = true # Para el snapshot final, aqui se omite
  deletion_protection     = false # quita la protección de borrado

  tags = { Name = "${var.project_name}-postgis" }
}
