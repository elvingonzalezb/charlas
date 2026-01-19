.PHONY: help status start build deploy demo clean

# Variables
PROFILE ?= minikube
DRIVER ?= podman
MEMORY ?= 3072
CPUS ?= 2
KUBERNETES_VERSION ?= v1.31.0
CHART_NAME = helm
RELEASE_NAME = cqrs-stack
NAMESPACE = default

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
		echo "=== Estado del Release Helm ==="; \
		helm status $(RELEASE_NAME) --namespace $(NAMESPACE) 2>/dev/null || echo "Release Helm no encontrado"; \
		echo ""; \
		echo "=== Pods del Sistema CQRS ==="; \
		kubectl get pods -n $(NAMESPACE) -l app.kubernetes.io/instance=$(RELEASE_NAME) || echo "No hay pods CQRS desplegados"; \
		echo ""; \
		echo "=== Servicios ==="; \
		kubectl get services -n $(NAMESPACE) -l app.kubernetes.io/instance=$(RELEASE_NAME) || echo "No hay servicios CQRS"; \
	else \
		echo "⚠️  Minikube no está corriendo. Ejecuta 'make start' primero."; \
	fi

build: ## Construir imágenes de los servicios
	@echo "🏗️  Construyendo servicios CQRS..."
	@echo "Compilando write-service..."
	cd docker/write-service && mvn clean package -DskipTests
	@echo "Compilando read-service..."
	cd docker/read-service && mvn clean package -DskipTests
	@echo "Compilando redis-service..."
	cd docker/redis-service && mvn clean package -DskipTests
	@echo "Construyendo imágenes con Podman..."
	cd docker/write-service && podman build -t write-service:latest .
	cd docker/read-service && podman build -t read-service:latest .
	cd docker/redis-service && podman build -t redis-service:latest .
	@echo "Cargando imágenes en minikube..."
	podman save write-service:latest | minikube image load -
	podman save read-service:latest | minikube image load -
	podman save redis-service:latest | minikube image load -
	@echo "✅ Imágenes construidas y cargadas!"

deploy: ## Desplegar sistema CQRS con Helm
	@echo "🚀 Desplegando sistema CQRS con Helm..."
	helm upgrade --install $(RELEASE_NAME) ./$(CHART_NAME) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--wait \
		--timeout=300s
	@echo "✅ Sistema CQRS desplegado con Helm!"

destroy: ## Destruir sistema CQRS
	@echo "💥 Destruyendo sistema CQRS..."
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE) || true
	@echo "✅ Sistema destruido!"

demo: ## Ejecutar demo del sistema CQRS
	@echo "🎯 Ejecutando Demo CQRS..."
	@echo ""
	@echo "🔗 Configurando port-forwards..."
	@kubectl port-forward service/$(RELEASE_NAME)-helm-write-service 8080:8080 > /dev/null 2>&1 &
	@kubectl port-forward service/$(RELEASE_NAME)-helm-read-service 8081:8081 > /dev/null 2>&1 &
	@kubectl port-forward service/$(RELEASE_NAME)-helm-redis 6379:6379 > /dev/null 2>&1 &
	@kubectl port-forward service/$(RELEASE_NAME)-helm-redis-service 8082:8082 > /dev/null 2>&1 &
	@sleep 3
	@echo ""
	@echo "1️⃣ Probando Redis Service (HTTP API)..."
	@curl -X POST http://localhost:8082/redis/set \
		-H "Content-Type: application/json" \
		-d '{"key":"demo-key","value":"demo-value"}' \
		-w "\n" || echo "❌ Redis Service no disponible"
	@echo ""
	@echo "2️⃣ Verificando valor en Redis Service..."
	@curl -X GET http://localhost:8082/redis/get/demo-key \
		-H "Content-Type: application/json" \
		-w "\n" || echo "❌ Redis Service no disponible"
	@echo ""
	@echo "3️⃣ Creando orden en Write Service..."
	@curl -X POST http://localhost:8080/write/orders \
		-H "Content-Type: application/json" \
		-d '{"orderId":"ORD-DEMO-001","customerId":"CUST-DEMO","productName":"Producto Demo","quantity":2,"price":50.00}' \
		-w "\n" || echo "❌ Write service no disponible"
	@echo ""
	@echo "4️⃣ Probando Redis nativo..."
	@kubectl run redis-demo --image=redis:7-alpine --rm -it --restart=Never -- redis-cli -h $(RELEASE_NAME)-helm-redis -p 6379 set demo "test-value" || echo "❌ Redis no disponible"
	@echo ""
	@echo "⏳ Esperando 3 segundos..."
	@sleep 3
	@echo ""
	@echo "5️⃣ Leyendo órdenes desde Read Service..."
	@curl -X GET http://localhost:8081/read/customers/CUST-DEMO/orders \
		-H "Content-Type: application/json" \
		-w "\n" || echo "❌ Read service no disponible"
	@echo ""
	@echo "🔗 Limpiando port-forwards..."
	@pkill -f "kubectl port-forward" || true
	@echo "✅ Demo completado!"

