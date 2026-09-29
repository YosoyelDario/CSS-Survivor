extends Control
class_name InputPanel

signal opcion_elegida(indice: int)

var lbl_enunciado: Label
var contenedor_botones: GridContainer # Cambiamos VBox a Grid

func _ready() -> void:
	# Contenedor principal que ordena el texto arriba y los botones abajo
	var layout_principal = VBoxContainer.new()
	layout_principal.set_anchors_preset(PRESET_FULL_RECT)
	layout_principal.add_theme_constant_override("separation", 20)
	add_child(layout_principal)
	
	lbl_enunciado = Label.new()
	lbl_enunciado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_enunciado.custom_minimum_size = Vector2(800, 60)
	lbl_enunciado.add_theme_font_size_override("font_size", 20)
	layout_principal.add_child(lbl_enunciado)
	
	# Usamos un GridContainer de 2 columnas para el formato 2x2 de los mockups
	contenedor_botones = GridContainer.new()
	contenedor_botones.columns = 2
	contenedor_botones.add_theme_constant_override("h_separation", 20)
	contenedor_botones.add_theme_constant_override("v_separation", 15)
	layout_principal.add_child(contenedor_botones)

func mostrar_ejercicio(pregunta_completa: Dictionary) -> void:
	for hijo in contenedor_botones.get_children():
		hijo.queue_free()
		
	var ej: Dictionary = pregunta_completa.get("ejercicio", {})
	var opciones: Array = pregunta_completa.get("opciones", [])
	var tipo: String = ej.get("tipo", "teorico")
	
	var texto_pantalla := "[%s] %s" % [tipo.to_upper(), ej.get("enunciado", "")]
	if tipo == "completar" and ej.has("codigo"):
		texto_pantalla += "\n\n" + str(ej.get("codigo", ""))
		
	lbl_enunciado.text = texto_pantalla
	
	for i in range(opciones.size()):
		var boton := Button.new()
		boton.text = str(opciones[i])
		# Tamaño más parecido a las tarjetas de los mockups
		boton.custom_minimum_size = Vector2(380, 60) 
		boton.pressed.connect(func(): _on_boton_presionado(i))
		contenedor_botones.add_child(boton)

func _on_boton_presionado(indice: int) -> void:
	for boton in contenedor_botones.get_children():
		if boton is Button:
			boton.disabled = true
	opcion_elegida.emit(indice)