# LoadBalancer Setup Guide

## Cambios Realizados

### 1. Servicios cambiados a LoadBalancer
- `read-service.yaml`: Cambiado de NodePort a LoadBalancer
- `write-service.yaml`: Cambiado de NodePort a LoadBalancer

### 2. Autoescalado Horizontal (HPA)
- `read-hpa.yaml`: HPA para read-service (1-5 replicas)
- `write-hpa.yaml`: HPA para write-service (1-5 replicas)
- Escalado basado en CPU (70%) y memoria (80%)

### 3. Ingress Controller
- `ingress.yaml`: Ingress para enrutar tráfico
- Host: `cqrs.local`
- Rutas: `/read` y `/write`

## Comandos Nuevos

### Túnel LoadBalancer
```bash
# Ejecutar en terminal separado
make tunnel
```

### Monitoreo HPA
```bash
make hpa-status
```

### IPs LoadBalancer
```bash
make loadbalancer-ips
```

### Información Ingress
```bash
make ingress-info
```

## Flujo de Uso

### 1. Desplegar con LoadBalancer
```bash
make start
make build
make deploy
```

### 2. Iniciar túnel (terminal separado)
```bash
make tunnel
```

### 3. Verificar servicios
```bash
make loadbalancer-ips
make hpa-status
```

### 4. Configurar Ingress (opcional)
```bash
# Agregar a /etc/hosts
echo "$(minikube ip) cqrs.local" | sudo tee -a /etc/hosts

# Acceder via Ingress
curl http://cqrs.local/write/health
curl http://cqrs.local/read/health
```

### 5. Ejecutar demo
```bash
make demo
```

## URLs de Acceso

### Con LoadBalancer (después de `make tunnel`)
- Write Service: `http://<EXTERNAL-IP>:8080`
- Read Service: `http://<EXTERNAL-IP>:8081`

### Con Ingress
- Write Service: `http://cqrs.local/write`
- Read Service: `http://cqrs.local/read`

## Monitoreo

### Ver escalado automático
```bash
kubectl get hpa
kubectl top pods
```

### Generar carga para probar HPA
```bash
# Instalar hey para pruebas de carga
brew install hey

# Generar carga en write-service
hey -z 2m -c 10 http://<EXTERNAL-IP>:8080/write/health
```