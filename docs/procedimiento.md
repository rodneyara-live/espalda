# Procedimiento completo de backup a Backblaze B2

## 1. Crear cuenta y bucket en Backblaze B2

### 1.1 Crear cuenta
1. Ir a https://secure.backblaze.com/signup
2. Completar registro
3. Ir a B2 Cloud Storage > Buckets

### 1.2 Crear bucket
1. Click "Create a Bucket"
2. Nombre: `espalda-backup` (o el que prefieras)
3. File Lifecycle Settings: "Keep all versions"
4. Encryption: Default
5. Click "Create a Bucket"

### 1.3 Crear Application Key
1. Ir a App Keys (menú superior derecho)
2. Click "Add a New Application Key"
3. Name: `espalda-rclone`
4. Bucket: `espalda-backup` (acceso solo a este bucket)
5. Type of Access: "Read and Write"
6. Capabilities: Marcar solo las necesarias
7. Click "Create New Key"
8. **GUARDAR** el Application Key ID y la Key (solo se muestran una vez)

## 2. Instalar rclone

```bash
sudo apt update
sudo apt install -y rclone
rclone version
```

O usar el script:
```bash
./scripts/install-rclone.sh
```

## 3. Configurar rclone con Backblaze B2

### 3.1 Opción manual
```bash
rclone config
```
- Seleccionar "n" (New remote)
- Nombre: `b2remote`
- Storage: "Backblaze B2"
- Account: pegar Application Key ID
- Key: pegar Application Key
- Endpoint: (dejar vacío)
- Seleccionar bucket existente o crear uno
- "y" para confirmar

### 3.2 Opción con script
```bash
./scripts/setup-b2.sh
```

### 3.3 Verificar configuración
```bash
rclone listremotes
rclone lsd b2remote:espalda-backup
```

## 4. Upload inicial

```bash
./scripts/sync-backup.sh
```

O manualmente:
```bash
rclone sync /home/rodneyr/BackBlaze b2remote:espalda-backup \
    --transfers=16 \
    --checkers=8 \
    --progress \
    --fast-list
```

**Nota:** El upload inicial de ~100GB puede tardar varias horas dependiendo de tu conexión.

## 5. Configurar sync diario con systemd

### 5.1 Copiar archivos de servicio
```bash
sudo cp /home/rodneyr/Code-Projects/espalda/systemd/backup-espalda.service /etc/systemd/system/
sudo cp /home/rodneyr/Code-Projects/espalda/systemd/backup-espalda.timer /etc/systemd/system/
```

### 5.2 Recargar y habilitar
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now backup-espalda.timer
```

### 5.3 Verificar que el timer está activo
```bash
systemctl status backup-espalda.timer
systemctl list-timers | grep espalda
```

### 5.4 Probar manualmente
```bash
sudo systemctl start backup-espalda.service
journalctl -u backup-espalda.service -f
```

## 6. Verificar integridad

```bash
./scripts/verify-backup.sh
```

## 7. Monitoreo

### Ver logs
```bash
# Último run
journalctl -u backup-espalda.service --since today

# Todos los logs de hoy
journalctl -u backup-espalda.service --since today --no-pager

# Log del archivo
tail -f /var/log/espalda-backup.log
```

### Verificar archivos en B2
```bash
rclone ls b2remote:espalda-backup | wc -l
rclone size b2remote:espalda-backup
```

## 8. Restauración

### Restaurar todo
```bash
rclone sync b2remote:espalda-backup /home/rodneyr/BackBlaze-restore \
    --transfers=16 \
    --progress
```

### Restaurar archivo específico
```bash
rclone copy b2remote:espalda-backup/path/to/file /home/rodneyr/restore/
```

### Listar archivos disponibles
```bash
rclone ls b2remote:espalda-backup --max-age 7d
```

## 9. Mantenimiento

### Limpiar archivos eliminados localmente
El `rclone sync` ya elimina automáticamente de B2 los archivos que ya no existen en origen.

### Monitorear uso de B2
```bash
rclone about b2remote:
```

### Cambiar configuración del timer
Editar `/etc/systemd/system/backup-espalda.timer`:
```ini
[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=3600
```

Para ejecutar cada 12 horas:
```ini
OnCalendar=*-*-* 00,12:00:00
```

## 10. Troubleshooting

### El servicio no arranca
```bash
sudo systemctl status backup-espalda.service
journalctl -u backup-espalda.service -n 50
```

### Error de permisos en rclone.conf
```bash
chmod 600 ~/.config/rclone/rclone.conf
```

### El backup tarda demasiado
- Verificar conexión a internet
- Reducir `--transfers` si hay throttling
- Usar `--bwlimit` para limitar ancho de banda

### Error de red
El timer con `Persistent=true` reintentará al día siguiente. Verificar:
```bash
ping secure.backblaze.com
rclone lsd b2remote:espalda-backup
```
