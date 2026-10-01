extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const BugScript = preload("res://scripts/bug.gd")
const WorldScript = preload("res://scripts/web_world.gd")

var world
var player
var game_camera: Camera2D
var bugs: Array = []
var level_config: Dictionary = {}

func setup() -> void:
	_build_world()

func _build_world() -> void:
	world = Node2D.new()
	world.set_script(WorldScript)
	world.name = "WebWorld"
	add_child(world)

	player = CharacterBody2D.new()
	player.set_script(PlayerScript)
	player.name = "Player"
	player.position = Vector2(1100, 700)
	add_child(player)

	game_camera = Camera2D.new()
	game_camera.name = "GameCamera"
	game_camera.position_smoothing_enabled = true
	game_camera.position_smoothing_speed = 7.0
	game_camera.limit_left = 0
	game_camera.limit_top = 0
	game_camera.limit_right = 2200
	game_camera.limit_bottom = 1400
	player.add_child(game_camera)
	game_camera.make_current()

func start_level(level: int, cfg: Dictionary, rows_left_values: Array) -> void:
	level_config = cfg
	world.set_level(level)
	_spawn_bugs(rows_left_values)
	player.position = Vector2(1100, 700)
	player.can_move = true
	world.visible = true
	player.visible = true

func _spawn_bugs(rows_left_values: Array) -> void:
	for old in bugs:
		if is_instance_valid(old):
			old.queue_free()
	bugs.clear()
	var positions := [Vector2(500, 350), Vector2(1700, 350), Vector2(500, 1050), Vector2(1700, 1050)]
	var names: Array = level_config.get("zone_names", ["PERFIL", "SEGURIDAD", "DATOS", "SOPORTE"])
	var difficulty: Array = level_config.get("zone_difficulty", ["Fácil", "Fácil", "Media", "Difícil"])
	var rows: Array = level_config.get("zone_rows", [3, 4, 4, 4])
	for i in range(4):
		var bug = Node2D.new()
		bug.set_script(BugScript)
		bug.position = positions[i]
		world.add_child(bug)
		bug.setup(i, str(names[i]), str(difficulty[i]), int(rows[i]), int(rows_left_values[i]))
		bugs.append(bug)

func nearest_bug(max_distance: float):
	var best = null
	var best_dist := INF
	for bug in bugs:
		if is_instance_valid(bug) and bug.active:
			var distance: float = player.global_position.distance_to(bug.global_position)
			if distance < max_distance and distance < best_dist:
				best = bug
				best_dist = distance
	return best

func update_zone(zone_index: int, rows_left: int, progress: float) -> void:
	if zone_index >= 0 and zone_index < bugs.size() and is_instance_valid(bugs[zone_index]):
		bugs[zone_index].set_rows(rows_left)
	world.set_zone_progress(zone_index, progress)
	if rows_left <= 0:
		world.clear_zone(zone_index)

func cleared_zone_count() -> int:
	var count := 0
	for bug in bugs:
		if is_instance_valid(bug) and not bug.active:
			count += 1
	return count

func set_player_movement(enabled: bool) -> void:
	if player:
		player.can_move = enabled

func set_game_visible(visible_value: bool) -> void:
	if world:
		world.visible = visible_value
	if player:
		player.visible = visible_value
