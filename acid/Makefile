.PHONY: help init-podman start-podman stop-podman status-podman build up down logs test-acid clean status db-connect

help:
	@echo "Comandos disponibles:"
	@echo "PODMAN:"
	@echo "make init-podman    - 🚀 Inicializar Podman (primera vez)"
	@echo "make start-podman   - ▶️ Iniciar máquina Podman"
	@echo "make status-podman  - 🔍 Ver estado de Podman"
	@echo "make images         - 📷 Ver todas las imágenes"
	@echo "  make build      - Construir imágenes Docker"
	@echo "  make up         - Levantar servicios"
	@echo "  make down       - Detener servicios"
	@echo "  make status     - Ver estado de servicios"
	@echo "  make db-connect - Conectar a MySQL (CLI)"

	@echo "  make logs       - Ver logs de los servicios"
	@echo "  make test-acid      - Ejecutar pruebas ACID"
	@echo "  make test-acid-sql  - Ejecutar pruebas ACID en MySQL"
	@echo "  make test-api       - Probar API"
	@echo "  make create-customer - Crear cliente"
	@echo "  make get-customer   - Obtener cliente"
	@echo "  make create-account - Crear cuenta"
	@echo "  make demo-mysql     - Demo ACID en MySQL"
	@echo "  make clean      - Limpiar contenedores y volúmenes"

init-podman:
	@echo "🚀 Inicializando Podman..."
	podman machine init
	podman machine start
	@echo "✅ Podman inicializado y iniciado"

start-podman:
	@echo "▶️ Iniciando máquina Podman..."
	podman machine start
	@echo "✅ Máquina Podman iniciada"

stop-podman:
	@echo "⏹️ Deteniendo máquina Podman..."
	podman machine stop
	@echo "✅ Máquina Podman detenida"

status-podman:
	@echo "🔍 Estado de Podman:"
	podman machine list
	@echo ""
	@echo "Conexiones:"
	podman system connection list

build:
	@echo "🔨 Iniciando Podman machine..."
	@podman machine start || true
	@echo "🔨 Construyendo imágenes con Podman..."
	~/.local/bin/podman-compose build

up:
	@echo "🚀 Levantando servicios..."
	~/.local/bin/podman-compose up -d
	@echo "⏳ Esperando que los servicios estén listos..."
	@sleep 15
	@echo "✅ Servicios listos!"
	@echo "📍 Spring Boot: http://localhost:8080"
	@echo "📍 MySQL: localhost:3306"

down:
	@echo "🛑 Deteniendo servicios..."
	~/.local/bin/podman-compose down

logs:
	@echo "📋 Logs de los servicios..."
	~/.local/bin/podman-compose logs -f

