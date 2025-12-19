.PHONY: help check clean t-init t-plan t-apply t-destroy s-build s-deploy s-delete deploy destroy test-web test-app test-whatsapp test-all logs-web logs-app logs-whatsapp

help:
	@echo "Comandos disponibles:"
	@echo "  make check         - Verificar cuenta AWS"
	@echo "  make t-init        - Inicializar Terraform"
	@echo "  make t-plan        - Ver plan de Terraform"
	@echo "  make t-apply       - Desplegar infraestructura"
	@echo "  make t-destroy     - Destruir infraestructura"
	@echo "  make s-build       - Construir lambdas con SAM"
	@echo "  make s-deploy      - Desplegar lambdas con SAM"
	@echo "  make s-delete      - Eliminar lambdas"
	@echo "  make deploy        - Desplegar todo (infra + lambdas)"
	@echo "  make destroy       - Destruir todo"
	@echo "  make test-web      - Probar evento Web"
	@echo "  make test-app      - Probar evento App"
	@echo "  make test-whatsapp - Probar evento WhatsApp"
	@echo "  make test-all      - Probar todos los eventos"
	@echo "  make logs-web      - Ver logs Lambda Web en tiempo real"
	@echo "  make logs-app      - Ver logs Lambda App en tiempo real"
	@echo "  make logs-whatsapp - Ver logs Lambda WhatsApp en tiempo real"

check:
	@echo "Verificando cuenta AWS..."
	@aws sts get-caller-identity --query '[Account, Arn]' --output text

