extends CanvasLayer

signal back_requested
const UIFactory=preload("res://scripts/ui/ui_factory.gd")
const GameConfig=preload("res://scripts/managers/game_config.gd")
var root:Control

func _ready()->void:
	layer=22; _build()
func show_howto()->void:
	root.visible=true
func hide_howto()->void:
	root.visible=false
func _build()->void:
	root=Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.theme=UIFactory.make_theme(); root.visible=false; add_child(root)
	var bg:=ColorRect.new(); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.color=UIFactory.PALETTE.bg; root.add_child(bg);
	var stage:=UIFactory.stage(root)
	var title:=UIFactory.title("CÓMO JUGAR",Rect2(100,40,1080,50),30,UIFactory.PALETTE.cyan); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; stage.add_child(title)
	var steps:Array=GameConfig.text("how_to",[])
	for i in range(steps.size()):
		var col:=i%2; var row:=i/2
		var card:=UIFactory.panel(Rect2(150+col*500,120+row*135,460,110),Color("101c35"),Color("294f70")); stage.add_child(card)
		var num:=UIFactory.label(str(i+1),Rect2(18,20,54,54),26,UIFactory.PALETTE.orange); num.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; num.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; card.add_child(num)
		card.add_child(UIFactory.title(str(steps[i][0]),Rect2(86,18,345,28),14,UIFactory.PALETTE.cyan))
		card.add_child(UIFactory.label(str(steps[i][1]),Rect2(86,49,345,48),13,UIFactory.PALETTE.text))
	var controls:=UIFactory.panel(Rect2(220,540,840,70),Color("0d172b"),UIFactory.PALETTE.purple); stage.add_child(controls)
	var c:=UIFactory.label("CONTROLES   WASD/Flechas: mover   •   E/Espacio/Enter: interactuar o continuar   •   1-4: responder   •   ESC: pausa",Rect2(24,18,792,38),14,UIFactory.PALETTE.text); c.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; controls.add_child(c)
	var back:=UIFactory.button("VOLVER",Rect2(70,635,180,44),Color("253959")); back.pressed.connect(func():back_requested.emit()); stage.add_child(back)
