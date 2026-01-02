# Implementación CQRS en Kubernetes - Guía Técnica

## Visión General del Sistema

Nuestro taller implementa un **sistema CQRS (Command Query Responsibility Segregation)** completo desplegado en Kubernetes, demostrando patrones modernos de arquitectura de microservicios.

### Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                    KUBERNETES CLUSTER                       │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   Write Service │    │   Read Service  │                │
│  │   (Port 30080)  │    │   (Port 30081)  │                │
│  │                 │    │                 │                │
│  │ • POST /orders  │    │ • GET /orders   │                │
│  │ • PUT /orders   │    │ • GET /health   │                │
│  │ • GET /health   │    │                 │                │
│  └─────────────────┘    └─────────────────┘                │
│           │                       │                        │
│           └───────┬───────────────┘                        │
│                   │                                        │
│           ┌─────────────────┐                              │
│           │    MongoDB      │                              │
│           │ Database: PRUEBA│                              │
│           │ Collection: ORDERS                             │
│           └─────────────────┘                              │
└─────────────────────────────────────────────────────────────┘
```

## Patrón CQRS Implementado

### Principios CQRS
- **Separación de Responsabilidades**: Comandos (escritura) y consultas (lectura) separados
- **Optimización Específica**: Cada servicio optimizado para su función
- **Escalabilidad Independiente**: Write y Read pueden escalar por separado
- **Modelo de Datos Flexible**: Diferentes vistas de los mismos datos

### Flujo de Datos
1. **Comando (Write)**: Cliente → Write Service → MongoDB
2. **Consulta (Read)**: Cliente → Read Service → MongoDB
3. **Consistencia**: Eventual consistency a través de la base de datos compartida

## Componentes del Sistema

### 1. Write Service (Servicio de Escritura)

**Responsabilidades:**
- Procesar comandos de creación y actualización de órdenes
- Validar datos de entrada
- Persistir cambios en MongoDB
- Generar IDs únicos para órdenes

**Endpoints:**
```http
POST /write/orders          # Crear nueva orden
PUT /write/orders/{id}      # Actualizar orden existente
GET /write/orders/recent    # Órdenes recientes (última hora)
GET /write/health          # Health check
```

**Modelo de Datos:**
```java
@Document(collection = "ORDERS")
public class Order {
    private String orderId;      // ID único de la orden
    private String customerId;   // ID del cliente
    private String productName;  // Nombre del producto
    private Integer quantity;    // Cantidad
    private BigDecimal price;    // Precio unitario
    private BigDecimal total;    // Total calculado
    private String status;       // Estado (PENDING, COMPLETED, etc.)
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
```

**Validaciones:**
- `@NotBlank` en campos requeridos
- `@Positive` para cantidad y precio
- Validación de IDs únicos
- Cálculo automático de totales

### 2. Read Service (Servicio de Lectura)

**Responsabilidades:**
- Procesar consultas de órdenes
- Optimizar queries para lectura
- Proporcionar vistas específicas de los datos
- Agregaciones y reportes

**Endpoints:**
```http
GET /read/customers/{customerId}/orders  # Órdenes por cliente
GET /read/orders/{orderId}              # Orden específica
GET /read/orders/status/{status}        # Órdenes por estado
GET /read/health                        # Health check
```

**Modelo de Vista:**
```java
@Document(collection = "ORDERS")
public class OrderView {
    // Misma estructura que Order pero optimizada para lectura
    // Puede incluir campos calculados o agregados
    // Índices específicos para consultas frecuentes
}
```

### 3. MongoDB Database

**Configuración:**
- **Base de datos**: `PRUEBA`
- **Colección**: `ORDERS`
- **Autenticación**: Usuario `admin` con permisos en `PRUEBA`
- **Índices optimizados** para rendimiento

**Índices Creados:**
```javascript
db.ORDERS.createIndex({ "customer_id": 1 });        // Búsquedas por cliente
db.ORDERS.createIndex({ "order_id": 1 }, { unique: true }); // ID único
db.ORDERS.createIndex({ "created_at": 1 });         // Ordenamiento temporal
db.ORDERS.createIndex({ "status": 1 });             // Filtros por estado
```

## Estructura de Archivos Kubernetes

### Organización Modular
```
manifiestos/
├── secrets.yaml              # Credenciales y configuración
├── mongodb-config.yaml       # ConfigMap para inicialización
├── mongodb-deployment.yaml   # Deployment de MongoDB
├── mongodb-service.yaml      # Service de MongoDB (ClusterIP)
├── write-deployment.yaml     # Deployment del Write Service
├── write-service.yaml        # Service del Write Service (NodePort)
├── read-deployment.yaml      # Deployment del Read Service
└── read-service.yaml         # Service del Read Service (NodePort)
```

### Configuración de Secrets

**Credenciales MongoDB:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-secret
data:
  MONGO_INITDB_ROOT_USERNAME: YWRtaW4=     # admin
  MONGO_INITDB_ROOT_PASSWORD: cGFzc3dvcmQxMjM= # password123
  MONGO_INITDB_DATABASE: YWRtaW4=          # admin
```

**URL de Conexión:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-config-secret
data:
  # mongodb://admin:password123@mongodb-service:27017/PRUEBA?authSource=admin
  MONGODB_URL: bW9uZ29kYjovL2FkbWluOnBhc3N3b3JkMTIzQG1vbmdvZGItc2VydmljZToyNzAxNy9QUlVFQkE/YXV0aFNvdXJjZT1hZG1pbg==
```

### Deployments Configuration

**Write Service Deployment:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: write-service-deployment
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: write-service
        image: localhost/cqrs-kube/write-service:latest
        ports:
        - containerPort: 8080
        env:
        - name: MONGODB_URL
          valueFrom:
            secretKeyRef:
              name: app-config-secret
              key: MONGODB_URL
        # Health checks configurados
        readinessProbe:
          httpGet:
            path: /write/health
            port: 8080
        livenessProbe:
          httpGet:
            path: /write/health
            port: 8080
```

### Services Configuration

**NodePort para Acceso Externo:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: write-service
spec:
  type: NodePort
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30080    # Acceso externo
  selector:
    app: write-service
```

## Tecnologías Utilizadas

### Backend Services
- **Java 17** con **Spring Boot 3.2.0**
- **Spring Data MongoDB** para persistencia
- **Jakarta Validation** para validaciones
- **Spring Web** para REST APIs
- **Spring Actuator** para health checks

### Containerización
- **Podman** como runtime de contenedores
- **Amazon Corretto 17 Alpine** como imagen base
- **Multi-stage builds** para optimización

### Orquestación
- **Kubernetes** para orquestación
- **Minikube** para desarrollo local
- **kubectl** para gestión del cluster

### Base de Datos
- **MongoDB 7.0** como base de datos principal
- **Índices optimizados** para rendimiento
- **Autenticación SCRAM-SHA-1**

## Flujo de Despliegue

### 1. Preparación del Entorno
```bash
make start    # Inicia Minikube con Podman
```

### 2. Construcción de Imágenes
```bash
make build    # Compila y construye imágenes Docker
```

### 3. Despliegue en Kubernetes
```bash
make deploy   # Despliega todos los manifiestos
```

### 4. Verificación del Sistema
```bash
make status   # Verifica estado de pods y servicios
make health   # Ejecuta health checks
```

### 5. Prueba del Sistema
```bash
make demo     # Ejecuta demo completo CQRS
```

## Patrones de Diseño Implementados

### 1. Command Query Responsibility Segregation (CQRS)
- **Separación clara** entre comandos y consultas
- **Servicios especializados** para cada responsabilidad
- **Optimización independiente** de lectura y escritura

### 2. Microservices Architecture
- **Servicios independientes** con responsabilidades específicas
- **Comunicación via APIs REST**
- **Despliegue independiente** de cada servicio

### 3. Database per Service (Variante)
- **Base de datos compartida** pero con **acceso segregado**
- **Write service** optimizado para transacciones
- **Read service** optimizado para consultas

### 4. Health Check Pattern
- **Endpoints de salud** en todos los servicios
- **Kubernetes probes** para auto-healing
- **Monitoreo proactivo** del sistema

### 5. Configuration Management
- **Secrets** para datos sensibles
- **ConfigMaps** para configuración
- **Environment variables** para inyección de dependencias

## Ventajas de la Implementación

### ✅ Escalabilidad
- **Write y Read services** pueden escalar independientemente
- **MongoDB** puede configurarse en replica set
- **Kubernetes HPA** para auto-scaling

### ✅ Mantenibilidad
- **Código separado** por responsabilidades
- **Despliegues independientes**
- **Testing aislado** de cada componente

### ✅ Rendimiento
- **Índices optimizados** para cada tipo de consulta
- **Servicios especializados** en su función
- **Caching** a nivel de aplicación posible

### ✅ Confiabilidad
- **Health checks** automáticos
- **Self-healing** via Kubernetes
- **Rolling updates** sin downtime

### ✅ Observabilidad
- **Logs estructurados** en cada servicio
- **Health endpoints** para monitoreo
- **Métricas** via Spring Actuator

## Casos de Uso Demostrados

### 1. Creación de Órdenes
```bash
curl -X POST http://localhost:8080/write/orders \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "ORD-001",
    "customerId": "CUST-001", 
    "productName": "Laptop",
    "quantity": 1,
    "price": 999.99
  }'
