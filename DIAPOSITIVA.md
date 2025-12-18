AWS Event-Driven: EventBridge + Lambda

1. ¿Qué es la arquitectura basada en eventos (EDA)?

Titulo en diapositiva:
La arquitectura basada en eventos (EDA) es un patrón de arquitectura moderna diseñado a partir de servicios pequeños y desacoplados que publican, consumen o enrutan eventos.

Mi Guion:
Es una arquitectura donde la aplicacion se basa en eventos, pero no en la propia aplicacion, entre aplicaciones, se deteactan cambios en cualquier microsevicio.

Titulo en diapositiva:
Importancia: 
- Modernizar las aplicaciones y sus almacenes de datos, se vuelven más fáciles de escalar y más rápidos de desarrollar.

Mi Guion:
"La importancia de EDA radica en su capacidad transformadora. Cuando las empresas adoptan esta arquitectura, no solo modernizan sus aplicaciones, sino también sus sistemas de datos. El resultado es doble: escalabilidad más natural y desarrollo más ágil. Los equipos pueden responder más rápido a las demandas del negocio porque la arquitectura misma facilita el crecimiento."

Titulo en diapositiva:
Beneficios:
- Escalado y errores por separado (Ej: servicio de pagos escala independiente del catálogo)
- Desarrollar con agilidad (Ej: equipo de notificaciones despliega sin coordinar con inventario)
- Creación de sistemas extensibles (Ej: agregar analytics sin tocar el checkout)

Mi Guion:
"Los beneficios de EDA son tres pilares fundamentales. Primero, escalado y errores por separado: cada servicio escala según su demanda y los fallos se aíslan. Segundo, agilidad en desarrollo: los equipos trabajan en paralelo sin coordinación constante. Tercero, sistemas extensibles: agregar funcionalidades no requiere modificar servicios existentes, solo suscribirse a eventos relevantes."

Titulo en diapositiva:
Funcionamiento:
- Publicar (Ej: "pedido-creado" con ID y monto)
- Enrutar (Ej: EventBridge envía a inventario, facturación, y email)
- Consumir (Ej: cada servicio procesa según su lógica específica)

Mi Guion:
"EDA funciona en tres etapas simples pero poderosas. Publicar: los servicios emiten eventos cuando algo importante ocurre, sin conocer quién los escuchará. Enrutar: el sistema de eventos dirige inteligentemente cada evento hacia los consumidores correctos usando reglas predefinidas. Consumir: los servicios receptores procesan eventos asíncronamente, ejecutando su lógica específica sin impactar al publicador."

Titulo en diapositiva:
Desafios:
- Latencia Variable (Ej: email puede llegar antes que SMS)
- coherencia eventual (Ej: inventario se actualiza después del pedido)
- Orquestación (Ej: coordinar pago → envío → factura)
- Depuración (Ej: rastrear evento a través de 5 servicios)

Mi Guion:
"EDA no es perfecta y debemos ser honestos sobre sus desafíos. La latencia variable surge del procesamiento asíncrono. La coherencia eventual significa que los datos pueden estar temporalmente inconsistentes. La orquestación se complica sin un controlador central. Y la depuración requiere herramientas especializadas para rastrear eventos distribuidos. Conocer estos desafíos es el primer paso para mitigarlos."


2. El Problema: Sincronía vs. Asincronía

Titulo en diapositiva:
El problema no es técnico en sí mismo, sino arquitectónico: elegir mal el modelo impacta acoplamiento, latencia, resiliencia y escalabilidad

Mi Guion:
"La decisión entre sincronía y asincronía no es técnica, es arquitectónica y estratégica. Elegir mal impacta cuatro pilares críticos: el acoplamiento entre componentes, los patrones de latencia, la capacidad de recuperación ante fallos, y la escalabilidad del sistema. Estas decisiones son costosas de revertir y pueden determinar el éxito o fracaso de toda la arquitectura."

Titulo en diapositiva:
Sincronía:
Un productor espera una respuesta inmediata del consumidor para continuar el flujo.
Problemas
- Alto acoplamiento temporal (Ej: si pagos falla, todo el checkout se detiene)
- Latencia acumulada (Ej: validar usuario + stock + precio = 300ms total)
- Menor resiliencia (Ej: servicio de descuentos caído bloquea ventas)
- Difícil escalar bajo picos (Ej: Black Friday satura toda la cadena)
Cuándo usarla
- Consultas tipo request/response (Ej: "¿cuál es mi saldo?")
- Validaciones inmediatas (Ej: autorización de tarjeta)
- Casos donde el resultado es obligatorio para continuar (Ej: login exitoso)

