terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

############################
# 1. RED (VPC y Conectividad)
############################

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

############################
# 2. SEGURIDAD (Firewall)
############################

resource "aws_security_group" "main" {
  name   = "${var.project_name}-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Acceso Web (Rango para Frontend 8000 y Backends 8080/8081)
  ingress {
    from_port   = 8000
    to_port     = 8081
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

resource "aws_security_group_rule" "mysql_internal" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.main.id
  source_security_group_id = aws_security_group.main.id
}

############################
# 3. REPOSITORIOS ECR
############################

resource "aws_ecr_repository" "back-ventas" {
  name         = "${var.project_name}-back-ventas"
  force_delete = true
}

resource "aws_ecr_repository" "back-despachos" {
  name         = "${var.project_name}-back-despachos"
  force_delete = true
}

resource "aws_ecr_repository" "frontend" {
  name         = "${var.project_name}-frontend"
  force_delete = true
}

############################
# 4. BASE DE DATOS (EC2)
############################

resource "aws_instance" "db" {
  ami                    = "ami-05b10e08d247fb927" 
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name               = var.key_pair_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    docker run -d --name mysql \
      -e MYSQL_ROOT_PASSWORD=${var.db_password} \
      -e MYSQL_DATABASE=${var.db_name} \
      -p 3306:3306 mysql:8 --bind-address=0.0.0.0
  EOF

  tags = { Name = "${var.project_name}-db" }
}

############################
# 5. ECS FARGATE
############################

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

data "aws_iam_role" "lab" {
  name = "LabRole"
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = data.aws_iam_role.lab.arn

  container_definitions = jsonencode([
    {
      name  = "back-ventas"
      image = "${aws_ecr_repository.back-ventas.repository_url}:latest"
      portMappings = [{ containerPort = 8080 }]
      
      # Espera activa: No levanta Spring Boot hasta que el puerto 3306 de la EC2 responda
      command = ["sh", "-c", "until nc -z ${aws_instance.db.private_ip} 3306; do echo 'Esperando MySQL...'; sleep 3; done; java -jar app.jar"]
      
      # CORREGIDO: Mapeo exacto de variables personalizadas para back-ventas
      environment = [
        { name = "DB_ENDPOINT", value = aws_instance.db.private_ip },
        { name = "DB_PORT",     value = "3306" },
        { name = "DB_NAME",     value = var.db_name },
        { name = "DB_USERNAME", value = var.db_user },
        { name = "DB_PASSWORD", value = var.db_password }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ventas"
        }
      }
    },
    {
      name  = "back-despachos"
      image = "${aws_ecr_repository.back-despachos.repository_url}:latest"
      portMappings = [{ containerPort = 8081 }]
      
      # Espera activa: No levanta Spring Boot hasta que el puerto 3306 de la EC2 responda
      command = ["sh", "-c", "until nc -z ${aws_instance.db.private_ip} 3306; do echo 'Esperando MySQL...'; sleep 3; done; java -jar app.jar"]
      
      # CORREGIDO: Mapeo exacto de variables personalizadas para back-despachos
      environment = [
        { name = "DB_ENDPOINT", value = aws_instance.db.private_ip },
        { name = "DB_PORT",     value = "3306" },
        { name = "DB_NAME",     value = var.db_name },
        { name = "DB_USERNAME", value = var.db_user },
        { name = "DB_PASSWORD", value = var.db_password }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "despachos"
        }
      }
    },
    {
      name  = "frontend"
      image = "${aws_ecr_repository.frontend.repository_url}:latest"
      
      # LIMPIO: Sin commands parches. Nginx arranca nativo usando el nuevo nginx.conf y Dockerfile
      
      portMappings = [{ 
        containerPort = 8000 
        hostPort      = 8000 
      }]
      
      dependsOn = [
        { containerName = "back-ventas", condition = "START" },
        { containerName = "back-despachos", condition = "START" }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "frontend"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "app" {
  name                              = "app-service"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.app.arn
  launch_type                       = "FARGATE"
  desired_count                     = 1
  health_check_grace_period_seconds = 180

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.main.id]
    assign_public_ip = true
  }
}