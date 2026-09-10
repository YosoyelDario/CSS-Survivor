extends Node2D
class_name Player

@export var vidas: int = 3
@export var puntaje: int = 0

## Actualiza el arma para reflejar la propiedad/valor elegido antes de disparar.
func actualizar_arma(propiedad: String, valor: String) -> void:
	CssEngine.aplicar(self, propiedad, valor)

func perder_vida() -> void:
	vidas -= 1
