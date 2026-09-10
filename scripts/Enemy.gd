extends Node2D
class_name Enemy
## Un enemigo/bug CSS. Ver Guia_Visual_Propiedades_CSS.md para el significado
## de cada capa visual (Cuerpo, Aura, Contorno, Etiqueta).

enum Distancia { LEJOS, MEDIO, FRENTE }

@export var propiedad_requerida: String = "color"
@export var valor_requerido: String = "red"
@export var hp: int = 1
@export var distancia: int = Distancia.FRENTE
@export var carril: int = 1  # 0 = izquierda, 1 = centro, 2 = derecha

const Y_POR_DISTANCIA := {
	Distancia.LEJOS: -160.0,
	Distancia.MEDIO: -80.0,
	Distancia.FRENTE: 0.0,
}

## Avanza una posicion de distancia. Devuelve true si ya estaba en FRENTE
## (es decir, alcanzo al jugador y deberia restarle una vida).
func avanzar() -> bool:
	if distancia == Distancia.FRENTE:
		return true
	distancia += 1
	_actualizar_posicion_visual()
	return false

func recibir_impacto() -> void:
	hp -= 1
	if hp <= 0:
		queue_free()

func _ready() -> void:
	_actualizar_posicion_visual()
	if has_node("Etiqueta"):
		get_node("Etiqueta").text = "BUG"

func _actualizar_posicion_visual() -> void:
	position.y = Y_POR_DISTANCIA[distancia]
