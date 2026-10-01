# CSS Survivor — estructura modular

El proyecto fue reorganizado para que `main.gd` no concentre todo el programa.
En Godot puedes abrir cada archivo `.gd` como una pestaña independiente en el editor de scripts.

## scripts/main.gd
Solo coordina el flujo general:
- inicio del juego
- cambio de nivel
- combate
- pre/post test
- resumen y game over

## scripts/managers/
- `question_manager.gd`: carga `questions.json`, random sin repetición, distractores y set del pre/post test.
- `log_manager.gd`: guarda el JSON de interacción.
- `input_config.gd`: configura WASD, flechas, E, Espacio y Enter.

## scripts/world_controller.gd
Se encarga del mapa explorable:
- crea el mundo y jugador
- cámara que sigue al jugador
- genera los 4 BUGS
- detecta el BUG más cercano
- informa cuando una zona queda limpia

## scripts/ui/
- `menu_ui.gd`: menú principal y Cómo jugar.
- `hud_ui.gd`: vidas, puntos, nivel, zonas y barra de reparación.
- `combat_ui.gd`: pantalla de batalla, transición, botones y proyectil.
- `summary_ui.gd`: KCR y resultados finales.
- `gameover_ui.gd`: reintentar o volver al menú.
- `evaluation_ui.gd`: pre-test y post-test.
- `ui_factory.gd`: funciones comunes para crear paneles, labels y botones.

## scripts existentes
- `player.gd`: movimiento del personaje.
- `bug.gd`: HP y dibujo del virus.
- `web_world.gd`: dibujo del mapa/página infectada.
- `battle_arena.gd`: dibujo de la escena visual de combate.

## Dónde modificar cada cosa
- Preguntas: `data/questions.json`
- Movimiento: `scripts/player.gd`
- Diseño del mapa: `scripts/web_world.gd`
- Posiciones de BUGS/cámara: `scripts/world_controller.gd`
- Aspecto de combate: `scripts/battle_arena.gd` + `scripts/ui/combat_ui.gd`
- Menú: `scripts/ui/menu_ui.gd`
- HUD: `scripts/ui/hud_ui.gd`
- Lógica principal: `scripts/main.gd`

## Apariencia / assets
- `assets/player/hacker.png`: sprite del personaje.
- `assets/enemies/virus_1.png` a `virus_4.png`: sprites de enemigos.
- `assets/backgrounds/level*_infected.png`: versión dañada de cada página.
- `assets/backgrounds/level*_clean.png`: versión reparada de cada página.
- `assets/backgrounds/battle_web.png`: fondo de la pantalla de batalla.

Si se conservan esos nombres, se puede rediseñar todo el arte reemplazando PNG sin editar GDScript.
