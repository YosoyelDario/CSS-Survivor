extends CanvasLayer

signal start_requested(player_id: String)

const UIFactory = preload("res://scripts/ui/ui_factory.gd")

var email_input: LineEdit
var menu_message: Label

func _ready() -> void:
	layer = 5
	_build()

<<<<<<< Updated upstream
func show_menu() -> void:
	visible = true
=======
func show_menu(alias_value: String, points: int, badges: int, completed: int, total: int, level1_complete: bool) -> void:
	root.visible = true
	player_alias.text = alias_value
	player_meta.text = "PUNTOS %d   •   INSIGNIAS %d" % [points, badges]
	progress_bar.value = (float(completed) / float(maxi(1, total))) * 100.0
	unlock_label.text = "Nivel %d desbloqueado" % clampi(completed + 1, 1, total)
	if level1_complete and ResourceLoader.exists("res://assets/backgrounds/level1_clean.png"):
		site_thumb.texture = load("res://assets/backgrounds/level1_clean.png")
	else:
		site_thumb.texture = BG
	_start_floaters()
>>>>>>> Stashed changes

func hide_menu() -> void:
	visible = false

func set_message(text_value: String) -> void:
	menu_message.text = text_value

func _build() -> void:
<<<<<<< Updated upstream
	var bg := ColorRect.new()
	bg.color = Color("080d22")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.size = Vector2(1280, 720)
	add_child(bg)

	var deco := UIFactory.label("<  CSS / DEBUG / REPAIR / SURVIVE  >", Rect2(405, 55, 470, 32), 16, Color("59d9ff"))
	deco.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(deco)

	var left := UIFactory.panel(Rect2(75, 140, 280, 430), Color("101c35"), Color("1e6f9d"))
	add_child(left)
	left.add_child(UIFactory.label("TU MISIÓN", Rect2(25, 25, 230, 40), 19, Color("5de1ff")))
	var left_body := UIFactory.label("Recorre una página web infectada como en un mapa 2D.\n\nEncuentra los 4 BUGS de las esquinas, enfréntalos y responde preguntas CSS.\n\nCada acierto daña al bug y repara el sitio.", Rect2(25, 85, 230, 250), 16, Color("d7e8fa"))
	left_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(left_body)

	var center := UIFactory.panel(Rect2(405, 120, 470, 475), Color("0d172b"), Color("20c7f3"))
	add_child(center)
	var title := UIFactory.label("CSS\nSURVIVOR", Rect2(35, 45, 400, 125), 48, Color("ffffff"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)
	var sub := UIFactory.label("DEFEND YOUR WEB. DOMINA CSS.", Rect2(35, 170, 400, 30), 15, Color("ff934d"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(sub)

	email_input = LineEdit.new()
	email_input.position = Vector2(75, 225)
	email_input.size = Vector2(320, 44)
	email_input.placeholder_text = "Correo / identificador del estudiante"
	center.add_child(email_input)

	var play := UIFactory.button("▶ JUGAR", Rect2(75, 288, 320, 52), Color("ff7a36"))
	play.pressed.connect(_on_play_pressed)
	center.add_child(play)
	var how := UIFactory.button("? CÓMO JUGAR", Rect2(75, 352, 320, 46), Color("253959"))
	how.pressed.connect(_show_how_to_play)
	center.add_child(how)
	menu_message = UIFactory.label("", Rect2(75, 410, 320, 35), 14, Color("ff9aaa"))
	menu_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(menu_message)
=======
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UIFactory.make_theme()
	root.visible = false
	add_child(root)

	# Fondo a pantalla completa (1920x1080), recortado en vez de deformado.
	var bg := UIFactory.texture_rect(BG, Rect2(0, 0, 1920, 1080), TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.modulate = Color(0.22, 0.28, 0.42, 0.34)
	root.add_child(bg)
	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.01, 0.02, 0.06, 0.82)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(veil)

	# Todo lo demás se diseña en coordenadas de 1280x720 (ver UIFactory.stage).
	var stage := UIFactory.stage(root)

	for i in range(6):
		var virus := UIFactory.texture_rect(VIRUSES[i % VIRUSES.size()], Rect2(25 + (i % 2) * 1170, 70 + i * 92, 60, 60))
		virus.modulate.a = 0.28
		stage.add_child(virus)
		floaters.append(virus)

	var player_card := UIFactory.panel(Rect2(32, 28, 300, 82), Color(0.04,0.08,0.15,0.94), Color("294f70"))
	stage.add_child(player_card)
	player_card.add_child(UIFactory.texture_rect(HACKER, Rect2(12, 8, 62, 62)))
	player_alias = UIFactory.label("JUGADOR", Rect2(84, 10, 200, 28), 18, UIFactory.PALETTE.cyan)
	player_card.add_child(player_alias)
	player_meta = UIFactory.label("", Rect2(84, 42, 200, 24), 12, UIFactory.PALETTE.muted)
	player_card.add_child(player_meta)

	var mission := UIFactory.panel(Rect2(42, 165, 280, 385), Color(0.04,0.08,0.15,0.94), Color("294f70"))
	stage.add_child(mission)
	mission.add_child(UIFactory.title("TU MISIÓN", Rect2(22, 24, 236, 32), 17, UIFactory.PALETTE.cyan))
	var mission_text := UIFactory.label(str(GameConfig.text("mission", "Recorre la página infectada y restaura el sitio.")), Rect2(22, 76, 236, 150), 16, UIFactory.PALETTE.text)
	mission_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mission.add_child(mission_text)
	mission.add_child(UIFactory.icon_rect("medal", Rect2(96, 245, 88, 88)))
	var mission_tip := UIFactory.label("Cada fila limpia repara visualmente una parte del sitio.", Rect2(30, 330, 220, 45), 13, UIFactory.PALETTE.muted)
	mission_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission.add_child(mission_tip)

	var center := UIFactory.panel(Rect2(380, 52, 520, 610), Color(0.035,0.07,0.13,0.96), UIFactory.PALETTE.cyan)
	stage.add_child(center)
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
	duo.add_child(UIFactory.texture_rect(HACKER, Rect2(0, 0, 86, 86)))
	duo.add_child(UIFactory.texture_rect(VIRUSES[0], Rect2(75, 10, 72, 72)))
	_add_menu_button(center, "JUGAR", 294, UIFactory.PALETTE.orange, "play", func(): play_requested.emit())
	_add_menu_button(center, "NIVELES", 350, Color("2e8bd1"), "", func(): levels_requested.emit())
	_add_menu_button(center, "LOGROS", 406, UIFactory.PALETTE.purple, "medal", func(): achievements_requested.emit())
	_add_menu_button(center, "RANKING", 462, Color("256ec0"), "trophy", func(): ranking_requested.emit())
	_add_menu_button(center, "CÓMO JUGAR", 518, Color("253959"), "", func(): howto_requested.emit())

	var right := UIFactory.panel(Rect2(958, 165, 280, 385), Color(0.04,0.08,0.15,0.94), UIFactory.PALETTE.green)
	stage.add_child(right)
	var rt := UIFactory.title("SITIO WEB\nBAJO ATAQUE", Rect2(18, 22, 244, 58), 15, UIFactory.PALETTE.green)
	rt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(rt)
	site_thumb = UIFactory.texture_rect(BG, Rect2(30, 98, 220, 130), TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	site_thumb.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	site_thumb.clip_contents = true
	right.add_child(site_thumb)
	right.add_child(UIFactory.label("PROGRESO GENERAL", Rect2(30, 252, 220, 22), 12, UIFactory.PALETTE.muted))
	progress_bar = UIFactory.progress(Rect2(30, 279, 220, 16), UIFactory.PALETTE.green)
	right.add_child(progress_bar)
	unlock_label = UIFactory.label("", Rect2(30, 305, 220, 28), 14, UIFactory.PALETTE.text)
	unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(unlock_label)

	var change := UIFactory.button("CAMBIAR JUGADOR", Rect2(42, 590, 220, 42), Color("26354d"))
	change.pressed.connect(func(): change_user_requested.emit()); stage.add_child(change)
	var exit := UIFactory.button("SALIR", Rect2(1018, 590, 160, 42), Color("442238"))
	exit.pressed.connect(func(): exit_requested.emit()); stage.add_child(exit)
	var footer := UIFactory.label("CSS Survivor • versión 0.3 piloto • PUCV OII-433", Rect2(410, 684, 460, 22), 11, UIFactory.PALETTE.muted)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; stage.add_child(footer)
>>>>>>> Stashed changes

	var right := UIFactory.panel(Rect2(925, 140, 280, 430), Color("101c35"), Color("35cf75"))
	add_child(right)
	var rtitle := UIFactory.label("SITIO WEB BAJO ATAQUE", Rect2(20, 25, 240, 35), 18, Color("66ef9f"))
	rtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(rtitle)
	var card := UIFactory.panel(Rect2(35, 90, 210, 170), Color("eaf7ff"), Color("73bde0"))
	right.add_child(card)
	var ct := UIFactory.label("MI SITIO WEB", Rect2(15, 25, 180, 30), 19, Color("226899"))
	ct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(ct)
	var cb := UIFactory.label("⚠ 4 ZONAS INFECTADAS\n\n3 NIVELES • 90 EJERCICIOS", Rect2(15, 68, 180, 70), 14, Color("d43c5e"))
	cb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(cb)
	var info := UIFactory.label("Banco: 30 preguntas por nivel\nSelección RANDOM sin repetir hasta agotar el pool.", Rect2(25, 295, 230, 90), 14, Color("c9d8e8"))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(info)

func _on_play_pressed() -> void:
	var player_id := email_input.text.strip_edges()
	if player_id.is_empty():
		player_id = "JUGADOR_01"
	start_requested.emit(player_id)

func _show_how_to_play() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Cómo jugar CSS Survivor"
	dialog.dialog_text = "1) Muévete con WASD o flechas: la cámara te sigue y vas recorriendo una página web grande.\n2) Busca los 4 BUGS distribuidos por las cuatro zonas del mapa.\n3) Acércate y presiona E, Espacio o Enter: el personaje salta al encuentro y entra a una batalla.\n4) La batalla usa una pregunta RANDOM del banco de 30 del nivel, sin repetir hasta agotar el pool.\n5) Cada acierto quita 1 HP. El combate continúa hasta derrotar el BUG; tras dos fallos aparece una pista.\n6) Vuelves al mapa, recorres la siguiente zona y al derrotar los 4 BUGS la página queda reparada."
	dialog.size = Vector2(680, 360)
	add_child(dialog)
	dialog.popup_centered()
	dialog.canceled.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)
