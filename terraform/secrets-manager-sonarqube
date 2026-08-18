# ============================================================
# SonarQube Database Secret
# ============================================================

resource "aws_secretsmanager_secret" "sonarqube_database" {
  name        = "server-inventory/sonarqube/database"
  description = "SonarQube PostgreSQL database credentials"

  tags = {
    Name      = "server-inventory-sonarqube-database"
    Project   = "Server-Inventory"
    ManagedBy = "Terraform"
  }
}
