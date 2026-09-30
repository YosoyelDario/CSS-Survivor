extends CanvasLayer

signal retry_requested
signal menu_requested

const UIFactory = preload("res://scripts/ui/ui_factory.gd")

var root: Control

func _ready() -> void:
	layer = 22
	_build()

func show_game_over() -> void:
	root.visible = true

func hide_game_over() -> void:
	root.visible = false

func _on_retry_pressed() -> void:
	retry_requested.emit()

func _on_menu_pressed() -> void:
	menu_requested.emit()

func _build() -> void:
	root = Control.new()
	root.size = Vector2(1280, 720)
	root.visible = false
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.01, 0.03, 0.88)
	dim.size = Vector2(1280, 720)
	root.add_child(dim)
	var card := UIFactory.panel(Rect2(390, 210, 500, 300), Color("25101b"), Color("ff456d"))
	root.add_child(card)
	var title := UIFactory.label("SITIO COMPROMETIDO", Rect2(30, 35, 440, 45), 27, Color("ff6586"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title)
	var body := UIFactory.label("Te quedaste sin vidas. Puedes reintentar el nivel: las preguntas volverán a barajarse.", Rect2(45, 95, 410, 80), 17, Color("e9d7df"))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(body)
	var retry := UIFactory.button("↻ REINTENTAR NIVEL", Rect2(55, 205, 200, 50), Color("ff704a"))
	retry.pressed.connect(_on_retry_pressed)
	card.add_child(retry)
	var menu := UIFactory.button("MENÚ", Rect2(280, 205, 160, 50), Color("3a2f47"))
	menu.pressed.connect(_on_menu_pressed)
	card.add_child(menu)
