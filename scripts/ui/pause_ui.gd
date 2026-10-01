extends CanvasLayer
signal continue_requested
signal menu_requested
const UIFactory=preload("res://scripts/ui/ui_factory.gd")
var root:Control
func _ready()->void:
	layer=60
	_build()
func show_pause()->void:
	root.visible=true
func hide_pause()->void:
	root.visible=false
func _build()->void:
	root=Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.theme=UIFactory.make_theme(); root.visible=false; add_child(root)
	var dim:=ColorRect.new(); dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dim.color=Color(0.01,0.02,0.05,0.98); root.add_child(dim)
	var stage:=UIFactory.stage(root)
	var card:=UIFactory.panel(Rect2(390,190,500,330),Color("0d172b"),UIFactory.PALETTE.cyan); stage.add_child(card)
	var title:=UIFactory.title("PAUSA",Rect2(40,35,420,45),26,UIFactory.PALETTE.cyan); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; card.add_child(title)
	var info:=UIFactory.label("Puedes continuar el intento o salir al menú. Si sales, el intento se contará como abandonado y no guardará mejores marcas.",Rect2(60,105,380,90),15,UIFactory.PALETTE.text); info.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; card.add_child(info)
	var c:=UIFactory.button("CONTINUAR",Rect2(70,220,160,48),UIFactory.PALETTE.green); c.pressed.connect(func():continue_requested.emit()); card.add_child(c)
	var m:=UIFactory.button("SALIR AL MENÚ",Rect2(260,220,170,48),Color("5a2940")); m.pressed.connect(func():menu_requested.emit()); card.add_child(m)
