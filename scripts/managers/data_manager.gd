extends RefCounted

const GameConfig = preload("res://scripts/managers/game_config.gd")

# Construye los paquetes de datos que se guardan en Google Sheets.
# No modifica la lógica del juego: solo transforma el historial existente de LevelRun.

var _attempt_id: String = ""
var _attempt_started_at: String = ""

func begin_attempt(session_manager, run) -> void:
	_attempt_started_at = Time.get_datetime_string_from_system()
	var stamp_ms: int = int(Time.get_unix_time_from_system() * 1000.0)
	_attempt_id = "%s-L%d-A%d-%d" % [
		str(session_manager.email()),
		int(run.level),
		int(run.attempt_number),
		stamp_ms
	]

func current_attempt_id() -> String:
	return _attempt_id

func build_attempt_payload(run, session_manager, result_name: String) -> Dictionary:
	if run == null or session_manager == null:
		return {}

	var timeout_count: int = 0
	var response_rows: Array = []
	var default_limit: float = float(run.config.get("question_time_seconds", 0.0))

	for value in run.history:
		var entry: Dictionary = value as Dictionary
		var selected: String = str(entry.get("selected", ""))
		var timed_out: bool = bool(entry.get("timed_out", selected == "SIN RESPUESTA"))
		if timed_out:
			timeout_count += 1

		response_rows.append({
			"fecha": str(entry.get("answered_at", Time.get_datetime_string_from_system())),
			"nivel": int(run.level),
			"zona": int(entry.get("zone", -1)) + 1,
			"id_pregunta": int(entry.get("id", -1)),
			"pregunta": str(entry.get("question", "")),
			"tipo": str(entry.get("type", "")),
			"propiedad_css": str(entry.get("main_property", "")),
			"respuesta_jugador": selected,
			"respuesta_correcta": str(entry.get("answer", "")),
			"correcta": bool(entry.get("correct", false)),
			"timeout": timed_out,
			"tiempo_respuesta_seg": float(entry.get("response_time", 0.0)),
			"tiempo_maximo_seg": float(entry.get("time_limit", default_limit)),
			"vidas_restantes": int(entry.get("lives_remaining", run.lives)),
			"puntaje_actual": int(entry.get("score_after", run.score))
		})

	var badge_names: PackedStringArray = []
	for badge_id in session_manager.badge_ids():
		badge_names.append(str(badge_id))

	var safe_attempt_id: String = _attempt_id
	if safe_attempt_id.is_empty():
		var fallback_stamp: int = int(Time.get_unix_time_from_system() * 1000.0)
		safe_attempt_id = "%s-L%d-A%d-%d" % [
			str(session_manager.email()),
			int(run.level),
			int(run.attempt_number),
			fallback_stamp
		]

	return {
		"action": "guardar_intento",
		"ranking": _ranking_snapshot(session_manager),
		"intento": {
			"id_intento": safe_attempt_id,
			"id_jugador": str(session_manager.email()),
			"correo": str(session_manager.email()),
			"alias": str(session_manager.alias()),
			"fecha": _attempt_started_at if not _attempt_started_at.is_empty() else Time.get_datetime_string_from_system(),
			"nivel": int(run.level),
			"puntaje": int(run.score),
			"aciertos": int(run.correct_count),
			"errores": int(run.error_count),
			"timeouts": timeout_count,
			"tiempo_total_seg": float(run.elapsed_seconds()),
			"vidas_restantes": int(run.lives),
			"mejor_racha": int(run.best_streak),
			"insignias": ", ".join(badge_names),
			"resultado": result_name
		},
		"respuestas": response_rows
	}


func build_ranking_sync_payload(session_manager) -> Dictionary:
	if session_manager == null:
		return {}
	return {
		"action": "sync_ranking",
		"ranking": _ranking_snapshot(session_manager)
	}

func _ranking_snapshot(session_manager) -> Dictionary:
	var best_by_level: Dictionary = {}
	var total: int = 0
	for level in range(1, GameConfig.total_levels() + 1):
		var stats: Dictionary = session_manager.level_stats(level)
		var best_score: int = int(stats.get("best_score", 0))
		best_by_level[str(level)] = best_score
		total += best_score

	var badge_names: PackedStringArray = []
	for badge_id in session_manager.badge_ids():
		badge_names.append(str(badge_id))

	return {
		"id_jugador": str(session_manager.email()),
		"alias": str(session_manager.alias()),
		"nivel_1": int(best_by_level.get("1", 0)),
		"nivel_2": int(best_by_level.get("2", 0)),
		"nivel_3": int(best_by_level.get("3", 0)),
		"puntaje_total": total,
		"insignias": ", ".join(badge_names)
	}
