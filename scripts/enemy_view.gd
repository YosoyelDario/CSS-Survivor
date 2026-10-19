extends Control

# Enemigo visual. Siguiendo la Guía Visual de propiedades CSS, cada propiedad controla una capa propia:
#   color            -> color del texto de la etiqueta ("BUG")
#   background-color -> aura/halo detrás del enemigo
#   border-color     -> color del contorno
#   border           -> grosor y color del contorno
#   border-radius    -> forma de la silueta (cuadrado -> redondeado -> círculo)
#   padding          -> espacio interno ("volumen" entre el borde y el núcleo)
#   margin           -> caja de margen exterior (el grupo se separa en la arena)
#   width / height   -> tamaño del cuerpo
#   transform        -> rotación del sprite completo (rotate)
#   font-size        -> tamaño de la etiqueta
#   opacity          -> transparencia
# Las propiedades de layout (flex-direction, justify-content, align-items, align-content, gap)
# no cambian al enemigo sino al grupo: las resuelve la arena con flex_layout.gd.

const VIRUS_TEXTURES: Array[Texture2D] = [
	preload("res://assets/enemies/virus_1.png"),
	preload("res://assets/enemies/virus_2.png"),
	preload("res://assets/enemies/virus_3.png"),
	preload("res://assets/enemies/virus_4.png")
]

const BASE_BODY := 76.0
const CENTER := Vector2(46, 46)
const DEFAULT_BORDER := Color(0.55, 0.65, 0.78, 0.45)
const DEFAULT_LABEL_COLOR := Color("d7e1f3")
const DEFAULT_HALO_BG := Color(0.1, 0.8, 1.0, 0.0)
const DEFAULT_HALO_BORDER := Color(0.3, 0.4, 0.55, 0.15)
const SIZE_FACTOR := 0.95            # px de CSS -> px de pantalla
const GROUP_PROPERTIES := ["flex-direction", "justify-content", "align-items", "align-content", "gap"]
# Propiedades CSS que el juego sabe mostrar; tests/model_smoke_test.gd verifica que todo el banco de
# ejercicios use solo estas.
const SUPPORTED_PROPERTIES := ["color", "background-color", "border-color", "border", "border-radius", "padding", "margin",
	"width", "height", "transform", "font-size", "opacity", "flex-direction", "justify-content", "align-items", "align-content", "gap"]

var enemy_id: int = 0
var lane: int = 0
var source_row: int = 0
var depth: int = 0
var halo: Panel
var margin_box: Panel
var frame: Panel
var core: Panel
var sprite: TextureRect
var bug_label: Label
var mark_label: Label
var mark_mode: String = "none"

# Estilo base del nivel (por ejemplo, en el Nivel 2 las esquinas parten cuadradas).
var base_radius: float = 12.0
var base_border_width: float = 2.0

# Estado visual actual.
var body_w: float = BASE_BODY
var body_h: float = BASE_BODY
var radius_px: float = 12.0
var radius_pct: float = -1.0
var radius_explicit: bool = false
var border_w: float = 2.0
var border_color: Color = DEFAULT_BORDER
var border_explicit: bool = false
var padding_px: float = 0.0
var margin_px: float = 0.0
var halo_bg: Color = DEFAULT_HALO_BG
var halo_border: Color = DEFAULT_HALO_BORDER
var rotation_deg: float = 0.0
var _radius_override: float = -1.0
var _border_override: float = -1.0

func setup(data: Dictionary, row_depth: int) -> void:
	enemy_id = int(data.get("id", 0))
	lane = int(data.get("lane", 0))
	source_row = int(data.get("source_row", 0))
	depth = row_depth
	custom_minimum_size = Vector2(92, 92)
	size = Vector2(92, 92)
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_layers()
	set_depth(row_depth)
	_layout_layers()

func _make_panel() -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	return panel

func _build_layers() -> void:
	margin_box = _make_panel()
	halo = _make_panel()
	frame = _make_panel()
	core = _make_panel()

	sprite = TextureRect.new()
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sprite)

	bug_label = Label.new()
	bug_label.text = "BUG"
	bug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bug_label.add_theme_font_size_override("font_size", 12)
	bug_label.add_theme_color_override("font_color", DEFAULT_LABEL_COLOR)
	bug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bug_label)

	mark_label = Label.new()
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

# Estilo base de un nivel: {"radius": px, "border_width": px}. Reinicia al enemigo a ese estado.
func set_base_style(style: Dictionary) -> void:
	base_radius = float(style.get("radius", 12.0))
	base_border_width = float(style.get("border_width", 2.0))
	reset_style()

