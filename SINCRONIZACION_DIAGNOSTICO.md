# Sincronización - corrección y diagnóstico

Versión esperada de la API: `2026-10-22-sync3`.

- Los paquetes inválidos ya no bloquean toda la cola del computador.
- `pending_uploads.json` conserva fallos reales de red.
- `failed_uploads.json` conserva paquetes rechazados para diagnóstico.
- Godot imprime líneas `[SYNC]` con el código HTTP y la respuesta de Google.
- `?action=status` permite confirmar qué versión de Apps Script está desplegada.
