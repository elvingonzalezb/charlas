.PHONY: help status start build deploy demo clean

# Variables
PROFILE ?= minikube
DRIVER ?= podman
MEMORY ?= 3072
CPUS ?= 2
KUBERNETES_VERSION ?= v1.31.0

help: ## Show available commands
	@echo 'CQRS Kubernetes Taller - Comandos Disponibles:'
	@echo ''
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# =============================================================================
# COMANDOS PRINCIPALES DEL TALLER
# =============================================================================

start: ## Iniciar minikube con Podman
	@echo "🚀 Iniciando minikube con Podman..."
	@echo "Verificando Podman..."
	podman machine init --cpus=$(CPUS) --memory=$(MEMORY) || echo "Podman machine ya existe"
	podman machine start || echo "Podman machine ya está corriendo"
	@echo "Iniciando minikube..."
	minikube start \
		--profile=$(PROFILE) \
		--driver=$(DRIVER) \
		--memory=$(MEMORY) \
		--cpus=$(CPUS) \
		--kubernetes-version=$(KUBERNETES_VERSION) \
		--container-runtime=containerd
	@echo "Habilitando addons necesarios..."
	minikube addons enable ingress -p $(PROFILE)
	minikube addons enable dashboard -p $(PROFILE)
	minikube addons enable metrics-server -p $(PROFILE)
	@echo "✅ Minikube listo!"

status: ## Ver estado del sistema
	@echo "=== Estado de Minikube ==="
	@if minikube status -p $(PROFILE) >/dev/null 2>&1; then \
		minikube status -p $(PROFILE); \
		echo ""; \
		echo "=== Pods del Sistema CQRS ==="; \
		kubectl get pods -l 'app in (mongodb,write-service,read-service)' || echo "No hay pods CQRS desplegados"; \
		echo ""; \
		echo "=== Servicios ==="; \
		kubectl get services -l 'app in (mongodb,write-service,read-service)' || echo "No hay servicios CQRS"; \
	else \
		echo "⚠️  Minikube no está corriendo. Ejecuta 'make start' primero."; \
	fi

build: ## Construir imágenes de los servicios
	@echo "🏗️  Construyendo servicios CQRS..."
	@echo "Compilando write-service..."
	cd docker/write-service && mvn clean package -DskipTests
	@echo "Compilando read-service..."
	cd docker/read-service && mvn clean package -DskipTests  
	@echo "Construyendo imágenes con Podman..."
	cd docker/write-service && podman build -t cqrs-kube/write-service:latest .
	cd docker/read-service && podman build -t cqrs-kube/read-service:latest .
	@echo "Cargando imágenes en minikube..."
	podman save cqrs-kube/write-service:latest | minikube image load -
	podman save cqrs-kube/read-service:latest | minikube image load -
	@echo "✅ Imágenes construidas y cargadas!"

deploy: ## Desplegar sistema CQRS
	@echo "🚀 Desplegando sistema CQRS..."
	kubectl apply -f manifiestos/secrets.yaml
	kubectl apply -f manifiestos/mongodb-config.yaml
	kubectl apply -f manifiestos/mongodb-deployment.yaml
	kubectl apply -f manifiestos/mongodb-service.yaml
	@echo "⏳ Esperando MongoDB..."
	kubectl wait --for=condition=ready pod -l app=mongodb --timeout=300s
	kubectl apply -f manifiestos/write-deployment.yaml
	kubectl apply -f manifiestos/write-service.yaml
	kubectl apply -f manifiestos/read-deployment.yaml
	kubectl apply -f manifiestos/read-service.yaml
	@echo "✅ Sistema CQRS desplegado!"

