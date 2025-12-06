# Makefile para Optimización de Imágenes Docker
DOCKER_USER = 
DOCKER_PASS = 
IMAGE_NAME = demo-springboot
TAG_BAD = bad
TAG_OPTIMIZED = optimized
TAG_V1 = v1.0.0
TAG_V2 = v2.0.0
APP_DIR_V1 = springboot-app
APP_DIR_V2 = springboot-app-v2

.PHONY: help init-podman start-podman stop-podman status-podman images build-bad run-bad dive-bad build-optimized run-optimized dive-optimized build-v1 build-v2 run-v1 run-v2 workflow-v1 workflow-v2 compare login push-v1 push-v2 clean details stop-all test-endpoints remove-image clean-none

help:
	@echo "Optimización de Imágenes Docker"
	@echo "============================================="
	@echo "INICIALES:"
	@echo "make init-podman    - 🚀 Inicializar Podman (primera vez)"
	@echo "make start-podman   - ▶️ Iniciar máquina Podman"
	@echo "make status-podman  - 🔍 Ver estado de Podman"
	@echo "make images         - 📷 Ver todas las imágenes"
	@echo ""
	@echo "IMAGEN MAL OPTIMIZADA (BAD):"
	@echo "make build-bad      - Construir imagen mal optimizada"
	@echo "make run-bad        - Ejecutar contenedor mal optimizado"
	@echo "make dive-bad       - Analizar imagen mal optimizada con dive"
	@echo ""
	@echo "IMAGEN OPTIMIZADA:"
	@echo "make build-optimized - Construir imagen optimizada"
	@echo "make run-optimized  - Ejecutar contenedor optimizado"
	@echo "make dive-optimized - Analizar imagen optimizada con dive"
	@echo ""
	@echo "FLUJOS COMPLETOS (VERSIONES):"
	@echo "make build-v1       - Construir imagen v1.0.0"
	@echo "make run-v1         - Ejecutar contenedor v1.0.0"
	@echo "make workflow-v1    - 🚀 Flujo completo v1.0.0 (build + run + push)"
	@echo "make build-v2       - Construir imagen v2.0.0"
	@echo "make run-v2         - Ejecutar contenedor v2.0.0"
	@echo "make workflow-v2    - 🚀 Flujo completo v2.0.0 (build + run + push)"
	@echo "make push-v1        - Subir imagen v1.0.0 a Docker Hub"
	@echo "make push-v2        - Subir imagen v2.0.0 a Docker Hub"
	@echo ""
	@echo "GESTIÓN:"
	@echo "make compare        - Comparar tamaños de imágenes"
	@echo "make details        - Ver detalles de las imágenes"
	@echo "make stop-all       - Detener todos los contenedores"
	@echo "make clean          - Limpiar imágenes locales"
	@echo "make clean-none     - Eliminar todas las imágenes <none>"
	@echo "make remove-image   - Eliminar imagen específica (solicita nombre)"
	@echo "make test-endpoints - Probar endpoints de la aplicación"
	@echo "make stop-podman    - ⏹️ Detener máquina Podman"
	@echo ""
	@echo "📝 Antes de usar, cambiar DOCKER_USER por tu usuario real"

# ============================================
# COMANDOS INICIALES
# ============================================

init-podman:
	@echo "🚀 Inicializando Podman..."
	podman machine init
	podman machine start
	@echo "✅ Podman inicializado y iniciado"

start-podman:
	@echo "▶️ Iniciando máquina Podman..."
	podman machine start
	@echo "✅ Máquina Podman iniciada"

stop-podman:
	@echo "⏹️ Deteniendo máquina Podman..."
	podman machine stop
	@echo "✅ Máquina Podman detenida"

status-podman:
	@echo "🔍 Estado de Podman:"
	podman machine list
	@echo ""
	@echo "Conexiones:"
	podman system connection list

images:
	@echo "📋 TODAS LAS IMÁGENES:"
	@echo "====================="
	podman images

