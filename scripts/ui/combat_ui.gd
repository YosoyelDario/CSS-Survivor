extends CanvasLayer

signal answer_selected(answer: String)

const UIFactory = preload("res://scripts/ui/ui_factory.gd")
const BattleArenaScript = preload("res://scripts/battle_arena.gd")

var root: Control
var title_label: Label
var meta_label: Label
var question_label: Label
var buttons: Array[Button] = []
var feedback_label: Label
var hint_label: Label
var arena
var card: Panel
var encounter_flash: ColorRect
var current_options: Array[String] = []

func _ready() -> void:
	layer = 20
	_build()

func show_question(question: Dictionary, options: Array[String], zone_number: int, hp: int, max_hp: int, hint_text: String = "") -> void:
	title_label.text = "⚠ BUG DE ZONA %d  •  HP %d/%d" % [zone_number, hp, max_hp]
	meta_label.text = "Pregunta #%d  •  %s  •  %s" % [int(question["id"]), str(question["type"]), str(question["difficulty"])]
	question_label.text = str(question["question"])
	feedback_label.text = ""
	set_hint(hint_text)
	current_options = options.duplicate()
	for i in range(buttons.size()):
		buttons[i].disabled = false
		buttons[i].text = "%s  %s" % [String.chr(65 + i), current_options[i]]

func set_battle_state(level: int, hp: int, max_hp: int, active: bool, zone_index: int = 0) -> void:
	arena.set_battle_state(level, hp, max_hp, active, zone_index)

func set_buttons_enabled(enabled: bool) -> void:
	for button in buttons:
		button.disabled = not enabled

func set_feedback(text_value: String, success: bool) -> void:
	feedback_label.text = text_value
	feedback_label.add_theme_color_override("font_color", Color("64f0a5") if success else Color("ff718f"))

func set_hint(text_value: String) -> void:
	hint_label.text = text_value
	hint_label.visible = not text_value.is_empty()

func get_option_texts() -> Array[String]:
	return current_options.duplicate()

func hide_immediate() -> void:
	root.visible = false
	root.modulate = Color.WHITE

func animate_encounter(player: Node2D, bug: Node2D) -> void:
	var origin: Vector2 = player.global_position
	var direction: Vector2 = (bug.global_position - origin).normalized()
	var jump_target: Vector2 = origin + direction * 56.0 + Vector2(0, -26)
	var jump := create_tween()
	jump.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump.tween_property(player, "global_position", jump_target, 0.12)
	jump.set_ease(Tween.EASE_IN)
	jump.tween_property(player, "global_position", origin, 0.11)
	await jump.finished

	root.visible = true
	root.modulate = Color(1, 1, 1, 0)
	encounter_flash.visible = true
	encounter_flash.modulate = Color(1, 1, 1, 0)
	var intro := create_tween()
	intro.set_parallel(true)
	intro.tween_property(root, "modulate:a", 1.0, 0.20)
	intro.tween_property(card, "position:y", 455.0, 0.24).from(535.0)
	intro.tween_property(encounter_flash, "modulate:a", 0.75, 0.08)
	await intro.finished
	var flash_out := create_tween()
	flash_out.tween_property(encounter_flash, "modulate:a", 0.0, 0.13)
	await flash_out.finished
	encounter_flash.visible = false

func close_to_map() -> void:
	var out := create_tween()
	out.tween_property(root, "modulate:a", 0.0, 0.16)
	await out.finished
	hide_immediate()

func animate_projectile(success: bool) -> void:
	var shot := Polygon2D.new()
	shot.polygon = PackedVector2Array([Vector2(-9, 0), Vector2(0, -9), Vector2(9, 0), Vector2(0, 9)])
	shot.color = Color("54f5ff") if success else Color("ff496f")
	shot.z_index = 50
	shot.position = arena.player_screen_position() + Vector2(27, -24)
	root.add_child(shot)
	var target: Vector2 = arena.target_screen_position()
	if not success:
		target += Vector2(105, -55)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(shot, "position", target, 0.34)
	tween.tween_property(shot, "rotation", TAU, 0.34)
	tween.tween_property(shot, "scale", Vector2(1.7, 1.7), 0.34)
	await tween.finished
	shot.queue_free()

func flash_hit(success: bool) -> void:
	await arena.flash_hit(success)

func _on_answer_pressed(index: int) -> void:
	if index >= 0 and index < current_options.size():
		answer_selected.emit(current_options[index])

func _build() -> void:
	root = Control.new()
	root.size = Vector2(1280, 720)
	root.visible = false
	add_child(root)

	arena = Node2D.new()
	arena.set_script(BattleArenaScript)
	root.add_child(arena)

	var row_data = [["LEJOS", 211, "36d98b"], ["MEDIO", 261, "f5b942"], ["FRENTE", 316, "ff5777"]]
	for row in row_data:
		var label := UIFactory.label(str(row[0]), Rect2(275, float(row[1]), 90, 24), 13, Color(str(row[2])))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(label)

	var header := UIFactory.panel(Rect2(82, 38, 1116, 45), Color(0.04, 0.09, 0.17, 0.98), Color("20c7f3"))
	root.add_child(header)
	header.add_child(UIFactory.label("DEFENDIENDO TU SITIO", Rect2(20, 8, 360, 28), 15, Color("b9d8e9")))
	var tip := UIFactory.label("RESPONDE CSS • CADA ACIERTO DAÑA AL BUG", Rect2(390, 8, 680, 28), 14, Color("ffe06e"))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(tip)

	card = UIFactory.panel(Rect2(82, 455, 1116, 235), Color(0.035, 0.075, 0.13, 0.99), Color("27d0f4"))
	root.add_child(card)
	title_label = UIFactory.label("", Rect2(22, 14, 475, 30), 18, Color("ff7695"))
	card.add_child(title_label)
	meta_label = UIFactory.label("", Rect2(520, 15, 570, 28), 13, Color("91acc2"))
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	card.add_child(meta_label)

	question_label = UIFactory.label("", Rect2(22, 52, 470, 91), 18, Color("f4f8ff"))
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(question_label)

	var answer_label := UIFactory.label("SELECCIONA TU ATAQUE CSS", Rect2(525, 47, 555, 23), 13, Color("5de1ff"))
	answer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(answer_label)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.position = Vector2(525, 73)
	grid.size = Vector2(555, 118)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	card.add_child(grid)
	for i in range(4):
		var button := UIFactory.button("", Rect2(0, 0, 270, 54), Color("17304c"))
		button.custom_minimum_size = Vector2(270, 54)
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(_on_answer_pressed.bind(i))
		grid.add_child(button)
		buttons.append(button)

	feedback_label = UIFactory.label("", Rect2(22, 149, 470, 32), 14, Color("ffffff"))
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(feedback_label)
	hint_label = UIFactory.label("", Rect2(22, 182, 470, 42), 12, Color("ffd86a"))
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(hint_label)

	encounter_flash = ColorRect.new()
	encounter_flash.color = Color("63e8ff")
	encounter_flash.size = Vector2(1280, 720)
	encounter_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	encounter_flash.visible = false
	root.add_child(encounter_flash)
