# Kubernetes - Guía Teórica para Charla

## ¿Qué es Kubernetes?

Kubernetes (K8s) es una plataforma de orquestación de contenedores que automatiza el despliegue, escalado y gestión de aplicaciones containerizadas.

**Analogía simple:** Si Docker es como tener un contenedor de envío, Kubernetes es como el puerto que gestiona miles de contenedores - decide dónde van, cómo se conectan y qué hacer si algo falla.

## Arquitectura de Kubernetes

### Control Plane (Plano de Control)
El "cerebro" del cluster que toma todas las decisiones:

- **API Server**: Punto de entrada para todas las operaciones
- **etcd**: Base de datos que guarda el estado del cluster
- **Scheduler**: Decide en qué nodo ejecutar cada Pod
- **Controller Manager**: Supervisa y mantiene el estado deseado

### Worker Nodes (Nodos de Trabajo)
Donde realmente se ejecutan las aplicaciones:

- **kubelet**: Agente que ejecuta y supervisa los Pods
- **kube-proxy**: Maneja la red y balanceo de carga
- **Container Runtime**: Docker, containerd, etc.

## Conceptos Fundamentales

### 1. Pod
**El átomo de Kubernetes** - La unidad más pequeña desplegable.

```yaml
# Ejemplo básico
apiVersion: v1
kind: Pod
metadata:
  name: mi-app
spec:
  containers:
  - name: app
    image: nginx:latest
    ports:
    - containerPort: 80
```

**Características:**
- Contiene uno o más contenedores
- Comparten red y almacenamiento
- Efímeros - pueden morir y recrearse
- IP única dentro del cluster

### 2. Deployment
**Gestor de Pods** - Controla el ciclo de vida de múltiples Pods.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mi-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mi-app
  template:
    metadata:
      labels:
        app: mi-app
    spec:
      containers:
      - name: app
        image: nginx:latest
```

**Funciones:**
- Mantiene el número deseado de réplicas
- Rolling updates sin downtime
- Rollback automático si algo falla
- Self-healing - recrea Pods que fallan

### 3. Service
**Punto de acceso estable** - Expone Pods a la red.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mi-service
spec:
  selector:
    app: mi-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

**Tipos de Service:**
- **ClusterIP**: Solo accesible dentro del cluster
- **NodePort**: Accesible desde fuera en puerto específico
- **LoadBalancer**: Usa balanceador de carga externo
- **ExternalName**: Alias DNS para servicios externos

### 4. ConfigMap y Secret
**Gestión de configuración** - Separa código de configuración.

```yaml
# ConfigMap - Datos no sensibles
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_url: "mongodb://db:27017"
  log_level: "info"

---
# Secret - Datos sensibles (base64)
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
data:
  username: YWRtaW4=  # admin
  password: cGFzcw==  # pass
```

### 5. Namespace
**Aislamiento lógico** - Divide el cluster en espacios virtuales.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: desarrollo
```

**Usos:**
- Separar entornos (dev, test, prod)
- Aislar equipos o proyectos
- Aplicar políticas específicas
- Gestión de recursos

## Flujo de Trabajo Típico

### 1. Desarrollo Local
```bash
# Escribir manifiestos YAML
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### 2. Kubernetes Procesa
1. **API Server** valida y guarda en **etcd**
2. **Scheduler** asigna Pods a nodos
3. **kubelet** descarga imágenes y ejecuta contenedores
4. **kube-proxy** configura reglas de red

### 3. Monitoreo Continuo
- Controllers verifican estado actual vs deseado
- Self-healing automático
- Escalado según demanda

## Ventajas de Kubernetes

### ✅ Escalabilidad
- Escalado horizontal automático
- Manejo de miles de contenedores
- Distribución inteligente de carga

### ✅ Alta Disponibilidad
- Self-healing automático
- Rolling updates sin downtime
- Distribución multi-zona

### ✅ Portabilidad
- Funciona en cualquier cloud
- Mismos manifiestos en dev y prod
- Abstrae la infraestructura

### ✅ Gestión Declarativa
- Describes el estado deseado
- Kubernetes se encarga del "cómo"
- Versionado de configuración

## Ejemplo Práctico: Sistema CQRS

En nuestro taller implementamos:

```
┌─────────────────┐    ┌─────────────────┐
│   Write Service │    │   Read Service  │
│   (Deployment)  │    │   (Deployment)  │
└─────────────────┘    └─────────────────┘
         │                       │
         └───────┬───────────────┘
                 │
         ┌─────────────────┐
         │    MongoDB      │
         │  (Deployment)   │
         └─────────────────┘
