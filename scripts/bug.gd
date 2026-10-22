extends Node2D

const BUG_TEXTURES: Array[Texture2D] = [
	preload("res://assets/enemies/virus_1.png"),
	preload("res://assets/enemies/virus_2.png"),
	preload("res://assets/enemies/virus_3.png"),
	preload("res://assets/enemies/virus_4.png")
]

var zone_index: int = 0
var rows_left: int = 0
var rows_total: int = 0
var active: bool = true
var zone_name: String = "ZONA"
var difficulty: String = "Fácil"
var title_label: Label
var rows_label: Label
var bug_texture: Texture2D

func setup(index: int, name_value: String, difficulty_value: String, total: int, remaining: int) -> void:
	zone_index = index
	zone_name = name_value
	difficulty = difficulty_value
	rows_total = total
	rows_left = remaining
	active = rows_left > 0
	name = "BugZone%d" % index
	bug_texture = BUG_TEXTURES[index % BUG_TEXTURES.size()]
	_build_labels()
	queue_redraw()

func _build_labels() -> void:
	# Las etiquetas van DEBAJO del guardián: arriba las tapaba la barra del HUD.
	# Borde oscuro para que se lean sobre el fondo claro o rosado de la página.
	title_label = _make_label(Vector2(-130, 60), Vector2(260, 26), 17, Color("ffffff"))
	rows_label = _make_label(Vector2(-130, 86), Vector2(260, 24), 14, Color("ffd447"))
	_update_labels()

func _make_label(pos: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = label_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("07101d"))
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	return label

func set_rows(remaining: int) -> void:
	rows_left = maxi(0, remaining)
	active = rows_left > 0
	visible = active
	_update_labels()
	queue_redraw()

func _update_labels() -> void:
	if title_label:
		title_label.text = "%s • %s" % [zone_name, difficulty]
	if rows_label:
		rows_label.text = "%d FILA(S) RESTANTE(S)" % rows_left

func _draw() -> void:
	if not active:
		return
	draw_circle(Vector2.ZERO, 50, Color(1.0, 0.15, 0.38, 0.16))
	if bug_texture:
		draw_texture_rect(bug_texture, Rect2(-48, -48, 96, 96), false)
	var ratio := float(rows_left) / float(maxi(1, rows_total))
	draw_rect(Rect2(-42, 45, 84, 8), Color("18243a"), true)
	draw_rect(Rect2(-42, 45, 84.0 * ratio, 8), Color("ffd447"), true)
