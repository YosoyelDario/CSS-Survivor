extends CanvasLayer

signal back_requested
signal global_connect_requested
signal admin_login_requested(password: String)
signal admin_refresh_requested
signal admin_set_test_requested(player_id: String, value: bool)
signal admin_set_hidden_requested(player_id: String, value: bool)
signal admin_delete_requested(player_id: String)
signal admin_logout_requested

const UIFactory = preload("res://scripts/ui/ui_factory.gd")

var root: Control
var rows_box: VBoxContainer
var title_label: Label
var status_label: Label
var local_button: Button
var global_button: Button
var connect_button: Button
var admin_button: Button
var session_manager_ref
var mode: String = "local"
var admin_password_input: LineEdit
var delete_candidate_id: String = ""

func _ready() -> void:
	layer = 22
	_build()

func show_ranking(session_manager) -> void:
	session_manager_ref = session_manager
	root.visible = true
	_show_local()

func hide_ranking() -> void:
	root.visible = false
	delete_candidate_id = ""

func show_global_loading() -> void:
	mode = "global"
	_clear_rows()
	title_label.text = "RANKING GLOBAL"
	status_label.text = "Conectando con Google Sheets..."
	connect_button.visible = true
	connect_button.disabled = true
	connect_button.text = "CONECTANDO..."
	admin_button.visible = true
	admin_button.disabled = true
	admin_button.text = "ADMIN"
	_add_message("Sincronizando resultados pendientes y descargando el Top 10.")

func show_global_ranking(rows: Array) -> void:
	mode = "global"
	delete_candidate_id = ""
	_clear_rows()
	title_label.text = "RANKING GLOBAL"
	status_label.text = "Conectado • Top 10 global"
	connect_button.visible = true
	connect_button.disabled = false
	connect_button.text = "ACTUALIZAR"
	admin_button.visible = true
	admin_button.disabled = false
	admin_button.text = "ADMIN"

	if rows.is_empty():
		_add_message("Aún no hay resultados en el ranking global.")
		return

	var limit: int = mini(10, rows.size())
	for i in range(limit):
		var raw: Dictionary = rows[i] as Dictionary
		var badges_text: String = str(raw.get("insignias", ""))
		var badge_count: int = 0
		if not badges_text.strip_edges().is_empty():
			badge_count = badges_text.split(",", false).size()
		var normalized: Dictionary = {
			"alias": str(raw.get("alias", "JUGADOR")),
			"points": int(raw.get("puntaje", 0)),
			"badges": badge_count,
			"n1": int(raw.get("nivel_1", 0)),
			"n2": int(raw.get("nivel_2", 0)),
			"n3": int(raw.get("nivel_3", 0)),
			"current": false
		}
		_add_row(i + 1, normalized, true)

func show_global_error(message: String) -> void:
	mode = "global"
	_clear_rows()
	title_label.text = "RANKING GLOBAL"
	status_label.text = "Sin conexión"
	connect_button.visible = true
	connect_button.disabled = false
	connect_button.text = "REINTENTAR"
	admin_button.visible = true
	admin_button.disabled = false
	admin_button.text = "ADMIN"
	_add_message(message)

func show_admin_login(message: String = "") -> void:
	mode = "admin_login"
	delete_candidate_id = ""
	_clear_rows()
	title_label.text = "ADMINISTRACIÓN"
	status_label.text = message if not message.is_empty() else "Acceso restringido. La contraseña no se guarda en el juego."
	connect_button.visible = false
	admin_button.visible = true
	admin_button.disabled = false
	admin_button.text = "CANCELAR"

	var card := UIFactory.panel(Rect2(0, 0, 780, 150), Color("101c35"), UIFactory.PALETTE.purple, 10)
	card.custom_minimum_size = Vector2(780, 150)
	card.add_child(UIFactory.label("Contraseña administrador", Rect2(36, 20, 300, 28), 16, UIFactory.PALETTE.text))
	admin_password_input = LineEdit.new()
	admin_password_input.position = Vector2(36, 55)
	admin_password_input.size = Vector2(470, 42)
	admin_password_input.secret = true
	admin_password_input.placeholder_text = "Contraseña"
	admin_password_input.add_theme_font_size_override("font_size", 16)
	admin_password_input.text_submitted.connect(_on_admin_password_submitted)
	card.add_child(admin_password_input)
	var enter := UIFactory.button("ENTRAR", Rect2(530, 55, 210, 42), UIFactory.PALETTE.purple)
	enter.pressed.connect(_submit_admin_login)
	card.add_child(enter)
	card.add_child(UIFactory.label("La sesión administrativa caduca automáticamente.", Rect2(36, 108, 700, 24), 13, UIFactory.PALETTE.muted))
	rows_box.add_child(card)
	admin_password_input.grab_focus()

