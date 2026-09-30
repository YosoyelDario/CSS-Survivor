# CSS Survivor — Godot 4.2 — V2 mapa explorable + combate

Versión actualizada para acercarse a los mockups del proyecto.

## Qué cambió

- El sitio web ahora es un mapa grande de **2200×1400**.
- La cámara sigue al jugador, por lo que el escenario se desplaza como un RPG/Pokémon 2D.
- Los 4 BUGS están separados en cuatro sectores reales del mapa.
- Al acercarte a un BUG y presionar `E`, `ESPACIO` o `ENTER`, el personaje hace un pequeño salto de encuentro.
- Se reproduce una transición/flash y se abre una pantalla de batalla inspirada en los mockups: navegador, filas **LEJOS / MEDIO / FRENTE**, personaje abajo y tarjeta de preguntas.
- El combate permanece abierto hasta derrotar al BUG de la zona (3 HP).
- Cada respuesta correcta lanza un proyectil animado hacia el virus.
- Respuesta incorrecta: disparo falla, flash rojo y se pierde una vida.
- Después de derrotar al BUG vuelves al mapa y continúas recorriendo el sitio.
- Al limpiar las cuatro zonas se completa el nivel.
- Se mantienen las 90 preguntas, 30 por nivel, selección aleatoria sin repetición, KR/KCR, pistas, vidas, puntaje, pre/post test y log JSON.

## Abrir

1. Abre Godot 4.2.
2. Importa `project.godot`.
3. Ejecuta con `F6` o `F5`.

## Controles

- WASD o flechas: moverse.
- E / Espacio / Enter: entrar en combate cuando estás cerca de un BUG.
- Mouse: responder preguntas.

## Nota

El proyecto está realizado sin assets externos: los elementos visuales se dibujan por código para que el proyecto funcione inmediatamente y luego puedan reemplazarse por sprites definitivos.

## Versión modular
Esta copia divide el antiguo `main.gd` de más de 1000 líneas en scripts independientes. Revisa `ARQUITECTURA.md` para saber qué pestaña editar según lo que quieras cambiar.

## Assets externos (fácil de personalizar)

La apariencia visual principal ya no está dibujada directamente en los scripts.
Puedes reemplazar los PNG dentro de `assets/` manteniendo los mismos nombres:

- `assets/player/hacker.png`: jugador.
- `assets/enemies/virus_1.png` ... `virus_4.png`: monstruos de las cuatro zonas.
- `assets/backgrounds/level1_infected.png` / `level1_clean.png`: mapa nivel 1.
- `assets/backgrounds/level2_infected.png` / `level2_clean.png`: mapa nivel 2.
- `assets/backgrounds/level3_infected.png` / `level3_clean.png`: mapa nivel 3.
- `assets/backgrounds/battle_web.png`: página que aparece detrás de los virus en combate.

Los fondos del mapa están preparados para 2200x1400 px. Los sprites pueden ser PNG transparentes.
Godot reimportará automáticamente cualquier imagen que reemplaces.
