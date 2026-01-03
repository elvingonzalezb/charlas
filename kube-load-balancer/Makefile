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

deploy: ## Desplegar sistema CQRS con LoadBalancer y HPA
	@echo "🚀 Desplegando sistema CQRS con LoadBalancer..."
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
	kubectl apply -f manifiestos/write-hpa.yaml
	kubectl apply -f manifiestos/read-hpa.yaml
	@echo "⏳ Esperando Ingress Controller..."
	@kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s || echo "⚠️  Ingress controller tardando"
	kubectl apply -f manifiestos/ingress.yaml
	@echo "✅ Sistema CQRS desplegado con LoadBalancer y HPA!"

demo: ## Ejecutar demo del sistema CQRS con LoadBalancer
	@echo "🎯 Ejecutando Demo CQRS con LoadBalancer..."
	@echo ""
	@echo "🔌 Verificando LoadBalancer IPs..."
	@WRITE_IP=$$(kubectl get service write-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo ""); \
	READ_IP=$$(kubectl get service read-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo ""); \
	if [ -z "$$WRITE_IP" ] || [ -z "$$READ_IP" ]; then \
		echo "⚠️  LoadBalancer IPs no disponibles. Usando port-forward..."; \
		kubectl port-forward service/write-service 8080:8080 > /dev/null 2>&1 & \
		kubectl port-forward service/read-service 8081:8081 > /dev/null 2>&1 & \
		sleep 3; \
		WRITE_URL="http://localhost:8080"; \
		READ_URL="http://localhost:8081"; \
	else \
		echo "✅ LoadBalancer IPs disponibles"; \
		WRITE_URL="http://$$WRITE_IP:8080"; \
		READ_URL="http://$$READ_IP:8081"; \
	fi; \
	echo ""; \
	echo "1️⃣ Creando orden en Write Service ($$WRITE_URL)..."; \
	curl -X POST $$WRITE_URL/write/orders \
		-H "Content-Type: application/json" \
		-d '{"orderId":"ORD-DEMO-001","customerId":"CUST-DEMO","productName":"Producto Demo","quantity":2,"price":50.00}' \
		-w "\n" || echo "❌ Write service no disponible"; \
	echo ""; \
	echo "⏳ Esperando 3 segundos..."; \
	sleep 3; \
	echo ""; \
	echo "2️⃣ Leyendo órdenes desde Read Service ($$READ_URL)..."; \
	curl -X GET $$READ_URL/read/customers/CUST-DEMO/orders \
		-H "Content-Type: application/json" \
		-w "\n" || echo "❌ Read service no disponible"; \
	echo ""; \
	if [ -z "$$WRITE_IP" ] || [ -z "$$READ_IP" ]; then \
		echo "🔗 Limpiando port-forwards..."; \
		pkill -f "kubectl port-forward service/write-service" || true; \
		pkill -f "kubectl port-forward service/read-service" || true; \
	fi; \
	echo "✅ Demo completado!"

clean-all: ## Limpiar todo el sistema
	@echo "💥 Limpiando TODO el sistema..."
	@read -p "¿Estás seguro? (y/n): " confirm && [ "$$confirm" = "y" ]
	make stop-tunnel
	make mongo-stop
	make stop-dashboard
	@echo "🗑️  Eliminando recursos CQRS..."
	@if kubectl cluster-info >/dev/null 2>&1; then \
		kubectl delete deployments,services,ingress,secrets,configmaps -l app=mongodb --ignore-not-found=true || true; \
		kubectl delete deployments,services,ingress,secrets,configmaps -l app=write-service --ignore-not-found=true || true; \
		kubectl delete deployments,services,ingress,secrets,configmaps -l app=read-service --ignore-not-found=true || true; \
		kubectl delete hpa write-service-hpa read-service-hpa --ignore-not-found=true || true; \
		kubectl delete ingress cqrs-ingress --ignore-not-found=true || true; \
		kubectl delete secrets mongodb-secret app-config-secret --ignore-not-found=true || true; \
		kubectl delete configmaps mongodb-init-config --ignore-not-found=true || true; \
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

