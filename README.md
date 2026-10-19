# CSS Survivor — Niveles 1, 2 y 3

Proyecto Godot 4.x organizado por módulos. Implementa los tres niveles con mapa explorable y combate en cuadrícula. Detalle de los Niveles 2 y 3 en `NIVELES_2_Y_3.md`.

| Nivel | Contenido | Propiedades | Ataque |
|---|---|---|---|
| 1 | Propiedades visuales básicas | color, background-color, border-color, opacity, font-size | área (objetivo + vecinos) |
| 2 | Modelo de caja y formas | border, border-radius, padding, margin, width, height | área (objetivo + vecinos) |
| 3 | Posicionamiento y layout | transform, flex-direction, justify-content, align-items, align-content, gap | dirigido: un disparo por enemigo |

## Flujo

1. Registro por correo / perfil local.
2. Menú principal.
3. Mapa explorable con 4 zonas por nivel (Nivel 1: PERFIL, SEGURIDAD, DATOS y SOPORTE; ver `game_config.json` para los otros niveles).
4. Al acercarse a un bug guardián: `E`, Espacio o Enter.
5. Combate con 3 filas visibles: LEJOS, MEDIO y FRENTE; 3 carriles.
6. Solo se ataca FRENTE. Un acierto limpia una fila: en los Niveles 1 y 2 el proyectil se divide hacia los vecinos; en el Nivel 3 sale un disparo hacia cada enemigo y el grupo se reorganiza según el layout CSS.
7. Si quedan filas, avanzan y entra una fila desde la cola.
8. Al fallar: -1 vida, pista y botón CONTINUAR; la reposición mantiene el tipo de pregunta.
9. Al limpiar las 4 zonas: resultados KCR y nivel completado (el siguiente nivel se desbloquea).

## Controles

- WASD / Flechas: mover.
- E / Espacio / Enter: interactuar y continuar tras un fallo.
- 1–4: elegir alternativa.
- ESC: pausa.

## Datos

- `data/questions.json`: 90 preguntas (30 por nivel) con opciones, pista, explicación, efectos visuales y propiedad principal.
- `data/game_config.json`: filas por zona, secuencias, puntajes, vidas, insignias y textos.
- Perfiles: `user://profiles/profiles.json`.
- Log: `user://css_survivor_log.jsonl` (una línea JSON por respuesta).

## Prueba automática de modelo

Con Godot instalado:

```bash
godot --headless --path . -s res://tests/model_smoke_test.gd
```

Valida los modos de ataque, el banco de 90 ejercicios, una partida perfecta de cada nivel (5250 / 5250 / 5700 pts), el layout flex y la configuración de insignias.

## Nota sobre assets

La carpeta `assets/` fue conservada sin cambios. Esta base no traía `assets/ui/` ni `assets/fonts/`; `ui_factory.gd` busca esos recursos si se agregan posteriormente y, mientras no existan, genera iconos pixel-art simples en memoria y usa la fuente predeterminada de Godot. No se escriben archivos nuevos dentro de `assets/`.
