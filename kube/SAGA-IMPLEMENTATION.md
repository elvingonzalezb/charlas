# Implementación del Patrón SAGA - Guía Práctica

## 🎯 Objetivo
Implementar el patrón SAGA sobre la infraestructura CQRS existente para manejar transacciones distribuidas en el procesamiento de pedidos.

---

## 🏗️ Arquitectura de Implementación

### Servicios Nuevos a Crear:
```
spring/
├── saga-orchestrator/     # 🎭 Coordinador central de SAGAs
├── payment-service/       # 💳 Procesamiento de pagos
├── inventory-service/     # 📦 Gestión de inventario
└── notification-service/  # 📧 Notificaciones a usuarios
```

### Integración con CQRS Existente:
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Write Service │    │  Saga Orchestr. │    │  Payment Service│
│   (Existente)   │───►│    (Nuevo)      │───►│    (Nuevo)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐              │
         │              │ Inventory Serv. │              │
         └──────────────►│    (Nuevo)      │◄─────────────┘
                        └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │ Notification S. │
                    │    (Nuevo)      │
                    └─────────────────┘
```

---

## 📋 Plan de Implementación Paso a Paso

### Fase 1: Preparación de Infraestructura

#### 1.1 Nuevas Tablas DynamoDB
```hcl
# iac/dynamodb.tf - Agregar estas tablas

resource "aws_dynamodb_table" "saga_state" {
  name           = "${var.project_name}-saga-state"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "saga_id"
  
  attribute {
    name = "saga_id"
    type = "S"
  }
  
  attribute {
    name = "order_id"
    type = "S"
  }
  
  global_secondary_index {
    name     = "order-index"
    hash_key = "order_id"
  }
  
  tags = {
    Name = "${var.project_name}-saga-state"
  }
}

resource "aws_dynamodb_table" "saga_events" {
  name           = "${var.project_name}-saga-events"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "saga_id"
  range_key      = "event_timestamp"
  
  attribute {
    name = "saga_id"
    type = "S"
  }
  
  attribute {
    name = "event_timestamp"
    type = "S"
  }
  
  tags = {
    Name = "${var.project_name}-saga-events"
  }
}
```

#### 1.2 Nuevos ECR Repositories
```hcl
# iac/ecr.tf - Agregar estos repositorios

