extends CanvasLayer

signal back_requested

const UIFactory = preload("res://scripts/ui/ui_factory.gd")
var root: Control
var rows_box: VBoxContainer

func _ready() -> void:
	layer=22
	_build()

func show_ranking(session_manager) -> void:
	root.visible=true
	for child in rows_box.get_children():
		child.queue_free()
	var ranking:Array=session_manager.ranking()
	if ranking.is_empty():
		var empty:=UIFactory.label("Aún no hay perfiles con puntaje.",Rect2(0,0,780,50),17,UIFactory.PALETTE.muted); empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; rows_box.add_child(empty); return
	var limit:=mini(10,ranking.size())
	var current_in_top:=false
	for i in range(limit):
		_add_row(i+1,ranking[i]); current_in_top = current_in_top or bool(ranking[i].get("current",false))
	if not current_in_top:
		for i in range(limit,ranking.size()):
			if bool(ranking[i].get("current",false)):
				_add_row(i+1,ranking[i]); break

func _add_row(position:int,data:Dictionary)->void:
	var border:=Color("33415c")
	if position==1:
		border=Color("ffd447")
	elif position==2:
		border=Color("b9c4d7")
	elif position==3:
		border=Color("c88c5d")
	if bool(data.get("current",false)):
		border=UIFactory.PALETTE.cyan
	var card:=UIFactory.panel(Rect2(0,0,780,46),Color("101c35"),border,8); card.custom_minimum_size=Vector2(780,46)
	if position==1:
		card.add_child(UIFactory.icon_rect("trophy",Rect2(16,10,26,26)))
	var pos:=UIFactory.label(str(position),Rect2(48,8,44,28),15,UIFactory.PALETTE.text); card.add_child(pos)
	card.add_child(UIFactory.label(str(data.get("alias","JUGADOR")),Rect2(105,8,300,28),15,UIFactory.PALETTE.text))
	var pts:=UIFactory.label("%d pts"%int(data.get("points",0)),Rect2(420,8,150,28),15,UIFactory.PALETTE.yellow); pts.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; card.add_child(pts)
	var badge:=UIFactory.label("%d insignias"%int(data.get("badges",0)),Rect2(585,8,170,28),13,UIFactory.PALETTE.muted); badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; card.add_child(badge)
	rows_box.add_child(card)

func hide_ranking()->void:
	root.visible=false

func _build()->void:
	root=Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.theme=UIFactory.make_theme(); root.visible=false; add_child(root)
	var bg:=ColorRect.new(); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.color=UIFactory.PALETTE.bg; root.add_child(bg)
	var title:=UIFactory.title("RANKING LOCAL",Rect2(100,45,1080,50),30,UIFactory.PALETTE.yellow); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; root.add_child(title)
	var headers:=UIFactory.label("POS.        JUGADOR                                  PUNTOS                 LOGROS",Rect2(250,115,780,28),13,UIFactory.PALETTE.muted); root.add_child(headers)
	var scroll:=ScrollContainer.new(); scroll.position=Vector2(250,150); scroll.size=Vector2(800,430); root.add_child(scroll)
	rows_box=VBoxContainer.new(); rows_box.custom_minimum_size=Vector2(780,0); rows_box.add_theme_constant_override("separation",8); scroll.add_child(rows_box)
	var back:=UIFactory.button("VOLVER",Rect2(70,635,180,44),Color("253959")); back.pressed.connect(func():back_requested.emit()); root.add_child(back)