Mi Guion:
"La sincronía es intuitiva pero limitante. Crea alto acoplamiento temporal donde si un servicio falla, toda la cadena se detiene. Cada llamada suma latencia al proceso total. Un punto de falla puede derribar múltiples servicios. Sin embargo, tiene casos válidos: consultas que necesitan respuesta inmediata, validaciones críticas como autorizaciones, y procesos donde el resultado es indispensable para continuar."

Titulo en diapositiva:
Asincronía:
El productor emite un evento y no espera respuesta. Los consumidores reaccionan de forma independiente.
Ventajas
- Desacoplamiento total (Ej: checkout funciona aunque email esté caído)
- Alta resiliencia (Ej: fallo en analytics no afecta el pedido)
- Escalabilidad natural (Ej: notificaciones escala 10x sin tocar pagos)
- Extensibilidad sin impacto (Ej: agregar auditoría sin modificar ventas)
Desafíos
- Consistencia eventual (Ej: dashboard muestra stock desactualizado)
- Observabilidad más compleja (Ej: correlacionar logs de 6 servicios)
- Manejo de idempotencia (Ej: evitar emails duplicados por reintentos)

Mi Guion:
"La asincronía libera el potencial arquitectónico. Ofrece desacoplamiento total en tiempo y lógica, alta resiliencia donde los fallos se aíslan, escalabilidad natural por servicio, y extensibilidad transparente. Pero tiene desafíos reales: consistencia eventual que requiere diseño cuidadoso, observabilidad compleja para rastrear flujos distribuidos, y manejo explícito de idempotencia para evitar efectos no deseados."

Titulo en diapositiva:
Tips:
El “problema” real:
- “Usar EDA pero seguir pensando en request/response”.

Buen enfoque (best practice AWS)
Regla base
- Comandos → síncronos - Cambiar de "pedir que se haga algo
- Eventos → asíncronos - Avisar que algo pasó

Patrón recomendado
- Síncrono solo para iniciar
- Asíncrono para propagar efectos

Mi Guion:
"El error más común es usar herramientas EDA con mentalidad request/response. La regla de oro de AWS es simple: comandos son síncronos para pedir que se haga algo, eventos son asíncronos para avisar que algo ya pasó. El patrón híbrido es perfecto: síncrono para iniciar y validar, asíncrono para propagar efectos. Combina respuesta inmediata donde es necesaria con escalabilidad donde es beneficiosa."


 3. El Cerebro: Amazon EventBridge

 EventBridge es la estrella de esta arquitectura. No es solo un "bus", es un enrutador inteligente.
 
 Es una plataforma de enrutamiento de eventos con tres piezas:
  - Bus → eventos de negocio (EDA real)
  - Pipes → integración técnica sin código
  - Scheduler → eventos basados en tiempo

Titulo en diapositiva:
EventBridge Bus

  - Es el núcleo de Event Bridge.:
  - Default Bus: Donde llegan eventos de AWS (Ej: S3 ObjectCreated, RDS failover)
  - Custom Bus: Para tus propias aplicaciones (Ej: ecommerce-events, user-events)
  - Valor arquitectónico (Ej: elimina RabbitMQ/Kafka personalizado)
  - Cuándo usarlo (Ej: microservicios, integraciones AWS, fan-out patterns)

Mi Guion:
"EventBridge Bus es el corazón del ecosistema de eventos. El Default Bus recibe automáticamente eventos de todos los servicios AWS, mientras que los Custom Bus aíslan eventos de tus aplicaciones de negocio. Su valor arquitectónico es eliminar infraestructura de mensajería personalizada y ofrecer enrutamiento inteligente con integración nativa a más de 100 servicios AWS. Úsalo para desacoplar servicios, integrar con AWS, o crear arquitecturas event-driven escalables."

Titulo en diapositiva:
EventBridge Pipes

  - Es una forma simplificada de integración punto a punto (Ej: DynamoDB → Lambda)
  - Conexion directa (Ej: SQS → Step Functions sin código pegamento)
  - Valor arquitectónico (Ej: elimina Lambdas de transformación simples)
  - Cuándo usarlo (Ej: ETL básico, sincronización de datos, stream processing)

Mi Guion:
"EventBridge Pipes es integración sin código. Conecta directamente fuentes como DynamoDB, Kinesis, SQS con destinos como Lambda, Step Functions, API Gateway, incluyendo transformaciones opcionales. Su valor es eliminar código repetitivo de integración, proporcionar transformaciones visuales, y manejar reintentos automáticamente. Perfecto para migraciones de datos, sincronización entre sistemas, y procesamiento de streams sin lógica compleja."

Titulo en diapositiva:
EventBridge Scheduler

  - Es el reemplazo moderno de CloudWatch Events cron (Ej: más flexible que 0 2 * * *)
  - Dispara eventos (Ej: cada lunes a las 9am, el 15 de cada mes)
  - Puede invocar (Ej: Lambda, SQS, SNS, Step Functions directamente)
  - Valor arquitectónico (Ej: maneja zonas horarias, reintentos, DLQ automático)
  - Cuándo usarlo (Ej: reportes mensuales, limpieza de datos, recordatorios)

