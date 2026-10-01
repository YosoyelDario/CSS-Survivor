extends Node

const InputConfig=preload("res://scripts/managers/input_config.gd")
const GameConfig=preload("res://scripts/managers/game_config.gd")
const SessionManager=preload("res://scripts/managers/session_manager.gd")
const LogManager=preload("res://scripts/managers/log_manager.gd")
const QuestionManager=preload("res://scripts/managers/question_manager.gd")
const LevelRun=preload("res://scripts/managers/level_run.gd")
const ZoneGrid=preload("res://scripts/managers/zone_grid.gd")
const WorldController=preload("res://scripts/world_controller.gd")

const LoginUI=preload("res://scripts/ui/login_ui.gd")
const MenuUI=preload("res://scripts/ui/menu_ui.gd")
const LevelsUI=preload("res://scripts/ui/levels_ui.gd")
const AchievementsUI=preload("res://scripts/ui/achievements_ui.gd")
const RankingUI=preload("res://scripts/ui/ranking_ui.gd")
const HowToUI=preload("res://scripts/ui/howto_ui.gd")
const HUDUI=preload("res://scripts/ui/hud_ui.gd")
const CombatUI=preload("res://scripts/ui/combat_ui.gd")
const ResultsUI=preload("res://scripts/ui/results_ui.gd")
const PauseUI=preload("res://scripts/ui/pause_ui.gd")
const EvaluationUI=preload("res://scripts/ui/evaluation_ui.gd")

const INTERACT_DISTANCE:=125.0

var session_manager
var log_manager
var question_manager
var world_controller
var level_run
var zone_grids:Array=[]

var login_ui
var menu_ui
var levels_ui
var achievements_ui
var ranking_ui
var howto_ui
var hud_ui
var combat_ui
var results_ui
var pause_ui
var evaluation_ui

var game_active:=false
var combat_open:=false
var paused:=false
var awaiting_continue:=false
var current_zone:int=-1
var current_question:Dictionary={}
var current_options:Array[String]=[]
var question_started_ms:int=0
var new_badges:Array=[]

func _ready()->void:
	InputConfig.configure()
	randomize()
	_create_managers()
	_create_world()
	_create_interfaces()
	_show_login()

func _process(_delta:float)->void:
	if Input.is_action_just_pressed("pause_game") and game_active and not results_ui.root.visible:
		_toggle_pause()
		return
	if not game_active or paused or combat_open:
		return
	var nearest=world_controller.nearest_bug(INTERACT_DISTANCE)
	if nearest!=null:
		hud_ui.show_interaction("Pulsa E para enfrentar • %s • %d fila(s)"%[nearest.zone_name,nearest.rows_left])
		if Input.is_action_just_pressed("interact"):
			_start_combat(nearest.zone_index)
	else:
		hud_ui.hide_interaction()

func _create_managers()->void:
	session_manager=SessionManager.new()
	log_manager=LogManager.new()
	question_manager=QuestionManager.new()
	question_manager.load_questions()

func _create_world()->void:
	world_controller=WorldController.new()
	world_controller.name="WorldController"
	add_child(world_controller)
	world_controller.setup()
	world_controller.set_game_visible(false)

func _create_interfaces()->void:
	login_ui=LoginUI.new(); add_child(login_ui)
	login_ui.login_requested.connect(_on_login_requested)
	login_ui.create_requested.connect(_on_create_profile_requested)
	menu_ui=MenuUI.new(); add_child(menu_ui)
	# JUGAR continúa en el primer nivel jugable que aún no está completado (o rejuega el 1).
	menu_ui.play_requested.connect(func():_start_level(session_manager.next_playable_level()))
	menu_ui.levels_requested.connect(_show_levels)
	menu_ui.achievements_requested.connect(_show_achievements)
	menu_ui.ranking_requested.connect(_show_ranking)
	menu_ui.howto_requested.connect(_show_howto)
	menu_ui.change_user_requested.connect(_change_user)
	menu_ui.exit_requested.connect(func():get_tree().quit())
	levels_ui=LevelsUI.new(); add_child(levels_ui)
	levels_ui.play_level.connect(_start_level)
	levels_ui.back_requested.connect(_show_menu)
	achievements_ui=AchievementsUI.new(); add_child(achievements_ui); achievements_ui.back_requested.connect(_show_menu)
	ranking_ui=RankingUI.new(); add_child(ranking_ui); ranking_ui.back_requested.connect(_show_menu)
	howto_ui=HowToUI.new(); add_child(howto_ui); howto_ui.back_requested.connect(_show_menu)
	hud_ui=HUDUI.new(); add_child(hud_ui)
	combat_ui=CombatUI.new(); add_child(combat_ui)
	combat_ui.answer_selected.connect(_on_answer_selected)
	combat_ui.continue_requested.connect(_on_continue_after_error)
	results_ui=ResultsUI.new(); add_child(results_ui)
	# REINTENTAR repite el nivel que se acaba de jugar, no siempre el 1.
	results_ui.retry_requested.connect(func():_start_level(level_run.level))
	results_ui.next_requested.connect(_start_level)
	results_ui.ranking_requested.connect(_ranking_from_results)
	results_ui.menu_requested.connect(_show_menu)
	pause_ui=PauseUI.new(); add_child(pause_ui)
	pause_ui.continue_requested.connect(_resume_from_pause)
	pause_ui.menu_requested.connect(_abandon_to_menu)
	# El pre/post test existente se conserva, pero queda inactivo porque pretest_active=false.
	evaluation_ui=EvaluationUI.new(); add_child(evaluation_ui); evaluation_ui.hide_evaluation()

