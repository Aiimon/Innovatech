# 1. Entrega la URL del repositorio de Ventas para el Pipeline
output "url_ecr_ventas" {
  value       = aws_ecr_repository.ventas.repository_url
  description = "URL del repositorio ECR para el microservicio de Ventas"
}

# 2. Entrega la URL del repositorio de Despachos para el Pipeline
output "url_ecr_despachos" {
  value       = aws_ecr_repository.despachos.repository_url
  description = "URL del repositorio ECR para el microservicio de Despachos"
}

# 3. Entrega la URL del repositorio del Frontend para el Pipeline
output "url_ecr_frontend" {
  value       = aws_ecr_repository.frontend.repository_url
  description = "URL del repositorio ECR para el Frontend"
}

# 4. Entrega el nombre del cluster para usarlo en el archivo cd.yml
output "nombre_cluster_ecs" {
  value       = aws_ecs_cluster.main_cluster.name
  description = "Nombre del cluster ECS creado en la region seleccionada"
}
