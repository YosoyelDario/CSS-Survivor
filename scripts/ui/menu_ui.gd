extends CanvasLayer

signal start_requested(player_id: String)

const UIFactory = preload("res://scripts/ui/ui_factory.gd")

var email_input: LineEdit
var menu_message: Label

func _ready() -> void:
	layer = 5
	_build()

func show_menu() -> void:
	visible = true

func hide_menu() -> void:
	visible = false

func set_message(text_value: String) -> void:
	menu_message.text = text_value

func _build() -> void:
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
