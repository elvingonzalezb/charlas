-- ============================================
-- SP: CREAR CUENTA
-- ============================================

USE bankdb;

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
    
    -- Verificar que el cliente existe
    SELECT COUNT(*) INTO v_customer_exists FROM customers WHERE customer_id = p_customer_id;
    
    -- Verificar que el número de cuenta no existe
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
        INSERT INTO accounts (customer_id, account_number, account_type, balance, name)
        VALUES (p_customer_id, p_account_number, p_account_type, p_initial_balance, CONCAT('Cuenta ', p_account_type));
        
        SET p_account_id = LAST_INSERT_ID();
        SET p_status = 'SUCCESS';
        SET p_message = 'Cuenta creada exitosamente';
        
        COMMIT;
    END IF;
END;