test: ## Probar todos los servicios
	@echo "🧪 Probando servicios..."
	@echo "Testing Redis..."
	kubectl run redis-test --image=redis:7-alpine --rm -it --restart=Never -- redis-cli -h $(RELEASE_NAME)-helm-redis -p 6379 ping || true
	@echo "Testing Write Service..."
	kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- curl -f http://$(RELEASE_NAME)-helm-write-service:8080/write/health || true
	@echo "Testing Read Service..."
	kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- curl -f http://$(RELEASE_NAME)-helm-read-service:8081/read/health || true
	@echo "Testing Redis Service..."
	kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- curl -f http://$(RELEASE_NAME)-helm-redis-service:8082/actuator/health || true

clean-all: ## Limpiar todo el sistema
	@echo "💥 Limpiando TODO el sistema..."
	@read -p "¿Estás seguro? (y/n): " confirm && [ "$$confirm" = "y" ]
	@echo "🗑️  Eliminando release Helm..."
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE) || true
	@echo "🗑️  Limpiando imágenes..."
	podman rmi write-service:latest --force 2>/dev/null || true
	podman rmi read-service:latest --force 2>/dev/null || true
	podman rmi redis-service:latest --force 2>/dev/null || true
	@echo "🗑️  Eliminando minikube..."
	minikube delete -p $(PROFILE) || true
	@echo "💥 Sistema completamente limpio!"

# =============================================================================
# COMANDOS REDIS
# =============================================================================

redis-set: ## Insertar clave-valor en Redis (make redis-set KEY=mikey VALUE=mivalue)
	@kubectl run redis-cmd --image=redis:7-alpine --rm -it --restart=Never -- redis-cli -h $(RELEASE_NAME)-helm-redis -p 6379 set $(KEY) "$(VALUE)"

redis-get: ## Obtener valor de Redis (make redis-get KEY=mikey)
	@kubectl run redis-cmd --image=redis:7-alpine --rm -it --restart=Never -- redis-cli -h $(RELEASE_NAME)-helm-redis -p 6379 get $(KEY)

redis-del: ## Eliminar clave de Redis (make redis-del KEY=mikey)
	@kubectl run redis-cmd --image=redis:7-alpine --rm -it --restart=Never -- redis-cli -h $(RELEASE_NAME)-helm-redis -p 6379 del $(KEY)

redis-keys: ## Listar todas las claves de Redis
	@kubectl run redis-cmd --image=redis:7-alpine --rm -it --restart=Never -- redis-cli -h $(RELEASE_NAME)-helm-redis -p 6379 keys "*"

redis-flush: ## Limpiar toda la base de datos Redis
	@kubectl run redis-cmd --image=redis:7-alpine --rm -it --restart=Never -- redis-cli -h $(RELEASE_NAME)-helm-redis -p 6379 flushdb

redis-info: ## Ver información de Redis
	@kubectl run redis-cmd --image=redis:7-alpine --rm -it --restart=Never -- redis-cli -h $(RELEASE_NAME)-helm-redis -p 6379 info