tunnel: ## Iniciar túnel para LoadBalancer (ejecutar en terminal separado)
	@echo "🔌 Iniciando túnel minikube para LoadBalancer..."
	@echo "IMPORTANTE: Mantén este comando corriendo en un terminal separado"
	@echo "Presiona Ctrl+C para detener el túnel"
	minikube tunnel -p $(PROFILE)

hpa-status: ## Ver estado del autoescalado horizontal
	@echo "=== Estado del HPA ==="
	kubectl get hpa
	@echo ""
	@echo "=== Métricas de CPU y Memoria ==="
	@kubectl top pods -l 'app in (write-service,read-service)' || echo "⚠️  Métricas aún no disponibles (esperando metrics-server)"

hpa-demo: ## Demostrar autoescalado horizontal
	@echo "🎯 Demostración HPA - Autoescalado Horizontal"
	@echo ""
	@echo "1️⃣ Estado inicial:"
	make hpa-status
	@echo ""
	@echo "2️⃣ Aplicando HPA con umbrales bajos..."
	kubectl apply -f manifiestos/write-hpa.yaml
	kubectl apply -f manifiestos/read-hpa.yaml
	@echo "✅ HPA actualizado"
	@echo ""
	@echo "3️⃣ Esperando 30 segundos para que HPA evalúe..."
	@sleep 30
	@echo ""
	@echo "4️⃣ Estado después de HPA:"
	make hpa-status
	@echo ""
	@echo "📈 ¡Observa cómo el HPA escala automáticamente!"
	@echo "Ejecuta 'make hpa-watch' para monitorear en tiempo real"

hpa-watch: ## Monitorear HPA en tiempo real
	@echo "👀 Monitoreando HPA en tiempo real (Ctrl+C para salir)..."
	@echo ""
	watch -n 5 'kubectl get hpa && echo "" && kubectl get pods -l "app in (write-service,read-service)" && echo "" && kubectl top pods -l "app in (write-service,read-service)"'

hpa-reset: ## Restaurar HPA a valores normales
	@echo "🔄 Restaurando HPA a valores normales..."
	@sed -i '' 's/averageUtilization: 10/averageUtilization: 70/g' manifiestos/write-hpa.yaml
	@sed -i '' 's/averageUtilization: 20/averageUtilization: 80/g' manifiestos/write-hpa.yaml
	@sed -i '' 's/averageUtilization: 10/averageUtilization: 70/g' manifiestos/read-hpa.yaml
	@sed -i '' 's/averageUtilization: 20/averageUtilization: 80/g' manifiestos/read-hpa.yaml
	kubectl apply -f manifiestos/write-hpa.yaml
	kubectl apply -f manifiestos/read-hpa.yaml
	@echo "✅ HPA restaurado a valores normales (CPU: 70%, Memoria: 80%)"

pod-demo: ## Demostrar auto-recuperación eliminando pods
	@echo "🔄 Demostración: Auto-recuperación de Pods"
	@echo ""
	@echo "1️⃣ Estado inicial de pods:"
	@kubectl get pods -l 'app in (write-service,read-service)' -o wide
	@echo ""
	@echo "2️⃣ Eliminando un pod de write-service..."
	@POD_NAME=$$(kubectl get pods -l app=write-service -o jsonpath='{.items[0].metadata.name}'); \
	echo "Eliminando pod: $$POD_NAME"; \
	kubectl delete pod $$POD_NAME
	@echo ""
	@echo "3️⃣ Esperando 10 segundos..."
	@sleep 10
	@echo ""
	@echo "4️⃣ Estado después de eliminación:"
	@kubectl get pods -l 'app in (write-service,read-service)' -o wide
	@echo ""
	@echo "📈 ¡Observa cómo Kubernetes creó automáticamente un nuevo pod!"
	@echo "Ejecuta 'make pod-watch' para monitorear en tiempo real"

pod-watch: ## Monitorear pods en tiempo real
	@echo "👀 Monitoreando pods en tiempo real (Ctrl+C para salir)..."
	@echo ""
	watch -n 2 'kubectl get pods -l "app in (write-service,read-service)" -o wide'

