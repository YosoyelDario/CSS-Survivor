extends CanvasLayer

signal answer_selected(answer: String)

const UIFactory = preload("res://scripts/ui/ui_factory.gd")
const BattleArenaScript = preload("res://scripts/battle_arena.gd")

<<<<<<< Updated upstream
var root: Control
var title_label: Label
var meta_label: Label
var question_label: Label
var buttons: Array[Button] = []
var feedback_label: Label
var hint_label: Label
=======
# Caja del enunciado de la pregunta. Se usa tanto para crear la etiqueta como para
# calcular si el texto cabe (ver _fit_question_text).
const QUESTION_BOX := Rect2(24, 52, 515, 72)

var root:Control
>>>>>>> Stashed changes
var arena
var card: Panel
var encounter_flash: ColorRect
var current_options: Array[String] = []

func _ready() -> void:
	layer = 20
	_build()

<<<<<<< Updated upstream
func show_question(question: Dictionary, options: Array[String], zone_number: int, hp: int, max_hp: int, hint_text: String = "") -> void:
	title_label.text = "⚠ BUG DE ZONA %d  •  HP %d/%d" % [zone_number, hp, max_hp]
	meta_label.text = "Pregunta #%d  •  %s  •  %s" % [int(question["id"]), str(question["type"]), str(question["difficulty"])]
	question_label.text = str(question["question"])
	feedback_label.text = ""
	set_hint(hint_text)
	current_options = options.duplicate()
=======
func show_combat(grid,zone_index:int,zone_name:String,difficulty:String)->void:
	root.visible=true
	zone_label.text="ZONA %d • %s"%[zone_index+1,zone_name]
	difficulty_label.text=difficulty.to_upper()
	arena.show_grid(grid)
	feedback_label.text=""
	hint_label.text=""
	feedback_icon.visible=false
	continue_button.visible=false

func hide_combat()->void:
	root.visible=false
	input_enabled=false

func animate_open() -> void:
	root.modulate.a = 0.0
	root.visible = true
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 1.0, 0.25)
	await tween.finished

func animate_close() -> void:
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 0.0, 0.22)
	await tween.finished
	root.visible = false
	root.modulate.a = 1.0
	input_enabled = false

func update_header(lives:int,max_lives:int,points:int,row_number:int,row_total:int,repair:float)->void:
	for child in hearts_box.get_children():
		child.queue_free()
	for i in range(max_lives):
		hearts_box.add_child(UIFactory.icon_rect("heart" if i<lives else "heart_empty",Rect2(0,0,22,22)))
	points_label.text="%d PTS"%points
	row_label.text="Fila %d de %d"%[clampi(row_number,1,maxi(1,row_total)),row_total]
	repair_bar.value=clampf(repair*100.0,0.0,100.0)

func show_question(question:Dictionary,options:Array[String])->void:
	current_options=options.duplicate()
	var kind:=str(question.get("kind","teorico"))
	var display_names={"teorico":"TEÓRICA","practico":"PRÁCTICA","completar":"COMPLETAR CÓDIGO","multi":"MULTI-OBJETIVO"}
	var colors={"teorico":UIFactory.PALETTE.cyan,"practico":UIFactory.PALETTE.orange,"completar":UIFactory.PALETTE.green,"multi":UIFactory.PALETTE.purple}
	type_chip.text=str(display_names.get(kind,kind.to_upper()))
	type_chip.add_theme_stylebox_override("normal",UIFactory.style_box(Color(colors.get(kind,UIFactory.PALETTE.cyan),0.18),colors.get(kind,UIFactory.PALETTE.cyan),1,10))
	question_label.text=str(question.get("question",""))
	_fit_question_text()
	var show_code:=kind=="completar" and not str(question.get("code","")).is_empty()
	code_panel.visible=show_code
	code_label.text=str(question.get("code",""))
	feedback_label.text=""
	hint_label.text=""
	feedback_icon.visible=false
	continue_button.visible=false
>>>>>>> Stashed changes
	for i in range(buttons.size()):
		buttons[i].disabled = false
		buttons[i].text = "%s  %s" % [String.chr(65 + i), current_options[i]]

<<<<<<< Updated upstream
func set_battle_state(level: int, hp: int, max_hp: int, active: bool, zone_index: int = 0) -> void:
	arena.set_battle_state(level, hp, max_hp, active, zone_index)
