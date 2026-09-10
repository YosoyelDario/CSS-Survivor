extends Control
class_name InputPanel
## Muestra chips (seleccion) o un LineEdit (texto libre) segun el modo del
## ejercicio activo. Ambos modos emiten la misma senal hacia BattleArena.

signal respuesta_enviada(propiedad: String, valor: String)

var modo: String = "seleccion"  # "seleccion" | "texto"
var propiedad_actual: String = ""

func mostrar_ejercicio(ejercicio: Dictionary) -> void:
	propiedad_actual = ejercicio.get("propiedad", "")
	modo = ejercicio.get("modo", "seleccion")
	for hijo in get_children():
		hijo.queue_free()
	if modo == "seleccion":
		_mostrar_chips(ejercicio)
	else:
		_mostrar_input_texto()

func _mostrar_chips(ejercicio: Dictionary) -> void:
	var contenedor := HBoxContainer.new()
	add_child(contenedor)
	for alt in ejercicio.get("alternativas", []):
		var boton := Button.new()
		boton.text = alt
		boton.pressed.connect(func(): _on_chip_elegido(alt))
		contenedor.add_child(boton)

func _mostrar_input_texto() -> void:
	var contenedor := HBoxContainer.new()
	add_child(contenedor)
	var campo := LineEdit.new()
	campo.placeholder_text = "propiedad: valor;"
	campo.custom_minimum_size = Vector2(240, 0)
	contenedor.add_child(campo)
	var boton := Button.new()
	boton.text = "Disparar"
	boton.pressed.connect(func(): _on_texto_enviado(campo.text))
	contenedor.add_child(boton)

func _on_chip_elegido(alt: String) -> void:
	var partes := Validator.extraer_propiedad_valor(alt)
	respuesta_enviada.emit(partes[0], partes[1])

func _on_texto_enviado(texto: String) -> void:
	var partes := Validator.extraer_propiedad_valor(texto)
	respuesta_enviada.emit(partes[0], partes[1])
