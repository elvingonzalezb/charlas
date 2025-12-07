variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "lambda-event"
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-1"
}
