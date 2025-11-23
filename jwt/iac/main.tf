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

## CLAVE ASIMÉTRICA KMS (PARA FIRMA) 🔑
# Usamos KMS para generar y proteger la clave privada, que nunca sale de KMS.
resource "aws_kms_key" "signing_key" {
  description              = "Clave KMS Asimétrica RSA para firmar JWTs"
  key_usage                = "SIGN_VERIFY"
  customer_master_key_spec = "RSA_2048"
  deletion_window_in_days  = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "Allow Lambda to sign"
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.key_manager_lambda_role.arn }
        Action    = ["kms:Sign", "kms:GetPublicKey"]
        Resource  = "*"
      }
    ]
  })
}

# --- S3 (ALMACENAMIENTO DEL JWKS) ---
resource "aws_s3_bucket" "jwks_bucket" {
  bucket = "${var.project_name}-jwks-public-endpoint"
}

resource "aws_s3_bucket_public_access_block" "jwks_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.jwks_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# La política permite el acceso de lectura pública (necesario para el JWKS)
resource "aws_s3_bucket_policy" "jwks_bucket_policy" {
  bucket = aws_s3_bucket.jwks_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.jwks_bucket.arn}/*"
      },
      {
        Sid       = "AllowLambdaWrite"
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.key_manager_lambda_role.arn }
        Action    = ["s3:PutObject", "s3:DeleteObject"]
        Resource  = "${aws_s3_bucket.jwks_bucket.arn}/*"
      }
    ]
  })
}

# --- LAMBDA DE GESTIÓN Y ROTACIÓN (KEY MANAGER) ---
resource "aws_iam_role" "key_manager_lambda_role" {
  name = "${var.project_name}-key-manager-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "key_manager_lambda_policy" {
  name = "${var.project_name}-key-manager-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Logs
      {
        Effect   = "Allow"
        Action   = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.key_manager_lambda.function_name}:*"
      },
      # KMS (Crear y gestionar claves)
      {
        Effect   = "Allow"
        Action   = ["kms:CreateKey", "kms:ScheduleKeyDeletion", "kms:DisableKey", "kms:GetPublicKey", "kms:ListAliases"]
        Resource = "*" # Asumimos gestión de todas las claves KMS, idealmente sería un ARN específico.
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "key_manager_attach" {
  role       = aws_iam_role.key_manager_lambda_role.name
  policy_arn = aws_iam_policy.key_manager_lambda_policy.arn
}

resource "aws_lambda_function" "key_manager_lambda" {
  filename      = "key_manager_lambda.zip" # Este archivo debe crearse con el código de la Parte 2
  function_name = "${var.project_name}-KeyManager"
  role          = aws_iam_role.key_manager_lambda_role.arn
  handler       = "key_manager.handler" # Asumiendo Python
  runtime       = "python3.9"
  timeout       = 60
  environment {
    variables = {
      JWKS_BUCKET_NAME = aws_s3_bucket.jwks_bucket.id
      KMS_KEY_ID       = aws_kms_key.signing_key.key_id
    }
  }
}

# --- EVENTBRIDGE (PROGRAMADOR DE ROTACIÓN) ---
resource "aws_cloudwatch_event_rule" "rotation_schedule" {
  name = "${var.project_name}-RotationSchedule"
  # Rotar cada 90 días (ajustar según 'rotation_interval_days')
  schedule_expression = "rate(${var.rotation_interval_days} days)"
}

resource "aws_cloudwatch_event_target" "rotation_target" {
  rule = aws_cloudwatch_event_rule.rotation_schedule.name
  arn  = aws_lambda_function.key_manager_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.key_manager_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rotation_schedule.arn
}

# --- API GATEWAY (ENDPOINT PÚBLICO JWKS) ---
# Se utiliza una API Gateway HTTP para servir el archivo jwks.json desde S3.
resource "aws_apigatewayv2_api" "jwks_api" {
  name          = "${var.project_name}-JWKS-API"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "jwks_integration" {
  api_id             = aws_apigatewayv2_api.jwks_api.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = "https://${aws_s3_bucket.jwks_bucket.bucket_regional_domain_name}/.well-known/jwks.json"
  integration_method = "GET"
}

resource "aws_apigatewayv2_route" "jwks_route" {
  api_id    = aws_apigatewayv2_api.jwks_api.id
  route_key = "GET /.well-known/jwks.json"
  target    = "integrations/${aws_apigatewayv2_integration.jwks_integration.id}"
}

# STAGE DE DESPLIEGUE (NECESARIO PARA QUE FUNCIONE)
resource "aws_apigatewayv2_stage" "jwks_stage" {
  api_id      = aws_apigatewayv2_api.jwks_api.id
  name        = "$default"
  auto_deploy = true
}

# Este es el endpoint final para los consumidores:
output "jwks_endpoint_url" {
  value = "${aws_apigatewayv2_api.jwks_api.api_endpoint}/.well-known/jwks.json"
}

data "aws_caller_identity" "current" {}