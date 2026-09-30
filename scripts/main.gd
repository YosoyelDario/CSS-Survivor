extends Node

# MAIN ahora solo coordina los módulos. La lógica específica vive en otras pestañas/scripts.
const InputConfig = preload("res://scripts/managers/input_config.gd")
const QuestionManager = preload("res://scripts/managers/question_manager.gd")
const LogManager = preload("res://scripts/managers/log_manager.gd")
const WorldController = preload("res://scripts/world_controller.gd")
const MenuUI = preload("res://scripts/ui/menu_ui.gd")
const HUDUI = preload("res://scripts/ui/hud_ui.gd")
const CombatUI = preload("res://scripts/ui/combat_ui.gd")
const SummaryUI = preload("res://scripts/ui/summary_ui.gd")
const GameOverUI = preload("res://scripts/ui/gameover_ui.gd")
const EvaluationUI = preload("res://scripts/ui/evaluation_ui.gd")

const MAX_LIVES := 5
const BUG_HP := 3
const INTERACT_DISTANCE := 118.0

var question_manager
var log_manager
var world_controller
var menu_ui
var hud_ui
var combat_ui
var summary_ui
var gameover_ui
var evaluation_ui

var current_bug
var current_question: Dictionary = {}
var question_started_ms: int = 0

var current_level := 1
var lives := MAX_LIVES
var points := 0
var level_correct := 0
var level_attempts: Array = []
var player_id := "JUGADOR_01"
var game_active := false
var combat_open := false
var summary_open := false
var level_complete_pending := false

var evaluation_open := false
var evaluation_mode := ""
var evaluation_questions: Array = []
var evaluation_index := 0
var evaluation_score := 0
var pretest_score := 0
var posttest_score := 0

func _ready() -> void:
	InputConfig.configure()
	randomize()
	_create_managers()
	_create_world()
	_create_interfaces()
	_show_menu()

func _process(_delta: float) -> void:
	if not game_active or combat_open or summary_open or evaluation_open:
		return
	var nearest = world_controller.nearest_bug(INTERACT_DISTANCE)
	if nearest != null:
		hud_ui.show_interaction("[E / ESPACIO] Enfrentar BUG • responde CSS para dañarlo")
		if Input.is_action_just_pressed("interact"):
			_start_combat(nearest)
	else:
		hud_ui.hide_interaction()

func _create_managers() -> void:
	question_manager = QuestionManager.new()
	question_manager.load_questions()
	log_manager = LogManager.new()

func _create_world() -> void:
	world_controller = WorldController.new()
	world_controller.name = "WorldController"
	add_child(world_controller)
	world_controller.setup(BUG_HP)
	world_controller.zone_cleared.connect(_on_zone_cleared)

func _create_interfaces() -> void:
	menu_ui = MenuUI.new()
	add_child(menu_ui)
	menu_ui.start_requested.connect(_start_game_from_menu)

	hud_ui = HUDUI.new()
	add_child(hud_ui)

	combat_ui = CombatUI.new()
	add_child(combat_ui)
	combat_ui.answer_selected.connect(_on_answer_pressed)

	summary_ui = SummaryUI.new()
	add_child(summary_ui)
	summary_ui.primary_requested.connect(_on_summary_primary)
	summary_ui.menu_requested.connect(_return_to_menu)

	gameover_ui = GameOverUI.new()
	add_child(gameover_ui)
	gameover_ui.retry_requested.connect(_retry_level)
	gameover_ui.menu_requested.connect(_return_to_menu)

	evaluation_ui = EvaluationUI.new()
	add_child(evaluation_ui)
	evaluation_ui.answer_selected.connect(_on_evaluation_answer)

# -----------------------------------------------------------------------------
# Flujo general / niveles
# -----------------------------------------------------------------------------
func _start_game_from_menu(new_player_id: String) -> void:
	player_id = new_player_id
	points = 0
	pretest_score = 0
	posttest_score = 0
	menu_ui.set_message("")
	_start_pretest()

func _start_level(level: int) -> void:
	current_level = level
	lives = MAX_LIVES
	level_correct = 0
	level_attempts.clear()
	level_complete_pending = false
	question_manager.refill_bag(level)
	world_controller.start_level(level)
	game_active = true
	hud_ui.visible = true
	menu_ui.hide_menu()
	_update_hud()

func _on_zone_cleared(_zone_index: int) -> void:
	_update_hud()
	if world_controller.cleared_zone_count() >= 4:
		level_complete_pending = true

