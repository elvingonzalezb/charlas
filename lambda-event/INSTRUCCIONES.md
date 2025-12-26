# Taller: EventBridge con Terraform y SAM

## Arquitectura
```
EventBridge Bus → 3 Reglas → 3 Lambdas Receptoras → SNS Topic → 3 SQS → 3 Lambdas Procesadoras
```

## Pre-requisitos
- AWS CLI configurado con credenciales
- Terraform >= 1.0
- SAM CLI
- Python 3.11+
- Make

## Pasos de Despliegue

### 1. Desplegar Infraestructura (Terraform)
```bash
make t-init
make t-plan
make t-apply
```

Esto crea:
- EventBridge Bus
- 3 Reglas de EventBridge (web, app, whatsapp)
- SNS Topic
- 3 SQS Queues
- Roles IAM

### 2. Desplegar Lambdas (SAM)
```bash
make s-build
make s-deploy
```

Durante `s-deploy` Usa los outputs de Terraform:
```bash
cd iac && terraform output
```

### 3. Despliegue Completo (Un solo comando)
```bash
make deploy-all
```

## Probar la Arquitectura

### Opción 1: Enviar eventos de prueba (Terminal 2)
```bash
make test-web       # Probar canal Web
make test-app       # Probar canal App
make test-whatsapp  # Probar canal WhatsApp
make test-all       # Probar los 3 canales
```

### Opción 2: Ver logs en tiempo real (Terminal 1)
```bash
make logs-web
# o
make logs-app
# o
make logs-whatsapp
```

### Flujo completo de prueba:
1. Abre una terminal y ejecuta `make logs-web`
2. Abre otra terminal y ejecuta `make test-web`
3. Verás en la primera terminal:
   - Lambda receptora recibe el evento
   - Publica a SNS
   - Lambda procesadora consume de SQS

## Limpieza
```bash
make destroy-all
```

## Estructura del Proyecto
```
lambda-event/
├── Makefile              # Comandos automatizados
├── iac/                  # Terraform
│   ├── main.tf          # Recursos principales
│   ├── variables.tf     # Variables
│   └── outputs.tf       # Outputs
├── lambdas/
│   ├── receptoras/      # Reciben de EventBridge, publican a SNS
│   │   ├── web/
│   │   ├── app/
│   │   └── whatsapp/
│   └── procesadoras/    # Consumen de SQS
│       ├── web/
│       ├── app/
│       └── whatsapp/
└── sam/
    └── template.yaml    # Define las 6 lambdas
```

## Puntos Clave del Taller

1. **EventBridge Rules**: La lógica de enrutamiento está en configuración, no en código
2. **SNS Fan-Out**: Un mensaje se distribuye a múltiples consumidores
3. **SQS Buffer**: Protege las lambdas procesadoras de picos de tráfico
4. **IaC**: Toda la infraestructura es código versionable
5. **Separation of Concerns**: Lambdas receptoras validan, procesadoras ejecutan lógica de negocio

## Flujo de Datos Detallado

### 1. Lambda Receptora recibe evento de EventBridge
```python
event = {
  "version": "0",
  "id": "...",
  "detail-type": "mensaje.recibido",
  "source": "com.miapp.web",  # ← Estático (viene del evento)
  "detail": {                 # ← Dinámico (tu data)
    "usuario": "Elvin",
    "mensaje": "Hola..."
  }
}
```

### 2. Lambda Receptora publica a SNS
```python
sns.publish(
    TopicArn='arn:aws:sns:...',           # ← A dónde enviar
    Message=json.dumps(mensaje_limpio),    # ← El contenido (body)
    MessageAttributes={                    # ← Metadatos para filtrar
        'source': {
            'DataType': 'String',
            'StringValue': 'web'
        }
    }
)
```

### Componentes de SNS Publish

**TopicArn** (Obligatorio)
- El destino: a qué SNS Topic enviar

**Message** (Obligatorio)
- El **cuerpo** del mensaje
- Lo que realmente quieres transmitir
- Es lo que llega a SQS y luego a la Lambda Procesadora

**MessageAttributes** (Opcional pero CLAVE)
- **Metadatos** del mensaje
- **NO van en el body**, van aparte
- Se usan para **filtrar en las suscripciones SNS**

### 3. SNS filtra y distribuye

SNS tiene 3 suscripciones (3 SQS) con filtros:

```python
# Suscripción Web con filtro:
filter_policy = {
  "source": ["web"]  # ← Solo mensajes con MessageAttribute source=web
}

# Suscripción App con filtro:
filter_policy = {
  "source": ["app"]  # ← Solo mensajes con MessageAttribute source=app
}
```

**Sin MessageAttributes:** Todos los mensajes irían a todas las colas ❌

**Con MessageAttributes:** SNS filtra automáticamente y envía cada mensaje solo a su cola ✅

### Flujo completo:

```
EventBridge (source: com.miapp.web)
    ↓
Lambda Web Receptora
    ↓ publica a SNS con MessageAttribute: source=web
SNS Topic
    ↓ filtra por MessageAttribute
    ├─→ SQS Web (acepta source=web) ✅
    ├─→ SQS App (rechaza, espera source=app) ❌
    └─→ SQS WhatsApp (rechaza, espera source=whatsapp) ❌
    ↓
Lambda Web Procesadora consume de SQS Web
```

## Recursos a crear:
1 EventBridge Bus (lambda-event-dev-bus)

3 EventBridge Rules (web, app, whatsapp)

1 SNS Topic

3 SQS Queues

3 SNS Subscriptions (con filtros)

3 SQS Policies

2 IAM Roles (receptor y procesador)

2 IAM Role Policies

## Ejemplo Event Bridge Pipe
Flujo completo:
Usuario actualiza producto en DynamoDB

DynamoDB Streams captura el cambio

EventBridge Pipe filtra solo INSERT/MODIFY

Pipe transforma automáticamente el formato

OpenSearch recibe el documento indexado