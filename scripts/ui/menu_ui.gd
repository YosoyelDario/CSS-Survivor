extends CanvasLayer

signal play_requested
signal levels_requested
signal achievements_requested
signal ranking_requested
signal howto_requested
signal change_user_requested
signal exit_requested

const UIFactory = preload("res://scripts/ui/ui_factory.gd")
const GameConfig = preload("res://scripts/managers/game_config.gd")
const BG: Texture2D = preload("res://assets/backgrounds/level1_infected.png")
const HACKER: Texture2D = preload("res://assets/player/hacker.png")
const VIRUSES: Array[Texture2D] = [preload("res://assets/enemies/virus_1.png"), preload("res://assets/enemies/virus_2.png"), preload("res://assets/enemies/virus_3.png"), preload("res://assets/enemies/virus_4.png")]

var root: Control
var player_alias: Label
var player_meta: Label
var site_thumb: TextureRect
var progress_bar: ProgressBar
var unlock_label: Label
var floaters: Array = []

func _ready() -> void:
	layer = 10
	_build()

func show_menu(alias_value: String, points: int, badges: int, completed: int, total: int, level1_complete: bool) -> void:
	root.visible = true
	player_alias.text = alias_value
	player_meta.text = "PUNTOS %d   •   INSIGNIAS %d" % [points, badges]
	progress_bar.value = (float(completed) / float(maxi(1, total))) * 100.0
	unlock_label.text = "Nivel %d desbloqueado" % clampi(completed + 1, 1, total)
	if level1_complete and FileAccess.file_exists("res://assets/backgrounds/level1_clean.png"):
		site_thumb.texture = load("res://assets/backgrounds/level1_clean.png")
	else:
		site_thumb.texture = BG
	_start_floaters()

func hide_menu() -> void:
	root.visible = false

