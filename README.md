# Innovatech - Cloud Infrastructure & CI/CD Pipeline

**Descripción** Infraestructura serverless administrada en AWS y automatizada mediante GitHub Actions para desplegar la plataforma unificada **Innovatech**, la cual está compuesta por un Frontend en React/Vite y dos microservicios en Spring Boot independientes que se conectan a una base de datos relacional.

El proyecto implementa un flujo completo de **Integración Continua (CI)** y **Despliegue Continuo (CD)**, empaquetando cada componente en contenedores Docker y orquestándolos en la nube sin necesidad de administrar servidores físicos.

---

## 🧭 Estructura del Proyecto
innovatech-project/
├── .github/
│   └── workflows/
│       ├── ci.yml             # Pipeline de Integración Continua (Validación)
│       └── cd.yml             # Pipeline de Despliegue Continuo (Producción AWS)
├── back-ventas/               # Microservicio de Ventas (Java / Spring Boot)
│   ├── Springboot-API-REST/
│   └── Dockerfile
├── back-despachos/            # Microservicio de Despachos (Java / Spring Boot)
│   ├── Springboot-API-REST-DESPACHO/
│   └── Dockerfile
├── front_despacho/            # Interfaz de Usuario (Node.js / React)
│   └── Dockerfile
├── docker-compose.yml         # Orquestación para Entorno de Desarrollo Local
└── README.md

## 🚀 Requisitos

- **Entorno Local:** Docker Desktop & Docker Compose para ejecución local.
- **Pipeline:** Cuenta de GitHub con secretos de repositorio configurados (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`).
- **Nube:** Cuenta de AWS Academy con servicios ECS Fargate y Elastic Container Registry (ECR) habilitados.

---

## ⚙️ Flujo de Trabajo (GitFlow & DevOps)

El proyecto mitiga errores en producción dividiendo el ciclo de vida del software en dos etapas automatizadas:

### 1. Integración Continua (CI) - Rama `develop`
Cada vez que el equipo de ingeniería sube cambios a la rama `develop`, se dispara el archivo `ci.yml` en GitHub Actions, el cual ejecuta:
* Validación estática del Frontend.
* Compilación aislada y testeo del backend de Ventas.
* Compilación aislada y testeo del backend de Despachos.

### 2. Despliegue Continuo (CD) - Rama `main`
Al realizar un merge exitoso hacia `main`, el pipeline `cd.yml` toma el control de forma autónoma:
* Autentica de forma segura la máquina virtual de GitHub en AWS.
* Inicia sesión en **Amazon ECR**.
* Construye las imágenes Docker con arquitectura de producción (`linux/amd64`) inyectando parámetros de red locales (`127.0.0.1`) mediante `--build-arg`.
* Sube las imágenes con el tag `:latest` a sus respectivos repositorios ECR.
* Ejecuta un `--force-new-deployment` en **AWS ECS Fargate**, refrescando los contenedores en caliente sin caída de servicio.

---

## 📦 Arquitectura de Contenedores

La aplicación se compone de 4 contenedores estrechamente acoplados bajo una red unificada:

| Servicio | Tecnología | Puerto Interno | Puerto Externo | Rol en la Arquitectura |
| :--- | :--- | :--- | :--- | :--- |
| **frontend** | Node.js / React | `80` | `80` | Interfaz gráfica expuesta a internet para los usuarios. |
| **back-ventas** | Java 21 / Spring Boot | `8080` | `8080` | API REST para la gestión y procesamiento de transacciones. |
| **back-despachos**| Java 21 / Spring Boot | `8081` | `8081` | API REST para la logística y control de envíos. |
| **mysql** | MySQL 8.0 | `3306` | `3306` | Base de datos relacional persistente (Volumen indexado). |

---

## 🧭 Lógica de Red en AWS Fargate (Solución de Producción)

A diferencia del entorno local donde Docker Compose resuelve los componentes por su nombre de servicio (`http://mysql:3306`), en **AWS ECS Fargate** todos los contenedores de la misma tarea comparten la misma interfaz de red virtual (*loopback*). 

Para garantizar una arquitectura sólida y portable, los backends se configuraron mediante un `ENTRYPOINT` parametrizado que inyecta dinámicamente las variables de entorno. Al desplegar en la nube, las APIs localizan la base de datos en **`127.0.0.1:3306`**, resolviendo de raíz fallas de comunicación y manteniendo el aislamiento de red corporativo.

---

## 📌 Buenas Prácticas DevOps Incluidas

* **Docker Multi-Stage Builds:** Los Dockerfiles de los backends dividen la etapa de compilación (`maven:3.9-eclipse-temurin`) de la etapa de ejecución (`eclipse-temurin:21-jdk`), reduciendo el tamaño de la imagen final y eliminando herramientas innecesarias en producción.
* **Principio de Menor Privilegio (Seguridad):** Los contenedores Java no se ejecutan como `root`. Se crea explícitamente el usuario del sistema `duocuser` para mitigar vulnerabilidades de inyección de procesos.
* **Configuración como Código:** Toda la tubería de despliegue se gestiona directamente en el repositorio de código, eliminando configuraciones manuales volátiles en la interfaz web de AWS.

---

## 🔧 Cómo Extender este Proyecto

1. **Persistencia Cloud:** Migrar el contenedor de MySQL hacia un servicio administrado como **Amazon RDS** para delegar los respaldos y la alta disponibilidad en AWS.
2. **Capa de Seguridad SSL/TLS:** Anteponer un **Application Load Balancer (ALB)** al clúster de ECS para gestionar certificados de seguridad HTTPS y balancear la carga entre múltiples zonas de disponibilidad.
3. **Monitoreo Centralizado:** Integrar AWS CloudWatch con alarmas SNS para notificar al equipo por correo si el consumo de CPU de Fargate supera el 80% o si los backends registran errores HTTP 5XX.