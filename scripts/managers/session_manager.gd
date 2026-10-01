extends RefCounted

const PROFILE_DIR := "user://profiles"
const PROFILE_PATH := "user://profiles/profiles.json"
const GameConfig = preload("res://scripts/managers/game_config.gd")

var profiles: Dictionary = {}
var current_email: String = ""

func _init() -> void:
	_load()

func _ensure_dir() -> void:
	var root := DirAccess.open("user://")
	if root != null and not root.dir_exists("profiles"):
		root.make_dir("profiles")

func _load() -> void:
	_ensure_dir()
	if not FileAccess.file_exists(PROFILE_PATH):
		profiles = {}
		return
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	profiles = parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _save() -> void:
	_ensure_dir()
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(profiles, "  "))

func valid_email(email: String) -> bool:
	var value := email.strip_edges().to_lower()
	var at := value.find("@")
	return at > 0 and value.find(".", at) > at + 1 and not value.contains(" ")

func login(email: String) -> bool:
	var key := email.strip_edges().to_lower()
	if profiles.has(key):
		current_email = key
		return true
	return false

func create_profile(email: String, alias_value: String, consent: bool) -> bool:
	var key := email.strip_edges().to_lower()
	var clean_alias := alias_value.strip_edges()
	if not valid_email(key) or clean_alias.length() < 2 or clean_alias.length() > 20 or not consent:
		return false
	profiles[key] = {
		"email": key,
		"alias": clean_alias,
		"consent": true,
		"created_at": Time.get_datetime_string_from_system(),
		"levels": {},
		"badges": {},
		"exposure": {}
	}
	current_email = key
	_save()
	return true

func logout() -> void:
	current_email = ""

func ensure_debug_session() -> void:
	if has_session():
		return
	var debug_email := "debug@csssurvivor.local"
	if not login(debug_email):
		create_profile(debug_email, "DEBUG", true)

func has_session() -> bool:
	return not current_email.is_empty() and profiles.has(current_email)

func email() -> String:
	return current_email

func alias() -> String:
	if not has_session():
		return "JUGADOR"
	return str(profiles[current_email].get("alias", "JUGADOR"))

func _level_key(level: int) -> String:
	return str(level)

func level_stats(level: int) -> Dictionary:
	if not has_session():
		return _empty_stats()
	var levels: Dictionary = profiles[current_email].get("levels", {})
	var stats: Dictionary = levels.get(_level_key(level), _empty_stats())
	return stats.duplicate(true)

func _empty_stats() -> Dictionary:
	return {"attempts":0, "completed":false, "best_score":0, "best_errors":999999, "best_time":999999.0, "last_score":0}

func level_completed(level: int) -> bool:
	return bool(level_stats(level).get("completed", false))

func level_unlocked(level: int) -> bool:
	if level <= 1:
		return true
	return level_completed(level - 1)

# Un nivel se puede jugar si el contenido existe (game_config.json: "available")
# y el jugador ya completó el nivel anterior.
func level_playable(level: int) -> bool:
	return GameConfig.level_available(level) and level_unlocked(level)

func completed_levels() -> int:
	var total := 0
	for level in range(1, GameConfig.total_levels() + 1):
		if level_completed(level):
			total += 1
	return total

# Primer nivel jugable que el jugador aún no completó. Si ya completó todos los
# disponibles, devuelve 1 para que pueda rejugar.
func next_playable_level() -> int:
	for level in range(1, GameConfig.total_levels() + 1):
		if level_playable(level) and not level_completed(level):
			return level
	return 1

func exposure(question_id: int) -> int:
	if not has_session():
		return 0
	var exp: Dictionary = profiles[current_email].get("exposure", {})
	return int(exp.get(str(question_id), 0))

func register_exposure(question_id: int) -> void:
	if not has_session():
		return
	var profile: Dictionary = profiles[current_email]
	var exp: Dictionary = profile.get("exposure", {})
	var key := str(question_id)
	exp[key] = int(exp.get(key, 0)) + 1
	profile["exposure"] = exp
	profiles[current_email] = profile
	_save()

func total_points() -> int:
	if not has_session():
		return 0
	var total := 0
	var levels: Dictionary = profiles[current_email].get("levels", {})
	for key in levels.keys():
		total += int(levels[key].get("best_score", 0))
	return total

