resource "random_password" "db" {
  length  = 32
  special = false # avoid characters that need extra escaping in connection strings
}

resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.project_name}/rds/master-password"
  description = "Master password for the ShopZone RDS instance"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db.result
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = var.db_engine_version

  # Sized and resized deliberately, by hand, rather than auto-scaled compute —
  # relational data benefits from controlled change management even though
  # the application layer above it scales freely.
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage # storage autoscaling IS enabled
  storage_type           = "gp3"
  storage_encrypted      = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  # Multi-AZ: a synchronously replicated standby in the second AZ, protecting
  # order and product data specifically during high-demand periods.
  multi_az = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = var.db_backup_retention_days
  backup_window           = "03:00-04:00" # low-traffic window, UTC
  maintenance_window      = "sun:04:30-sun:05:30"

  deletion_protection      = true
  skip_final_snapshot      = false
  final_snapshot_identifier = "${var.project_name}-db-final-snapshot"

  performance_insights_enabled = true

  tags = {
    Name = "${var.project_name}-db"
  }
}
