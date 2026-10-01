extends Control

const EnemyView = preload("res://scripts/enemy_view.gd")
const BATTLE_BG: Texture2D = preload("res://assets/backgrounds/battle_web.png")
const HACKER: Texture2D = preload("res://assets/player/hacker.png")
const QUEUE_VIRUS: Texture2D = preload("res://assets/enemies/virus_4.png")

const LANE_X := [470.0, 640.0, 810.0]
const DEPTH_Y := [330.0, 245.0, 160.0]

var background: TextureRect
var enemy_layer: Control
var projectile_layer: Control
var hacker: TextureRect
var queue_icon: TextureRect
var queue_label: Label
var enemies: Dictionary = {}
var current_grid

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()

func _build() -> void:
	background = TextureRect.new()
	background.texture = BATTLE_BG
	background.position = Vector2(86, 92)
	background.size = Vector2(1108, 350)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.modulate = Color(0.82, 0.9, 1.0, 0.96)
	add_child(background)

	var shade := ColorRect.new()
	shade.position = Vector2(86, 92)
	shade.size = Vector2(1108, 350)
	shade.color = Color(0.02, 0.04, 0.09, 0.24)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	_add_depth_label("LEJOS", 116, 146, Color("36d98b"))
	_add_depth_label("MEDIO", 116, 231, Color("ffb238"))
	_add_depth_label("FRENTE", 116, 316, Color("ff5777"))

	enemy_layer = Control.new()
	enemy_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	enemy_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(enemy_layer)

	projectile_layer = Control.new()
	projectile_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	projectile_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(projectile_layer)

	hacker = TextureRect.new()
	hacker.texture = HACKER
	hacker.position = Vector2(596, 357)
	hacker.size = Vector2(88, 88)
	hacker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hacker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hacker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hacker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hacker)

	queue_icon = TextureRect.new()
	queue_icon.texture = QUEUE_VIRUS
	queue_icon.position = Vector2(1064, 122)
	queue_icon.size = Vector2(48, 48)
	queue_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	queue_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	queue_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(queue_icon)
	queue_label = Label.new()
	queue_label.position = Vector2(1010, 170)
	queue_label.size = Vector2(160, 44)
	queue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	queue_label.add_theme_font_size_override("font_size", 12)
	queue_label.add_theme_color_override("font_color", Color("d7e1f3"))
	queue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(queue_label)

func _add_depth_label(text_value: String, x: float, y: float, color: Color) -> void:
	var label := Label.new()
	label.text = text_value
	label.position = Vector2(x, y)
	label.size = Vector2(120, 30)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func show_grid(grid) -> void:
	current_grid = grid
	_sync_grid(true)
	mark_selection(grid.target_and_neighbors())

func _sync_grid(spawn_new: bool) -> void:
	if current_grid == null:
		return

	var visible_ids: Array[int] = []

	var visible_state: Array = current_grid.visible_state() as Array

	for item_data in visible_state:
		var item: Dictionary = item_data as Dictionary

		var depth: int = int(
			item.get("depth", 0)
		)

		var row: Dictionary = item.get(
			"row",
			{}
		) as Dictionary

		var row_enemies: Array = row.get(
			"enemies",
			[]
		) as Array

		for enemy_data in row_enemies:
			var data: Dictionary = enemy_data as Dictionary

			var alive: bool = bool(
				data.get("alive", false)
			)

			if not alive:
				continue

			var enemy_id: int = int(
				data.get("id", 0)
			)

			visible_ids.append(enemy_id)

			var view = null

			if enemies.has(enemy_id):
				var existing_view: Variant = enemies[enemy_id]

				if is_instance_valid(existing_view):
					view = existing_view

			if view == null:
				view = EnemyView.new()

				view.setup(
					data,
					depth
				)

				enemy_layer.add_child(view)

				enemies[enemy_id] = view

				if spawn_new:
					view.animate_spawn()

			view.set_depth(depth)

			var lane: int = int(
				data.get("lane", 0)
			)

			view.position = _enemy_position(
				lane,
				depth
			)

	var enemy_ids: Array = enemies.keys()

	for stored_id in enemy_ids:
		var enemy_id: int = int(stored_id)

		if not visible_ids.has(enemy_id):
			var old_view: Variant = enemies.get(
				enemy_id,
				null
			)

			if old_view != null and is_instance_valid(old_view):
				old_view.queue_free()

			enemies.erase(enemy_id)

	var queued: int = int(
		current_grid.queue_count()
	)

	queue_icon.visible = queued > 0
	queue_label.visible = queued > 0

	queue_label.text = "%d FILA(S) EN COLA" % queued
	