func show_admin_loading(message: String = "Cargando usuarios...") -> void:
	mode = "admin"
	_clear_rows()
	title_label.text = "ADMIN • RANKING GLOBAL"
	status_label.text = message
	connect_button.visible = true
	connect_button.disabled = true
	connect_button.text = "CARGANDO..."
	admin_button.visible = true
	admin_button.disabled = false
	admin_button.text = "SALIR ADMIN"
	_add_message("Consultando datos administrativos.")

func show_admin_players(rows: Array, message: String = "Sesión administrador activa") -> void:
	mode = "admin"
	_clear_rows()
	title_label.text = "ADMIN • RANKING GLOBAL"
	status_label.text = message
	connect_button.visible = true
	connect_button.disabled = false
	connect_button.text = "ACTUALIZAR"
	admin_button.visible = true
	admin_button.disabled = false
	admin_button.text = "SALIR ADMIN"

	if rows.is_empty():
		_add_message("No hay jugadores registrados en Google Sheets.")
		return

	for raw_value in rows:
		_add_admin_row(raw_value as Dictionary)

func show_admin_error(message: String) -> void:
	if mode == "admin_login":
		show_admin_login(message)
		return
	status_label.text = message
	connect_button.disabled = false
	connect_button.text = "ACTUALIZAR"

func _show_local() -> void:
	mode = "local"
	delete_candidate_id = ""
	_clear_rows()
	title_label.text = "RANKING LOCAL"
	status_label.text = "Datos guardados en este computador."
	connect_button.visible = false
	connect_button.disabled = false
	connect_button.text = "CONECTAR"
	admin_button.visible = false
	admin_button.disabled = false
	admin_button.text = "ADMIN"

	if session_manager_ref == null:
		_add_message("No hay una sesión activa.")
		return

	var ranking: Array = session_manager_ref.ranking()
	if ranking.is_empty():
		_add_message("Aún no hay perfiles con puntaje.")
		return

	var limit: int = mini(10, ranking.size())
	var current_in_top: bool = false
	for i in range(limit):
		var row: Dictionary = ranking[i] as Dictionary
		_add_row(i + 1, row, false)
		current_in_top = current_in_top or bool(row.get("current", false))

	if not current_in_top:
		for i in range(limit, ranking.size()):
			var current_row: Dictionary = ranking[i] as Dictionary
			if bool(current_row.get("current", false)):
				_add_row(i + 1, current_row, false)
				break

func _select_global() -> void:
	mode = "global"
	delete_candidate_id = ""
	_clear_rows()
	title_label.text = "RANKING GLOBAL"
	status_label.text = "Ranking global desconectado."
	connect_button.visible = true
	connect_button.disabled = false
	connect_button.text = "CONECTAR"
	admin_button.visible = true
	admin_button.disabled = false
	admin_button.text = "ADMIN"
	_add_message("Pulsa CONECTAR para consultar el Top 10. No se realizan consultas automáticas.")

func _request_global() -> void:
	if mode == "admin":
		show_admin_loading("Actualizando lista de usuarios...")
		admin_refresh_requested.emit()
		return
	show_global_loading()
	global_connect_requested.emit()

