resource "aws_ssm_parameter" "db_master_pwd" {
  name        = "/${var.project}/${var.env}/database/master-password"
  description = "Db master password"
  type        = "SecureString"
  value       = "${var.database_master_password}"
}

resource "aws_ssm_parameter" "db_master_user" {
  name        = "/${var.project}/${var.env}/database/master-user"
  description = "Db master user"
  type        = "SecureString"
  value       = "${var.database_master_user}"
}

resource "aws_ssm_parameter" "db_user" {
  name        = "/${var.project}/${var.env}/database/user"
  description = "Db user"
  type        = "SecureString"
  value       = "${var.database_user}"
}

resource "aws_ssm_parameter" "db_pwd" {
  name        = "/${var.project}/${var.env}/database/password"
  description = "Db password"
  type        = "SecureString"
  value       = "${var.database_password}"
}