extends RefCounted

const CONFIG_PATH := "res://data/game_config.json"
static var _cache: Dictionary = {}

static func data() -> Dictionary:
	if _cache.is_empty():
		_load()
	return _cache

static func _load() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		push_error("No se encontró game_config.json")
		_cache = {}
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("game_config.json no contiene un objeto válido")
		_cache = {}
		return
	_cache = parsed

static func level(number: int) -> Dictionary:
	var levels: Dictionary = data().get("levels", {})
	return levels.get(str(number), {})

static func total_levels() -> int:
	return int(data().get("total_levels", 3))

static func level_available(number: int) -> bool:
	return bool(level(number).get("available", false))

static func level_name(number: int) -> String:
	return str(level(number).get("name", "Nivel %d" % number))

static func level_short(number: int) -> String:
	return str(level(number).get("short", "NIVEL %d" % number))

static func badges() -> Array:
	return data().get("badges", [])

static func pretest_active() -> bool:
	return bool(data().get("pretest_active", false))

static func text(key: String, fallback: Variant = "") -> Variant:
	var texts: Dictionary = data().get("texts", {})
	return texts.get(key, fallback)
