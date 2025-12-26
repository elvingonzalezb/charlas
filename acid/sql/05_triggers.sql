-- ============================================
-- Triggers para auditoría automática
-- ============================================

USE bankdb;

DELIMITER $$

-- Trigger: Auditar cambios en cuentas (UPDATE)
DROP TRIGGER IF EXISTS trg_accounts_audit_update$$
CREATE TRIGGER trg_accounts_audit_update
AFTER UPDATE ON accounts
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (table_name, operation, record_id, old_value, new_value)
    VALUES (
        'accounts',
        'UPDATE',
        NEW.id,
        JSON_OBJECT(
            'balance', OLD.balance,
            'status', OLD.status,
            'updated_at', OLD.updated_at
        ),
        JSON_OBJECT(
            'balance', NEW.balance,
            'status', NEW.status,
            'updated_at', NEW.updated_at
        )
    );
END$$

-- Trigger: Auditar inserciones en transacciones
DROP TRIGGER IF EXISTS trg_transactions_audit_insert$$
CREATE TRIGGER trg_transactions_audit_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (table_name, operation, record_id, new_value)
    VALUES (
        'transactions',
        'INSERT',
        NEW.id,
        JSON_OBJECT(
            'type', NEW.transaction_type,
            'from_account', NEW.from_account_id,
            'to_account', NEW.to_account_id,
            'amount', NEW.amount,
            'status', NEW.status
        )
    );
END$$

DELIMITER ;
