# NoSQL - Operaciones CRUD y los Principios de CAP y BASE

## Introducción a NoSQL

Las bases de datos NoSQL (Not Only SQL) son sistemas de gestión de bases de datos que no siguen el modelo relacional tradicional. Están diseñadas para manejar grandes volúmenes de datos no estructurados o semi-estructurados, ofreciendo escalabilidad horizontal y flexibilidad en el esquema.

### Tipos principales de bases de datos NoSQL:
- **Documentales**: MongoDB, CouchDB
- **Clave-Valor**: Redis, DynamoDB
- **Columnares**: Cassandra, HBase
- **Grafos**: Neo4j, Amazon Neptune

## Operaciones CRUD en Bases de Datos NoSQL

Las operaciones CRUD (Create, Read, Update, Delete) son fundamentales en cualquier sistema de base de datos:

### Create (Crear)
- Inserción de nuevos documentos/registros
- En NoSQL, los datos pueden tener estructuras flexibles
- No requiere esquema predefinido en muchos casos

### Read (Leer)
- Consulta y recuperación de datos
- Soporte para consultas complejas y filtros
- Indexación para optimizar el rendimiento

### Update (Actualizar)
- Modificación de documentos/registros existentes
- Actualizaciones parciales o completas
- Operaciones atómicas a nivel de documento

### Delete (Eliminar)
- Eliminación de documentos/registros
- Eliminación lógica vs física
- Gestión de referencias y consistencia

## Teorema CAP

El teorema de CAP establece que en un sistema distribuido es **imposible garantizar simultáneamente** las tres propiedades siguientes frente a particiones de red:

**C – Consistency | A – Availability | P – Partition Tolerance**

*Cuando ocurre una partición de red, el sistema debe sacrificar C o A.*

### C – Consistency (Consistencia)
- **Definición:** Todas las lecturas devuelven el dato más reciente. No existen lecturas obsoletas.
- **Ejemplo:** Un GET siempre devuelve el último PUT.

### A – Availability (Disponibilidad)
- **Definición:** Cada solicitud recibe una respuesta válida, aunque no sea la más reciente. No se permiten errores ni timeouts.
- **Ejemplo:** El sistema responde aunque devuelva datos antiguos.

### P – Partition Tolerance (Tolerancia al Particionado)
- **Definición:** El sistema sigue funcionando aunque haya fallos de red entre nodos.
- **Ejemplo:** Pérdida de comunicación entre dos AZ o regiones.

**En sistemas distribuidos reales, P no es opcional.**

### Combinaciones posibles

#### CA (Consistency + Availability)
- No tolera particiones
- Funciona bien en sistemas monolíticos o single-node
- **Ejemplos:** PostgreSQL sin replicación, base de datos relacional en un solo nodo
- **Uso:** Sistemas simples, entornos controlados, baja distribución

#### CP (Consistency + Partition Tolerance)
- Prioriza consistencia, sacrifica disponibilidad durante particiones
- **Ejemplos:** DynamoDB con lecturas strongly consistent, HBase, Zookeeper, Etcd
- **Comportamiento:** Si no puede garantizar consistencia, rechaza peticiones
- **Casos de uso:** Configuración distribuida, locks, metadatos críticos, control de líderes

#### AP (Availability + Partition Tolerance)
- Prioriza disponibilidad, acepta inconsistencias temporales
- **Ejemplos:** DynamoDB (por defecto), Cassandra, CouchDB, Riak
- **Comportamiento:** Siempre responde, los datos convergen luego
- **Casos de uso:** Catálogos, feeds, métricas, IoT, sistemas de alta escala

### CAP en AWS (ejemplos prácticos)

| Servicio | Tipo | Comportamiento |
|----------|------|----------------|
| **DynamoDB** | AP por defecto | Opción CP en lecturas (Strongly Consistent Reads) |
| **S3** | Históricamente AP | Hoy ofrece consistencia fuerte, pero sigue priorizando P |
| **RDS/Aurora** | CA dentro de una AZ | CP en setups multi-AZ (failover afecta disponibilidad) |

### Ejemplo real (EDA)
**Sistema de pedidos:**
1. Usuario crea pedido
2. Partición entre regiones
3. Sistema AP acepta pedidos
4. Estado se reconcilia luego (eventual consistency)