redis-ping: ## Probar conexión Redis
	@kubectl run redis-cmd --image=redis:7-alpine --rm -it --restart=Never -- redis-cli -h $(RELEASE_NAME)-helm-redis -p 6379 ping

# =============================================================================
# COMANDOS DE UTILIDAD
# =============================================================================

helm-list: ## Listar releases de Helm
	@echo "📋 Releases de Helm:"
	helm list --all-namespaces

helm-status: ## Ver estado del release actual
	@echo "📊 Estado del release $(RELEASE_NAME):"
	helm status $(RELEASE_NAME) --namespace $(NAMESPACE) || echo "❌ Release no encontrado"

helm-history: ## Ver historial del release
	@echo "📜 Historial del release $(RELEASE_NAME):"
	helm history $(RELEASE_NAME) --namespace $(NAMESPACE) || echo "❌ Release no encontrado"

helm-rollback: ## Rollback a versión anterior
	@echo "⏪ Haciendo rollback del release $(RELEASE_NAME)..."
	helm rollback $(RELEASE_NAME) --namespace $(NAMESPACE)

kube-status: ## Ver estado completo de Kubernetes
	@echo "🔍 Estado completo de Kubernetes:"
	@echo "=== Namespaces ==="
	kubectl get namespaces
	@echo "\n=== Pods ==="
	kubectl get pods --all-namespaces
	@echo "\n=== Services ==="
	kubectl get services --all-namespaces
	@echo "\n=== Deployments ==="
	kubectl get deployments --all-namespaces

clean-pods: ## Limpiar pods en estado Error/Completed
	@echo "🧹 Limpiando pods..."
	kubectl delete pods --field-selector=status.phase=Failed --all-namespaces || true
	kubectl delete pods --field-selector=status.phase=Succeeded --all-namespaces || true
	@echo "✅ Pods limpiados"

minikube-status: ## Ver estado detallado de minikube
	@echo "🚀 Estado de minikube:"
	minikube status -p $(PROFILE)
	@echo "\n=== Addons habilitados ==="
	minikube addons list -p $(PROFILE) | grep enabled
	@echo "\n=== IP de minikube ==="
	minikube ip -p $(PROFILE) || echo "Minikube no está corriendo"

logs: ## Ver logs de todos los servicios
	@echo "📋 Logs de todos los servicios:"
	@echo "=== Redis ==="
	kubectl logs -l app.kubernetes.io/component=redis -n $(NAMESPACE) --tail=20 || true
	@echo "=== Redis Service ==="
	kubectl logs -l app.kubernetes.io/component=redis-service -n $(NAMESPACE) --tail=20 || true
	@echo "=== Write Service ==="
	kubectl logs -l app.kubernetes.io/component=write-service -n $(NAMESPACE) --tail=20 || true
	@echo "=== Read Service ==="
	kubectl logs -l app.kubernetes.io/component=read-service -n $(NAMESPACE) --tail=20 || true
	@echo "=== MongoDB ==="
	kubectl logs -l app.kubernetes.io/component=mongodb -n $(NAMESPACE) --tail=20 || true

port-forward: ## Configurar port-forward para todos los servicios
	@echo "🔗 Configurando port-forwards..."
	@echo "Write Service: http://localhost:8080"
	@echo "Read Service: http://localhost:8081"
	@echo "Redis Service: http://localhost:8082"
	@echo "Redis CLI: redis-cli -h localhost -p 6380"
	@echo "MongoDB: mongodb://admin:password123@localhost:27017/PRUEBA?authSource=admin"
	@echo ""
	@echo "Presiona Ctrl+C para detener todos los port-forwards"
	@kubectl port-forward service/$(RELEASE_NAME)-helm-write-service 8080:8080 > /dev/null 2>&1 &
	@kubectl port-forward service/$(RELEASE_NAME)-helm-read-service 8081:8081 > /dev/null 2>&1 &
	@kubectl port-forward service/$(RELEASE_NAME)-helm-redis-service 8082:8082 > /dev/null 2>&1 &
	@kubectl port-forward service/$(RELEASE_NAME)-helm-redis 6380:6379 > /dev/null 2>&1 &
	@kubectl port-forward service/$(RELEASE_NAME)-helm-mongodb 27017:27017

