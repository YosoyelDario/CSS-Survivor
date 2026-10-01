extends CanvasLayer

signal play_level(level: int)
signal back_requested

const UIFactory = preload("res://scripts/ui/ui_factory.gd")
const GameConfig = preload("res://scripts/managers/game_config.gd")
const THUMBS: Array[Texture2D] = [
	preload("res://assets/backgrounds/level1_infected.png"),
	preload("res://assets/backgrounds/level2_infected.png"),
	preload("res://assets/backgrounds/level3_infected.png")
]

var root: Control
var cards: Array = []

func _ready() -> void:
	layer = 22
	_build()

func show_levels(session_manager) -> void:
	root.visible = true
	for i in range(cards.size()):
		var level := i + 1
		var data: Dictionary = cards[i]
		var stats: Dictionary = session_manager.level_stats(level)
		var has_content: bool = GameConfig.level_available(level)   # el nivel existe en game_config.json
		var unlocked: bool = session_manager.level_unlocked(level)  # completó el nivel anterior
		var playable: bool = has_content and unlocked
		var completed: bool = bool(stats.get("completed", false))
		data["button"].disabled = not playable
		data["lock"].visible = not playable
		data["thumb"].modulate = Color.WHITE if playable else Color(0.45, 0.45, 0.5, 0.55)
		if completed:
			data["status"].text = "COMPLETADO"
		elif playable:
			data["status"].text = "DISPONIBLE"
		elif has_content:
			data["status"].text = "BLOQUEADO"
		else:
			data["status"].text = "PRÓXIMAMENTE"
		var status_color: Color = UIFactory.PALETTE.green if playable else UIFactory.PALETTE.muted
		data["status"].add_theme_color_override("font_color", status_color)
		if playable:
			data["meta"].text = "Mejor puntaje: %d\nIntentos: %d" % [int(stats.get("best_score", 0)), int(stats.get("attempts", 0))]
		elif has_content:
			data["meta"].text = "Completa el Nivel %d para desbloquearlo" % (level - 1)
		else:
			data["meta"].text = "Contenido en desarrollo"

func hide_levels() -> void:
	root.visible = false

func _build() -> void:
	root = Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.theme = UIFactory.make_theme(); root.visible = false; add_child(root)
	var bg := ColorRect.new(); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.color = UIFactory.PALETTE.bg; root.add_child(bg);
	var stage:=UIFactory.stage(root)
	var title := UIFactory.title("NIVELES", Rect2(100, 45, 1080, 50), 30, UIFactory.PALETTE.cyan); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; stage.add_child(title)
	var names := ["NIVEL 1\nCOLORES Y TIPOGRAFÍAS", "NIVEL 2\nMODELO DE CAJA", "NIVEL 3\nLAYOUT"]
	for i in range(3):
		var x := 85 + i * 395
		var card := UIFactory.panel(Rect2(x, 145, 330, 430), Color("0d172b"), UIFactory.PALETTE.cyan if i == 0 else Color("33415c"))
		stage.add_child(card)
		# Corrección: antes la miniatura se creaba con la textura (2200x1400) ANTES de poner
		# expand_mode, y Godot ignoraba el tamaño de 290x150. UIFactory.texture_rect lo hace en orden.
		# KEEP_ASPECT_COVERED llena el recuadro recortando el centro, sin deformar el mapa.
		var thumb := UIFactory.texture_rect(THUMBS[i], Rect2(20,20,290,150), TextureRect.STRETCH_KEEP_ASPECT_COVERED)
		thumb.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # es una imagen reducida, no pixel art
		thumb.clip_contents = true
		thumb.modulate = Color.WHITE if i == 0 else Color(0.45,0.45,0.5,0.55)
		card.add_child(thumb)
		var label := UIFactory.title(names[i], Rect2(25, 190, 280, 75), 14, UIFactory.PALETTE.text); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; card.add_child(label)
		var status := UIFactory.label("", Rect2(30, 275, 270, 28), 15, UIFactory.PALETTE.green if i == 0 else UIFactory.PALETTE.muted); status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; card.add_child(status)
		var meta := UIFactory.label("", Rect2(30, 310, 270, 55), 14, UIFactory.PALETTE.muted); meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; card.add_child(meta)
		var button := UIFactory.button("JUGAR", Rect2(65, 370, 200, 42), UIFactory.PALETTE.orange, "play"); button.pressed.connect(_on_play_pressed.bind(i + 1)); card.add_child(button)
		var lock := UIFactory.icon_rect("lock", Rect2(135, 65, 60, 60)); lock.visible = i != 0; card.add_child(lock)
		cards.append({"button":button,"status":status,"meta":meta,"lock":lock,"thumb":thumb})
	var back := UIFactory.button("VOLVER", Rect2(70, 635, 180, 44), Color("253959")); back.pressed.connect(func(): back_requested.emit()); stage.add_child(back)

func _on_play_pressed(level: int) -> void:
	play_level.emit(level)
