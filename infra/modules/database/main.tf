resource "aws_security_group" "database" {
  name        = "${var.name}-db"
  description = "PostgreSQL from the lab node security group."
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "from_nodes" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = var.node_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "PostgreSQL from lab nodes"
}

resource "aws_vpc_security_group_egress_rule" "none" {
  security_group_id = aws_security_group.database.id
  ip_protocol       = "-1"
  cidr_ipv4         = "127.0.0.1/32"
  description       = "No database egress"
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "7.2.2"

  identifier = var.name
  engine     = "postgres"
  # Pin the minor in the catalog before the saved plan. Do not float it at apply time.
  engine_version       = var.engine_version
  family               = "postgres17"
  major_engine_version = "17"
  instance_class       = var.instance_class

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "chaoslab"
  username = "chaosadmin"
  port     = 5432

  manage_master_user_password         = true
  iam_database_authentication_enabled = true
  publicly_accessible                 = false
  multi_az                            = var.multi_az
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = var.skip_final_snapshot
  backup_retention_period             = 1
  delete_automated_backups            = true
  apply_immediately                   = true
  performance_insights_enabled        = false

  db_subnet_group_name   = var.subnet_group_name
  vpc_security_group_ids = [aws_security_group.database.id]
  create_db_subnet_group = false

  tags = var.tags
}
