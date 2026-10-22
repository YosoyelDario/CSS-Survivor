extends Control

const EnemyView = preload("res://scripts/enemy_view.gd")
const FlexLayout = preload("res://scripts/managers/flex_layout.gd")
const UIFactory = preload("res://scripts/ui/ui_factory.gd")
const BATTLE_BG: Texture2D = preload("res://assets/backgrounds/battle_web.png")
const HACKER: Texture2D = preload("res://assets/player/hacker.png")
const QUEUE_VIRUS: Texture2D = preload("res://assets/enemies/virus_4.png")

const LANE_X := [470.0, 640.0, 810.0]
const DEPTH_Y := [330.0, 245.0, 160.0]

var background: TextureRect
var enemy_layer: Control
var projectile_layer: Control
var hacker: TextureRect
var damage_flash: ColorRect
var queue_icon: TextureRect
var queue_label: Label
var enemies: Dictionary = {}
var current_grid

# Configuración del nivel en curso (game_config.json).
#   layout_mode "lanes": filas fijas en tres carriles (Niveles 1 y 2).
#   layout_mode "flex" : cada fila es un contenedor flex que el jugador reorganiza (Nivel 3).
var row_layout: String = "lanes"
var attack_mode: String = "adjacent"
var base_style: Dictionary = {}
# Propiedades flex vigentes de la fila del frente (solo row_layout "flex").
var row_props: Dictionary = FlexLayout.default_props()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()

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

	damage_flash = ColorRect.new()
	damage_flash.position = Vector2(86, 92)
	damage_flash.size = Vector2(1108, 350)
	damage_flash.color = Color(1.0, 0.05, 0.08, 0.0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_flash)

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

func configure_level(cfg: Dictionary) -> void:
	row_layout = str(cfg.get("layout_mode", "lanes"))
	attack_mode = str(cfg.get("attack_mode", "adjacent"))
	base_style = (cfg.get("enemy_style", {}) as Dictionary).duplicate()

func _clear_views() -> void:
	for view in enemies.values():
		if is_instance_valid(view):
			view.queue_free()
	enemies.clear()

func show_grid(grid) -> void:
	# Cada zona tiene sus propios ids de enemigo; al cambiar de zona (o de intento) se descartan
	# las vistas anteriores para no reutilizar enemigos ya destruidos.
	if grid != current_grid:
		_clear_views()
		row_props = FlexLayout.default_props()
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

				if not base_style.is_empty():
					view.set_base_style(base_style)

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

# ----------------------------------------------------------------------------------------------
# Estado de la fila del frente y ataque
# ----------------------------------------------------------------------------------------------

# Vistas vivas de la fila del frente, ordenadas por carril.
func _front_row_views() -> Array:
	var views: Array = []
	for view in enemies.values():
		if is_instance_valid(view) and int(view.depth) == 0:
			views.append(view)
	views.sort_custom(func(a, b) -> bool: return int(a.lane) < int(b.lane))
	return views

func _views_from(affected: Array) -> Array:
	var views: Array = []
	for data in affected:
		var id := int((data as Dictionary).get("id", -1))
		if enemies.has(id) and is_instance_valid(enemies[id]):
			views.append(enemies[id])
	views.sort_custom(func(a, b) -> bool: return int(a.lane) < int(b.lane))
	return views

# Efectos de un enemigo concreto: si el ejercicio define efectos por carril (por ejemplo, "una
# propiedad por enemigo") se usan esos; si no, todos reciben los efectos comunes.
func _lane_effects(common: Array, per_lane: Array, lane_index: int) -> Array:
	if lane_index >= 0 and lane_index < per_lane.size():
		return per_lane[lane_index] as Array
	return common

func _set_back_rows_alpha(alpha: float) -> void:
	for view in enemies.values():
		if is_instance_valid(view) and int(view.depth) > 0:
			view.modulate.a = alpha

# Deja la fila del frente tal como la ve el jugador antes de responder: sin efectos, o con el
# "bug" del ejercicio (bug_effects / lane_bug_effects) si el enunciado parte de un estado roto.
func prepare_row(question: Dictionary) -> void:
	var bug_effects: Array = question.get("bug_effects", []) as Array
	var lane_bug: Array = question.get("lane_bug_effects", []) as Array
	row_props = FlexLayout.apply_effects(FlexLayout.default_props(), bug_effects)
	var views: Array = _front_row_views()
	for view in views:
		view.reset_style()
		view.apply_effects(_lane_effects(bug_effects, lane_bug, int(view.lane)))
	_place_front_row(views, false)

func _margin_of(effects: Array) -> float:
	var amount := 0.0
	for effect in effects:
		if str((effect as Dictionary).get("property", "")) == "margin":
			amount = maxf(amount, str(effect.get("value", "0")).trim_suffix("px").to_float())
	return amount

