#!/bin/bash

# Script para ejecutar todos los scripts SQL en orden

echo "🗄️  Ejecutando scripts SQL en MySQL..."
echo ""

CONTAINER="acid-mysql"
PASSWORD="123456"

# Verificar que el contenedor esté corriendo
if ! podman ps | grep -q $CONTAINER; then
    echo "❌ Error: El contenedor $CONTAINER no está corriendo"
    echo "   Ejecuta: make up"
    exit 1
fi

echo "✅ Contenedor MySQL encontrado"
echo ""

# Ejecutar scripts en orden
echo "📝 1/5 - Ejecutando DDL (estructura de tablas)..."
podman exec -i $CONTAINER mysql -uroot -p$PASSWORD bankdb < 01_DDL_schema.sql
echo "✅ DDL completado"
echo ""

echo "📝 2/5 - Ejecutando DML (datos de prueba)..."
podman exec -i $CONTAINER mysql -uroot -p$PASSWORD bankdb < 02_DML_data.sql
echo "✅ DML completado"
echo ""

echo "📝 3/5 - Ejecutando DCL (usuarios y permisos)..."
podman exec -i $CONTAINER mysql -uroot -p$PASSWORD < 03_DCL_permissions.sql
echo "✅ DCL completado"
echo ""

echo "📝 4/5 - Ejecutando Stored Procedures..."
podman exec -i $CONTAINER mysql -uroot -p$PASSWORD bankdb < 04_stored_procedures.sql
echo "✅ Stored Procedures completados"
echo ""

echo "📝 5/5 - Ejecutando Triggers..."
podman exec -i $CONTAINER mysql -uroot -p$PASSWORD bankdb < 05_triggers.sql
echo "✅ Triggers completados"
echo ""

echo "🎉 ¡Todos los scripts ejecutados exitosamente!"
echo ""
echo "📊 Verificando datos..."
podman exec -i $CONTAINER mysql -uroot -p$PASSWORD bankdb -e "
SELECT 'Clientes:' as Info, COUNT(*) as Total FROM customers
UNION ALL
SELECT 'Cuentas:', COUNT(*) FROM accounts
UNION ALL
SELECT 'Transacciones:', COUNT(*) FROM transactions;
"
echo ""
echo "🔗 Conecta con DBeaver usando:"
echo "   Host: localhost"
echo "   Port: 3306"
echo "   Database: bankdb"
echo "   User: root"
echo "   Password: rootpassword"