func _show_login()->void:
	_hide_non_login()
	login_ui.show_login()

func _on_login_requested(email:String)->void:
	if not session_manager.valid_email(email):
		login_ui.set_message("Ingresa un correo válido.")
		return
	if session_manager.login(email):
		login_ui.hide_login()
		_show_menu()
	else:
		login_ui.set_message("Correo nuevo: crea tu perfil para continuar.")
		login_ui.show_new_profile()

func _on_create_profile_requested(email:String,alias_value:String,consent:bool)->void:
	if not session_manager.valid_email(email):
		login_ui.set_message("El correo no tiene un formato válido.")
		return
	if alias_value.length()<2 or alias_value.length()>20:
		login_ui.set_message("El alias debe tener entre 2 y 20 caracteres.")
		return
	if not consent:
		login_ui.set_message("Debes aceptar el consentimiento para continuar.")
		return
	if not session_manager.create_profile(email,alias_value,consent):
		login_ui.set_message("No se pudo crear el perfil.")
		return
	login_ui.hide_login()
	_show_menu()

func _change_user()->void:
	session_manager.logout()
	_show_login()

func _show_menu()->void:
	game_active=false
	combat_open=false
	paused=false
	awaiting_continue=false
	world_controller.set_player_movement(false)
	world_controller.set_game_visible(false)
	hud_ui.set_hud_visible(false)
	combat_ui.hide_combat()
	results_ui.hide_results()
	levels_ui.hide_levels(); achievements_ui.hide_achievements(); ranking_ui.hide_ranking(); howto_ui.hide_howto(); pause_ui.hide_pause(); login_ui.hide_login()
	menu_ui.show_menu(session_manager.alias(),session_manager.total_points(),session_manager.badge_count(),session_manager.completed_levels(),GameConfig.total_levels(),session_manager.level_completed(1))

func _hide_menu_pages()->void:
	menu_ui.hide_menu(); levels_ui.hide_levels(); achievements_ui.hide_achievements(); ranking_ui.hide_ranking(); howto_ui.hide_howto(); results_ui.hide_results(); login_ui.hide_login()

func _hide_non_login()->void:
	game_active=false; combat_open=false; paused=false
	world_controller.set_player_movement(false); world_controller.set_game_visible(false)
	hud_ui.set_hud_visible(false); combat_ui.hide_combat(); results_ui.hide_results(); menu_ui.hide_menu(); levels_ui.hide_levels(); achievements_ui.hide_achievements(); ranking_ui.hide_ranking(); howto_ui.hide_howto(); pause_ui.hide_pause()

func _show_levels()->void:
	menu_ui.hide_menu(); levels_ui.show_levels(session_manager)
func _show_achievements()->void:
	menu_ui.hide_menu(); achievements_ui.show_achievements(session_manager)
func _show_ranking()->void:
	menu_ui.hide_menu(); ranking_ui.show_ranking(session_manager)
func _show_howto()->void:
	menu_ui.hide_menu(); howto_ui.show_howto()
func _ranking_from_results()->void:
	results_ui.hide_results(); ranking_ui.show_ranking(session_manager)

func _start_level(level:int)->void:
	if not GameConfig.level_available(level):
		push_warning("Nivel %d no disponible todavía."%level)
		return
	_hide_menu_pages()
	new_badges.clear()
	var cfg:=GameConfig.level(level)
	level_run=LevelRun.new()
	level_run.setup(level,cfg,question_manager,session_manager)
	zone_grids.clear()
	var rows:Array=cfg.get("zone_rows",[3,4,4,4])
	for i in range(rows.size()):
		var grid=ZoneGrid.new()
		grid.setup(i,int(rows[i]),int(cfg.get("lanes",3)),int(cfg.get("visible_rows",3)),str(cfg.get("attack_mode","adjacent")))
		zone_grids.append(grid)
	world_controller.start_level(level,cfg,level_run.zone_rows_left)
	world_controller.set_game_visible(true)
	world_controller.set_player_movement(true)
	hud_ui.set_hud_visible(true)
	game_active=true; combat_open=false; paused=false; awaiting_continue=false
	_update_hud()

