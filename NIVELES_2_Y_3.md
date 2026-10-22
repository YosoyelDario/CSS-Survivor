# Niveles 2 y 3: lógica implementada

Este documento describe cómo funcionan los Niveles 2 y 3 y cómo se mapea el diseño (documento de etapa de diseño y *Guía Visual de Propiedades CSS*) al código.

## Resumen

| | Nivel 1 | Nivel 2 | Nivel 3 |
|---|---|---|---|
| Nombre | Propiedades visuales básicas | Modelo de caja y formas | Posicionamiento y layout |
| Zonas | PERFIL, SEGURIDAD, DATOS, SOPORTE | TARJETAS, BOTONES, FORMULARIO, MENÚ | CABECERA, GALERÍA, COLUMNAS, PIE DE PÁGINA |
| Filas por zona | 3 / 4 / 4 / 4 | 3 / 4 / 4 / 4 | 3 / 4 / 4 / 4 |
| Ejercicios del banco | 30 (ids 1–30) | 30 (ids 31–60) | 30 (ids 61–90) |
| Tipos | teórico, práctico, completar, multi | ídem | ídem + enemigo final (`boss`) |
| Ataque (`attack_mode`) | `adjacent` | `adjacent` | `volley` |
| Layout de filas (`layout_mode`) | `lanes` | `lanes` | `flex` |
| Puntaje perfecto | 5250 | 5250 | 5700 (el `boss` vale 500) |

Las secuencias de tipos por zona están en `data/game_config.json` (`zone_sequences`). El Nivel 2 repite la secuencia del Nivel 1. El Nivel 3 termina la última zona con el enemigo final.

## Cómo se ve cada propiedad (capas de `enemy_view.gd`)

Cada propiedad controla una capa distinta, tal como define la Guía Visual:

| Propiedad | Efecto visual |
|---|---|
| `color` | color del texto "BUG" |
| `background-color` | aura detrás del enemigo |
| `border-color` | color del contorno |
| `opacity` | transparencia |
| `font-size` | tamaño del texto "BUG" |
| `border` | grosor y color del contorno |
| `border-radius` | forma: cuadrado, redondeado o círculo (`50%`) |
| `padding` | relleno interno: aparece un núcleo oscuro separado del borde |
| `margin` | caja naranja exterior y los vecinos se separan |
| `width` / `height` | tamaño del cuerpo |
| `transform: rotate(Ndeg)` | rotación del enemigo completo |
| `flex-direction`, `justify-content`, `align-items`, `align-content`, `gap` | no cambian al enemigo sino al **grupo** (ver abajo) |

En el Nivel 2 los enemigos parten con esquinas cuadradas y borde fino (`enemy_style` en la configuración del nivel) para que `border-radius` se note.

## Estado "con el bug"

Cada ejercicio puede definir cómo se ve la fila **antes** de responder, de modo que la respuesta correcta se vea como una reparación:

- `bug_effects`: efectos que se aplican a toda la fila al mostrar el ejercicio (por ejemplo un enemigo angosto antes de `width: 80px`, o el grupo en columna antes de `flex-direction: row`).
- `lane_bug_effects`: lo mismo, pero distinto por carril.

Si un ejercicio no los define, la fila parte limpia.

## Nivel 3: ataque dirigido y layout flex

En el Nivel 3 cada fila es un contenedor `display: flex`. Su estado por defecto es el de CSS: fila, `flex-start` y `gap: 0` (grupo pegado a la izquierda). Al acertar:

1. El grupo se reorganiza según las propiedades de layout de la respuesta (`flex_layout.gd`). `justify-content` lo mueve en el eje principal, `align-items` en el transversal, `flex-direction: column` lo apila, `align-content` lo parte en dos líneas y `gap` lo separa. Mientras el grupo está apilado o en dos líneas, las filas de atrás se atenúan.
2. El punto de impacto se desplaza con el grupo y sale un **disparo dirigido hacia cada enemigo** (en los Niveles 1 y 2, en cambio, un solo proyectil se divide hacia los vecinos).
3. Cada enemigo recibe sus efectos. Si el ejercicio define `lane_effects`, cada carril recibe los suyos (ejercicio 69: una propiedad distinta por enemigo).
4. La fila se elimina.

