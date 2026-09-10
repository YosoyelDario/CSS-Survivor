# CSS-Survivor
Juego desarrollado para la asignatura de Sistemas educativos inteligentes.
















# CSS Survivor — Base del proyecto (Godot 4)

Base inicial jugable del juego educativo de CSS para OII-433. Implementa el ciclo
principal (mostrar ejercicio → responder → validar → aplicar efecto visual →
log), usando la arquitectura definida en las notas de diseño del equipo.

## Cómo abrir

1. Abre Godot 4.3+ → "Import" → selecciona `project.godot` de esta carpeta.
2. Presiona F5 (o el botón Play) sobre la escena `scenes/Main.tscn`.
3. Aparecen 3 enemigos en la fila frente; al resolver correctamente el ejercicio
   mostrado abajo, ese enemigo muere y llega una oleada nueva. Si fallas,
   pierdes una vida (ver el HUD arriba).

## Estructura

```
project.godot          Config del proyecto + autoloads registrados
scripts/
  autoload/
    CssEngine.gd        Traduce propiedad/valor -> efecto visual real
    Validator.gd        Normaliza y compara la respuesta del jugador
    LogManager.gd        Escribe el log (user://logs/log.jsonl)
    TurnManager.gd        Máquina de estados del ciclo de turno
  Enemy.gd                Lógica del enemigo (distancia, hp, propiedad exigida)
  Player.gd                Vidas, puntaje, actualización del arma
  BattleArena.gd            Script raíz de Main.tscn, conecta todo
  ui/InputPanel.gd          Chips o LineEdit según el modo del ejercicio
scenes/
  Main.tscn                 Escena jugable
  Enemy.tscn                 Enemigo reutilizable (Cuerpo + Etiqueta)
data/
  ejercicios_nivel{1,2,3}.json   Banco de ejercicios (ver Anexo A del informe)
```

## Qué SÍ está implementado

- Ciclo completo: mostrar ejercicio → jugador responde (chips o texto) →
  `Validator` compara → si acierta, `CssEngine` aplica el efecto visual real
  y el enemigo muere; si falla, se pierde una vida.
- Log de cada intento en `user://logs/log.jsonl`, con los 7 campos que exige
  el enunciado del curso.
- Propiedades de Nivel 1 y Nivel 2 (color, background-color, border-color,
  opacity, font-size, width, height) y `transform: rotate()` de Nivel 3.

## Qué falta (a propósito, para no sobre-prometer)

Esto es una **base**, no el juego terminado. Pendiente, en orden sugerido:

1. **Avance por turnos real** (lejos → medio → frente). Ahora mismo los
   enemigos nacen directo en la fila frente — `TurnManager.Estado.AVANCE_ENEMIGOS`
   existe pero todavía no mueve nada. Ver `BattleArena._spawn_oleada()` (TODO marcado).
2. **Capas visuales que faltan en el arte**: `Aura` (background-color) y
   `Contorno` (border-color) no existen todavía en `Enemy.tscn` — el código
   ya las busca (`CssEngine._aplicar_background_color`, etc.) pero no hacen
   nada hasta que se agreguen esos nodos hijos. Ver Guia_Visual_Propiedades_CSS.md.
3. **Propiedades de layout** (`flex-direction`, `justify-content`,
   `align-items`, `gap`, `margin`, `padding`) — todavía no tienen aplicador en
   `CssEngine`. `border-radius` está mapeado pero sin efecto real (ColorRect
   no soporta esquinas redondeadas; hay que migrar `Cuerpo` a un `Panel` con
   `StyleBoxFlat`).
4. **Mini-jefe** (enemigo cuyo requisito cambia según distancia/carril) — no
   implementado aún, es la siguiente pieza de diseño conversada con el equipo.
5. **Identificación real de jugador** (ahora `id_jugador` es un string fijo
   de prueba) y **pantallas de menú, resultado (KCR), pre/post test** — no
   existen como escenas todavía, solo la pantalla de batalla.
6. **Gamificación** (insignias, ranking) y **narrativa** (reparación visual
   del sitio) — diseñadas en las notas, no implementadas en código aún.

## Convenciones de nombres

Variables y funciones en español (`propiedad_requerida`, `resolver_respuesta`),
consistente con el resto de la documentación del proyecto (informe, notas,
guía visual), para que cualquiera del equipo pueda leer el código sin
traducir mentalmente.
