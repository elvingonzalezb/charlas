# 🐳 Taller: Optimización de Imágenes Docker

## 🎯 DevOps y Containerización

### ¿Qué es DevOps?

DevOps es una metodología que combina desarrollo (Development) y operaciones (Operations) para acelerar la entrega de software mediante:

- **Automatización**: CI/CD pipelines, infraestructura como código
- **Colaboración**: Equipos multifuncionales trabajando juntos
- **Monitoreo continuo**: Observabilidad y feedback loops
- **Entrega rápida**: Despliegues frecuentes y confiables

### Docker vs Podman

| Aspecto | Docker | Podman |
|---------|--------|---------|
| **Arquitectura** | Cliente-servidor (daemon) | Sin daemon (fork/exec) |
| **Seguridad** | Requiere privilegios root | Rootless por defecto |
| **Compatibilidad** | API Docker | Compatible con Docker CLI |
| **Orquestación** | Docker Swarm | Kubernetes nativo |
| **Uso** | Desarrollo y producción | Enfoque en seguridad |

**¿Por qué Podman?**
- ✅ Mayor seguridad (sin daemon root)
- ✅ Compatible con systemd
- ✅ Soporte nativo para pods
- ✅ Transición fácil desde Docker

## 🏗️ Microservicios con Spring Boot

### Características de un Microservicio:

1. **Independiente**: Desplegable por separado
2. **Especializado**: Una responsabilidad específica
3. **Comunicación**: APIs REST/gRPC
4. **Datos**: Base de datos propia
5. **Resiliente**: Tolerante a fallos

### Spring Boot para Microservicios:

```java
@SpringBootApplication
@RestController
public class MicroserviceApplication {
    
    @GetMapping("/health")
    public String health() {
        return "OK";
    }
    
    @GetMapping("/info")
    public Map<String, String> info() {
        return Map.of(
            "service", "demo-microservice",
            "version", "1.0.0"
        );
    }
}
```

**Beneficios de Spring Boot:**
- ⚡ Configuración automática
- 📦 JAR ejecutable independiente
- 🔧 Actuator para monitoreo
- 🌐 Servidor embebido (Tomcat)

## 🚀 Estrategias de Optimización Docker

### 1. Multistage Builds

**Problema**: Imágenes pesadas con herramientas de build

```dockerfile
# ❌ Single stage - Imagen pesada
FROM openjdk:17-jdk
COPY . .
RUN mvn clean package
CMD ["java", "-jar", "app.jar"]
```

**Solución**: Separar build de runtime

```dockerfile
# ✅ Multistage - Imagen optimizada
# Stage 1: Build
FROM openjdk:17-jdk AS builder
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Runtime
FROM openjdk:17-jre-slim
COPY --from=builder /app/target/app.jar .
CMD ["java", "-jar", "app.jar"]
```

**Beneficios**:
- 🔽 Reduce tamaño 60-80%
- 🛡️ Menor superficie de ataque
- ⚡ Despliegues más rápidos

### 2. Optimización de Capas

```dockerfile
# ❌ Mal: Invalida cache frecuentemente
COPY . .
RUN mvn dependency:go-offline

# ✅ Bien: Aprovecha cache de Docker
COPY pom.xml .
RUN mvn dependency:go-offline  # Se cachea
COPY src ./src                 # Solo se ejecuta si src cambia
```

### 3. Imágenes Base Ligeras

| Imagen Base | Tamaño | Uso |
|-------------|--------|----- |
| `openjdk:17` | ~470MB | Desarrollo |
| `openjdk:17-jre` | ~285MB | Producción |
| `openjdk:17-jre-slim` | ~185MB | Optimizado |
| `openjdk:17-jre-alpine` | ~165MB | Mínimo |

## 🔒 Imágenes Distroless

### ¿Qué son las Imágenes Distroless?

Imágenes que contienen **solo** la aplicación y sus dependencias runtime, sin:
- ❌ Shell (bash, sh)
- ❌ Package managers (apt, yum)
- ❌ Utilidades del sistema
- ❌ Bibliotecas innecesarias

### Ejemplo con Distroless:

```dockerfile
# Build stage
FROM maven:3.8-openjdk-17 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

# Runtime stage con Distroless
FROM gcr.io/distroless/java17-debian11
COPY --from=builder /app/target/app.jar /app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app.jar"]
```

### Beneficios de Distroless:

1. **Seguridad**: 
   - Menor superficie de ataque
   - Sin vulnerabilidades de SO
   - Imposible ejecutar shell

2. **Tamaño**:
   - Imágenes ultra-ligeras
   - Menos transferencia de red
   - Arranque más rápido

3. **Compliance**:
   - Cumple estándares de seguridad
   - Auditorías más simples
   - Menos componentes que mantener

### Comparación de Tamaños:

```bash
# Imagen tradicional
openjdk:17-jre        285MB

# Imagen slim
openjdk:17-jre-slim   185MB

# Imagen distroless
gcr.io/distroless/java17  ~120MB
```

### Debugging en Distroless:

```dockerfile
# Para debugging, usar imagen con debug tools
FROM gcr.io/distroless/java17-debian11:debug
# Incluye busybox para troubleshooting
```

