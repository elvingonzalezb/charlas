Arquitectura: "EventBridge Direct Routing"

1. Ingesta y Enrutamiento (El cerebro)
EventBridge (Bus): Recibe todo el tráfico.

3 Reglas (Rules): Aquí está la magia. En lugar de código Python/NodeJS, usas configuración JSON.

Regla 1: Si source == "com.miapp.web" -> Enviar a Lambda Web

Regla 2: Si source == "com.miapp.app" -> Enviar a Lambda App

Regla 3: Si source == "com.miapp.whatsapp" -> Enviar a Lambda WA

2. Procesamiento Inicial (Validadores)
3 Lambdas Receptoras (Web, App, WA):

Ahora son invocadas directamente por EventBridge.

Función: Hacen la limpieza inicial (validar que el JSON es correcto, formatear fechas, etc.).

Salida: Publican el mensaje limpio al SNS Topic.

3. Distribución (Fan-Out)
SNS Topic: (Igual que antes). Recibe el mensaje limpio y grita "¡Nuevo mensaje!".

4. Consumo Resiliente (El Buffer de seguridad)
3 SQS Suscriptores: (Igual que antes). Cada una configurada con Subscription Filter Policy en el SNS para agarrar solo lo suyo (o todo, dependiendo de tu lógica).

3 Lambdas Finales: Procesan el mensaje asíncronamente sin prisa.

¿Cómo se ve esto en Terraform? (Conceptualmente)
Para que te vayas haciendo una idea de lo que escribiremos:

Resource aws_cloudwatch_event_rule (x3): Crearemos 3 recursos de estos. Cada uno tendrá un event_pattern.

Terraform

# Ejemplo conceptual del patrón para la regla de WhatsApp
event_pattern = jsonencode({
  "source": ["com.miapp.whatsapp"]
})
Resource aws_cloudwatch_event_target (x3): Estos conectan la Regla con la Lambda.

Terraform

arn = aws_lambda_function.lambda_whatsapp.arn
Resource aws_lambda_permission: Muy importante y a menudo se olvida: Necesitamos decirle a la Lambda "Oye, deja que EventBridge te invoque".

Resumen para el Taller
Esta arquitectura optimizada es mejor para enseñar:

Event Driven Architecture (EDA) real: Menos código "pegamento", más configuración de servicios.

Infraestructura como Código (IaC): La lógica de negocio (el enrutamiento) vive en Terraform, no en un archivo .js o .py.

Es una Best Practice (Buena Práctica), no una obligación de sintaxis.

Entendimiento.

1. ¿Por qué usamos com.miapp.whatsapp? (Reverse Domain Name Notation)
EventBridge no te obliga a usar puntos (.). Tú podrías poner en el campo source simplemente "whatsapp" o "mensaje_web" y funcionaría técnicamente.

Sin embargo, la convención de la industria (adoptada de Java y de los identificadores de aplicaciones de Apple/Android) es usar la Notación de Dominio Inverso.

La estructura es: dominio.organizacion.proyecto.servicio

Ventajas de hacerlo así:

Evita colisiones: Si tú pones solo "whatsapp" y mañana integras un servicio de terceros que también envía eventos con source "whatsapp", tus reglas se van a volver locas y se mezclarán los eventos. Al poner com.tuempresa.whatsapp, garantizas que ese evento es tuyo.

Filtrado Jerárquico: Te permite crear reglas que atrapen grupos de eventos.

Ejemplo: Si tienes com.miapp.ventas y com.miapp.marketing, podrías crear una regla que escuche todo lo que empiece por com.miapp. para guardar un log de auditoría general.

2. ¿Cómo lo ve EventBridge realmente?
Para EventBridge, un evento es solo un objeto JSON. Cuando tú envías un evento desde tu código (o desde el CLI), se ve así:

JSON

{
  "Source": "com.miapp.whatsapp",   <-- EL CAMPO CLAVE
  "DetailType": "MensajeRecibido",  <-- QUÉ PASÓ
  "Detail": "{\"mensaje\": \"Hola\", \"usuario\": \"Elvin\"}", <-- LA DATA REAL
  "Time": "2023-10-27T..."
}
3. En tu Terraform (Las Reglas)
Cuando configuremos las reglas en Terraform, le diremos a EventBridge: "Busca eventos que coincidan exactamente con este string".

Si no usas buenas prácticas, tu Terraform se verá así (funciona, pero es desordenado):

Terraform

# Mal ejemplo
event_pattern = jsonencode({
  "source": ["cosas_de_whatsapp"] 
})
Si usas buenas prácticas, se ve profesional y escalable:

Terraform

# Buen ejemplo
event_pattern = jsonencode({
  "source": ["com.miapp.whatsapp"]
})

"EventBridge es un sistema de mensajería ciego; solo compara textos. Usamos com.empresa.servicio para poner orden y etiqueta a nuestros paquetes, asegurándonos de que nadie más en la cuenta de AWS use la misma etiqueta por accidente."

## Idempotencia en la Arquitectura

Para garantizar que los mensajes se procesen una sola vez, cada servicio AWS proporciona identificadores únicos:

### EventBridge
**Atributo:** `id`
```json
{
  "version": "0",
  "id": "12345678-1234-1234-1234-123456789012",  // ← ID único del evento
  "detail-type": "mensaje.recibido",
  "source": "com.miapp.web",
  "detail": {...}
}
```
**Uso:** Almacenar `event['id']` en DynamoDB/Redis para detectar duplicados.

### SNS
**Atributo:** `MessageId`
```json
{
  "Type": "Notification",
  "MessageId": "12345678-1234-1234-1234-123456789012",  // ← ID único del mensaje SNS
  "TopicArn": "arn:aws:sns:...",
  "Message": "{...}"
}
```
**Uso:** Almacenar `body['MessageId']` para evitar procesar el mismo mensaje SNS dos veces.

### SQS
**Atributo:** `messageId`
```json
{
  "Records": [{
    "messageId": "12345678-1234-1234-1234-123456789012",  // ← ID único del mensaje SQS
    "receiptHandle": "...",
    "body": "{...}"
  }]
}
```
**Uso:** Almacenar `record['messageId']` para detectar reprocesamiento de mensajes SQS.

### Estrategia Recomendada

1. **EventBridge → Lambda Receptora:** Usar `event['id']`
2. **SNS → SQS → Lambda Procesadora:** Usar `record['messageId']` (SQS)
3. **Almacenamiento:** DynamoDB con TTL de 24 horas
4. **Patrón:** Verificar ID antes de procesar, guardar ID después de procesar exitosamente

```python
# Ejemplo en Lambda
def lambda_handler(event, context):
    event_id = event.get('id')  # EventBridge
    # o
    message_id = event['Records'][0]['messageId']  # SQS
    
    # Verificar si ya procesamos este ID
    if already_processed(event_id):
        return {'statusCode': 200, 'body': 'Already processed'}
    
    # Procesar mensaje
    process_message(event)
    
    # Marcar como procesado
    mark_as_processed(event_id)
```

https://aws.amazon.com/es/what-is/eda/

https://serverlessland.com/patterns

https://docs.aws.amazon.com/eventbridge/

https://repost.aws/es/knowledge-center/lambda-function-idempotent

https://swpatterns.com/

https://www.grahambrooks.com/architecture/

https://docs.aws.amazon.com/powertools/

https://github.com/elvingonzalezb/charlas/tree/lambda-event/lambda-event