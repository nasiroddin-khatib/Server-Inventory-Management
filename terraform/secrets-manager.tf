# ==========================================================
# DATABASE SECRET
# ==========================================================

resource "aws_secretsmanager_secret" "database_secret" {

  name = var.db_secret_name

  description = "PostgreSQL Database Credentials"

  tags = {

    Name        = var.db_secret_name
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Terraform"

  }

}

# ==========================================================
# DATABASE SECRET VALUE
# ==========================================================

resource "aws_secretsmanager_secret_version" "database_secret_value" {

  secret_id = aws_secretsmanager_secret.database_secret.id

  secret_string = jsonencode({

    username = var.db_username

    password = var.db_password

  })

}
