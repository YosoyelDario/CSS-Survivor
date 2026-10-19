# Prueba de modelo

Con Godot 4.2+ instalado, desde la raíz del proyecto:

```bash
godot --headless --path . -s res://tests/model_smoke_test.gd
```

Valida:

- Cuadrícula en modo `adjacent` y `volley`, objetivo central + vecinos y avance de filas.
- Banco de 90 ejercicios: 4 alternativas, respuesta entre ellas, pista, explicación, `code` en los de completar y solo propiedades con soporte visual.
- Una partida perfecta de cada nivel: 15 preguntas sin repetir, secuencias por zona, enemigo final en el Nivel 3 y puntaje esperado (5250 / 5250 / 5700).
- Reposición tras un error (misma categoría de pregunta).
- Layout flex del Nivel 3: posiciones por `justify-content`, `align-items`, `flex-direction`, `align-content` y `gap`, siempre dentro de la arena.
- Configuración de insignias (triggers válidos y una de completar/impecable por nivel).
