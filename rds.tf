# ==========================================================
# DB SUBNET GROUP
# ==========================================================

resource "aws_db_subnet_group" "db_subnet_group" {

  name = "server-inventory-db-subnet-group"

  subnet_ids = [

    aws_subnet.private_subnet_1.id,

    aws_subnet.private_subnet_2.id

  ]

  tags = {

    Name = "server-inventory-db-subnet-group"

    Project = "Server-Inventory"

    Environment = "Production"

    ManagedBy = "Terraform"

  }

}

# ==========================================================
# RDS PostgreSQL
# ==========================================================

resource "aws_db_instance" "postgres" {

  identifier = var.db_instance_identifier

  engine = "postgres"

  engine_version = var.db_engine_version

  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage

  storage_type = var.db_storage_type

  storage_encrypted = true

  db_name = var.db_name

  username = var.db_username

  password = var.db_password

  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name

  vpc_security_group_ids = [

    aws_security_group.rds_sg.id

  ]

  publicly_accessible = false

  multi_az = false

  deletion_protection = false

  skip_final_snapshot = true

  backup_retention_period = 7

  auto_minor_version_upgrade = true

  apply_immediately = true

  tags = {

    Name = var.db_instance_identifier

    Project = "Server-Inventory"

    Environment = "Production"

    ManagedBy = "Terraform"

  }

}