demo: ## Ejecutar demo del sistema CQRS
	@echo "🎯 Ejecutando Demo CQRS..."
	@echo ""
	@echo "🔗 Configurando port-forwards..."
	@kubectl port-forward service/write-service 8080:8080 > /dev/null 2>&1 &
	@kubectl port-forward service/read-service 8081:8081 > /dev/null 2>&1 &
	@sleep 3
	@echo ""
	@echo "1️⃣ Creando orden en Write Service..."
	@curl -X POST http://localhost:8080/write/orders \
		-H "Content-Type: application/json" \
		-d '{"orderId":"ORD-DEMO-001","customerId":"CUST-DEMO","productName":"Producto Demo","quantity":2,"price":50.00}' \
		-w "\n" || echo "❌ Write service no disponible"
	@echo ""
	@echo "⏳ Esperando 3 segundos..."
	@sleep 3
	@echo ""
	@echo "2️⃣ Leyendo órdenes desde Read Service..."
	@curl -X GET http://localhost:8081/read/customers/CUST-DEMO/orders \
		-H "Content-Type: application/json" \
		-w "\n" || echo "❌ Read service no disponible"
	@echo ""
	@echo "🔗 Limpiando port-forwards..."
	@pkill -f "kubectl port-forward service/write-service" || true
	@pkill -f "kubectl port-forward service/read-service" || true
	@echo "✅ Demo completado!"

clean-all: ## Limpiar todo el sistema
	@echo "💥 Limpiando TODO el sistema..."
	@read -p "¿Estás seguro? (y/n): " confirm && [ "$$confirm" = "y" ]
	@echo "🗑️  Eliminando recursos CQRS..."
	@if kubectl cluster-info >/dev/null 2>&1; then \
		kubectl delete deployments,services,ingress,secrets,configmaps -l app=mongodb --ignore-not-found=true || true; \
		kubectl delete deployments,services,ingress,secrets,configmaps -l app=write-service --ignore-not-found=true || true; \
		kubectl delete deployments,services,ingress,secrets,configmaps -l app=read-service --ignore-not-found=true || true; \
		kubectl delete ingress cqrs-ingress --ignore-not-found=true || true; \
		kubectl delete secrets mongodb-secret app-config-secret --ignore-not-found=true || true; \
		kubectl delete configmaps mongodb-init-config --ignore-not-found=true || true; \
		kubectl delete services write-service-nodeport read-service-nodeport --ignore-not-found=true || true; \
	else \
		echo "⚠️  Kubernetes cluster no disponible, saltando limpieza de recursos"; \
	fi
	@echo "🗑️  Limpiando imágenes..."
	podman rmi cqrs-kube/write-service:latest --force 2>/dev/null || true
	podman rmi cqrs-kube/read-service:latest --force 2>/dev/null || true
	@echo "🗑️  Eliminando minikube..."
	minikube delete -p $(PROFILE) || true
	@echo "💥 Sistema completamente limpio!"

# =============================================================================
# COMANDOS DE UTILIDAD
# =============================================================================

logs-write: ## Ver logs del write service
	kubectl logs -l app=write-service --tail=50

logs-read: ## Ver logs del read service
	kubectl logs -l app=read-service --tail=50

logs-mongo: ## Ver logs de MongoDB
	kubectl logs -l app=mongodb --tail=50

health: ## Verificar health de todos los servicios
	@echo "🏥 Verificando Health de los Servicios..."
	@echo ""
	@echo "🔗 Configurando port-forwards temporales..."
	@kubectl port-forward service/write-service 8080:8080 > /dev/null 2>&1 &
	@kubectl port-forward service/read-service 8081:8081 > /dev/null 2>&1 &
	@sleep 3
	@echo ""
	@echo "1️⃣ Write Service Health:"
	@curl -s http://localhost:8080/write/health | jq '.' 2>/dev/null || curl -s http://localhost:8080/write/health || echo "❌ Write service no disponible"
	@echo ""
	@echo "2️⃣ Read Service Health:"
	@curl -s http://localhost:8081/read/health | jq '.' 2>/dev/null || curl -s http://localhost:8081/read/health || echo "❌ Read service no disponible"
	@echo ""
	@echo "3️⃣ Kubernetes Liveness/Readiness Probes:"
	@kubectl get pods -l 'app in (write-service,read-service)' -o custom-columns="NAME:.metadata.name,READY:.status.containerStatuses[0].ready,RESTARTS:.status.containerStatuses[0].restartCount,STATUS:.status.phase"
	@echo ""
	@echo "🔗 Limpiando port-forwards temporales..."
	@pkill -f "kubectl port-forward service/write-service" || true
	@pkill -f "kubectl port-forward service/read-service" || true
	@echo "✅ Health check completado!"