Mi Guion:
"EventBridge Scheduler es la evolución de CloudWatch Events para programación temporal. Dispara eventos con cronogramas complejos, fechas específicas, o intervalos personalizados, invocando directamente más de 270 servicios AWS. Ofrece programación más flexible que cron, maneja zonas horarias automáticamente, y proporciona reintentos configurables. Ideal para mantenimiento programado, procesamiento batch, recordatorios de negocio, y cualquier proceso temporal en arquitecturas serverless."


4. El Músculo: AWS Lambda

Lambda: Es quien reacciona al evento. Aquí es donde ocurre la lógica de negocio.

Lambda se encarga de procesar, y ejecutar lógica, no orquesta. La arquitectura vive en los eventos, no en la función.

Titulo en diapositiva:
Modelo de invocación asíncrona:

  - Event Bridge: Invoca a Lambda asíncronamente (Ej: fire-and-forget)
  - El productor no espera respuesta (Ej: checkout continúa sin esperar email)
  - Reintentos automáticos ante fallos (Ej: 3 intentos con backoff exponencial)
  - Aislamiento entre servicios (Ej: Lambda de analytics caída no afecta pagos)

Mi Guion:
"El modelo asíncrono es donde EventBridge y Lambda brillan juntos. EventBridge invoca Lambda sin bloquear al productor, creando flujo completamente desacoplado. El productor continúa inmediatamente sin esperar confirmación, mejorando el rendimiento. AWS maneja reintentos automáticos con backoff exponencial configurable. Este aislamiento significa que problemas en un consumidor no afectan otros componentes, creando arquitecturas resilientes y tolerantes a fallos."

Titulo en diapositiva:
El objeto (event):

  - Evento en JSON estándar (Ej: source, detail-type, timestamp, detail)
  - El detail contiene los datos de dominio (Ej: {"orderId": "123", "amount": 99.99})
  - Contratos claros y versionables (Ej: OrderCreated v1.0, v1.1 con nuevos campos)

Mi Guion:
"El objeto evento que Lambda recibe sigue un formato JSON estándar con metadatos como source, detail-type, y timestamp. El campo 'detail' contiene los datos específicos del dominio de negocio. La clave es mantener contratos claros y versionables entre productores y consumidores, permitiendo evolución independiente. Esta estructura facilita debugging, monitoring, y herramientas de desarrollo. Recomiendo esquemas explícitos y versionado semántico para cambios evolutivos."

Titulo en diapositiva:
Qué debe hacer:

Buenas prácticas: 

 - Ejecutar una responsabilidad clara (Ej: solo procesar pago, no enviar email)
 - Ser idempotente (Ej: procesar mismo evento 3 veces = mismo resultado)
 - Emitir nuevos eventos, no llamar servicios directamente (Ej: publicar "payment-processed")
 - Manejar errores de forma explícita (Ej: logs detallados, DLQ para fallos)
 - Qué NO debe hacer
 - Orquestar flujos complejos (Ej: coordinar pago→envío→factura va a Step Functions)
 - Mantener estado (Ej: no guardar variables entre invocaciones)
 - Encadenar Lambdas vía código (Ej: no invocar directamente otra Lambda)

Mi Guion:
"Las reglas de oro para Lambda en EDA son claras. Debe ejecutar una responsabilidad única, ser idempotente para múltiples ejecuciones del mismo evento, emitir nuevos eventos en lugar de llamadas directas, y manejar errores explícitamente con logging detallado. Lo que NO debe hacer: orquestar flujos complejos que van a Step Functions, mantener estado violando el principio stateless, y encadenar Lambdas que crea acoplamiento y dificulta debugging."

5. Patrones de Arquitectura (EDA con AWS)

Titulo en diapositiva:
Publish / Subscribe:

 - Servicios publican eventos (Ej: checkout publica "order-created")
 - Múltiples consumidores reaccionan (Ej: inventory, billing, notifications)
 - EventBridge como núcleo (Ej: enrutamiento inteligente con reglas)
 - Desacoplamiento total (Ej: agregar analytics sin tocar checkout)
 - AWS Services: EventBridge + Lambda + SQS + SNS + DynamoDB

Mi Guion:
"Publish/Subscribe es el fundamento de EDA moderno. Los servicios publican eventos sin conocer quién los consumirá, mientras múltiples consumidores reaccionan independientemente al mismo evento. EventBridge facilita este patrón con enrutamiento inteligente y filtrado. Logra desacoplamiento total permitiendo evolución independiente. Un evento 'pedido creado' puede disparar inventario, facturación, y notificaciones simultáneamente, cada uno a su propio ritmo."

