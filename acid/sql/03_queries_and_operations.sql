-- ============================================
-- CONSULTAS Y OPERACIONES
-- SELECT statements, llamadas a SP, funciones
-- ============================================

USE bankdb;
DELETE from customers;
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE transactions;
TRUNCATE TABLE accounts;
TRUNCATE TABLE customers;
SET FOREIGN_KEY_CHECKS = 1;

-- Ver todos los clientes
SELECT * FROM customers;
SELECT * FROM accounts;

-- Verificar que los SP existen
SHOW PROCEDURE STATUS WHERE Name LIKE 'sp_%';

-- ============================================
-- EJECUCIÓN 1: CREAR CLIENTE 1
-- ============================================
CALL sp_create_customer('Elvin', 'González', 'elvin.gonzalez@email.com', '555-0001', @cust_id1, @cust_status1, @cust_msg1);
SELECT @cust_id1 AS customer_id, @cust_status1 AS estado, @cust_msg1 AS mensaje;

-- ============================================
-- EJECUCIÓN 2: CREAR CLIENTE 2
-- ============================================
CALL sp_create_customer('Diego', 'Ordóñez', 'diego.ordonez@email.com', '555-0002', @cust_id2, @cust_status2, @cust_msg2);
SELECT @cust_id2 AS customer_id, @cust_status2 AS estado, @cust_msg2 AS mensaje;

-- ============================================
-- EJECUCIÓN 3: CREAR CUENTA PARA CLIENTE 1
-- ============================================
CALL sp_create_account(1, 'ACC-2024-001', 'CORRIENTE', 5000.00, @acc_id1, @acc_status1, @acc_msg1);
SELECT @acc_id1 AS account_id, @acc_status1 AS estado, @acc_msg1 AS mensaje;

-- ============================================
-- EJECUCIÓN 4: CREAR CUENTA PARA CLIENTE 2
-- ============================================
CALL sp_create_account(2, 'ACC-2024-002', 'AHORROS', 3000.00, @acc_id2, @acc_status2, @acc_msg2);
SELECT @acc_id2 AS account_id, @acc_status2 AS estado, @acc_msg2 AS mensaje;


-- ============================================
-- EJECUCIÓN 5: TRANSFERENCIA CLIENTE 1 A CLIENTE 2 (ACID)
-- ============================================
CALL sp_transfer_funds(1, 2, 1000.00, @tx_id, @tx_status, @tx_msg);
SELECT @tx_id AS transaction_id, @tx_status AS estado, @tx_msg AS mensaje;

-- ============================================
-- EJECUCIÓN 6: VERIFICAR BALANCES FINALES
-- ============================================
SELECT 
    c.first_name,
    c.last_name,
    a.account_number,
    a.account_type,
    a.balance
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
ORDER BY c.customer_id;

-- ============================================
-- EJECUCIÓN 7: VER HISTORIAL DE TRANSACCIONES
-- ============================================
SELECT 
    t.transaction_id,
    t.transaction_type,
    fa.account_number AS cuenta_origen,
    ta.account_number AS cuenta_destino,
    t.amount,
    t.status,
    t.created_at
FROM transactions t
LEFT JOIN accounts fa ON t.from_account_id = fa.account_id
LEFT JOIN accounts ta ON t.to_account_id = ta.account_id
ORDER BY t.created_at DESC;