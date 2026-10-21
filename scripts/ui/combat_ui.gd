extends CanvasLayer

signal answer_selected(answer: String)
signal continue_requested

const UIFactory=preload("res://scripts/ui/ui_factory.gd")
const BattleArena=preload("res://scripts/battle_arena.gd")

# Caja del enunciado de la pregunta. Se usa tanto para crear la etiqueta como para
# calcular si el texto cabe (ver _fit_question_text).
const QUESTION_BOX := Rect2(24, 52, 515, 72)

var root:Control
var arena
var zone_label:Label
var difficulty_label:Label
var hearts_box:HBoxContainer
var points_label:Label
var row_label:Label
var repair_bar:ProgressBar
var type_chip:Label
var question_label:Label
var code_panel:Panel
var code_label:Label
var buttons:Array[Button]=[]
var feedback_icon:TextureRect
var feedback_label:Label
var hint_label:Label
var continue_button:Button
var current_options:Array[String]=[]
var _last_lives:int=-1
var _button_disabled_style:StyleBox
const OPTION_TEXT_WIDTH:=258.0   # ancho útil del texto dentro de una alternativa (288 px menos márgenes)
var input_enabled:bool=false

func _ready()->void:
	layer=30
	_build()
	set_process(true)

# Configura la arena según el nivel (modo de ataque, layout del grupo y estilo base del enemigo).
func configure_level(cfg:Dictionary)->void:
	arena.configure_level(cfg)

# Muestra la fila del frente tal como parte el ejercicio (con su "bug" si lo tiene).
func prepare_row(question:Dictionary)->void:
	arena.prepare_row(question)

func show_combat(grid,zone_index:int,zone_name:String,difficulty:String)->void:
	_last_lives=-1
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
		hearts_box.remove_child(child)
		child.queue_free()
	for i in range(max_lives):
		hearts_box.add_child(UIFactory.icon_rect("heart" if i<lives else "heart_empty",Rect2(0,0,22,22)))
	if _last_lives>=0 and lives!=_last_lives:
		_animate_heart(clampi(lives-1 if lives>_last_lives else lives,0,maxi(0,max_lives-1)),lives>_last_lives)
	_last_lives=lives
	points_label.text="%d PTS"%points
	row_label.text="Fila %d de %d"%[clampi(row_number,1,maxi(1,row_total)),row_total]
	repair_bar.value=clampf(repair*100.0,0.0,100.0)

func show_question(question:Dictionary,options:Array[String])->void:
	current_options=options.duplicate()
	var kind:=str(question.get("kind","teorico"))
	var display_names={"teorico":"TEÓRICA","practico":"PRÁCTICA","completar":"COMPLETAR CÓDIGO","multi":"MULTI-OBJETIVO","boss":"ENEMIGO FINAL"}
	var colors={"teorico":UIFactory.PALETTE.cyan,"practico":UIFactory.PALETTE.orange,"completar":UIFactory.PALETTE.green,"multi":UIFactory.PALETTE.purple,"boss":UIFactory.PALETTE.red}
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
	for i in range(buttons.size()):
		buttons[i].visible=i<current_options.size()
		buttons[i].disabled=false
		buttons[i].add_theme_stylebox_override("disabled",_button_disabled_style)
		var option_label:Label=buttons[i].get_node("OptionText") as Label
		option_label.modulate.a=1.0
		if i<current_options.size():
			var mono=UIFactory.mono_font()
			if kind!="teorico" and mono!=null:
				option_label.add_theme_font_override("font",mono)
			else:
				option_label.remove_theme_font_override("font")
			_fit_option_text(option_label,"%d   %s"%[i+1,current_options[i]])
	input_enabled=true

# Las alternativas largas (por ejemplo, tres propiedades combinadas) no caben en una línea:
# se ajustan a dos líneas y, si hace falta, con una letra algo menor. Así nunca se salen de la tarjeta.
func _fit_option_text(label:Label,text_value:String)->void:
	label.text=text_value
	var font:Font=label.get_theme_font("font")
	var chosen:=11
	if font!=null:
		for candidate in [13,12,11]:
			var needed:Vector2=font.get_multiline_string_size(text_value,HORIZONTAL_ALIGNMENT_CENTER,OPTION_TEXT_WIDTH,candidate)
			if needed.y<=3.0*font.get_height(candidate)+2.0:
				chosen=candidate
				break
	label.add_theme_font_size_override("font_size",chosen)

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

