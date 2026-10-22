# Audio, temporizador y feedback de daño

Esta versión agrega estas funciones sin modificar las reglas de los niveles, sus preguntas ni sus mecánicas de ataque/layout.

## Tiempo por pregunta

Los tiempos están configurados en `data/game_config.json`:

- Nivel 1: 40 segundos (`urgent_time_seconds`: 10).
- Nivel 2: 30 segundos (`urgent_time_seconds`: 8).
- Nivel 3: 20 segundos (`urgent_time_seconds`: 6).

El reloj se reinicia al mostrar cada pregunta. Si llega a 0, la respuesta se registra como `SIN RESPUESTA`, se pierde una vida y se muestra feedback con pista. El reloj se pausa cuando se abre el menú de pausa con ESC.

## Audio

`scripts/managers/audio_manager.gd` controla música y efectos. La configuración se guarda en `user://audio_settings.json`.

El panel AUDIO, accesible desde el menú principal y desde PAUSA, permite ajustar:

- Volumen general.
- Música.
- Efectos.
- Silenciar todo.

La música acelera (`pitch_scale`) al entrar en el tramo urgente del temporizador.

Los archivos se encuentran en `assets/audio/`:

- `menu_music.wav`
- `game_music.wav`
- `shoot.wav`
- `correct.wav`
- `hit.wav`
- `timeout.wav`
- `tick.wav`

Pueden reemplazarse por otros WAV manteniendo los mismos nombres.

## Feedback por daño

Al fallar o agotar el tiempo:

- se pierde una vida mediante la lógica existente de `LevelRun`;
- se reproduce un sonido de golpe;
- el hacker recibe un tinte rojo semitransparente;
- se sacude horizontalmente;
- aparece un flash rojo breve sobre el área de combate.

El código visual está en `scripts/battle_arena.gd`, método `animate_player_damage()`.
