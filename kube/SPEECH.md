Diferencia
ACID prioriza corrección inmediata.
BASE prioriza disponibilidad y escala.

Qué significa en la práctica
ACID - BASE
- Atomicity → todo o nada -- Basically Available → siempre responde
- Consistency → datos siempre correctos -- Soft State → el estado cambia con el tiempo
- Isolation → sin interferencias -- Eventual Consistency → consistencia después
- Durability → no se pierde nada

En la práctica
ACID - BASE
Transacciones - asincronia
Bloqueos - eventos
Esperas - reintentos
Menor escala - Escala masiva

## ¿Qué es NoSQL? (5 minutos)

Las bases de datos NoSQL (Not Only SQL) no siguen el modelo relacional tradicional. 
Están diseñadas para manejar grandes volúmenes de datos no estructurados, ofreciendo escalabilidad horizontal y flexibilidad.

### Tipos principales:
- **Documentales** (MongoDB, CouchDB): Buscas por contenido, modelo flexible
- **Clave-Valor** (Redis, DynamoDB): Buscas solo por clave, máxima velocidad
- **Columnares** (Cassandra, HBase): Enormes volúmenes de datos
- **Grafos** (Neo4j): Lo importante son las conexiones entre datos

## Operaciones CRUD en Bases de Datos NoSQL

Las operaciones CRUD son fundamentales en cualquier sistema de base de datos:
Existen unas Diferencias entre SQL vs NoSQL
- Esquema fijo y felxible o no existe
- CREATE: inserciones en varias tablas - un solo documento
- READ: Join entre tablas - acceso por clave
- UPDATE: con locks, en cascada - parcial o total sin cascadas, no tiene restricciones
- DELETE: reglas de integrifad - directo con TTL
- CONSISTENCIA: fuerte (ACID) - eventual (BASE)
- ESCALABILIDAD: vertical - horizontal
- FLEXIBILIDAD: cambio de esquemas costosos - baratos
- USO TIPICO: negocio, reportes, transacciones - alta escala, microserviciso, EDA

## Teorema CAP (15 minutos)

El teorema CAP establece que es **imposible garantizar simultáneamente** las tres propiedades siguientes:

**"En sistemas distribuidos, solo puedes elegir 2 de 3."**
o *Cuando ocurre una partición de red, el sistema debe sacrificar C o A.*
basicamente en **En sistemas distribuidos reales, P no es opcional.**
- **La decisión real es:** C vs A

### Las 3 propiedades:

**C - Consistency (Consistencia)**
- Todas las lecturas devuelven el dato más reciente
- Ejemplo: Un GET siempre devuelve el último PUT

**A - Availability (Disponibilidad)**  
- El sistema siempre responde, aunque no sea la data más reciente
- Ejemplo: Responde aunque devuelva datos antiguos

**P - Partition Tolerance (Tolerancia al Particionado)**
- Funciona aunque se corte la red entre servidores
- Ejemplo: Pérdida de comunicación entre regiones AWS

**En sistemas distribuidos reales, P no es opcional.**

### CAP en AWS (ejemplos prácticos)

| Servicio | Tipo | Comportamiento |
|----------|------|----------------|
| **DynamoDB** | AP por defecto | Opción CP en lecturas (Strongly Consistent Reads) |
| **S3** | Históricamente AP | Hoy ofrece consistencia fuerte, pero sigue priorizando P |
| **RDS/Aurora** | CA dentro de una AZ | CP en setups multi-AZ (failover afecta disponibilidad) |

### Combinaciones Reales:

#### CP - Consistency + Partition Tolerance
**"Prefiero que el sistema se caiga antes que mostrar datos incorrectos"**

**Ejemplo: Tu banco**
- Si transfieres $1000 y hay problema de red
- El banco prefiere rechazar la operación
- Mejor eso que tener $1000 debitados y $0 acreditados

**Tecnologías:** PostgreSQL, Zookeeper, DynamoDB con Strong Consistency

#### AP - Availability + Partition Tolerance  
**"Prefiero mostrar datos un poco viejos que caerme"**

**Ejemplo: Instagram**
- Si hay problemas de red entre servidores
- Instagram sigue funcionando
- Tu like puede tardar 2 segundos en aparecer

**Tecnologías:** DynamoDB (por defecto), Cassandra, MongoDB

#### CA - Consistency + Availability
**"Solo funciona si no hay problemas de red"**

**Ejemplo:** Base de datos en un solo servidor
- Perfecta consistencia y disponibilidad
- Pero si se cae el servidor, se cae todo

### La Decisión Clave

**"Pregúntense: ¿Qué es peor para mi negocio?"**
- **¿Que el sistema esté caído 5 minutos?** → Usa CP (ACID)
- **¿Que los datos estén inconsistentes 5 minutos?** → Usa AP (BASE)

---

## Modelo BASE (15 minutos)