```

### Componentes Desplegados:
1. **3 Deployments**: write-service, read-service, mongodb
2. **3 Services**: Exponen cada deployment
3. **2 ConfigMaps**: Configuración de MongoDB
4. **2 Secrets**: Credenciales de base de datos

### Flujo de Datos:
1. **Write Service** recibe requests → guarda en MongoDB
2. **Read Service** consulta MongoDB → devuelve datos
3. **Services** balancean carga entre réplicas
4. **Kubernetes** mantiene todo funcionando

## Comandos Esenciales

```bash
# Ver recursos
kubectl get pods
kubectl get services
kubectl get deployments

# Describir recursos
kubectl describe pod <nombre>
kubectl describe service <nombre>

# Logs y debugging
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- /bin/bash

# Aplicar manifiestos
kubectl apply -f archivo.yaml
kubectl apply -f directorio/

# Eliminar recursos
kubectl delete -f archivo.yaml
kubectl delete pod <nombre>
```

## Conceptos Avanzados (Mención Rápida)

### Ingress
- Enrutamiento HTTP/HTTPS inteligente
- SSL termination
- Path-based routing

### Persistent Volumes
- Almacenamiento persistente
- Independiente del ciclo de vida del Pod
- Diferentes tipos de storage

### RBAC (Role-Based Access Control)
- Control de permisos granular
- Usuarios, roles y políticas
- Seguridad a nivel de namespace

### Helm
- Gestor de paquetes para Kubernetes
- Templates y valores parametrizables
- Versionado de releases

## Ecosistema Kubernetes

### Distribuciones Populares:
- **Minikube**: Desarrollo local
- **Kind**: Kubernetes en Docker
- **K3s**: Lightweight para IoT/Edge
- **EKS/GKE/AKS**: Servicios cloud managed

### Herramientas Complementarias:
- **kubectl**: CLI oficial
- **Helm**: Package manager
- **Prometheus**: Monitoreo
- **Grafana**: Visualización
- **Istio**: Service mesh

## Mejores Prácticas

### 🎯 Diseño de Aplicaciones
- Aplicaciones stateless
- Health checks obligatorios
- Graceful shutdown
- 12-factor app principles

### 🔒 Seguridad
- Usar Secrets para datos sensibles
- Principio de menor privilegio
- Escaneo de vulnerabilidades
- Network policies

### 📊 Monitoreo
- Logs estructurados
- Métricas de aplicación
- Alertas proactivas
- Distributed tracing

### 🚀 Despliegue
- Rolling updates
- Blue-green deployments
- Canary releases
- Automated testing

## Conclusión

Kubernetes transforma la gestión de aplicaciones containerizadas de un proceso manual y propenso a errores en un sistema automatizado, escalable y confiable.

**Beneficios clave:**
- **Automatización**: Menos trabajo manual
- **Confiabilidad**: Self-healing y alta disponibilidad
- **Escalabilidad**: Crece con tu aplicación
- **Portabilidad**: Funciona en cualquier lugar

**En nuestro taller veremos estos conceptos en acción** construyendo un sistema CQRS completo con Kubernetes, desde el desarrollo local hasta el despliegue en producción.