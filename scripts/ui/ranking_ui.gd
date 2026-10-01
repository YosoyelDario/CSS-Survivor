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
	var bg:=ColorRect.new(); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.color=UIFactory.PALETTE.bg; root.add_child(bg);
	var stage:=UIFactory.stage(root)
	var title:=UIFactory.title("RANKING LOCAL",Rect2(100,45,1080,50),30,UIFactory.PALETTE.yellow); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; stage.add_child(title)
	# Encabezado con las mismas columnas que _add_row (x de la tarjeta + 250 del contenedor).
	var muted:Color=UIFactory.PALETTE.muted
	stage.add_child(UIFactory.label("POS.",Rect2(250+48,118,60,24),13,muted))
	stage.add_child(UIFactory.label("JUGADOR",Rect2(250+105,118,300,24),13,muted))
	var h_pts:=UIFactory.label("PUNTOS",Rect2(250+420,118,150,24),13,muted); h_pts.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; stage.add_child(h_pts)
	var h_badges:=UIFactory.label("INSIGNIAS",Rect2(250+585,118,170,24),13,muted); h_badges.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; stage.add_child(h_badges)
	var scroll:=ScrollContainer.new(); scroll.position=Vector2(250,150); scroll.size=Vector2(800,430); stage.add_child(scroll)
	rows_box=VBoxContainer.new(); rows_box.custom_minimum_size=Vector2(780,0); rows_box.add_theme_constant_override("separation",8); scroll.add_child(rows_box)
	var back:=UIFactory.button("VOLVER",Rect2(70,635,180,44),Color("253959")); back.pressed.connect(func():back_requested.emit()); stage.add_child(back)
