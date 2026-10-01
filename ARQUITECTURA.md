# Arquitectura

## Coordinación

- `scripts/main.gd`: flujo login → menú → mapa → combate → resultados; pausa y log.

## Managers / modelo

- `game_config.gd`: lectura de `data/game_config.json`.
- `session_manager.gd`: perfiles, progreso, exposición, insignias y ranking.
- `log_manager.gd`: JSON Lines del piloto.
- `question_manager.gd`: banco y alternativas.
- `level_run.gd`: reglas de intento, secuencias, reposición, vidas y puntaje.
- `zone_grid.gd`: modelo sin nodos de filas/carriles/cola/ataque adyacente.
- `input_config.gd`: controles.

## Mundo

- `player.gd`: movimiento del jugador.
- `web_world.gd`: fondo infectado/limpio y reparación por zona.
- `bug.gd`: guardián del mapa; muestra filas restantes.
- `world_controller.gd`: cámara, jugador, guardianes y sincronización del mapa.

## Combate

- `enemy_view.gd`: capas visuales de un enemigo y motor visual CSS provisional.
- `battle_arena.gd`: cuadrícula, objetivo/alcance, proyectil, animación y avance.
- `ui/combat_ui.gd`: pregunta, alternativas, pista, HUD de zona y CONTINUAR.

## Pantallas

- `login_ui.gd`: correo, alias y consentimiento.
- `menu_ui.gd`: menú principal.
- `levels_ui.gd`: selección de niveles.
- `achievements_ui.gd`: logros.
- `ranking_ui.gd`: ranking local por alias.
- `howto_ui.gd`: instrucciones.
- `hud_ui.gd`: HUD del mapa.
- `pause_ui.gd`: pausa.
- `results_ui.gd`: resultados y KCR.
- `evaluation_ui.gd`: conservado, inactivo.
- `ui_factory.gd`: tema, componentes e iconos.

`summary_ui.gd` y `gameover_ui.gd` permanecen como archivos heredados, pero ya no forman parte del flujo activo.
