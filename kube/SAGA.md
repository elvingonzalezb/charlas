# Patrón SAGA - Transacciones Distribuidas

## 🎯 ¿Qué es el Patrón SAGA?

El patrón **SAGA** es una técnica para manejar **transacciones distribuidas** en arquitecturas de microservicios. En lugar de usar transacciones ACID tradicionales (que no funcionan bien entre servicios), SAGA divide una transacción larga en una secuencia de transacciones locales más pequeñas.

### 🔄 Principio Fundamental
- **Cada paso** de la transacción es una operación local en un servicio
- **Si un paso falla**, se ejecutan operaciones de **compensación** para deshacer los pasos anteriores
- **Eventual Consistency**: El sistema eventualmente llega a un estado consistente

---

## 🏗️ Tipos de SAGA

### 1. **Choreography SAGA** (Coreografía) - no esperas respuesta - 
- **Descentralizado**: Cada servicio sabe qué hacer después
- **Event-driven**: Los servicios publican eventos y reaccionan a eventos
- **Sin coordinador central**

### 2. **Orchestration SAGA** (Orquestación) - Esperas respuesta - para flujos mas complejos
- **Centralizado**: Un orquestador controla toda la transacción
- **Command-driven**: El orquestador envía comandos a los servicios
- **Coordinador central** (Saga Manager)

---

## 🎬 Ejemplo: Procesamiento de Pedido E-commerce

### Flujo Normal (Happy Path):
```
1. 📦 Order Service    → Crear pedido
2. 💳 Payment Service  → Procesar pago
3. 📋 Inventory Service → Reservar productos
4. 🚚 Shipping Service → Programar envío
5. ✅ Order Service    → Confirmar pedido
```

### Flujo de Compensación (Failure Path):
```
❌ Shipping Service falla → Ejecutar compensaciones:
4. 🚚 Shipping Service → [SKIP - falló]
3. 📋 Inventory Service → Liberar productos reservados
2. 💳 Payment Service → Reembolsar pago
1. 📦 Order Service → Cancelar pedido
```

---

## 🤔 ¿Cuándo Implementar SAGA?

### ✅ **Usar SAGA cuando:**
- Tienes **múltiples microservicios** que necesitan coordinación
- Las **transacciones ACID** no son posibles entre servicios
- Necesitas **alta disponibilidad** y tolerancia a fallos
- Los **rollbacks** son complejos pero manejables
- Puedes **definir operaciones de compensación** para cada paso

### ❌ **NO usar SAGA cuando:**
- Puedes usar **transacciones ACID locales** (un solo servicio/DB)
- Las **operaciones de compensación** son imposibles o muy complejas
- Necesitas **consistencia inmediata** (no eventual)
- El **flujo es muy simple** (2-3 pasos máximo)

---

## 🛠️ Implementación en Nuestro Proyecto CQRS

### Arquitectura Propuesta:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Order SAGA    │    │  Payment SAGA   │    │ Inventory SAGA  │
│   Orchestrator  │    │    Service      │    │    Service      │
│                 │    │                 │    │                 │
│ - Create Order  │◄──►│ - Process Pay   │◄──►│ - Reserve Items │
│ - Cancel Order  │    │ - Refund Pay    │    │ - Release Items │
│ - Confirm Order │    │ - Validate Pay  │    │ - Confirm Items │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   DynamoDB      │
                    │                 │
                    │ - saga_state    │
                    │ - saga_events   │
                    │ - saga_history  │
                    └─────────────────┘
```

---

## 📋 Plan de Implementación

### Fase 1: Estructura Base
```bash
spring/
├── saga-orchestrator/     # Coordinador central
├── payment-service/       # Servicio de pagos
├── inventory-service/     # Servicio de inventario
└── notification-service/  # Servicio de notificaciones
```

### Fase 2: Tablas DynamoDB
```
saga_state          # Estado actual de cada SAGA
saga_events         # Eventos de cada paso
saga_history        # Historial completo para auditoría
```

### Fase 3: Servicios Spring Boot
- **Saga Orchestrator**: Controla el flujo completo
- **Payment Service**: Procesa pagos y reembolsos
- **Inventory Service**: Reserva y libera productos
- **Notification Service**: Envía confirmaciones

### Fase 4: Integración con CQRS Existente
- **Write Service**: Inicia SAGAs para pedidos complejos
- **Read Service**: Consulta estado de SAGAs
- **Sync Service**: Procesa eventos de SAGA

---

## 🔄 Estados de SAGA

```java
public enum SagaState {
    STARTED,           // SAGA iniciada
    PAYMENT_PENDING,   // Esperando pago
    PAYMENT_COMPLETED, // Pago completado
    INVENTORY_PENDING, // Esperando reserva
    INVENTORY_RESERVED,// Inventario reservado
    SHIPPING_PENDING,  // Esperando envío
    COMPLETED,         // SAGA completada exitosamente
    COMPENSATING,      // Ejecutando compensaciones
    CANCELLED,         // SAGA cancelada
    FAILED            // SAGA falló definitivamente
}
```

---

## 📊 Eventos de SAGA

```java
// Eventos de Comando (hacia servicios)
- OrderCreateCommand
- PaymentProcessCommand
- InventoryReserveCommand
- ShippingScheduleCommand

