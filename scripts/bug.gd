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
	title_label = Label.new()
	title_label.position = Vector2(-105, -88)
	title_label.size = Vector2(210, 28)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color("e8f0ff"))
	add_child(title_label)
	rows_label = Label.new()
	rows_label.position = Vector2(-105, 54)
	rows_label.size = Vector2(210, 42)
	rows_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows_label.add_theme_font_size_override("font_size", 12)
	rows_label.add_theme_color_override("font_color", Color("ffd447"))
	add_child(rows_label)
	_update_labels()

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
