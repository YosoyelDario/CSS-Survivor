extends RefCounted

# Retroalimentación diagnóstica: explica POR QUÉ falló la alternativa que eligió el jugador,
# sin revelar la respuesta correcta (andamiaje: se resalta la categoría de la propiedad
# requerida, no la respuesta directa). Es lógica pura, sin nodos, y se prueba en
# tests/model_smoke_test.gd.
#
# Funciona con las alternativas de los ejercicios prácticos, de completar código, multi-objetivo
# y enemigo final (declaraciones CSS o nombres de propiedad). Para las teóricas, cuyas
# alternativas son frases, devuelve "" y quien llama usa la pista del ejercicio.

const MEANING := {
	"color": "el color del texto",
	"background-color": "el color del fondo (el aura del enemigo)",
	"border-color": "el color del contorno",
	"opacity": "la transparencia",
	"font-size": "el tamaño del texto",
	"border": "el grosor y el estilo del contorno",
	"border-radius": "la curvatura de las esquinas",
	"padding": "el espacio interno",
	"margin": "la separación externa",
	"width": "el ancho",
	"height": "el alto",
	"transform": "la rotación y otras transformaciones",
	"flex-direction": "la dirección del eje principal (fila o columna)",
	"justify-content": "la alineación en el eje principal",
	"align-items": "la alineación en el eje transversal",
	"align-content": "el reparto de las líneas",
	"gap": "el espacio entre los elementos"
}

# "color: red; + font-size: 24px;" -> [{"prop": "color", "value": "red"}, {"prop": "font-size", "value": "24px"}]
# "padding" -> [{"prop": "padding", "value": ""}]
# Una frase de teoría -> [] (no es una declaración CSS).
static func parse(text: String) -> Array:
	var result: Array = []
	for raw_part in text.split("+", false):
		var part: String = raw_part.strip_edges()
		var paren: int = part.find("(")
		# "opacity (una por enemigo)" -> "opacity"; "transform: rotate(45deg)" conserva su paréntesis.
		if paren > 0 and not part.contains(":"):
			part = part.substr(0, paren).strip_edges()
		part = part.trim_suffix(";").strip_edges()
		if part.contains(":"):
			var pieces: PackedStringArray = part.split(":", true, 1)
			var property_name: String = pieces[0].strip_edges()
			if not MEANING.has(property_name):
				return []
			result.append({"prop": property_name, "value": pieces[1].strip_edges().trim_suffix(";").strip_edges()})
		elif MEANING.has(part):
			result.append({"prop": part, "value": ""})
		else:
			return []
	return result

static func _props_of(declarations: Array) -> Array:
	var props: Array = []
	for declaration in declarations:
		var property_name: String = str((declaration as Dictionary)["prop"])
		if not props.has(property_name):
			props.append(property_name)
	return props

static func _is_numeric_token(token: String) -> bool:
	if token.is_empty():
		return false
	var first: String = token.substr(0, 1)
	return first.is_valid_int() or first == "." or (first == "-" and token.length() > 1)

# Separa "12px" en ["12", "px"] y "50%" en ["50", "%"].
static func _split_number_unit(token: String) -> Array:
	var number_text: String = ""
	var index: int = 0
	while index < token.length():
		var character: String = token.substr(index, 1)
		if character.is_valid_int() or character == "." or (character == "-" and index == 0):
			number_text += character
			index += 1
		else:
			break
	return [number_text, token.substr(index)]

