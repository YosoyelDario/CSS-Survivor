extends CanvasLayer

signal settings_changed(master: float, music: float, sfx: float, muted: bool)
signal close_requested

const UIFactory = preload("res://scripts/ui/ui_factory.gd")

var root: Control
var master_slider: HSlider
var music_slider: HSlider
var sfx_slider: HSlider
var master_value: Label
var music_value: Label
var sfx_value: Label
var mute_check: CheckButton
var _updating: bool = false

func _ready() -> void:
	layer = 80
	_build()

func show_settings(values: Dictionary) -> void:
	_updating = true
	master_slider.value = float(values.get("master", 0.85)) * 100.0
	music_slider.value = float(values.get("music", 0.65)) * 100.0
	sfx_slider.value = float(values.get("sfx", 0.85)) * 100.0
	mute_check.button_pressed = bool(values.get("muted", false))
	_update_labels()
	_updating = false
	root.visible = true

func hide_settings() -> void:
	root.visible = false

func _emit_settings() -> void:
	_update_labels()
	if _updating:
		return
	settings_changed.emit(
		float(master_slider.value) / 100.0,
		float(music_slider.value) / 100.0,
		float(sfx_slider.value) / 100.0,
		mute_check.button_pressed
	)

func _update_labels() -> void:
	master_value.text = "%d%%" % int(round(master_slider.value))
	music_value.text = "%d%%" % int(round(music_slider.value))
	sfx_value.text = "%d%%" % int(round(sfx_slider.value))
	mute_check.text = "SILENCIAR TODO" if not mute_check.button_pressed else "SONIDO SILENCIADO"

func _make_slider(card: Control, title_text: String, y: float) -> Array:
	var title := UIFactory.label(title_text, Rect2(55, y, 180, 28), 16, UIFactory.PALETTE.text)
	card.add_child(title)
	var slider := HSlider.new()
	slider.position = Vector2(230, y + 1)
	slider.size = Vector2(250, 28)
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	card.add_child(slider)
	var value_label := UIFactory.label("0%", Rect2(495, y, 70, 28), 15, UIFactory.PALETTE.cyan)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	card.add_child(value_label)
	return [slider, value_label]

func _build() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UIFactory.make_theme()
	root.visible = false
	add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.02, 0.05, 0.94)
	root.add_child(dim)
	var stage := UIFactory.stage(root)
	var card := UIFactory.panel(Rect2(325, 125, 630, 470), Color("0d172b"), UIFactory.PALETTE.cyan)
	stage.add_child(card)
	var title := UIFactory.title("AUDIO", Rect2(60, 35, 510, 46), 28, UIFactory.PALETTE.cyan)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title)
	var subtitle := UIFactory.label("Ajusta la música y los efectos del juego.", Rect2(80, 85, 470, 30), 15, UIFactory.PALETTE.muted)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(subtitle)
	var row := _make_slider(card, "VOLUMEN GENERAL", 145)
	master_slider = row[0] as HSlider
	master_value = row[1] as Label
	row = _make_slider(card, "MÚSICA", 205)
	music_slider = row[0] as HSlider
	music_value = row[1] as Label
	row = _make_slider(card, "EFECTOS", 265)
	sfx_slider = row[0] as HSlider
	sfx_value = row[1] as Label
	mute_check = CheckButton.new()
	mute_check.position = Vector2(190, 330)
	mute_check.size = Vector2(250, 42)
	mute_check.add_theme_font_size_override("font_size", 16)
	card.add_child(mute_check)
	var back := UIFactory.button("VOLVER", Rect2(205, 395, 220, 48), Color("253959"))
	back.pressed.connect(func() -> void:
		hide_settings()
		close_requested.emit()
	)
	card.add_child(back)
	master_slider.value_changed.connect(func(_value: float) -> void: _emit_settings())
	music_slider.value_changed.connect(func(_value: float) -> void: _emit_settings())
	sfx_slider.value_changed.connect(func(_value: float) -> void: _emit_settings())
	mute_check.toggled.connect(func(_value: bool) -> void: _emit_settings())
