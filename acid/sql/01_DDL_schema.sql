-- ============================================
-- DDL - Data Definition Language
-- Estructura de base de datos
-- ============================================

USE bankdb;

-- Tabla de clientes
CREATE TABLE IF NOT EXISTS customers (
    customer_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla de cuentas bancarias
CREATE TABLE IF NOT EXISTS accounts (
    account_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    account_type ENUM('CORRIENTE', 'AHORROS', 'INVERSION') NOT NULL,
    balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    status ENUM('ACTIVA', 'INACTIVA', 'CONGELADA') DEFAULT 'ACTIVA',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_customer (customer_id),
    INDEX idx_account_number (account_number),
    CONSTRAINT chk_balance CHECK (balance >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla de transacciones
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    transaction_type ENUM('DEPOSITO', 'RETIRO', 'TRANSFERENCIA') NOT NULL,
    from_account_id BIGINT,
    to_account_id BIGINT,
    amount DECIMAL(15,2) NOT NULL,
    status ENUM('PENDIENTE', 'COMPLETADA', 'FALLIDA', 'REVERTIDA') DEFAULT 'PENDIENTE',
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    FOREIGN KEY (from_account_id) REFERENCES accounts(account_id),
    FOREIGN KEY (to_account_id) REFERENCES accounts(account_id),
    INDEX idx_from_account (from_account_id),
    INDEX idx_to_account (to_account_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
