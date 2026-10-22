# Opciones de pantalla

Se agregó configuración de pantalla persistente a CSS Survivor.

## Menú
El botón **AUDIO** fue reemplazado por **OPCIONES**. La ventana de opciones contiene:

- Volumen general, música, efectos y silencio.
- Modo **Ventana**.
- Modo **Pantalla completa**.
- Modo **Pantalla completa sin bordes**.
- **Resolución automática** para modo Ventana.
- Resoluciones manuales: 1280x720, 1366x768, 1600x900, 1920x1080 y 2560x1440.
- **VSync**.
- Botón **APLICAR PANTALLA**.

## Persistencia
Las opciones de pantalla se guardan en:

`user://display_settings.json`

Las preferencias vuelven a aplicarse automáticamente al iniciar el juego.

## Comportamiento
- En **Ventana**, la resolución puede ser automática o manual.
- En **Pantalla completa**, Godot usa la resolución del monitor.
- En **Sin bordes**, la ventana ocupa el monitor completo a resolución nativa.
- La interfaz conserva el viewport lógico del proyecto y usa el stretch `canvas_items`, por lo que el contenido se adapta al tamaño de ventana.