```

### 2. Consulta de Órdenes
```bash
curl -X GET http://localhost:8081/read/customers/CUST-001/orders
```

### 3. Health Monitoring
```bash
curl http://localhost:8080/write/health
curl http://localhost:8081/read/health
```

## Extensiones Posibles

### 🚀 Mejoras de Arquitectura
- **Event Sourcing** para historial completo
- **Message Queue** (RabbitMQ/Kafka) para desacoplamiento
- **Read replicas** para mejor rendimiento de lectura
- **API Gateway** para enrutamiento centralizado

### 🔒 Seguridad
- **JWT Authentication** para APIs
- **RBAC** en Kubernetes
- **Network Policies** para aislamiento
- **TLS** para comunicación segura

### 📊 Observabilidad
- **Prometheus** para métricas
- **Grafana** para dashboards
- **Jaeger** para distributed tracing
- **ELK Stack** para logs centralizados

### 🎯 DevOps
- **Helm Charts** para gestión de releases
- **CI/CD Pipeline** con GitOps
- **Automated testing** en pipeline
- **Blue-Green deployments**

## Conclusión

Esta implementación demuestra cómo construir un sistema CQRS moderno y escalable usando Kubernetes, combinando:

- **Patrones arquitectónicos** probados (CQRS, Microservices)
- **Tecnologías modernas** (Spring Boot, MongoDB, Kubernetes)
- **Mejores prácticas** de desarrollo y despliegue
- **Herramientas de producción** (Health checks, Monitoring)

El resultado es un sistema **robusto, escalable y mantenible** que sirve como base para aplicaciones empresariales reales.