# ============================================
# IMAGEN MAL OPTIMIZADA (BAD)
# ============================================

build-bad:
	@echo "🚀 Construyendo imagen MAL OPTIMIZADA..."
	@echo "Dockerfile: dockerfiles/Dockerfile.bad"
	podman build -f dockerfiles/Dockerfile.bad -t $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_BAD) $(APP_DIR_V1)
	@echo "✅ Imagen mal optimizada creada: $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_BAD)"

run-bad: build-bad stop-bad
	@echo "🚀 Ejecutando contenedor mal optimizado..."
	podman run -d --name demo-bad -p 8080:8080 $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_BAD)
	@echo "✅ Contenedor iniciado en http://localhost:8080"

stop-bad:
	@echo "🛑 Deteniendo contenedor mal optimizado..."
	podman stop demo-bad 2>/dev/null || true
	podman rm demo-bad 2>/dev/null || true

dive-bad:
	@echo "🔍 Analizando imagen mal optimizada con dive (interactivo)..."
	dive --source podman $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_BAD)

# ============================================
# IMAGEN OPTIMIZADA
# ============================================

build-optimized:
	@echo "🚀 Construyendo imagen OPTIMIZADA..."
	@echo "Dockerfile: dockerfiles/Dockerfile.optimized"
	podman build -f dockerfiles/Dockerfile.optimized -t $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_OPTIMIZED) $(APP_DIR_V1)
	@echo "✅ Imagen optimizada creada: $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_OPTIMIZED)"

run-optimized: build-optimized stop-optimized
	@echo "🚀 Ejecutando contenedor optimizado..."
	podman run -d --name demo-optimized -p 8081:8080 $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_OPTIMIZED)
	@echo "✅ Contenedor iniciado en http://localhost:8081"

stop-optimized:
	@echo "🛑 Deteniendo contenedor optimizado..."
	podman stop demo-optimized 2>/dev/null || true
	podman rm demo-optimized 2>/dev/null || true

dive-optimized:
	@echo "🔍 Analizando imagen optimizada con dive (interactivo)..."
	dive --source podman $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_OPTIMIZED)

# ============================================
# FLUJOS COMPLETOS (VERSIONES)
# ============================================

build-v1:
	@echo "🚀 Construyendo imagen v1.0.0..."
	@echo "Dockerfile: dockerfiles/Dockerfile.optimized"
	podman build -f dockerfiles/Dockerfile.optimized -t $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_V1) $(APP_DIR_V1)
	@echo "✅ Imagen v1.0.0 creada: $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_V1)"

run-v1: build-v1
	@echo "🚀 Ejecutando contenedor v1.0.0..."
	podman stop demo-v1 2>/dev/null || true
	podman rm demo-v1 2>/dev/null || true
	podman run -d --name demo-v1 -p 8082:8080 $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_V1)
	@echo "✅ Contenedor v1.0.0 iniciado en http://localhost:8082"

workflow-v1: build-v1 run-v1 push-v1
	@echo "✅ 🎉 Workflow v1.0.0 completado exitosamente!"
	@echo "Contenedor: http://localhost:8082"
	@echo "Imagen: $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_V1)"

push-v1: login
	@echo "📤 Subiendo imagen v1.0.0 a Docker Hub..."
	podman push $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_V1)
	@echo "✅ Imagen v1.0.0 subida: $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_V1)"

build-v2:
	@echo "🚀 Construyendo imagen v2.0.0..."
	@echo "Dockerfile: dockerfiles/Dockerfile.v2"
	podman build -f dockerfiles/Dockerfile.v2 -t $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_V2) $(APP_DIR_V2)
	@echo "✅ Imagen v2.0.0 creada: $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_V2)"

run-v2: build-v2
	@echo "🚀 Ejecutando contenedor v2.0.0..."
	podman stop demo-v2 2>/dev/null || true
	podman rm demo-v2 2>/dev/null || true
	podman run -d --name demo-v2 -p 8083:8080 $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_V2)
	@echo "✅ Contenedor v2.0.0 iniciado en http://localhost:8083"