## 📋 Objetivos del Taller

1. **Crear imágenes mal optimizadas** y entender sus problemas
2. **Optimizar con multistage builds** y mejores prácticas
3. **Comparar tamaños** y rendimiento
4. **Usar herramientas como dive** para análisis
5. **Subir a Docker Hub** con tags apropiados

## 🏗️ Estructura del Proyecto

```
podman/
├── springboot-app/          # Aplicación Spring Boot de ejemplo
│   ├── src/main/java/...
│   └── pom.xml
├── dockerfiles/             # Dockerfiles para comparar
│   ├── Dockerfile.bad       # ❌ Mal optimizado
│   └── Dockerfile.optimized # ✅ Optimizado
├── scripts/                 # Scripts de automatización
│   ├── build-images.sh      # Construir imágenes
│   ├── push-images.sh       # Subir a Docker Hub
│   └── test-images.sh       # Probar imágenes
└── README.md               # Este archivo
```

## 🚀 Pasos del Taller

### 1. Preparación

```bash
# Instalar herramientas necesarias
brew install dive  # Para análisis de imágenes

# Verificar Podman
podman --version
podman machine start  # Si no está iniciado
```

### 2. Construir Imágenes

```bash
cd scripts
./build-images.sh
```

**Antes de ejecutar**, edita los scripts y cambia `tu-usuario-dockerhub` por tu usuario real.

### 3. Analizar con Dive

```bash
# Analizar imagen mal optimizada
dive tu-usuario/demo-springboot:bad

# Analizar imagen optimizada  
dive tu-usuario/demo-springboot:optimized
```

### 4. Comparar Tamaños

```bash
podman images | grep demo-springboot
```

### 5. Probar Imágenes

```bash
./test-images.sh
```

### 6. Subir a Docker Hub

```bash
# Login en Docker Hub
podman login docker.io

# Subir imágenes
./push-images.sh
```

## 📊 Comparación Esperada

| Aspecto | Imagen Mal Optimizada | Imagen Optimizada |
|---------|----------------------|-------------------|
| **Tamaño** | ~800MB+ | ~200-300MB |
| **Capas** | Muchas capas innecesarias | Capas optimizadas |
| **Seguridad** | Ejecuta como root | Usuario no-root |
| **Contenido** | Incluye Maven, código fuente | Solo JAR final |
| **Base** | OpenJDK completo | JRE slim |

## 🔍 Análisis con Dive

### Qué buscar en Dive:

1. **Número de capas**: Menos es mejor
2. **Tamaño por capa**: Identificar capas pesadas
3. **Eficiencia**: % de espacio desperdiciado
4. **Contenido**: Qué archivos están en cada capa

### Comandos útiles en Dive:

- `Tab`: Cambiar entre paneles
- `Ctrl+U`: Mostrar solo archivos modificados
- `Ctrl+A`: Mostrar todos los archivos
- `Space`: Colapsar/expandir directorios

## 🎯 Mejores Prácticas Demostradas

### ❌ Problemas en Dockerfile.bad:

1. **Imagen base pesada**: `openjdk:17` (JDK completo)
2. **Herramientas innecesarias**: Maven en imagen final
3. **Código fuente incluido**: Archivos .java en imagen final
4. **Sin multistage**: Todo en una sola etapa
5. **Usuario root**: Riesgo de seguridad
6. **Sin optimización de capas**: Comandos mal organizados

### ✅ Soluciones en Dockerfile.optimized:

1. **Multistage build**: Separar build de runtime
2. **Imagen base ligera**: `openjdk:17-jre-slim`
3. **Usuario no-root**: Crear y usar usuario específico
4. **Optimización de capas**: Copiar pom.xml primero
5. **Health check**: Monitoreo de salud
6. **Variables de entorno**: Configuración JVM para contenedores

## Subir a Docker Hub

### Configuración inicial:

```bash
# Editar scripts y cambiar usuario
sed -i 's/tu-usuario-dockerhub/TU_USUARIO_REAL/g' scripts/*.sh

# Login
podman login docker.io
```

### Tags recomendados:

- `bad`: Imagen mal optimizada (para comparación)
- `optimized`: Imagen optimizada
- `latest`: Apuntar a la optimizada
- `v1.0.0`: Tag de versión específica

## 🧪 Ejercicios Adicionales

1. **Crear Dockerfile con Alpine**: Usar `openjdk:17-jre-alpine`
2. **Implementar .dockerignore**: Excluir archivos innecesarios
3. **Usar distroless**: Probar imágenes distroless de Google
4. **Análisis de vulnerabilidades**: Usar `podman scan`
5. **Optimizar para CI/CD**: Usar cache de capas

## 📚 Recursos Adicionales

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Multistage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Dive Tool](https://github.com/wagoodman/dive)
- [Distroless Images](https://github.com/GoogleContainerTools/distroless)

## 🎉 Conclusiones

Al final del taller habrás aprendido:

- ✅ Identificar problemas en Dockerfiles
- ✅ Implementar multistage builds
- ✅ Optimizar tamaño de imágenes
- ✅ Usar herramientas de análisis
- ✅ Aplicar mejores prácticas de seguridad
- ✅ Gestionar imágenes en Docker Hub