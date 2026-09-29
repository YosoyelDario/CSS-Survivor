extends Control
## Lista de niveles. El Nivel 1 es jugable (muestra mejor puntaje e insignias);
## los niveles 2 y 3 aparecen bloqueados ("Próximamente").

@onready var boton_volver: Button = %BotonVolver
@onready var boton_jugar_nivel1: Button = %BotonJugarNivel1
@onready var detalle_nivel1: Label = %Nivel1Detalle
@onready var insignias_nivel1: Label = %Nivel1Insignias


func _ready() -> void:
	if not SessionManager.hay_sesion():
		Navegacion.ir_a("registro")
		return

	boton_volver.pressed.connect(func() -> void: Navegacion.ir_a("menu"))
	boton_jugar_nivel1.pressed.connect(func() -> void: Navegacion.ir_a("nivel", {"nivel": 1}))
	_refrescar()
	boton_jugar_nivel1.grab_focus()


func _refrescar() -> void:
	var datos := SessionManager.datos_nivel(1)
	var estado := "Completado" if bool(datos.get("completado", false)) else "Sin completar"
	detalle_nivel1.text = "Mejor puntaje: %d   |   Intentos: %d   |   %s" % [
		int(datos.get("mejor_puntaje", 0)), int(datos.get("intentos", 0)), estado]

	var obtenidas: Array[String] = []
	for id in Config.INSIGNIAS_NIVEL_1.keys():
		if SessionManager.tiene_insignia(str(id)):
			obtenidas.append(str(Config.INSIGNIAS_NIVEL_1[id]["nombre"]))
	var total := Config.INSIGNIAS_NIVEL_1.size()
	if obtenidas.is_empty():
		insignias_nivel1.text = "Insignias: ninguna todavía (0 de %d)" % total
	else:
		insignias_nivel1.text = "Insignias: %s (%d de %d)" % [", ".join(obtenidas), obtenidas.size(), total]
