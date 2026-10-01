extends CanvasLayer

signal login_requested(email: String)
signal create_requested(email: String, alias_value: String, consent: bool)

const UIFactory = preload("res://scripts/ui/ui_factory.gd")
const GameConfig = preload("res://scripts/managers/game_config.gd")

var root: Control
var email_input: LineEdit
var alias_input: LineEdit
var consent_check: CheckBox
var consent_box: Panel
var message_label: Label
var create_button: Button

func _ready() -> void:
	layer = 40
	_build()

func show_login() -> void:
	root.visible = true
	message_label.text = ""
	consent_box.visible = false
	email_input.grab_focus()

func hide_login() -> void:
	root.visible = false

func show_new_profile() -> void:
	consent_box.visible = true
	alias_input.grab_focus()

func set_message(text_value: String) -> void:
	message_label.text = text_value

func _build() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UIFactory.make_theme()
	add_child(root)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = UIFactory.PALETTE.bg
	root.add_child(bg)
	var card := UIFactory.panel(Rect2(340, 80, 600, 560), Color("0d172b"), UIFactory.PALETTE.cyan)
	root.add_child(card)
	var logo := UIFactory.title("CSS\nSURVIVOR", Rect2(60, 35, 480, 110), 36, UIFactory.PALETTE.text)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(logo)
	var subtitle := UIFactory.label("PRUEBA PILOTO • IDENTIFICACIÓN DEL JUGADOR", Rect2(60, 148, 480, 28), 14, UIFactory.PALETTE.orange)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(subtitle)
	card.add_child(UIFactory.label("Correo", Rect2(70, 205, 460, 24), 15, UIFactory.PALETTE.muted))
	email_input = LineEdit.new()
	email_input.position = Vector2(70, 232)
	email_input.size = Vector2(460, 44)
	email_input.placeholder_text = "nombre@correo.cl"
	card.add_child(email_input)
	var continue_button := UIFactory.button("CONTINUAR", Rect2(70, 292, 460, 48), UIFactory.PALETTE.orange, "play")
	continue_button.pressed.connect(func(): login_requested.emit(email_input.text.strip_edges()))
	card.add_child(continue_button)
	message_label = UIFactory.label("", Rect2(70, 345, 460, 38), 14, UIFactory.PALETTE.red)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(message_label)
	consent_box = UIFactory.panel(Rect2(55, 386, 490, 145), Color("101c35"), Color("334b70"))
	consent_box.visible = false
	card.add_child(consent_box)
	alias_input = LineEdit.new()
	alias_input.position = Vector2(14, 12)
	alias_input.size = Vector2(180, 38)
	alias_input.placeholder_text = "Alias (2 a 20)"
	consent_box.add_child(alias_input)
	var consent_text := UIFactory.label(str(GameConfig.text("consent", "Acepto participar en la prueba piloto.")), Rect2(208, 8, 265, 62), 12, UIFactory.PALETTE.muted)
	consent_box.add_child(consent_text)
	consent_check = CheckBox.new()
	consent_check.text = "Acepto el consentimiento"
	consent_check.position = Vector2(14, 60)
	consent_check.size = Vector2(260, 32)
	consent_box.add_child(consent_check)
	create_button = UIFactory.button("CREAR PERFIL", Rect2(285, 88, 188, 42), UIFactory.PALETTE.green)
	create_button.pressed.connect(func(): create_requested.emit(email_input.text.strip_edges(), alias_input.text.strip_edges(), consent_check.button_pressed))
	consent_box.add_child(create_button)