resource "aws_ecr_repository" "saga_orchestrator" {
  name = "${var.project_name}/saga-orchestrator"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "payment_service" {
  name = "${var.project_name}/payment-service"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "inventory_service" {
  name = "${var.project_name}/inventory-service"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "notification_service" {
  name = "${var.project_name}/notification-service"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}
```

---

### Fase 2: Implementación de Servicios

#### 2.1 Saga Orchestrator Service

**Estructura del proyecto:**
```
spring/saga-orchestrator/
├── pom.xml
├── src/main/java/com/cqrs/saga/
│   ├── SagaOrchestratorApplication.java
│   ├── controller/
│   │   └── SagaController.java
│   ├── service/
│   │   ├── SagaOrchestrator.java
│   │   └── SagaStateManager.java
│   ├── model/
│   │   ├── SagaState.java
│   │   ├── SagaEvent.java
│   │   └── OrderSaga.java
│   └── config/
│       └── DynamoDBConfig.java
└── Dockerfile
```

**Dependencias principales (pom.xml):**
```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>software.amazon.awssdk</groupId>
        <artifactId>dynamodb-enhanced</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-webflux</artifactId>
    </dependency>
</dependencies>
```

#### 2.2 Payment Service

**Funcionalidades:**
- Procesar pagos con tarjeta
- Validar información de pago
- Ejecutar reembolsos (compensación)
- Simular fallos para testing

#### 2.3 Inventory Service

**Funcionalidades:**
- Verificar disponibilidad de productos
- Reservar productos temporalmente
- Confirmar reservas
- Liberar reservas (compensación)

#### 2.4 Notification Service

**Funcionalidades:**
- Enviar confirmaciones de pedido
- Notificar fallos y cancelaciones
- Enviar actualizaciones de estado
- Logs de auditoría

---

### Fase 3: Flujos de SAGA

#### 3.1 Flujo Principal (Happy Path)
```java
public class OrderSagaFlow {
    
    @SagaStep(order = 1)
    public void createOrder(OrderSagaContext context) {
        // Ya implementado en write-service
        context.setOrderCreated(true);
    }
    
    @SagaStep(order = 2)
    public void processPayment(OrderSagaContext context) {
        PaymentRequest request = buildPaymentRequest(context);
        PaymentResponse response = paymentService.processPayment(request);
        context.setPaymentId(response.getPaymentId());
    }
    
    @SagaStep(order = 3)
    public void reserveInventory(OrderSagaContext context) {
        InventoryRequest request = buildInventoryRequest(context);
        InventoryResponse response = inventoryService.reserve(request);
        context.setReservationId(response.getReservationId());
    }
    
    @SagaStep(order = 4)
    public void sendConfirmation(OrderSagaContext context) {
        NotificationRequest request = buildNotificationRequest(context);
        notificationService.sendOrderConfirmation(request);
    }
    
    @SagaStep(order = 5)
    public void completeOrder(OrderSagaContext context) {
        // Actualizar estado final en read-service
        context.setCompleted(true);
    }
}
```

#### 3.2 Flujo de Compensación
```java
public class OrderSagaCompensation {
    
    @CompensationStep(for = "processPayment")
    public void refundPayment(OrderSagaContext context) {
        if (context.getPaymentId() != null) {
            paymentService.refund(context.getPaymentId());
        }
    }
    
    @CompensationStep(for = "reserveInventory")
    public void releaseInventory(OrderSagaContext context) {
        if (context.getReservationId() != null) {
            inventoryService.release(context.getReservationId());
        }
    }
    
    @CompensationStep(for = "createOrder")
    public void cancelOrder(OrderSagaContext context) {
        orderService.cancel(context.getOrderId());
        notificationService.sendCancellationNotice(context);
    }
}
```

---

### Fase 4: Integración con CQRS Existente

#### 4.1 Modificar Write Service
```java
@RestController
@RequestMapping("/write")
public class WriteController {
    
    @Autowired
    private SagaOrchestrator sagaOrchestrator;
    
    @PostMapping("/orders")
    public ResponseEntity<OrderResponse> createOrder(@RequestBody OrderRequest request) {
        // Crear pedido simple (como antes)
        if (request.isSimpleOrder()) {
            return createSimpleOrder(request);
        }
        
        // Crear pedido complejo usando SAGA
        String sagaId = sagaOrchestrator.startOrderSaga(request);
        
        return ResponseEntity.accepted()
            .body(OrderResponse.builder()
                .sagaId(sagaId)
                .status("PROCESSING")
                .message("Order is being processed")
                .build());
    }
}
```

#### 4.2 Modificar Read Service
```java
@RestController
@RequestMapping("/read")
public class ReadController {
    
    @GetMapping("/sagas/{sagaId}")
    public ResponseEntity<SagaStatusResponse> getSagaStatus(@PathVariable String sagaId) {
        SagaState state = sagaStateManager.getState(sagaId);
        List<SagaEvent> events = sagaEventRepository.findBySagaId(sagaId);
        
        return ResponseEntity.ok(SagaStatusResponse.builder()
            .sagaId(sagaId)
            .currentState(state.getStatus())
            .progress(calculateProgress(events))
            .events(events)
            .build());
    }
    
    @GetMapping("/orders/{orderId}/saga")
    public ResponseEntity<SagaStatusResponse> getOrderSagaStatus(@PathVariable String orderId) {
        String sagaId = sagaStateManager.findSagaByOrderId(orderId);
        return getSagaStatus(sagaId);
    }
}
```

---

### Fase 5: Dockerfiles y Despliegue

#### 5.1 Dockerfile para Saga Orchestrator
```dockerfile
# dockerfiles/Dockerfile.saga-orchestrator
FROM openjdk:17-jdk-slim

WORKDIR /app

COPY spring/saga-orchestrator/target/saga-orchestrator-1.0.0.jar app.jar

EXPOSE 8083

ENTRYPOINT ["java", "-jar", "app.jar"]
```

#### 5.2 Nuevos Comandos en Makefile
```makefile
# Agregar al Makefile existente

build-saga: ## Build SAGA services
	@echo "Building SAGA services..."
	mvn -f spring/saga-orchestrator/pom.xml clean package -DskipTests
	mvn -f spring/payment-service/pom.xml clean package -DskipTests
	mvn -f spring/inventory-service/pom.xml clean package -DskipTests
	mvn -f spring/notification-service/pom.xml clean package -DskipTests

podman-build-saga: ## Build SAGA Podman images
	@echo "Building SAGA Podman images..."
	podman build --platform linux/amd64 -f dockerfiles/Dockerfile.saga-orchestrator -t $(PROJECT_NAME)/saga-orchestrator:latest .
	podman build --platform linux/amd64 -f dockerfiles/Dockerfile.payment -t $(PROJECT_NAME)/payment-service:latest .
	podman build --platform linux/amd64 -f dockerfiles/Dockerfile.inventory -t $(PROJECT_NAME)/inventory-service:latest .
	podman build --platform linux/amd64 -f dockerfiles/Dockerfile.notification -t $(PROJECT_NAME)/notification-service:latest .

deploy-with-saga: deploy-infra build build-saga podman-build podman-build-saga ecr-push-all-saga ## Full deployment with SAGA
	@echo "Waiting for all services including SAGA to start..."
	@sleep 60
	@echo "Verifying SAGA deployment..."
	@make verify-saga
	@echo ""
	@echo "✅ CQRS + SAGA system deployed successfully!"
	@echo "Write Service: $(cd iac && terraform output -raw write_service_url)"
	@echo "Read Service: $(cd iac && terraform output -raw read_service_url)"
	@echo "Saga Orchestrator: $(cd iac && terraform output -raw saga_orchestrator_url)"

test-saga-happy: ## Test SAGA happy path
	@echo "=== SAGA Happy Path Test ==="
	@WRITE_URL=$(cd iac && terraform output -raw write_service_url); \
	curl -X POST $WRITE_URL/orders \
		-H "Content-Type: application/json" \
		-d '{"customerId": "customer-saga-123", "total": 299.99, "paymentMethod": "credit_card", "items": [{"productId": "prod-complex", "quantity": 1, "price": 299.99}], "complex": true}'

test-saga-failure: ## Test SAGA with payment failure
	@echo "=== SAGA Payment Failure Test ==="
	@WRITE_URL=$(cd iac && terraform output -raw write_service_url); \
	curl -X POST $WRITE_URL/orders \
		-H "Content-Type: application/json" \
		-d '{"customerId": "customer-saga-456", "total": 999.99, "paymentMethod": "invalid_card", "items": [{"productId": "prod-expensive", "quantity": 1, "price": 999.99}], "complex": true}'

demo-saga: ## Run complete SAGA demonstration
	@echo "=== SAGA Pattern Demonstration ==="
	@echo ""
	@echo "🎭 STEP 1: Starting Complex Order SAGA..."
	@make test-saga-happy
	@echo ""
	@echo "⏱️ STEP 2: Waiting for SAGA completion..."
	@sleep 10
	@echo ""
	@echo "📊 STEP 3: Checking SAGA status..."
	@READ_URL=$(cd iac && terraform output -raw read_service_url); \
	curl -X GET $READ_URL/customers/customer-saga-123/orders
	@echo ""
	@echo "❌ STEP 4: Testing SAGA failure and compensation..."
	@make test-saga-failure
	@echo ""
	@echo "🎯 SAGA DEMO COMPLETED!"

logs-saga: ## View saga orchestrator logs
	aws logs tail /ecs/$(PROJECT_NAME)-saga-orchestrator --follow

verify-saga: ## Verify SAGA services
	@echo "=== SAGA Services Status ==="
	@aws ecs describe-services --cluster $(PROJECT_NAME)-cluster --services $(PROJECT_NAME)-saga-orchestrator $(PROJECT_NAME)-payment-service $(PROJECT_NAME)-inventory-service $(PROJECT_NAME)-notification-service --query 'services[*].{Name:serviceName,Status:status,Running:runningCount,Desired:desiredCount}' --output table
```

---

## 🧪 Plan de Testing

### Test Cases Principales:

#### 1. **Happy Path Complete**
```bash
make test-saga-happy
# Verificar: Order → Payment → Inventory → Notification → Complete
```

#### 2. **Payment Failure**
```bash
make test-saga-payment-failure
# Verificar: Order → Payment FAIL → Cancel Order
```

#### 3. **Inventory Failure**
```bash
make test-saga-inventory-failure
# Verificar: Order → Payment → Inventory FAIL → Refund → Cancel
```

#### 4. **Service Timeout**
```bash
make test-saga-timeout
# Verificar: Timeout handling y compensación automática
```

---

## 📊 Monitoreo y Observabilidad

### Métricas Clave:
- **SAGA Success Rate**: % de SAGAs completadas exitosamente
- **Compensation Rate**: % de SAGAs que requirieron rollback
- **Step Failure Distribution**: En qué paso fallan más las SAGAs
- **Average SAGA Duration**: Tiempo promedio de completar una SAGA
- **Service Availability**: Uptime de cada servicio participante

### Dashboards CloudWatch:
- Estado de SAGAs en tiempo real
- Distribución de fallos por servicio
- Tendencias de rendimiento
- Alertas proactivas

---

## 🎯 Próximos Pasos

### 1. **Implementación Incremental**
- Empezar con Saga Orchestrator básico
- Agregar Payment Service
- Integrar Inventory Service
- Finalizar con Notification Service

### 2. **Testing Exhaustivo**
- Implementar todos los casos de prueba
- Validar compensaciones
- Probar recuperación de fallos

### 3. **Optimización**
- Ajustar timeouts
- Optimizar performance
- Implementar circuit breakers

### 4. **Documentación**
- Actualizar INSTRUCCIONES.md
- Crear guías de troubleshooting
- Documentar APIs

¿Estás listo para comenzar con la implementación? Podemos empezar por cualquier fase que prefieras. 🚀