**Resultado:** Negocio sigue operando, inconsistencias temporales aceptables

### Regla práctica
- **En sistemas distribuidos reales:** P es obligatorio
- **La decisión real es:** C vs A

### Cuándo usar cada enfoque

| Necesidad | Enfoque |
|-----------|----------|
| No perder operaciones | AP |
| No aceptar datos incorrectos | CP |
| Simplicidad | CA |

## Modelo BASE

BASE es un enfoque de diseño para sistemas distribuidos, común en arquitecturas event-driven y bases de datos NoSQL. Prioriza disponibilidad y escalabilidad sobre consistencia inmediata, en contraste con ACID.

**BASE = Basically Available, Soft state, Eventual consistency**

### B – Basically Available (Básicamente Disponible)

**Definición:** El sistema garantiza que siempre responde, aunque sea con datos parciales, desactualizados o degradados.

**Ejemplo práctico:**
- Un e-commerce devuelve el catálogo de productos aunque el servicio de inventario esté caído
- Una API responde con cached data desde DynamoDB DAX o CloudFront

**En AWS:**
- DynamoDB con lecturas eventually consistent
- API Gateway + Lambda con fallback
- CloudFront sirviendo contenido cacheado si el backend falla

**Casos de uso:**
- Catálogos
- Feeds
- Dashboards
- Sistemas de lectura intensiva

### S – Soft State (Estado Suave)

**Definición:** El estado del sistema puede cambiar sin una transacción directa, debido a eventos asíncronos, replicación o expiración.

**Ejemplo práctico:**
- Un pedido aparece como "procesando" y cambia a "enviado" cuando llega un evento
- Una sesión de usuario expira sin acción explícita del cliente

**En AWS:**
- DynamoDB con TTL
- EventBridge propagando eventos
- SQS con consumidores asíncronos
- Lambda actualizando vistas materializadas

**Casos de uso:**
- Workflows asíncronos
- Estados temporales
- Sesiones
- Proyecciones CQRS

### E – Eventually Consistent (Eventualmente Consistente)

**Definición:** Los datos no son consistentes inmediatamente, pero convergen a un estado correcto con el tiempo.

**Ejemplo práctico:**
- El stock de un producto se actualiza segundos después de una compra
- Un perfil de usuario refleja cambios tras la propagación de eventos

**En AWS:**
- DynamoDB (eventual consistency por defecto)
- Replicación multi-región
- EventBridge + Lambda
- S3 (consistencia eventual histórica)

**Casos de uso:**
- Inventarios
- Métricas
- Notificaciones
- Sistemas distribuidos multi-región

### Ejemplo completo (EDA en AWS)
1. Usuario crea pedido → API Gateway
2. Lambda guarda pedido en DynamoDB (Basically Available)
3. EventBridge emite evento OrderCreated
4. Servicios de pagos, inventario y notificaciones reaccionan (Soft State)
5. El estado final se sincroniza en segundos (Eventually Consistent)

## ACID vs BASE: La Gran Comparación

| Aspecto | ACID | BASE |
|---------|------|------|
| **Filosofía** | Límite teórico | Estrategia práctica |
| **Enfoque** | Decisión en fallos | Comportamiento esperado |
| **Consistencia** | Fuerte e inmediata | Eventual |
| **Disponibilidad** | Puede verse comprometida | Priorizada |
| **Escalabilidad** | Limitada (vertical) | Alta (horizontal) |
| **Complejidad** | Menor | Mayor |
| **Casos de uso** | Transacciones críticas | Sistemas distribuidos |
| **Orientación** | Enfocado en transacciones | Enfocado en datos |

**BASE suele implementarse sobre sistemas AP del teorema CAP.**

## Patrón CQRS: Caso de Uso Común

### ¿Qué es CQRS?
**CQRS (Command Query Responsibility Segregation)** separa escrituras (commands) de lecturas (queries) porque tienen necesidades técnicas distintas.

**CQRS no define tecnologías, define roles:**
- **WRITE model** → protege invariantes de negocio
- **READ model** → optimiza consultas

### Caso de uso común: Gestión de pedidos

**Contexto:**
- Alto volumen de tráfico
- APIs públicas
- Microservicios
- Event-Driven Architecture
- No se requieren joins ni reportes complejos en tiempo real

