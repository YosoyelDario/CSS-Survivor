extends RefCounted

# Layout "flex" del grupo de enemigos de una fila (Nivel 3).
#
# Cada fila de enemigos se comporta como un contenedor `display: flex`, y las propiedades que
# aprende el jugador mueven visiblemente al grupo:
#   flex-direction  -> fila (horizontal) o columna (vertical)
#   justify-content -> alineación en el eje principal
#   align-items     -> alineación en el eje transversal
#   align-content   -> reparto de las líneas (el grupo se parte en 2 líneas)
#   gap             -> separación entre enemigos
#
# El estado por defecto es el de CSS: fila, flex-start y gap 0 (grupo pegado a la izquierda).
# Esto es lógica pura (sin nodos), por lo que se puede probar sin abrir la escena.

const ITEM := 92.0                 # lado del nodo de un enemigo
const MAIN_LEFT := 424.0           # borde izquierdo del contenedor
const MAIN_RIGHT := 856.0          # borde derecho del contenedor
const CROSS_HEIGHT := 150.0        # alto disponible en el eje transversal (fila)
const WRAP_HEIGHT := 220.0         # alto disponible cuando hay varias líneas
const COLUMN_TOP := 128.0
const COLUMN_BOTTOM := 432.0
const COLUMN_SCALE := 0.62         # en columna los enemigos se ven más pequeños para caber
const WRAP_SCALE := 0.7

const LAYOUT_PROPERTIES := ["flex-direction", "justify-content", "align-items", "align-content", "gap"]

static func default_props() -> Dictionary:
	return {"direction": "row", "justify": "flex-start", "align_items": "flex-start", "align_content": "normal", "gap": 0.0}

static func is_layout_property(property_name: String) -> bool:
	return LAYOUT_PROPERTIES.has(property_name)

static func has_layout_effect(effects: Array) -> bool:
	for effect in effects:
		if is_layout_property(str((effect as Dictionary).get("property", ""))):
			return true
	return false

# Devuelve una copia de `props` con los efectos CSS de layout aplicados.
static func apply_effects(props: Dictionary, effects: Array) -> Dictionary:
	var out: Dictionary = props.duplicate()
	for effect_value in effects:
		var effect: Dictionary = effect_value as Dictionary
		var value: String = str(effect.get("value", "")).strip_edges()
		match str(effect.get("property", "")):
			"flex-direction":
				out["direction"] = "column" if value.begins_with("column") else "row"
			"justify-content":
				out["justify"] = value
			"align-items":
				out["align_items"] = value
			"align-content":
				out["align_content"] = value
			"gap":
				out["gap"] = maxf(0.0, value.trim_suffix("px").to_float())
	return out

static func _normalize(value: String) -> String:
	match value:
		"start", "flex-start":
			return "start"
		"end", "flex-end":
			return "end"
		"center":
			return "center"
		"space-between":
			return "between"
		_:
			return "start"

# Posiciones finales (centro del enemigo y escala) para `count` enemigos de una fila cuyo centro
# por defecto está a la altura `depth_y`. Devuelve [{"center": Vector2, "scale": float}, ...].
static func positions(props: Dictionary, count: int, depth_y: float) -> Array:
	if count <= 0:
		return []
	if str(props.get("align_content", "normal")) != "normal" and count >= 3:
		return _wrap_positions(props, count, depth_y)
	if str(props.get("direction", "row")) == "column":
		return _column_positions(props, count)
	return _row_positions(props, count, depth_y)

static func _row_positions(props: Dictionary, count: int, depth_y: float) -> Array:
	var gap: float = float(props.get("gap", 0.0))
	var total: float = count * ITEM + (count - 1) * gap
	var step: float = ITEM + gap
	var x0: float = MAIN_LEFT
	match _normalize(str(props.get("justify", "flex-start"))):
		"center":
			x0 = (MAIN_LEFT + MAIN_RIGHT) * 0.5 - total * 0.5
		"end":
			x0 = MAIN_RIGHT - total
		"between":
			if count > 1:
				step = maxf(step, (MAIN_RIGHT - MAIN_LEFT - count * ITEM) / float(count - 1) + ITEM)
	var free: float = CROSS_HEIGHT - ITEM
	var y_offset: float = 0.0
	match _normalize(str(props.get("align_items", "flex-start"))):
		"center":
			y_offset = free * 0.5
		"end":
			y_offset = free
	var result: Array = []
	for i in range(count):
		result.append({"center": Vector2(x0 + ITEM * 0.5 + i * step, depth_y + y_offset), "scale": 1.0})
	return result

static func _column_positions(props: Dictionary, count: int) -> Array:
	var gap: float = float(props.get("gap", 0.0))
	var s: float = ITEM * COLUMN_SCALE
	var total: float = count * s + (count - 1) * gap
	var step: float = s + gap
	var y0: float = COLUMN_TOP
	match _normalize(str(props.get("justify", "flex-start"))):
		"center":
			y0 = (COLUMN_TOP + COLUMN_BOTTOM) * 0.5 - total * 0.5
		"end":
			y0 = COLUMN_BOTTOM - total
		"between":
			if count > 1:
				step = maxf(step, (COLUMN_BOTTOM - COLUMN_TOP - count * s) / float(count - 1) + s)
	var x: float = MAIN_LEFT + s * 0.5
	match _normalize(str(props.get("align_items", "flex-start"))):
		"center":
			x = (MAIN_LEFT + MAIN_RIGHT) * 0.5
		"end":
			x = MAIN_RIGHT - s * 0.5
	var result: Array = []
	for i in range(count):
		result.append({"center": Vector2(x, y0 + s * 0.5 + i * step), "scale": COLUMN_SCALE})
	return result

# align-content solo tiene sentido con varias líneas: el grupo se parte en dos líneas
# (los dos primeros enemigos arriba y el resto abajo) y `align-content` reparte esas líneas.
static func _wrap_positions(props: Dictionary, count: int, depth_y: float) -> Array:
	var s: float = ITEM * WRAP_SCALE
	var top: float = depth_y - 120.0
	var bottom: float = top + WRAP_HEIGHT
	var line_one: int = mini(2, count)
	var line_two: int = count - line_one
	var lines: int = 2 if line_two > 0 else 1
	var y_first: float = top + s * 0.5
	var y_last: float = y_first + s
	match _normalize(str(props.get("align_content", "normal"))):
		"center":
			var block: float = lines * s
			y_first = (top + bottom) * 0.5 - block * 0.5 + s * 0.5
			y_last = y_first + s
		"end":
			y_last = bottom - s * 0.5
			y_first = y_last - s
		"between":
			y_first = top + s * 0.5
			y_last = bottom - s * 0.5
	var gap: float = float(props.get("gap", 0.0))
	var result: Array = []
	for i in range(count):
		var on_first: bool = i < line_one
		var index_in_line: int = i if on_first else i - line_one
		result.append({
			"center": Vector2(MAIN_LEFT + s * 0.5 + index_in_line * (s + gap), y_first if on_first else y_last),
			"scale": WRAP_SCALE})
	return result
