resource "aws_ssm_parameter" "database_url" {
  name  = "/${var.project_name}/${var.environment}/database_url"
  type  = "SecureString"
  value = "postgresql://${var.db_username}@${aws_db_instance.main.address}:5432/${var.db_name}"

  tags = {
    Name = "${var.project_name}-database-url"
  }
}

resource "aws_ssm_parameter" "s3_assets_bucket" {
  name  = "/${var.project_name}/${var.environment}/s3_assets_bucket"
  type  = "String"
  value = aws_s3_bucket.assets.bucket
}
