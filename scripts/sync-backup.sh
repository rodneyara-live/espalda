#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${HOME}/.local/log"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/espalda-backup.log"

SOURCE="/home/rodneyr/BackBlaze"
REMOTE="b2remote"
BUCKET="espalda-backup"
DEST="${REMOTE}:${BUCKET}"

echo "$(date '+%Y-%m-%d %H:%M:%S') [INICIO] Backup espalda" >> "${LOG_FILE}"

if ! command -v rclone &>/dev/null; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] rclone no encontrado" >> "${LOG_FILE}"
    exit 1
fi

if [ ! -d "${SOURCE}" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] Directorio origen no existe: ${SOURCE}" >> "${LOG_FILE}"
    exit 1
fi

if ! rclone listremotes 2>/dev/null | grep -q "^${REMOTE}:$"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] Remote '${REMOTE}' no configurado" >> "${LOG_FILE}"
    exit 1
fi

rclone sync "${SOURCE}" "${DEST}" \
    --transfers=16 \
    --checkers=8 \
    --log-level=INFO \
    --log-file="${LOG_FILE}" \
    --stats=30s \
    --stats-log-level=INFO \
    --min-age=0s

EXIT_CODE=$?

if [ ${EXIT_CODE} -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [OK] Backup completado exitosamente" >> "${LOG_FILE}"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] rclone terminó con código ${EXIT_CODE}" >> "${LOG_FILE}"
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') [FIN] Backup espalda" >> "${LOG_FILE}"

exit ${EXIT_CODE}
