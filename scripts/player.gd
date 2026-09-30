extends CharacterBody2D

const PLAYER_TEXTURE: Texture2D = preload("res://assets/player/hacker.png")

var speed: float = 255.0
var can_move: bool = false
# Mapa grande: la cámara seguirá al jugador y revelará distintas partes de la web.
var movement_bounds := Rect2(130, 130, 1940, 1140)

func _ready() -> void:
	z_index = 20
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	global_position.x = clamp(global_position.x, movement_bounds.position.x, movement_bounds.end.x)
	global_position.y = clamp(global_position.y, movement_bounds.position.y, movement_bounds.end.y)

func _draw() -> void:
	# La apariencia del jugador ahora sale de assets/player/hacker.png.
	# Puedes reemplazar ese PNG sin tocar este script.
	draw_ellipse(Vector2(0, 28), Vector2(29, 9), Color(0, 0, 0, 0.28))
	if PLAYER_TEXTURE:
		draw_texture_rect(PLAYER_TEXTURE, Rect2(-48, -48, 96, 96), false)

# Helper porque Node2D no trae draw_ellipse.
func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(pts, color)
