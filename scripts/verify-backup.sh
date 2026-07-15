#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SOURCE="/home/rodneyr/BackBlaze"
REMOTE="b2remote"
BUCKET="espalda-backup"
DEST="${REMOTE}:${BUCKET}"

echo "=== Verificación de backup espalda ==="
echo "Fecha: $(date)"
echo ""

if ! command -v rclone &>/dev/null; then
    echo "ERROR: rclone no encontrado"
    exit 1
fi

echo "Comparando origen y destino..."
echo "  Origen:  ${SOURCE}"
echo "  Destino: ${DEST}"
echo ""

rclone check "${SOURCE}" "${DEST}" \
    --one-way \
    --transfers=8 \
    --checkers=8 \
    --fast-list

EXIT_CODE=$?

echo ""
if [ ${EXIT_CODE} -eq 0 ]; then
    echo "Backup verificado: origen y destino coinciden."
else
    echo "Diferencias encontradas. Ejecuta sync-backup.sh para sincronizar."
fi

exit ${EXIT_CODE}
