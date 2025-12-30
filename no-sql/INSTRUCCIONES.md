# INSTRUCCIONES - Taller NoSQL CQRS

## 📋 Requisitos Previos

### Software Necesario
- **AWS CLI** configurado con credenciales
- **Terraform** >= 1.0
- **Podman** instalado y corriendo
- **Maven** >= 3.6
- **Java** 17 o superior
- **Make** (incluido en macOS/Linux)

### Verificar Instalación
```bash
aws --version
terraform --version
podman --version
mvn --version
java --version
make --version
```

### Configurar AWS
```bash
aws configure
# Ingresa: Access Key, Secret Key, Region (us-east-1), Output (json)
```

---

## 🏗️ Servicios que se Crearán

### AWS Resources
| Servicio | Nombre | Propósito |
|----------|--------|-----------|
| **DynamoDB** | `cqrs-orders-orders-command` | Tabla de escritura (WRITE model) |
| **DynamoDB** | `cqrs-orders-orders-query` | Tabla de lectura (READ model) |
| **ECS Cluster** | `cqrs-orders-cluster` | Contenedor para servicios |
| **ECR Repository** | `cqrs-orders/write-service` | Imágenes Docker write |
| **ECR Repository** | `cqrs-orders/read-service` | Imágenes Docker read |
| **ECR Repository** | `cqrs-orders/sync-service` | Imágenes Docker sync |
| **Application Load Balancer** | `cqrs-orders-alb` | Balanceador de carga |
| **VPC** | `cqrs-orders-vpc` | Red virtual privada |
| **Subnets** | `cqrs-orders-public-subnet-*` | Subredes públicas |

### Aplicaciones
| Servicio | Puerto | URL | Función |
|----------|--------|-----|---------|
| **Write Service** | 8080 | `/write/*` | Crear pedidos (WRITE) |
| **Read Service** | 8081 | `/read/*` | Consultar pedidos (READ) |
| **Sync Service** | 8082 | N/A | Sincronizar datos (DynamoDB Streams) |

---

## 🚀 Paso a Paso - Ejecución

### Paso 1: Clonar y Navegar
```bash
cd /ruta/a/tu/proyecto/no-sql
ls -la
# Deberías ver: iac/, spring/, dockerfiles/, Makefile, README.md, SPEECH.md
```

### Paso 2: Ver Comandos Disponibles
```bash
make help
```
**Salida esperada:**
```
Usage: make [target]

Targets:
  help            Show this help message
  init            Initialize Terraform
  deploy          Full deployment
  test-write      Test write service
  test-read       Test read service
  demo            Run demo sequence
  status          Show infrastructure status
  destroy         Destroy Terraform resources
```

### Paso 3: Despliegue Completo
```bash
make deploy-with-sync
```

**¿Qué hace este comando?**
1. **Inicializa Terraform** (`terraform init`)
2. **Crea infraestructura AWS** (DynamoDB, ECS, ALB, VPC)
3. **Compila aplicaciones Spring Boot** (`mvn package`)
4. **Construye imágenes Podman** (write, read, sync services)
5. **Sube imágenes a ECR**
6. **Despliega servicios en ECS** (incluyendo sync service)

**Tiempo estimado:** 10-15 minutos

**Salida esperada al final:**
```
✅ CQRS system with sync service deployed successfully!
Write Service: http://cqrs-orders-alb-1387261234.us-east-1.elb.amazonaws.com/write
Read Service: http://cqrs-orders-alb-1387261234.us-east-1.elb.amazonaws.com/read
Sync Service: Running in background processing DynamoDB streams
```

### Paso 4: Verificar Estado
```bash
make status
```

**Salida esperada:**
```
=== DynamoDB Tables ===
cqrs-orders-orders-command
cqrs-orders-orders-query

=== Load Balancer ===
http://cqrs-orders-alb-1387261234.us-east-1.elb.amazonaws.com

=== Services ===
http://cqrs-orders-alb-1387261234.us-east-1.elb.amazonaws.com/write
http://cqrs-orders-alb-1387261234.us-east-1.elb.amazonaws.com/read
```

---

## 🧪 Pruebas y Demostración

### Paso 5: Probar Write Service (Crear Pedido)
```bash
make test-write
```

**¿Qué hace?**
- Envía POST a `/write/orders`
- Crea un pedido en la tabla Command
- Activa DynamoDB Stream

**Salida esperada:**
```json
{
  "orderId": "uuid-generado",
  "status": "CREATED",
  "message": "Order created successfully"
}
```

### Paso 6: Probar Read Service (Consultar Pedidos)
```bash
make test-read
```

**¿Qué hace?**
- Envía GET a `/read/customers/customer-123/orders`
- Lee desde la tabla Query

**Salida esperada:**
```json
{
  "customerId": "customer-123",
  "orders": [
    {
      "orderId": "uuid-generado",
      "status": "CREATED",
      "total": 99.99,
      "createdAt": "2025-01-24T10:00:00.000Z"
    }
  ],
  "count": 1
}
```

### Paso 7: Demo Completo (Eventual Consistency)
```bash
make demo
```

**¿Qué hace?**
1. **Crea pedido** → Write Service
2. **Espera 5 segundos** → Eventual Consistency
3. **Lee pedidos** → Read Service

**Esto demuestra:**
- ✅ **Basically Available** - Servicios siempre responden
- ✅ **Soft State** - Estado evoluciona automáticamente
- ✅ **Eventually Consistent** - Datos se sincronizan con el tiempo