health-write: ## Verificar health del write service
	@echo "🏥 Write Service Health Check..."
	@kubectl port-forward service/write-service 8080:8080 > /dev/null 2>&1 &
	@sleep 2
	@curl -s http://localhost:8080/write/health | jq '.' 2>/dev/null || curl -s http://localhost:8080/write/health || echo "❌ Write service no disponible"
	@pkill -f "kubectl port-forward service/write-service" || true

health-read: ## Verificar health del read service
	@echo "🏥 Read Service Health Check..."
	@kubectl port-forward service/read-service 8081:8081 > /dev/null 2>&1 &
	@sleep 2
	@curl -s http://localhost:8081/read/health | jq '.' 2>/dev/null || curl -s http://localhost:8081/read/health || echo "❌ Read service no disponible"
	@pkill -f "kubectl port-forward service/read-service" || true

port-forward: ## Configurar port-forward para MongoDB
	@echo "🔗 Configurando port-forward para MongoDB..."
	@echo "Ejecutando: kubectl port-forward service/mongodb-service 27017:27017"
	@echo "Presiona Ctrl+C para detener el port-forward"
	@echo ""
	@echo "Una vez activo, conecta MongoDB Compass con:"
	@echo "mongodb://admin:password123@localhost:27017/PRUEBA?authSource=admin"
	@echo ""
	kubectl port-forward service/mongodb-service 27017:27017

urls: ## Mostrar URLs de los servicios
	@echo "=== URLs de los Servicios ==="
	@if minikube status -p $(PROFILE) >/dev/null 2>&1; then \
		MINIKUBE_IP=$$(minikube ip -p $(PROFILE)) && \
		echo "Write Service: http://localhost:8080/write" && \
		echo "Read Service:  http://localhost:8081/read" && \
		echo "" && \
		echo "Health Checks:" && \
		echo "Write Health:  http://localhost:8080/write/health" && \
		echo "Read Health:   http://localhost:8081/read/health" && \
		echo "" && \
		echo "=== MongoDB Connection ===" && \
		echo "Para conectar MongoDB Compass:" && \
		echo "1. Ejecuta: kubectl port-forward service/mongodb-service 27017:27017" && \
		echo "2. Usa esta URL en MongoDB Compass:" && \
		echo "   mongodb://admin:password123@localhost:27017/PRUEBA?authSource=admin"; \
	else \
		echo "⚠️  Minikube no está corriendo. Ejecuta 'make start' primero."; \
		echo ""; \
		echo "URLs esperadas cuando minikube esté corriendo:"; \
		echo "Write Service: http://MINIKUBE_IP:30080/write"; \
		echo "Read Service:  http://MINIKUBE_IP:30081/read"; \
		echo ""; \
		echo "=== MongoDB Connection ==="; \
		echo "Para conectar MongoDB Compass:"; \
		echo "1. Ejecuta: kubectl port-forward service/mongodb-service 27017:27017"; \
		echo "2. Usa esta URL en MongoDB Compass:"; \
		echo "   mongodb://admin:password123@localhost:27017/PRUEBA?authSource=admin"; \
	fi

dashboard: ## Abrir dashboard de Kubernetes
	minikube dashboard -p $(PROFILE)

# =============================================================================
# FLUJO COMPLETO DEL TALLER
# =============================================================================

flow-execute: start build deploy ## Ejecutar flujo completo del taller
	@echo ""
	@echo "🎉 ¡Flow CQRS completado exitosamente!"
	@echo ""
	@echo "🔗 Configurando port-forward para MongoDB..."
	@kubectl port-forward service/mongodb-service 27017:27017 > /dev/null 2>&1 &
	@echo "Port-forward configurado en background"
	@echo ""
	@echo "📋 MongoDB Compass - Usa esta conexión:"
	@echo "mongodb://admin:password123@localhost:27017/PRUEBA?authSource=admin"
	@echo ""
	@echo "Comandos útiles:"
	@echo "  make status       - Ver estado del sistema"
	@echo "  make urls         - Ver URLs de servicios"
	@echo "  make port-forward - Port-forward manual para MongoDB"
	@echo "  make dashboard    - Abrir dashboard de Kubernetes"
	@echo "  make flow-execute - Ejecutar flujo completo"