pod-chaos: ## Simular fallas eliminando pods aleatoriamente
	@echo "🌪️  Simulación de Chaos Engineering"
	@echo ""
	@echo "1️⃣ Estado inicial:"
	@kubectl get pods -l 'app in (write-service,read-service)' --no-headers | wc -l | xargs echo "Total pods:"
	@echo ""
	@echo "2️⃣ Eliminando 2 pods aleatoriamente..."
	@kubectl get pods -l 'app in (write-service,read-service)' -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | head -2 | while read pod; do \
		echo "Eliminando: $$pod"; \
		kubectl delete pod $$pod & \
	done
	@echo ""
	@echo "3️⃣ Esperando recuperación..."
	@sleep 15
	@echo ""
	@echo "4️⃣ Estado final:"
	@kubectl get pods -l 'app in (write-service,read-service)' -o wide
	@echo ""
	@echo "🛡️  ¡Sistema auto-recuperado! Kubernetes mantuvo la disponibilidad"

pod-stress: ## Generar carga para activar HPA
	@echo "💪 Generando carga para activar HPA..."
	@echo ""
	@echo "Ejecutando 2000 requests (controlado)..."
	@for batch in $$(seq 1 20); do \
		echo "Batch $$batch/20"; \
		for i in $$(seq 1 100); do \
			curl -s http://127.0.0.1:8080/write/health > /dev/null & \
			curl -s http://127.0.0.1:8081/read/health > /dev/null & \
		done; \
		sleep 2; \
	done
	@echo "Carga completada. Verifica HPA con 'make hpa-status'"

loadbalancer-ips: ## Obtener IPs externas de LoadBalancer
	@echo "=== IPs de LoadBalancer ==="
	@echo "Write Service:"
	@kubectl get service write-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' && echo
	@echo "Read Service:"
	@kubectl get service read-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' && echo
	@echo ""
	@echo "Si no hay IPs, ejecuta 'make tunnel' en otro terminal"

ingress-info: ## Información del Ingress
	@echo "=== Información del Ingress ==="
	kubectl get ingress cqrs-ingress
	@echo ""
	@echo "=== Configurar /etc/hosts ==="
	@echo "Agrega esta línea a /etc/hosts:"
	@echo "$$(minikube ip -p $(PROFILE)) cqrs.local"
	@echo ""
	@echo "URLs disponibles:"
	@echo "http://cqrs.local/write - Write Service"
	@echo "http://cqrs.local/read - Read Service"

logs-write: ## Ver logs del write service
	kubectl logs -l app=write-service --tail=50

logs-read: ## Ver logs del read service
	kubectl logs -l app=read-service --tail=50

logs-mongo: ## Ver logs de MongoDB
	kubectl logs -l app=mongodb --tail=50

health: ## Verificar health con LoadBalancer/Ingress
	@echo "🏥 Verificando Health de los Servicios..."
	@echo ""
	@WRITE_IP=$$(kubectl get service write-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo ""); \
	READ_IP=$$(kubectl get service read-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo ""); \
	if [ -n "$$WRITE_IP" ] && [ -n "$$READ_IP" ]; then \
		echo "✅ Usando LoadBalancer IPs"; \
		WRITE_URL="http://$$WRITE_IP:8080"; \
		READ_URL="http://$$READ_IP:8081"; \
	else \
		echo "🔗 LoadBalancer no disponible, usando Ingress"; \
		WRITE_URL="http://cqrs.local"; \
		READ_URL="http://cqrs.local"; \
	fi; \
	echo ""; \
	echo "1️⃣ Write Service Health ($$WRITE_URL):"; \
	curl -s $$WRITE_URL/write/health | jq '.' 2>/dev/null || curl -s $$WRITE_URL/write/health || echo "❌ Write service no disponible"; \
	echo ""; \
	echo "2️⃣ Read Service Health ($$READ_URL):"; \
	curl -s $$READ_URL/read/health | jq '.' 2>/dev/null || curl -s $$READ_URL/read/health || echo "❌ Read service no disponible"; \
	echo ""; \
	echo "3️⃣ Kubernetes Pods Status:"; \
	kubectl get pods -l 'app in (write-service,read-service)' -o custom-columns="NAME:.metadata.name,READY:.status.containerStatuses[0].ready,RESTARTS:.status.containerStatuses[0].restartCount,STATUS:.status.phase"; \
	echo "✅ Health check completado!"

