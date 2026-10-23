extends CanvasLayer

signal settings_changed(master: float, music: float, sfx: float, muted: bool)
signal display_settings_changed(mode: String, auto_resolution: bool, width: int, height: int, vsync_enabled: bool)
signal close_requested

const UIFactory = preload("res://scripts/ui/ui_factory.gd")

var root: Control

# Audio
var master_slider: HSlider
var music_slider: HSlider
var sfx_slider: HSlider
var master_value: Label
var music_value: Label
var sfx_value: Label
var mute_check: CheckButton
var _updating_audio: bool = false

# Pantalla
var mode_option: OptionButton
var auto_check: CheckButton
var resolution_option: OptionButton
var vsync_check: CheckButton
var display_hint: Label
var display_status: Label
var _resolution_values: Array[Vector2i] = []
var _updating_display: bool = false

func _ready() -> void:
	layer = 80
	_build()

func show_settings(audio_values: Dictionary, display_values: Dictionary, resolutions: Array) -> void:
	_updating_audio = true
	master_slider.value = float(audio_values.get("master", 0.85)) * 100.0
	music_slider.value = float(audio_values.get("music", 0.65)) * 100.0
	sfx_slider.value = float(audio_values.get("sfx", 0.85)) * 100.0
	mute_check.button_pressed = bool(audio_values.get("muted", false))
	_update_audio_labels()
	_updating_audio = false

	_updating_display = true
	_fill_resolutions(resolutions)
	_select_mode(str(display_values.get("mode", "borderless")))
	auto_check.button_pressed = bool(display_values.get("auto_resolution", true))
	vsync_check.button_pressed = bool(display_values.get("vsync", true))
	_select_resolution(Vector2i(
		int(display_values.get("width", 1280)),
		int(display_values.get("height", 720))
	))
	display_status.text = ""
	_update_display_controls()
	_updating_display = false

	root.visible = true

func hide_settings() -> void:
	root.visible = false

func _emit_audio_settings() -> void:
	_update_audio_labels()
	if _updating_audio:
		return
	settings_changed.emit(
		float(master_slider.value) / 100.0,
		float(music_slider.value) / 100.0,
		float(sfx_slider.value) / 100.0,
		mute_check.button_pressed
	)

func _update_audio_labels() -> void:
	master_value.text = "%d%%" % int(round(master_slider.value))
	music_value.text = "%d%%" % int(round(music_slider.value))
	sfx_value.text = "%d%%" % int(round(sfx_slider.value))
	mute_check.text = "SILENCIAR TODO" if not mute_check.button_pressed else "SONIDO SILENCIADO"

func _make_slider(card: Control, title_text: String, y: float) -> Array:
	var title := UIFactory.label(title_text, Rect2(35, y, 165, 28), 15, UIFactory.PALETTE.text)
	card.add_child(title)
	var slider := HSlider.new()
	slider.position = Vector2(190, y + 1)
	slider.size = Vector2(205, 28)
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	card.add_child(slider)
	var value_label := UIFactory.label("0%", Rect2(405, y, 60, 28), 14, UIFactory.PALETTE.cyan)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	card.add_child(value_label)
	return [slider, value_label]

func _fill_resolutions(values: Array) -> void:
	_resolution_values.clear()
	resolution_option.clear()
	for value in values:
		if typeof(value) == TYPE_VECTOR2I:
			var res: Vector2i = value
			_resolution_values.append(res)
			resolution_option.add_item("%d x %d" % [res.x, res.y])
	if _resolution_values.is_empty():
		_resolution_values.append(Vector2i(1280, 720))
		resolution_option.add_item("1280 x 720")

func _select_mode(mode: String) -> void:
	match mode:
		"fullscreen": mode_option.select(1)
		"borderless": mode_option.select(2)
		_: mode_option.select(0)

func _selected_mode() -> String:
	match mode_option.selected:
		1: return "fullscreen"
		2: return "borderless"
		_: return "windowed"

func _select_resolution(target: Vector2i) -> void:
	for i in range(_resolution_values.size()):
		if _resolution_values[i] == target:
			resolution_option.select(i)
			return
	resolution_option.select(0)

func _update_display_controls() -> void:
	var mode: String = _selected_mode()
	var is_windowed: bool = mode == "windowed"
	auto_check.disabled = not is_windowed
	resolution_option.disabled = not is_windowed or auto_check.button_pressed

	if mode == "fullscreen":
		display_hint.text = "Pantalla completa usa automáticamente la resolución del monitor."
	elif mode == "borderless":
		display_hint.text = "Sin bordes ocupa el monitor completo con su resolución nativa."
	elif auto_check.button_pressed:
		display_hint.text = "Ventana automática elige la resolución más grande que cabe cómodamente."
	else:
		display_hint.text = "Elige manualmente el tamaño de la ventana."

func _apply_display_settings() -> void:
	if _resolution_values.is_empty():
		return
	var index: int = clampi(resolution_option.selected, 0, _resolution_values.size() - 1)
	var selected_resolution: Vector2i = _resolution_values[index]
	display_settings_changed.emit(
		_selected_mode(),
		auto_check.button_pressed,
		selected_resolution.x,
		selected_resolution.y,
		vsync_check.button_pressed
	)
	display_status.text = "Configuración aplicada y guardada."

