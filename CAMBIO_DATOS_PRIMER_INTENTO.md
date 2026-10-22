# Cambio de datos — primer intento válido

Esta versión conserva todos los resúmenes en `Intentos`, pero evita guardar respuestas detalladas repetidas para análisis.

## Regla

- Primer `completado` o `game_over` de un jugador en un nivel: se guarda en `Intentos` y sus respuestas se agregan a `Respuestas`.
- Repeticiones posteriores del mismo nivel: se guardan en `Intentos`, pero no vuelven a agregarse a `Respuestas`.
- `abandonado`: se guarda en `Intentos`, pero no cuenta como primer intento válido.
- `Ranking`: usa el mejor puntaje de cada nivel.
- `Preguntas`: se recalcula solo desde `Respuestas`.

No se modificó la lógica de niveles, preguntas, combate, audio, temporizadores ni puntajes.