BASE es un enfoque de diseño para sistemas distribuidos, común en arquitecturas event-driven y bases de datos NoSQL. 
Prioriza disponibilidad y escalabilidad sobre consistencia inmediata, en contraste con ACID.

**BASE = Basically Available, Soft state, Eventually consistent**

**"Es la filosofía de Netflix, Amazon, Instagram"**

### B - Basically Available (Básicamente Disponible)

**"El sistema siempre responde, aunque no sea perfecto"**

**Ejemplo Netflix:**
- Si el servicio de recomendaciones falla
- Netflix te muestra películas populares
- No te dice "Error 500, vuelve en 10 minutos"

**Ejemplo Amazon:**
- Pueden mostrar "En stock: 5 unidades" cuando realmente quedan 3
- Pero el sitio sigue funcionando

### S - Soft State (Estado Suave)

**"El estado puede cambiar sin que hagas nada"**
Es decir, sin una transacción directa, debido a eventos asíncronos, replicación o expiración.

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

**Ejemplo Uber:**
- Tu pedido aparece como "Buscando conductor"
- Cambia a "Conductor asignado" automáticamente
- Sin que toques nada

**Ejemplo WhatsApp:**
- Tu mensaje aparece con un check ✓
- Luego cambia a dos checks ✓✓
- El estado evoluciona solo

### E - Eventually Consistent (Eventualmente Consistente)

**"Los datos se sincronizan, pero no inmediatamente"**
Los datos no son consistentes inmediatamente, pero convergen a un estado correcto con el tiempo.

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

**Ejemplo Instagram:**
- Publicas una foto
- Tus amigos la ven en diferentes momentos
- En 1-2 segundos todos la tienen

**Ejemplo Amazon:**
- Compras el último producto
- Por 30 segundos sigue apareciendo disponible
- Luego se actualiza a "Agotado"

### BASE vs ACID - Casos de Uso

| Situación | ACID (CP) | BASE (AP) |
|-----------|-----------|-----------|
| **Transferencias bancarias** | ✅ Perfecto | ❌ Inaceptable |
| **Netflix/Streaming** | ❌ Se caería | ✅ Perfecto |
| **E-commerce catálogo** | ❌ No escala | ✅ Millones de usuarios |
| **Inventario medicamentos** | ✅ Necesario | ❌ Peligroso |
| **Redes sociales** | ❌ Muy lento | ✅ Ideal |

---

## CQRS - Command Query Responsibility Segregation (15 minutos)
### ¿Qué es CQRS?
**CQRS (Command Query Responsibility Segregation)** separa escrituras (commands) de lecturas (queries) porque tienen necesidades técnicas distintas.

**CQRS no define tecnologías, define roles:**
- **WRITE model** → protege invariantes de negocio
- **READ model** → optimiza consultas

### El Problema

**"¿Por qué usar la misma base para escribir y leer?"**

Imaginen una tienda online:
- **Escribir**: Crear pedido (simple, rápido, validaciones)
- **Leer**: Dashboard con reportes (complejo, lento, joins)

**¿Por qué la misma tabla debe servir para ambos?**

### La Solución CQRS

**"Separar escritura y lectura"**

```
WRITE: API → Spring Boot → DynamoDB Command Table
EVENT: DynamoDB Stream → Sync Processor  
READ:  DynamoDB Query Table ← Spring Boot ← API
```

### Ejemplo Práctico: Sistema de Pedidos

#### WRITE MODEL (Command side)
**Tabla: OrdersCommand**
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

**Responsabilidad:**
- Validar reglas de negocio
- Garantizar idempotencia
- Mantener estado canónico

#### READ MODEL (Query side)  
**Tabla: OrdersQuery**
```json
{
  "PK": "CUSTOMER#456",
  "SK": "ORDER#2025-01-24#123",
  "status": "CREATED", 
  "total": 100,
  "createdAt": "2025-01-24T10:00:00Z"
}
```

**Responsabilidad:**
- Optimizar lecturas
- Desnormalizar datos
- Cero lógica de negocio

### Flujo Completo
```
1. POST /orders → Write Service → OrdersCommand (DynamoDB)
2. DynamoDB Stream → Sync Service
3. Sync Service → OrdersQuery (DynamoDB)
4. GET /orders → Read Service → OrdersQuery
```

### Beneficios Reales

1. **Proteges el modelo de negocio (WRITE)**
   - Las consultas no rompen las escrituras
   - Cambios de negocio más seguros

2. **Lecturas ultra rápidas (READ)**
   - Datos desnormalizados y optimizados
   - Sin joins costosos

3. **Escalabilidad independiente**
   - Picos de lectura no afectan escrituras
   - Escala cada lado según necesidad

4. **Evolución segura**
   - Puedes cambiar el READ sin tocar el WRITE
   - Agregar nuevas vistas sin migraciones

### Cuándo Usar CQRS

**✅ SÍ usar cuando:**
- Alto volumen de tráfico (más reads que writes)
- Necesidades muy diferentes entre lectura/escritura
- Sistemas event-driven
- Escalabilidad independiente requerida

