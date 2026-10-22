# CSS Survivor — Ranking global y datos de investigación

## Qué hace esta versión

- Mantiene el ranking local existente.
- Agrega una vista GLOBAL que no se conecta automáticamente: el usuario debe pulsar `GLOBAL` y luego `CONECTAR`.
- Registra respuestas detalladas para análisis solo en el primer intento válido de cada jugador por nivel. Un intento válido es `completado` o `game_over`; `abandonado` queda en historial pero no consume ese primer intento.
- Al terminar, perder o abandonar un intento, el paquete se guarda primero en `user://pending_uploads.json`.
- Después intenta subirlo a Google Sheets. Si falla Internet, el paquete permanece local para reintentar en el próximo intento o al conectar el ranking global.
- El ranking global consulta solo el Top 10.

## URL configurada

La aplicación usa la Web App entregada para el proyecto:

`https://script.google.com/macros/s/AKfycbzL5GKEfsljb1Nc6wbu5YytI-pOjWQrEm8fo17zG2Tyw35f1zoSKLYMZLLtI963cgBs/exec`

Está definida en `scripts/managers/online_manager.gd`.

## Paso necesario en Google Apps Script

El archivo `server/CSS_Survivor_API.gs` contiene la versión recomendada del servidor.

Esta versión mejora el script inicial en tres puntos importantes:

1. evita duplicar un intento si una sincronización se reintenta;
2. el ranking suma el MEJOR puntaje de cada nivel, en vez de sumar infinitamente cada repetición;
3. `Respuestas` y `Preguntas` usan solo el primer intento válido de cada jugador por nivel, evitando que un alumno que repita muchas veces distorsione el análisis.

Para actualizarlo:

1. Abre `CSS Survivor - Base de Datos`.
2. `Extensiones > Apps Script`.
3. Reemplaza el contenido de `Code.gs` por el contenido de `server/CSS_Survivor_API.gs`.
4. Guarda.
5. `Implementar > Gestionar implementaciones`.
6. Edita la implementación activa (lápiz).
7. Selecciona `Nueva versión` y pulsa `Implementar`.
8. Mantén `Ejecutar como: Yo` y `Quién tiene acceso: Cualquier usuario`.

La URL `/exec` puede mantenerse igual al actualizar la implementación existente.

## Hojas de datos

- `Jugadores`: identidad privada y alias.
- `Intentos`: resumen de TODAS las ejecuciones, incluidas repeticiones y abandonos.
- `Respuestas`: respuestas detalladas solo del primer intento válido de cada jugador en cada nivel.
- `Ranking`: mejor puntaje de cada nivel por jugador.
- `Preguntas`: agregados calculados desde `Respuestas`, por lo que cada jugador aporta como máximo un primer intento válido por nivel.

El correo nunca se devuelve en el endpoint público de ranking: el juego global muestra alias, puntaje, nivel e insignias.
