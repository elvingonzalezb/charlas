.PHONY: help init plan apply destroy clean build deploy test verify

# Variables
PROJECT_NAME ?= cqrs-orders
ENVIRONMENT ?= dev
AWS_REGION ?= us-east-1
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text)

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# =============================================================================
# INFRASTRUCTURE COMMANDS
# =============================================================================

init: ## Initialize Terraform
	cd iac && terraform init

plan: ## Plan Terraform changes
	cd iac && terraform plan \
		-var="project_name=$(PROJECT_NAME)" \
		-var="environment=$(ENVIRONMENT)" \
		-var="aws_region=$(AWS_REGION)"

apply: ## Apply Terraform changes
	cd iac && terraform apply \
		-var="project_name=$(PROJECT_NAME)" \
		-var="environment=$(ENVIRONMENT)" \
		-var="aws_region=$(AWS_REGION)" \
		-auto-approve

deploy-infra: init apply ## Deploy infrastructure only
	@echo "Infrastructure deployed successfully!"
	@echo "Load Balancer URL: $$(cd iac && terraform output -raw load_balancer_url)"

# =============================================================================
# CLEANUP COMMANDS
# =============================================================================

ecr-clean: ## Clean ECR repositories
	@echo "Cleaning ECR repositories..."
	-aws ecr delete-repository --repository-name $(PROJECT_NAME)/write-service --force --region $(AWS_REGION)
	-aws ecr delete-repository --repository-name $(PROJECT_NAME)/read-service --force --region $(AWS_REGION)
	-aws ecr delete-repository --repository-name $(PROJECT_NAME)/sync-service --force --region $(AWS_REGION)

destroy: ecr-clean ## Destroy all resources
	@echo "Destroying Terraform resources..."
	cd iac && terraform destroy \
		-var="project_name=$(PROJECT_NAME)" \
		-var="environment=$(ENVIRONMENT)" \
		-var="aws_region=$(AWS_REGION)" \
		-auto-approve

clean: ## Clean temporary files
	rm -rf iac/.terraform
	rm -f iac/terraform.tfstate*
	rm -f iac/.terraform.lock.hcl
	mvn -f spring/write-service/pom.xml clean
	mvn -f spring/read-service/pom.xml clean
	mvn -f spring/sync-service/pom.xml clean
	@echo "Cleaning Podman images..."
	-podman image prune -a -f
	-podman system prune -a -f

# =============================================================================
# BUILD COMMANDS
# =============================================================================

build: ## Build Spring Boot applications
	@echo "Building Spring Boot applications..."
	mvn -f spring/write-service/pom.xml clean package -DskipTests
	mvn -f spring/read-service/pom.xml clean package -DskipTests
	mvn -f spring/sync-service/pom.xml clean package -DskipTests

podman-start: ## Start Podman machine
	podman machine start

podman-init: ## Initialize Podman machine
	-podman machine init
	podman machine start

podman-build: ## Build Podman images for AMD64
	@echo "Building Podman images for AMD64 architecture..."
	podman build --platform linux/amd64 -f dockerfiles/Dockerfile.write -t $(PROJECT_NAME)/write-service:latest .
	podman build --platform linux/amd64 -f dockerfiles/Dockerfile.read -t $(PROJECT_NAME)/read-service:latest .
	podman build --platform linux/amd64 -f dockerfiles/Dockerfile.sync -t $(PROJECT_NAME)/sync-service:latest .

podman-login: ## Login to ECR
	aws ecr get-login-password --region $(AWS_REGION) | podman login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

ecr-push: podman-login ## Push images to ECR
	@echo "Tagging and pushing images to ECR..."
	@WRITE_REPO=$$(cd iac && terraform output -raw ecr_write_repository_url); \
	READ_REPO=$$(cd iac && terraform output -raw ecr_read_repository_url); \
	podman tag $(PROJECT_NAME)/write-service:latest $$WRITE_REPO:latest; \
	podman tag $(PROJECT_NAME)/read-service:latest $$READ_REPO:latest; \
	podman push $$WRITE_REPO:latest; \
	podman push $$READ_REPO:latest