func _on_admin_button_pressed() -> void:
	if mode == "admin":
		admin_logout_requested.emit()
		_select_global()
		return
	if mode == "admin_login":
		_select_global()
		return
	show_admin_login()

func _on_admin_password_submitted(_value: String) -> void:
	_submit_admin_login()

func _emit_admin_test(player_id: String, value: bool) -> void:
	admin_set_test_requested.emit(player_id, value)

func _emit_admin_hidden(player_id: String, value: bool) -> void:
	admin_set_hidden_requested.emit(player_id, value)

func _submit_admin_login() -> void:
	if admin_password_input == null:
		return
	var password: String = admin_password_input.text
	if password.is_empty():
		status_label.text = "Ingresa la contraseña de administrador."
		return
	admin_password_input.editable = false
	status_label.text = "Validando acceso..."
	admin_login_requested.emit(password)
	admin_password_input.text = ""

func _clear_rows() -> void:
	for child in rows_box.get_children():
		child.queue_free()

func _add_message(text_value: String) -> void:
	var empty := UIFactory.label(text_value, Rect2(0, 0, 780, 60), 16, UIFactory.PALETTE.muted)
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rows_box.add_child(empty)

func _add_row(position: int, data: Dictionary, global_row: bool = false) -> void:
	var border := Color("33415c")
	if position == 1:
		border = Color("ffd447")
	elif position == 2:
		border = Color("b9c4d7")
	elif position == 3:
		border = Color("c88c5d")
	if bool(data.get("current", false)):
		border = UIFactory.PALETTE.cyan

	var card := UIFactory.panel(Rect2(0, 0, 780, 46), Color("101c35"), border, 8)
	card.custom_minimum_size = Vector2(780, 46)
	if position == 1:
		card.add_child(UIFactory.icon_rect("trophy", Rect2(16, 10, 26, 26)))

	var pos := UIFactory.label(str(position), Rect2(48, 8, 44, 28), 15, UIFactory.PALETTE.text)
	card.add_child(pos)
	card.add_child(UIFactory.label(str(data.get("alias", "JUGADOR")), Rect2(105, 8, 300, 28), 15, UIFactory.PALETTE.text))

	var pts := UIFactory.label("%d pts" % int(data.get("points", 0)), Rect2(420, 8, 150, 28), 15, UIFactory.PALETTE.yellow)
	pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	card.add_child(pts)

	var detail_text: String
	if global_row:
		detail_text = "N1 %d • N2 %d • N3 %d" % [
			int(data.get("n1", 0)),
			int(data.get("n2", 0)),
			int(data.get("n3", 0))
		]
	else:
		detail_text = "%d insignias" % int(data.get("badges", 0))
	var detail := UIFactory.label(detail_text, Rect2(585, 8, 170, 28), 13, UIFactory.PALETTE.muted)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	card.add_child(detail)
	rows_box.add_child(card)

func _add_admin_row(data: Dictionary) -> void:
	var player_id: String = str(data.get("id_jugador", ""))
	var alias_value: String = str(data.get("alias", "JUGADOR"))
	var points: int = int(data.get("puntaje", 0))
	var is_test: bool = bool(data.get("es_prueba", false))
	var hidden: bool = bool(data.get("oculto_ranking", false))

	var border: Color = UIFactory.PALETTE.purple if is_test else Color("33415c")
	var card := UIFactory.panel(Rect2(0, 0, 780, 68), Color("101c35"), border, 8)
	card.custom_minimum_size = Vector2(780, 68)
	card.add_child(UIFactory.label(alias_value, Rect2(16, 7, 190, 25), 15, UIFactory.PALETTE.text))
	card.add_child(UIFactory.label(player_id, Rect2(16, 34, 285, 22), 11, UIFactory.PALETTE.muted))

	var pts := UIFactory.label("%d pts" % points, Rect2(205, 18, 100, 28), 14, UIFactory.PALETTE.yellow)
	pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	card.add_child(pts)

	var test_text: String = "HACER REAL" if is_test else "PRUEBA"
	var test_color: Color = UIFactory.PALETTE.purple if not is_test else Color("253959")
	var test_button := UIFactory.button(test_text, Rect2(320, 13, 125, 40), test_color)
	test_button.pressed.connect(_emit_admin_test.bind(player_id, not is_test))
	card.add_child(test_button)

	var hidden_text: String = "MOSTRAR" if hidden else "OCULTAR"
	var hidden_button := UIFactory.button(hidden_text, Rect2(455, 13, 125, 40), Color("253959"))
	hidden_button.pressed.connect(_emit_admin_hidden.bind(player_id, not hidden))
	card.add_child(hidden_button)

	var delete_text: String = "CONFIRMAR" if delete_candidate_id == player_id else "BORRAR"
	var delete_button := UIFactory.button(delete_text, Rect2(590, 13, 170, 40), UIFactory.PALETTE.red)
	delete_button.pressed.connect(_request_delete.bind(player_id))
	card.add_child(delete_button)
	rows_box.add_child(card)

