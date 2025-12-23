# Ejemplos para Enviar Mensajes desde AWS Console

## 1. Desde EventBridge Console

**Dónde:** AWS Console → EventBridge → Event buses → lambda-event-dev-bus → Send events

**Campos del formulario:**

**Event Bus:** `lambda-event-dev-bus`

**Origen del evento (Event Source):**
```
com.miapp.web
```

**Tipo de detalle (Detail Type):**
```
mensaje.recibido
```

**Detalle del evento (Event Detail):**
```json
{
  "usuario": "Elvin",
  "mensaje": "Mensaje desde EventBridge Console",
  "timestamp": "2024-12-07T15:30:00Z"
}
```

**Pasos:**
1. Ve a EventBridge Console
2. Click en "Event buses"
3. Selecciona "lambda-event-dev-bus"
4. Click "Send events"
5. Llena los campos:
   - **Event Source:** `com.miapp.web`
   - **Detail Type:** `mensaje.recibido`
   - **Event Detail:** Pega el JSON de arriba
6. Click "Send"

**Alternativa con JSON completo:**
```json
{
  "Source": "com.miapp.web",
  "DetailType": "mensaje.recibido",
  "Detail": "{\"usuario\": \"Elvin\", \"mensaje\": \"Mensaje desde EventBridge Console\", \"timestamp\": \"2024-12-07T15:30:00Z\"}"
}
```

---

## 2. Desde SNS Console

**Dónde:** AWS Console → SNS → Topics → lambda-event-dev-messages → Publish message

**Message body:**
```json
{
  "source": "web",
  "timestamp": "2024-12-07T15:30:00.000Z",
  "data": {
    "usuario": "Elvin",
    "mensaje": "Mensaje directo desde SNS Console",
    "timestamp": "2024-12-07T15:30:00Z"
  },
  "processed_by": "lambda-web-receptor"
}
```

**Message attributes (IMPORTANTE):**
- Type: `String`
- Key: `source`
- Value: `web`

**Pasos:**
1. Ve a SNS Console
2. Click en "Topics"
3. Selecciona "lambda-event-dev-messages"
4. Click "Publish message"
5. Pega el JSON en "Message body"
6. Agrega el Message attribute "source" = "web"
7. Click "Publish message"

---

## 3. Desde Lambda Console (Test Event)

**Dónde:** AWS Console → Lambda → lambda-event-web-receptor → Test

**Test event JSON:**
```json
{
  "version": "0",
  "id": "test-12345",
  "detail-type": "mensaje.recibido",
  "source": "com.miapp.web",
  "account": "123456789012",
  "time": "2024-12-07T15:30:00Z",
  "region": "us-east-1",
  "detail": {
    "usuario": "Elvin",
    "mensaje": "Test directo desde Lambda Console",
    "timestamp": "2024-12-07T15:30:00Z"
  }
}
```

**Pasos:**
1. Ve a Lambda Console
2. Busca "lambda-event-web-receptor"
3. Click en la función
4. Ve a la pestaña "Test"
5. Click "Create new test event"
6. Pega el JSON arriba
7. Nombra el test "EventBridgeTest"
8. Click "Test"

---

## 4. Desde Lambda Console (Test Lambda Procesadora)

**Dónde:** AWS Console → Lambda → lambda-event-web-procesador → Test

**Test event JSON (formato SQS Records):**
```json
{
  "Records": [
    {
      "messageId": "test-message-123",
      "receiptHandle": "test-receipt-handle",
      "body": "{\"Type\":\"Notification\",\"MessageId\":\"test-sns-123\",\"TopicArn\":\"arn:aws:sns:us-east-1:123456789012:lambda-event-dev-messages\",\"Message\":\"{\\\"source\\\":\\\"web\\\",\\\"timestamp\\\":\\\"2024-12-07T15:30:00.000Z\\\",\\\"data\\\":{\\\"usuario\\\":\\\"Elvin\\\",\\\"mensaje\\\":\\\"Test Lambda Procesadora\\\",\\\"timestamp\\\":\\\"2024-12-07T15:30:00Z\\\"},\\\"processed_by\\\":\\\"lambda-web-receptor\\\"}\",\"Timestamp\":\"2024-12-07T15:30:00.000Z\",\"SignatureVersion\":\"1\",\"Signature\":\"test-signature\",\"SigningCertURL\":\"test-cert-url\",\"UnsubscribeURL\":\"test-unsubscribe-url\",\"MessageAttributes\":{\"source\":{\"Type\":\"String\",\"Value\":\"web\"}}}",
      "attributes": {
        "ApproximateReceiveCount": "1",
        "SentTimestamp": "1701952200000",
        "SenderId": "AIDAIENQZJOLO23YVJ4VO",
        "ApproximateFirstReceiveTimestamp": "1701952200000"
      },
      "messageAttributes": {},
      "md5OfBody": "test-md5",
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:us-east-1:123456789012:lambda-event-web-queue",
      "awsRegion": "us-east-1"
    }
  ]
}
```

**Pasos:**
1. Ve a Lambda Console
2. Busca "lambda-event-web-procesador"
3. Click en la función
4. Ve a la pestaña "Test"
5. Click "Create new test event"
6. Pega el JSON arriba
7. Nombra el test "SQSTest"
8. Click "Test"

---

## 5. Desde SQS Console

**Dónde:** AWS Console → SQS → lambda-event-web-queue → Send and receive messages

**Message body:**
```json
{
  "Type": "Notification",
  "MessageId": "test-message-123",
  "TopicArn": "arn:aws:sns:us-east-1:ACCOUNT:lambda-event-dev-messages",
  "Message": "{\"source\":\"web\",\"timestamp\":\"2024-12-07T15:30:00Z\",\"data\":{\"usuario\":\"Elvin\",\"mensaje\":\"Mensaje directo desde SQS Console\"},\"processed_by\":\"manual-sqs-test\"}",
  "Timestamp": "2024-12-07T15:30:00.000Z",
  "SignatureVersion": "1",
  "Signature": "test-signature",
  "SigningCertURL": "test-cert-url",
  "UnsubscribeURL": "test-unsubscribe-url",
  "MessageAttributes": {
    "source": {
      "Type": "String",
      "Value": "web"
    }
  }
}
```

**Pasos:**
1. Ve a SQS Console
2. Click en "Queues"
3. Selecciona "lambda-event-web-queue"
4. Click "Send and receive messages"
5. Pega el JSON en "Message body"
6. Click "Send message"

---

## Flujo Completo de Pruebas

### Test 1: EventBridge (Flujo completo)
EventBridge → Lambda Receptor → SNS → SQS → Lambda Procesador

### Test 2: SNS (Desde el medio)
SNS → SQS → Lambda Procesador

### Test 3: Lambda Receptor (Función específica)
Solo ejecuta la Lambda Receptor

### Test 4: Lambda Procesador (Función específica)
Solo ejecuta la Lambda Procesador

### Test 5: SQS (Final del flujo)
Solo ejecuta la Lambda Procesador

## Verificar Resultados

**CloudWatch Logs:**
- `/aws/lambda/lambda-event-web-receptor`
- `/aws/lambda/lambda-event-web-procesador`

**Comando para ver logs:**
```bash
aws logs tail /aws/lambda/lambda-event-web-receptor --since 5m
aws logs tail /aws/lambda/lambda-event-web-procesador --since 5m
```