FROM maven:3.9-eclipse-temurin-21 AS builder

WORKDIR /build

# 1. Copiamos el archivo de configuración de dependencias
COPY pom.xml .

# 2. Copiamos el código fuente
COPY src ./src

# 3. COMPILACIÓN: Usamos 'mvn' directamente
RUN mvn clean package -DskipTests

FROM eclipse-temurin:21-jdk AS runner

WORKDIR /app

RUN useradd -m duocuser
USER duocuser

# Copiamos el artefacto generado en la etapa anterior
COPY --from=builder /build/target/*.jar app.jar

# Puerto específico de Despachos según tu docker-compose
EXPOSE 8081

ENTRYPOINT [ "java", "-Dspring.datasource.url=${SPRING_DATASOURCE_URL}", "-Dspring.datasource.username=${SPRING_DATASOURCE_USERNAME}", "-Dspring.datasource.password=${SPRING_DATASOURCE_PASSWORD}", "-jar", "app.jar" ]