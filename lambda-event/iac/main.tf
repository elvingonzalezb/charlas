terraform {
  required_version = ">= 1.0"
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

# EventBridge Bus
resource "aws_cloudwatch_event_bus" "main" {
  name = "${var.project_name}-${var.environment}-bus"
}

# EventBridge Rules
resource "aws_cloudwatch_event_rule" "web" {
  name           = "${var.project_name}-web-rule"
  event_bus_name = aws_cloudwatch_event_bus.main.name
  event_pattern = jsonencode({
    source = ["com.miapp.web"]
  })
}

resource "aws_cloudwatch_event_rule" "app" {
  name           = "${var.project_name}-app-rule"
  event_bus_name = aws_cloudwatch_event_bus.main.name
  event_pattern = jsonencode({
    source = ["com.miapp.app"]
  })
}

resource "aws_cloudwatch_event_rule" "whatsapp" {
  name           = "${var.project_name}-whatsapp-rule"
  event_bus_name = aws_cloudwatch_event_bus.main.name
  event_pattern = jsonencode({
    source = ["com.miapp.whatsapp"]
  })
}

# SNS Topic
resource "aws_sns_topic" "messages" {
  name = "${var.project_name}-${var.environment}-messages"
}

# SQS Queues
resource "aws_sqs_queue" "web" {
  name                       = "${var.project_name}-web-queue"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 345600
}

resource "aws_sqs_queue" "app" {
  name                       = "${var.project_name}-app-queue"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 345600
}

resource "aws_sqs_queue" "whatsapp" {
  name                       = "${var.project_name}-whatsapp-queue"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 345600
}

# SNS to SQS Subscriptions
resource "aws_sns_topic_subscription" "web" {
  topic_arn = aws_sns_topic.messages.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.web.arn
  filter_policy = jsonencode({
    source = ["web"]
  })
}

resource "aws_sns_topic_subscription" "app" {
  topic_arn = aws_sns_topic.messages.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.app.arn
  filter_policy = jsonencode({
    source = ["app"]
  })
}

resource "aws_sns_topic_subscription" "whatsapp" {
  topic_arn = aws_sns_topic.messages.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.whatsapp.arn
  filter_policy = jsonencode({
    source = ["whatsapp"]
  })
}

# SQS Policies para permitir SNS
resource "aws_sqs_queue_policy" "web" {
  queue_url = aws_sqs_queue.web.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.web.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.messages.arn
        }
      }
    }]
  })
}

resource "aws_sqs_queue_policy" "app" {
  queue_url = aws_sqs_queue.app.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.app.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.messages.arn
        }
      }
    }]
  })
}

resource "aws_sqs_queue_policy" "whatsapp" {
  queue_url = aws_sqs_queue.whatsapp.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.whatsapp.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.messages.arn
        }
      }
    }]
  })
}

# IAM Role para Lambdas Receptoras
resource "aws_iam_role" "lambda_receptor" {
  name = "${var.project_name}-lambda-receptor-role"
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

resource "aws_iam_role_policy" "lambda_receptor" {
  name = "${var.project_name}-lambda-receptor-policy"
  role = aws_iam_role.lambda_receptor.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.messages.arn
      }
    ]
  })
}

# IAM Role para Lambdas Procesadoras
resource "aws_iam_role" "lambda_procesador" {
  name = "${var.project_name}-lambda-procesador-role"
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

resource "aws_iam_role_policy" "lambda_procesador" {
  name = "${var.project_name}-lambda-procesador-policy"
  role = aws_iam_role.lambda_procesador.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          aws_sqs_queue.web.arn,
          aws_sqs_queue.app.arn,
          aws_sqs_queue.whatsapp.arn
        ]
      }
    ]
  })
}