# Devuelve al enemigo a su aspecto base (sin efectos CSS aplicados).
func reset_style() -> void:
	body_w = BASE_BODY
	body_h = BASE_BODY
	radius_px = base_radius
	radius_pct = -1.0
	radius_explicit = false
	border_w = base_border_width
	border_color = DEFAULT_BORDER
	border_explicit = false
	padding_px = 0.0
	margin_px = 0.0
	halo_bg = DEFAULT_HALO_BG
	halo_border = DEFAULT_HALO_BORDER
	rotation_deg = 0.0
	rotation = 0.0
	_radius_override = -1.0
	_border_override = -1.0
	modulate.a = 1.0
	scale = Vector2.ONE
	if bug_label != null:
		bug_label.add_theme_color_override("font_color", DEFAULT_LABEL_COLOR)
		bug_label.add_theme_font_size_override("font_size", 12)
	if frame != null:
		_layout_layers()

func set_mark(mode: String) -> void:
	mark_mode = mode
	if mode == "target":
		mark_label.text = "OBJETIVO"
		mark_label.add_theme_color_override("font_color", Color("20c7f3"))
	elif mode == "neighbor":
		mark_label.text = "ALCANCE"
		mark_label.add_theme_color_override("font_color", Color("7be4ff"))
	else:
		mark_label.text = ""
	_layout_layers()

