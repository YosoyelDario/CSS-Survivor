# CSS Survivor — Nivel 1 híbrido

Proyecto Godot 4.x organizado por módulos. Esta versión implementa el flujo jugable del Nivel 1 con mapa explorable y combate en cuadrícula.

## Flujo

1. Registro por correo / perfil local.
2. Menú principal.
3. Mapa explorable con 4 zonas: PERFIL, SEGURIDAD, DATOS y SOPORTE.
4. Al acercarse a un bug guardián: `E`, Espacio o Enter.
5. Combate con 3 filas visibles: LEJOS, MEDIO y FRENTE; 3 carriles.
6. Solo se ataca FRENTE. Un acierto afecta objetivo central + dos vecinos y limpia una fila.
7. Si quedan filas, avanzan y entra una fila desde la cola.
8. Al fallar: -1 vida, pista y botón CONTINUAR; la reposición mantiene el tipo de pregunta.
9. Al limpiar las 4 zonas: resultados KCR y Nivel 1 completado.

## Controles

- WASD / Flechas: mover.
- E / Espacio / Enter: interactuar y continuar tras un fallo.
- 1–4: elegir alternativa.
- ESC: pausa.

## Datos

- `data/questions.json`: 90 preguntas; el Nivel 1 (1–30) incluye opciones, pista, explicación, efectos y propiedad principal.
- `data/game_config.json`: filas por zona, secuencias, puntajes, vidas, insignias y textos.
- Perfiles: `user://profiles/profiles.json`.
- Log: `user://css_survivor_log.jsonl` (una línea JSON por respuesta).

## Prueba automática de modelo

Con Godot instalado:

```bash
godot --headless --path . -s res://tests/model_smoke_test.gd
```

Prueba una zona de cuadrícula, el ataque adyacente, avance de filas, 15 preguntas sin repetir y el puntaje perfecto esperado (5250 pts).

## Nota sobre assets

La carpeta `assets/` fue conservada sin cambios. Esta base no traía `assets/ui/` ni `assets/fonts/`; `ui_factory.gd` busca esos recursos si se agregan posteriormente y, mientras no existan, genera iconos pixel-art simples en memoria y usa la fuente predeterminada de Godot. No se escriben archivos nuevos dentro de `assets/`.
