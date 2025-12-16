-- ============================================
-- DML - Data Manipulation Language
-- Inserción de datos de prueba
-- ============================================

USE bankdb;

-- Insertar clientes
INSERT INTO customers (first_name, last_name, email, phone) VALUES
('Elvin', 'Gonzalez', 'juan.perez@email.com', '555-0101'),
('Diego', 'Ordoñez', 'maria.lopez@email.com', '555-0102'),
('Jonh', 'Doe', 'carlos.garcia@email.com', '555-0103');

-- Insertar cuentas bancarias
INSERT INTO accounts (customer_id, account_number, account_type, balance, status) VALUES
(1, 'ACC-2024-001', 'CORRIENTE', 5000.00, 'ACTIVA'),
(1, 'ACC-2024-002', 'AHORROS', 15000.00, 'ACTIVA'),
(2, 'ACC-2024-003', 'CORRIENTE', 3500.00, 'ACTIVA'),
(2, 'ACC-2024-004', 'INVERSION', 25000.00, 'ACTIVA'),
(3, 'ACC-2024-005', 'CORRIENTE', 8000.00, 'ACTIVA');

-- Insertar algunas transacciones de ejemplo
INSERT INTO transactions (transaction_type, from_account_id, to_account_id, amount, status, description, completed_at) VALUES
('DEPOSITO', NULL, 1, 5000.00, 'COMPLETADA', 'Depósito inicial', NOW()),
('DEPOSITO', NULL, 2, 15000.00, 'COMPLETADA', 'Depósito inicial', NOW()),
('TRANSFERENCIA', 1, 3, 500.00, 'COMPLETADA', 'Transferencia a María', NOW()),
('RETIRO', 3, NULL, 200.00, 'COMPLETADA', 'Retiro en cajero', NOW());