func _update_hud()->void:
	if level_run==null:
		return
	hud_ui.update_hud(level_run.lives,int(level_run.config.get("lives",5)),level_run.score,GameConfig.level_short(level_run.level),world_controller.cleared_zone_count(),level_run.repair_percent()*100.0)

func _start_combat(zone_index:int)->void:
	if zone_index<0 or zone_index>=zone_grids.size() or level_run.zone_clean(zone_index):
		return
	current_zone=zone_index
	combat_open=true
	awaiting_continue=false
	world_controller.set_player_movement(false)
	hud_ui.hide_interaction()
	var cfg: Dictionary = level_run.config
	var names: Array = cfg.get("zone_names", []) as Array
	var difficulty: Array = cfg.get("zone_difficulty", []) as Array
	combat_ui.show_combat(zone_grids[zone_index],zone_index,str(names[zone_index]),str(difficulty[zone_index]))
	await combat_ui.animate_open()
	_prepare_question()

func _prepare_question(replacement:Dictionary={})->void:
	if level_run==null or current_zone<0:
		return
	current_question=replacement if not replacement.is_empty() else level_run.next_question(current_zone)
	if current_question.is_empty():
		push_error("No se pudo obtener una pregunta para la zona %d."%current_zone)
		return
	current_options=question_manager.options_for(current_question)
	question_started_ms=Time.get_ticks_msec()
	var row_number: int = int(level_run.rows_cleared(current_zone)) + 1
	combat_ui.update_header(level_run.lives,int(level_run.config.get("lives",5)),level_run.score,row_number,level_run.rows_total(current_zone),level_run.zone_repair_percent(current_zone))
	combat_ui.show_question(current_question,current_options)
	combat_ui.mark_selection(zone_grids[current_zone].target_and_neighbors())

func _on_answer_selected(answer: String) -> void:
	if not combat_open or paused or current_question.is_empty():
		return

	combat_ui.set_buttons_enabled(false)

	var response_time: float = float(
		maxi(0, Time.get_ticks_msec() - question_started_ms)
	) / 1000.0

	var correct: bool = answer == str(
		current_question.get("answer", "")
	)

	var grid = zone_grids[current_zone]

	var selection: Dictionary = grid.target_and_neighbors()

	var affected: Array = selection.get("affected", []) as Array
	var affected_count: int = affected.size() if correct else 0

	var row_number: int = int(
		level_run.rows_cleared(current_zone)
	) + 1

	var result: Dictionary = level_run.answer(
		current_zone,
		current_question,
		answer,
		affected_count,
		response_time,
		current_options
	)

	_write_answer_log(
		answer,
		correct,
		response_time,
		row_number,
		affected_count
	)

	var awarded_badges: Array = session_manager.evaluate_badges_answer(
		level_run,
		correct
	)

	for badge_id in awarded_badges:
		var badge_name: String = _badge_name(str(badge_id))

		if not new_badges.has(badge_name):
			new_badges.append(badge_name)

	_update_hud()

	if correct:
		var base_points: int = int(
			result.get("base_points", 0)
		)

		var bonus_points: int = int(
			result.get("bonus", 0)
		)

		var gained: int = base_points + bonus_points

		combat_ui.show_feedback(
			true,
			"CORRECTO   +%d PTS" % gained
		)

		var effects: Array = current_question.get(
			"effects",
			[]
		) as Array

		await combat_ui.animate_attack(
			selection,
			effects
		)

		grid.resolve_success()

		if grid.front_cleared():
			grid.advance_rows()

		var rows_left: int = int(
			level_run.rows_left(current_zone)
		)

		var repair_percent: float = float(
			level_run.zone_repair_percent(current_zone)
		)

		world_controller.update_zone(
			current_zone,
			rows_left,
			repair_percent
		)

		var next_row_number: int = int(
			level_run.rows_cleared(current_zone)
		) + 1

		var total_rows: int = int(
			level_run.rows_total(current_zone)
		)

		var max_lives: int = int(
			level_run.config.get("lives", 5)
		)

		combat_ui.update_header(
			level_run.lives,
			max_lives,
			level_run.score,
			next_row_number,
			total_rows,
			repair_percent
		)

		if level_run.zone_clean(current_zone):
			await get_tree().create_timer(0.35).timeout
			await _return_to_map_or_finish()
		else:
			await combat_ui.animate_advance(grid)
			_prepare_question()

	else:
		awaiting_continue = true

		var hint: String = str(
			current_question.get("hint", "")
		)

		combat_ui.show_feedback(
			false,
			"INCORRECTO   -1 VIDA",
			hint
		)

		var max_lives: int = int(
			level_run.config.get("lives", 5)
		)

		var total_rows: int = int(
			level_run.rows_total(current_zone)
		)

		var repair_percent: float = float(
			level_run.zone_repair_percent(current_zone)
		)

		combat_ui.update_header(
			level_run.lives,
			max_lives,
			level_run.score,
			row_number,
			total_rows,
			repair_percent
		)
