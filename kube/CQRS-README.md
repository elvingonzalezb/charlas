# Sistema CQRS en Kubernetes - Guía Completa

## 📋 Descripción del Sistema

Este proyecto implementa un sistema **CQRS (Command Query Responsibility Segregation)** completo en Kubernetes local usando minikube, demostrando los principios de **eventual consistency** y separación de responsabilidades entre escritura y lectura.

### 🏗️ Arquitectura del Sistema

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Write Service │    │   Sync Service  │    │   Read Service  │
│   (Port 8080)   │    │   (Port 8082)   │    │   (Port 8081)   │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ Spring Boot │ │    │ │ Spring Boot │ │    │ │ Spring Boot │ │
│ │     +       │ │    │ │     +       │ │    │ │     +       │ │
│ │     JPA     │ │    │ │ JPA + Mongo │ │    │ │   MongoDB   │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          ▼                      │                      ▼
┌─────────────────┐              │            ┌─────────────────┐
│   PostgreSQL    │              │            │     MongoDB     │
│                 │              │            │                 │
│ ┌─────────────┐ │              │            │ ┌─────────────┐ │
│ │ WRITE_KUBE  │ │◄─────────────┘            │ │ READ_KUBE   │ │
│ │   (tabla)   │ │                           │ │ (colección) │ │
│ └─────────────┘ │                           │ └─────────────┘ │
└─────────────────┘                           └─────────────────┘
```

### 🔄 Flujo de Datos CQRS

1. **WRITE**: Cliente envía comando → Write Service → PostgreSQL (WRITE_KUBE)
2. **SYNC**: Sync Service lee cambios → Transforma datos → MongoDB (READ_KUBE)
3. **READ**: Cliente consulta → Read Service → MongoDB (READ_KUBE)

---

## 🚀 Inicio Rápido

### Prerequisitos
- Minikube instalado y configurado
- Podman como driver por defecto
- Maven para compilar servicios Java
- kubectl configurado

### Demo Completo en Un Comando
```bash
make full-demo
```

Este comando ejecuta:
1. Inicia minikube
2. Compila e construye todas las imágenes Docker
3. Despliega el sistema completo en Kubernetes
4. Ejecuta una demostración del flujo CQRS

---

## 🛠️ Comandos Disponibles

### Gestión de Minikube
```bash
make start          # Iniciar minikube
make status         # Ver estado del cluster
make stop           # Detener minikube
make dashboard      # Abrir dashboard de Kubernetes
```

### Sistema CQRS
```bash
make build-images   # Compilar y construir imágenes Docker
make deploy-cqrs    # Desplegar sistema CQRS completo
make cqrs-status    # Ver estado de todos los servicios
make cqrs-urls      # Mostrar URLs de los servicios
make destroy-cqrs   # Eliminar sistema CQRS
```

### Pruebas y Demo
```bash
make test-write     # Probar servicio de escritura
make test-read      # Probar servicio de lectura
make test-sync      # Ver estado de sincronización
make demo-cqrs      # Demo completo del flujo CQRS
```

### Logs y Monitoreo
```bash
make cqrs-logs      # Ver logs de todos los servicios
make logs-write     # Logs en tiempo real del write service
make logs-read      # Logs en tiempo real del read service
make logs-sync      # Logs en tiempo real del sync service
```

---

## 📊 Servicios del Sistema

### 1. Write Service (Puerto 8080)
**Responsabilidad**: Manejar comandos de escritura

**Endpoints**:
- `POST /write/orders` - Crear nueva orden
- `PUT /write/orders/{orderId}` - Actualizar orden
- `GET /write/orders/recent` - Órdenes recientes
- `GET /write/health` - Health check

**Base de Datos**: PostgreSQL (tabla WRITE_KUBE)

### 2. Read Service (Puerto 8081)
**Responsabilidad**: Manejar consultas de lectura

**Endpoints**:
- `GET /read/orders/{orderId}` - Obtener orden por ID
- `GET /read/customers/{customerId}/orders` - Órdenes por cliente
- `GET /read/customers/{customerId}/orders/status/{status}` - Órdenes por cliente y estado
- `GET /read/orders/status/{status}` - Órdenes por estado
- `GET /read/orders/recent?hours=1` - Órdenes recientes
- `GET /read/health` - Health check

**Base de Datos**: MongoDB (colección READ_KUBE)

### 3. Sync Service (Puerto 8082)
**Responsabilidad**: Sincronizar datos entre PostgreSQL y MongoDB

**Endpoints**:
- `GET /sync/status` - Estado de sincronización
- `POST /sync/trigger` - Disparar sincronización manual
- `GET /sync/health` - Health check

**Funcionamiento**: 
- Ejecuta cada 10 segundos automáticamente
- Lee cambios de PostgreSQL
- Actualiza MongoDB con datos enriquecidos

---

## 🗄️ Estructura de Datos

### PostgreSQL - Tabla WRITE_KUBE
```sql
CREATE TABLE WRITE_KUBE (
    id SERIAL PRIMARY KEY,
    order_id VARCHAR(255) UNIQUE NOT NULL,
    customer_id VARCHAR(255) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### MongoDB - Colección READ_KUBE
```javascript
{
  _id: ObjectId,
  order_id: "ORD-12345",
  customer_id: "CUST-001",
  customer_name: "Juan Pérez",  // Enriquecido por sync service
  product_name: "Laptop Dell",
  quantity: 1,
  price: 999.99,
  total: 999.99,
  status: "COMPLETED",
  created_at: ISODate,
  updated_at: ISODate,
  sync_timestamp: ISODate       // Timestamp de sincronización
}
```

---

## 🧪 Ejemplos de Uso

### Crear una Orden (Write)
```bash
MINIKUBE_IP=$(minikube ip)
curl -X POST http://$MINIKUBE_IP:30080/write/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "CUST-123",
    "productName": "MacBook Pro",
    "quantity": 1,
    "price": 2499.99
  }'
```

### Consultar Órdenes por Cliente (Read)
```bash
curl -X GET http://$MINIKUBE_IP:30081/read/customers/CUST-123/orders
```

### Ver Estado de Sincronización
```bash
curl -X GET http://$MINIKUBE_IP:30082/sync/status
```

---

## 🔍 Monitoreo y Debugging

### Ver Estado del Sistema
```bash
make cqrs-status
```

### Verificar Conectividad de Bases de Datos
```bash
# PostgreSQL
kubectl exec -it deployment/postgres-deployment -- psql -U postgres -d write_db -c "SELECT COUNT(*) FROM WRITE_KUBE;"

# MongoDB
kubectl exec -it deployment/mongodb-deployment -- mongo read_db --eval "db.READ_KUBE.count()"
```

### Logs Detallados
```bash
# Ver logs del sync service para monitorear sincronización
make logs-sync

# Ver logs de todos los servicios
make cqrs-logs
```

---

## 🎯 Conceptos CQRS Demostrados

### 1. Separación de Responsabilidades
- **Write Service**: Optimizado para escritura (PostgreSQL con ACID)
- **Read Service**: Optimizado para lectura (MongoDB con consultas flexibles)

### 2. Eventual Consistency
- Los datos no son inmediatamente consistentes
- La sincronización ocurre cada 10 segundos
- Demuestra el principio BASE (Basically Available, Soft state, Eventually consistent)

### 3. Escalabilidad Independiente
- Write Service: 2 réplicas para manejar comandos
- Read Service: 2 réplicas para consultas
- Sync Service: 1 réplica para evitar conflictos

### 4. Modelos de Datos Diferentes
- **Write Model**: Normalizado, enfocado en integridad
- **Read Model**: Desnormalizado, enriquecido con datos adicionales

---

## 🚨 Troubleshooting

### Servicios no Inician
```bash
# Verificar estado de pods
kubectl get pods

# Ver logs de inicialización
kubectl logs deployment/write-service-deployment
```

### Bases de Datos no Conectan
```bash
# Verificar servicios de BD
kubectl get services postgres-service mongodb-service

# Probar conectividad
kubectl exec -it deployment/write-service-deployment -- curl postgres-service:5432
```

### Sincronización no Funciona
```bash
# Ver logs del sync service
make logs-sync

# Disparar sincronización manual
curl -X POST http://$(minikube ip):30082/sync/trigger
```

---

## 🧹 Limpieza

### Eliminar Solo el Sistema CQRS
```bash
make destroy-cqrs
```

### Eliminar Todo (incluyendo minikube)
```bash
make destroy-cqrs
make delete
```

---

## 📚 Para el Taller

### Secuencia de Demostración Recomendada

1. **Explicar Arquitectura** (5 min)
   - Mostrar diagrama CQRS
   - Explicar separación write/read

2. **Desplegar Sistema** (10 min)
   ```bash
   make start
   make build-images
   make deploy-cqrs
   ```

3. **Demostrar Flujo CQRS** (10 min)
   ```bash
   make demo-cqrs
   make logs-sync  # Mostrar sincronización en tiempo real
   ```

4. **Explorar Datos** (5 min)
   - Mostrar PostgreSQL vs MongoDB
   - Explicar eventual consistency

5. **Escalabilidad** (5 min)
   ```bash
   kubectl scale deployment write-service-deployment --replicas=3
   kubectl scale deployment read-service-deployment --replicas=4
   ```

### Comandos Clave para Demo
```bash
make full-demo      # Demo completo automatizado
make cqrs-urls      # URLs para pruebas manuales
make cqrs-status    # Estado del sistema
make logs-sync      # Ver sincronización en vivo
```

---

## 🎓 Conceptos Aprendidos

Al completar este taller, los participantes habrán aprendido:

- ✅ Implementación práctica de CQRS
- ✅ Eventual consistency en sistemas distribuidos
- ✅ Despliegue de aplicaciones en Kubernetes
- ✅ Gestión de bases de datos en contenedores
- ✅ Monitoreo y debugging de microservicios
- ✅ Escalabilidad independiente de servicios
- ✅ Patrones de sincronización de datos