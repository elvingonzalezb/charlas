# Scripts SQL - Sistema Bancario ACID

## Orden de ejecución

Ejecuta los scripts en este orden:

1. **01_DDL_schema.sql** - Crea las tablas (DDL)
2. **02_DML_data.sql** - Inserta datos de prueba (DML)
3. **03_DCL_permissions.sql** - Crea usuarios y permisos (DCL)
4. **04_stored_procedures.sql** - Crea procedimientos almacenados
5. **05_triggers.sql** - Crea triggers de auditoría

## Conexión a MySQL

### Desde línea de comandos:
```bash
# Conectar como root
podman exec -it acid-mysql mysql -uroot -prootpassword bankdb

# Conectar como usuario de aplicación
podman exec -it acid-mysql mysql -ubank_app -papp_password_123 bankdb
```

### Desde DBeaver:
- Host: localhost
- Port: 3306
- Database: bankdb
- Username: root
- Password: 123456

## Usuarios creados

| Usuario | Password | Permisos |
|---------|----------|----------|
| root | rootpassword | Todos |
| bank_app | app_password_123 | SELECT, INSERT, UPDATE en tablas principales |
| bank_readonly | readonly_password_123 | Solo SELECT |
| bank_admin | admin_password_123 | Todos en bankdb |

## Stored Procedures

### sp_transfer_funds
Transferencia entre cuentas con ACID completo:
```sql
CALL sp_transfer_funds(1, 2, 100.00, @tx_id, @status, @msg);
SELECT @tx_id, @status, @msg;
```

### sp_deposit
Depósito en cuenta:
```sql
CALL sp_deposit(1, 500.00, @tx_id, @status, @msg);
SELECT @tx_id, @status, @msg;
```

### sp_withdrawal
Retiro de cuenta:
```sql
CALL sp_withdrawal(1, 200.00, @tx_id, @status, @msg);
SELECT @tx_id, @status, @msg;
```

## Funciones

### fn_get_customer_total_balance
Obtiene el balance total de todas las cuentas de un cliente:
```sql
SELECT fn_get_customer_total_balance(1);
```

## Consultas útiles

```sql
-- Ver todas las cuentas con sus clientes
SELECT c.first_name, c.last_name, a.account_number, a.account_type, a.balance
FROM customers c
JOIN accounts a ON c.id = a.customer_id;

-- Ver historial de transacciones
SELECT t.*, 
       a1.account_number as from_account,
       a2.account_number as to_account
FROM transactions t
LEFT JOIN accounts a1 ON t.from_account_id = a1.id
LEFT JOIN accounts a2 ON t.to_account_id = a2.id
ORDER BY t.created_at DESC;

-- Ver logs de auditoría
SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 20;
```
