output "eventbridge_bus_name" {
  value = aws_cloudwatch_event_bus.main.name
}

output "eventbridge_bus_arn" {
  value = aws_cloudwatch_event_bus.main.arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.messages.arn
}

output "sqs_web_url" {
  value = aws_sqs_queue.web.url
}

output "sqs_app_url" {
  value = aws_sqs_queue.app.url
}

output "sqs_whatsapp_url" {
  value = aws_sqs_queue.whatsapp.url
}

output "lambda_receptor_role_arn" {
  value = aws_iam_role.lambda_receptor.arn
}

output "lambda_procesador_role_arn" {
  value = aws_iam_role.lambda_procesador.arn
}

output "eventbridge_rule_web_arn" {
  value = aws_cloudwatch_event_rule.web.arn
}

output "eventbridge_rule_app_arn" {
  value = aws_cloudwatch_event_rule.app.arn
}

output "eventbridge_rule_whatsapp_arn" {
  value = aws_cloudwatch_event_rule.whatsapp.arn
}
