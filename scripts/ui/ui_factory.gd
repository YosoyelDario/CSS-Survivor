extends RefCounted

const PALETTE := {
	"bg": Color("080d22"), "panel": Color("0d172b"), "panel2": Color("101c35"),
	"cyan": Color("20c7f3"), "orange": Color("ff7a36"), "red": Color("ff5777"),
	"green": Color("36d98b"), "yellow": Color("ffd447"), "purple": Color("8a5cf6"),
	"text": Color("e8f0ff"), "muted": Color("9aa7c4")
}

static var _icon_cache: Dictionary = {}

static func make_theme() -> Theme:
	var theme := Theme.new()
	if FileAccess.file_exists("res://assets/fonts/Rajdhani-Regular.ttf"):
		var font = load("res://assets/fonts/Rajdhani-Regular.ttf")
		if font != null:
			theme.default_font = font
	theme.default_font_size = 16
	return theme

static func title_font():
	if FileAccess.file_exists("res://assets/fonts/PressStart2P-Regular.ttf"):
		return load("res://assets/fonts/PressStart2P-Regular.ttf")
	return null

static func mono_font():
	if FileAccess.file_exists("res://assets/fonts/JetBrainsMono-Regular.ttf"):
		return load("res://assets/fonts/JetBrainsMono-Regular.ttf")
	return null

static func panel(rect: Rect2, bg: Color = PALETTE.panel, border: Color = Color("294461"), radius: int = 12) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	node.add_theme_stylebox_override("panel", style_box(bg, border, 2, radius))
	return node

static func style_box(bg: Color, border: Color, width: int = 2, radius: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func label(text_value: String, rect: Rect2, font_size: int = 16, color: Color = PALETTE.text) -> Label:
	var node := Label.new()
	node.text = text_value
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node

static func title(text_value: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var node := label(text_value, rect, font_size, color)
	var font = title_font()
	if font != null:
		node.add_theme_font_override("font", font)
	return node

static func code_label(text_value: String, rect: Rect2, font_size: int = 15) -> Label:
	var node := label(text_value, rect, font_size, Color("d8f5e7"))
	var font = mono_font()
	if font != null:
		node.add_theme_font_override("font", font)
	return node

static func button(text_value: String, rect: Rect2, bg: Color = Color("17304c"), icon_name: String = "") -> Button:
	var node := Button.new()
	node.text = text_value
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_size_override("font_size", 16)
	node.add_theme_color_override("font_color", PALETTE.text)
	node.add_theme_color_override("font_hover_color", Color.WHITE)
	node.add_theme_stylebox_override("normal", style_box(bg, bg.lightened(0.22), 2, 10))
	node.add_theme_stylebox_override("hover", style_box(bg.lightened(0.1), PALETTE.cyan, 2, 10))
	node.add_theme_stylebox_override("pressed", style_box(bg.darkened(0.14), Color.WHITE, 2, 10))
	node.add_theme_stylebox_override("disabled", style_box(Color("151c2c"), Color("293249"), 2, 10))
	if not icon_name.is_empty():
		node.icon = icon_texture(icon_name)
		node.expand_icon = false
	return node

static func chip(text_value: String, color: Color) -> Label:
	var node := Label.new()
	node.text = text_value
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.custom_minimum_size = Vector2(120, 28)
	node.add_theme_font_size_override("font_size", 12)
	node.add_theme_color_override("font_color", Color.WHITE)
	node.add_theme_stylebox_override("normal", style_box(Color(color, 0.18), color, 1, 10))
	return node

static func progress(rect: Rect2, color: Color = PALETTE.green) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = rect.position
	bar.size = rect.size
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 0
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", style_box(Color("17233a"), Color("2b3b58"), 1, 7))
	bar.add_theme_stylebox_override("fill", style_box(color, color, 0, 7))
	return bar

static func icon_rect(name: String, rect: Rect2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = icon_texture(name)
	node.position = rect.position
	node.size = rect.size
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func icon_texture(name: String) -> Texture2D:
	if _icon_cache.has(name):
		return _icon_cache[name]
	var path := "res://assets/ui/%s.png" % name
	if FileAccess.file_exists(path):
		var tex = load(path)
		if tex is Texture2D:
			_icon_cache[name] = tex
			return tex
	# DECISIÓN: la base entregada no incluye assets/ui; se generan íconos pixel-art en memoria sin modificar assets/.
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_draw_fallback_icon(image, name)
	var texture := ImageTexture.create_from_image(image)
	_icon_cache[name] = texture
	return texture

static func _draw_fallback_icon(image: Image, name: String) -> void:
	var c := PALETTE.text
	if name == "heart" or name == "heart_empty":
		c = PALETTE.red if name == "heart" else Color("53617b")
		var pixels := [Vector2i(3,3),Vector2i(4,2),Vector2i(5,2),Vector2i(6,3),Vector2i(7,4),Vector2i(8,3),Vector2i(9,2),Vector2i(10,2),Vector2i(11,3)]
		for p in pixels:
			image.set_pixelv(p,c)
		for y in range(4,10):
			var inset := floori(float(y - 4) / 3.0)
			for x in range(2 + inset, 14 - inset):
				image.set_pixel(x,y,c)
		for y in range(10,14):
			for x in range(5 + (y-10), 11 - (y-10)):
				image.set_pixel(x,y,c)
	elif name == "star":
		c = PALETTE.yellow
		for p in [Vector2i(8,1),Vector2i(7,2),Vector2i(8,2),Vector2i(9,2),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,5),Vector2i(7,4),Vector2i(8,3),Vector2i(9,4),Vector2i(10,5),Vector2i(11,6),Vector2i(12,6),Vector2i(13,6),Vector2i(8,7),Vector2i(7,8),Vector2i(6,9),Vector2i(5,10),Vector2i(6,10),Vector2i(7,10),Vector2i(8,12),Vector2i(9,10),Vector2i(10,10),Vector2i(11,10),Vector2i(10,9),Vector2i(9,8)]:
			image.set_pixelv(p,c)
	elif name == "check":
		c = PALETTE.green
		for i in range(4):
			image.set_pixel(3+i,8+i,c)
		for i in range(7):
			image.set_pixel(6+i,11-i,c)
	elif name == "cross":
		c = PALETTE.red
		for i in range(9):
			image.set_pixel(3+i,3+i,c); image.set_pixel(11-i,3+i,c)
	elif name == "lock":
		c = PALETTE.muted
		for x in range(4,12):
			for y in range(7,14):
				image.set_pixel(x,y,c)
		for x in range(6,10):
			image.set_pixel(x,4,c)
		image.set_pixel(5,5,c); image.set_pixel(10,5,c); image.set_pixel(5,6,c); image.set_pixel(10,6,c)
	elif name == "play":
		c = PALETTE.orange
		for x in range(4,12):
			var half := 4 - absi(8-x)
			for y in range(8-half,9+half):
				image.set_pixel(x,y,c)
	elif name == "trophy" or name == "medal" or name == "medal_locked":
		c = PALETTE.yellow if name != "medal_locked" else Color("53617b")
		for x in range(4,12):
			for y in range(3,9):
				image.set_pixel(x,y,c)
		for x in range(7,9):
			for y in range(9,13):
				image.set_pixel(x,y,c)
		for x in range(5,11):
			image.set_pixel(x,13,c)
	else:
		for x in range(4,12):
			for y in range(4,12):
				image.set_pixel(x,y,c)