workflow-v2: build-v2 run-v2 push-v2
	@echo "✅ 🎉 Workflow v2.0.0 completado exitosamente!"
	@echo "Contenedor: http://localhost:8083"
	@echo "Imagen: $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_V2)"

push-v2: login
	@echo "📤 Subiendo imagen v2.0.0 a Docker Hub..."
	podman push $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_V2)
	@echo "✅ Imagen v2.0.0 subida: $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_V2)"

# ============================================
# COMANDOS DE GESTIÓN
# ============================================

login:
	@echo "🔑 Haciendo login en Docker Hub..."
	@echo "$(DOCKER_PASS)" | podman login docker.io -u $(DOCKER_USER) --password-stdin
	@echo "✅ Login completado"

compare:
	@echo "📊 COMPARACIÓN DE TAMAÑOS:"
	@echo "=========================="
	@echo "❌ Imagen mal optimizada:"
	podman images $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_BAD) --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
	@echo "✅ Imagen optimizada:"
	podman images $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_OPTIMIZED) --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
	@echo ""
	@echo "🔍 Para analizar con dive:"
	@echo "dive $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_BAD)"
	@echo "dive $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_OPTIMIZED)"

details:
	@echo "🔍 DETALLES DE LAS IMÁGENES:"
	@echo "============================"
	@echo "❌ Imagen mal optimizada:"
	podman inspect $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_BAD) --format '{{.Size}} bytes, {{len .RootFS.Layers}} layers' 2>/dev/null || echo "Imagen no encontrada"
	@echo "✅ Imagen optimizada:"
	podman inspect $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_OPTIMIZED) --format '{{.Size}} bytes, {{len .RootFS.Layers}} layers' 2>/dev/null || echo "Imagen no encontrada"

stop-all:
	@echo "🛑 Deteniendo todos los contenedores..."
	podman stop demo-bad demo-optimized demo-v1 demo-v2 2>/dev/null || true
	podman rm demo-bad demo-optimized demo-v1 demo-v2 2>/dev/null || true
	@echo "✅ Todos los contenedores detenidos"

clean:
	@echo "🧹 Limpiando imágenes locales..."
	podman rmi $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_BAD) 2>/dev/null || true
	podman rmi $(DOCKER_USER)/$(IMAGE_NAME):$(TAG_OPTIMIZED) 2>/dev/null || true

test-endpoints:
	@echo "🧪 Probando endpoints de la aplicación..."
	@echo "📍 GET /"
	curl -s http://localhost:8081/
	@echo ""
	@echo "📍 GET /hello"
	curl -s http://localhost:8081/health
	@echo ""
	@echo "📍 GET /actuator/health"
	curl -s http://localhost:8081/info

remove-image:
	@echo "🗑️ ELIMINAR IMAGEN ESPECÍFICA"
	@echo "=============================="
	@echo "Imágenes disponibles:"
	@podman images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
	@echo ""
	@read -p "Ingresa el nombre de la imagen a eliminar (formato: repository:tag): " IMAGE_TO_REMOVE; \
	if [ -n "$$IMAGE_TO_REMOVE" ]; then \
		echo "Eliminando imagen: $$IMAGE_TO_REMOVE"; \
		podman rmi "$$IMAGE_TO_REMOVE" || echo "❌ Error al eliminar la imagen"; \
	else \
		echo "❌ No se proporcionó nombre de imagen"; \
	fi

clean-none:
	@echo "🧹 Eliminando imágenes <none>..."
	@NONE_IMAGES=$$(podman images -f "dangling=true" -q); \
	if [ -n "$$NONE_IMAGES" ]; then \
		echo "Eliminando $$(echo "$$NONE_IMAGES" | wc -l) imágenes sin etiqueta..."; \
		echo "$$NONE_IMAGES" | xargs podman rmi; \
		echo "✅ Imágenes <none> eliminadas"; \
	else \
		echo "✅ No hay imágenes <none> para eliminar"; \
	fi