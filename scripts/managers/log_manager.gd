extends RefCounted

const LOG_PATH := "user://css_survivor_log.jsonl"

func append(record: Dictionary) -> void:
	var file := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE) if FileAccess.file_exists(LOG_PATH) else FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo abrir el log de CSS Survivor")
		return
	file.seek_end()
	file.store_line(JSON.stringify(record))

func answer_record(id_jugador: String, pregunta: String, alternativas: Array, respuesta: String, correcta: bool, tiempo_segundos: float, extras: Dictionary = {}) -> Dictionary:
	var record := {
		"timestamp": Time.get_datetime_string_from_system(),
		"idJugador": id_jugador,
		"pregunta": pregunta,
		"alternativas": alternativas.duplicate(),
		"respuestaJugador": respuesta,
		"siFueCorrectaoNo": correcta,
		"tiempoDeRespuesta": tiempo_segundos
	}
	for key in extras.keys():
		record[key] = extras[key]
	return record

func read_all() -> Array:
	var rows: Array = []
	if not FileAccess.file_exists(LOG_PATH):
		return rows
	var file := FileAccess.open(LOG_PATH, FileAccess.READ)
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parsed = JSON.parse_string(line)
		if typeof(parsed) == TYPE_DICTIONARY:
			rows.append(parsed)
	return rows

func full_path() -> String:
	return ProjectSettings.globalize_path(LOG_PATH)
