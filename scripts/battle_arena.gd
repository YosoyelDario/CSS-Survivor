extends Node2D

const PLAYER_TEXTURE: Texture2D = preload("res://assets/player/hacker.png")
const BATTLE_WEB_TEXTURE: Texture2D = preload("res://assets/backgrounds/battle_web.png")
const BUG_TEXTURES: Array[Texture2D] = [
	preload("res://assets/enemies/virus_1.png"),
	preload("res://assets/enemies/virus_2.png"),
	preload("res://assets/enemies/virus_3.png"),
	preload("res://assets/enemies/virus_4.png")
]

var level: int = 1
var target_hp: int = 3
var target_max_hp: int = 3
var target_alive: bool = true
var target_variant: int = 0
var hit_flash: float = 0.0
var miss_flash: float = 0.0

func set_battle_state(level_value: int, hp_value: int, max_hp_value: int, alive_value: bool = true, variant_value: int = 0) -> void:
	level = level_value
	target_hp = hp_value
	target_max_hp = max_hp_value
	target_alive = alive_value
	target_variant = clampi(variant_value, 0, BUG_TEXTURES.size() - 1)
	queue_redraw()

func target_screen_position() -> Vector2:
	return Vector2(640, 320)

func player_screen_position() -> Vector2:
	return Vector2(640, 414)

func flash_hit(success: bool) -> void:
	if success:
		hit_flash = 1.0
	else:
		miss_flash = 1.0
	queue_redraw()
	var tween := create_tween()
	if success:
		tween.tween_method(_set_hit_flash, 1.0, 0.0, 0.28)
	else:
		tween.tween_method(_set_miss_flash, 1.0, 0.0, 0.28)
	await tween.finished

func _set_hit_flash(value: float) -> void:
	hit_flash = value
	queue_redraw()

func _set_miss_flash(value: float) -> void:
	miss_flash = value
	queue_redraw()

func _draw_bug_sprite(pos: Vector2, texture: Texture2D, size: float = 60.0, alpha: float = 1.0) -> void:
	if texture == null:
		return
	var half := size / 2.0
	draw_texture_rect(texture, Rect2(pos - Vector2(half, half), Vector2(size, size)), false, Color(1, 1, 1, alpha))

func _draw() -> void:
	# Fondo general de batalla.
	draw_rect(Rect2(0, 0, 1280, 720), Color("07101d"), true)

	# Sitio web de batalla cargado desde PNG externo.
	var browser := Rect2(82, 92, 1116, 350)
	if BATTLE_WEB_TEXTURE:
		draw_texture_rect(BATTLE_WEB_TEXTURE, browser, false)
	else:
		draw_rect(browser, Color("edf6fb"), true)
	draw_rect(browser, Color("22c7f2"), false, 3)

	# Enemigos de fondo: sprites externos.
	for x in [470.0, 640.0, 810.0]:
		_draw_bug_sprite(Vector2(x, 225), BUG_TEXTURES[1], 54, 0.92)
		_draw_bug_sprite(Vector2(x, 275), BUG_TEXTURES[2], 60, 0.92)
		if x != 640.0:
			_draw_bug_sprite(Vector2(x, 330), BUG_TEXTURES[0], 66, 0.70)

	# BUG objetivo de esta zona.
	if target_alive:
		var target_texture: Texture2D = BUG_TEXTURES[target_variant]
		var size := 88.0 + hit_flash * 10.0
		var modulate_color := Color.WHITE.lerp(Color("8ff8ff"), hit_flash * 0.65)
		var half := size / 2.0
		draw_texture_rect(target_texture, Rect2(Vector2(640, 320) - Vector2(half, half), Vector2(size, size)), false, modulate_color)
		draw_arc(Vector2(640, 320), 48 + hit_flash * 8, 0, TAU, 40, Color(0.2, 0.85, 1.0, 0.7), 3)

	# HP del enemigo seleccionado.
	draw_rect(Rect2(590, 365, 100, 9), Color("2b1b2e"), true)
	var ratio := 0.0
	if target_max_hp > 0:
		ratio = float(target_hp) / float(target_max_hp)
	draw_rect(Rect2(590, 365, 100 * ratio, 9), Color("ffd447"), true)

	# Jugador: mismo PNG que se usa en el mapa.
	if PLAYER_TEXTURE:
		draw_texture_rect(PLAYER_TEXTURE, Rect2(592, 366, 96, 96), false)

	if miss_flash > 0.0:
		draw_rect(browser, Color(1.0, 0.08, 0.20, 0.18 * miss_flash), true)