func _show_menu() -> void:
	game_active = false
	combat_open = false
	summary_open = false
	evaluation_open = false
	world_controller.set_player_movement(false)
	world_controller.set_game_visible(false)
	hud_ui.visible = false
	hud_ui.hide_interaction()
	combat_ui.hide_immediate()
	summary_ui.hide_summary()
	gameover_ui.hide_game_over()
	evaluation_ui.hide_evaluation()
	menu_ui.show_menu()

func _return_to_menu() -> void:
	summary_ui.hide_summary()
	gameover_ui.hide_game_over()
	_show_menu()

# -----------------------------------------------------------------------------
# Combate
# -----------------------------------------------------------------------------
func _start_combat(bug: Node2D) -> void:
	if bug == null or not bug.active or combat_open:
		return
	current_bug = bug
	combat_open = true
	world_controller.set_player_movement(false)
	hud_ui.hide_interaction()
	_prepare_next_combat_question()
	combat_ui.set_battle_state(current_level, bug.hp, bug.max_hp, bug.active, bug.zone_index)
	combat_ui.set_buttons_enabled(false)
	await combat_ui.animate_encounter(world_controller.player, bug)
	combat_ui.set_buttons_enabled(true)

func _prepare_next_combat_question() -> void:
	current_question = question_manager.next_random(current_level)
	question_started_ms = Time.get_ticks_msec()
	var hint := ""
	if current_bug.failures >= 2:
		hint = "PISTA: esta pregunta pertenece a la categoría %s." % question_manager.category_for_level(current_level)
	combat_ui.show_question(
		current_question,
		question_manager.options_for(current_question),
		current_bug.zone_index + 1,
		current_bug.hp,
		current_bug.max_hp,
		hint
	)

func _on_answer_pressed(answer: String) -> void:
	if not combat_open:
		return
	combat_ui.set_buttons_enabled(false)
	var correct_answer := str(current_question["answer"])
	var is_correct := answer == correct_answer
	var elapsed_ms: int = maxi(0, Time.get_ticks_msec() - question_started_ms)

	if is_correct:
		level_correct += 1
		var speed_bonus: int = clampi(80 - int(elapsed_ms / 250), 0, 80)
		var gained := 100 + speed_bonus
		points += gained
		combat_ui.set_feedback("✓ CORRECTO  +%d pts • ataque CSS ejecutado." % gained, true)
		await combat_ui.animate_projectile(true)
		await combat_ui.flash_hit(true)
		current_bug.hit()
		world_controller.set_zone_progress(current_bug.zone_index, 1.0 - (float(current_bug.hp) / float(current_bug.max_hp)))
		combat_ui.set_battle_state(current_level, current_bug.hp, current_bug.max_hp, current_bug.active, current_bug.zone_index)
	else:
		lives = max(0, lives - 1)
		current_bug.failures += 1
		combat_ui.set_feedback("✕ INCORRECTO • el virus contraataca y pierdes una vida.", false)
		await combat_ui.animate_projectile(false)
		await combat_ui.flash_hit(false)
		if current_bug.failures >= 2:
			combat_ui.set_hint("PISTA: categoría %s. Revisa las propiedades de este nivel." % question_manager.category_for_level(current_level))

	var record := {
		"event_type": "game_attempt",
		"timestamp": Time.get_datetime_string_from_system(),
		"idJugador": player_id,
		"nivel": current_level,
		"zona": current_bug.zone_index + 1,
		"pregunta_id": int(current_question["id"]),
		"pregunta": str(current_question["question"]),
		"alternativas": combat_ui.get_option_texts(),
		"respuestaJugador": answer,
		"respuestaCorrecta": correct_answer,
		"siFueCorrectoNo": is_correct,
		"tiempoDeRespuestaMs": elapsed_ms
	}
	level_attempts.append(record)
	log_manager.append(record)
	_update_hud()

	await get_tree().create_timer(0.85).timeout
	if lives <= 0:
		combat_ui.hide_immediate()
		combat_open = false
		_show_game_over()
		return

	if not current_bug.active:
		combat_ui.set_feedback("✓ BUG ELIMINADO • zona reparada.", true)
		await get_tree().create_timer(0.55).timeout
		await _exit_combat_to_map()
	else:
		_prepare_next_combat_question()
		combat_ui.set_battle_state(current_level, current_bug.hp, current_bug.max_hp, current_bug.active, current_bug.zone_index)

func _exit_combat_to_map() -> void:
	await combat_ui.close_to_map()
	combat_open = false
	if level_complete_pending:
		world_controller.set_player_movement(false)
		await get_tree().create_timer(0.35).timeout
		_show_level_summary()
	else:
		world_controller.set_player_movement(true)