func _on_continue_after_error() -> void:
	if not combat_open or not awaiting_continue or paused:
		return

	awaiting_continue = false

	if level_run.game_over():
		_end_attempt(true)
		return

	var replacement: Dictionary = level_run.replace_question(
		current_question,
		current_zone
	)

	if replacement.is_empty():
		push_error("No se pudo obtener una pregunta de reposición.")
		return

	_prepare_question(replacement)

func _return_to_map_or_finish()->void:
	await combat_ui.animate_close()
	combat_open=false
	if level_run.all_zones_clean():
		_end_attempt(false)
	else:
		world_controller.set_player_movement(true)
		_update_hud()

func _end_attempt(game_over: bool) -> void:
	if combat_open:
		combat_ui.hide_combat()

	combat_open = false
	game_active = false

	world_controller.set_player_movement(false)
	hud_ui.set_hud_visible(false)

	if not game_over:
		level_run.finalize_level()

	var before_color: bool = bool(
		session_manager.has_badge("color_master")
	)

	var before_perfect: bool = bool(
		session_manager.has_badge("perfect")
	)

	var session_result: Dictionary = level_run.session_result(false)

	session_manager.register_attempt(session_result)

	var has_color_master: bool = bool(
		session_manager.has_badge("color_master")
	)

	var has_perfect: bool = bool(
		session_manager.has_badge("perfect")
	)

	var color_badge_name: String = _badge_name("color_master")
	var perfect_badge_name: String = _badge_name("perfect")

	if not before_color and has_color_master:
		if not new_badges.has(color_badge_name):
			new_badges.append(color_badge_name)

	if not before_perfect and has_perfect:
		if not new_badges.has(perfect_badge_name):
			new_badges.append(perfect_badge_name)

	# SIGUIENTE NIVEL solo se habilita si se completó este nivel y el siguiente es jugable.
	# Se calcula después de register_attempt, que es lo que desbloquea el siguiente.
	var next_level: int = 0

	if not game_over and bool(session_result.get("completed", false)):
		var candidate: int = int(level_run.level) + 1

		if candidate <= GameConfig.total_levels() and session_manager.level_playable(candidate):
			next_level = candidate

	results_ui.show_results(
		level_run,
		game_over,
		new_badges,
		next_level
	)

func _write_answer_log(
	answer: String,
	correct: bool,
	response_time: float,
	row_number: int,
	affected_count: int
) -> void:

	var cfg: Dictionary = level_run.config

	var difficulty: Array = cfg.get(
		"zone_difficulty",
		[]
	) as Array

	var difficulty_name: String = ""

	if current_zone >= 0 and current_zone < difficulty.size():
		difficulty_name = str(difficulty[current_zone])

	var extras: Dictionary = {
		"event_type": "game_attempt",
		"idEjercicio": int(current_question.get("id", -1)),
		"nivel": int(level_run.level),
		"zona": current_zone + 1,
		"fila": row_number,
		"tipo": QuestionManager.kind_of(current_question),
		"dificultad": difficulty_name,
		"vidasRestantes": int(level_run.lives),
		"puntajeActual": int(level_run.score),
		"numeroIntento": int(level_run.attempt_number),
		"afectados": affected_count if correct else 0,
		"codigo": str(current_question.get("code", ""))
	}

	var player_email: String = str(
		session_manager.email()
	)

	var question_text: String = str(
		current_question.get("question", "")
	)

	var options_shown: Array = current_options.duplicate()

	var record: Dictionary = log_manager.answer_record(
		player_email,
		question_text,
		options_shown,
		answer,
		correct,
		response_time,
		extras
	)

	log_manager.append(record)
func _toggle_pause()->void:
	if paused:
		_resume_from_pause()
		return
	paused=true
	world_controller.set_player_movement(false)
	if combat_open:
		combat_ui.set_buttons_enabled(false)
	pause_ui.show_pause()

func _resume_from_pause()->void:
	paused=false
	pause_ui.hide_pause()
	if combat_open:
		combat_ui.set_buttons_enabled(not awaiting_continue)
	else:
		world_controller.set_player_movement(true)

func _abandon_to_menu()->void:
	pause_ui.hide_pause(); paused=false
	if level_run!=null:
		session_manager.register_attempt(level_run.session_result(true))
	_show_menu()

func _badge_name(badge_id: String) -> String:
	for badge in GameConfig.badges():
		if str(badge.get("id", "")) == badge_id:
			return str(badge.get("name", badge_id))
	return badge_id