### Arquitectura CQRS con DynamoDB (Write + Read)

#### WRITE MODEL (Command side)
**Tabla:** `OrdersCommand`

**Responsabilidad:**
- Validar reglas de negocio
- Garantizar idempotencia
- Mantener el estado canónico

**Ejemplo:**
```json
{
  "PK": "ORDER#123",
  "SK": "STATE",
  "status": "CREATED",
  "customerId": "456",
  "total": 100,
  "version": 1
}
```

#### EVENT (Propagación del cambio)
**DynamoDB Streams** → cada cambio emite un evento

#### READ MODEL (Query side)
**Tabla:** `OrdersQuery`

**Responsabilidad:**
- Optimizar lecturas
- Desnormalizar datos
- Cero lógica de negocio

**Ejemplo:**
```json
{
  "PK": "CUSTOMER#456",
  "SK": "ORDER#2025-12-24#123",
  "status": "CREATED",
  "total": 100,
  "createdAt": "2025-12-24T10:00:00Z"
}
```

### Flujo completo
```
WRITE: API → Lambda → OrdersCommand (DynamoDB)
EVENT: OrdersCommand → Stream → Lambda
READ:  OrdersQuery (DynamoDB)
```

### ¿Cuál es el beneficio?

**El beneficio no es "usar dos tablas". El beneficio es control, escalabilidad y evolución del sistema.**

#### Beneficios concretos:

1. **Proteges el modelo de negocio (WRITE)**
   - El WRITE solo se preocupa por validar reglas y mantener invariantes
   - No se contamina con queries "convenientes"
   - **Resultado:** Menos bugs, cambios de negocio más seguros

2. **Lecturas mucho más rápidas (READ)**
   - El READ está desnormalizado y optimizado por acceso
   - Sin joins ni filtros costosos
   - **Resultado:** Menor latencia, menor costo, mejor UX

3. **Escalas WRITE y READ de forma independiente**
   - Picos de lectura no afectan escrituras
   - **Resultado:** Sistema más estable, menos throttling

4. **Evolución segura**
   - Cambiar el READ no rompe el WRITE
   - Puedes agregar nuevas tablas de lectura y reprocesar eventos
   - **Resultado:** Evolución sin migraciones dolorosas

### Cuándo usar CQRS

**✅ Usar cuando:**
- Alto volumen de tráfico - ej: redes sociales tienes mas read que write
- Necesidades de lectura y escritura muy diferentes
- Sistemas event-driven
- Escalabilidad independiente requerida

**❌ NO usar cuando:**
- CRUD simple
- Bajo tráfico
- Equipo pequeño
- Dominio trivial

### Mensaje clave
**"CQRS no optimiza la base. Optimiza la arquitectura."**

**"Mismo motor, distintos modelos. DynamoDB escribe estados. DynamoDB lee vistas."**

## Implementación Práctica

### Estructura del Proyecto
```
no-sql/
├── iac/                    # Infraestructura como Código
│   ├── main.tf            # Recursos AWS (DynamoDB, ECS, ALB)
│   ├── variables.tf       # Variables de configuración
│   └── outputs.tf         # Outputs de la infraestructura
├── spring/                # Aplicaciones Spring Boot
│   ├── write-service/     # WRITE - Servicio de escritura
│   └── read-service/      # READ - Servicio de lectura
├── dockerfiles/           # Contenedores Docker
│   ├── Dockerfile.write   # Imagen para write service
│   └── Dockerfile.read    # Imagen para read service
├── Makefile              # Automatización de despliegue
├── SPEECH.md             # Contenido teórico para el taller
└── README.md             # Este archivo
```

### Despliegue Rápido

```bash
# 1. Desplegar infraestructura y aplicaciones
make deploy

# 2. Probar las APIs
make test-write
make test-read

# 3. Demo completo con eventual consistency
make demo
```

### Recursos Creados

**DynamoDB:**
- `cqrs-orders-orders-command` - Tabla de escritura (WRITE model)
- `cqrs-orders-orders-query` - Tabla de lectura (READ model)

**Spring Boot Services:**
- `write-service` - Puerto 8080 - Crear pedidos
- `read-service` - Puerto 8081 - Consultar pedidos