// Eventos de Respuesta (desde servicios)
- OrderCreatedEvent
- PaymentProcessedEvent / PaymentFailedEvent
- InventoryReservedEvent / InventoryFailedEvent
- ShippingScheduledEvent / ShippingFailedEvent

// Eventos de Compensación
- OrderCancelCommand
- PaymentRefundCommand
- InventoryReleaseCommand
- ShippingCancelCommand
```

---

## 🎯 Ventajas del Patrón SAGA

### ✅ **Beneficios:**
- **Escalabilidad**: Cada servicio puede escalar independientemente
- **Disponibilidad**: Un servicio caído no bloquea todo el sistema
- **Flexibilidad**: Fácil agregar/quitar pasos en el flujo
- **Observabilidad**: Historial completo de cada transacción
- **Resilencia**: Manejo automático de fallos y recuperación

### ⚠️ **Desafíos:**
- **Complejidad**: Más código y lógica de coordinación
- **Debugging**: Más difícil rastrear problemas
- **Eventual Consistency**: No hay consistencia inmediata
- **Compensaciones**: Definir rollbacks puede ser complejo
- **Duplicación**: Posibles mensajes duplicados

---

## 🚀 Comandos Make Propuestos

```makefile
# Nuevos comandos para SAGA
deploy-saga         # Despliega servicios SAGA
test-saga-happy     # Prueba flujo exitoso
test-saga-failure   # Prueba flujo con fallos
demo-saga           # Demo completo SAGA
logs-saga           # Ver logs de orquestador
status-saga         # Estado de SAGAs activas
```

---

## 🧪 Casos de Prueba

### Test 1: Flujo Exitoso
```bash
make test-saga-happy
# 1. Crear pedido → ✅
# 2. Procesar pago → ✅
# 3. Reservar inventario → ✅
# 4. Programar envío → ✅
# 5. Confirmar pedido → ✅
```

### Test 2: Fallo en Pago
```bash
make test-saga-payment-failure
# 1. Crear pedido → ✅
# 2. Procesar pago → ❌ (tarjeta inválida)
# 3. Compensar: Cancelar pedido → ✅
```

### Test 3: Fallo en Inventario
```bash
make test-saga-inventory-failure
# 1. Crear pedido → ✅
# 2. Procesar pago → ✅
# 3. Reservar inventario → ❌ (sin stock)
# 4. Compensar: Reembolsar pago → ✅
# 5. Compensar: Cancelar pedido → ✅
```

---

## 📈 Métricas y Monitoreo

### KPIs Importantes:
- **Success Rate**: % de SAGAs completadas exitosamente
- **Compensation Rate**: % de SAGAs que requirieron rollback
- **Average Duration**: Tiempo promedio de completar SAGA
- **Failure Points**: Dónde fallan más las SAGAs
- **Recovery Time**: Tiempo de recuperación después de fallos

### Dashboards:
- **SAGA State Distribution**: Estados actuales de todas las SAGAs
- **Service Health**: Disponibilidad de cada servicio participante
- **Error Patterns**: Tipos de errores más comunes
- **Performance Trends**: Tendencias de rendimiento over time

---

## 🎓 Comparación: CQRS vs SAGA

| Aspecto | CQRS | SAGA |
|---------|------|------|
| **Propósito** | Separar lecturas/escrituras | Transacciones distribuidas |
| **Consistencia** | Eventual | Eventual |
| **Complejidad** | Media | Alta |
| **Casos de Uso** | Sistemas con muchas consultas | Workflows complejos |
| **Rollback** | No necesario | Compensaciones críticas |
| **Servicios** | 2-3 servicios | 3+ servicios |

---

## 🎯 Próximos Pasos

### 1. **Diseño Detallado**
- Definir flujos específicos para tu dominio
- Identificar operaciones de compensación
- Diseñar esquema de base de datos

### 2. **Implementación Incremental**
- Empezar con Saga Orchestrator básico
- Agregar un servicio a la vez
- Probar cada integración

### 3. **Testing Exhaustivo**
- Casos happy path
- Casos de fallo en cada paso
- Casos de recuperación

### 4. **Monitoreo y Observabilidad**
- Logs estructurados
- Métricas de negocio
- Alertas proactivas

---

## 💡 Recomendación

**Implementa SAGA después de dominar CQRS**. Los dos patrones se complementan perfectamente:

- **CQRS** maneja la separación de responsabilidades
- **SAGA** maneja la coordinación entre servicios
- **Juntos** crean una arquitectura robusta y escalable

¿Estás listo para implementar el patrón SAGA en tu proyecto? 🚀