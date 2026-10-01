extends RefCounted

static func panel(rect: Rect2, bg: Color, border: Color) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	node.add_theme_stylebox_override("panel", style)
	return node

static func label(text_value: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var node := Label.new()
	node.text = text_value
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	return node

static func button(text_value: String, rect: Rect2, bg: Color) -> Button:
	var node := Button.new()
	node.text = text_value
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_size_override("font_size", 16)
	node.add_theme_color_override("font_color", Color("f3f8ff"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = bg.lightened(0.28)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(9)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.12)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.12)
	node.add_theme_stylebox_override("normal", normal)
	node.add_theme_stylebox_override("hover", hover)
	node.add_theme_stylebox_override("pressed", pressed)
	return node
