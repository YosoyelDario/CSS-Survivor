extends RefCounted

<<<<<<< Updated upstream
static func panel(rect: Rect2, bg: Color, border: Color) -> Panel:
=======
# --- Fuentes (D3/D4): Cinzel para títulos, Lato para todo el resto. ---
# Los archivos deben estar en assets/fonts/ con estos nombres exactos.
const FONT_BODY_PATH := "res://assets/fonts/Lato-Regular.ttf"
const FONT_BODY_BOLD_PATH := "res://assets/fonts/Lato-Bold.ttf"
const FONT_TITLE_PATH := "res://assets/fonts/Cinzel-Bold.ttf"

# Texto de las preguntas del combate: más grande y más claro que el texto normal.
const QUESTION_SIZE := 24
const QUESTION_COLOR := Color("f7faff")

const PALETTE := {
	"bg": Color("080d22"), "panel": Color("0d172b"), "panel2": Color("101c35"),
	"cyan": Color("20c7f3"), "orange": Color("ff7a36"), "red": Color("ff5777"),
	"green": Color("36d98b"), "yellow": Color("ffd447"), "purple": Color("8a5cf6"),
	"text": Color("e8f0ff"), "muted": Color("9aa7c4"), "question": QUESTION_COLOR
}

# --- Escenario de diseño ---
# El proyecto usa 1920x1080, pero las pantallas están diseñadas en coordenadas de 1280x720.
# 1920/1280 = 1080/720 = 1.5: cada pantalla pone su contenido dentro de un "escenario" de
# 1280x720 escalado 1.5x, que ocupa justo toda la ventana. Los fondos a pantalla completa
# se agregan directamente al root (sin escenario) para que cubran los 1920x1080.
const DESIGN_SIZE := Vector2(1280, 720)
const STAGE_SCALE := 1.5

static var _icon_cache: Dictionary = {}
static var _font_cache: Dictionary = {}

# Carga una fuente una sola vez. Devuelve null si el archivo no existe,
# y en ese caso Godot usa su fuente predeterminada (el juego no se rompe).
# Se usa ResourceLoader.exists (y no FileAccess) porque en un juego exportado
# el .ttf original ya no está en el paquete, solo su versión importada.
static func _load_font(path: String):
	if _font_cache.has(path):
		return _font_cache[path]
	var font = null
	if ResourceLoader.exists(path):
		font = load(path)
	else:
		push_warning("Fuente no encontrada: %s (se usa la fuente por defecto)" % path)
	_font_cache[path] = font
	return font

static func make_theme() -> Theme:
	var theme := Theme.new()
	var font = body_font()
	if font != null:
		theme.default_font = font
	theme.default_font_size = 16
	return theme

# Crea el escenario 1280x720 (escalado 1.5x) dentro de `parent` y lo devuelve.
# Todo el contenido de una pantalla va dentro de este nodo, con coordenadas de 1280x720.
static func stage(parent: Node) -> Control:
	var node := Control.new()
	node.name = "Stage"
	node.size = DESIGN_SIZE
	node.scale = Vector2(STAGE_SCALE, STAGE_SCALE)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

# Texto general: Lato Regular.
static func body_font():
	return _load_font(FONT_BODY_PATH)

# Énfasis dentro del texto general: Lato Bold.
static func body_bold_font():
	return _load_font(FONT_BODY_BOLD_PATH)

# Títulos: Cinzel Bold.
static func title_font():
	return _load_font(FONT_TITLE_PATH)

# DECISIÓN D4: por ahora el código CSS también va en Lato.
# Se mantiene el nombre mono_font() porque combat_ui.gd y code_label() lo llaman.
# Si más adelante se prefiere una monoespaciada, solo hay que cambiar esta función.
static func mono_font():
	return body_font()

static func panel(rect: Rect2, bg: Color = PALETTE.panel, border: Color = Color("294461"), radius: int = 12) -> Panel:
>>>>>>> Stashed changes
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
	# ORDEN IMPORTANTE (corrección de desborde de textos):
	# Godot no deja que un Control sea más chico que su tamaño mínimo. Un Label sin
	# autowrap tiene como mínimo el ancho de todo su texto en una sola línea, así que
	# si se asigna primero el texto y el tamaño, la caja crece hasta ese ancho y
	# después ya no se achica aunque se active el autowrap.
	# Por eso: 1) autowrap, 2) tamaño y posición, 3) recién al final el texto.
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
<<<<<<< Updated upstream
=======
	node.position = rect.position
	node.size = rect.size
	node.text = text_value
	return node

# Etiqueta para el enunciado de una pregunta: Lato, grande y de color claro.
static func question_label(text_value: String, rect: Rect2) -> Label:
	var node := label(text_value, rect, QUESTION_SIZE, QUESTION_COLOR)
	var font = body_font()
	if font != null:
		node.add_theme_font_override("font", font)
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
=======

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
	return texture_rect(icon_texture(name), rect)

