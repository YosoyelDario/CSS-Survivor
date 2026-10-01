extends Node2D

signal defeated(zone_index: int)

const BUG_TEXTURES: Array[Texture2D] = [
	preload("res://assets/enemies/virus_1.png"),
	preload("res://assets/enemies/virus_2.png"),
	preload("res://assets/enemies/virus_3.png"),
	preload("res://assets/enemies/virus_4.png")
]

var zone_index: int = 0
var hp: int = 3
var max_hp: int = 3
var failures: int = 0
var active: bool = true
var title_label: Label
var bug_texture: Texture2D

func setup(index: int, zone_name: String) -> void:
	zone_index = index
	name = "BugZone%d" % index
	bug_texture = BUG_TEXTURES[index % BUG_TEXTURES.size()]

	title_label = Label.new()
	title_label.text = zone_name
	title_label.position = Vector2(-70, -72)
	title_label.size = Vector2(140, 30)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", Color("ffb3c7"))
	add_child(title_label)
	_update_label()
	queue_redraw()

func hit() -> bool:
	if not active:
		return false
	hp = max(0, hp - 1)
	_update_label()
	queue_redraw()
	if hp <= 0:
		active = false
		hide()
		defeated.emit(zone_index)
		return true
	return false

func _update_label() -> void:
	if title_label:
		title_label.text = "BUG • %d/%d" % [hp, max_hp]

func _draw() -> void:
	if not active:
		return

	# Aura/selección del enemigo. El dibujo principal viene del PNG externo.
	draw_circle(Vector2.ZERO, 46, Color(1.0, 0.15, 0.38, 0.13))
	if bug_texture:
		draw_texture_rect(bug_texture, Rect2(-48, -48, 96, 96), false)

	# Barra de HP se mantiene en código para que responda a la lógica del juego.
	draw_rect(Rect2(-38, 45, 76, 8), Color("23152e"), true)
	var ratio := 0.0
	if max_hp > 0:
		ratio = float(hp) / float(max_hp)
	draw_rect(Rect2(-38, 45, 76 * ratio, 8), Color("ffd447"), true)
