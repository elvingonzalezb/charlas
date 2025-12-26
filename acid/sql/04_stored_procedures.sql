-- ============================================
-- STORED PROCEDURES
-- Procedimientos almacenados para operaciones ACID
-- Ejecutar cada uno por separado
-- ============================================

USE bankdb;

-- ============================================
-- SP 1: CREAR CLIENTE (Protección SQL Injection)
-- ============================================
DROP PROCEDURE IF EXISTS sp_create_customer;

CREATE PROCEDURE sp_create_customer(
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100),
    IN p_email VARCHAR(150),
    IN p_phone VARCHAR(20),
    OUT p_customer_id BIGINT,
    OUT p_status VARCHAR(50),
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_email_exists INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status = 'FAILED';
        SET p_message = 'Error al crear el cliente';
        SET p_customer_id = NULL;
    END;
    
    SET p_customer_id = NULL;
    SET p_status = 'FAILED';
    SET p_message = 'Error desconocido';
    
    START TRANSACTION;
    
    SELECT COUNT(*) INTO v_email_exists FROM customers WHERE email = p_email;
    
    IF p_first_name IS NULL OR p_first_name = '' THEN
        SET p_status = 'FAILED';
        SET p_message = 'Nombre es requerido';
        ROLLBACK;
    ELSEIF p_last_name IS NULL OR p_last_name = '' THEN
        SET p_status = 'FAILED';
        SET p_message = 'Apellido es requerido';
        ROLLBACK;
    ELSEIF p_email IS NULL OR p_email = '' THEN
        SET p_status = 'FAILED';
        SET p_message = 'Email es requerido';
        ROLLBACK;
    ELSEIF v_email_exists > 0 THEN
        SET p_status = 'FAILED';
        SET p_message = 'Email ya existe';
        ROLLBACK;
    ELSE
        INSERT INTO customers (first_name, last_name, email, phone)
        VALUES (p_first_name, p_last_name, p_email, p_phone);
        
        SET p_customer_id = LAST_INSERT_ID();
        SET p_status = 'SUCCESS';
        SET p_message = 'Cliente creado exitosamente';
        
        COMMIT;
    END IF;
END;

-- ============================================
-- SP 2: CREAR CUENTA
-- ============================================
DROP PROCEDURE IF EXISTS sp_create_account;

