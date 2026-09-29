extends Control
## Pantalla de reglas. Los textos fijos viven en la escena; los que dependen de la
## configuración (vidas y puntos) se generan desde Config para que nunca queden desactualizados.

@onready var boton_volver: Button = %BotonVolver
@onready var texto_vidas: Label = %TextoVidas
@onready var texto_puntos: Label = %TextoPuntos


func _ready() -> void:
	boton_volver.pressed.connect(_volver)

	texto_vidas.text = "Empiezas cada intento con %d vidas. Cada error te quita 1 vida. Si llegas a 0 pierdes el intento, pero puedes reintentar el nivel." % Config.VIDAS_INICIALES

	var p: Dictionary = Config.PUNTOS_POR_TIPO
	texto_puntos.text = "Cada acierto suma: Teórico %d, Completar código %d, Práctico %d y Multi-objetivo %d.\nBonos: +%d por cada %d aciertos seguidos, +%d por una oleada sin errores y +%d por cada vida que te sobre al terminar el nivel.\nEquivocarte no resta puntos: solo pierdes una vida." % [
		p["teorico"], p["completar"], p["practico"], p["multi"],
		Config.BONO_RACHA, Config.ACERTOS_PARA_RACHA, Config.BONO_OLEADA_PERFECTA, Config.BONO_VIDA_RESTANTE]


## Con sesión vuelve al menú; sin sesión (no debería pasar) al registro.
func _volver() -> void:
	Navegacion.ir_a("menu" if SessionManager.hay_sesion() else "registro")
