extends Node2D

<<<<<<< Updated upstream
const PLAYER_TEXTURE: Texture2D = preload("res://assets/player/hacker.png")
const BATTLE_WEB_TEXTURE: Texture2D = preload("res://assets/backgrounds/battle_web.png")
const BUG_TEXTURES: Array[Texture2D] = [
	preload("res://assets/enemies/virus_1.png"),
	preload("res://assets/enemies/virus_2.png"),
	preload("res://assets/enemies/virus_3.png"),
	preload("res://assets/enemies/virus_4.png")
]
=======
const EnemyView = preload("res://scripts/enemy_view.gd")
const UIFactory = preload("res://scripts/ui/ui_factory.gd")
const BATTLE_BG: Texture2D = preload("res://assets/backgrounds/battle_web.png")
const HACKER: Texture2D = preload("res://assets/player/hacker.png")
const QUEUE_VIRUS: Texture2D = preload("res://assets/enemies/virus_4.png")
>>>>>>> Stashed changes

var level: int = 1
var target_hp: int = 3
var target_max_hp: int = 3
var target_alive: bool = true
var target_variant: int = 0
var hit_flash: float = 0.0
var miss_flash: float = 0.0

func set_battle_state(level_value: int, hp_value: int, max_hp_value: int, alive_value: bool = true, variant_value: int = 0) -> void:
	level = level_value
	target_hp = hp_value
	target_max_hp = max_hp_value
	target_alive = alive_value
	target_variant = clampi(variant_value, 0, BUG_TEXTURES.size() - 1)
	queue_redraw()

func target_screen_position() -> Vector2:
	return Vector2(640, 320)

<<<<<<< Updated upstream
func player_screen_position() -> Vector2:
	return Vector2(640, 414)

func flash_hit(success: bool) -> void:
	if success:
		hit_flash = 1.0
	else:
		miss_flash = 1.0
	queue_redraw()
=======
func _build() -> void:
	# UIFactory.texture_rect asigna expand_mode ANTES de la textura: así el tamaño pedido se respeta
	# (antes el fondo, el hacker y el ícono de cola salían con el tamaño de su PNG).
	background = UIFactory.texture_rect(BATTLE_BG, Rect2(86, 92, 1108, 350), TextureRect.STRETCH_SCALE)
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

	hacker = UIFactory.texture_rect(HACKER, Rect2(596, 357, 88, 88))
	add_child(hacker)

	queue_icon = UIFactory.texture_rect(QUEUE_VIRUS, Rect2(1064, 122, 48, 48))
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
>>>>>>> Stashed changes
	var tween := create_tween()
	if success:
		tween.tween_method(_set_hit_flash, 1.0, 0.0, 0.28)
	else:
		tween.tween_method(_set_miss_flash, 1.0, 0.0, 0.28)
	await tween.finished

func _set_hit_flash(value: float) -> void:
	hit_flash = value
	queue_redraw()

func _set_miss_flash(value: float) -> void:
	miss_flash = value
	queue_redraw()

func _draw_bug_sprite(pos: Vector2, texture: Texture2D, size: float = 60.0, alpha: float = 1.0) -> void:
	if texture == null:
		return
	var half := size / 2.0
	draw_texture_rect(texture, Rect2(pos - Vector2(half, half), Vector2(size, size)), false, Color(1, 1, 1, alpha))

func _draw() -> void:
	# Fondo general de batalla.
	draw_rect(Rect2(0, 0, 1280, 720), Color("07101d"), true)

	# Sitio web de batalla cargado desde PNG externo.
	var browser := Rect2(82, 92, 1116, 350)
	if BATTLE_WEB_TEXTURE:
		draw_texture_rect(BATTLE_WEB_TEXTURE, browser, false)
	else:
		draw_rect(browser, Color("edf6fb"), true)
	draw_rect(browser, Color("22c7f2"), false, 3)

	# Enemigos de fondo: sprites externos.
	for x in [470.0, 640.0, 810.0]:
		_draw_bug_sprite(Vector2(x, 225), BUG_TEXTURES[1], 54, 0.92)
		_draw_bug_sprite(Vector2(x, 275), BUG_TEXTURES[2], 60, 0.92)
		if x != 640.0:
			_draw_bug_sprite(Vector2(x, 330), BUG_TEXTURES[0], 66, 0.70)

	# BUG objetivo de esta zona.
	if target_alive:
		var target_texture: Texture2D = BUG_TEXTURES[target_variant]
		var size := 88.0 + hit_flash * 10.0
		var modulate_color := Color.WHITE.lerp(Color("8ff8ff"), hit_flash * 0.65)
		var half := size / 2.0
		draw_texture_rect(target_texture, Rect2(Vector2(640, 320) - Vector2(half, half), Vector2(size, size)), false, modulate_color)
		draw_arc(Vector2(640, 320), 48 + hit_flash * 8, 0, TAU, 40, Color(0.2, 0.85, 1.0, 0.7), 3)

	# HP del enemigo seleccionado.
	draw_rect(Rect2(590, 365, 100, 9), Color("2b1b2e"), true)
	var ratio := 0.0
	if target_max_hp > 0:
		ratio = float(target_hp) / float(target_max_hp)
	draw_rect(Rect2(590, 365, 100 * ratio, 9), Color("ffd447"), true)

	# Jugador: mismo PNG que se usa en el mapa.
	if PLAYER_TEXTURE:
		draw_texture_rect(PLAYER_TEXTURE, Rect2(592, 366, 96, 96), false)

	if miss_flash > 0.0:
		draw_rect(browser, Color(1.0, 0.08, 0.20, 0.18 * miss_flash), true)
