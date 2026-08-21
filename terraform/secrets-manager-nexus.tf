############################################
# Nexus Credentials Secret
############################################

resource "aws_secretsmanager_secret" "nexus_credentials" {

  name        = var.nexus_secret_name
  description = "Credentials used by Jenkins to deploy artifacts to Nexus"

  tags = {
    Name        = var.nexus_secret_name
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