# -----------------------------------------------------------------------------
# Resumen KCR / fin de nivel
# -----------------------------------------------------------------------------
func _show_level_summary() -> void:
	summary_open = true
	game_active = false
	world_controller.set_player_movement(false)
	summary_ui.show_level(current_level, level_correct, level_attempts, points)
	log_manager.append({
		"event_type":"level_summary",
		"timestamp":Time.get_datetime_string_from_system(),
		"idJugador":player_id,
		"nivel":current_level,
		"aciertos":level_correct,
		"intentos":level_attempts.size(),
		"puntajeTotal":points
	})

func _on_summary_primary(action: String) -> void:
	summary_ui.hide_summary()
	summary_open = false
	match action:
		"next_level":
			_start_level(current_level + 1)
		"posttest":
			_start_posttest()
		"menu":
			_return_to_menu()

# -----------------------------------------------------------------------------
# Pre-test / Post-test
# -----------------------------------------------------------------------------
func _start_pretest() -> void:
	evaluation_questions = question_manager.prepare_evaluation_set()
	evaluation_mode = "pre"
	evaluation_index = 0
	evaluation_score = 0
	evaluation_open = true
	menu_ui.hide_menu()
	hud_ui.visible = false
	world_controller.set_game_visible(false)
	_show_evaluation_question()

func _start_posttest() -> void:
	evaluation_mode = "post"
	evaluation_index = 0
	evaluation_score = 0
	evaluation_open = true
	hud_ui.visible = false
	world_controller.set_game_visible(false)
	_show_evaluation_question()

func _show_evaluation_question() -> void:
	if evaluation_index >= evaluation_questions.size():
		_finish_evaluation()
		return
	var question: Dictionary = evaluation_questions[evaluation_index]
	evaluation_ui.show_question(
		evaluation_mode,
		evaluation_index,
		evaluation_questions.size(),
		question,
		question_manager.options_for(question)
	)

func _on_evaluation_answer(answer: String) -> void:
	if not evaluation_open or evaluation_index >= evaluation_questions.size():
		return
	var question: Dictionary = evaluation_questions[evaluation_index]
	evaluation_ui.set_buttons_enabled(false)
	var ok := answer == str(question["answer"])
	if ok:
		evaluation_score += 1
	evaluation_ui.set_feedback("✓ Respuesta registrada" if ok else "Respuesta registrada", ok)
	log_manager.append({
		"event_type": "%stest_attempt" % evaluation_mode,
		"timestamp": Time.get_datetime_string_from_system(),
		"idJugador": player_id,
		"pregunta_id": int(question["id"]),
		"nivel_oa": int(question["level"]),
		"respuestaJugador": answer,
		"respuestaCorrecta": str(question["answer"]),
		"siFueCorrectoNo": ok
	})
	await get_tree().create_timer(0.55).timeout
	evaluation_index += 1
	_show_evaluation_question()

func _finish_evaluation() -> void:
	if evaluation_mode == "pre":
		pretest_score = evaluation_score
		log_manager.append({"event_type":"pretest_summary","timestamp":Time.get_datetime_string_from_system(),"idJugador":player_id,"score":pretest_score,"total":evaluation_questions.size()})
		evaluation_ui.hide_evaluation()
		evaluation_open = false
		_start_level(1)
	else:
		posttest_score = evaluation_score
		log_manager.append({"event_type":"posttest_summary","timestamp":Time.get_datetime_string_from_system(),"idJugador":player_id,"score":posttest_score,"total":evaluation_questions.size()})
		evaluation_ui.hide_evaluation()
		evaluation_open = false
		_show_final_results()

func _show_final_results() -> void:
	summary_open = true
	summary_ui.show_final(pretest_score, posttest_score, evaluation_questions.size(), points, log_manager.full_path())

# -----------------------------------------------------------------------------
# Game Over / HUD
# -----------------------------------------------------------------------------
func _show_game_over() -> void:
	game_active = false
	world_controller.set_player_movement(false)
	gameover_ui.show_game_over()

func _retry_level() -> void:
	gameover_ui.hide_game_over()
	_start_level(current_level)

func _update_hud() -> void:
	var max_hits := 4 * BUG_HP
	var repair_percent := 100.0 * float(level_correct) / float(max_hits)
	hud_ui.update_hud(lives, MAX_LIVES, points, current_level, world_controller.cleared_zone_count(), repair_percent)
