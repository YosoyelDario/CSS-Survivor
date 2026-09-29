extends Node2D
class_name Enemy
## Un enemigo/bug CSS (solo vista: las reglas viven en LevelRun).
##
## Capas visuales (los nombres los usa CssEngine, no cambiarlos):
##   Aura      <- background-color
##   Contorno  <- border-color
##   Cuerpo    <- color
##   Etiqueta  <- font-size (texto "BUG")
## MarcaObjetivo es solo un indicador de "este es el enemigo al que se ataca".
##
## Uso desde la arena (siempre DESPUÉS de add_child):
##   enemigo.colocar(carril, distancia)
##   enemigo.marcar_objetivo(true)
##   enemigo.aplicar_efecto(ejercicio["efecto_visual"])
##   enemigo.derrotar()

enum Distancia { LEJOS, MEDIO, FRENTE }

const X_POR_CARRIL := 150.0
const Y_POR_DISTANCIA := {
	Distancia.LEJOS: -160.0,
	Distancia.MEDIO: -80.0,
	Distancia.FRENTE: 0.0,
}

var distancia: int = Distancia.FRENTE
var carril: int = 1  # 0 = izquierda, 1 = centro, 2 = derecha
var derrotado: bool = false

@onready var marca_objetivo: Line2D = $MarcaObjetivo
@onready var etiqueta: Label = $Etiqueta


## Posición local (respecto a la fila de enemigos) de un carril y una distancia.
static func posicion_de(p_carril: int, p_distancia: int) -> Vector2:
	return Vector2((p_carril - 1) * X_POR_CARRIL, Y_POR_DISTANCIA[p_distancia])


func _ready() -> void:
	etiqueta.text = "BUG"
	marca_objetivo.visible = false
	_actualizar_posicion()


## Lo ubica en un carril y una distancia (sin animación).
func colocar(p_carril: int, p_distancia: int) -> void:
	carril = p_carril
	distancia = p_distancia
	_actualizar_posicion()


## Muestra u oculta la marca de objetivo. No usa modulate: CssEngine lo usa para opacity.
func marcar_objetivo(activo: bool) -> void:
	marca_objetivo.visible = activo and not derrotado


## Aplica el efecto visual de un ejercicio: {"color": "red", "font-size": "24px", ...}.
func aplicar_efecto(efectos: Dictionary) -> void:
	CssEngine.aplicar_diccionario(self, efectos)


## Lo da por derrotado DE INMEDIATO (no depende de queue_free, que es diferido) y lo retira.
func derrotar() -> void:
	derrotado = true
	marca_objetivo.visible = false
	hide()
	queue_free()


func _actualizar_posicion() -> void:
	position = posicion_de(carril, distancia)