func _request_delete(player_id: String) -> void:
	if delete_candidate_id != player_id:
		delete_candidate_id = player_id
		status_label.text = "Pulsa CONFIRMAR para borrar ranking, intentos y respuestas de ese jugador."
		admin_refresh_requested.emit()
		return
	delete_candidate_id = ""
	show_admin_loading("Eliminando datos del jugador...")
	admin_delete_requested.emit(player_id)

func _build() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UIFactory.make_theme()
	root.visible = false
	add_child(root)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = UIFactory.PALETTE.bg
	root.add_child(bg)

	var stage := UIFactory.stage(root)
	title_label = UIFactory.title("RANKING LOCAL", Rect2(100, 38, 1080, 50), 30, UIFactory.PALETTE.yellow)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage.add_child(title_label)

	local_button = UIFactory.button("LOCAL", Rect2(285, 100, 150, 42), Color("253959"))
	local_button.pressed.connect(_show_local)
	stage.add_child(local_button)

	global_button = UIFactory.button("GLOBAL", Rect2(455, 100, 150, 42), Color("256ec0"), "trophy")
	global_button.pressed.connect(_select_global)
	stage.add_child(global_button)

	connect_button = UIFactory.button("CONECTAR", Rect2(625, 100, 170, 42), UIFactory.PALETTE.green)
	connect_button.visible = false
	connect_button.pressed.connect(_request_global)
	stage.add_child(connect_button)

	admin_button = UIFactory.button("ADMIN", Rect2(815, 100, 180, 42), UIFactory.PALETTE.purple)
	admin_button.visible = false
	admin_button.pressed.connect(_on_admin_button_pressed)
	stage.add_child(admin_button)

	status_label = UIFactory.label("Datos guardados en este computador.", Rect2(200, 151, 880, 28), 13, UIFactory.PALETTE.muted)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage.add_child(status_label)

	var muted: Color = UIFactory.PALETTE.muted
	stage.add_child(UIFactory.label("POS.", Rect2(250 + 48, 190, 60, 24), 13, muted))
	stage.add_child(UIFactory.label("JUGADOR", Rect2(250 + 105, 190, 300, 24), 13, muted))
	var h_pts := UIFactory.label("PUNTOS", Rect2(250 + 420, 190, 150, 24), 13, muted)
	h_pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stage.add_child(h_pts)
	var h_badges := UIFactory.label("DETALLE", Rect2(250 + 565, 190, 190, 24), 13, muted)
	h_badges.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stage.add_child(h_badges)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(250, 220)
	scroll.size = Vector2(800, 355)
	stage.add_child(scroll)

	rows_box = VBoxContainer.new()
	rows_box.custom_minimum_size = Vector2(780, 0)
	rows_box.add_theme_constant_override("separation", 8)
	scroll.add_child(rows_box)

	var back := UIFactory.button("VOLVER", Rect2(70, 635, 180, 44), Color("253959"))
	back.pressed.connect(func(): back_requested.emit())
	stage.add_child(back)
