-- ============================================
-- DCL - Data Control Language
-- Gestión de usuarios y permisos
-- ============================================

-- Crear usuario de aplicación (solo lectura/escritura en tablas específicas)
CREATE USER IF NOT EXISTS 'bank_app'@'%' IDENTIFIED BY 'app_password_123';

-- Permisos para la aplicación
GRANT SELECT, INSERT, UPDATE ON bankdb.customers TO 'bank_app'@'%';
GRANT SELECT, INSERT, UPDATE ON bankdb.accounts TO 'bank_app'@'%';
GRANT SELECT, INSERT, UPDATE ON bankdb.transactions TO 'bank_app'@'%';
-- GRANT SELECT, INSERT ON bankdb.audit_logs TO 'bank_app'@'%';

-- Permisos para ejecutar stored procedures
GRANT EXECUTE ON PROCEDURE bankdb.sp_create_customer TO 'bank_app'@'%';
GRANT EXECUTE ON PROCEDURE bankdb.sp_create_account TO 'bank_app'@'%';
GRANT EXECUTE ON PROCEDURE bankdb.sp_transfer_funds TO 'bank_app'@'%';
GRANT EXECUTE ON PROCEDURE bankdb.sp_get_customer TO 'bank_app'@'%';
GRANT EXECUTE ON PROCEDURE bankdb.sp_update_customer TO 'bank_app'@'%';
GRANT EXECUTE ON PROCEDURE bankdb.sp_deposit TO 'bank_app'@'%';
GRANT EXECUTE ON PROCEDURE bankdb.sp_withdrawal TO 'bank_app'@'%';

-- Crear usuario de solo lectura (para reportes)
CREATE USER IF NOT EXISTS 'bank_readonly'@'%' IDENTIFIED BY 'readonly_password_123';

-- Permisos de solo lectura
GRANT SELECT ON bankdb.* TO 'bank_readonly'@'%';

-- Crear usuario administrador
CREATE USER IF NOT EXISTS 'bank_admin'@'%' IDENTIFIED BY 'admin_password_123';

-- Permisos completos para admin
GRANT ALL PRIVILEGES ON bankdb.* TO 'bank_admin'@'%';

-- Aplicar cambios
FLUSH PRIVILEGES;

-- Mostrar usuarios creados
SELECT user, host FROM mysql.user WHERE user LIKE 'bank_%';
