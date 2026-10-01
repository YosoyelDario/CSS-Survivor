extends CanvasLayer

signal answer_selected(answer: String)

const UIFactory = preload("res://scripts/ui/ui_factory.gd")

var root: Control
var title_label: Label
var progress_label: Label
var question_label: Label
var buttons: Array[Button] = []
var feedback_label: Label
var current_options: Array[String] = []

func _ready() -> void:
	layer = 23
	_build()

func show_question(mode: String, index: int, total: int, question: Dictionary, options: Array[String]) -> void:
	root.visible = true
	title_label.text = "PRE-TEST DE CONOCIMIENTOS" if mode == "pre" else "POST-TEST DE CONOCIMIENTOS"
	progress_label.text = "Pregunta %d/%d • OA%d" % [index + 1, total, int(question["level"])]
	question_label.text = str(question["question"])
	feedback_label.text = ""
	current_options = options.duplicate()
	for i in range(buttons.size()):
		buttons[i].disabled = false
		buttons[i].text = "%s  %s" % [String.chr(65 + i), current_options[i]]

func set_feedback(text_value: String, success: bool) -> void:
	feedback_label.text = text_value
	feedback_label.add_theme_color_override("font_color", Color("64f0a5") if success else Color("d8e5f3"))

func set_buttons_enabled(enabled: bool) -> void:
	for button in buttons:
		button.disabled = not enabled

func hide_evaluation() -> void:
	root.visible = false

func _on_answer_pressed(index: int) -> void:
	if index >= 0 and index < current_options.size():
		answer_selected.emit(current_options[index])

func _build() -> void:
	root = Control.new()
	root.size = Vector2(1280, 720)
	root.visible = false
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color("08111f")
	bg.size = Vector2(1280, 720)
	root.add_child(bg)
	var card := UIFactory.panel(Rect2(180, 90, 920, 550), Color("0d1829"), Color("9b6bff"))
	root.add_child(card)
	title_label = UIFactory.label("", Rect2(40, 28, 840, 42), 27, Color("c7a8ff"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title_label)
	progress_label = UIFactory.label("", Rect2(40, 76, 840, 28), 15, Color("8da8be"))
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(progress_label)
	question_label = UIFactory.label("", Rect2(55, 125, 810, 95), 22, Color("f4f8ff"))
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(question_label)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.position = Vector2(55, 235)
	grid.size = Vector2(810, 170)
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	card.add_child(grid)
	for i in range(4):
		var button := UIFactory.button("", Rect2(0, 0, 396, 72), Color("1c2e4a"))
		button.custom_minimum_size = Vector2(396, 72)
		button.pressed.connect(_on_answer_pressed.bind(i))
		grid.add_child(button)
		buttons.append(button)
	feedback_label = UIFactory.label("", Rect2(55, 445, 810, 40), 17, Color("d8e5f3"))
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(feedback_label)
	var note := UIFactory.label("El pre-test y el post-test usan exactamente el mismo conjunto de preguntas para poder comparar resultados.", Rect2(55, 492, 810, 35), 13, Color("8da8be"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(note)
