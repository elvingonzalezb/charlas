# Redis con Docker, Kubernetes y Helm

Este proyecto implementa un servicio Redis completo usando Docker, Kubernetes y Helm.

## Estructura del Proyecto

```
kube-redis-helm/
├── docker/
│   └── redis-service/
│       ├── Dockerfile
│       └── redis.conf
├── manifiestos/
│   ├── redis-deployment.yaml
│   └── redis-service.yaml
├── redis-chart/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       └── service.yaml
├── Makefile
└── README.md
```

## Prerrequisitos

- Docker
- Kubernetes (minikube, kind, o cluster)
- Helm 3.x
- kubectl

## Instalación y Despliegue

### Opción 1: Usando Kubernetes Manifiestos

```bash
# Desplegar Redis
make deploy-k8s

# Verificar estado
make status

# Probar conexión
make test-redis
```

### Opción 2: Usando Helm Chart

```bash
# Desplegar con Helm
make deploy-helm

# Verificar estado
make status

# Probar conexión
make test-redis
```

### Construir Imagen Docker (Opcional)

```bash
# Construir imagen personalizada
make build-docker
```

## Comandos Útiles

```bash
# Ver ayuda
make help

# Limpiar recursos de Kubernetes
make clean-k8s

# Limpiar release de Helm
make clean-helm

# Ver estado de recursos
make status
```

## Configuración

### Redis Configuration
- Puerto: 6379
- Memoria máxima: 256MB
- Política de memoria: allkeys-lru
- Persistencia: Configurada para guardar cada 15 minutos

### Recursos de Kubernetes
- CPU: 100m (request) / 200m (limit)
- Memoria: 128Mi (request) / 256Mi (limit)

## Acceso a Redis

Una vez desplegado, Redis estará disponible en:
- Servicio: `redis-service`
- Puerto: `6379`
- Namespace: `default`

Para conectarse desde otro pod:
```bash
redis-cli -h redis-service -p 6379
```