test-acid:
	@echo "🧪 Ejecutando pruebas ACID desde Spring Boot..."
	@echo ""
	@echo "📝 EJECUCIÓN 1: CREAR CLIENTE 1 (Elvin González)"
	@curl -X POST http://localhost:8080/api/customer \
		-H "Content-Type: application/json" \
		-d '{"firstName":"Elvin","lastName":"González","email":"elvin.gonzalez@email.com","phone":"555-0001"}' 2>/dev/null | jq .
	@echo ""
	@echo "📝 EJECUCIÓN 2: CREAR CLIENTE 2 (Diego Ordóñez)"
	@curl -X POST http://localhost:8080/api/customer \
		-H "Content-Type: application/json" \
		-d '{"firstName":"Diego","lastName":"Ordóñez","email":"diego.ordonez@email.com","phone":"555-0002"}' 2>/dev/null | jq .
	@echo ""
	@echo "📝 EJECUCIÓN 3: CREAR CUENTA PARA CLIENTE 1 ($$5000 CORRIENTE)"
	@curl -X POST http://localhost:8080/api/account \
		-H "Content-Type: application/json" \
		-d '{"customerId":1,"accountType":"CORRIENTE","initialBalance":5000}' 2>/dev/null | jq .
	@echo ""
	@echo "📝 EJECUCIÓN 4: CREAR CUENTA PARA CLIENTE 2 ($$3000 AHORROS)"
	@curl -X POST http://localhost:8080/api/account \
		-H "Content-Type: application/json" \
		-d '{"customerId":2,"accountType":"AHORROS","initialBalance":3000}' 2>/dev/null | jq .
	@echo ""
	@echo "📝 EJECUCIÓN 5: TRANSFERENCIA CLIENTE 1 A CLIENTE 2 ($$1000 - ACID)"
	@curl -X POST http://localhost:8080/api/transfer \
		-H "Content-Type: application/json" \
		-d '{"fromAccountId":1,"toAccountId":2,"amount":1000}' 2>/dev/null | jq .
	@echo ""
	@echo "📝 EJECUCIÓN 6: VERIFICAR BALANCES FINALES"
	@echo "Cuenta 1 (Elvin):"
	@curl -X GET http://localhost:8080/api/account/1 2>/dev/null | jq .
	@echo "Cuenta 2 (Diego):"
	@curl -X GET http://localhost:8080/api/account/2 2>/dev/null | jq .
	@echo ""
	@echo "📝 EJECUCIÓN 7: INTENTAR TRANSFERIR MÁS DINERO DEL DISPONIBLE (debe fallar)"
	@curl -X POST http://localhost:8080/api/transfer \
		-H "Content-Type: application/json" \
		-d '{"fromAccountId":1,"toAccountId":2,"amount":10000}' 2>/dev/null | jq .
	@echo ""
	@echo "✅ Pruebas ACID desde Spring Boot completadas"

test-api:
	@echo "✅ Probando API..."
	@curl -s http://localhost:8080/api/test | jq .

create-customer:
	@echo "👤 Creando cliente..."
	@curl -X POST http://localhost:8080/api/customer \
		-H "Content-Type: application/json" \
		-d '{"firstName":"Juan","lastName":"Perez","email":"juan@test.com","phone":"123456789"}' | jq .

get-customer:
	@echo "🔍 Obteniendo cliente ID 1..."
	@curl -X GET http://localhost:8080/api/customer/1 | jq .

create-account:
	@echo "🏦 Creando cuenta para cliente ID 1..."
	@curl -X POST http://localhost:8080/api/account \
		-H "Content-Type: application/json" \
		-d '{"customerId":1,"accountType":"AHORROS","initialBalance":1000}' | jq .

demo-mysql:
	@echo "💾 Demostración ACID desde MySQL..."
	@echo "Conectando a MySQL para demostrar stored procedures..."
	@echo "Ejecuta: make db-connect"
	@echo "Luego ejecuta los siguientes comandos:"
	@echo "CALL sp_create_customer('Juan', 'Perez', 'juan@demo.com', '123456789', @id, @status, @msg);"
	@echo "SELECT @id, @status, @msg;"

status:
	@echo "📊 Estado de los servicios:"
	@podman ps --filter name=acid
	@echo ""
	@echo "🔍 Verificando conexión a MySQL..."
	@podman exec acid-mysql mysqladmin -uroot -p123456 ping 2>/dev/null && echo "✅ MySQL está funcionando" || echo "❌ MySQL no responde"
	@echo ""
	@echo "📋 Datos de conexión:"
	@echo "   Host: localhost"
	@echo "   Port: 3306"
	@echo "   Database: bankdb"
	@echo "   User: root"
	@echo "   Password: 123456"

db-connect:
	@echo "🔌 Conectando a MySQL..."
	podman exec -it acid-mysql mysql -uroot -p123456 bankdb

