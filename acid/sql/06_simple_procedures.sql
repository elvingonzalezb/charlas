-- Stored Procedures simplificados para el taller
USE bankdb;

-- SP simple para crear cliente
DROP PROCEDURE IF EXISTS sp_create_customer_simple;
CREATE PROCEDURE sp_create_customer_simple(
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100),
    IN p_email VARCHAR(150),
    IN p_phone VARCHAR(20)
)
BEGIN
    INSERT INTO customers (first_name, last_name, email, phone)
    VALUES (p_first_name, p_last_name, p_email, p_phone);
END;

-- SP simple para obtener cliente
DROP PROCEDURE IF EXISTS sp_get_customer_simple;
CREATE PROCEDURE sp_get_customer_simple(
    IN p_customer_id BIGINT
)
BEGIN
    SELECT * FROM customers WHERE customer_id = p_customer_id;
END;

-- SP simple para transferencia
DROP PROCEDURE IF EXISTS sp_transfer_simple;
CREATE PROCEDURE sp_transfer_simple(
    IN p_from_account_id BIGINT,
    IN p_to_account_id BIGINT,
    IN p_amount DECIMAL(15,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Verificar saldo suficiente
    IF (SELECT balance FROM accounts WHERE account_id = p_from_account_id) < p_amount THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo insuficiente';
    END IF;
    
    -- Realizar transferencia
    UPDATE accounts SET balance = balance - p_amount WHERE account_id = p_from_account_id;
    UPDATE accounts SET balance = balance + p_amount WHERE account_id = p_to_account_id;
    
    -- Registrar transacción
    INSERT INTO transactions (transaction_type, from_account_id, to_account_id, amount, status)
    VALUES ('TRANSFERENCIA', p_from_account_id, p_to_account_id, p_amount, 'COMPLETADA');
    
    COMMIT;
END;