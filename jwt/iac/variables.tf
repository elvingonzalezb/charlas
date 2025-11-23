variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "jwt-keys-manager"
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "rotation_interval_days" {
  description = "Intervalo de rotación de claves en días"
  type        = number
  default     = 90
}