# Crea un TextureRect con el tamaño pedido, sin que la imagen lo agrande.
# ORDEN IMPORTANTE: expand_mode IGNORE_SIZE va ANTES de asignar textura y tamaño.
# Si no, el tamaño mínimo es el de la imagen (ej. 2200x1400 en los fondos, 96x96 en
# los sprites) y Godot ignora el tamaño pedido. Usar siempre este helper para imágenes.
static func texture_rect(tex: Texture2D, rect: Rect2, stretch: int = TextureRect.STRETCH_KEEP_ASPECT_CENTERED) -> TextureRect:
	var node := TextureRect.new()
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = stretch
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.texture = tex
	# Tamaño mínimo = tamaño pedido: sin esto, dentro de un HBox/VBox (corazones del HUD) la
	# imagen se colapsa a 0 px porque EXPAND_IGNORE_SIZE le quita el mínimo propio de la textura.
	node.custom_minimum_size = rect.size
	node.position = rect.position
	node.size = rect.size
	return node

static func icon_texture(name: String) -> Texture2D:
	if _icon_cache.has(name):
		return _icon_cache[name]
	var path := "res://assets/ui/%s.png" % name
	if ResourceLoader.exists(path):
		var tex = load(path)
		if tex is Texture2D:
			_icon_cache[name] = tex
			return tex
	# DECISIÓN: la base entregada no incluye assets/ui; se generan íconos pixel-art en memoria.
	# Se dibujan en una grilla de 16x16 y se amplían 2x (sin suavizar) a 32x32 para que se vean
	# nítidos dentro de botones y tarjetas. Para usar arte real, basta dejar un PNG en assets/ui/.
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_draw_fallback_icon(image, name)
	image.resize(32, 32, Image.INTERPOLATE_NEAREST)
	var texture := ImageTexture.create_from_image(image)
	_icon_cache[name] = texture
	return texture

static func _rect(image: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if xx >= 0 and xx < 16 and yy >= 0 and yy < 16:
				image.set_pixel(xx, yy, c)

static func _draw_trophy(image: Image) -> void:
	var gold := Color("ffd447")
	var dark := Color("d9a521")
	var light := Color("fff0a8")
	_rect(image, 3, 1, 10, 2, gold)       # borde de la copa
	_rect(image, 4, 3, 8, 3, gold)        # cuerpo
	_rect(image, 5, 6, 6, 2, gold)
	_rect(image, 6, 8, 4, 1, gold)
	_rect(image, 10, 3, 2, 5, dark)       # sombra derecha
	_rect(image, 5, 3, 1, 3, light)       # brillo
	for p in [Vector2i(1,2),Vector2i(2,2),Vector2i(1,3),Vector2i(1,4),Vector2i(1,5),Vector2i(2,6),Vector2i(3,6)]:
		image.set_pixel(p.x, p.y, gold)             # asa izquierda
		image.set_pixel(15 - p.x, p.y, gold)        # asa derecha (espejo)
	_rect(image, 7, 9, 2, 2, dark)        # pie
	_rect(image, 5, 11, 6, 1, gold)
	_rect(image, 4, 12, 8, 2, dark)       # base

static func _draw_medal(image: Image, locked: bool) -> void:
	var gold := Color("ffd447") if not locked else Color("53617b")
	var dark := Color("d9a521") if not locked else Color("3b475e")
	var light := Color("fff0a8") if not locked else Color("7a88a3")
	var red := Color("ff5777") if not locked else Color("46526a")
	var blue := Color("20c7f3") if not locked else Color("46526a")
	_rect(image, 4, 0, 3, 6, red)         # cinta
	_rect(image, 9, 0, 3, 6, blue)
	for y in range(5, 16):
		for x in range(16):
			var d := Vector2(x - 7.5, y - 10.0).length()
			if d <= 5.2:
				image.set_pixel(x, y, dark if d > 4.0 else gold)
	_rect(image, 7, 8, 2, 5, light)       # estrella simple (cruz)
	_rect(image, 5, 10, 6, 1, light)

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
		# Estrella de 5 puntas: se rellena probando cada píxel contra el polígono.
		var poly := PackedVector2Array()
		for i in range(10):
			var radius := 7.4 if i % 2 == 0 else 3.1
			var ang := -PI / 2.0 + float(i) * PI / 5.0
			poly.append(Vector2(8.0 + cos(ang) * radius, 8.6 + sin(ang) * radius))
		for y in range(16):
			for x in range(16):
				if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), poly):
					image.set_pixel(x, y, PALETTE.yellow)
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
		c = Color("fff5e8")
		for x in range(4,12):
			var half := roundi(float(11 - x) * 4.0 / 7.0)
			for y in range(8-half,9+half):
				image.set_pixel(x,y,c)
	elif name == "trophy":
		_draw_trophy(image)
	elif name == "medal" or name == "medal_locked":
		_draw_medal(image, name == "medal_locked")
	else:
		for x in range(4,12):
			for y in range(4,12):
				image.set_pixel(x,y,c)
>>>>>>> Stashed changes
