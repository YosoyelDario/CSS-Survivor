extends Node

const InputConfig=preload("res://scripts/managers/input_config.gd")
const GameConfig=preload("res://scripts/managers/game_config.gd")
const SessionManager=preload("res://scripts/managers/session_manager.gd")
const LogManager=preload("res://scripts/managers/log_manager.gd")
const QuestionManager=preload("res://scripts/managers/question_manager.gd")
const FeedbackBuilder = preload("res://scripts/managers/feedback_builder.gd")
const LevelRun=preload("res://scripts/managers/level_run.gd")
const ZoneGrid=preload("res://scripts/managers/zone_grid.gd")
const WorldController=preload("res://scripts/world_controller.gd")
const AudioManager=preload("res://scripts/managers/audio_manager.gd")
const QuestionTimer=preload("res://scripts/managers/question_timer.gd")
const DataManager=preload("res://scripts/managers/data_manager.gd")
const OnlineManager=preload("res://scripts/managers/online_manager.gd")

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
const AudioSettingsUI=preload("res://scripts/ui/audio_settings_ui.gd")

const INTERACT_DISTANCE:=125.0

var session_manager
var log_manager
var question_manager
var audio_manager
var question_timer
var data_manager
var online_manager
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
var audio_settings_ui

var game_active:=false
var combat_open:=false
var paused:=false
var awaiting_continue:=false
var current_zone:int=-1
var current_question:Dictionary={}
var current_options:Array[String]=[]
var question_started_ms:int=0
var new_badges:Array=[]
var _last_timer_second:int=-1

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
	audio_manager=AudioManager.new()
	audio_manager.name="AudioManager"
	add_child(audio_manager)
	question_timer=QuestionTimer.new()
	question_timer.name="QuestionTimer"
	add_child(question_timer)
	question_timer.tick.connect(_on_question_timer_tick)
	question_timer.expired.connect(_on_question_timeout)
	data_manager=DataManager.new()
	online_manager=OnlineManager.new()
	online_manager.name="OnlineManager"
	add_child(online_manager)
	online_manager.global_ranking_received.connect(_on_global_ranking_received)
	online_manager.global_ranking_failed.connect(_on_global_ranking_failed)
	online_manager.upload_status.connect(_on_upload_status)

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
	menu_ui.audio_requested.connect(_show_audio_settings)
	menu_ui.change_user_requested.connect(_change_user)
	menu_ui.exit_requested.connect(func():get_tree().quit())
	levels_ui=LevelsUI.new(); add_child(levels_ui)
	levels_ui.play_level.connect(_start_level)
	levels_ui.back_requested.connect(_show_menu)
	achievements_ui=AchievementsUI.new(); add_child(achievements_ui); achievements_ui.back_requested.connect(_show_menu)
	ranking_ui=RankingUI.new(); add_child(ranking_ui); ranking_ui.back_requested.connect(_show_menu)
	ranking_ui.global_connect_requested.connect(_on_global_ranking_requested)
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
	pause_ui.audio_requested.connect(_show_audio_settings)
	# El pre/post test existente se conserva, pero queda inactivo porque pretest_active=false.
	evaluation_ui=EvaluationUI.new(); add_child(evaluation_ui); evaluation_ui.hide_evaluation()
	audio_settings_ui=AudioSettingsUI.new(); add_child(audio_settings_ui)
	audio_settings_ui.settings_changed.connect(_on_audio_settings_changed)

func _show_login()->void:
	_hide_non_login()
	audio_manager.play_menu_music()
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
	question_timer.stop()
	audio_manager.set_urgent(false)
	audio_manager.play_menu_music()
	game_active=false
	combat_open=false
	paused=false
	awaiting_continue=false
	world_controller.set_player_movement(false)
	world_controller.set_game_visible(false)
	hud_ui.set_hud_visible(false)
	combat_ui.hide_combat()
	results_ui.hide_results()
	levels_ui.hide_levels(); achievements_ui.hide_achievements(); ranking_ui.hide_ranking(); howto_ui.hide_howto(); pause_ui.hide_pause(); login_ui.hide_login(); audio_settings_ui.hide_settings()
	menu_ui.show_menu(session_manager.alias(),session_manager.total_points(),session_manager.badge_count(),session_manager.completed_levels(),GameConfig.total_levels(),session_manager.level_completed(1))

