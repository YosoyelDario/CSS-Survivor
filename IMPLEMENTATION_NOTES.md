# Notas de implementación

Estas decisiones se tomaron para convertir los documentos de diseño en un juego ejecutable:

1. **Exploración del mapa:** se implementó la idea acordada de recorrer libremente una página web con WASD/flechas, estilo RPG/Pokémon, en vez de mantener al personaje estático durante toda la experiencia.
2. **Cuatro esquinas:** cada nivel tiene cuatro zonas infectadas, una por esquina. Cada zona contiene un BUG guardián de 3 HP. Cada respuesta correcta quita 1 HP; al derrotarlo se considera reparada esa esquina. Al reparar las cuatro, la página queda limpia.
3. **Banco random:** las 30 preguntas del nivel se barajan. Una pregunta usada se retira temporalmente del pool; no vuelve a aparecer hasta que se agotan las 30 y se vuelve a barajar.
4. **Distractores:** el Anexo A define la pregunta y la respuesta esperada, pero no entrega cuatro alternativas para cada uno de los 90 ejercicios. Por eso el juego genera tres distractores dinámicamente, priorizando respuestas del mismo nivel, tipo y formato.
5. **KR / andamiaje / KCR:** al fallar no se revela la respuesta correcta de inmediato. Solo se informa el fallo (KR). Después de dos fallos contra el mismo BUG aparece una pista de categoría. La respuesta correcta de los ejercicios fallados se entrega en el resumen KCR al final del nivel.
6. **Pre/post test:** la propuesta de los documentos entrega preguntas de ejemplo, pero no un set completo de alternativas y claves. Para que el sistema sea ejecutable, al comenzar se seleccionan 3 preguntas teóricas de cada nivel (9 total) desde el banco ya documentado. Esas mismas 9 preguntas se repiten en el post-test de esa partida.
7. **Vidas:** se dejaron 5 vidas porque los mockups finales muestran 5 corazones. La ficha inicial hablaba de 3. Se puede cambiar en una línea (`MAX_LIVES` en `scripts/main.gd`).
8. **Datos:** cada intento guarda timestamp, jugador, nivel, zona, pregunta, alternativas, respuesta del jugador, respuesta correcta, resultado y tiempo de respuesta en un JSON local.

El proyecto no usa assets externos: personaje, BUGS, página y UI se dibujan con nodos y primitivas de Godot, para que sea fácil de abrir y modificar.
