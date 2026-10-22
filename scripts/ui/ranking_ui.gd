extends CanvasLayer

signal back_requested
signal global_connect_requested

const UIFactory = preload("res://scripts/ui/ui_factory.gd")

var root: Control
var rows_box: VBoxContainer
var title_label: Label
var status_label: Label
var local_button: Button
var global_button: Button
var connect_button: Button
var session_manager_ref
var mode: String = "local"

func _ready() -> void:
	layer = 22
	_build()

func show_ranking(session_manager) -> void:
	session_manager_ref = session_manager
	root.visible = true
	_show_local()

func hide_ranking() -> void:
	root.visible = false

func show_global_loading() -> void:
	mode = "global"
	_clear_rows()
	title_label.text = "RANKING GLOBAL"
	status_label.text = "Conectando con Google Sheets..."
	connect_button.visible = true
	connect_button.disabled = true
	connect_button.text = "CONECTANDO..."
	_add_message("Sincronizando resultados pendientes y descargando el Top 10.")

func show_global_ranking(rows: Array) -> void:
	mode = "global"
	_clear_rows()
	title_label.text = "RANKING GLOBAL"
	status_label.text = "Conectado • Top 10 global"
	connect_button.visible = true
	connect_button.disabled = false
	connect_button.text = "ACTUALIZAR"

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
	_add_message(message)

func _show_local() -> void:
	mode = "local"
	_clear_rows()
	title_label.text = "RANKING LOCAL"
	status_label.text = "Datos guardados en este computador."
	connect_button.visible = false
	connect_button.disabled = false
	connect_button.text = "CONECTAR"

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
	_clear_rows()
	title_label.text = "RANKING GLOBAL"
	status_label.text = "Ranking global desconectado."
	connect_button.visible = true
	connect_button.disabled = false
	connect_button.text = "CONECTAR"
	_add_message("Pulsa CONECTAR para consultar el Top 10. No se realizan consultas automáticas.")

func _request_global() -> void:
	show_global_loading()
	global_connect_requested.emit()

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

	local_button = UIFactory.button("LOCAL", Rect2(355, 100, 170, 42), Color("253959"))
	local_button.pressed.connect(_show_local)
	stage.add_child(local_button)

	global_button = UIFactory.button("GLOBAL", Rect2(555, 100, 170, 42), Color("256ec0"), "trophy")
	global_button.pressed.connect(_select_global)
	stage.add_child(global_button)

	connect_button = UIFactory.button("CONECTAR", Rect2(755, 100, 170, 42), UIFactory.PALETTE.green)
	connect_button.visible = false
	connect_button.pressed.connect(_request_global)
	stage.add_child(connect_button)

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
