# Subredes y Grupo de Seguridad
resource "aws_dms_replication_subnet_group" "dms_subnet_group" {
  replication_subnet_group_id          = "dms-subnet-group-${var.nombre_base_app}"
  replication_subnet_group_description = "Subnet group for DMS"
  subnet_ids                           = var.subnets_ids
}

resource "aws_security_group" "dms_security_group" {
  name   = "sg-${var.nombre_base_app}-dms"
  vpc_id = var.vpc_id

  ingress {
    from_port   = var.database_port
    to_port     = var.database_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Instancia de Replicación
resource "aws_dms_replication_instance" "dms_instance" {
  replication_instance_id   = "dms-instance-${var.nombre_base_app}"
  replication_instance_class = "dms.r5.large"
  allocated_storage          = 100
  publicly_accessible        = false
  replication_subnet_group_id = aws_dms_replication_subnet_group.dms_subnet_group.replication_subnet_group_id
  vpc_security_group_ids     = [aws_security_group.dms_security_group.id]

  tags = {
    Environment = "production"
    Application = var.nombre_base_app
  }
}

#Endpoints de Origen y Destino
resource "aws_dms_endpoint" "source" {
  endpoint_id   = "source-${var.nombre_base_app}"
  endpoint_type = "source"
  engine_name   = "postgres"
  username      = var.database_user
  password      = var.database_user_pass
  database_name = var.database_name
  server_name   = var.database_host
  port          = var.database_port

  tags = {
    Environment = "production"
    Application = var.nombre_base_app
  }
}

resource "aws_dms_endpoint" "target" {
  endpoint_id   = "target-${var.nombre_base_app}"
  endpoint_type = "target"
  engine_name   = "postgres"
  username      = var.database_user
  password      = var.database_user_pass
  database_name = var.database_name
  server_name   = var.database_host
  port          = var.database_port

  tags = {
    Environment = "production"
    Application = var.nombre_base_app
  }
}

#Tarea de Replicación
resource "aws_dms_task" "dms_task" {
  replication_task_id      = "dms-task-${var.nombre_base_app}"
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target.endpoint_arn
  replication_instance_arn = aws_dms_replication_instance.dms_instance.replication_instance_arn
  migration_type           = "full-load"

  table_mappings = <<EOT
  {
      "rules": [
          {
              "rule-type": "selection",
              "rule-id": "1",
              "rule-name": "include-tableA",
              "object-locator": {
                  "schema-name": "esquema",
                  "table-name": "tablaA"
              },
              "rule-action": "include"
          },
          {
              "rule-type": "transformation",
              "rule-id": "map-partition-01",
              "rule-name": "map-to-partition-01",
              "rule-target": "table",
              "object-locator": {
                  "schema-name": "esquema",
                  "table-name": "tablaA"
              },
              "value": "tablaB_particion_01"
          },
          {
              "rule-type": "transformation",
              "rule-id": "map-partition-02",
              "rule-name": "map-to-partition-02",
              "rule-target": "table",
              "object-locator": {
                  "schema-name": "esquema",
                  "table-name": "tablaA"
              },
              "value": "tablaB_particion_02"
          }
          // Repite para las demás particiones...
      ]
  }
  EOT

  task_settings = jsonencode({
    FullLoadSettings = {
      ParallelLoadThreads = 16
      ParallelApplyThreads = 8
      MaxFileSize = 10240  # 10 GB
    }
    Logging = {
      EnableLogging = true
    }
  })

  tags = {
    Environment = "production"
    Application = var.nombre_base_app
  }
}

#CloudWatch Logs
resource "aws_cloudwatch_log_group" "dms_logs" {
  name              = "/aws/dms/${aws_dms_replication_instance.dms_instance.replication_instance_id}"
  retention_in_days = 7

  tags = {
    Environment = "production"
    Application = var.nombre_base_app
  }
}