CREATE PROCEDURE sp_create_account(
    IN p_customer_id BIGINT,
    IN p_account_number VARCHAR(20),
    IN p_account_type ENUM('CORRIENTE','AHORROS','INVERSION'),
    IN p_initial_balance DECIMAL(38,2),
    OUT p_account_id BIGINT,
    OUT p_status VARCHAR(50),
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_customer_exists INT DEFAULT 0;
    DECLARE v_account_exists INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status = 'FAILED';
        SET p_message = 'Error al crear la cuenta';
        SET p_account_id = NULL;
    END;
    
    SET p_account_id = NULL;
    SET p_status = 'FAILED';
    SET p_message = 'Error desconocido';
    
    START TRANSACTION;
    
    SELECT COUNT(*) INTO v_customer_exists FROM customers WHERE customer_id = p_customer_id;
    SELECT COUNT(*) INTO v_account_exists FROM accounts WHERE account_number = p_account_number;
    
    IF v_customer_exists = 0 THEN
        SET p_status = 'FAILED';
        SET p_message = 'Cliente no existe';
        ROLLBACK;
    ELSEIF v_account_exists > 0 THEN
        SET p_status = 'FAILED';
        SET p_message = 'Número de cuenta ya existe';
        ROLLBACK;
    ELSEIF p_initial_balance < 0 THEN
        SET p_status = 'FAILED';
        SET p_message = 'El balance inicial no puede ser negativo';
        ROLLBACK;
    ELSE
        INSERT INTO accounts (customer_id, account_number, account_type, balance)
        VALUES (p_customer_id, p_account_number, p_account_type, p_initial_balance);
        
        SET p_account_id = LAST_INSERT_ID();
        SET p_status = 'SUCCESS';
        SET p_message = 'Cuenta creada exitosamente';
        
        COMMIT;
    END IF;
END;

-- ============================================
-- SP 3: ACTUALIZAR CLIENTE
-- ============================================
DROP PROCEDURE IF EXISTS sp_update_customer;

CREATE PROCEDURE sp_update_customer(
    IN p_customer_id BIGINT,
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100),
    IN p_phone VARCHAR(20),
    OUT p_status VARCHAR(50),
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_customer_exists INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status = 'FAILED';
        SET p_message = 'Error al actualizar el cliente';
    END;
    
    START TRANSACTION;
    
    SELECT COUNT(*) INTO v_customer_exists FROM customers WHERE customer_id = p_customer_id;
    
    IF v_customer_exists = 0 THEN
        SET p_status = 'FAILED';
        SET p_message = 'Cliente no existe';
        ROLLBACK;
    ELSEIF p_first_name IS NULL OR p_first_name = '' THEN
        SET p_status = 'FAILED';
        SET p_message = 'Nombre es requerido';
        ROLLBACK;
    ELSEIF p_last_name IS NULL OR p_last_name = '' THEN
        SET p_status = 'FAILED';
        SET p_message = 'Apellido es requerido';
        ROLLBACK;
    ELSE
        UPDATE customers 
        SET first_name = p_first_name, last_name = p_last_name, phone = p_phone, updated_at = CURRENT_TIMESTAMP
        WHERE customer_id = p_customer_id;
        
        SET p_status = 'SUCCESS';
        SET p_message = 'Cliente actualizado exitosamente';
        
        COMMIT;
    END IF;
END;

-- ============================================
-- SP 4: OBTENER CLIENTE POR ID
-- ============================================
DROP PROCEDURE IF EXISTS sp_get_customer;

CREATE PROCEDURE sp_get_customer(
    IN p_customer_id BIGINT,
    OUT p_status VARCHAR(50),
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_customer_exists INT DEFAULT 0;
    DECLARE v_first_name VARCHAR(100);
    DECLARE v_last_name VARCHAR(100);
    DECLARE v_email VARCHAR(150);
    
    SELECT COUNT(*), MAX(first_name), MAX(last_name), MAX(email)
    INTO v_customer_exists, v_first_name, v_last_name, v_email
    FROM customers 
    WHERE customer_id = p_customer_id;
    
    IF v_customer_exists = 0 THEN
        SET p_status = 'NOT_FOUND';
        SET p_message = 'Cliente no encontrado';
    ELSE
        SET p_status = 'SUCCESS';
        SET p_message = CONCAT('Cliente encontrado: ', v_first_name, ' ', v_last_name, ' (', v_email, ')');
    END IF;
END;

-- ============================================
-- SP 5: TRANSFERENCIA (ACID completo)
-- ============================================
DROP PROCEDURE IF EXISTS sp_transfer_funds;

CREATE PROCEDURE sp_transfer_funds(
    IN p_from_account_id BIGINT,
    IN p_to_account_id BIGINT,
    IN p_amount DECIMAL(15,2),
    OUT p_transaction_id BIGINT,
    OUT p_status VARCHAR(50),
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_from_balance DECIMAL(15,2);
    DECLARE v_from_status VARCHAR(20);
    DECLARE v_to_status VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status = 'FAILED';
        SET p_message = 'Error en la transacción - Rollback ejecutado';
        SET p_transaction_id = NULL;
    END;
    
    START TRANSACTION;
    
    IF p_amount <= 0 THEN
        SET p_status = 'FAILED';
        SET p_message = 'El monto debe ser mayor a cero';
        ROLLBACK;
    ELSE
        SELECT balance, status INTO v_from_balance, v_from_status
        FROM accounts WHERE account_id = p_from_account_id FOR UPDATE;
        
        SELECT status INTO v_to_status
        FROM accounts WHERE account_id = p_to_account_id FOR UPDATE;
        
        IF v_from_status IS NULL THEN
            SET p_status = 'FAILED';
            SET p_message = 'Cuenta origen no existe';
            ROLLBACK;
        ELSEIF v_to_status IS NULL THEN
            SET p_status = 'FAILED';
            SET p_message = 'Cuenta destino no existe';
            ROLLBACK;
        ELSEIF v_from_status != 'ACTIVA' THEN
            SET p_status = 'FAILED';
            SET p_message = 'Cuenta origen no está activa';
            ROLLBACK;
        ELSEIF v_to_status != 'ACTIVA' THEN
            SET p_status = 'FAILED';
            SET p_message = 'Cuenta destino no está activa';
            ROLLBACK;
        ELSEIF v_from_balance < p_amount THEN
            SET p_status = 'FAILED';
            SET p_message = 'Saldo insuficiente';
            ROLLBACK;
        ELSE
            INSERT INTO transactions (transaction_type, from_account_id, to_account_id, amount, status, description)
            VALUES ('TRANSFERENCIA', p_from_account_id, p_to_account_id, p_amount, 'PENDIENTE', 'Transferencia entre cuentas');
            
            SET p_transaction_id = LAST_INSERT_ID();
            
            UPDATE accounts 
            SET balance = balance - p_amount, updated_at = CURRENT_TIMESTAMP
            WHERE account_id = p_from_account_id;
            
            UPDATE accounts 
            SET balance = balance + p_amount, updated_at = CURRENT_TIMESTAMP
            WHERE account_id = p_to_account_id;
            
            UPDATE transactions 
            SET status = 'COMPLETADA', completed_at = CURRENT_TIMESTAMP
            WHERE transaction_id = p_transaction_id;
            
            SET p_status = 'COMPLETED';
            SET p_message = 'Transferencia exitosa';
            
            COMMIT;
        END IF;
    END IF;
END;

-- ============================================
-- SP 6: DEPÓSITO
-- ============================================
DROP PROCEDURE IF EXISTS sp_deposit;

CREATE PROCEDURE sp_deposit(
    IN p_account_id BIGINT,
    IN p_amount DECIMAL(15,2),
    OUT p_transaction_id BIGINT,
    OUT p_status VARCHAR(50),
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status = 'FAILED';
        SET p_message = 'Error en el depósito';
    END;
    
    START TRANSACTION;
    
    IF p_amount <= 0 THEN
        SET p_status = 'FAILED';
        SET p_message = 'El monto debe ser mayor a cero';
        ROLLBACK;
    ELSE
        INSERT INTO transactions (transaction_type, to_account_id, amount, status)
        VALUES ('DEPOSITO', p_account_id, p_amount, 'PENDIENTE');
        
        SET p_transaction_id = LAST_INSERT_ID();
        
        UPDATE accounts 
        SET balance = balance + p_amount
        WHERE account_id = p_account_id;
        
        UPDATE transactions 
        SET status = 'COMPLETADA', completed_at = CURRENT_TIMESTAMP
        WHERE transaction_id = p_transaction_id;
        
        SET p_status = 'COMPLETED';
        SET p_message = 'Depósito exitoso';
        
        COMMIT;
    END IF;
END;

-- ============================================
-- SP 7: RETIRO
-- ============================================
DROP PROCEDURE IF EXISTS sp_withdrawal;

CREATE PROCEDURE sp_withdrawal(
    IN p_account_id BIGINT,
    IN p_amount DECIMAL(15,2),
    OUT p_transaction_id BIGINT,
    OUT p_status VARCHAR(50),
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_balance DECIMAL(15,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status = 'FAILED';
        SET p_message = 'Error en el retiro';
    END;
    
    START TRANSACTION;
    
    SELECT balance INTO v_balance
    FROM accounts WHERE account_id = p_account_id FOR UPDATE;
    
    IF p_amount <= 0 THEN
        SET p_status = 'FAILED';
        SET p_message = 'El monto debe ser mayor a cero';
        ROLLBACK;
    ELSEIF v_balance < p_amount THEN
        SET p_status = 'FAILED';
        SET p_message = 'Saldo insuficiente';
        ROLLBACK;
    ELSE
        INSERT INTO transactions (transaction_type, from_account_id, amount, status)
        VALUES ('RETIRO', p_account_id, p_amount, 'PENDIENTE');
        
        SET p_transaction_id = LAST_INSERT_ID();
        
        UPDATE accounts 
        SET balance = balance - p_amount
        WHERE account_id = p_account_id;
        
        UPDATE transactions 
        SET status = 'COMPLETADA', completed_at = CURRENT_TIMESTAMP
        WHERE transaction_id = p_transaction_id;
        
        SET p_status = 'COMPLETED';
        SET p_message = 'Retiro exitoso';
        
        COMMIT;
    END IF;
END;

-- ============================================
-- FUNCIÓN: BALANCE TOTAL CLIENTE
-- ============================================
DROP FUNCTION IF EXISTS fn_get_customer_total_balance;

CREATE FUNCTION fn_get_customer_total_balance(p_customer_id BIGINT)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(15,2);
    
    SELECT COALESCE(SUM(balance), 0) INTO v_total
    FROM accounts
    WHERE customer_id = p_customer_id AND status = 'ACTIVA';
    
    RETURN v_total;
ENDURRENT_TIMESTAMP
            WHERE account_id = p_to_account_id;
            
            UPDATE transactions 
            SET status = 'COMPLETADA', completed_at = CURRENT_TIMESTAMP
            WHERE transaction_id = p_transaction_id;
            
            SET p_status = 'COMPLETED';
            SET p_message = 'Transferencia exitosa';
            
            COMMIT;
        END IF;
    END IF;
END;

-- ============================================
-- SP 5: DEPÓSITO
-- ============================================
DROP PROCEDURE IF EXISTS sp_deposit;

CREATE PROCEDURE sp_deposit(
    IN p_account_id BIGINT,
    IN p_amount DECIMAL(15,2),
    OUT p_transaction_id BIGINT,
    OUT p_status VARCHAR(50),
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status = 'FAILED';
        SET p_message = 'Error en el depósito';
    END;
    
    START TRANSACTION;
    
    IF p_amount <= 0 THEN
        SET p_status = 'FAILED';
        SET p_message = 'El monto debe ser mayor a cero';
        ROLLBACK;
    ELSE
        INSERT INTO transactions (transaction_type, to_account_id, amount, status)
        VALUES ('DEPOSITO', p_account_id, p_amount, 'PENDIENTE');
        
        SET p_transaction_id = LAST_INSERT_ID();
        
        UPDATE accounts 
        SET balance = balance + p_amount
        WHERE account_id = p_account_id;
        
        UPDATE transactions 
        SET status = 'COMPLETADA', completed_at = CURRENT_TIMESTAMP
        WHERE transaction_id = p_transaction_id;
        
        SET p_status = 'COMPLETED';
        SET p_message = 'Depósito exitoso';
        
        COMMIT;
    END IF;
END;

-- ============================================
-- SP 6: RETIRO
-- ============================================
DROP PROCEDURE IF EXISTS sp_withdrawal;

CREATE PROCEDURE sp_withdrawal(
    IN p_account_id BIGINT,
    IN p_amount DECIMAL(15,2),
    OUT p_transaction_id BIGINT,
    OUT p_status VARCHAR(50),
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_balance DECIMAL(15,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status = 'FAILED';
        SET p_message = 'Error en el retiro';
    END;
    
    START TRANSACTION;
    
    SELECT balance INTO v_balance
    FROM accounts WHERE account_id = p_account_id FOR UPDATE;
    
    IF p_amount <= 0 THEN
        SET p_status = 'FAILED';
        SET p_message = 'El monto debe ser mayor a cero';
        ROLLBACK;
    ELSEIF v_balance < p_amount THEN
        SET p_status = 'FAILED';
        SET p_message = 'Saldo insuficiente';
        ROLLBACK;
    ELSE
        INSERT INTO transactions (transaction_type, from_account_id, amount, status)
        VALUES ('RETIRO', p_account_id, p_amount, 'PENDIENTE');
        
        SET p_transaction_id = LAST_INSERT_ID();
        
        UPDATE accounts 
        SET balance = balance - p_amount
        WHERE account_id = p_account_id;
        
        UPDATE transactions 
        SET status = 'COMPLETADA', completed_at = CURRENT_TIMESTAMP
        WHERE transaction_id = p_transaction_id;
        
        SET p_status = 'COMPLETED';
        SET p_message = 'Retiro exitoso';
        
        COMMIT;
    END IF;
END;

-- ============================================
-- FUNCIÓN: BALANCE TOTAL CLIENTE
-- ============================================
DROP FUNCTION IF EXISTS fn_get_customer_total_balance;

CREATE FUNCTION fn_get_customer_total_balance(p_customer_id BIGINT)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(15,2);
    
    SELECT COALESCE(SUM(balance), 0) INTO v_total
    FROM accounts
    WHERE customer_id = p_customer_id AND status = 'ACTIVA';
    
    RETURN v_total;
END;