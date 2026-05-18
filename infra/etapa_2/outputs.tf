# IP de la base de datos (esta sí es fija mientras no destruyas la EC2)
output "mysql_public_ip" {
  value = aws_instance.db.public_ip
}

# URLs de los Repositorios ECR para el Pipeline
output "ecr_ventas_url" {
  value = aws_ecr_repository.back-ventas.repository_url
}

output "ecr_despachos_url" {
  value = aws_ecr_repository.back-despachos.repository_url
}

output "ecr_frontend_url" {
  value = aws_ecr_repository.frontend.repository_url
}