# Aplica efectos CSS. Con animate=true los cambios de tamaño, forma, borde, espacio y giro se interpolan.
func apply_effects(effects: Array, animate: bool = false) -> void:
	var from := _snapshot()
	var target_rotation := rotation_deg
	for effect_value in effects:
		var effect: Dictionary = effect_value as Dictionary
		var property_name: String = str(effect.get("property", ""))
		var value: String = str(effect.get("value", ""))
		match property_name:
			"color":
				bug_label.add_theme_color_override("font_color", _css_color(value))
			"background-color":
				halo_bg = Color(_css_color(value), 0.35)
				halo_border = Color(_css_color(value), 0.7)
			"border-color":
				border_color = _css_color(value)
				border_w = 5.0
				border_explicit = true
				if base_radius > 0.0 and not radius_explicit:
					radius_px = 14.0
			"border":
				var parts: PackedStringArray = value.split(" ", false)
				for part in parts:
					if part.ends_with("px"):
						border_w = clampf(_px(part), 0.0, 12.0)
					elif part != "solid" and part != "dashed" and part != "dotted" and part != "double":
						border_color = _css_color(part)
				border_explicit = true
			"border-radius":
				radius_explicit = true
				if value.ends_with("%"):
					radius_pct = clampf(value.trim_suffix("%").to_float(), 0.0, 50.0)
				else:
					radius_pct = -1.0
					radius_px = maxf(0.0, _px(value))
			"padding":
				padding_px = maxf(0.0, _px(value))
			"margin":
				margin_px = maxf(0.0, _px(value))
			"width":
				body_w = clampf(_px(value) * SIZE_FACTOR, 30.0, 132.0)
			"height":
				body_h = clampf(_px(value) * SIZE_FACTOR, 30.0, 132.0)
			"transform":
				target_rotation = _rotation_of(value)
			"font-size":
				bug_label.add_theme_font_size_override("font_size", clampi(int(_px(value)), 9, 28))
			"opacity":
				modulate.a = clampf(value.to_float(), 0.15, 1.0)
			"":
				pass
			_:
				if not GROUP_PROPERTIES.has(property_name):
					push_warning("Efecto CSS visual todavía no implementado: %s" % property_name)
	var final_state := _snapshot()
	var changed: bool = from != final_state or not is_equal_approx(target_rotation, rotation_deg)
	rotation_deg = target_rotation
	if animate and changed and is_inside_tree():
		var tween := create_tween().set_parallel(true)
		tween.tween_method(_blend.bind(from, final_state), 0.0, 1.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "rotation", deg_to_rad(rotation_deg), 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_blend(0.0, from, final_state)
	else:
		rotation = deg_to_rad(rotation_deg)
		_layout_layers()

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
	tween.tween_property(self, "scale", scale * 1.35, 0.28).set_trans(Tween.TRANS_BACK)
	await tween.finished

# ----------------------------------------------------------------------------------------------
# Dibujo de las capas a partir del estado
# ----------------------------------------------------------------------------------------------

func _snapshot() -> Dictionary:
	return {"w": body_w, "h": body_h, "pad": padding_px, "mar": margin_px, "bw": _frame_border()["width"], "rad": _resolved_radius(body_w, body_h)}

func _blend(t: float, from: Dictionary, to: Dictionary) -> void:
	body_w = lerpf(float(from["w"]), float(to["w"]), t)
	body_h = lerpf(float(from["h"]), float(to["h"]), t)
	padding_px = lerpf(float(from["pad"]), float(to["pad"]), t)
	margin_px = lerpf(float(from["mar"]), float(to["mar"]), t)
	if t >= 1.0:
		_radius_override = -1.0
		_border_override = -1.0
	else:
		_radius_override = lerpf(float(from["rad"]), float(to["rad"]), t)
		_border_override = lerpf(float(from["bw"]), float(to["bw"]), t)
	_layout_layers()

func _resolved_radius(w: float, h: float) -> float:
	var limit: float = minf(w, h) * 0.5
	if radius_pct >= 0.0:
		return minf(limit, minf(w, h) * radius_pct / 100.0)
	var value: float = radius_px
	if mark_mode != "none" and not radius_explicit and base_radius > 0.0:
		value += 2.0
	return minf(limit, value)

func _frame_border() -> Dictionary:
	if border_explicit:
		return {"color": border_color, "width": border_w}
	match mark_mode:
		"target":
			return {"color": Color("20c7f3"), "width": 4.0}
		"neighbor":
			return {"color": Color(0.12, 0.78, 0.95, 0.45), "width": maxf(2.0, base_border_width)}
	return {"color": DEFAULT_BORDER, "width": base_border_width}

func _layout_layers() -> void:
	if frame == null:
		return
	var w: float = body_w
	var h: float = body_h
	var radius: float = _radius_override if _radius_override >= 0.0 else _resolved_radius(w, h)
	var border: Dictionary = _frame_border()
	var bw: float = _border_override if _border_override >= 0.0 else float(border["width"])

	# Caja de margen (capa externa, naranja): crece con `margin`.
	var margin_visual: float = clampf(margin_px * 0.8, 0.0, 28.0)
	margin_box.visible = margin_visual > 0.5
	margin_box.size = Vector2(w + margin_visual * 2.0, h + margin_visual * 2.0)
	margin_box.position = CENTER - margin_box.size * 0.5
	_style(margin_box, Color(1.0, 0.48, 0.21, 0.10), Color(1.0, 0.48, 0.21, 0.85), 2, radius + margin_visual * 0.5)

	# Aura (background-color): siempre ovalada.
	halo.size = Vector2(w + 4.0, h + 4.0)
	halo.position = CENTER - halo.size * 0.5
	_style(halo, halo_bg, halo_border, 2, minf(halo.size.x, halo.size.y) * 0.5)

	# Cuerpo (border / border-radius / width / height) y relleno interno (padding).
	frame.size = Vector2(w, h)
	frame.position = CENTER - frame.size * 0.5
	var padding_visual: float = clampf(padding_px * 0.9, 0.0, 22.0)
	var padding_fill: Color = Color(0.13, 0.78, 0.95, 0.20) if padding_visual > 0.5 else Color(0, 0, 0, 0)
	_style(frame, padding_fill, border["color"], int(round(bw)), radius)

	var inset: float = bw + padding_visual
	core.visible = padding_visual > 0.5
	core.position = frame.position + Vector2(inset, inset)
	core.size = Vector2(maxf(8.0, w - inset * 2.0), maxf(8.0, h - inset * 2.0))
	_style(core, Color(0.02, 0.05, 0.10, 0.55), Color(0, 0, 0, 0), 0, maxf(0.0, radius - inset * 0.6))

	# Sprite y etiqueta, dentro del contenido.
	var content_w: float = maxf(8.0, w - inset * 2.0)
	var content_h: float = maxf(8.0, h - inset * 2.0)
	var sprite_side: float = clampf(floorf(minf(content_w, content_h) * 0.8889), 14.0, 128.0)
	sprite.size = Vector2(sprite_side, sprite_side)
	sprite.position = CENTER - Vector2(sprite_side * 0.5, sprite_side * 0.5 + 4.0)
	bug_label.size = Vector2(maxf(40.0, w), 20.0)
	bug_label.position = Vector2(CENTER.x - bug_label.size.x * 0.5, CENTER.y + h * 0.5 - 16.0)
	mark_label.position = Vector2(CENTER.x - 56.0, CENTER.y - h * 0.5 - 25.0)

func _style(node: Panel, bg: Color, border: Color, width: int, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(maxi(0, width))
	style.set_corner_radius_all(maxi(0, int(round(radius))))
	node.add_theme_stylebox_override("panel", style)

func _px(value: String) -> float:
	return value.strip_edges().trim_suffix("px").trim_suffix("deg").to_float()

# transform: rotate(45deg) -> 45.0 ; cualquier otra función se ignora.
func _rotation_of(value: String) -> float:
	var text: String = value.strip_edges()
	if text.begins_with("rotate(") and text.ends_with(")"):
		return text.trim_prefix("rotate(").trim_suffix(")").trim_suffix("deg").to_float()
	return rotation_deg

func _css_color(value: String) -> Color:
	var colors := {
		"red": Color("ff5777"), "blue": Color("20c7f3"), "green": Color("36d98b"),
		"yellow": Color("ffd447"), "black": Color("111827"), "white": Color("f8fbff"),
		"orange": Color("ff7a36"), "purple": Color("8a5cf6"), "pink": Color("ff7eb6"),
		"gray": Color("8a94a8"), "grey": Color("8a94a8")
	}
	return colors.get(value.to_lower(), Color("d7e1f3"))
