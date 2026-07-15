#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Instalación de rclone ==="

if command -v rclone &>/dev/null; then
    echo "rclone ya está instalado:"
    rclone version
    echo ""
    read -p "¿Deseas actualizarlo? [y/N]: " update
    if [[ "$update" =~ ^[Yy]$ ]]; then
        sudo apt update && sudo apt install -y rclone
    fi
else
    echo "Instalando rclone vía apt..."
    sudo apt update && sudo apt install -y rclone
fi

echo ""
echo "Verificación:"
rclone version
echo ""
echo "rclone instalado correctamente."
echo ""
echo "Siguiente paso: ejecutar scripts/setup-b2.sh para configurar el remote de Backblaze B2."
