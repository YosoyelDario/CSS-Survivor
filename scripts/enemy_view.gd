extends Control

const VIRUS_TEXTURES: Array[Texture2D] = [
	preload("res://assets/enemies/virus_1.png"),
	preload("res://assets/enemies/virus_2.png"),
	preload("res://assets/enemies/virus_3.png"),
	preload("res://assets/enemies/virus_4.png")
]

var enemy_id: int = 0
var lane: int = 0
var source_row: int = 0
var depth: int = 0
var halo: Panel
var frame: Panel
var sprite: TextureRect
var bug_label: Label
var mark_label: Label
var mark_mode: String = "none"

func setup(data: Dictionary, row_depth: int) -> void:
	enemy_id = int(data.get("id", 0))
	lane = int(data.get("lane", 0))
	source_row = int(data.get("source_row", 0))
	depth = row_depth
	custom_minimum_size = Vector2(92, 92)
	size = Vector2(92, 92)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_layers()
	set_depth(row_depth)

func _build_layers() -> void:
	halo = Panel.new()
	halo.position = Vector2(6, 6)
	halo.size = Vector2(80, 80)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(halo)
	_set_panel_style(halo, Color(0.1, 0.8, 1.0, 0.0), Color(0.3, 0.4, 0.55, 0.15), 2, 40)

	frame = Panel.new()
	frame.position = Vector2(8, 8)
	frame.size = Vector2(76, 76)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	_set_panel_style(frame, Color(0, 0, 0, 0), Color(0.55, 0.65, 0.78, 0.45), 2, 12)

	sprite = TextureRect.new()
	sprite.position = Vector2(14, 10)
	sprite.size = Vector2(64, 64)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sprite)

	bug_label = Label.new()
	bug_label.text = "BUG"
	bug_label.position = Vector2(8, 68)
	bug_label.size = Vector2(76, 20)
	bug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bug_label.add_theme_font_size_override("font_size", 12)
	bug_label.add_theme_color_override("font_color", Color("d7e1f3"))
	bug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bug_label)

	mark_label = Label.new()
	mark_label.position = Vector2(-10, -17)
	mark_label.size = Vector2(112, 20)
	mark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark_label.add_theme_font_size_override("font_size", 10)
	mark_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mark_label)

func set_depth(row_depth: int) -> void:
	depth = row_depth
	var texture_index := 0
	match depth:
		0:
			texture_index = 0
		1:
			texture_index = 2
		2:
			texture_index = 1
		_:
			texture_index = 3
	sprite.texture = VIRUS_TEXTURES[texture_index]

func set_mark(mode: String) -> void:
	mark_mode = mode
	if mode == "target":
		_set_panel_style(frame, Color(0, 0, 0, 0), Color("20c7f3"), 4, 14)
		mark_label.text = "OBJETIVO"
		mark_label.add_theme_color_override("font_color", Color("20c7f3"))
	elif mode == "neighbor":
		_set_panel_style(frame, Color(0, 0, 0, 0), Color(0.12, 0.78, 0.95, 0.45), 2, 14)
		mark_label.text = "ALCANCE"
		mark_label.add_theme_color_override("font_color", Color("7be4ff"))
	else:
		_set_panel_style(frame, Color(0, 0, 0, 0), Color(0.55, 0.65, 0.78, 0.45), 2, 12)
		mark_label.text = ""

func apply_effects(effects: Array) -> void:
	for effect in effects:
		var property_name := str(effect.get("property", ""))
		var value := str(effect.get("value", ""))
		match property_name:
			"color":
				bug_label.add_theme_color_override("font_color", _css_color(value))
			"background-color":
				_set_panel_style(halo, Color(_css_color(value), 0.35), Color(_css_color(value), 0.7), 2, 40)
			"border-color":
				_set_panel_style(frame, Color(0, 0, 0, 0), _css_color(value), 5, 14)
			"font-size":
				var amount := value.trim_suffix("px").to_int()
				bug_label.add_theme_font_size_override("font_size", clampi(amount, 9, 28))
			"opacity":
				modulate.a = clampf(value.to_float(), 0.15, 1.0)
			"":
				pass
			_:
				push_warning("Efecto CSS visual todavía no implementado: %s" % property_name)

func animate_spawn() -> void:
	modulate.a = 0.0
	scale = Vector2(0.75, 0.75)
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.22)
	tween.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished

func animate_die() -> void:
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.28)
	tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.28).set_trans(Tween.TRANS_BACK)
	await tween.finished

func _set_panel_style(node: Panel, bg: Color, border: Color, width: int, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	node.add_theme_stylebox_override("panel", style)

func _css_color(value: String) -> Color:
	var colors := {
		"red": Color("ff5777"), "blue": Color("20c7f3"), "green": Color("36d98b"),
		"yellow": Color("ffd447"), "black": Color("111827"), "white": Color("f8fbff"),
		"orange": Color("ff7a36"), "purple": Color("8a5cf6"), "pink": Color("ff7eb6")
	}
	return colors.get(value.to_lower(), Color("d7e1f3"))
