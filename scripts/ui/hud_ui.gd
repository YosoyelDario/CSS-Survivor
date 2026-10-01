extends CanvasLayer

const UIFactory = preload("res://scripts/ui/ui_factory.gd")

<<<<<<< Updated upstream
var hearts_label: Label
var points_label: Label
var level_label: Label
var zones_label: Label
var repair_bar: ProgressBar
var interact_label: Label

func _ready() -> void:
	layer = 10
	_build()
	visible = false

func update_hud(lives: int, max_lives: int, points: int, level: int, cleared_zones: int, repair_percent: float) -> void:
	hearts_label.text = "VIDAS  " + "♥".repeat(lives) + "♡".repeat(max_lives - lives)
	points_label.text = "★ %d PTS" % points
	var names := {1:"VISUALES BÁSICAS", 2:"MODELO DE CAJA", 3:"LAYOUT"}
	level_label.text = "NIVEL %d — %s" % [level, names[level]]
	zones_label.text = "ZONAS REPARADAS  %d/4" % cleared_zones
	repair_bar.value = clampf(repair_percent, 0.0, 100.0)

func show_interaction(text_value: String) -> void:
	interact_label.text = text_value
	interact_label.visible = true

func hide_interaction() -> void:
	interact_label.visible = false

func _build() -> void:
	var top := UIFactory.panel(Rect2(70, 25, 1140, 55), Color(0.04, 0.09, 0.17, 0.96), Color("20c7f3"))
	add_child(top)
	hearts_label = UIFactory.label("", Rect2(18, 12, 250, 32), 18, Color("ff5777"))
	top.add_child(hearts_label)
	points_label = UIFactory.label("", Rect2(275, 12, 200, 32), 18, Color("ffd45f"))
	top.add_child(points_label)
	level_label = UIFactory.label("", Rect2(465, 8, 320, 38), 17, Color("ffffff"))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(level_label)
	zones_label = UIFactory.label("", Rect2(820, 12, 285, 32), 16, Color("66efa0"))
	zones_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(zones_label)

	var bottom := UIFactory.panel(Rect2(180, 625, 920, 62), Color(0.04, 0.09, 0.17, 0.96), Color("315b82"))
	add_child(bottom)
	bottom.add_child(UIFactory.label("REPARACIÓN DEL SITIO", Rect2(18, 8, 190, 25), 13, Color("bcd1e5")))
	repair_bar = ProgressBar.new()
	repair_bar.position = Vector2(210, 10)
	repair_bar.size = Vector2(680, 22)
	repair_bar.min_value = 0
	repair_bar.max_value = 100
	repair_bar.show_percentage = true
	bottom.add_child(repair_bar)
	interact_label = UIFactory.label("", Rect2(160, 34, 600, 25), 14, Color("ffe06e"))
	interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(interact_label)
=======
func _ready()->void:
	layer=15; _build(); root.visible=false
func set_hud_visible(value: bool) -> void:
	root.visible = value
func update_hud(lives:int,max_lives:int,points:int,level_name:String,cleared_zones:int,repair_percent:float)->void:
	for c in hearts_box.get_children():
		c.queue_free()
	for i in range(max_lives):
		hearts_box.add_child(UIFactory.icon_rect("heart" if i<lives else "heart_empty",Rect2(0,0,24,24)))
	points_label.text="%d PTS"%points
	level_label.text=level_name
	zones_label.text="ZONAS %d/4"%cleared_zones
	repair_bar.value=clampf(repair_percent,0.0,100.0)
func show_interaction(text_value:String)->void:
	interact_label.text=text_value
	interact_panel.visible=true
func hide_interaction()->void:
	interact_panel.visible=false
func _build()->void:
	root=Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.theme=UIFactory.make_theme(); root.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(root)
	var stage:=UIFactory.stage(root)
	var top:=UIFactory.panel(Rect2(45,22,1190,58),Color(0.03,0.07,0.13,0.96),UIFactory.PALETTE.cyan); stage.add_child(top)
	hearts_box=HBoxContainer.new(); hearts_box.position=Vector2(20,17); hearts_box.size=Vector2(170,26); hearts_box.add_theme_constant_override("separation",4); top.add_child(hearts_box)
	top.add_child(UIFactory.icon_rect("star",Rect2(215,16,26,26)))
	points_label=UIFactory.label("0 PTS",Rect2(248,14,150,30),16,UIFactory.PALETTE.yellow); top.add_child(points_label)
	level_label=UIFactory.title("NIVEL 1",Rect2(415,12,380,34),14,UIFactory.PALETTE.text); level_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; top.add_child(level_label)
	zones_label=UIFactory.label("ZONAS 0/4",Rect2(930,14,220,30),16,UIFactory.PALETTE.green); zones_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; top.add_child(zones_label)
	var bottom:=UIFactory.panel(Rect2(220,642,840,54),Color(0.03,0.07,0.13,0.96),Color("315b82")); stage.add_child(bottom)
	bottom.add_child(UIFactory.label("REPARACIÓN DEL SITIO",Rect2(18,8,190,22),12,UIFactory.PALETTE.muted))
	repair_bar=UIFactory.progress(Rect2(210,10,600,14),UIFactory.PALETTE.green); bottom.add_child(repair_bar)
	interact_panel=UIFactory.panel(Rect2(360,585,560,46),Color(0.03,0.07,0.13,0.96),UIFactory.PALETTE.yellow); stage.add_child(interact_panel)
	interact_label=UIFactory.label("",Rect2(15,8,530,28),14,UIFactory.PALETTE.yellow); interact_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; interact_panel.add_child(interact_label); interact_panel.visible=false
>>>>>>> Stashed changes
