#!/bin/bash

# Script para subir imágenes a Docker Hub

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variables
DOCKER_USER="tu-usuario-dockerhub"  # Cambiar por tu usuario
IMAGE_NAME="demo-springboot"
TAG_BAD="bad"
TAG_OPTIMIZED="optimized"

echo -e "${YELLOW}🔐 Iniciando sesión en Docker Hub...${NC}"
echo "Asegúrate de estar logueado: podman login docker.io"

echo -e "${YELLOW}📤 Subiendo imagen mal optimizada...${NC}"
podman push ${DOCKER_USER}/${IMAGE_NAME}:${TAG_BAD}

echo -e "${YELLOW}📤 Subiendo imagen optimizada...${NC}"
podman push ${DOCKER_USER}/${IMAGE_NAME}:${TAG_OPTIMIZED}

echo -e "${GREEN}✅ Imágenes subidas exitosamente!${NC}"
echo ""
echo "🌐 URLs de Docker Hub:"
echo "https://hub.docker.com/r/${DOCKER_USER}/${IMAGE_NAME}/tags"
echo ""
echo "📥 Para descargar:"
echo "podman pull ${DOCKER_USER}/${IMAGE_NAME}:${TAG_BAD}"
echo "podman pull ${DOCKER_USER}/${IMAGE_NAME}:${TAG_OPTIMIZED}"