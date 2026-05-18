terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_ecr_repository" "ventas" { # Cambiado de back-ventas a ventas
    name = "${var.nombre_proyecto}-back-ventas"
    force_delete = true
}

resource "aws_ecr_repository" "despachos" { # Cambiado de back-despachos a despachos
    name = "${var.nombre_proyecto}-back-despachos"
    force_delete = true
}

resource "aws_ecr_repository" "frontend" {
    name = "${var.nombre_proyecto}-frontend"
    force_delete = true
}

resource "aws_ecs_cluster" "main_cluster" {
    name = "${var.nombre_proyecto}-cluster"
}