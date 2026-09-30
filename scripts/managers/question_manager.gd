extends RefCounted

const QUESTIONS_PATH := "res://data/questions.json"

var questions: Array = []
var question_bags := {1: [], 2: [], 3: []}

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
	for level in [1, 2, 3]:
		refill_bag(level)
	return true

func refill_bag(level: int) -> void:
	var bag: Array = []
	for q in questions:
		if int(q["level"]) == level:
			bag.append(int(q["id"]))
	bag.shuffle()
	question_bags[level] = bag

func next_random(level: int) -> Dictionary:
	if question_bags[level].is_empty():
		refill_bag(level)
	var id: int = question_bags[level].pop_back()
	return question_by_id(id)

func question_by_id(id: int) -> Dictionary:
	for q in questions:
		if int(q["id"]) == id:
			return q
	return {}

func options_for(q: Dictionary) -> Array[String]:
	var correct := str(q["answer"])
	var pool: Array[String] = []
	var target_group := _type_group(str(q["type"]))
	var target_kind := _answer_kind(correct)

	for other in questions:
		var answer := str(other["answer"])
		if int(other["level"]) == int(q["level"]) and _type_group(str(other["type"])) == target_group and _answer_kind(answer) == target_kind:
			if answer != correct and not pool.has(answer):
				pool.append(answer)

	if pool.size() < 3:
		for other in questions:
			if int(other["level"]) == int(q["level"]) and _type_group(str(other["type"])) == target_group:
				var answer := str(other["answer"])
				if answer != correct and not pool.has(answer):
					pool.append(answer)

	if pool.size() < 3:
		for other in questions:
			if int(other["level"]) == int(q["level"]):
				var answer := str(other["answer"])
				if answer != correct and not pool.has(answer):
					pool.append(answer)

	pool.shuffle()
	var result: Array[String] = [correct]
	for answer in pool:
		if result.size() >= 4:
			break
		result.append(answer)
	result.shuffle()
	return result

func prepare_evaluation_set() -> Array:
	var result: Array = []
	for level in [1, 2, 3]:
		var candidates: Array = []
		for q in questions:
			if int(q["level"]) == level and str(q["type"]) == "Teórico":
				candidates.append(q)
		candidates.shuffle()
		for i in range(min(3, candidates.size())):
			result.append(candidates[i])
	return result

func category_for_level(level: int) -> String:
	match level:
		1:
			return "VISUAL (color, background-color, font-size, opacity, border-color)"
		2:
			return "CAJA (border, border-radius, padding, margin, width, height)"
		_:
			return "LAYOUT (transform, flex-direction, justify-content, align-content/items, gap)"

func _type_group(type_name: String) -> String:
	if type_name.begins_with("Multi"):
		return "Multi-objetivo"
	return type_name

func _answer_kind(answer: String) -> String:
	if "+" in answer:
		return "combo"
	if ":" in answer:
		return "declaration"
	if " " in answer:
		return "description"
	return "property"
