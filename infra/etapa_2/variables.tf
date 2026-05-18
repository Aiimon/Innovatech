variable "aws_region" {
  description = "Región de AWS"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto para Innovatech Chile"
  default     = "eva-2"
}

# Estas variables las puedes llenar en un archivo terraform.tfvars o por consola
variable "db_user" {
  default = "root"
}

variable "db_password" {
  default = "root"
}

variable "db_name" {
  default = "innovatech_db"
}

variable "key_pair_name" {
  description = "Nombre de tu llave .pem creada en AWS"
}