test-acid-sql:
	@echo "🧪 Ejecutando pruebas ACID en MySQL..."
	@echo ""
	@echo "📝 Paso 1: Limpiar datos existentes"
	@podman exec acid-mysql mysql -uroot -p123456 bankdb -e "SET FOREIGN_KEY_CHECKS = 0; TRUNCATE TABLE transactions; TRUNCATE TABLE accounts; TRUNCATE TABLE customers; SET FOREIGN_KEY_CHECKS = 1;" 2>/dev/null
	@echo "✅ Datos limpiados"
	@echo ""
	@echo "📝 EJECUCIÓN 1: CREAR CLIENTE 1"
	@podman exec acid-mysql mysql -uroot -p123456 bankdb -e "CALL sp_create_customer('Elvin', 'González', 'elvin.gonzalez@email.com', '555-0001', @cust_id1, @cust_status1, @cust_msg1); SELECT @cust_id1 AS customer_id, @cust_status1 AS estado, @cust_msg1 AS mensaje;"
	@echo ""
	@echo "📝 EJECUCIÓN 2: CREAR CLIENTE 2"
	@podman exec acid-mysql mysql -uroot -p123456 bankdb -e "CALL sp_create_customer('Diego', 'Ordóñez', 'diego.ordonez@email.com', '555-0002', @cust_id2, @cust_status2, @cust_msg2); SELECT @cust_id2 AS customer_id, @cust_status2 AS estado, @cust_msg2 AS mensaje;"
	@echo ""
	@echo "📝 EJECUCIÓN 3: CREAR CUENTA PARA CLIENTE 1"
	@podman exec acid-mysql mysql -uroot -p123456 bankdb -e "CALL sp_create_account(1, 'ACC-2024-001', 'CORRIENTE', 5000.00, @acc_id1, @acc_status1, @acc_msg1); SELECT @acc_id1 AS account_id, @acc_status1 AS estado, @acc_msg1 AS mensaje;"
	@echo ""
	@echo "📝 EJECUCIÓN 4: CREAR CUENTA PARA CLIENTE 2"
	@podman exec acid-mysql mysql -uroot -p123456 bankdb -e "CALL sp_create_account(2, 'ACC-2024-002', 'AHORROS', 3000.00, @acc_id2, @acc_status2, @acc_msg2); SELECT @acc_id2 AS account_id, @acc_status2 AS estado, @acc_msg2 AS mensaje;"
	@echo ""
	@echo "📝 EJECUCIÓN 5: TRANSFERENCIA CLIENTE 1 A CLIENTE 2 (ACID)"
	@podman exec acid-mysql mysql -uroot -p123456 bankdb -e "CALL sp_transfer_funds(1, 2, 1000.00, @tx_id, @tx_status, @tx_msg); SELECT @tx_id AS transaction_id, @tx_status AS estado, @tx_msg AS mensaje;"
	@echo ""
	@echo "📝 EJECUCIÓN 6: VERIFICAR BALANCES FINALES"
	@podman exec acid-mysql mysql -uroot -p123456 bankdb -e "SELECT c.first_name, c.last_name, a.account_number, a.account_type, a.balance FROM customers c JOIN accounts a ON c.customer_id = a.customer_id ORDER BY c.customer_id;"
	@echo ""
	@echo "📝 EJECUCIÓN 7: VER HISTORIAL DE TRANSACCIONES"
	@podman exec acid-mysql mysql -uroot -p123456 bankdb -e "SELECT t.transaction_id, t.transaction_type, fa.account_number AS cuenta_origen, ta.account_number AS cuenta_destino, t.amount, t.status, t.created_at FROM transactions t LEFT JOIN accounts fa ON t.from_account_id = fa.account_id LEFT JOIN accounts ta ON t.to_account_id = ta.account_id ORDER BY t.created_at DESC;"
	@echo ""
	@echo "✅ Pruebas ACID en MySQL completadas"

clean:
	@echo "🧹 Limpiando contenedores y volúmenes..."
	~/.local/bin/podman-compose down -v
	@echo "✅ Limpieza completada"