func _hide_menu_pages()->void:
	menu_ui.hide_menu(); levels_ui.hide_levels(); achievements_ui.hide_achievements(); ranking_ui.hide_ranking(); howto_ui.hide_howto(); results_ui.hide_results(); login_ui.hide_login()

func _hide_non_login()->void:
	question_timer.stop()
	audio_manager.set_urgent(false)
	game_active=false; combat_open=false; paused=false
	world_controller.set_player_movement(false); world_controller.set_game_visible(false)
	hud_ui.set_hud_visible(false); combat_ui.hide_combat(); results_ui.hide_results(); menu_ui.hide_menu(); levels_ui.hide_levels(); achievements_ui.hide_achievements(); ranking_ui.hide_ranking(); howto_ui.hide_howto(); pause_ui.hide_pause(); audio_settings_ui.hide_settings()

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
	question_timer.stop()
	audio_manager.set_urgent(false)
	audio_manager.play_game_music()
	new_badges.clear()
	var cfg:=GameConfig.level(level)
	level_run=LevelRun.new()
	level_run.setup(level,cfg,question_manager,session_manager)
	data_manager.begin_attempt(session_manager,level_run)
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
	combat_ui.configure_level(cfg)
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
	combat_ui.prepare_row(current_question)
	combat_ui.mark_selection(zone_grids[current_zone].target_and_neighbors())
	var question_time:float=float(level_run.config.get("question_time_seconds",40.0))
	var urgent_time:float=float(level_run.config.get("urgent_time_seconds",10.0))
	_last_timer_second=-1
	question_timer.start(question_time,urgent_time)

func _on_answer_selected(answer: String) -> void:
	_resolve_answer(answer,false)