=======
# El enunciado usa UIFactory.QUESTION_SIZE (24 px). Si el texto no cabe en la caja,
# baja a 22 y luego a 20 px; nunca baja de 20 para que siga siendo claramente más
# grande que el texto normal (16 px).
func _fit_question_text() -> void:
	var font: Font = question_label.get_theme_font("font")
	var sizes: Array[int] = [UIFactory.QUESTION_SIZE, 22, 20]
	var chosen: int = sizes[sizes.size() - 1]
	if font != null:
		for candidate in sizes:
			var needed: Vector2 = font.get_multiline_string_size(question_label.text, HORIZONTAL_ALIGNMENT_LEFT, QUESTION_BOX.size.x, candidate)
			if needed.y <= QUESTION_BOX.size.y:
				chosen = candidate
				break
	question_label.add_theme_font_size_override("font_size", chosen)
	# El Label crece solo si el texto es más alto que la caja; se devuelve al tamaño fijo.
	question_label.size = QUESTION_BOX.size

func show_feedback(correct:bool,summary:String,hint:String="")->void:
	input_enabled=false
	for b in buttons:
		b.disabled=true
	feedback_icon.texture=UIFactory.icon_texture("check" if correct else "cross")
	feedback_icon.visible=true
	feedback_label.text=summary
	feedback_label.add_theme_color_override("font_color",UIFactory.PALETTE.green if correct else UIFactory.PALETTE.red)
	hint_label.text=("PISTA: "+hint) if not correct and not hint.is_empty() else ""
	continue_button.visible=not correct
>>>>>>> Stashed changes

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

<<<<<<< Updated upstream
func flash_hit(success: bool) -> void:
	await arena.flash_hit(success)

func _on_answer_pressed(index: int) -> void:
	if index >= 0 and index < current_options.size():
		answer_selected.emit(current_options[index])
=======
func _build()->void:
	root=Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.theme=UIFactory.make_theme(); root.visible=false; add_child(root)
	var bg:=ColorRect.new(); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.color=UIFactory.PALETTE.bg; root.add_child(bg)
	var stage:=UIFactory.stage(root)
	arena=BattleArena.new(); arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); stage.add_child(arena)
	var header:=UIFactory.panel(Rect2(45,18,1190,64),Color(0.03,0.07,0.13,0.97),UIFactory.PALETTE.cyan); stage.add_child(header)
	zone_label=UIFactory.title("ZONA 1 • PERFIL",Rect2(20,11,320,38),14,UIFactory.PALETTE.text); header.add_child(zone_label)
	difficulty_label=UIFactory.label("FÁCIL",Rect2(345,16,90,28),12,UIFactory.PALETTE.green); header.add_child(difficulty_label)
	hearts_box=HBoxContainer.new(); hearts_box.position=Vector2(455,18); hearts_box.size=Vector2(145,24); hearts_box.add_theme_constant_override("separation",3); header.add_child(hearts_box)
	header.add_child(UIFactory.icon_rect("star",Rect2(625,17,24,24)))
	points_label=UIFactory.label("0 PTS",Rect2(654,14,130,30),14,UIFactory.PALETTE.yellow); header.add_child(points_label)
	row_label=UIFactory.label("Fila 1 de 3",Rect2(795,14,120,30),13,UIFactory.PALETTE.text); header.add_child(row_label)
	repair_bar=UIFactory.progress(Rect2(930,20,230,14),UIFactory.PALETTE.green); header.add_child(repair_bar)
	var repair_text:=UIFactory.label("REPARACIÓN",Rect2(930,37,230,18),10,UIFactory.PALETTE.muted); repair_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; header.add_child(repair_text)

	var card:=UIFactory.panel(Rect2(45,452,1190,246),Color("0d172b"),Color("294f70")); stage.add_child(card)
	type_chip=UIFactory.chip("TEÓRICA",UIFactory.PALETTE.cyan); type_chip.position=Vector2(24,16); type_chip.size=Vector2(160,28); card.add_child(type_chip)
	question_label=UIFactory.question_label("",QUESTION_BOX); question_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; card.add_child(question_label)
	code_panel=UIFactory.panel(Rect2(24,126,515,54),Color("07101d"),Color("315b82"),8); card.add_child(code_panel)
	code_label=UIFactory.code_label("",Rect2(14,10,487,34),15); code_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; code_panel.add_child(code_label); code_panel.visible=false
	feedback_icon=UIFactory.icon_rect("check",Rect2(24,193,24,24)); feedback_icon.visible=false; card.add_child(feedback_icon)
	feedback_label=UIFactory.label("",Rect2(56,188,480,30),14,UIFactory.PALETTE.text); card.add_child(feedback_label)
	hint_label=UIFactory.label("",Rect2(24,217,515,24),12,UIFactory.PALETTE.yellow); card.add_child(hint_label)
>>>>>>> Stashed changes

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
