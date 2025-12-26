# Taller: Principios ACID en Transacciones

## 📋 Índice
1. [Configuración del Entorno](#configuración-del-entorno)
2. [Teoría ACID](#teoría-acid)
3. [Casos de Uso Prácticos](#casos-de-uso-prácticos)
4. [Comandos del Taller](#comandos-del-taller)
5. [Guión para Presentación](#guión-para-presentación)

---

## 🚀 Configuración del Entorno

### Pre-requisitos

**macOS:**
```bash
brew install podman
podman machine init
podman machine start
```

**Linux:**
```bash
sudo apt-get update
sudo apt-get install podman
```

### Instalar pipx y podman-compose

```bash
brew install pipx
pipx ensurepath
pipx install podman-compose
```

**Nota:** Después de instalar, abre una nueva terminal o ejecuta:
```bash
source ~/.zshrc
```

### Verificar instalación

```bash
podman --version
podman-compose --version
```

### Levantar el entorno

```bash
make build 
make up 
```

---

## 📚 Teoría ACID

### ¿Qué es ACID?

ACID son las propiedades que garantizan que las transacciones en bases de datos sean **confiables y consistentes**:

### **A - Atomicity (Atomicidad)**
- **"Todo o Nada"** - Una transacción se ejecuta completamente o no se ejecuta
- No hay estados intermedios
- **Analogía:** Como un interruptor de luz - está encendido o apagado, nunca a medias
- **Ejemplo:** Transferir dinero - se debita Y se acredita, o no pasa nada

### **C - Consistency (Consistencia)**
- **"Reglas Siempre Válidas"** - La base de datos mantiene todas las reglas de negocio
- Pasa de un estado válido a otro estado válido
- **Analogía:** Como las leyes de física - nunca se rompen
- **Ejemplo:** Saldos nunca negativos, stock nunca menor a cero

### **I - Isolation (Aislamiento)**
- **"Carriles Separados"** - Las transacciones no se interfieren entre sí
- Cada transacción ve un estado consistente
- **Analogía:** Como carriles de autopista - cada auto en su carril
- **Ejemplo:** Dos compras simultáneas del mismo producto no causan sobreventa

### **D - Durability (Durabilidad)**
- **"Para Siempre"** - Una vez confirmada, la transacción persiste permanentemente
- Sobrevive a fallos del sistema (cortes de luz, crashes)
- **Analogía:** Como escribir con tinta permanente
- **Ejemplo:** Transferencia confirmada permanece aunque se caiga el servidor

### ¿Por qué son importantes los principios ACID?

Los principios ACID son la base de la **confiabilidad** en sistemas de bases de datos. Sin ellos:
- 💸 **Dinero podría desaparecer** en transferencias bancarias
- 📦 **Inventarios inconsistentes** en e-commerce
- 🎫 **Doble reserva** de asientos en aerolíneas
- 🏥 **Historiales médicos corruptos**

### Analogía del Mundo Real: Transferencia Bancaria

Imagina que transfieres $500 de tu cuenta a la de tu amigo:

```
Estado Inicial:
Tu cuenta:     $1,000
Cuenta amigo:    $200
Total sistema: $1,200
```

**Sin ACID (❌ Problemático):**
```
Paso 1: Debitar $500 de tu cuenta → $500
Paso 2: [FALLA EL SISTEMA] 💥
Resultado: Tu cuenta: $500, Cuenta amigo: $200
Total sistema: $700 (¡$500 desaparecieron!)
```

**Con ACID (✅ Correcto):**
```
Transacción:
  BEGIN
  Paso 1: Debitar $500 de tu cuenta → $500
  Paso 2: Acreditar $500 a cuenta amigo → $700
  COMMIT
Resultado: Tu cuenta: $500, Cuenta amigo: $700
Total sistema: $1,200 (✅ Conservado)
```

---

## 🏦 Casos de Uso Prácticos

### Caso 1: Sistema Bancario

**Problema sin ACID:**
- Usuario A transfiere $500 a Usuario B
- Sistema debita $500 de A, pero falla antes de acreditar a B
- ❌ Resultado: $500 desaparecen del sistema

**Solución con ACID:**
- **Atomicidad**: O se completan ambas operaciones o ninguna
- **Consistencia**: Total del sistema siempre se mantiene
- **Aislamiento**: Otras transacciones no ven estados intermedios
- **Durabilidad**: Una vez confirmada, la transferencia es permanente

### Caso 2: E-commerce

**Problema sin ACID:**
- Producto con stock = 1
- Dos usuarios compran simultáneamente
- ❌ Resultado: Stock = -1 (sobreventa)

**Solución con ACID:**
- **Atomicidad**: Compra completa (reducir stock + crear orden) o nada
- **Consistencia**: Stock nunca puede ser negativo
- **Aislamiento**: Solo un usuario puede comprar el último producto
- **Durabilidad**: Orden confirmada persiste aunque falle el sistema

### Caso 3: Sistema de Reservas

**Problema sin ACID:**
- Vuelo con 1 asiento disponible
- Dos usuarios reservan simultáneamente
- ❌ Resultado: 2 reservas para 1 asiento

**Solución con ACID:**
- **Atomicidad**: Reserva completa (reducir asientos + crear reserva + pago) o nada
- **Consistencia**: Asientos disponibles nunca negativos
- **Aislamiento**: Reservas simultáneas no interfieren
- **Durabilidad**: Reserva confirmada es permanente

---

## 🎤 Presentación

### Diapositiva 1: Introducción
**Guión:**
"Hoy vamos a aprender sobre los principios ACID, que son fundamentales para garantizar la integridad de los datos en sistemas críticos como bancos, e-commerce y reservas de vuelos."

### Diapositiva 2: ¿Por qué ACID?
**Guión:**
"Imaginen que transfieren $500 a un amigo. Sin ACID, el dinero podría desaparecer si el sistema falla en el momento equivocado. Con ACID, garantizamos que o la transferencia se completa totalmente, o no pasa nada."

### Diapositiva 3: Atomicidad
**Guión:**
"La Atomicidad significa 'todo o nada'. Como un átomo que no se puede dividir, una transacción no se puede ejecutar parcialmente. Veamos un ejemplo práctico..."

**Demo:** Ejecutar `make test-acid-sql` y mostrar cómo se crean los clientes y cuentas.

### Diapositiva 4: Consistencia
**Guión:**
"La Consistencia garantiza que las reglas de negocio siempre se respeten. Por ejemplo, un saldo nunca puede ser negativo. Veamos qué pasa cuando intentamos transferir más dinero del disponible..."

**Demo:** Mostrar el último paso de `make test-acid-sql` donde falla la transferencia por saldo insuficiente.

### Diapositiva 5: Aislamiento
**Guión:**
"El Aislamiento evita que las transacciones concurrentes se interfieran. Es como tener carriles separados en una autopista - cada transacción tiene su propio carril."

**Demo:** Ejecutar `make test-acid` para mostrar cómo la aplicación Spring Boot maneja las transacciones.

### Diapositiva 6: Durabilidad
**Guión:**
"La Durabilidad garantiza que una vez confirmada, la transacción persiste para siempre, incluso si se va la luz o se cae el servidor."

**Demo:** Mostrar los balances finales y explicar que estos datos están guardados permanentemente.

### Diapositiva 7: Comparación Práctica
**Guión:**
"Ahora vamos a comparar las dos formas de ejecutar las mismas operaciones: directamente en MySQL con stored procedures, y a través de nuestra aplicación Spring Boot."

### Diapositiva 8: Casos de Uso Reales
**Guión:**
"Los principios ACID son críticos en:
- **Bancos**: Transferencias de dinero
- **E-commerce**: Gestión de inventario
- **Aerolíneas**: Reservas de asientos
- **Hospitales**: Historiales médicos"

### Diapositiva 9: Tecnologías Utilizadas
**Guión:**
"En este taller hemos usado:
- **MySQL 8.0** con stored procedures para garantizar ACID
- **Spring Boot 3.x** con transacciones declarativas
- **Docker/Podman** para un entorno reproducible
- **JPA/Hibernate** para el mapeo objeto-relacional"

### Diapositiva 10: Conclusiones
**Guión:**
"Los principios ACID no son solo teoría - son herramientas prácticas que usamos todos los días para construir sistemas confiables. Cada vez que hacen una compra online o transfieren dinero, ACID está trabajando para proteger sus datos."

---

## 🔬 Ejemplos Detallados por Principio

### ⚛️ ATOMICIDAD (Atomicity)

**Definición:** Una transacción es una unidad indivisible - todo se ejecuta o nada se ejecuta.

#### Ejemplo 1: Sistema de Reservas de Vuelos
- Paso 1: Verificar disponibilidad 
- Paso 2: Reducir asientos disponibles
- Paso 3: Crear reserva
- Paso 4: Procesar pago
- **Si CUALQUIER paso falla, TODO se revierte automáticamente**

**Escenarios de falla:**
- ❌ Pago rechazado → Se revierten asientos y reserva
- ❌ Error de red → Nada se guarda
- ❌ Base de datos llena → Transacción completa falla

#### Ejemplo 2: E-commerce - Procesar Orden
- 1. Crear la orden
- 2. Reducir inventario para cada producto
- 3. Aplicar cupón de descuento (si existe)
- 4. Procesar pago
- **Si falla en cualquier punto, TODO se revierte:**
  - Orden no se crea
  - Stock no se reduce
  - Cupón no se marca como usado
  - Pago no se procesa

### 🔄 CONSISTENCIA (Consistency)

**Definición:** La base de datos siempre mantiene un estado válido, respetando todas las reglas de negocio.

#### Reglas de Consistencia Comunes:
- Saldos bancarios nunca negativos (sin límite de crédito)
- Stock de productos nunca menor a cero
- Fechas de fin siempre posteriores a fechas de inicio
- Emails únicos en el sistema
- Relaciones de integridad referencial

### 🔒 AISLAMIENTO (Isolation)

**Definición:** Las transacciones concurrentes no interfieren entre sí, cada una ve un estado consistente.

#### Niveles de Aislamiento:

1. **READ_UNCOMMITTED** - Puede leer datos no confirmados
   - ⚠️ PELIGROSO: Puede leer datos que luego se revierten
   - Uso: Reportes aproximados donde la precisión no es crítica

2. **READ_COMMITTED** - Solo lee datos confirmados
   - ✅ Seguro: No lee datos no confirmados
   - ⚠️ Problema: Lecturas no repetibles (datos pueden cambiar)
   - Uso: Mayoría de aplicaciones web

3. **REPEATABLE_READ** - Misma lectura durante toda la transacción
   - ✅ Garantiza: Mismos datos en múltiples lecturas
   - ⚠️ Problema: Phantom reads (nuevas filas pueden aparecer)
   - Uso: Reportes que requieren consistencia

4. **SERIALIZABLE** - Máximo aislamiento
   - ✅ Máxima consistencia: Como si fuera la única transacción
   - ❌ Rendimiento: Muy lento, muchos bloqueos
   - Uso: Operaciones críticas (transferencias bancarias)

### 💾 DURABILIDAD (Durability)

**Definición:** Una vez confirmada, la transacción persiste permanentemente, incluso ante fallos del sistema.

#### Mecanismos de Durabilidad:
- **Write-Ahead Logging (WAL)**: Cambios se escriben al log antes que a los datos
- **Checkpoints**: Puntos de sincronización entre memoria y disco
- **Replicación**: Copias en múltiples servidores
- **Backups**: Copias de seguridad regulares

## 🧪 Ejercicios Prácticos

### Ejercicio 1: Transferencia Fallida
1. Ejecutar `make test-acid-sql`
2. Observar cómo falla la transferencia de $10,000 (más del saldo disponible)
3. Verificar que los balances no cambiaron

### Ejercicio 2: Concurrencia
1. Abrir dos terminales
2. Ejecutar `make test-acid` en ambas simultáneamente
3. Observar cómo Spring Boot maneja la concurrencia

### Ejercicio 3: Exploración de Datos
1. Conectar a MySQL: `make db-connect`
2. Explorar las tablas: `SHOW TABLES;`
3. Ver los stored procedures: `SHOW PROCEDURE STATUS;`

### Ejercicio 4: Problemas Comunes

#### Deadlocks
**Problema:** Dos transacciones se bloquean mutuamente.
**Solución:** Ordenar bloqueos consistentemente (siempre en orden ascendente de ID)

#### Transacciones Largas
**Problema:** Transacciones que duran mucho tiempo bloquean recursos.
**Solución:** Procesar en lotes pequeños, mantener transacciones cortas

#### Aislamiento Excesivo
**Problema:** Usar SERIALIZABLE cuando no es necesario.
**Solución:** Usar el nivel mínimo necesario, `readOnly=true` para lecturas

---

## 🆚 Comparación: ACID vs BASE (NoSQL)

### Bases de Datos Relacionales (ACID)
**Características:**
- ✅ Consistencia fuerte
- ✅ Transacciones ACID completas
- ❌ Menor escalabilidad horizontal
- ❌ Esquema rígido

**Cuándo usar:**
- Transacciones financieras
- Inventarios críticos
- Reservas (hoteles, vuelos)
- Sistemas médicos

### Bases de Datos NoSQL (BASE)
**Características:**
- ✅ Alta disponibilidad
- ✅ Escalabilidad horizontal
- ✅ Esquema flexible
- ❌ Consistencia eventual

**Cuándo usar:**
- Redes sociales
- Logs y analytics
- Catálogos de productos
- Sistemas de recomendación

## 📊 Tecnologías

- **Spring Boot 3.x** - Framework Java
- **MySQL 8.0** - Base de datos
- **Podman** - Contenedores
- **JPA/Hibernate** - ORM para transacciones
- **Stored Procedures** - Lógica de negocio en BD

## 📝 Mejores Prácticas

### ✅ Hacer
1. **Mantener transacciones cortas** - Menos bloqueos, mejor rendimiento
2. **Usar el nivel de aislamiento mínimo necesario** - Balance entre consistencia y performance
3. **Manejar excepciones apropiadamente** - Rollback automático con RuntimeException
4. **Usar `@Transactional(readOnly = true)`** para operaciones de solo lectura
5. **Ordenar bloqueos consistentemente** - Evitar deadlocks
6. **Validar reglas de negocio antes de modificar datos**

### ❌ Evitar
1. **Transacciones muy largas** - Bloquean recursos por mucho tiempo
2. **Llamadas HTTP dentro de transacciones** - Pueden fallar y causar rollback
3. **Usar SERIALIZABLE por defecto** - Impacto severo en performance
4. **Ignorar excepciones** - Pueden dejar datos inconsistentes
5. **Transacciones anidadas innecesarias** - Complejidad adicional
6. **Modificar datos sin validación** - Rompe consistencia

---