**❌ NO usar cuando:**
- CRUD simple
- Equipo pequeño
- Bajo tráfico
- Dominio trivial

### Mensaje Clave
**"CQRS no optimiza la base de datos. Optimiza la arquitectura."**

---

## Implementación Práctica (10 minutos)

### Lo que vamos a construir

**Sistema de pedidos con CQRS + BASE + DynamoDB**

### Arquitectura Real

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Write Service │    │   Sync Service  │    │   Read Service  │
│   (Port 8080)   │    │  (Background)   │    │   (Port 8081)   │
│                 │    │                 │    │                 │
│ POST /orders    │───►│ DynamoDB Stream │───►│ GET /orders     │
│                 │    │   Processor     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ OrdersCommand   │    │   Event Flow    │    │  OrdersQuery    │
│   (DynamoDB)    │    │                 │    │   (DynamoDB)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Tecnologías Usadas

- **Spring Boot** - Microservicios
- **DynamoDB** - Base de datos NoSQL (AP del teorema CAP)
- **DynamoDB Streams** - Event sourcing
- **Docker** - Containerización
- **Terraform** - Infraestructura como código
- **AWS ECS** - Orquestación de contenedores
- **Application Load Balancer** - Distribución de tráfico

### Comandos de Despliegue

```bash
# Desplegar infraestructura completa
make deploy-with-sync

# Probar APIs individualmente
make test-write    # Crear pedido
make test-read     # Consultar pedidos

# Demo completo con eventual consistency
make demo

# Ver estado del sistema
make status

# Limpiar recursos
make destroy
```

---

## Demostración en Vivo (10 minutos)

### Flujo que vamos a ver:

1. **🔵 WRITE SERVICE - Crear pedido**
   - POST /orders → DynamoDB Command Table
   - Respuesta inmediata

2. **🟡 SYNC SERVICE - Procesamiento automático**
   - DynamoDB Stream detecta cambio
   - Sync service procesa evento
   - Actualiza Query Table

3. **🟢 READ SERVICE - Consultar pedidos**
   - GET /orders → DynamoDB Query Table
   - Datos ya sincronizados

### Puntos Clave a Mostrar

- **Basically Available**: APIs siempre responden
- **Soft State**: Estado evoluciona automáticamente via streams
- **Eventually Consistent**: Datos tardan segundos en aparecer
- **CQRS**: Separación clara entre write y read

### Comandos en Vivo

```bash
# 1. Crear pedido (WRITE)
make test-write
# Respuesta: {"orderId": "uuid", "status": "CREATED"}

# 2. Esperar eventual consistency (5 segundos)
sleep 5

# 3. Consultar pedidos (READ)  
make test-read
# Respuesta: Lista de pedidos incluyendo el nuevo
```

---

## Casos de Uso Prácticos (5 minutos)

### 🚀 Cuándo usar NoSQL con BASE:

**Netflix - Sistema de recomendaciones**
- Si el algoritmo se equivoca, no pasa nada grave
- Pero necesitas disponibilidad 24/7 para millones

**Instagram - Feed y likes**
- Si tu like tarda 2 segundos, está bien
- Pero si Instagram se cae, pierdes usuarios

**Amazon - Catálogo de productos**
- Pueden mostrar stock incorrecto por segundos
- Pero el sistema debe estar siempre disponible

### 🏦 Cuándo mantener ACID:

**Banco - Transferencias**
- NO puedes tener dinero debitado sin acreditar
- Mejor que el sistema se caiga que perder dinero

**Farmacia - Inventario de medicamentos**
- No puedes vender el último frasco a dos personas
- Consistencia es literalmente vida o muerte

**Aerolínea - Reserva de asientos**
- No puedes vender el asiento 12A a dos pasajeros
- Mejor sistema caído que conflictos en el avión

---

## Conclusiones (5 minutos)

### Mensajes Clave

1. **CAP es una decisión de negocio, no técnica**
   - ¿Qué es peor: caerse o ser inconsistente?

2. **BASE no es mejor que ACID, es diferente**
   - Cada uno para su caso de uso específico

3. **CQRS optimiza arquitectura, no base de datos**
   - Separar responsabilidades para escalar mejor

### Reglas de Oro

**"Netflix usa BASE porque prefiere que veas una película vieja a que no veas nada"**

**"Tu banco usa ACID porque prefiere caerse a perderte dinero"**

**"CQRS separa lo que escribes de lo que lees, como separar la cocina del comedor"**

### La Pregunta Clave

**"¿Qué es peor para MI negocio?"**
- **¿Sistema caído 5 minutos?** → Usa ACID (CP)
- **¿Datos inconsistentes 5 minutos?** → Usa BASE (AP)

### Próximos Pasos

- Implementen CQRS en sus proyectos actuales
- Evalúen si necesitan BASE o ACID según su dominio
- Experimenten con DynamoDB Streams
- Consideren el patrón SAGA para transacciones distribuidas

**¿Preguntas?**