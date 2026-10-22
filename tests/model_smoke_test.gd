extends SceneTree

const GameConfig = preload("res://scripts/managers/game_config.gd")
const QuestionManager = preload("res://scripts/managers/question_manager.gd")
const LevelRun = preload("res://scripts/managers/level_run.gd")
const ZoneGrid = preload("res://scripts/managers/zone_grid.gd")
const FlexLayout = preload("res://scripts/managers/flex_layout.gd")
const EnemyView = preload("res://scripts/enemy_view.gd")
const FeedbackBuilder = preload("res://scripts/managers/feedback_builder.gd")

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
	_test_life_recovery(failures)
	_test_feedback(failures)
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

# Siguiente ejercicio disponible en cualquier zona aún no limpia; responde bien o mal.
func _answer_next(run, correct: bool) -> Dictionary:
	for zone in range(4):
		if run.zone_clean(zone):
			continue
		var q: Dictionary = run.next_question(zone)
		var selected: String = str(q.get("answer", ""))
		if not correct:
			for option in q.get("options", []):
				if option != q.get("answer", ""):
					selected = option
					break
		return run.answer(zone, q, selected, 3, 1.0, q.get("options", []))
	return {}

func _test_life_recovery(failures: Array[String]) -> void:
	var qm = QuestionManager.new()
	qm.load_questions()
	var cfg: Dictionary = GameConfig.level(1)
	var run = LevelRun.new()
	run.setup(1, cfg, qm, FakeSession.new())
	var max_lives: int = int(cfg.get("lives", 5))
	# Con las vidas al máximo, una racha de 5 no suma vidas.
	for i in range(5):
		var result: Dictionary = _answer_next(run, true)
		if bool(result.get("life_gained", false)):
			failures.append("Vidas: con las vidas completas no debía recuperar más")
	if run.lives != max_lives or run.lives_regained != 0:
		failures.append("Vidas: no debía pasar del máximo")
	# Un error resta una vida y reinicia la racha.
	_answer_next(run, false)
	if run.lives != max_lives - 1 or run.streak != 0:
		failures.append("Vidas: el error debía restar una vida y reiniciar la racha")
	# Cuatro aciertos seguidos todavía no recuperan; el quinto sí.
	for i in range(4):
		var partial: Dictionary = _answer_next(run, true)
		if bool(partial.get("life_gained", false)):
			failures.append("Vidas: se recuperó antes del quinto acierto seguido")
	if run.lives != max_lives - 1:
		failures.append("Vidas: no debía haber recuperado todavía")
	var fifth: Dictionary = _answer_next(run, true)
	if not bool(fifth.get("life_gained", false)) or run.lives != max_lives or run.lives_regained != 1:
		failures.append("Vidas: el quinto acierto seguido debía recuperar una vida")
	# Un error en mitad de la racha cancela la recuperación.
	_answer_next(run, false)
	for i in range(3):
		_answer_next(run, true)
	_answer_next(run, false)
	for i in range(4):
		_answer_next(run, true)
	if run.lives_regained != 1:
		failures.append("Vidas: una racha interrumpida no debía recuperar vida")
	var review: Array = run.review_properties()
	if review.is_empty() or int(review[0].get("count", 0)) < 1:
		failures.append("Repaso: debía listar las propiedades falladas")
	if int(run.session_result().get("lives_regained", -1)) != run.lives_regained:
		failures.append("Vidas: session_result debía informar las vidas recuperadas")

func _question_by_id(qm, id: int) -> Dictionary:
	for level in range(1, 4):
		for question in qm.pool_for(level):
			if int(question.get("id", -1)) == id:
				return question
	return {}

func _test_feedback(failures: Array[String]) -> void:
	var qm = QuestionManager.new()
	qm.load_questions()
	# Casos concretos.
	var q2: Dictionary = _question_by_id(qm, 2)            # Enemigo con texto rojo -> color: red;
	var wrong_property: String = FeedbackBuilder.diagnose(q2, "background-color: red;")
	if not wrong_property.contains("background-color") or not wrong_property.contains("color del texto"):
		failures.append("Feedback: debía explicar que background-color no controla el texto (%s)" % wrong_property)
	var wrong_value: String = FeedbackBuilder.diagnose(q2, "color: blue;")
	if not wrong_value.contains("valor"):
		failures.append("Feedback: debía indicar que el valor no coincide (%s)" % wrong_value)
	var q50: Dictionary = _question_by_id(qm, 50)          # border-radius: 12px;
	if not FeedbackBuilder.diagnose(q50, "border-radius: 12%;").ends_with("revisa la unidad."):
		failures.append("Feedback: border-radius: 12%; debía señalar solo la unidad (%s)" % FeedbackBuilder.diagnose(q50, "border-radius: 12%;"))
	var q58: Dictionary = _question_by_id(qm, 58)          # border: 4px solid black; + border-radius: 50%;
	if not FeedbackBuilder.diagnose(q58, "border: 4px dotted black; + border-radius: 0;").contains("estilo o el color del borde"):
		failures.append("Feedback: dotted en vez de solid debía señalar el estilo del borde")
	var q70: Dictionary = _question_by_id(qm, 70)          # border-radius: 50%; + transform: rotate(45deg);
	if not FeedbackBuilder.diagnose(q70, "border-radius: 50%; + transform: skew(45deg);").contains("la función"):
		failures.append("Feedback: skew en vez de rotate debía señalar la función")
	if not FeedbackBuilder.diagnose(_question_by_id(qm, 60), "width: 50px; + height: 50px; + border-radius: 150px;").contains("revisa el número"):
		failures.append("Feedback: un ancho distinto debía señalar el número")
	var q56: Dictionary = _question_by_id(qm, 56)          # width + height
	if not FeedbackBuilder.diagnose(q56, "width: 100px; + padding: 100px;").contains("padding"):
		failures.append("Feedback: debía señalar la propiedad que sobra en la combinación")
	if FeedbackBuilder.diagnose(_question_by_id(qm, 1), "Cambia el color del fondo").length() != 0:
		failures.append("Feedback: una alternativa teórica no debía tener diagnóstico específico")
	# Todas las alternativas incorrectas de los 90 ejercicios.
	var with_diagnosis := 0
	for level in range(1, 4):
		for question in qm.pool_for(level):
			var id := int(question.get("id", -1))
			var answer: String = str(question.get("answer", ""))
			for option in question.get("options", []):
				if option == answer:
					continue
				var detail: String = FeedbackBuilder.error_detail(question, option)
				if detail.is_empty():
					failures.append("Feedback #%d: la alternativa '%s' quedó sin pista ni diagnóstico" % [id, option])
				var diagnosis: String = FeedbackBuilder.diagnose(question, option)
				if not diagnosis.is_empty():
					with_diagnosis += 1
					# Se compara con la declaración completa ("color: red;"): para respuestas de una sola
					# propiedad ("color") la categoría ("el color del texto") es justo el andamiaje buscado.
					if answer.contains(":") and diagnosis.contains(answer):
						failures.append("Feedback #%d: el diagnóstico no debe revelar la respuesta ('%s')" % [id, diagnosis])
					if diagnosis.length() > 190:
						failures.append("Feedback #%d: diagnóstico demasiado largo para la tarjeta (%d)" % [id, diagnosis.length()])
	if with_diagnosis < 150:
		failures.append("Feedback: se esperaba diagnóstico específico en la mayoría de las alternativas (%d)" % with_diagnosis)