# Coloca la fila del frente. En "flex" usa el layout vigente; en "lanes" respeta los carriles y,
# si hay margin, separa a los vecinos. Devuelve el Tween si animate=true (o null).
func _place_front_row(views: Array, animate: bool, spread: float = 0.0) -> Tween:
	var targets: Array = []
	if row_layout == "flex":
		var layout: Array = FlexLayout.positions(row_props, views.size(), float(DEPTH_Y[0]))
		for i in range(views.size()):
			var item: Dictionary = layout[i] as Dictionary
			targets.append({"pos": (item["center"] as Vector2) - Vector2(46.0, 46.0), "scale": float(item["scale"])})
	else:
		for view in views:
			var position_value: Vector2 = _enemy_position(int(view.lane), 0)
			position_value.x += float(int(view.lane) - 1) * spread
			targets.append({"pos": position_value, "scale": 1.0})
	var compact: bool = row_layout == "flex" and (str(row_props.get("direction", "row")) == "column" or str(row_props.get("align_content", "normal")) != "normal")
	_set_back_rows_alpha(0.25 if compact else 1.0)
	var tween: Tween = null
	if animate:
		tween = create_tween().set_parallel(true)
	for i in range(views.size()):
		var view = views[i]
		var target_scale := Vector2.ONE * float(targets[i]["scale"])
		if animate:
			tween.tween_property(view, "position", targets[i]["pos"], 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(view, "scale", target_scale, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		else:
			view.position = targets[i]["pos"]
			view.scale = target_scale
	return tween

func animate_player_damage() -> void:
	if hacker == null:
		return
	var origin: Vector2 = hacker.position
	hacker.pivot_offset = hacker.size * 0.5
	hacker.modulate = Color(1.0, 0.28, 0.28, 0.72)
	var flash := create_tween()
	flash.tween_property(damage_flash, "color:a", 0.26, 0.07)
	flash.tween_property(damage_flash, "color:a", 0.0, 0.30)
	var shake := create_tween()
	shake.tween_property(hacker, "position:x", origin.x - 14.0, 0.055)
	shake.tween_property(hacker, "position:x", origin.x + 13.0, 0.055)
	shake.tween_property(hacker, "position:x", origin.x - 10.0, 0.055)
	shake.tween_property(hacker, "position:x", origin.x + 8.0, 0.055)
	shake.tween_property(hacker, "position:x", origin.x, 0.08)
	shake.tween_property(hacker, "modulate", Color.WHITE, 0.18)
	await shake.finished
	hacker.position = origin
	hacker.modulate = Color.WHITE

func animate_attack(selection: Dictionary, effects: Array, question: Dictionary = {}) -> void:
	var views: Array = _views_from(selection.get("affected", []) as Array)
	if views.is_empty():
		return
	var per_lane: Array = question.get("lane_effects", []) as Array
	if str(selection.get("mode", attack_mode)) == "volley":
		await _attack_volley(views, effects, per_lane)
	else:
		await _attack_adjacent(selection, views, effects, per_lane)
	# Tiempo visible para que el estudiante vea cómo la propiedad CSS altera al bug.
	await get_tree().create_timer(0.7).timeout
	for view in views:
		if is_instance_valid(view):
			view.animate_die()
	await get_tree().create_timer(0.3).timeout

# Niveles 1 y 2: el proyectil impacta al objetivo central y se divide hacia sus vecinos.
func _attack_adjacent(selection: Dictionary, views: Array, effects: Array, per_lane: Array) -> void:
	var target: Dictionary = selection.get("target", {})
	var target_id := int(target.get("id", -1))
	if target_id < 0 or not enemies.has(target_id):
		return
	var target_view = enemies[target_id]
	await _shoot_projectile(hacker.position + hacker.size * 0.5, target_view.position + target_view.size * 0.5)
	for view in views:
		view.apply_effects(_lane_effects(effects, per_lane, int(view.lane)), true)
	var spread := _margin_of(effects)
	if spread > 0.0:
		_place_front_row(views, true, spread)

# Nivel 3: primero el grupo se reorganiza según las propiedades de layout (el punto de impacto se
# desplaza con él) y luego sale un disparo dirigido hacia cada enemigo.
func _attack_volley(views: Array, effects: Array, per_lane: Array) -> void:
	row_props = FlexLayout.apply_effects(row_props, effects)
	if FlexLayout.has_layout_effect(effects):
		var layout_tween: Tween = _place_front_row(views, true)
		if layout_tween != null:
			await layout_tween.finished
	var origin: Vector2 = hacker.position + hacker.size * 0.5
	var tween := create_tween().set_parallel(true)
	for i in range(views.size()):
		var view = views[i]
		var delay: float = float(i) * 0.12
		var projectile := _make_projectile(origin)
		var destination: Vector2 = view.position + view.size * 0.5 - Vector2(7, 7)
		tween.tween_property(projectile, "position", destination, 0.22).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		var lane_fx: Array = _lane_effects(effects, per_lane, int(view.lane))
		tween.tween_callback(func() -> void:
			projectile.queue_free()
			if is_instance_valid(view):
				view.apply_effects(lane_fx, true)
		).set_delay(delay + 0.22)
	await tween.finished

func _make_projectile(from: Vector2) -> Panel:
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
	return projectile

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
	row_props = FlexLayout.default_props()
	_set_back_rows_alpha(1.0)
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
	var depth_position: int = clampi(depth_index, 0, DEPTH_Y.size() - 1)

	if row_layout == "flex":
		# En el Nivel 3 cada fila parte con el estado por defecto de CSS (fila, flex-start, gap 0).
		var layout: Array = FlexLayout.positions(FlexLayout.default_props(), 3, float(DEPTH_Y[depth_position]))
		var item: Dictionary = layout[clampi(lane_index, 0, layout.size() - 1)] as Dictionary
		return (item["center"] as Vector2) - Vector2(46.0, 46.0)

	var lane_position: int = clampi(lane_index, 0, LANE_X.size() - 1)
	var x: float = float(LANE_X[lane_position])
	var y: float = float(DEPTH_Y[depth_position])
	return Vector2(x - 46.0, y - 46.0)
