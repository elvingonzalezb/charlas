#!/bin/bash

# Script para construir ambas imágenes y compararlas

set -e

echo "🚀 Iniciando construcción de imágenes Docker..."
echo "================================================"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
APP_DIR="../springboot-app"
DOCKER_USER="tu-usuario-dockerhub"  # Cambiar por tu usuario
IMAGE_NAME="demo-springboot"
TAG_BAD="bad"
TAG_OPTIMIZED="optimized"

cd "$(dirname "$0")"

echo -e "${YELLOW}📦 Construyendo imagen MAL OPTIMIZADA...${NC}"
echo "Dockerfile: ../dockerfiles/Dockerfile.bad"
podman build -f ../dockerfiles/Dockerfile.bad -t ${DOCKER_USER}/${IMAGE_NAME}:${TAG_BAD} ${APP_DIR}

echo -e "${YELLOW}📦 Construyendo imagen OPTIMIZADA...${NC}"
echo "Dockerfile: ../dockerfiles/Dockerfile.optimized"
podman build -f ../dockerfiles/Dockerfile.optimized -t ${DOCKER_USER}/${IMAGE_NAME}:${TAG_OPTIMIZED} ${APP_DIR}

echo -e "${GREEN}✅ Construcción completada!${NC}"
echo ""

echo "📊 COMPARACIÓN DE TAMAÑOS:"
echo "=========================="
echo -e "${RED}❌ Imagen mal optimizada:${NC}"
podman images ${DOCKER_USER}/${IMAGE_NAME}:${TAG_BAD} --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"

echo -e "${GREEN}✅ Imagen optimizada:${NC}"
podman images ${DOCKER_USER}/${IMAGE_NAME}:${TAG_OPTIMIZED} --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"

echo ""
echo "🔍 Para analizar las imágenes con dive:"
echo "dive ${DOCKER_USER}/${IMAGE_NAME}:${TAG_BAD}"
echo "dive ${DOCKER_USER}/${IMAGE_NAME}:${TAG_OPTIMIZED}"

echo ""
echo "📤 Para subir a Docker Hub:"
echo "./push-images.sh"