func start_attempt(level: int) -> int:
	if not has_session():
		return 1
	var profile: Dictionary = profiles[current_email]
	var levels: Dictionary = profile.get("levels", {})
	var stats: Dictionary = levels.get(_level_key(level), _empty_stats())
	stats["attempts"] = int(stats.get("attempts", 0)) + 1
	levels[_level_key(level)] = stats
	profile["levels"] = levels
	profiles[current_email] = profile
	_save()
	return int(stats["attempts"])

func register_attempt(run: Variant) -> void:
	if not has_session():
		return

	var result: Dictionary = run as Dictionary

	var level: int = int(result.get("level", 1))
	var completed: bool = bool(result.get("completed", false))
	var score: int = int(result.get("score", 0))
	var errors: int = int(result.get("errors", 0))
	var elapsed: float = float(result.get("time", 0.0))

	var profile: Dictionary = profiles.get(current_email, {})
	var levels: Dictionary = profile.get("levels", {})
	var level_key: String = _level_key(level)
	var stats: Dictionary = levels.get(level_key, _empty_stats())

	# OJO: "attempts" NO se suma aquí. start_attempt() ya lo sumó cuando empezó el
	# intento (LevelRun.setup). Sumarlo en los dos lugares contaba cada partida x2.

	if completed:
		stats["completed"] = true

		var best_score: int = int(stats.get("best_score", 0))

		if score > best_score:
			stats["best_score"] = score
			stats["best_errors"] = errors
			stats["best_time"] = elapsed

		elif score == best_score:
			if errors < int(stats.get("best_errors", 999999)):
				stats["best_errors"] = errors
				stats["best_time"] = elapsed

			elif errors == int(stats.get("best_errors", 999999)) \
			and elapsed < float(stats.get("best_time", 999999.0)):
				stats["best_time"] = elapsed

	levels[level_key] = stats
	profile["levels"] = levels
	profiles[current_email] = profile

	if completed and level == 1:
		_award_badge("color_master")

		if errors == 0:
			_award_badge("perfect")

	_save()

func has_badge(badge_id: String) -> bool:
	if not has_session():
		return false
	return profiles[current_email].get("badges", {}).has(badge_id)

func badge_date(badge_id: String) -> String:
	if not has_badge(badge_id):
		return ""
	return str(profiles[current_email].get("badges", {}).get(badge_id, ""))

func badge_count() -> int:
	if not has_session():
		return 0
	return profiles[current_email].get("badges", {}).size()

func _award_badge(badge_id: String) -> bool:
	if not has_session() or has_badge(badge_id):
		return false
	var profile: Dictionary = profiles[current_email]
	var badges: Dictionary = profile.get("badges", {})
	badges[badge_id] = Time.get_date_string_from_system()
	profile["badges"] = badges
	profiles[current_email] = profile
	_save()
	return true

func evaluate_badges_answer(run: Variant, correct: bool) -> Array:
	var awarded: Array = []
	if not correct:
		return awarded
	if not has_badge("first_bug"):
		if _award_badge("first_bug"):
			awarded.append("first_bug")
	var streak := 0
	if run != null and run.has_method("current_streak"):
		streak = int(run.current_streak())
	if streak >= 5 and not has_badge("streak_5"):
		if _award_badge("streak_5"):
			awarded.append("streak_5")
	return awarded

func ranking() -> Array:
	var rows: Array = []
	for key in profiles.keys():
		var profile: Dictionary = profiles[key]
		var score := 0
		var total_errors := 0
		var total_time := 0.0
		var levels: Dictionary = profile.get("levels", {})
		for level_key in levels.keys():
			var stats: Dictionary = levels[level_key]
			score += int(stats.get("best_score", 0))
			if bool(stats.get("completed", false)):
				total_errors += int(stats.get("best_errors", 0))
				total_time += float(stats.get("best_time", 0.0))
		rows.append({
			"alias": str(profile.get("alias", "JUGADOR")),
			"points": score,
			"badges": profile.get("badges", {}).size(),
			"errors": total_errors,
			"time": total_time,
			"current": key == current_email
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["points"]) != int(b["points"]):
			return int(a["points"]) > int(b["points"])
		if int(a["errors"]) != int(b["errors"]):
			return int(a["errors"]) < int(b["errors"])
		return float(a["time"]) < float(b["time"])
	)
	return rows
