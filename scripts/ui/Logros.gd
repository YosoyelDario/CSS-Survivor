extends Control
## Pantalla de Logros: las insignias del juego con su estado (obtenida / bloqueada) y fecha.

@onready var boton_volver: Button = %BotonVolver
@onready var resumen: Label = %Resumen
@onready var lista: VBoxContainer = %ListaLogros


func _ready() -> void:
	if not SessionManager.hay_sesion():
		Navegacion.ir_a("registro")
		return

	boton_volver.pressed.connect(func() -> void: Navegacion.ir_a("menu"))
	_construir_lista()


func _construir_lista() -> void:
	var obtenidas := 0
	for id in Config.INSIGNIAS_NIVEL_1.keys():
		var info: Dictionary = Config.INSIGNIAS_NIVEL_1[id]
		var fecha := _fecha_de(str(id))
		var tiene := fecha != ""
		if tiene:
			obtenidas += 1
		lista.add_child(_crear_fila(str(info["nombre"]), str(info["desc"]), tiene, fecha))
	resumen.text = "Insignias obtenidas: %d de %d" % [obtenidas, Config.INSIGNIAS_NIVEL_1.size()]


## Fecha (solo el día) en que se obtuvo la insignia; "" si aún no la tiene.
func _fecha_de(id_insignia: String) -> String:
	for ins in SessionManager.jugador_actual.get("insignias", []):
		if str(ins["id"]) == id_insignia:
			return str(ins.get("fecha", "")).split("T")[0]
	return ""


func _crear_fila(nombre: String, descripcion: String, obtenida: bool, fecha: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var margen := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 12)
	panel.add_child(margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	margen.add_child(fila)

	var estado := Label.new()
	estado.text = "OBTENIDA" if obtenida else "BLOQUEADA"
	estado.custom_minimum_size = Vector2(110, 0)
	fila.add_child(estado)

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(textos)

	var etiqueta_nombre := Label.new()
	etiqueta_nombre.text = nombre
	textos.add_child(etiqueta_nombre)

	var etiqueta_desc := Label.new()
	etiqueta_desc.text = descripcion
	etiqueta_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(etiqueta_desc)

	var etiqueta_fecha := Label.new()
	etiqueta_fecha.text = fecha if obtenida else "-"
	fila.add_child(etiqueta_fecha)

	if not obtenida:
		panel.modulate = Color(1, 1, 1, 0.55)
	return panel