health-write: ## Verificar health del write service con LoadBalancer
	@echo "🏥 Write Service Health Check..."
	@WRITE_IP=$$(kubectl get service write-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo ""); \
	if [ -n "$$WRITE_IP" ]; then \
		WRITE_URL="http://$$WRITE_IP:8080"; \
	else \
		WRITE_URL="http://cqrs.local"; \
	fi; \
	echo "Verificando: $$WRITE_URL/write/health"; \
	curl -s $$WRITE_URL/write/health | jq '.' 2>/dev/null || curl -s $$WRITE_URL/write/health || echo "❌ Write service no disponible"

health-read: ## Verificar health del read service con LoadBalancer
	@echo "🏥 Read Service Health Check..."
	@READ_IP=$$(kubectl get service read-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo ""); \
	if [ -n "$$READ_IP" ]; then \
		READ_URL="http://$$READ_IP:8081"; \
	else \
		READ_URL="http://cqrs.local"; \
	fi; \
	echo "Verificando: $$READ_URL/read/health"; \
	curl -s $$READ_URL/read/health | jq '.' 2>/dev/null || curl -s $$READ_URL/read/health || echo "❌ Read service no disponible"

test-read: ## Ejecutar solo Read Service para consultar órdenes
	@echo "📖 Ejecutando Read Service - Consulta de Órdenes"
	@echo ""
	@READ_IP=$$(kubectl get service read-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo ""); \
	if [ -n "$$READ_IP" ]; then \
		READ_URL="http://$$READ_IP:8081"; \
	else \
		READ_URL="http://127.0.0.1:8081"; \
	fi; \
	echo "📋 Consultando órdenes del cliente CUST-DEMO:"; \
	curl -X GET $$READ_URL/read/customers/CUST-DEMO/orders \
		-H "Content-Type: application/json" \
		-w "\n" || echo "❌ Read service no disponible"; \
	echo "✅ Read Service ejecutado"

port-forward: ## Configurar port-forward para MongoDB
	@echo "🔗 Configurando port-forward para MongoDB..."
	@echo "Ejecutando: kubectl port-forward service/mongodb-service 27017:27017"
	@echo "Presiona Ctrl+C para detener el port-forward"
	@echo ""
	@echo "Una vez activo, conecta MongoDB Compass con:"
	@echo "mongodb://admin:password123@localhost:27017/PRUEBA?authSource=admin"
	@echo ""
	kubectl port-forward service/mongodb-service 27017:27017

mongo-connect: ## Iniciar port-forward para MongoDB en background
	@echo "🔗 Iniciando port-forward para MongoDB..."
	@kubectl port-forward service/mongodb-service 27017:27017 > /dev/null 2>&1 & echo $$! > mongo.pid
	@sleep 2
	@echo "✅ Port-forward activo (PID: $$(cat mongo.pid))"
	@echo ""
	@echo "📋 Conexión MongoDB Compass:"
	@echo "mongodb://admin:password123@localhost:27017/PRUEBA?authSource=admin"
	@echo ""
	@echo "Para detener: make mongo-stop"

mongo-stop: ## Detener port-forward de MongoDB
	@if [ -f mongo.pid ]; then \
		echo "🛑 Deteniendo port-forward MongoDB (PID: $$(cat mongo.pid))"; \
		kill $$(cat mongo.pid) 2>/dev/null || true; \
		rm -f mongo.pid; \
		echo "✅ Port-forward detenido"; \
	else \
		echo "⚠️  No hay port-forward de MongoDB corriendo"; \
	fi

