extends RefCounted

const QuestionManager = preload("res://scripts/managers/question_manager.gd")

var level: int = 1
var config: Dictionary = {}
var question_manager
var session_manager
var lives: int = 5
var score: int = 0
var streak: int = 0
var best_streak: int = 0
var correct_count: int = 0
var error_count: int = 0
var attempt_number: int = 1
var started_ms: int = 0
var history: Array = []
var used_ids: Array[int] = []
var zone_rows_left: Array[int] = []
var zone_rows_total: Array[int] = []
var zone_errors: Array[int] = []
var zone_bonus_awarded: Array[bool] = []
var finalized: bool = false
var abandoned: bool = false

func setup(level_number: int, level_config: Dictionary, q_manager, s_manager) -> void:
	level = level_number
	config = level_config
	question_manager = q_manager
	session_manager = s_manager
	lives = int(config.get("lives", 5))
	score = 0
	streak = 0
	best_streak = 0
	correct_count = 0
	error_count = 0
	history.clear()
	used_ids.clear()
	zone_rows_total.clear()
	zone_rows_left.clear()
	zone_errors.clear()
	zone_bonus_awarded.clear()
	for value in config.get("zone_rows", [3, 4, 4, 4]):
		var rows := int(value)
		zone_rows_total.append(rows)
		zone_rows_left.append(rows)
		zone_errors.append(0)
		zone_bonus_awarded.append(false)
	started_ms = Time.get_ticks_msec()
	finalized = false
	abandoned = false
	attempt_number = session_manager.start_attempt(level) if session_manager != null else 1

func rows_left(zone_index: int) -> int:
	return zone_rows_left[zone_index] if zone_index >= 0 and zone_index < zone_rows_left.size() else 0

func rows_total(zone_index: int) -> int:
	return zone_rows_total[zone_index] if zone_index >= 0 and zone_index < zone_rows_total.size() else 0

func rows_cleared(zone_index: int) -> int:
	return rows_total(zone_index) - rows_left(zone_index)

func zone_clean(zone_index: int) -> bool:
	return rows_left(zone_index) <= 0

func all_zones_clean() -> bool:
	for value in zone_rows_left:
		if value > 0:
			return false
	return true

func current_streak() -> int:
	return streak

func kind_for_zone(zone_index: int) -> String:
	var sequences: Array = config.get("zone_sequences", [])
	if zone_index < 0 or zone_index >= sequences.size():
		return "teorico"
	var sequence: Array = sequences[zone_index]
	var index := clampi(rows_cleared(zone_index), 0, maxi(0, sequence.size() - 1))
	return str(sequence[index]) if not sequence.is_empty() else "teorico"

func next_question(zone_index: int) -> Dictionary:
	return _pick_question(kind_for_zone(zone_index), "", -1)

func replace_question(failed_question: Dictionary, zone_index: int) -> Dictionary:
	var kind := QuestionManager.kind_of(failed_question)
	var property_name := str(failed_question.get("main_property", ""))
	var replacement := _pick_question(kind, property_name, int(failed_question.get("id", -1)))
	if replacement.is_empty():
		replacement = _pick_question(kind, "", int(failed_question.get("id", -1)))
	if replacement.is_empty():
		push_warning("Pool agotado para %s: se permite repetir una pregunta fallada." % kind)
		var pool := _candidates(kind, "", -1, false)
		if not pool.is_empty():
			replacement = pool.pick_random()
	return replacement

func _pick_question(
	kind: String,
	property_name: String,
	excluded_id: int
) -> Dictionary:

	var candidates: Array = _candidates(
		kind,
		property_name,
		excluded_id,
		true
	)

	if candidates.is_empty() and not property_name.is_empty():
		candidates = _candidates(
			kind,
			"",
			excluded_id,
			true
		)

	if candidates.is_empty():
		return {}

	var min_exposure: int = 999999

	for q in candidates:
		var question: Dictionary = q as Dictionary

		var exposure_count: int = 0

		if session_manager != null:
			exposure_count = int(
				session_manager.exposure(
					int(question.get("id", 0))
				)
			)

		min_exposure = mini(
			min_exposure,
			exposure_count
		)

	var least_seen: Array = []

	for q in candidates:
		var question: Dictionary = q as Dictionary

		var seen: int = 0

		if session_manager != null:
			seen = int(
				session_manager.exposure(
					int(question.get("id", 0))
				)
			)

		if seen == min_exposure:
			least_seen.append(question)

	if least_seen.is_empty():
		return {}

	var picked: Variant = least_seen.pick_random()

	if not picked is Dictionary:
		push_error("La pregunta seleccionada no es un Dictionary.")
		return {}

	var chosen: Dictionary = (picked as Dictionary).duplicate(true)

	var question_id: int = int(
		chosen.get("id", -1)
	)

	if question_id >= 0 and not used_ids.has(question_id):
		used_ids.append(question_id)

	if session_manager != null and question_id >= 0:
		session_manager.register_exposure(question_id)

	return chosen

