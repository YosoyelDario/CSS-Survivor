# Administración del ranking global

Esta versión agrega un modo administrador al Ranking Global.

## Acceso

1. Copia `server/CSS_Survivor_API.gs` a tu proyecto de Apps Script.
2. Guarda el script.
3. Ejecuta manualmente **una sola vez** la función `setupAdmin()`.
4. Revisa el registro de ejecución. Aparecerá una línea como:
   `Contraseña admin CSS Survivor: CSS-XXXXXXXXXXXXXX`
5. Guarda esa contraseña. No está incluida en Godot.
6. Ejecuta `setupSheets()` una vez para agregar las columnas `es_prueba` y `oculto_ranking` a la hoja Jugadores.
7. Actualiza la implementación de la Web App: Implementar > Gestionar implementaciones > Editar > Nueva versión > Implementar.

`setupAdmin()` puede ejecutarse de nuevo para volver a mostrar la misma contraseña guardada.

## Uso dentro del juego

Ranking > Global > ADMIN

La contraseña se envía por HTTPS al Apps Script. Si es correcta, Apps Script devuelve un token temporal de administrador que dura aproximadamente 30 minutos y se conserva solo en memoria.

### PRUEBA / HACER REAL
- `PRUEBA`: marca la cuenta como cuenta de desarrollo/prueba.
- Las cuentas de prueba NO aparecen en el ranking global.
- Las respuestas de esas cuentas NO se usan en las estadísticas agregadas de `Preguntas`.
- Sus datos crudos permanecen en `Intentos` y `Respuestas` para depuración.
- `HACER REAL`: vuelve a incluir la cuenta en ranking y estadísticas.

### OCULTAR / MOSTRAR
- Oculta o vuelve a mostrar al jugador en el ranking global.
- No cambia sus datos académicos ni sus respuestas.

### BORRAR
- Requiere pulsar `BORRAR` y luego `CONFIRMAR`.
- Elimina ese `id_jugador` de: Jugadores, Intentos, Respuestas y Ranking.
- Recalcula automáticamente la hoja Preguntas.
- Si ese jugador vuelve a jugar o sincronizar desde su computador, puede registrarse nuevamente.

## Recomendación para el equipo

Para las cuentas de desarrollo del equipo conviene usar **PRUEBA** en lugar de borrarlas constantemente. De esa manera pueden seguir probando sincronización sin contaminar el ranking ni las estadísticas finales.