func _resolve_answer(answer:String,timed_out:bool=false)->void:
	if not combat_open or paused or current_question.is_empty() or awaiting_continue:
		return

	combat_ui.set_buttons_enabled(false)
	var response_time:float=question_timer.elapsed_seconds()
	question_timer.stop()
	audio_manager.set_urgent(false)

	var correct:bool=(not timed_out) and answer==str(current_question.get("answer",""))
	var grid=zone_grids[current_zone]
	var selection:Dictionary=grid.target_and_neighbors()
	var affected:Array=selection.get("affected",[]) as Array
	var affected_count:int=affected.size() if correct else 0
	var row_number:int=int(level_run.rows_cleared(current_zone))+1
	var logged_answer:String="SIN RESPUESTA" if timed_out else answer

	var result:Dictionary=level_run.answer(
		current_zone,
		current_question,
		logged_answer,
		affected_count,
		response_time,
		current_options
	)

	# Añade metadatos analíticos al historial sin cambiar la resolución de la pregunta.
	if not level_run.history.is_empty():
		var history_index:int=level_run.history.size()-1
		var history_entry:Dictionary=level_run.history[history_index] as Dictionary
		history_entry["timed_out"]=timed_out
		history_entry["answered_at"]=Time.get_datetime_string_from_system()
		history_entry["time_limit"]=float(level_run.config.get("question_time_seconds",0.0))
		history_entry["row"]=row_number
		history_entry["lives_remaining"]=int(level_run.lives)
		history_entry["score_after"]=int(level_run.score)
		level_run.history[history_index]=history_entry

	_write_answer_log(
		logged_answer,
		correct,
		response_time,
		row_number,
		affected_count,
		timed_out
	)

	var awarded_badges:Array=session_manager.evaluate_badges_answer(level_run,correct)
	for badge_id in awarded_badges:
		var badge_name:String=_badge_name(str(badge_id))
		if not new_badges.has(badge_name):
			new_badges.append(badge_name)

	_update_hud()

	if correct:
		var base_points:int=int(result.get("base_points",0))
		var bonus_points:int=int(result.get("bonus",0))
		var gained:int=base_points+bonus_points
		var summary_text:String="CORRECTO   +%d PTS"%gained
		var streak_now:int=int(result.get("streak",0))
		if streak_now>=3:
			summary_text+="   RACHA x%d"%streak_now
		var life_gained:bool=bool(result.get("life_gained",false))
		if life_gained:
			summary_text+="   +1 VIDA"

		combat_ui.show_feedback(
			true,
			summary_text,
			str(current_question.get("explanation","")),
			answer
		)

		if life_gained:
			combat_ui.update_header(
				level_run.lives,
				int(level_run.config.get("lives",5)),
				level_run.score,
				row_number,
				int(level_run.rows_total(current_zone)),
				float(level_run.zone_repair_percent(current_zone))
			)

		audio_manager.play_sfx("shoot")
		var effects:Array=current_question.get("effects",[]) as Array
		await combat_ui.animate_attack(selection,effects,current_question)
		audio_manager.play_sfx("correct")

		grid.resolve_success()
		if grid.front_cleared():
			grid.advance_rows()

		var rows_left:int=int(level_run.rows_left(current_zone))
		var repair_percent:float=float(level_run.zone_repair_percent(current_zone))
		world_controller.update_zone(current_zone,rows_left,repair_percent)

		var next_row_number:int=int(level_run.rows_cleared(current_zone))+1
		var total_rows:int=int(level_run.rows_total(current_zone))
		var max_lives:int=int(level_run.config.get("lives",5))
		combat_ui.update_header(level_run.lives,max_lives,level_run.score,next_row_number,total_rows,repair_percent)

		if level_run.zone_clean(current_zone):
			await get_tree().create_timer(0.35).timeout
			await _return_to_map_or_finish()
		else:
			await combat_ui.animate_advance(grid)
			_prepare_question()
	else:
		awaiting_continue=true
		var detail_text:String
		if timed_out:
			detail_text="Se acabó el tiempo. "+str(current_question.get("hint","Revisa la propiedad solicitada antes de continuar."))
		else:
			detail_text=FeedbackBuilder.error_detail(current_question,answer)

		var error_summary:String="TIEMPO AGOTADO   -1 VIDA" if timed_out else "INCORRECTO   -1 VIDA"
		if level_run.lives<=0:
			error_summary="TIEMPO AGOTADO   SIN VIDAS" if timed_out else "INCORRECTO   SIN VIDAS"

		combat_ui.show_feedback(false,error_summary,detail_text,"" if timed_out else answer)
		if timed_out:
			audio_manager.play_sfx("timeout")
		audio_manager.play_sfx("hit")
		await combat_ui.animate_player_damage()

		var max_lives:int=int(level_run.config.get("lives",5))
		var total_rows:int=int(level_run.rows_total(current_zone))
		var repair_percent:float=float(level_run.zone_repair_percent(current_zone))
		combat_ui.update_header(level_run.lives,max_lives,level_run.score,row_number,total_rows,repair_percent)

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
	question_timer.stop()
	audio_manager.set_urgent(false)
	await combat_ui.animate_close()
	combat_open=false
	if level_run.all_zones_clean():
		_end_attempt(false)
	else:
		world_controller.set_player_movement(true)
		_update_hud()

