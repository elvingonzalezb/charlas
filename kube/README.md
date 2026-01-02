# Kubernetes con Minikube - Guía Completa

## 📋 Requisitos Previos

### Software Necesario
- **Minikube** >= 1.30
- **kubectl** (cliente de Kubernetes)
- **Podman** (como driver por defecto)
- **Make** (incluido en macOS/Linux)

### Verificar Instalación
```bash
minikube version
kubectl version --client
podman --version
make --version
```

---

## 🚀 Inicio Rápido

### 1. Ver Comandos Disponibles
```bash
make help
```

### 2. Inicio Rápido con Configuración Básica
```bash
make quick-start
```
**¿Qué hace este comando?**
- Inicia minikube con configuración optimizada
- Habilita addons comunes (dashboard, ingress, metrics)
- Configura el entorno para desarrollo

### 3. Verificar Estado
```bash
make status
```

---

## 🛠️ Comandos Principales

### Gestión del Cluster

| Comando | Descripción |
|---------|-------------|
| `make start` | Iniciar cluster minikube |
| `make stop` | Detener cluster minikube |
| `make restart` | Reiniciar cluster minikube |
| `make delete` | Eliminar cluster minikube |
| `make status` | Ver estado del cluster |
| `make info` | Información detallada del cluster |

### Recursos de Kubernetes

| Comando | Descripción |
|---------|-------------|
| `make pods` | Listar todos los pods |
| `make services` | Listar todos los servicios |
| `make deployments` | Listar todos los deployments |
| `make namespaces` | Listar todos los namespaces |
| `make all-resources` | Listar todos los recursos |

### Dashboard y UI

| Comando | Descripción |
|---------|-------------|
| `make dashboard` | Abrir dashboard de Kubernetes |
| `make dashboard-url` | Obtener URL del dashboard |

### Networking

| Comando | Descripción |
|---------|-------------|
| `make tunnel` | Iniciar túnel para LoadBalancer |
| `make service-list` | Listar URLs de servicios |
| `make ip` | Obtener IP de minikube |

---

## 🔧 Addons y Extensiones

### Habilitar Addons Comunes
```bash
make enable-common
```
**Incluye:**
- Dashboard de Kubernetes
- Ingress Controller
- Metrics Server

### Addons Individuales
```bash
make enable-ingress     # Controlador de ingress
make enable-dashboard   # Dashboard web
make enable-metrics     # Servidor de métricas
make enable-registry    # Registry local
```

### Ver Addons Disponibles
```bash
make addons
```

---

## 🐳 Integración con Podman

### Configurar Podman Environment
```bash
make podman-env
```
**Luego ejecutar:**
```bash
eval $(minikube podman-env)
```

### Ver Imágenes Podman en Minikube
```bash
make podman-images
```

---

## 📊 Monitoreo y Debugging

### Logs y Eventos
```bash
make logs           # Logs de minikube
make events         # Eventos del cluster
make top-nodes      # Uso de recursos de nodos
make top-pods       # Uso de recursos de pods
```

### Troubleshooting
```bash
make troubleshoot   # Diagnóstico automático
make describe-node  # Detalles del nodo
```

---

## 🎯 Configuración Personalizada

### Variables de Entorno
Puedes personalizar la configuración usando variables:

```bash
# Iniciar con más memoria y CPUs
make start MEMORY=8192 CPUS=4

# Usar un perfil específico
make start PROFILE=my-cluster

# Especificar versión de Kubernetes
make start KUBERNETES_VERSION=v1.29.0

# Cambiar driver
make start DRIVER=virtualbox
```

### Perfiles Múltiples
```bash
# Listar perfiles
make profile-list

# Cambiar perfil activo
make profile-set PROFILE=development

# Crear cluster con perfil específico
make start PROFILE=production MEMORY=8192 CPUS=4
```

---

## 🧪 Casos de Uso Comunes

### Desarrollo Local
```bash
# 1. Iniciar entorno de desarrollo
make demo-setup

# 2. Configurar Podman para usar minikube
eval $(minikube podman-env)

# 3. Construir y desplegar aplicación
podman build -t my-app:latest .
kubectl create deployment my-app --image=my-app:latest

# 4. Exponer servicio
kubectl expose deployment my-app --type=LoadBalancer --port=8080

# 5. Obtener URL del servicio
make service-url SERVICE=my-app
```

