extends Node2D

signal zone_cleared(zone_index: int)

const PlayerScript = preload("res://scripts/player.gd")
const BugScript = preload("res://scripts/bug.gd")
const WorldScript = preload("res://scripts/web_world.gd")

var world
var player
var game_camera: Camera2D
var bugs: Array = []
var bug_hp: int = 3

func setup(bug_hp_value: int) -> void:
	bug_hp = bug_hp_value
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

	var page_title := Label.new()
	page_title.name = "PageTitle"
	page_title.text = "MI SITIO WEB  •  PERFIL / DATOS / SEGURIDAD / SOPORTE"
	page_title.position = Vector2(690, 93)
	page_title.size = Vector2(850, 32)
	page_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_title.add_theme_font_size_override("font_size", 18)
	page_title.add_theme_color_override("font_color", Color("eaffff"))
	world.add_child(page_title)

	var sector_data = [
		["ZONA 1 • PERFIL", Vector2(305, 184)],
		["ZONA 2 • SEGURIDAD", Vector2(1615, 184)],
		["ZONA 3 • DATOS", Vector2(305, 864)],
		["ZONA 4 • SOPORTE", Vector2(1615, 864)]
	]
	for info in sector_data:
		var sector := Label.new()
		sector.text = info[0]
		sector.position = info[1]
		sector.size = Vector2(280, 30)
		sector.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sector.add_theme_font_size_override("font_size", 16)
		sector.add_theme_color_override("font_color", Color("ff5f82"))
		world.add_child(sector)

func start_level(level: int) -> void:
	world.set_level(level)
	_spawn_bugs()
	player.position = Vector2(1100, 700)
	player.can_move = true
	world.visible = true
	player.visible = true

func _spawn_bugs() -> void:
	for old in bugs:
		if is_instance_valid(old):
			old.queue_free()
	bugs.clear()
	var positions := [Vector2(500, 350), Vector2(1700, 350), Vector2(500, 1050), Vector2(1700, 1050)]
	for i in range(4):
		var bug = Node2D.new()
		bug.set_script(BugScript)
		bug.position = positions[i]
		bug.max_hp = bug_hp
		bug.hp = bug_hp
		world.add_child(bug)
		bug.setup(i, "ZONA %d" % (i + 1))
		bug.defeated.connect(_on_bug_defeated)
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

func cleared_zone_count() -> int:
	var count := 0
	for bug in bugs:
		if is_instance_valid(bug) and not bug.active:
			count += 1
	return count

func set_zone_progress(zone_index: int, progress: float) -> void:
	world.set_zone_progress(zone_index, progress)

func set_player_movement(enabled: bool) -> void:
	if player:
		player.can_move = enabled

func set_game_visible(visible_value: bool) -> void:
	if world:
		world.visible = visible_value
	if player:
		player.visible = visible_value

func _on_bug_defeated(zone_index: int) -> void:
	world.clear_zone(zone_index)
	zone_cleared.emit(zone_index)
