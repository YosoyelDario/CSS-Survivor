extends CanvasLayer

signal back_requested

const UIFactory = preload("res://scripts/ui/ui_factory.gd")
const GameConfig = preload("res://scripts/managers/game_config.gd")

var root: Control
var list_container: VBoxContainer

func _ready() -> void:
	layer = 22
	_build()

func show_achievements(session_manager: Variant) -> void:
	root.visible = true

	for child in list_container.get_children():
		child.queue_free()

	for badge_data in GameConfig.badges():
		var badge: Dictionary = badge_data as Dictionary

		var badge_id: String = str(
			badge.get("id", "")
		)

		var owned: bool = bool(
			session_manager.has_badge(badge_id)
		)

		var card = UIFactory.panel(
			Rect2(0, 0, 820, 82),
			Color("101c35"),
			UIFactory.PALETTE.yellow if owned else Color("33415c")
		)

		card.custom_minimum_size = Vector2(820, 82)

		var icon_name: String = "medal" if owned else "medal_locked"

		card.add_child(
			UIFactory.icon_rect(
				icon_name,
				Rect2(18, 15, 48, 48)
			)
		)

		var badge_name: String = str(
			badge.get("name", "Insignia")
		)

		var name_label = UIFactory.label(
			badge_name,
			Rect2(84, 12, 480, 26),
			17,
			UIFactory.PALETTE.text
		)

		card.add_child(name_label)

		var description: String = str(
			badge.get("description", "")
		)

		var desc_label = UIFactory.label(
			description,
			Rect2(84, 40, 560, 30),
			13,
			UIFactory.PALETTE.muted
		)

		card.add_child(desc_label)

		var date_text: String = "BLOQUEADA"

		if owned:
			date_text = str(
				session_manager.badge_date(badge_id)
			)

		var date_color = (
			UIFactory.PALETTE.green
			if owned
			else UIFactory.PALETTE.muted
		)

		var date_label = UIFactory.label(
			date_text,
			Rect2(650, 24, 145, 26),
			12,
			date_color
		)

		card.add_child(date_label)

		list_container.add_child(card)
func hide_achievements() -> void:
	root.visible = false

func _build() -> void:
	root = Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.theme = UIFactory.make_theme(); root.visible=false; add_child(root)
	var bg:=ColorRect.new(); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.color=UIFactory.PALETTE.bg; root.add_child(bg)
	var title:=UIFactory.title("LOGROS",Rect2(100,45,1080,50),30,UIFactory.PALETTE.purple); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; root.add_child(title)
	var scroll:=ScrollContainer.new(); scroll.position=Vector2(230,130); scroll.size=Vector2(840,440); root.add_child(scroll)
	list_container=VBoxContainer.new(); list_container.custom_minimum_size=Vector2(820,0); list_container.add_theme_constant_override("separation",12); scroll.add_child(list_container)
	var back:=UIFactory.button("VOLVER",Rect2(70,635,180,44),Color("253959")); back.pressed.connect(func(): back_requested.emit()); root.add_child(back)
