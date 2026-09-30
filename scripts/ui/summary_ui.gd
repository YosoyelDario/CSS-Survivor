extends CanvasLayer

signal primary_requested(action: String)
signal menu_requested

const UIFactory = preload("res://scripts/ui/ui_factory.gd")

var root: Control
var title_label: Label
var body: RichTextLabel
var primary_button: Button
var primary_action := ""

func _ready() -> void:
	layer = 21
	_build()

func show_level(level: int, correct: int, attempts: Array, points: int) -> void:
	root.visible = true
	title_label.text = "NIVEL %d COMPLETADO • PÁGINA REPARADA" % level
	var unique_wrong := {}
	for attempt in attempts:
		if not bool(attempt["siFueCorrectoNo"]):
			unique_wrong[int(attempt["pregunta_id"])] = attempt
	var text := "[b]KCR — Knowledge of Correct Response[/b]\n"
	text += "Aciertos: %d   •   Intentos: %d   •   Puntaje total: %d\n\n" % [correct, attempts.size(), points]
	if unique_wrong.is_empty():
		text += "[color=#64f0a5]¡Nivel perfecto! No hubo respuestas incorrectas.[/color]\n"
	else:
		text += "[b]Ejercicios que conviene repasar:[/b]\n"
		for key in unique_wrong.keys():
			var attempt = unique_wrong[key]
			text += "\n• #%d  %s\n  [color=#64f0a5]Correcta: %s[/color]\n" % [int(attempt["pregunta_id"]), str(attempt["pregunta"]), str(attempt["respuestaCorrecta"])]
	body.text = text
	if level < 3:
		primary_button.text = "SIGUIENTE NIVEL →"
		primary_action = "next_level"
	else:
		primary_button.text = "REALIZAR POST-TEST →"
		primary_action = "posttest"

func show_final(pre_score: int, post_score: int, total: int, points: int, log_path: String) -> void:
	root.visible = true
	title_label.text = "CSS SURVIVOR COMPLETADO"
	var delta := post_score - pre_score
	body.text = "[b]Sitio web restaurado al 100%[/b]\n\nPre-test: %d/%d\nPost-test: %d/%d\nCambio: %+d respuestas correctas\n\nPuntaje final del juego: %d\n\n[color=#64f0a5]Los resultados y cada intento quedaron registrados en el log local JSON.[/color]\n\nRuta del log:\n%s" % [pre_score, total, post_score, total, delta, points, log_path]
	primary_button.text = "VOLVER AL MENÚ"
	primary_action = "menu"

func hide_summary() -> void:
	root.visible = false

func _on_primary_pressed() -> void:
	primary_requested.emit(primary_action)

func _on_menu_pressed() -> void:
	menu_requested.emit()

func _build() -> void:
	root = Control.new()
	root.size = Vector2(1280, 720)
	root.visible = false
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.06, 0.88)
	dim.size = Vector2(1280, 720)
	root.add_child(dim)
	var card := UIFactory.panel(Rect2(180, 80, 920, 565), Color("0d1829"), Color("48dc91"))
	root.add_child(card)
	title_label = UIFactory.label("", Rect2(35, 25, 850, 45), 25, Color("69efa7"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title_label)
	body = RichTextLabel.new()
	body.bbcode_enabled = true
	body.position = Vector2(50, 90)
	body.size = Vector2(820, 365)
	body.add_theme_font_size_override("normal_font_size", 16)
	body.add_theme_color_override("default_color", Color("d8e5f3"))
	card.add_child(body)
	primary_button = UIFactory.button("SIGUIENTE NIVEL →", Rect2(530, 485, 340, 52), Color("38cf74"))
	primary_button.pressed.connect(_on_primary_pressed)
	card.add_child(primary_button)
	var menu_button := UIFactory.button("VOLVER AL MENÚ", Rect2(50, 485, 250, 52), Color("263a58"))
	menu_button.pressed.connect(_on_menu_pressed)
	card.add_child(menu_button)
