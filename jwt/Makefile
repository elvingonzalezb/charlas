# Makefile para Arquitectura JWKS con AWS
PROJECT_NAME = jwt-keys-manager
REGION = us-east-1
TF_DIR = iac

# Deshabilitar paginador AWS CLI
export AWS_PAGER =

.PHONY: help check-aws check-aws-account init validate build deploy destroy update-lambda rotate-keys logs get-endpoint test-endpoint status clean

help:
	@echo "Arquitectura JWKS con AWS"
	@echo "========================="
	@echo "make check-aws-account - Verificar cuenta AWS activa"
	@echo "make init         - Inicializar Terraform"
	@echo "make validate     - Validar infraestructura Terraform"
	@echo "make build        - Preparar ZIP de Lambda"
	@echo "make deploy       - Desplegar stack completo"
	@echo "make update-lambda - Actualizar código Lambda"
	@echo "make destroy      - Eliminar infraestructura"
	@echo ""
	@echo "OPERACIONES:"
	@echo "make rotate-keys  - Ejecutar rotación manual de claves"
	@echo "make get-endpoint - Obtener URL del endpoint JWKS"
	@echo "make test-endpoint - Probar endpoint JWKS"
	@echo "make logs         - Ver logs de la Lambda KeyManager"
	@echo "make status       - Estado de recursos AWS"
	@echo "make clean        - Limpiar archivos temporales"

check-aws:
	@echo "Verificando cuenta AWS..."
	@aws sts get-caller-identity --query 'Account' --output text
	@echo "Cuenta AWS verificada"

check-aws-account: check-aws

init:
	@echo "Inicializando Terraform..."
	cd $(TF_DIR) && terraform init
	@echo "Terraform inicializado"

validate: init
	@echo "Validando infraestructura Terraform..."
	cd $(TF_DIR) && terraform fmt -check
	cd $(TF_DIR) && terraform validate
	@echo "Infraestructura válida"

build:
	@echo "Creando archivo ZIP de Lambda (sin dependencias externas)..."
	cd lambda && zip -r ../$(TF_DIR)/key_manager_lambda.zip key_manager.py
	@echo "ZIP de Lambda creado: $(TF_DIR)/key_manager_lambda.zip"

deploy: check-aws build
	@echo "Desplegando infraestructura JWKS..."
	cd $(TF_DIR) && terraform init
	cd $(TF_DIR) && terraform plan
	cd $(TF_DIR) && terraform apply -auto-approve
	@echo "Despliegue completado"

destroy:
	@echo "Eliminando infraestructura JWKS..."
	@echo "Vaciando bucket S3..."
	@aws s3 rm s3://$(PROJECT_NAME)-jwks-public-endpoint --recursive --region $(REGION) 2>/dev/null || true
	cd $(TF_DIR) && terraform destroy -auto-approve
	@echo "Infraestructura eliminada"

update-lambda: build
	@echo "Actualizando código de Lambda..."
	cd $(TF_DIR) && terraform init && terraform apply -auto-approve
	@echo "Actualizando código directamente en AWS..."
	@aws lambda update-function-code --function-name $(PROJECT_NAME)-KeyManager --zip-file fileb://$(TF_DIR)/key_manager_lambda.zip --region $(REGION) > /dev/null
	@echo "Lambda actualizada"

rotate-keys:
	@echo "Ejecutando rotación manual de claves..."
	@aws lambda invoke --function-name $(PROJECT_NAME)-KeyManager --region $(REGION) /tmp/rotation-response.json
	@echo "Respuesta:"
	@cat /tmp/rotation-response.json | jq .
	@rm -f /tmp/rotation-response.json

logs:
	@echo "Logs de Lambda KeyManager:"
	@aws logs tail /aws/lambda/$(PROJECT_NAME)-KeyManager --since 30m --region $(REGION)

get-endpoint:
	@echo "Endpoint JWKS:"
	@cd $(TF_DIR) && terraform output -raw jwks_endpoint_url

test-endpoint:
	@echo "Probando endpoint JWKS..."
	@ENDPOINT=$$(cd $(TF_DIR) && terraform output -raw jwks_endpoint_url) && \
	echo "URL: $$ENDPOINT" && \
	curl -s "$$ENDPOINT" | jq . && \
	echo "✅ Endpoint funcionando correctamente"

status:
	@echo "Estado de recursos AWS:"
	@echo "Lambda KeyManager:"
	@aws lambda get-function --function-name $(PROJECT_NAME)-KeyManager --region $(REGION) --query 'Configuration.[FunctionName,State,LastModified]' --output table 2>/dev/null || echo "Lambda no encontrada"
	@echo ""
	@echo "Bucket S3 JWKS:"
	@aws s3 ls s3://$(PROJECT_NAME)-jwks-public-endpoint/ 2>/dev/null || echo "Bucket no encontrado"
	@echo ""
	@echo "Claves KMS:"
	@aws kms list-keys --region $(REGION) --query 'Keys[*].KeyId' --output table

clean:
	@echo "Limpiando archivos temporales..."
	@rm -f $(TF_DIR)/key_manager_lambda.zip
	@rm -f $(TF_DIR)/.terraform.lock.hcl
	@rm -rf $(TF_DIR)/.terraform/
	@rm -f /tmp/rotation-response.json
	@echo "Limpiando dependencias de Lambda..."
	cd lambda && find . -name "*.dist-info" -type d -exec rm -rf {} + 2>/dev/null || true
	cd lambda && find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	cd lambda && ls | grep -v -E "(key_manager.py|requirements.txt)" | xargs rm -rf 2>/dev/null || true
	@echo "Limpieza completada"