func mark_selection(selection: Dictionary) -> void:
	for view in enemies.values():
		if is_instance_valid(view):
			view.set_mark("none")
	var target: Dictionary = selection.get("target", {})
	var target_id := int(target.get("id", -1))
	if enemies.has(target_id):
		enemies[target_id].set_mark("target")
	for neighbor in selection.get("neighbors", []):
		var id := int(neighbor.get("id", -1))
		if enemies.has(id):
			enemies[id].set_mark("neighbor")

func animate_attack(selection: Dictionary, effects: Array) -> void:
	var target: Dictionary = selection.get("target", {})
	var target_id := int(target.get("id", -1))
	if target_id < 0 or not enemies.has(target_id):
		return
	var target_view = enemies[target_id]
	await _shoot_projectile(hacker.position + hacker.size * 0.5, target_view.position + target_view.size * 0.5)
	var affected_views: Array = []
	for data in selection.get("affected", []):
		var id := int(data.get("id", -1))
		if enemies.has(id) and is_instance_valid(enemies[id]):
			var view = enemies[id]
			view.apply_effects(effects)
			affected_views.append(view)
	# Tiempo visible para que el estudiante vea cómo la propiedad CSS altera al bug.
	await get_tree().create_timer(0.7).timeout
	for view in affected_views:
		view.animate_die()
	await get_tree().create_timer(0.3).timeout

func _shoot_projectile(from: Vector2, to: Vector2) -> void:
	var projectile := Panel.new()
	projectile.position = from - Vector2(7, 7)
	projectile.size = Vector2(14, 14)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("20c7f3")
	style.border_color = Color("e8f0ff")
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	projectile.add_theme_stylebox_override("panel", style)
	projectile_layer.add_child(projectile)
	var tween := create_tween()
	tween.tween_property(projectile, "position", to - Vector2(7, 7), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	projectile.queue_free()
	# Ramificaciones desde el objetivo a los vecinos.
	var branches: Array = []
	for view in enemies.values():
		if is_instance_valid(view) and view.mark_mode == "neighbor":
			branches.append(view)
	if not branches.is_empty():
		var branch_tween := create_tween().set_parallel(true)
		for view in branches:
			var spark := ColorRect.new()
			spark.color = Color("7be4ff")
			spark.position = to - Vector2(4, 4)
			spark.size = Vector2(8, 8)
			projectile_layer.add_child(spark)
			branch_tween.tween_property(spark, "position", view.position + view.size * 0.5 - Vector2(4, 4), 0.14)
			branch_tween.tween_callback(spark.queue_free).set_delay(0.15)
		await branch_tween.finished

func animate_advance(grid) -> void:
	current_grid = grid
	var desired: Dictionary = {}
	for item in grid.visible_state():
		var depth := int(item.get("depth", 0))
		var row: Dictionary = item.get("row", {})
		for data in row.get("enemies", []):
			if bool(data.get("alive", false)):
				desired[int(data.get("id", 0))] = {"pos": _enemy_position(int(data.get("lane", 0)), depth), "depth": depth, "data": data}
	var tween := create_tween().set_parallel(true)
	var moved := false
	for id in enemies.keys():
		if desired.has(int(id)) and is_instance_valid(enemies[id]):
			moved = true
			tween.tween_property(enemies[id], "position", desired[int(id)]["pos"], 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if moved:
		await tween.finished
	_sync_grid(true)
	mark_selection(grid.target_and_neighbors())

func _enemy_position(lane_index: int, depth_index: int) -> Vector2:
	var lane_position: int = clampi(
		lane_index,
		0,
		LANE_X.size() - 1
	)

	var depth_position: int = clampi(
		depth_index,
		0,
		DEPTH_Y.size() - 1
	)

	var x: float = float(
		LANE_X[lane_position]
	)

	var y: float = float(
		DEPTH_Y[depth_position]
	)

	return Vector2(
		x - 46.0,
		y - 46.0
	)