func _candidates(kind: String, property_name: String, excluded_id: int, avoid_used: bool) -> Array:
	var result: Array = []
	for q in question_manager.pool_for(level):
		var id := int(q.get("id", -1))
		if id == excluded_id:
			continue
		if avoid_used and used_ids.has(id):
			continue
		if QuestionManager.kind_of(q) != kind:
			continue
		if not property_name.is_empty() and str(q.get("main_property", "")) != property_name:
			continue
		result.append(q)
	return result

func answer(zone_index: int, question: Dictionary, selected: String, affected: int, response_time: float, shown_options: Array) -> Dictionary:
	var correct := selected == str(question.get("answer", ""))
	var kind := QuestionManager.kind_of(question)
	var gained := 0
	var bonus := 0
	var zone_finished := false
	if correct:
		correct_count += 1
		streak += 1
		best_streak = maxi(best_streak, streak)
		var points_by_type: Dictionary = config.get("points_by_type", {})
		gained = int(points_by_type.get(kind, 100))
		score += gained
		var streak_cfg: Dictionary = config.get("streak_bonus", {"every": 3, "points": 100})
		var every := int(streak_cfg.get("every", 3))
		if every > 0 and streak % every == 0:
			bonus += int(streak_cfg.get("points", 100))
			score += int(streak_cfg.get("points", 100))
		if zone_index >= 0 and zone_index < zone_rows_left.size():
			zone_rows_left[zone_index] = maxi(0, zone_rows_left[zone_index] - 1)
			zone_finished = zone_rows_left[zone_index] == 0
			if zone_finished and not zone_bonus_awarded[zone_index] and zone_errors[zone_index] == 0:
				var clean_bonus := int(config.get("clean_zone_bonus", 250))
				bonus += clean_bonus
				score += clean_bonus
				zone_bonus_awarded[zone_index] = true
	else:
		error_count += 1
		streak = 0
		lives = maxi(0, lives - 1)
		if zone_index >= 0 and zone_index < zone_errors.size():
			zone_errors[zone_index] += 1
	var entry := {
		"id": int(question.get("id", -1)),
		"type": kind,
		"zone": zone_index,
		"question": str(question.get("question", "")),
		"code": str(question.get("code", "")),
		"options": shown_options.duplicate(),
		"selected": selected,
		"answer": str(question.get("answer", "")),
		"correct": correct,
		"explanation": str(question.get("explanation", "")),
		"response_time": response_time,
		"score_gained": gained + bonus,
		"affected": affected if correct else 0
	}
	history.append(entry)
	return {"correct":correct, "base_points":gained, "bonus":bonus, "zone_finished":zone_finished, "lives":lives, "score":score}

func repair_percent() -> float:
	var total := 0
	var left := 0
	for value in zone_rows_total:
		total += value
	for value in zone_rows_left:
		left += value
	if total <= 0:
		return 0.0
	return float(total - left) / float(total)

func zone_repair_percent(zone_index: int) -> float:
	var total := rows_total(zone_index)
	if total <= 0:
		return 0.0
	return float(total - rows_left(zone_index)) / float(total)

func finalize_level() -> int:
	if finalized or not all_zones_clean():
		return 0
	finalized = true
	var bonus := lives * int(config.get("life_bonus", 200))
	score += bonus
	return bonus

func game_over() -> bool:
	return lives <= 0

func elapsed_seconds() -> float:
	return float(maxi(0, Time.get_ticks_msec() - started_ms)) / 1000.0

func session_result(force_abandoned: bool = false) -> Dictionary:
	return {
		"level": level,
		"score": score,
		"errors": error_count,
		"correct": correct_count,
		"time": elapsed_seconds(),
		"completed": all_zones_clean() and not force_abandoned,
		"abandoned": force_abandoned,
		"best_streak": best_streak,
		"lives": lives
	}