dashboard: ## Abrir dashboard de Kubernetes
	minikube dashboard -p $(PROFILE)

# =============================================================================
# FLUJO COMPLETO DEL TALLER
# =============================================================================

flow-execute: start build deploy port-forward-background redis-connect mongo-connect wait-services ## Ejecutar flujo completo del taller
	@echo ""
	@echo "🎉 ¡Flow CQRS completado exitosamente!"
	@echo ""
	@echo "=== Estado del Sistema ==="
	@make status || echo "⚠️  Sistema aún inicializando..."
	@echo ""
	@echo "=== Servicios Disponibles ==="
	@echo "Write Service: http://localhost:8080"
	@echo "Read Service: http://localhost:8081"
	@echo "Redis Service: http://localhost:8082"
	@echo "Redis: redis-cli -h localhost -p 6379"
	@echo "MongoDB: mongodb://admin:password123@localhost:27017/PRUEBA?authSource=admin"
	@echo ""
	@echo "Comandos útiles:"
	@echo "  make demo         - Ejecutar demo completo"
	@echo "  make test         - Probar todos los servicios"
	@echo "  make logs         - Ver logs de servicios"
	@echo "  make destroy      - Destruir el sistema"
	@echo ""
	@echo "📋 Abriendo dashboard..."
	@nohup minikube dashboard -p $(PROFILE) > dashboard.log 2>&1 & echo $$! > dashboard.pid
	@sleep 3
	@echo "✅ Dashboard iniciado (PID: $$(cat dashboard.pid))"

redis-connect: ## Configurar conexión Redis en background
	@echo "🔗 Configurando Redis port-forward..."
	@kubectl port-forward service/$(RELEASE_NAME)-helm-redis 6379:6379 > /dev/null 2>&1 &
	@echo "✅ Redis disponible en localhost:6379"
mongo-connect: ## Configurar conexión MongoDB en background
	@echo "🔗 Configurando MongoDB port-forward..."
	@kubectl port-forward service/$(RELEASE_NAME)-helm-mongodb 27017:27017 > /dev/null 2>&1 &
	@echo "✅ MongoDB disponible en localhost:27017"

port-forward-background: ## Configurar port-forwards en background
	@echo "🔗 Configurando port-forwards en background..."
	@kubectl port-forward service/$(RELEASE_NAME)-helm-write-service 8080:8080 > /dev/null 2>&1 &
	@kubectl port-forward service/$(RELEASE_NAME)-helm-read-service 8081:8081 > /dev/null 2>&1 &
	@kubectl port-forward service/$(RELEASE_NAME)-helm-redis-service 8082:8082 > /dev/null 2>&1 &
	@kubectl port-forward service/$(RELEASE_NAME)-helm-redis 6380:6379 > /dev/null 2>&1 &
	@kubectl port-forward service/$(RELEASE_NAME)-helm-mongodb 27017:27017 > /dev/null 2>&1 &
	@echo "✅ Port-forwards configurados en background"

wait-services: ## Esperar que los servicios estén listos
	@echo "⏳ Esperando que los servicios estén listos..."
	@kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=mongodb --timeout=300s
	@kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=redis --timeout=300s
	@kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=write-service --timeout=300s
	@kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=read-service --timeout=300s
	@echo "✅ Servicios principales están listos"
	@echo ""
	@echo "📋 Conexiones disponibles:"
	@echo "Write Service: http://localhost:8080"
	@echo "Read Service: http://localhost:8081"
	@echo "Redis Service: http://localhost:8082"
	@echo "Redis: redis-cli -h localhost -p 6379"
	@echo "MongoDB: mongodb://admin:password123@localhost:27017/PRUEBA?authSource=admin"


## make redis-set KEY=usuario VALUE=admin
## make redis-set KEY=contador VALUE=100
## make redis-set KEY=producto VALUE="Laptop Dell"
## make redis-get KEY=usuario