func _build() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UIFactory.make_theme()
	root.visible = false
	add_child(root)
	var bg := TextureRect.new()
	bg.texture = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.modulate = Color(0.22, 0.28, 0.42, 0.34)
	root.add_child(bg)
	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.01, 0.02, 0.06, 0.82)
	root.add_child(veil)

	for i in range(6):
		var virus := TextureRect.new()
		virus.texture = VIRUSES[i % VIRUSES.size()]
		virus.position = Vector2(25 + (i % 2) * 1170, 70 + i * 92)
		virus.size = Vector2(60, 60)
		virus.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		virus.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		virus.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		virus.modulate.a = 0.28
		virus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(virus)
		floaters.append(virus)

	var player_card := UIFactory.panel(Rect2(32, 28, 300, 82), Color(0.04,0.08,0.15,0.94), Color("294f70"))
	root.add_child(player_card)
	var avatar := TextureRect.new()
	avatar.texture = HACKER
	avatar.position = Vector2(12, 8)
	avatar.size = Vector2(62, 62)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_card.add_child(avatar)
	player_alias = UIFactory.label("JUGADOR", Rect2(84, 10, 200, 28), 18, UIFactory.PALETTE.cyan)
	player_card.add_child(player_alias)
	player_meta = UIFactory.label("", Rect2(84, 42, 200, 24), 12, UIFactory.PALETTE.muted)
	player_card.add_child(player_meta)

	var mission := UIFactory.panel(Rect2(42, 165, 280, 385), Color(0.04,0.08,0.15,0.94), Color("294f70"))
	root.add_child(mission)
	mission.add_child(UIFactory.title("TU MISIÓN", Rect2(22, 24, 236, 32), 17, UIFactory.PALETTE.cyan))
	var mission_text := UIFactory.label(str(GameConfig.text("mission", "Recorre la página infectada y restaura el sitio.")), Rect2(22, 76, 236, 150), 16, UIFactory.PALETTE.text)
	mission_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mission.add_child(mission_text)
	mission.add_child(UIFactory.icon_rect("medal", Rect2(96, 245, 88, 88)))
	var mission_tip := UIFactory.label("Cada fila limpia repara visualmente una parte del sitio.", Rect2(30, 330, 220, 45), 13, UIFactory.PALETTE.muted)
	mission_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission.add_child(mission_tip)

	var center := UIFactory.panel(Rect2(380, 78, 520, 565), Color(0.035,0.07,0.13,0.96), UIFactory.PALETTE.cyan)
	root.add_child(center)
	var logo_css := UIFactory.title("CSS", Rect2(60, 38, 400, 56), 42, UIFactory.PALETTE.cyan)
	logo_css.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(logo_css)
	var logo_surv := UIFactory.title("SURVIVOR", Rect2(60, 92, 400, 58), 38, UIFactory.PALETTE.orange)
	logo_surv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(logo_surv)
	var sub := UIFactory.label("DEFIENDE TU WEB. DOMINA CSS.", Rect2(60, 154, 400, 30), 14, UIFactory.PALETTE.text)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(sub)
	var duo := Control.new(); duo.position = Vector2(185, 188); duo.size = Vector2(150, 90); center.add_child(duo)
	var h := TextureRect.new(); h.texture = HACKER; h.position = Vector2(0, 0); h.size = Vector2(86,86); h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; h.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; duo.add_child(h)
	var v := TextureRect.new(); v.texture = VIRUSES[0]; v.position = Vector2(75, 10); v.size = Vector2(72,72); v.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; v.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; v.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; duo.add_child(v)
	_add_menu_button(center, "JUGAR", 294, UIFactory.PALETTE.orange, "play", func(): play_requested.emit())
	_add_menu_button(center, "NIVELES", 350, Color("2e8bd1"), "", func(): levels_requested.emit())
	_add_menu_button(center, "LOGROS", 406, UIFactory.PALETTE.purple, "medal", func(): achievements_requested.emit())
	_add_menu_button(center, "RANKING", 462, Color("256ec0"), "trophy", func(): ranking_requested.emit())
	_add_menu_button(center, "CÓMO JUGAR", 518, Color("253959"), "", func(): howto_requested.emit())

	var right := UIFactory.panel(Rect2(958, 165, 280, 385), Color(0.04,0.08,0.15,0.94), UIFactory.PALETTE.green)
	root.add_child(right)
	var rt := UIFactory.title("SITIO WEB\nBAJO ATAQUE", Rect2(18, 22, 244, 58), 15, UIFactory.PALETTE.green)
	rt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(rt)
	site_thumb = TextureRect.new()
	site_thumb.position = Vector2(30, 98)
	site_thumb.size = Vector2(220, 130)
	site_thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	site_thumb.stretch_mode = TextureRect.STRETCH_SCALE
	site_thumb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	right.add_child(site_thumb)
	right.add_child(UIFactory.label("PROGRESO GENERAL", Rect2(30, 252, 220, 22), 12, UIFactory.PALETTE.muted))
	progress_bar = UIFactory.progress(Rect2(30, 279, 220, 16), UIFactory.PALETTE.green)
	right.add_child(progress_bar)
	unlock_label = UIFactory.label("", Rect2(30, 305, 220, 28), 14, UIFactory.PALETTE.text)
	unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(unlock_label)

	var change := UIFactory.button("CAMBIAR JUGADOR", Rect2(42, 590, 220, 42), Color("26354d"))
	change.pressed.connect(func(): change_user_requested.emit()); root.add_child(change)
	var exit := UIFactory.button("SALIR", Rect2(1018, 590, 160, 42), Color("442238"))
	exit.pressed.connect(func(): exit_requested.emit()); root.add_child(exit)
	var footer := UIFactory.label("CSS Survivor • versión 0.3 piloto • PUCV OII-433", Rect2(410, 678, 460, 22), 11, UIFactory.PALETTE.muted)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; root.add_child(footer)

func _add_menu_button(parent: Control, text_value: String, y: float, color: Color, icon_name: String, callback: Callable) -> void:
	var b := UIFactory.button(text_value, Rect2(100, y, 320, 44), color, icon_name)
	b.pressed.connect(callback)
	parent.add_child(b)

func _start_floaters() -> void:
	for i in range(floaters.size()):
		var node: Control = floaters[i]
		if not is_instance_valid(node):
			continue
		var tween := create_tween().set_loops()
		var base_y := node.position.y
		tween.tween_property(node, "position:y", base_y + 14.0, 2.0 + float(i) * 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(node, "position:y", base_y, 2.0 + float(i) * 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