### Testing de Aplicaciones
```bash
# 1. Iniciar cluster limpio
make start

# 2. Desplegar aplicación de prueba
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=NodePort --port=80

# 3. Acceder a la aplicación
minikube service nginx --url

# 4. Ver logs y métricas
make logs
make top-pods
```

### Desarrollo con Ingress
```bash
# 1. Habilitar ingress
make enable-ingress

# 2. Crear ingress resource
kubectl apply -f my-ingress.yaml

# 3. Obtener IP de minikube
make ip

# 4. Configurar /etc/hosts si es necesario
echo "$(minikube ip) my-app.local" | sudo tee -a /etc/hosts
```

---

## 🔄 Workflows Típicos

### Workflow de Desarrollo Diario
```bash
# Mañana - Iniciar trabajo
make start
make dashboard &  # Abrir dashboard en background

# Durante el día - Monitorear
make pods
make services
make logs

# Noche - Pausar para ahorrar recursos
make pause

# Al día siguiente - Continuar
make unpause
```

### Workflow de Testing
```bash
# Preparar entorno limpio
make delete
make quick-start

# Desplegar y probar
kubectl apply -f manifests/
make troubleshoot

# Limpiar después de pruebas
make clean-all
```

### Workflow de Demo/Presentación
```bash
# Preparar demo
make demo-setup
make dashboard-url  # Anotar URL para la demo

# Durante la demo
make pods
make services
make tunnel  # Si necesitas LoadBalancer

# Después de la demo
make stop
```

---

## 🧹 Limpieza y Mantenimiento

### Limpieza Regular
```bash
make clean-images   # Limpiar imágenes no usadas
make clean-all      # Limpieza completa (cuidado!)
```

### Reset Completo
```bash
make reset          # Eliminar y recrear cluster
```

### Parar Temporalmente
```bash
make pause          # Pausar cluster (ahorra recursos)
make unpause        # Reanudar cluster
```

---

## ⚠️ Troubleshooting Común

### Problemas de Inicio
```bash
# Si minikube no inicia
make delete
make start DRIVER=docker

# Si hay problemas de red
make troubleshoot
```

### Problemas de Recursos
```bash
# Aumentar recursos
make delete
make start MEMORY=8192 CPUS=4

# Ver uso actual
make top-nodes
make top-pods
```

### Problemas de Podman
```bash
# Reconfigurar Podman environment
eval $(minikube podman-env)
make podman-images
```

---

## 📈 Configuraciones Recomendadas

### Para Desarrollo
```bash
make start MEMORY=4096 CPUS=2 PROFILE=dev
make enable-common
```

### Para Testing
```bash
make start MEMORY=6144 CPUS=3 PROFILE=test
make enable-common
make enable-registry
```

### Para Demos
```bash
make start MEMORY=8192 CPUS=4 PROFILE=demo
make enable-common
make dashboard &
```

---

## 🎓 Próximos Pasos

1. **Familiarízate con kubectl**
   ```bash
   kubectl get pods
   kubectl describe pod <pod-name>
   kubectl logs <pod-name>
   ```

2. **Experimenta con deployments**
   ```bash
   kubectl create deployment nginx --image=nginx
   kubectl scale deployment nginx --replicas=3
   ```

3. **Prueba servicios y networking**
   ```bash
   kubectl expose deployment nginx --type=LoadBalancer --port=80
   make tunnel
   ```

4. **Explora el dashboard**
   ```bash
   make dashboard
   ```

---

## 🆘 Ayuda y Recursos

### Comandos de Ayuda
```bash
make help           # Ver todos los comandos disponibles
minikube --help     # Ayuda de minikube
kubectl --help      # Ayuda de kubectl
```

### Recursos Útiles
- [Documentación oficial de Minikube](https://minikube.sigs.k8s.io/docs/)
- [Documentación de Kubernetes](https://kubernetes.io/docs/)
- [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

### Comandos de Emergencia
```bash
make troubleshoot   # Diagnóstico automático
make reset          # Reset completo del cluster
make delete         # Eliminar cluster completamente
```