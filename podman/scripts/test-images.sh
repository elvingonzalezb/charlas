#!/bin/bash

# Script para probar ambas imágenes

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Variables
DOCKER_USER="tu-usuario-dockerhub"
IMAGE_NAME="demo-springboot"
TAG_BAD="bad"
TAG_OPTIMIZED="optimized"

echo -e "${YELLOW}🧪 Probando imágenes Docker...${NC}"
echo "================================"

# Función para probar una imagen
test_image() {
    local tag=$1
    local port=$2
    local container_name="test-${tag}"
    
    echo -e "${YELLOW}🚀 Probando imagen: ${tag}${NC}"
    
    # Ejecutar contenedor
    podman run -d --name ${container_name} -p ${port}:8080 ${DOCKER_USER}/${IMAGE_NAME}:${tag}
    
    # Esperar que inicie
    echo "Esperando que la aplicación inicie..."
    sleep 10
    
    # Probar endpoints
    echo "Probando endpoints:"
    curl -s http://localhost:${port}/ && echo ""
    curl -s http://localhost:${port}/health && echo ""
    curl -s http://localhost:${port}/info && echo ""
    
    # Mostrar logs
    echo -e "${YELLOW}📋 Últimos logs:${NC}"
    podman logs --tail 5 ${container_name}
    
    # Limpiar
    podman stop ${container_name}
    podman rm ${container_name}
    
    echo -e "${GREEN}✅ Prueba completada para ${tag}${NC}"
    echo ""
}

# Probar imagen mal optimizada
test_image ${TAG_BAD} 8081

# Probar imagen optimizada
test_image ${TAG_OPTIMIZED} 8082

echo -e "${GREEN}🎉 Todas las pruebas completadas!${NC}"