# Notas de implementación — entrega híbrida Nivel 1

## Decisiones aplicadas

- 4 zonas en orden libre.
- `zone_rows = [3, 4, 4, 4]`.
- 3 enemigos por fila; 3 filas visibles.
- `attack_mode = adjacent`: objetivo central + dos vecinos.
- Los enemigos avanzan solo al limpiar FRENTE.
- 5 vidas.
- Puntaje: teórico 100, completar 150, práctico 200, multi 300.
- +100 cada 3 aciertos, +250 por zona perfecta, +200 por vida al completar.
- Pre/post test conservado pero inactivo.

## Verificaciones realizadas en este entorno

- `questions.json`: 90 preguntas; Nivel 1 = 30; distribución 10 teóricas / 10 prácticas / 5 completar / 5 multi.
- Todas las preguntas de Nivel 1 tienen exactamente 4 opciones y la respuesta correcta aparece una sola vez.
- `game_config.json` válido y filas `[3,4,4,4]`.
- Comparación SHA-256 de `assets/`: ningún archivo de assets fue modificado.
- Se agregó `tests/model_smoke_test.gd` para ejecutar en Godot headless.

## Limitación del entorno de generación

En este entorno no está instalado el ejecutable de Godot, por lo que no fue posible ejecutar el editor/headless ni capturar pantallas reales. La prueba automática queda incluida para ejecutarla localmente con Godot 4.2+.

## Assets opcionales ausentes en la base recibida

El prompt menciona `assets/ui/` y `assets/fonts/`, pero la versión base disponible no los contenía. Para respetar la regla de no modificar `assets/`, la UI usa fallback: iconos pixel-art generados en memoria y la fuente predeterminada de Godot. Si posteriormente agregan los archivos esperados, `ui_factory.gd` los detecta automáticamente.