func _style_option(option: OptionButton) -> void:
	option.add_theme_font_size_override("font_size", 15)
	option.add_theme_color_override("font_color", UIFactory.PALETTE.text)
	option.add_theme_stylebox_override("normal", UIFactory.style_box(Color("14233c"), Color("345270"), 2, 8))
	option.add_theme_stylebox_override("hover", UIFactory.style_box(Color("1a2b47"), UIFactory.PALETTE.cyan, 2, 8))

func _build() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UIFactory.make_theme()
	root.visible = false
	add_child(root)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.02, 0.05, 0.96)
	root.add_child(dim)

	var stage := UIFactory.stage(root)
	var outer := UIFactory.panel(Rect2(95, 55, 1090, 610), Color("0b1427"), UIFactory.PALETTE.cyan)
	stage.add_child(outer)

	var title := UIFactory.title("OPCIONES", Rect2(60, 25, 970, 44), 28, UIFactory.PALETTE.cyan)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(title)
	var subtitle := UIFactory.label("Configura el audio y la pantalla de CSS Survivor.", Rect2(150, 68, 790, 28), 14, UIFactory.PALETTE.muted)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(subtitle)

	# --- AUDIO ---
	var audio_card := UIFactory.panel(Rect2(35, 115, 490, 390), Color("0d172b"), Color("294f70"))
	outer.add_child(audio_card)
	var audio_title := UIFactory.title("AUDIO", Rect2(35, 24, 420, 36), 20, UIFactory.PALETTE.cyan)
	audio_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	audio_card.add_child(audio_title)
	var row := _make_slider(audio_card, "GENERAL", 85)
	master_slider = row[0] as HSlider
	master_value = row[1] as Label
	row = _make_slider(audio_card, "MÚSICA", 145)
	music_slider = row[0] as HSlider
	music_value = row[1] as Label
	row = _make_slider(audio_card, "EFECTOS", 205)
	sfx_slider = row[0] as HSlider
	sfx_value = row[1] as Label
	mute_check = CheckButton.new()
	mute_check.position = Vector2(125, 285)
	mute_check.size = Vector2(250, 42)
	mute_check.add_theme_font_size_override("font_size", 15)
	audio_card.add_child(mute_check)

	# --- PANTALLA ---
	var display_card := UIFactory.panel(Rect2(565, 115, 490, 390), Color("0d172b"), Color("365a48"))
	outer.add_child(display_card)
	var display_title := UIFactory.title("PANTALLA", Rect2(35, 24, 420, 36), 20, UIFactory.PALETTE.green)
	display_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display_card.add_child(display_title)

	display_card.add_child(UIFactory.label("MODO", Rect2(40, 82, 150, 30), 15, UIFactory.PALETTE.text))
	mode_option = OptionButton.new()
	mode_option.position = Vector2(190, 78)
	mode_option.size = Vector2(250, 38)
	mode_option.add_item("Ventana")
	mode_option.add_item("Pantalla completa")
	mode_option.add_item("Pantalla completa sin bordes")
	_style_option(mode_option)
	display_card.add_child(mode_option)

	auto_check = CheckButton.new()
	auto_check.text = "RESOLUCIÓN AUTOMÁTICA"
	auto_check.position = Vector2(40, 135)
	auto_check.size = Vector2(400, 38)
	auto_check.add_theme_font_size_override("font_size", 15)
	display_card.add_child(auto_check)

	display_card.add_child(UIFactory.label("RESOLUCIÓN", Rect2(40, 190, 150, 30), 15, UIFactory.PALETTE.text))
	resolution_option = OptionButton.new()
	resolution_option.position = Vector2(190, 186)
	resolution_option.size = Vector2(250, 38)
	_style_option(resolution_option)
	display_card.add_child(resolution_option)

	vsync_check = CheckButton.new()
	vsync_check.text = "VSYNC"
	vsync_check.position = Vector2(40, 240)
	vsync_check.size = Vector2(180, 38)
	vsync_check.add_theme_font_size_override("font_size", 15)
	display_card.add_child(vsync_check)

	display_hint = UIFactory.label("", Rect2(40, 285, 400, 48), 12, UIFactory.PALETTE.muted)
	display_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display_card.add_child(display_hint)

	var apply := UIFactory.button("APLICAR PANTALLA", Rect2(135, 335, 220, 42), Color("275b47"))
	apply.pressed.connect(_apply_display_settings)
	display_card.add_child(apply)

	display_status = UIFactory.label("", Rect2(590, 515, 440, 26), 12, UIFactory.PALETTE.green)
	display_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(display_status)

	var back := UIFactory.button("VOLVER", Rect2(435, 535, 220, 48), Color("253959"))
	back.pressed.connect(func() -> void:
		hide_settings()
		close_requested.emit()
	)
	outer.add_child(back)

	master_slider.value_changed.connect(func(_value: float) -> void: _emit_audio_settings())
	music_slider.value_changed.connect(func(_value: float) -> void: _emit_audio_settings())
	sfx_slider.value_changed.connect(func(_value: float) -> void: _emit_audio_settings())
	mute_check.toggled.connect(func(_value: bool) -> void: _emit_audio_settings())
	mode_option.item_selected.connect(func(_index: int) -> void:
		if not _updating_display:
			display_status.text = ""
		_update_display_controls()
	)
	auto_check.toggled.connect(func(_value: bool) -> void:
		if not _updating_display:
			display_status.text = ""
		_update_display_controls()
	)
	resolution_option.item_selected.connect(func(_index: int) -> void:
		if not _updating_display:
			display_status.text = ""
	)
	vsync_check.toggled.connect(func(_value: bool) -> void:
		if not _updating_display:
			display_status.text = ""
	)