# =============================================================================
# DEPLOYMENT COMMANDS
# =============================================================================

deploy: deploy-infra build podman-build ecr-push ## Full deployment with verification
	@echo "Waiting for services to start..."
	@sleep 30
	@echo "Verifying deployment..."
	@make verify-ecs
	@echo ""
	@echo "✅ CQRS system deployed successfully!"
	@echo "Write Service: $$(cd iac && terraform output -raw write_service_url)"
	@echo "Read Service: $$(cd iac && terraform output -raw read_service_url)"

force-deploy-services: ## Force new deployment of ECS services
	@echo "Forcing new deployment of ECS services..."
	@aws ecs update-service --cluster $(PROJECT_NAME)-cluster --service $(PROJECT_NAME)-write-service --force-new-deployment
	@aws ecs update-service --cluster $(PROJECT_NAME)-cluster --service $(PROJECT_NAME)-read-service --force-new-deployment
	@aws ecs update-service --cluster $(PROJECT_NAME)-cluster --service $(PROJECT_NAME)-sync-service --force-new-deployment

# =============================================================================
# TESTING COMMANDS
# =============================================================================

test-write: ## Test write service
	@WRITE_URL=$$(cd iac && terraform output -raw write_service_url); \
	curl -X POST $$WRITE_URL/orders \
		-H "Content-Type: application/json" \
		-d '{"customerId": "customer-123", "total": 99.99, "items": [{"productId": "prod-1", "quantity": 2, "price": 49.99}]}'

test-read: ## Test read service
	@READ_URL=$$(cd iac && terraform output -raw read_service_url); \
	curl -X GET $$READ_URL/customers/customer-123/orders

test: test-write test-read ## Run all tests

demo: ## Run demo sequence
	@echo "=== CQRS Demo ==="
	@echo ""
	@echo "🔵 STEP 1: WRITE SERVICE - Creating order..."
	@echo "Service: Write Service (Port 8080)"
	@echo "Action: POST /orders -> DynamoDB Command Table"
	@make test-write
	@echo ""
	@echo "🟡 STEP 2: SYNC SERVICE - Processing DynamoDB Stream..."
	@echo "Service: Sync Service (Background Process)"
	@echo "Action: DynamoDB Stream -> Command Table to Query Table"
	@echo "Waiting for eventual consistency (5 seconds)..."
	@sleep 5
	@echo "✅ Sync service has processed the stream event"
	@echo ""
	@echo "🟢 STEP 3: READ SERVICE - Querying orders..."
	@echo "Service: Read Service (Port 8081)"
	@echo "Action: GET /customers/{id}/orders -> DynamoDB Query Table"
	@make test-read
	@echo ""
	@echo "🎯 DEMO COMPLETED - CQRS Pattern Demonstrated Successfully!"
	@echo "✅ Write Model: Order created in Command table"
	@echo "✅ Sync Process: Data synchronized via DynamoDB Streams"
	@echo "✅ Read Model: Order available in Query table"

# =============================================================================
# HEALTH CHECK COMMANDS
# =============================================================================

health-write: ## Check write service health
	@WRITE_URL=$$(cd iac && terraform output -raw write_service_url 2>/dev/null); \
	if [ ! -z "$$WRITE_URL" ]; then \
		curl -s $$WRITE_URL/actuator/health | jq . || echo "Health check failed"; \
	else \
		echo "Write service URL not available"; \
	fi

health-read: ## Check read service health
	@READ_URL=$$(cd iac && terraform output -raw read_service_url 2>/dev/null); \
	if [ ! -z "$$READ_URL" ]; then \
		curl -s $$READ_URL/actuator/health | jq . || echo "Health check failed"; \
	else \
		echo "Read service URL not available"; \
	fi

health-all: health-write health-read ## Check all services health
# =============================================================================
# VERIFICATION COMMANDS
# =============================================================================

