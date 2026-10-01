extends CanvasLayer

signal retry_requested
signal ranking_requested
signal menu_requested

const UIFactory=preload("res://scripts/ui/ui_factory.gd")
var root:Control
var title_label:Label
var metrics_label:Label
var repair_bar:ProgressBar
var badges_label:Label
var kcr_box:VBoxContainer
var show_more_button:Button
var next_button:Button
var history:Array=[]
var visible_count:int=5

func _ready()->void:
	layer=45; _build()

func show_results(run,game_over:bool,new_badges:Array)->void:
	root.visible=true
	history=run.history.duplicate(true)
	visible_count=5
	title_label.text="GAME OVER" if game_over else "NIVEL 1 COMPLETADO"
	title_label.add_theme_color_override("font_color",UIFactory.PALETTE.red if game_over else UIFactory.PALETTE.green)
	metrics_label.text="Puntaje: %d    Aciertos: %d    Errores: %d    Vidas: %d    Tiempo: %.1f s    Mejor racha: %d"%[run.score,run.correct_count,run.error_count,run.lives,run.elapsed_seconds(),run.best_streak]
	repair_bar.value=run.repair_percent()*100.0
	var badge_text := "ninguna nueva"
	if not new_badges.is_empty():
		var names: PackedStringArray = []
		for value in new_badges:
			names.append(str(value))
		badge_text = ", ".join(names)
	badges_label.text = "Nuevas insignias: " + badge_text
	_refresh_kcr()

func hide_results()->void:
	root.visible=false

func _refresh_kcr()->void:
	for child in kcr_box.get_children():
		child.queue_free()
	var amount:=mini(visible_count,history.size())
	for i in range(amount):
		var item: Dictionary = history[i]
		var correct := bool(item.get("correct", false))
		var code := str(item.get("code", ""))
		var has_code := not code.is_empty()
		var card_height := 118 if correct and has_code else (154 if not correct and has_code else (96 if correct else 132))
		var card := UIFactory.panel(Rect2(0, 0, 880, card_height), Color("101c35"), UIFactory.PALETTE.green if correct else UIFactory.PALETTE.red, 8)
		card.custom_minimum_size = Vector2(880, card_height)
		card.add_child(UIFactory.icon_rect("check" if correct else "cross", Rect2(14, 16, 24, 24)))
		var tag := UIFactory.label("%s • ZONA %d" % [str(item.get("type", "")).to_upper(), int(item.get("zone", 0)) + 1], Rect2(48, 10, 250, 22), 11, UIFactory.PALETTE.muted)
		card.add_child(tag)
		var q := UIFactory.label(str(item.get("question", "")), Rect2(48, 34, 805, 32), 14, UIFactory.PALETTE.text)
		card.add_child(q)
		var answer_y := 66
		if has_code:
			var code_line := UIFactory.code_label(code, Rect2(48, 65, 805, 24), 12)
			card.add_child(code_line)
			answer_y = 90
		var answer := UIFactory.label("Tu respuesta: %s" % str(item.get("selected", "")), Rect2(48, answer_y, 805, 24), 12, UIFactory.PALETTE.green if correct else UIFactory.PALETTE.red)
		card.add_child(answer)
		if not correct:
			var correct_answer := UIFactory.label("Correcta: %s" % str(item.get("answer", "")), Rect2(48, answer_y + 25, 805, 20), 12, UIFactory.PALETTE.green)
			card.add_child(correct_answer)
			var exp := UIFactory.label(str(item.get("explanation", "")), Rect2(48, answer_y + 45, 805, 18), 11, UIFactory.PALETTE.muted)
			card.add_child(exp)
		kcr_box.add_child(card)
	show_more_button.visible=visible_count<history.size()

func _build()->void:
	root=Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.theme=UIFactory.make_theme(); root.visible=false; add_child(root)
	var bg:=ColorRect.new(); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.color=UIFactory.PALETTE.bg; root.add_child(bg)
	title_label=UIFactory.title("NIVEL 1 COMPLETADO",Rect2(90,26,1100,48),28,UIFactory.PALETTE.green); title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; root.add_child(title_label)
	metrics_label=UIFactory.label("",Rect2(100,82,1080,30),14,UIFactory.PALETTE.text); metrics_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; root.add_child(metrics_label)
	repair_bar=UIFactory.progress(Rect2(290,122,700,16),UIFactory.PALETTE.green); root.add_child(repair_bar)
	badges_label=UIFactory.label("",Rect2(210,148,860,28),13,UIFactory.PALETTE.yellow); badges_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; root.add_child(badges_label)
	var scroll:=ScrollContainer.new(); scroll.position=Vector2(190,190); scroll.size=Vector2(900,355); root.add_child(scroll)
	kcr_box=VBoxContainer.new(); kcr_box.custom_minimum_size=Vector2(880,0); kcr_box.add_theme_constant_override("separation",8); scroll.add_child(kcr_box)
	show_more_button=UIFactory.button("MOSTRAR MÁS",Rect2(550,555,180,38),Color("253959")); show_more_button.pressed.connect(func():visible_count+=5;_refresh_kcr()); root.add_child(show_more_button)
	var retry:=UIFactory.button("REINTENTAR NIVEL",Rect2(125,625,220,44),UIFactory.PALETTE.orange); retry.pressed.connect(func():retry_requested.emit()); root.add_child(retry)
	var ranking:=UIFactory.button("RANKING",Rect2(380,625,180,44),Color("256ec0"),"trophy"); ranking.pressed.connect(func():ranking_requested.emit()); root.add_child(ranking)
	next_button=UIFactory.button("SIGUIENTE NIVEL",Rect2(595,625,220,44),UIFactory.PALETTE.green); next_button.disabled=true; next_button.tooltip_text="Nivel 2 aún no está disponible"; root.add_child(next_button)
	var menu:=UIFactory.button("VOLVER AL MENÚ",Rect2(850,625,220,44),Color("253959")); menu.pressed.connect(func():menu_requested.emit()); root.add_child(menu)
