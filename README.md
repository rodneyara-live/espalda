# espalda - Backup a Backblaze B2 con rclone

Respaldo automatizado de `/home/rodneyr/BackBlaze` a Backblaze B2 usando rclone y systemd timers.

## Requisitos

- Ubuntu 24.04+ (systemd 259+)
- Cuenta en [Backblaze B2](https://www.backblaze.com/b2/cloud-storage.html)
- Application Key con permisos `b2:read-and-write`

## Inicio rápido

```bash
# 1. Instalar rclone
./scripts/install-rclone.sh

# 2. Configurar remote B2 (necesitas Application Key ID + Key)
./scripts/setup-b2.sh

# 3. Upload inicial (~<100GB)
./scripts/sync-backup.sh

# 4. Instalar systemd timer para sync diario
sudo cp systemd/backup-espalda.service /etc/systemd/system/
sudo cp systemd/backup-espalda.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now backup-espalda.timer

# 5. Verificar integridad
./scripts/verify-backup.sh
```

## Estructura

```
espalda/
├── scripts/
│   ├── install-rclone.sh        # Instala rclone via apt
│   ├── setup-b2.sh              # Configura remote B2 en rclone
│   ├── sync-backup.sh           # Script de sincronización
│   └── verify-backup.sh         # Verifica integridad del backup
├── systemd/
│   ├── backup-espalda.service   # Servicio systemd
│   └── backup-espalda.timer     # Timer diario
├── config/
│   └── rclone.conf.example      # Ejemplo de configuración
└── docs/
    └── procedimiento.md         # Guía detallada paso a paso
```

## Comandos útiles

```bash
# Ver estado del timer
systemctl status backup-espalda.timer

# Ver último log del backup
journalctl -u backup-espalda.service --since today

# Ejecutar backup manualmente
sudo systemctl start backup-espalda.service

# Verificar integridad
./scripts/verify-backup.sh

# Listar archivos en B2
rclone ls b2remote:espalda-backup
```

## Documentación

Ver [docs/procedimiento.md](docs/procedimiento.md) para la guía completa paso a paso.

## Seguridad

- `config/rclone.conf` contiene credenciales y está excluido del repo via `.gitignore`
- El timer usa `Nice=19` y `IOSchedulingClass=idle` para no afectar rendimiento del sistema
- Se recomienda crear una Application Key dedicada (no la master key)
