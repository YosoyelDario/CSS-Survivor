extends SceneTree

const GameConfig = preload("res://scripts/managers/game_config.gd")
const QuestionManager = preload("res://scripts/managers/question_manager.gd")
const LevelRun = preload("res://scripts/managers/level_run.gd")
const ZoneGrid = preload("res://scripts/managers/zone_grid.gd")

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
	_test_level_run(failures)
	if failures.is_empty():
		print("CSS Survivor model smoke test: OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _test_grid(failures: Array[String]) -> void:
	var grid = ZoneGrid.new()
	grid.setup(0, 4, 3, 3, "adjacent")
	if grid.rows_left() != 4:
		failures.append("Grid: debía iniciar con 4 filas")
	var target := grid.target_and_neighbors()
	if int(target.get("target", {}).get("lane", -1)) != 1:
		failures.append("Grid: el objetivo debía ser el carril central")
	if target.get("neighbors", []).size() != 2:
		failures.append("Grid: debía seleccionar dos vecinos")
	grid.resolve_success()
	if not grid.front_cleared():
		failures.append("Grid: una respuesta correcta debía limpiar la fila FRENTE")
	grid.advance_rows()
	if grid.rows_left() != 3 or grid.queue_count() != 0:
		failures.append("Grid: las filas no avanzaron correctamente")

func _test_level_run(failures: Array[String]) -> void:
	var qm = QuestionManager.new()
	if not qm.load_questions():
		failures.append("LevelRun: no se pudo cargar questions.json")
		return
	var session = FakeSession.new()
	var run = LevelRun.new()
	run.setup(1, GameConfig.level(1), qm, session)
	var ids: Array[int] = []
	for zone in range(4):
		while not run.zone_clean(zone):
			var q: Dictionary = run.next_question(zone)
			var id := int(q.get("id", -1))
			if ids.has(id):
				failures.append("LevelRun: repitió una pregunta dentro del intento")
			ids.append(id)
			run.answer(zone, q, str(q.get("answer", "")), 3, 1.0, q.get("options", []))
	if ids.size() != 15:
		failures.append("LevelRun: una partida perfecta debía usar 15 preguntas")
	var life_bonus := run.finalize_level()
	if life_bonus != 1000:
		failures.append("LevelRun: bono de vidas esperado 1000")
	if run.score != 5250:
		failures.append("LevelRun: puntaje perfecto esperado 5250, obtuvo %d" % run.score)