clean:
	@echo "🧹 Limpiando archivos de Terraform y SAM..."
	@rm -rf iac/.terraform iac/.terraform.lock.hcl iac/*.tfstate iac/*.tfstate.backup
	@rm -rf .aws-sam
	@echo "✅ Limpieza completada"

# Terraform commands
t-init:
	cd iac && terraform init

t-plan:
	cd iac && terraform plan

t-apply:
	cd iac && terraform apply -auto-approve

t-destroy:
	cd iac && terraform destroy -auto-approve

# SAM commands
s-build:
	sam build -t sam/template.yaml

s-deploy:
	@echo "Obteniendo outputs de Terraform..."
	@cd iac && \
	EVENTBRIDGE_BUS_NAME=$$(terraform output -raw eventbridge_bus_name) && \
	SNS_TOPIC_ARN=$$(terraform output -raw sns_topic_arn) && \
	SQS_WEB_URL=$$(terraform output -raw sqs_web_url) && \
	SQS_APP_URL=$$(terraform output -raw sqs_app_url) && \
	SQS_WHATSAPP_URL=$$(terraform output -raw sqs_whatsapp_url) && \
	LAMBDA_RECEPTOR_ROLE_ARN=$$(terraform output -raw lambda_receptor_role_arn) && \
	LAMBDA_PROCESADOR_ROLE_ARN=$$(terraform output -raw lambda_procesador_role_arn) && \
	EVENTBRIDGE_RULE_WEB_ARN=$$(terraform output -raw eventbridge_rule_web_arn) && \
	EVENTBRIDGE_RULE_APP_ARN=$$(terraform output -raw eventbridge_rule_app_arn) && \
	EVENTBRIDGE_RULE_WHATSAPP_ARN=$$(terraform output -raw eventbridge_rule_whatsapp_arn) && \
	cd .. && \
	sam deploy \
	  --stack-name lambda-event-stack \
	  --capabilities CAPABILITY_IAM \
	  --region us-east-1 \
	  --parameter-overrides \
	    EventBridgeBusName=$$EVENTBRIDGE_BUS_NAME \
	    SNSTopicArn=$$SNS_TOPIC_ARN \
	    SQSWebUrl=$$SQS_WEB_URL \
	    SQSAppUrl=$$SQS_APP_URL \
	    SQSWhatsAppUrl=$$SQS_WHATSAPP_URL \
	    LambdaReceptorRoleArn=$$LAMBDA_RECEPTOR_ROLE_ARN \
	    LambdaProcesadorRoleArn=$$LAMBDA_PROCESADOR_ROLE_ARN \
	    EventBridgeRuleWebArn=$$EVENTBRIDGE_RULE_WEB_ARN \
	    EventBridgeRuleAppArn=$$EVENTBRIDGE_RULE_APP_ARN \
	    EventBridgeRuleWhatsAppArn=$$EVENTBRIDGE_RULE_WHATSAPP_ARN

s-delete:
	sam delete --stack-name lambda-event-stack --no-prompts

# Test commands
test-web:
	@echo "🧪 Enviando evento Web a EventBridge..."
	@aws events put-events --entries file://invoke/event-web.json --region us-east-1 --no-cli-pager
	@echo "Esperando procesamiento..."
	@sleep 2
	@$(MAKE) logs-web

test-app:
	@echo "🧪 Enviando evento App a EventBridge..."
	@aws events put-events --entries file://invoke/event-app.json --region us-east-1 --no-cli-pager
	@echo "Esperando procesamiento..."
	@sleep 2
	@$(MAKE) logs-app

test-whatsapp:
	@echo "🧪 Enviando evento WhatsApp a EventBridge..."
	@aws events put-events --entries file://invoke/event-whatsapp.json --region us-east-1 --no-cli-pager
	@echo "Esperando procesamiento..."
	@sleep 2
	@$(MAKE) logs-whatsapp

test-all: test-web test-app test-whatsapp
	@echo "✅ Todos los eventos enviados"

# Logs commands
logs-web:
	@echo "📋 Logs de Web Receptor..."
	@sleep 3
	@aws logs tail /aws/lambda/lambda-event-web-receptor --since 10m --format short
	@echo ""
	@echo "📋 Logs de Web Procesador..."
	@sleep 2
	@aws logs tail /aws/lambda/lambda-event-web-procesador --since 10m --format short

logs-app:
	@echo "📋 Logs de App Receptor..."
	@sleep 3
	@aws logs tail /aws/lambda/lambda-event-app-receptor --since 10m --format short
	@echo ""
	@echo "📋 Logs de App Procesador..."
	@sleep 2
	@aws logs tail /aws/lambda/lambda-event-app-procesador --since 10m --format short

logs-whatsapp:
	@echo "📋 Logs de WhatsApp Receptor..."
	@sleep 3
	@aws logs tail /aws/lambda/lambda-event-whatsapp-receptor --since 10m --format short
	@echo ""
	@echo "📋 Logs de WhatsApp Procesador..."
	@sleep 2
	@aws logs tail /aws/lambda/lambda-event-whatsapp-procesador --since 10m --format short


# Combined commands
deploy:
	@echo "🚀 Iniciando despliegue completo..."
	@echo ""
	@echo "📋 Stage 1 [Clean]: Limpiando archivos anteriores..."
	@$(MAKE) clean
	@echo ""
	@echo "📋 Stage 2 [Init]: Inicializando Terraform..."
	@$(MAKE) t-init
	@echo ""
	@echo "📋 Stage 3 [Plan]: Generando plan de Terraform..."
	@$(MAKE) t-plan
	@echo ""
	@echo "==============================================="
	@echo "⚠️  Revisa el plan anterior"
	@echo "==============================================="
	@bash -c 'read -p "¿Deseas continuar con el despliegue? (si/no): " respuesta; \
	if [ "$$respuesta" != "si" ]; then \
		echo "❌ Despliegue cancelado"; \
		exit 1; \
	fi'
	@echo ""
	@echo "📋 Stage 4 [Apply]: Aplicando infraestructura con Terraform..."
	@$(MAKE) t-apply
	@echo ""
	@echo "📋 Stage 5 [Build Lambdas]: Construyendo lambdas con SAM..."
	@$(MAKE) s-build
	@echo ""
	@echo "📋 Stage 6 [Deploy Lambdas]: Desplegando lambdas con SAM..."
	@$(MAKE) s-deploy
	@echo ""
	@echo "✅ Despliegue completado de forma exitosa"

destroy: s-delete t-destroy
	@echo "✅ Destrucción completada de forma exitosa"