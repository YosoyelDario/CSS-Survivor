extends Node

signal settings_changed(values: Dictionary)

const SETTINGS_PATH := "user://display_settings.json"
const MODES := ["windowed", "fullscreen", "borderless"]
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

# Primera ejecución: modo cómodo para jugar, usando la resolución nativa del monitor.
var window_mode: String = "borderless"
var auto_resolution: bool = true
var resolution: Vector2i = Vector2i(1280, 720)
var vsync_enabled: bool = true

func _ready() -> void:
	_load_settings()
	apply_settings()

func settings() -> Dictionary:
	return {
		"mode": window_mode,
		"auto_resolution": auto_resolution,
		"width": resolution.x,
		"height": resolution.y,
		"vsync": vsync_enabled
	}

func available_resolutions() -> Array:
	return RESOLUTIONS.duplicate()

func set_settings(mode: String, use_auto_resolution: bool, new_resolution: Vector2i, use_vsync: bool) -> void:
	window_mode = mode if MODES.has(mode) else "windowed"
	auto_resolution = use_auto_resolution
	resolution = _validated_resolution(new_resolution)
	vsync_enabled = use_vsync
	apply_settings()
	_save_settings()
	settings_changed.emit(settings())

func apply_settings() -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)

	match window_mode:
		"fullscreen":
			# Godot 4.2 ajusta el tamaño al monitor al entrar en fullscreen.
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"borderless":
			_apply_borderless_fullscreen()
		_:
			_apply_windowed()

func _apply_windowed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

	var target: Vector2i = _automatic_windowed_resolution() if auto_resolution else resolution
	DisplayServer.window_set_size(target)
	_center_window(target)

func _apply_borderless_fullscreen() -> void:
	# Borderless real: ventana sin bordes del tamaño exacto del monitor actual.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)

	var screen: int = DisplayServer.window_get_current_screen()
	var screen_pos: Vector2i = DisplayServer.screen_get_position(screen)
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen)
	if screen_size.x <= 0 or screen_size.y <= 0:
		screen_size = Vector2i(1920, 1080)
	DisplayServer.window_set_position(screen_pos)
	DisplayServer.window_set_size(screen_size)

func _automatic_windowed_resolution() -> Vector2i:
	var screen: int = DisplayServer.window_get_current_screen()
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	if usable.size.x <= 0 or usable.size.y <= 0:
		return Vector2i(1280, 720)

	# Dejamos margen para barra de tareas y bordes de la ventana.
	var max_width: int = int(float(usable.size.x) * 0.90)
	var max_height: int = int(float(usable.size.y) * 0.88)
	var best: Vector2i = RESOLUTIONS[0]
	for candidate_value in RESOLUTIONS:
		var candidate: Vector2i = candidate_value
		if candidate.x <= max_width and candidate.y <= max_height:
			best = candidate
	return best

func _center_window(size: Vector2i) -> void:
	var screen: int = DisplayServer.window_get_current_screen()
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	if usable.size.x <= 0 or usable.size.y <= 0:
		return
	var offset_x: int = maxi(0, int(float(usable.size.x - size.x) / 2.0))
	var offset_y: int = maxi(0, int(float(usable.size.y - size.y) / 2.0))
	var pos: Vector2i = usable.position + Vector2i(offset_x, offset_y)
	DisplayServer.window_set_position(pos)

func _validated_resolution(value: Vector2i) -> Vector2i:
	for candidate_value in RESOLUTIONS:
		var candidate: Vector2i = candidate_value
		if candidate == value:
			return value
	return Vector2i(1280, 720)

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed as Dictionary
	var saved_mode: String = str(data.get("mode", window_mode))
	window_mode = saved_mode if MODES.has(saved_mode) else window_mode
	auto_resolution = bool(data.get("auto_resolution", auto_resolution))
	var width: int = int(data.get("width", resolution.x))
	var height: int = int(data.get("height", resolution.y))
	resolution = _validated_resolution(Vector2i(width, height))
	vsync_enabled = bool(data.get("vsync", vsync_enabled))

func _save_settings() -> void:
	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo guardar la configuración de pantalla.")
		return
	file.store_string(JSON.stringify(settings(), "  "))