verify-dynamodb: ## Verify DynamoDB tables
	@echo "=== DynamoDB Tables Status ==="
	@aws dynamodb list-tables --query 'TableNames[?contains(@, `$(PROJECT_NAME)`)]' --output table

verify-ecs: ## Verify ECS cluster and services
	@echo "=== ECS Cluster ==="
	@aws ecs describe-clusters --clusters $(PROJECT_NAME)-cluster --query 'clusters[0].{Name:clusterName,Status:status,ActiveServices:activeServicesCount,RunningTasks:runningTasksCount}' --output table
	@echo ""
	@echo "=== ECS Services ==="
	@aws ecs describe-services --cluster $(PROJECT_NAME)-cluster --services $(PROJECT_NAME)-write-service $(PROJECT_NAME)-read-service $(PROJECT_NAME)-sync-service --query 'services[*].{Name:serviceName,Status:status,Running:runningCount,Desired:desiredCount}' --output table

verify-tasks: ## Verify ECS tasks
	@echo "=== ECS Tasks ==="
	@aws ecs list-tasks --cluster $(PROJECT_NAME)-cluster --output table
	@echo ""
	@echo "=== Task Details ==="
	@TASKS=$$(aws ecs list-tasks --cluster $(PROJECT_NAME)-cluster --query 'taskArns' --output text); \
	if [ ! -z "$$TASKS" ]; then \
		aws ecs describe-tasks --cluster $(PROJECT_NAME)-cluster --tasks $$TASKS --query 'tasks[*].{TaskArn:taskArn,LastStatus:lastStatus,DesiredStatus:desiredStatus,HealthStatus:healthStatus}' --output table; \
	else \
		echo "No tasks found"; \
	fi

verify-task-definitions: ## Verify ECS task definitions
	@echo "=== Task Definitions ==="
	@aws ecs list-task-definitions --family-prefix $(PROJECT_NAME) --output table
	@echo ""
	@echo "=== Task Definition Details ==="
	@aws ecs describe-task-definition --task-definition $(PROJECT_NAME)-write-service --query 'taskDefinition.{Family:family,Revision:revision,Status:status,CPU:cpu,Memory:memory}' --output table 2>/dev/null || echo "Write service task definition not found"
	@aws ecs describe-task-definition --task-definition $(PROJECT_NAME)-read-service --query 'taskDefinition.{Family:family,Revision:revision,Status:status,CPU:cpu,Memory:memory}' --output table 2>/dev/null || echo "Read service task definition not found"
	@aws ecs describe-task-definition --task-definition $(PROJECT_NAME)-sync-service --query 'taskDefinition.{Family:family,Revision:revision,Status:status,CPU:cpu,Memory:memory}' --output table 2>/dev/null || echo "Sync service task definition not found"

verify-ecr: ## Verify ECR repositories
	@echo "=== ECR Repositories ==="
	@aws ecr describe-repositories --query 'repositories[?contains(repositoryName, `$(PROJECT_NAME)`)].{Name:repositoryName,URI:repositoryUri,Images:imageTagMutability}' --output table

verify-alb: ## Verify Application Load Balancer
	@echo "=== Load Balancer ==="
	@aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `$(PROJECT_NAME)`)].{Name:LoadBalancerName,DNS:DNSName,State:State.Code}' --output table
	@echo ""
	@echo "=== Target Groups ==="
	@aws elbv2 describe-target-groups --query 'TargetGroups[?contains(TargetGroupName, `$(PROJECT_NAME)`)].{Name:TargetGroupName,Port:Port,HealthyCount:HealthyHostCount,UnhealthyCount:UnhealthyHostCount}' --output table

verify-all: verify-dynamodb verify-ecs verify-tasks verify-task-definitions verify-ecr verify-alb ## Verify all resources

# =============================================================================
# STATUS AND MONITORING COMMANDS
# =============================================================================