# summary: resultado en una línea. detail: explicación (por qué falló o refuerzo tras acertar).
# chosen_text: alternativa elegida; se marca en rojo (error) o verde (acierto). Al fallar NO se
# señala la correcta, para no regalar la respuesta.
func show_feedback(correct:bool,summary:String,detail:String="",chosen_text:String="")->void:
	input_enabled=false
	for i in range(buttons.size()):
		buttons[i].disabled=true
		var is_chosen:bool=i<current_options.size() and current_options[i]==chosen_text and not chosen_text.is_empty()
		(buttons[i].get_node("OptionText") as Label).modulate.a=1.0 if is_chosen else 0.55
		if is_chosen:
			var color:Color=UIFactory.PALETTE.green if correct else UIFactory.PALETTE.red
			buttons[i].add_theme_stylebox_override("disabled",UIFactory.style_box(Color(color,0.20),color,3,10))
	feedback_icon.texture=UIFactory.icon_texture("check" if correct else "cross")
	feedback_icon.visible=true
	feedback_label.text=summary
	feedback_label.add_theme_color_override("font_color",UIFactory.PALETTE.green if correct else UIFactory.PALETTE.red)
	hint_label.text=detail
	hint_label.add_theme_color_override("font_color",Color("9be8c6") if correct else UIFactory.PALETTE.yellow)
	continue_button.visible=not correct

# Corazón que se gana: crece y se tiñe de verde. Corazón que se pierde: se agranda y se pone rojo.
func _animate_heart(index:int,gained:bool)->void:
	if index<0 or index>=hearts_box.get_child_count():
		return
	var heart:Control=hearts_box.get_child(index) as Control
	heart.pivot_offset=heart.size*0.5
	var tint:Color=Color("7dffb8") if gained else Color("ff5777")
	heart.modulate=tint
	var tween:=create_tween()
	tween.set_parallel(true)
	tween.tween_property(heart,"scale",Vector2(1.7,1.7),0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(heart,"scale",Vector2.ONE,0.22)
	tween.tween_property(heart,"modulate",Color.WHITE,0.45)

func set_buttons_enabled(enabled:bool)->void:
	input_enabled=enabled
	for b in buttons:
		b.disabled=not enabled

func get_option_texts()->Array:
	return current_options.duplicate()

func animate_attack(selection:Dictionary,effects:Array,question:Dictionary={})->void:
	await arena.animate_attack(selection,effects,question)

func animate_advance(grid)->void:
	await arena.animate_advance(grid)

func mark_selection(selection:Dictionary)->void:
	arena.mark_selection(selection)

func _process(_delta:float)->void:
	if not root.visible:
		return
	if input_enabled:
		for i in range(4):
			if Input.is_action_just_pressed("answer_%d"%(i+1)) and i<current_options.size():
				_on_answer(i)
	else:
		if continue_button.visible and Input.is_action_just_pressed("interact"):
			continue_requested.emit()

func _on_answer(index:int)->void:
	if not input_enabled or index<0 or index>=current_options.size():
		return
	input_enabled=false
	answer_selected.emit(current_options[index])

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
	feedback_icon=UIFactory.icon_rect("check",Rect2(24,186,24,24)); feedback_icon.visible=false; card.add_child(feedback_icon)
	feedback_label=UIFactory.label("",Rect2(56,182,480,30),14,UIFactory.PALETTE.text); card.add_child(feedback_label)
	hint_label=UIFactory.label("",Rect2(24,207,520,34),12,UIFactory.PALETTE.yellow); hint_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; card.add_child(hint_label)

	var grid:=GridContainer.new(); grid.columns=2; grid.position=Vector2(570,25); grid.size=Vector2(590,150); grid.add_theme_constant_override("h_separation",12); grid.add_theme_constant_override("v_separation",12); card.add_child(grid)
	for i in range(4):
		var b:=UIFactory.button("",Rect2(0,0,288,68),Color("17304c")); b.custom_minimum_size=Vector2(288,68); b.add_theme_font_size_override("font_size",13); b.pressed.connect(_on_answer.bind(i)); grid.add_child(b); buttons.append(b)
		# El texto va en una etiqueta con ajuste de línea (el Button de Godot 4.2 no lo tiene).
		var option_label:=Label.new(); option_label.name="OptionText"; option_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		option_label.offset_left=10; option_label.offset_right=-10; option_label.offset_top=4; option_label.offset_bottom=-4
		option_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; option_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		option_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; option_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		option_label.add_theme_color_override("font_color",UIFactory.PALETTE.text); option_label.add_theme_font_size_override("font_size",13)
		b.add_child(option_label)
	_button_disabled_style=buttons[0].get_theme_stylebox("disabled")
	continue_button=UIFactory.button("CONTINUAR",Rect2(760,190,240,42),UIFactory.PALETTE.orange,"play"); continue_button.visible=false; continue_button.pressed.connect(func():continue_requested.emit()); card.add_child(continue_button)