`flex_layout.gd` es lógica pura (sin nodos) y se prueba en `tests/model_smoke_test.gd`.

## Campos de un ejercicio (`data/questions.json`)

| Campo | Uso |
|---|---|
| `id`, `level`, `type`, `difficulty`, `question`, `answer` | del Anexo A del documento |
| `kind` | `teorico`, `practico`, `completar`, `multi` o `boss` |
| `options` | 4 alternativas; incluye la respuesta correcta |
| `hint`, `explanation` | pista tras un error y explicación del KCR |
| `main_property` | propiedad principal; la reposición tras un error la respeta |
| `effects` | efectos visuales de la respuesta correcta: `{"property": ..., "value": ...}` |
| `code` | solo en completar: código con el espacio `____` |
| `bug_effects`, `lane_bug_effects` | estado inicial con el bug (opcional) |
| `lane_effects` | efectos distintos por carril (opcional) |

## Vidas y retroalimentación

**Vida por racha.** Cada 5 aciertos seguidos se recupera 1 vida, sin pasar del máximo del nivel. Se configura por nivel en `game_config.json` (`life_recovery`: `streak` y `amount`). Un error reinicia la racha. Las vidas recuperadas suman al bono final de vidas, pero nunca superan el puntaje máximo del nivel. El log registra `rachaActual` y `vidaRecuperada` en cada respuesta.

**Diagnóstico del error** (`feedback_builder.gd`). Al fallar, el juego explica *por qué* falló la alternativa elegida, sin revelar la respuesta:

- Propiedad equivocada: "Elegiste border, que controla el grosor y el estilo del contorno. Aquí se necesita controlar la curvatura de las esquinas."
- Propiedad correcta con valor distinto: señala si hay que revisar el número, la unidad, la función (`rotate` frente a `skew`) o el estilo del borde.
- Falta o sobra una propiedad en las combinaciones.
- En las preguntas teóricas, cuyas alternativas son frases, se muestra la pista del ejercicio.

El diagnóstico se guarda en el historial y reaparece en el resumen final (KCR) junto con la explicación.

**Otros cambios de retroalimentación:**

- La alternativa elegida se marca en rojo (error) o verde (acierto) y las demás se atenúan. Al fallar no se señala la correcta.
- Tras un acierto se muestra la explicación como refuerzo, además de puntos, racha y vida recuperada.
- Los corazones se animan al ganar o perder una vida.
- El resumen muestra las vidas recuperadas y "A repasar", con las propiedades más falladas.
- Las alternativas largas se ajustan a la tarjeta (antes se cortaban al borde de la ventana).

## Insignias

Se definen en `game_config.json` con un `trigger`: `answer`, `streak`, `level_complete`, `level_perfect` o `all_levels`. Nuevas: Maestro de la Caja, Impecable II, Maestro del Layout, Impecable III y CSS Survivor (los tres niveles).

## Cambios respecto al Anexo A del documento

Para poder jugarlos se ajustaron los enunciados de tres ejercicios, sin cambiar sus respuestas:

| # | Antes | Ahora |
|---|---|---|
| 61 | Enemigo rotado 45° (marcado como Teórico) | ¿Qué declaración rota un elemento 45°? |
| 69 | 3 enemigos en fila frente, cada uno con un defecto distinto | … cada uno con un defecto distinto: texto pequeño, texto sin color y casi invisible |
| 90 | Grupo en columna, centrado y con separación de 20px | Grupo en columna, centrado en el eje principal y con separación de 20px |

Conviene actualizar esas tres filas en el Anexo A.

## No incluido

- Mini-jefe de la Guía Visual (enemigo cuyo requisito cambia con su posición). El enemigo final del Nivel 3 (#70 y #90) usa las mismas capas y solo combina dos o tres propiedades.
- Disparo a filas traseras en el Nivel 3 (`z-index`): el Anexo A no tiene ejercicios de esa propiedad.
- El arma no cambia de forma según la alternativa elegida y un error no lanza un proyectil fallido (el error se informa con texto, diagnóstico y la alternativa marcada).
- Diagnóstico específico en las preguntas teóricas: sus alternativas son frases y hoy muestran la pista del ejercicio.