Titulo en diapositiva:
Event Notification:

  - Evento informa que algo ocurrió (Ej: "user-registered" con solo userId)
  - El consumidor decide si actúa (Ej: email service decide si enviar bienvenida)
  - Eventos livianos (Ej: solo IDs y timestamps, no objetos completos)
  - Bajo acoplamiento (Ej: productor no conoce qué harán los consumidores)
  - AWS Services: EventBridge + Lambda + API Gateway + CloudWatch

Mi Guion:
"Event Notification es el patrón más simple y efectivo. Estos eventos son informativos, comunicando que 'algo ocurrió' sin prescribir acciones. El consumidor mantiene autonomía total para decidir si actúa y cómo responder. Mantenemos eventos livianos con información mínima: identificadores y metadatos básicos. Minimiza acoplamiento porque el productor no necesita conocer requerimientos específicos de cada consumidor. Ejemplos: 'usuario registrado', 'producto actualizado'."

Titulo en diapositiva:
Event Carried State Transfer:

  - El evento transporta el estado necesario (Ej: "order-created" incluye productos, precios, cliente)
  - Evita llamadas síncronas (Ej: no necesita consultar API de productos)
  - Reduce dependencias en tiempo de ejecución (Ej: funciona aunque product-service esté caído)
  - AWS Services: EventBridge + Lambda + S3 + DynamoDB + Kinesis Data Streams

Mi Guion:
"Event Carried State Transfer es una optimización poderosa donde el evento incluye todos los datos necesarios para que los consumidores actúen. En lugar de solo notificaciones, transporta el estado completo o cambios relevantes, eliminando llamadas adicionales. Evita llamadas síncronas de vuelta al productor, mejorando rendimiento y resiliencia. Reduce dependencias en tiempo de ejecución porque los consumidores operan completamente con la información del evento. Balance clave: completitud vs tamaño del evento."

Titulo en diapositiva:
Fan-out:

  - Un evento → múltiples destinos (Ej: "payment-completed" va a 5 servicios)
  - EventBridge + reglas (Ej: filtros por región, tipo de cliente, monto)
  - Escalabilidad natural (Ej: agregar servicio de fraude sin modificar pagos)
  - AWS Services: EventBridge + SNS + SQS + Lambda + Step Functions + Kinesis

Mi Guion:
"Fan-out es la manifestación práctica del poder de EventBridge para distribuir un evento a múltiples destinos simultáneamente. EventBridge usa reglas configurables para determinar qué servicios reciben cada evento, creando distribución inteligente y eficiente. La escalabilidad es natural: agregar consumidores no requiere modificar el productor ni otros consumidores. Un evento 'venta completada' dispara inventario, facturas, notificaciones, y análisis simultáneamente, cada proceso independiente y a su velocidad. Fundamental para arquitecturas escalables."



Tu infraestructura combina:
Pub/Sub: EventBridge distribuye eventos a múltiples consumidores

Fan-out: SNS envía a 3 colas diferentes automáticamente

Event Notification: Eventos livianos con información básica

¿Por qué es poderoso?

Agregar un nuevo canal (ej: Telegram) no requiere tocar código existente

Si un canal falla, los otros siguen funcionando

Cada canal puede procesar a su propio ritmo


     monolitica
Microservicios- implica una comunicación directa en http, grpc servicio a - servico b
EDA - tecnicamente es una arq de microservicios (Micro a publica un evento al broker, luego tiene mmicro diferentes que los lee)

Request/Response
- Flujo simple de seguir
Respuesta rapida

Desventajas:
- Alto acoplamiento
- Latancia
- Orquestador punto de falla

Ventajas:
- Bajo acoplamiento
- Independencia entre productos y consumidor
- Consumidores trabajan de acuerdo a su capacidad
- Fallos en servicio no afectan otros

Desventajas:
- Flujo no claro
- Rollbacks mas complejos

Impacto
- Obliga Mayor infraestructrua
- Mayor control en la infra
- Monitoreo, mayos costo, mayor mantenimiento
- Transacciones, usar patron SAGA



Pub/Sub
EDAs (3 tipos)
Elementos fundamentales
- Escalabilidad - De manera independiente, sin una dependencia de un servico a otro
- Desacoplamiento - El publicador no tiene que conocer el receptor, hay un descoplamiento entre lo que hace uno del otro
Evento: No es un mensaje, es un cambio en el sistema que debe ser informado

3 Variantes:
- Event Notification
El emisor del evento avisa de un cambio, indicando pocos datos
- Event carreid state transfer
El emsior del evento envia toda la entidad
- Event sourcing
El emisor del evento envia solo el -los campos que cambiaran y el contexto del cambio