urls: ## Mostrar URLs de los servicios LoadBalancer
	@echo "=== URLs de los Servicios LoadBalancer ==="
	@if minikube status -p $(PROFILE) >/dev/null 2>&1; then \
		WRITE_IP=$$(kubectl get service write-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo ""); \
		READ_IP=$$(kubectl get service read-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo ""); \
		if [ -n "$$WRITE_IP" ] && [ -n "$$READ_IP" ]; then \
			echo "✅ LoadBalancer URLs disponibles:"; \
			echo "Write Service: http://$$WRITE_IP:8080/write"; \
			echo "Read Service:  http://$$READ_IP:8081/read"; \
			echo ""; \
			echo "Health Checks:"; \
			echo "Write Health:  http://$$WRITE_IP:8080/write/health"; \
			echo "Read Health:   http://$$READ_IP:8081/read/health"; \
		else \
			echo "⚠️  LoadBalancer IPs no disponibles. Ejecuta 'make tunnel' primero."; \
			echo "Mientras tanto, usa port-forward:"; \
			echo "Write Service: http://localhost:8080/write (port-forward)"; \
			echo "Read Service:  http://localhost:8081/read (port-forward)"; \
		fi; \
		echo ""; \
		echo "=== URLs via Ingress ==="; \
		echo "Configura /etc/hosts: $$(minikube ip -p $(PROFILE)) cqrs.local"; \
		echo "Write Service: http://cqrs.local/write"; \
		echo "Read Service:  http://cqrs.local/read"; \
		echo ""; \
		echo "=== MongoDB Connection ==="; \
		echo "Port-forward: kubectl port-forward service/mongodb-service 27017:27017"; \
		echo "URL: mongodb://admin:password123@localhost:27017/PRUEBA?authSource=admin"; \
	else \
		echo "⚠️  Minikube no está corriendo. Ejecuta 'make start' primero."; \
	fi

dashboard: ## Abrir dashboard de Kubernetes
	minikube dashboard -p $(PROFILE)

# =============================================================================
# FLUJO COMPLETO DEL TALLER
# =============================================================================

flow-execute: start build deploy tunnel-background mongo-connect wait-services ## Ejecutar flujo completo con LoadBalancer
	@echo ""
	@echo "🎉 ¡Flow CQRS con LoadBalancer completado!"
	@echo ""
	@echo "=== Estado del Sistema ==="
	@make hpa-status || echo "⚠️  HPA aún inicializando..."
	@echo ""
	@echo "=== IPs LoadBalancer ==="
	make loadbalancer-ips
	@echo ""
	@echo "=== Información Ingress ==="
	make ingress-info
	@echo ""
	@echo "Comandos útiles:"
	@echo "  make demo         - Ejecutar demo"
	@echo "  make hpa-status   - Ver autoescalado"
	@echo "  make mongo-stop   - Detener MongoDB port-forward"
	@echo "  make tunnel       - Túnel manual (si es necesario)"
	@echo ""
	@echo "📋 Abriendo dashboard..."
	@nohup minikube dashboard -p $(PROFILE) > dashboard.log 2>&1 & echo $$! > dashboard.pid
	@sleep 3
	@echo "✅ Dashboard iniciado (PID: $$(cat dashboard.pid))"

wait-services: ## Esperar a que los servicios estén listos
	@echo "⏳ Esperando servicios..."
	@kubectl wait --for=condition=ready pod -l app=write-service --timeout=120s || echo "⚠️  Write service tardando en iniciar"
	@kubectl wait --for=condition=ready pod -l app=read-service --timeout=120s || echo "⚠️  Read service tardando en iniciar"
	@sleep 10

tunnel-background: ## Iniciar túnel en background para flow-execute
	@echo "🔌 Iniciando túnel LoadBalancer en background..."
	@nohup minikube tunnel -p $(PROFILE) > tunnel.log 2>&1 & echo $$! > tunnel.pid
	@sleep 5
	@echo "✅ Túnel iniciado (PID: $$(cat tunnel.pid))"

stop-tunnel: ## Detener túnel en background
	@if [ -f tunnel.pid ]; then \
		echo "🛑 Deteniendo túnel (PID: $$(cat tunnel.pid))"; \
		kill $$(cat tunnel.pid) 2>/dev/null || true; \
		rm -f tunnel.pid tunnel.log; \
		echo "✅ Túnel detenido"; \
	else \
		echo "⚠️  No hay túnel en background corriendo"; \
	fi

stop-dashboard: ## Detener dashboard en background
	@if [ -f dashboard.pid ]; then \
		echo "🛑 Deteniendo dashboard (PID: $$(cat dashboard.pid))"; \
		kill $$(cat dashboard.pid) 2>/dev/null || true; \
		rm -f dashboard.pid dashboard.log; \
		echo "✅ Dashboard detenido"; \
	else \
		echo "⚠️  No hay dashboard corriendo en background"; \
	fi