**Infraestructura:**
- ECS Cluster con Fargate
- Application Load Balancer
- ECR Repositories
- VPC con subnets públicas

### APIs Disponibles

**Write Service:**
- `POST /write/orders` - Crear pedido
- `GET /write/health` - Health check

**Read Service:**
- `GET /read/customers/{customerId}/orders` - Obtener pedidos
- `GET /read/orders/{orderId}` - Obtener pedido específico
- `GET /read/health` - Health check

### Ejemplo de Uso

```bash
# Crear pedido (WRITE)
curl -X POST http://load-balancer-url/write/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "customer-123",
    "total": 99.99,
    "items": [{
      "productId": "prod-1",
      "quantity": 2,
      "price": 49.99
    }]
  }'

# Consultar pedidos (READ)
curl http://load-balancer-url/read/customers/customer-123/orders
```

### Comandos Útiles

```bash
# Ver estado de la infraestructura
make status

# Ver logs en tiempo real
make logs-write
make logs-read

# Limpiar recursos
make destroy
```

## Casos de Uso Prácticos

### 🚀 Cuándo usar NoSQL con BASE:

**"Imaginen que están construyendo Netflix..."**
- **Caso**: Sistema de recomendaciones de películas
- **Motor recomendado**: MongoDB o DynamoDB
- **¿Por qué?**: Si el algoritmo se equivoca y te recomienda una comedia romántica en lugar de acción, el mundo no se acaba. Pero necesitas que el sistema esté disponible 24/7 para millones de usuarios.

**"Pensemos en Instagram..."**
- **Caso**: Feed de publicaciones y likes
- **Motor recomendado**: Cassandra o Redis
- **¿Por qué?**: Si tu like tarda 2 segundos en aparecer, está bien. Pero si Instagram se cae, pierdes millones de usuarios al instante.

**"Consideremos Amazon..."**
- **Caso**: Catálogo de productos y búsquedas
- **Motor recomendado**: Elasticsearch + DynamoDB
- **¿Por qué?**: Pueden mostrar "En stock: 5 unidades" cuando realmente quedan 3, pero el sistema debe estar siempre disponible para procesar compras.

**"Veamos Uber..."**
- **Caso**: Tracking de conductores en tiempo real
- **Motor recomendado**: Redis + MongoDB
- **¿Por qué?**: Si la ubicación del conductor se actualiza con 1-2 segundos de retraso, es aceptable. Pero el sistema no puede fallar durante las horas pico.

### 🏦 Cuándo mantener ACID:

**"Hablemos de tu banco..."**
- **Caso**: Transferencias bancarias
- **Motor recomendado**: PostgreSQL o Oracle
- **¿Por qué?**: Si transfieres $1000 y el sistema falla a medias, NO puedes tener $1000 debitados de tu cuenta y $0 acreditados en la otra. Prefieren que el sistema se caiga antes que perder dinero.

**"Pensemos en una farmacia..."**
- **Caso**: Control de inventario de medicamentos
- **Motor recomendado**: MySQL o SQL Server
- **¿Por qué?**: No puedes vender el último frasco de insulina a dos personas diferentes. La consistencia es literalmente vida o muerte.

**"Consideremos una aerolínea..."**
- **Caso**: Reserva de asientos
- **Motor recomendado**: PostgreSQL
- **¿Por qué?**: No puedes vender el asiento 12A a dos pasajeros. Mejor que el sistema esté temporalmente no disponible que tener conflictos en el avión.

**"Veamos un e-commerce crítico..."**
- **Caso**: Procesamiento de pagos
- **Motor recomendado**: PostgreSQL + Redis (cache)
- **¿Por qué?**: El pago debe ser exacto. Si cobras $100 pero el producto cuesta $200, o viceversa, tienes un problema legal y financiero.

### 🎯 La Regla de Oro para tu Charla:

**"Pregúntensen: ¿Qué es peor para mi negocio?"**
- **¿Que el sistema esté caído 5 minutos?** → Usa ACID
- **¿Que los datos estén inconsistentes 5 minutos?** → Usa BASE

**"En resumen:"**
- **BASE**: "Mejor aproximadamente correcto que perfectamente no disponible"
- **ACID**: "Mejor perfectamente correcto que aproximadamente disponible"