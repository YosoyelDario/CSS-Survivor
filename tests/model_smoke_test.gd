extends SceneTree

const GameConfig = preload("res://scripts/managers/game_config.gd")
const QuestionManager = preload("res://scripts/managers/question_manager.gd")
const LevelRun = preload("res://scripts/managers/level_run.gd")
const ZoneGrid = preload("res://scripts/managers/zone_grid.gd")
const FlexLayout = preload("res://scripts/managers/flex_layout.gd")
const EnemyView = preload("res://scripts/enemy_view.gd")

# Puntaje de una partida perfecta (15 ejercicios sin errores y con las 5 vidas).
const PERFECT_SCORE := {1: 5250, 2: 5250, 3: 5700}

class FakeSession:
	extends RefCounted
	var seen: Dictionary = {}
	func start_attempt(_level: int) -> int:
		return 1
	func exposure(id: int) -> int:
		return int(seen.get(str(id), 0))
	func register_exposure(id: int) -> void:
		seen[str(id)] = exposure(id) + 1

func _initialize() -> void:
	var failures: Array[String] = []
	_test_grid(failures)
	_test_question_bank(failures)
	for level in range(1, 4):
		_test_level_run(level, failures)
	_test_flex_layout(failures)
	_test_badges_config(failures)
	if failures.is_empty():
		print("CSS Survivor model smoke test: OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _test_grid(failures: Array[String]) -> void:
	for mode in ["adjacent", "volley"]:
		var grid = ZoneGrid.new()
		grid.setup(0, 4, 3, 3, mode)
		if grid.rows_left() != 4:
			failures.append("Grid[%s]: debía iniciar con 4 filas" % mode)
		var target := grid.target_and_neighbors()
		if int(target.get("target", {}).get("lane", -1)) != 1:
			failures.append("Grid[%s]: el objetivo debía ser el carril central" % mode)
		if target.get("neighbors", []).size() != 2:
			failures.append("Grid[%s]: debía seleccionar dos vecinos" % mode)
		if str(target.get("mode", "")) != mode:
			failures.append("Grid[%s]: la selección debía informar su modo de ataque" % mode)
		grid.resolve_success()
		if not grid.front_cleared():
			failures.append("Grid[%s]: una respuesta correcta debía limpiar la fila FRENTE" % mode)
		grid.advance_rows()
		if grid.rows_left() != 3 or grid.queue_count() != 0:
			failures.append("Grid[%s]: las filas no avanzaron correctamente" % mode)

func _test_question_bank(failures: Array[String]) -> void:
	var qm = QuestionManager.new()
	if not qm.load_questions():
		failures.append("Banco: no se pudo cargar questions.json")
		return
	var expected_kinds := {
		1: {"teorico": 10, "practico": 10, "completar": 5, "multi": 5},
		2: {"teorico": 7, "practico": 11, "completar": 7, "multi": 5},
		3: {"teorico": 7, "practico": 11, "completar": 5, "multi": 5, "boss": 2}}
	for level in range(1, 4):
		var pool: Array = qm.pool_for(level)
		if pool.size() != 30:
			failures.append("Banco: el Nivel %d debía tener 30 ejercicios (tiene %d)" % [level, pool.size()])
		var counts := {}
		for question in pool:
			var kind := QuestionManager.kind_of(question)
			counts[kind] = int(counts.get(kind, 0)) + 1
			var id := int(question.get("id", -1))
			var options: Array = question.get("options", [])
			if options.size() != 4:
				failures.append("Banco #%d: debía tener 4 alternativas" % id)
			if not options.has(question.get("answer", "")):
				failures.append("Banco #%d: la respuesta no está entre las alternativas" % id)
			if str(question.get("hint", "")).is_empty() or str(question.get("explanation", "")).is_empty():
				failures.append("Banco #%d: falta pista o explicación" % id)
			if str(question.get("main_property", "")).is_empty():
				failures.append("Banco #%d: falta main_property" % id)
			if kind == "completar" and str(question.get("code", "")).is_empty():
				failures.append("Banco #%d: un ejercicio de completar necesita 'code'" % id)
			if kind != "teorico" and kind != "completar" and (question.get("effects", []) as Array).is_empty():
				failures.append("Banco #%d: un ejercicio práctico/multi/boss necesita efectos visuales" % id)
			for list_name in ["effects", "bug_effects"]:
				for effect in question.get(list_name, []):
					if not EnemyView.SUPPORTED_PROPERTIES.has(str(effect.get("property", ""))):
						failures.append("Banco #%d: propiedad sin soporte visual (%s)" % [id, effect.get("property", "")])
			for list_name in ["lane_effects", "lane_bug_effects"]:
				for lane_list in question.get(list_name, []):
					for effect in lane_list:
						if not EnemyView.SUPPORTED_PROPERTIES.has(str(effect.get("property", ""))):
							failures.append("Banco #%d: propiedad sin soporte visual (%s)" % [id, effect.get("property", "")])
		for kind in expected_kinds[level].keys():
			if int(counts.get(kind, 0)) != int(expected_kinds[level][kind]):
				failures.append("Banco: Nivel %d debía tener %d de tipo %s (tiene %d)" % [level, expected_kinds[level][kind], kind, counts.get(kind, 0)])

func _test_level_run(level: int, failures: Array[String]) -> void:
	var qm = QuestionManager.new()
	if not qm.load_questions():
		failures.append("LevelRun %d: no se pudo cargar questions.json" % level)
		return
	if not GameConfig.level_available(level):
		failures.append("LevelRun %d: el nivel debía estar disponible" % level)
		return
	var cfg: Dictionary = GameConfig.level(level)
	var session = FakeSession.new()
	var run = LevelRun.new()
	run.setup(level, cfg, qm, session)
	var ids: Array[int] = []
	var kinds_by_zone: Array = []
	for zone in range(4):
		var kinds: Array = []
		while not run.zone_clean(zone):
			var q: Dictionary = run.next_question(zone)
			var id := int(q.get("id", -1))
			if ids.has(id):
				failures.append("LevelRun %d: repitió una pregunta dentro del intento" % level)
			if int(q.get("level", 0)) != level:
				failures.append("LevelRun %d: usó una pregunta de otro nivel (#%d)" % [level, id])
			ids.append(id)
			kinds.append(QuestionManager.kind_of(q))
			run.answer(zone, q, str(q.get("answer", "")), 3, 1.0, q.get("options", []))
		kinds_by_zone.append(kinds)
		if kinds != (cfg.get("zone_sequences", [])[zone] as Array):
			failures.append("LevelRun %d: la zona %d no siguió su secuencia de tipos" % [level, zone + 1])
	if ids.size() != 15:
		failures.append("LevelRun %d: una partida perfecta debía usar 15 preguntas (usó %d)" % [level, ids.size()])
	var life_bonus := run.finalize_level()
	if life_bonus != 1000:
		failures.append("LevelRun %d: bono de vidas esperado 1000" % level)
	if run.score != int(PERFECT_SCORE[level]):
		failures.append("LevelRun %d: puntaje perfecto esperado %d, obtuvo %d" % [level, PERFECT_SCORE[level], run.score])
	if level == 3:
		var last_kinds: Array = kinds_by_zone[3]
		if last_kinds.back() != "boss":
			failures.append("LevelRun 3: la última fila del nivel debía ser el enemigo final")

	# Un error resta una vida, reinicia la racha y entrega una pregunta de reposición del mismo tipo.
	var run2 = LevelRun.new()
	run2.setup(level, cfg, qm, session)
	var first: Dictionary = run2.next_question(0)
	var result: Dictionary = run2.answer(0, first, "respuesta incorrecta", 0, 1.0, first.get("options", []))
	if bool(result.get("correct", true)) or run2.lives != int(cfg.get("lives", 5)) - 1:
		failures.append("LevelRun %d: un error debía restar una vida" % level)
	var replacement: Dictionary = run2.replace_question(first, 0)
	if replacement.is_empty() or QuestionManager.kind_of(replacement) != QuestionManager.kind_of(first):
		failures.append("LevelRun %d: la reposición debía ser del mismo tipo" % level)

func _test_flex_layout(failures: Array[String]) -> void:
	var depth_y := 330.0
	var base := FlexLayout.default_props()
	var row: Array = FlexLayout.positions(base, 3, depth_y)
	if row.size() != 3:
		failures.append("Flex: debía devolver 3 posiciones")
		return
	# Por defecto: fila pegada a la izquierda, en orden y sin superponerse.
	var x0: float = (row[0]["center"] as Vector2).x
	var x1: float = (row[1]["center"] as Vector2).x
	var x2: float = (row[2]["center"] as Vector2).x
	if not (x0 < x1 and x1 < x2) or absf((x1 - x0) - FlexLayout.ITEM) > 0.01:
		failures.append("Flex: la fila por defecto debía ir pegada y en orden")
	var centered: Array = FlexLayout.positions(FlexLayout.apply_effects(base, [{"property": "justify-content", "value": "center"}]), 3, depth_y)
	if absf((centered[1]["center"] as Vector2).x - 640.0) > 0.01:
		failures.append("Flex: justify-content: center debía centrar el grupo")
	var ended: Array = FlexLayout.positions(FlexLayout.apply_effects(base, [{"property": "justify-content", "value": "flex-end"}]), 3, depth_y)
	if (ended[2]["center"] as Vector2).x <= x2:
		failures.append("Flex: justify-content: flex-end debía mover el grupo a la derecha")
	var spaced: Array = FlexLayout.positions(FlexLayout.apply_effects(base, [{"property": "gap", "value": "20px"}]), 3, depth_y)
	if absf(((spaced[1]["center"] as Vector2).x - (spaced[0]["center"] as Vector2).x) - (FlexLayout.ITEM + 20.0)) > 0.01:
		failures.append("Flex: gap: 20px debía separar a los enemigos")
	var aligned: Array = FlexLayout.positions(FlexLayout.apply_effects(base, [{"property": "align-items", "value": "center"}]), 3, depth_y)
	if (aligned[0]["center"] as Vector2).y <= depth_y:
		failures.append("Flex: align-items: center debía desplazar al grupo en el eje transversal")
	var column: Array = FlexLayout.positions(FlexLayout.apply_effects(base, [{"property": "flex-direction", "value": "column"}]), 3, depth_y)
	if absf((column[0]["center"] as Vector2).x - (column[2]["center"] as Vector2).x) > 0.01 or (column[2]["center"] as Vector2).y <= (column[0]["center"] as Vector2).y:
		failures.append("Flex: flex-direction: column debía apilar a los enemigos en vertical")
	var wrap_start: Array = FlexLayout.positions(FlexLayout.apply_effects(base, [{"property": "align-content", "value": "flex-start"}]), 3, depth_y)
	var wrap_between: Array = FlexLayout.positions(FlexLayout.apply_effects(base, [{"property": "align-content", "value": "space-between"}]), 3, depth_y)
	if (wrap_between[2]["center"] as Vector2).y <= (wrap_start[2]["center"] as Vector2).y:
		failures.append("Flex: align-content: space-between debía separar las líneas")
	# Cualquier combinación de las usadas en el banco debe quedar dentro de la arena (86..1194 x 92..442).
	var combos: Array = []
	for direction in ["row", "column"]:
		for justify in ["flex-start", "center", "flex-end"]:
			for align in ["flex-start", "center", "flex-end"]:
				for gap in ["0px", "16px", "20px", "24px"]:
					combos.append([direction, justify, align, gap])
	for combo in combos:
		var props := FlexLayout.apply_effects(base, [
			{"property": "flex-direction", "value": combo[0]}, {"property": "justify-content", "value": combo[1]},
			{"property": "align-items", "value": combo[2]}, {"property": "gap", "value": combo[3]}])
		for item in FlexLayout.positions(props, 3, depth_y):
			var half: float = FlexLayout.ITEM * float(item["scale"]) * 0.5
			var center: Vector2 = item["center"]
			if center.x - half < 86.0 or center.x + half > 1194.0 or center.y - half < 92.0 or center.y + half > 442.0:
				failures.append("Flex: la combinación %s deja a un enemigo fuera de la arena (%s)" % [combo, center])
				return

func _test_badges_config(failures: Array[String]) -> void:
	var ids: Array = []
	for badge in GameConfig.badges():
		ids.append(str(badge.get("id", "")))
		var trigger := str(badge.get("trigger", ""))
		if not ["answer", "streak", "level_complete", "level_perfect", "all_levels"].has(trigger):
			failures.append("Insignias: '%s' tiene un trigger desconocido (%s)" % [badge.get("id", ""), trigger])
	for level in range(1, GameConfig.total_levels() + 1):
		var has_complete := false
		var has_perfect := false
		for badge in GameConfig.badges():
			if int(badge.get("level", 0)) == level and str(badge.get("trigger", "")) == "level_complete":
				has_complete = true
			if int(badge.get("level", 0)) == level and str(badge.get("trigger", "")) == "level_perfect":
				has_perfect = true
		if not has_complete or not has_perfect:
			failures.append("Insignias: el Nivel %d debía tener insignia de completar y de impecable" % level)
