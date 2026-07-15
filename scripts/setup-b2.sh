#!/usr/bin/env bash
set -euo pipefail

RCLONE_CONF="${HOME}/.config/rclone/rclone.conf"
REMOTE_NAME="b2remote"

echo "=== Configuración de Backblaze B2 en rclone ==="
echo ""

if ! command -v rclone &>/dev/null; then
    echo "ERROR: rclone no está instalado. Ejecuta primero scripts/install-rclone.sh"
    exit 1
fi

if rclone listremotes 2>/dev/null | grep -q "^${REMOTE_NAME}:$"; then
    echo "El remote '${REMOTE_NAME}' ya existe."
    read -p "¿Deseas reconfigurarlo? [y/N]: " reconfigure
    if [[ ! "$reconfigure" =~ ^[Yy]$ ]]; then
        echo "Cancelado."
        exit 0
    fi
fi

echo "Necesitas tu Application Key ID y Application Key de Backblaze B2."
echo "Creamos en https://secure.backblaze.com/b2_buckets.htm"
echo ""

read -p "Application Key ID: " key_id
read -s -p "Application Key: " key_secret
echo ""

read -p "Nombre del bucket (default: espalda-backup): " bucket_name
bucket_name="${bucket_name:-espalda-backup}"

echo ""
echo "Creando remote '${REMOTE_NAME}' apuntando a b2:${bucket_name}..."

rclone config create "${REMOTE_NAME}" b2 \
    account="${key_id}" \
    key="${key_secret}"

echo ""
echo "Remote configurado:"
rclone listremotes
echo ""
echo "Verificando conexión..."
if rclone lsd "${REMOTE_NAME}:${bucket_name}" &>/dev/null; then
    echo "Conexión exitosa. Bucket '${bucket_name}' accesible."
elif rclone mkdir "${REMOTE_NAME}:${bucket_name}"; then
    echo "Bucket '${bucket_name}' creado y accesible."
else
    echo "ERROR: No se pudo acceder al bucket. Verifica tus credenciales."
    exit 1
fi

echo ""
echo "Configuración completada."
echo "Siguiente paso: ejecutar scripts/sync-backup.sh para el upload inicial."