# Qué debe revisar el jugador cuando la propiedad es correcta pero el valor no coincide.
static func _value_hint(property_name: String, picked_value: String, correct_value: String) -> String:
	# Funciones, por ejemplo rotate(45deg) frente a skew(45deg) o rotate(50%).
	if correct_value.contains("(") or picked_value.contains("("):
		var picked_function: String = picked_value.substr(0, maxi(0, picked_value.find("(")))
		var correct_function: String = correct_value.substr(0, maxi(0, correct_value.find("(")))
		if picked_function != correct_function:
			return "revisa la función de la transformación"
		return _number_hint(_inside_parentheses(picked_value), _inside_parentheses(correct_value))
	var picked_tokens: PackedStringArray = picked_value.split(" ", false)
	var correct_tokens: PackedStringArray = correct_value.split(" ", false)
	if picked_tokens.size() == correct_tokens.size():
		for i in range(correct_tokens.size()):
			if picked_tokens[i] == correct_tokens[i]:
				continue
			if _is_numeric_token(picked_tokens[i]) and _is_numeric_token(correct_tokens[i]):
				return _number_hint(picked_tokens[i], correct_tokens[i])
			if property_name == "border":
				return "revisa el estilo o el color del borde"
			break
	return _keyword_hint(property_name)

static func _inside_parentheses(value: String) -> String:
	var start: int = value.find("(")
	var finish: int = value.rfind(")")
	if start < 0 or finish <= start:
		return value
	return value.substr(start + 1, finish - start - 1)

static func _number_hint(picked_token: String, correct_token: String) -> String:
	var picked_parts: Array = _split_number_unit(picked_token)
	var correct_parts: Array = _split_number_unit(correct_token)
	var same_number: bool = str(picked_parts[0]) == str(correct_parts[0])
	var same_unit: bool = str(picked_parts[1]) == str(correct_parts[1])
	if same_number and not same_unit:
		return "revisa la unidad"
	if same_unit and not same_number:
		return "revisa el número"
	return "revisa el número y la unidad"

static func _keyword_hint(property_name: String) -> String:
	match property_name:
		"color", "background-color", "border-color":
			return "revisa el color elegido"
		"flex-direction":
			return "revisa si debe ser fila o columna"
		"justify-content", "align-items", "align-content":
			return "revisa el tipo de alineación"
	return "revisa el valor"

# Explicación de por qué falló `chosen`. "" si no hay diagnóstico (alternativas de teoría).
static func diagnose(question: Dictionary, chosen: String) -> String:
	var correct: Array = parse(str(question.get("answer", "")))
	var picked: Array = parse(chosen)
	if correct.is_empty() or picked.is_empty():
		return ""
	var correct_props: Array = _props_of(correct)
	var picked_props: Array = _props_of(picked)

	var extra: Array = []
	for property_name in picked_props:
		if not correct_props.has(property_name):
			extra.append(property_name)
	var missing: Array = []
	for property_name in correct_props:
		if not picked_props.has(property_name):
			missing.append(property_name)

	# 1) Eligió una propiedad que no corresponde.
	if not extra.is_empty():
		var wrong_property: String = str(extra[0])
		var message: String = "Elegiste %s, que controla %s." % [wrong_property, MEANING[wrong_property]]
		if not missing.is_empty():
			message += " Aquí se necesita controlar %s." % MEANING[str(missing[0])]
		return message

	# 2) Le falta una de las propiedades que pide el enunciado.
	if not missing.is_empty():
		return "Falta una propiedad: también hay que controlar %s." % MEANING[str(missing[0])]

	# 3) Las propiedades son las correctas, pero algún valor no coincide.
	for picked_declaration in picked:
		for correct_declaration in correct:
			if str(picked_declaration["prop"]) != str(correct_declaration["prop"]):
				continue
			var picked_value: String = str(picked_declaration["value"])
			var correct_value: String = str(correct_declaration["value"])
			if picked_value != correct_value:
				return "%s es la propiedad correcta, pero su valor no coincide con el enunciado: %s." % [
					str(picked_declaration["prop"]), _value_hint(str(picked_declaration["prop"]), picked_value, correct_value)]

	# 4) Mismas propiedades repetidas o en otro orden: sin diagnóstico específico.
	return ""

# Texto que se muestra tras un error: el diagnóstico si existe y, si no, la pista del ejercicio.
static func error_detail(question: Dictionary, chosen: String) -> String:
	var diagnosis: String = diagnose(question, chosen)
	if not diagnosis.is_empty():
		return "POR QUÉ FALLÓ: " + diagnosis
	var hint: String = str(question.get("hint", ""))
	return ("PISTA: " + hint) if not hint.is_empty() else ""