---

## 🔍 Monitoreo y Logs

### Ver Logs en Tiempo Real
```bash
# Logs del servicio de escritura
make logs-write

# Logs del servicio de lectura
make logs-read

# Logs del servicio de sincronización
make logs-sync
```

### Verificar en AWS Console

#### DynamoDB
1. Ir a **DynamoDB** → **Tables**
2. Ver tablas:
   - `cqrs-orders-orders-command` (datos de escritura)
   - `cqrs-orders-orders-query` (datos de lectura)

#### ECS
1. Ir a **ECS** → **Clusters**
2. Click en `cqrs-orders-cluster`
3. Ver servicios corriendo:
   - `cqrs-orders-write-service` (puerto 8080)
   - `cqrs-orders-read-service` (puerto 8081)
   - `cqrs-orders-sync-service` (background service)

#### Load Balancer
1. Ir a **EC2** → **Load Balancers**
2. Click en `cqrs-orders-alb`
3. Copiar DNS name para pruebas manuales

---

## 🧪 Pruebas Manuales

### Crear Pedido Manualmente
```bash
# Reemplaza URL_DEL_LOAD_BALANCER con la URL real
curl -X POST http://URL_DEL_LOAD_BALANCER/write/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "cliente-456",
    "total": 150.50,
    "items": [
      {
        "productId": "producto-A",
        "quantity": 3,
        "price": 50.17
      }
    ]
  }'
```

### Consultar Pedidos Manualmente
```bash
curl http://URL_DEL_LOAD_BALANCER/read/customers/cliente-456/orders
```

### Health Checks
```bash
# Write service health
curl http://URL_DEL_LOAD_BALANCER/write/health

# Read service health
curl http://URL_DEL_LOAD_BALANCER/read/health
```

---

## 🛠️ Solución de Problemas

### Error: "No credentials found"
```bash
aws configure
# Configura tus credenciales AWS
```

### Error: "Podman daemon not running"
```bash
# macOS
podman machine start

# Linux
sudo systemctl start podman

# Verificar estado
podman info
```

### Error: "Terraform not found"
```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
```

### Error: "Podman not found"
```bash
# macOS
brew install podman
podman machine init
podman machine start

# Linux (RHEL/CentOS/Fedora)
sudo dnf install podman

# Linux (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install podman
```

### Servicios no responden
```bash
# Verificar estado de ECS
aws ecs describe-services --cluster cqrs-orders-cluster --services cqrs-orders-write-service cqrs-orders-read-service

# Reiniciar servicios
aws ecs update-service --cluster cqrs-orders-cluster --service cqrs-orders-write-service --force-new-deployment
```

### Comandos Podman Adicionales
```bash
# Ver imágenes locales
podman images

# Limpiar imágenes no usadas
podman image prune

# Ver contenedores corriendo
podman ps

# Verificar conectividad con ECR
podman login $(aws ecr get-login-uri --region us-east-1)
```

---

## 🧹 Limpieza

### Destruir Todos los Recursos
```bash
make destroy
```

**¿Qué hace?**
- Elimina servicios ECS
- Borra imágenes ECR
- Destruye DynamoDB tables
- Elimina VPC y subnets
- Remueve Load Balancer

**Tiempo estimado:** 5-8 minutos

### Limpiar Archivos Locales
```bash
make clean
```

**¿Qué hace?**
- Limpia archivos Terraform
- Limpia builds Maven
- Remueve archivos temporales

### Limpiar Imágenes Podman Locales
```bash
podman image prune -a
podman system prune -a
```

---

## 📊 Costos Estimados

### Recursos AWS (por hora)
- **DynamoDB** (Pay per request): ~$0.01
- **ECS Fargate** (3 tasks): ~$0.12
- **Application Load Balancer**: ~$0.025
- **ECR Storage**: ~$0.001

**Total estimado:** ~$0.16/hora (~$4/día)

### Para el Taller
- **Duración:** 1 hora
- **Costo total:** ~$0.16

---

## ✅ Checklist Final

Antes de la presentación, verificar:

- [ ] `make deploy-with-sync` ejecuta sin errores
- [ ] `make status` muestra todos los recursos
- [ ] `make test-write` crea pedidos correctamente
- [ ] `make test-read` lee pedidos correctamente
- [ ] `make demo` demuestra eventual consistency
- [ ] AWS Console muestra tablas DynamoDB con datos
- [ ] Load Balancer responde en ambos endpoints
- [ ] `make logs-sync` muestra actividad del sync service
- [ ] `make destroy` limpia todos los recursos

---

## 🎯 Para la Demostración en Vivo

### Secuencia Recomendada
1. **Mostrar arquitectura** → Explicar CQRS
2. **Ejecutar `make deploy-with-sync`** → Mientras se despliega, explicar teoría
3. **Ejecutar `make demo`** → Mostrar eventual consistency
4. **Abrir AWS Console** → Mostrar tablas DynamoDB
5. **Mostrar logs sync service** → `make logs-sync`
6. **Ejecutar pruebas manuales** → Interactuar con audiencia
7. **Ejecutar `make destroy`** → Limpiar recursos

### Comandos Clave para Demo
```bash
make deploy-with-sync    # Al inicio
make demo               # Demostración principal
make logs-sync          # Mostrar sincronización
make status             # Mostrar recursos
make destroy            # Al final
```