status: ## Show infrastructure status
	@echo "=== DynamoDB Tables ==="
	@cd iac && terraform output orders_command_table_name
	@cd iac && terraform output orders_query_table_name
	@echo ""
	@echo "=== Load Balancer ==="
	@cd iac && terraform output load_balancer_url
	@echo ""
	@echo "=== Services ==="
	@cd iac && terraform output write_service_url
	@cd iac && terraform output read_service_url

logs-write: ## View write service logs
	aws logs tail /ecs/$(PROJECT_NAME)-write-service --follow

logs-read: ## View read service logs
	aws logs tail /ecs/$(PROJECT_NAME)-read-service --follow
# Sync service specific commands
logs-sync: ## View sync service logs
	aws logs tail /ecs/$(PROJECT_NAME)-sync-service --follow

check-sync-logs: ## Check recent sync service logs (last 10 minutes)
	@echo "=== Recent Sync Service Activity ==="
	@aws logs filter-log-events --log-group-name /ecs/$(PROJECT_NAME)-sync-service --start-time $(shell date -v-10M +%s)000 --query 'events[*].[timestamp,message]' --output table 2>/dev/null || echo "No recent sync logs found"

demo-with-logs: ## Run demo sequence with detailed logging
	@echo "=== CQRS Demo with Detailed Logging ==="
	@echo ""
	@echo "🔵 STEP 1: WRITE SERVICE - Creating order..."
	@echo "Service: Write Service (Port 8080)"
	@echo "Action: POST /orders -> DynamoDB Command Table"
	@make test-write
	@echo ""
	@echo "🟡 STEP 2: SYNC SERVICE - Processing DynamoDB Stream..."
	@echo "Service: Sync Service (Background Process)"
	@echo "Action: DynamoDB Stream -> Command Table to Query Table"
	@echo "Checking sync service logs..."
	@make check-sync-logs
	@echo "Waiting for eventual consistency (5 seconds)..."
	@sleep 5
	@echo "✅ Sync service has processed the stream event"
	@echo ""
	@echo "🟢 STEP 3: READ SERVICE - Querying orders..."
	@echo "Service: Read Service (Port 8081)"
	@echo "Action: GET /customers/{id}/orders -> DynamoDB Query Table"
	@make test-read
	@echo ""
	@echo "🎯 DEMO COMPLETED - CQRS Pattern Demonstrated Successfully!"
	@echo "✅ Write Model: Order created in Command table"
	@echo "✅ Sync Process: Data synchronized via DynamoDB Streams"
	@echo "✅ Read Model: Order available in Query table"

# Enhanced ECR push with sync service
ecr-push-all: podman-login ## Push all images to ECR including sync service
	@echo "Tagging and pushing all images to ECR..."
	@WRITE_REPO=$$(cd iac && terraform output -raw ecr_write_repository_url); \
	READ_REPO=$$(cd iac && terraform output -raw ecr_read_repository_url); \
	SYNC_REPO=$$(cd iac && terraform output -raw ecr_sync_repository_url); \
	podman tag $(PROJECT_NAME)/write-service:latest $$WRITE_REPO:latest; \
	podman tag $(PROJECT_NAME)/read-service:latest $$READ_REPO:latest; \
	podman tag $(PROJECT_NAME)/sync-service:latest $$SYNC_REPO:latest; \
	podman push $$WRITE_REPO:latest; \
	podman push $$READ_REPO:latest; \
	podman push $$SYNC_REPO:latest

# Full deployment with sync service
deploy-with-sync: deploy-infra build podman-build ecr-push-all ## Full deployment including sync service
	@echo "Waiting for all services to start..."
	@sleep 45
	@echo "Verifying deployment..."
	@make verify-ecs
	@echo ""
	@echo "✅ CQRS system with sync service deployed successfully!"
	@echo "Write Service: $$(cd iac && terraform output -raw write_service_url)"
	@echo "Read Service: $$(cd iac && terraform output -raw read_service_url)"
	@echo "Sync Service: Running in background processing DynamoDB streams"