func _end_attempt(game_over: bool) -> void:
	question_timer.stop()
	audio_manager.set_urgent(false)
	if combat_open:
		combat_ui.hide_combat()

	combat_open = false
	game_active = false

	world_controller.set_player_movement(false)
	hud_ui.set_hud_visible(false)

	if not game_over:
		level_run.finalize_level()

	# Las insignias de nivel (completar, impecable, tres niveles) las otorga register_attempt según
	# game_config.json; aquí solo se comparan las que tenía antes con las que tiene ahora.
	var badges_before: Array = session_manager.badge_ids()

	var session_result: Dictionary = level_run.session_result(false)

	session_manager.register_attempt(session_result)

	for badge_id in session_manager.badge_ids():
		if not badges_before.has(badge_id):
			var earned_name: String = _badge_name(str(badge_id))

			if not new_badges.has(earned_name):
				new_badges.append(earned_name)

	# El envío online ocurre una sola vez al cerrar el intento. Primero se guarda en una
	# cola local; si no hay Internet, queda pendiente sin bloquear el juego.
	var result_name:String="game_over" if game_over else "completado"
	var online_payload:Dictionary=data_manager.build_attempt_payload(level_run,session_manager,result_name)
	online_manager.submit_attempt(online_payload)

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
	affected_count: int,
	timed_out: bool = false
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
		"rachaActual": int(level_run.streak),
		"vidaRecuperada": bool(level_run.history.back().get("life_gained", false)) if not level_run.history.is_empty() else false,
		"numeroIntento": int(level_run.attempt_number),
		"afectados": affected_count if correct else 0,
		"codigo": str(current_question.get("code", "")),
		"tiempoAgotado": timed_out,
		"idIntento": data_manager.current_attempt_id(),
		"alias": session_manager.alias(),
		"respuestaCorrecta": str(current_question.get("answer", "")),
		"propiedadCSS": str(current_question.get("main_property", "")),
		"tiempoMaximoSeg": float(level_run.config.get("question_time_seconds", 0.0))
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
		question_timer.set_paused(true)
		audio_manager.set_urgent(false)
	pause_ui.show_pause()

func _resume_from_pause()->void:
	paused=false
	pause_ui.hide_pause()
	if combat_open:
		combat_ui.set_buttons_enabled(not awaiting_continue)
		question_timer.set_paused(false)
	else:
		world_controller.set_player_movement(true)

func _abandon_to_menu()->void:
	question_timer.stop()
	audio_manager.set_urgent(false)
	pause_ui.hide_pause(); paused=false
	if level_run!=null:
		var abandoned_result:Dictionary=level_run.session_result(true)
		session_manager.register_attempt(abandoned_result)
		var online_payload:Dictionary=data_manager.build_attempt_payload(level_run,session_manager,"abandonado")
		online_manager.submit_attempt(online_payload)
	_show_menu()

func _on_question_timer_tick(remaining:float,total:float,urgent:bool)->void:
	if not combat_open:
		return
	combat_ui.update_timer(remaining,total,urgent)
	audio_manager.set_urgent(urgent)
	var seconds_left:int=ceili(remaining)
	if urgent and seconds_left>0 and seconds_left<=5 and seconds_left!=_last_timer_second:
		audio_manager.play_sfx("tick")
	_last_timer_second=seconds_left

func _on_question_timeout()->void:
	if not combat_open or paused or awaiting_continue or current_question.is_empty():
		return
	_resolve_answer("SIN RESPUESTA",true)

func _on_global_ranking_requested()->void:
	ranking_ui.show_global_loading()
	var ranking_snapshot: Dictionary = data_manager.build_ranking_sync_payload(session_manager)
	online_manager.request_global_ranking(ranking_snapshot)

func _on_global_ranking_received(rows:Array)->void:
	ranking_ui.show_global_ranking(rows)

func _on_global_ranking_failed(message:String)->void:
	ranking_ui.show_global_error(message)

func _on_upload_status(message:String,success:bool)->void:
	print("[SYNC] ", "OK: " if success else "ERROR: ", message)
	if not success:
		push_warning("[SYNC] " + message)

func _show_audio_settings()->void:
	audio_settings_ui.show_settings(audio_manager.settings())

func _on_audio_settings_changed(master:float,music:float,sfx:float,muted:bool)->void:
	audio_manager.set_settings(master,music,sfx,muted)

func _badge_name(badge_id: String) -> String:
	for badge in GameConfig.badges():
		if str(badge.get("id", "")) == badge_id:
			return str(badge.get("name", badge_id))
	return badge_id
