extends RefCounted

const QUESTIONS_PATH := "res://data/questions.json"
var questions: Array = []

func load_questions() -> bool:
	if not FileAccess.file_exists(QUESTIONS_PATH):
		push_error("No se encontró el banco de preguntas: %s" % QUESTIONS_PATH)
		return false
	var file := FileAccess.open(QUESTIONS_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("questions.json no contiene un Array válido")
		return false
	questions = parsed
	return true

func pool_for(level: int) -> Array:
	var pool: Array = []
	for q in questions:
		if int(q.get("level", 0)) == level:
			pool.append(q)
	return pool

func question_by_id(id: int) -> Dictionary:
	for q in questions:
		if int(q.get("id", -1)) == id:
			return q
	return {}

func options_for(q: Dictionary) -> Array[String]:
	var options: Array[String] = []
	for value in q.get("options", []):
		options.append(str(value))
	if options.size() != 4:
		push_warning("Pregunta %s no tiene exactamente 4 opciones curadas." % str(q.get("id", "?")))
		var correct := str(q.get("answer", ""))
		if not options.has(correct):
			options.append(correct)
		while options.size() < 4:
			options.append("Opción no disponible %d" % (options.size() + 1))
		if options.size() > 4:
			options.resize(4)
	options.shuffle()
	return options

static func kind_of(q: Dictionary) -> String:
	if q.has("kind"):
		return str(q["kind"])
	var type_name := str(q.get("type", "")).to_lower()
	if type_name.begins_with("teó") or type_name.begins_with("teo"):
		return "teorico"
	if type_name.begins_with("prá") or type_name.begins_with("pra"):
		return "practico"
	if type_name.begins_with("completar"):
		return "completar"
	return "multi"

func prepare_evaluation_set() -> Array:
	var result: Array = []
	for q in questions:
		if int(q.get("level", 0)) == 1 and kind_of(q) == "teorico":
			result.append(q)
			if result.size() >= 3:
				break
	return result
