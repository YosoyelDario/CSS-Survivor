extends Node2D

const WORLD_SIZE := Vector2(2200, 1400)
const PAGE := Rect2(80, 80, 2040, 1240)
const ZONES := [
	Rect2(160, 170, 560, 380),
	Rect2(1480, 170, 560, 380),
	Rect2(160, 850, 560, 380),
	Rect2(1480, 850, 560, 380)
]

# Los fondos ahora son PNG externos. Para cambiar un nivel, reemplaza estos archivos
# manteniendo el mismo nombre. Tamaño recomendado: 2200x1400.
const INFECTED_BACKGROUNDS: Array[Texture2D] = [
	preload("res://assets/backgrounds/level1_infected.png"),
	preload("res://assets/backgrounds/level2_infected.png"),
	preload("res://assets/backgrounds/level3_infected.png")
]
const CLEAN_BACKGROUNDS: Array[Texture2D] = [
	preload("res://assets/backgrounds/level1_clean.png"),
	preload("res://assets/backgrounds/level2_clean.png"),
	preload("res://assets/backgrounds/level3_clean.png")
]

var level: int = 1
var cleared: Array[bool] = [false, false, false, false]
var zone_progress: Array[float] = [0.0, 0.0, 0.0, 0.0]
var fully_repaired: bool = false

func set_level(value: int) -> void:
	level = clampi(value, 1, 3)
	cleared = [false, false, false, false]
	zone_progress = [0.0, 0.0, 0.0, 0.0]
	fully_repaired = false
	queue_redraw()

func set_zone_progress(index: int, value: float) -> void:
	if index >= 0 and index < zone_progress.size():
		zone_progress[index] = clampf(value, 0.0, 1.0)
	queue_redraw()

func clear_zone(index: int) -> void:
	if index >= 0 and index < cleared.size():
		cleared[index] = true
		zone_progress[index] = 1.0
	fully_repaired = true
	for value in cleared:
		if not value:
			fully_repaired = false
			break
	queue_redraw()

func _draw() -> void:
	var texture_index := clampi(level - 1, 0, 2)
	var infected: Texture2D = INFECTED_BACKGROUNDS[texture_index]
	var clean: Texture2D = CLEAN_BACKGROUNDS[texture_index]

	# Fondo base infectado del nivel.
	if infected:
		draw_texture_rect(infected, Rect2(Vector2.ZERO, WORLD_SIZE), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("07101d"), true)

	# Cada zona se va "limpiando" mostrando la misma región del PNG limpio.
	# Así no necesitas programar el diseño: basta reemplazar los PNG.
	if clean:
		if fully_repaired:
			draw_texture_rect(clean, Rect2(Vector2.ZERO, WORLD_SIZE), false)
		else:
			for i in range(ZONES.size()):
				var r: Rect2 = ZONES[i]
				var progress := zone_progress[i]
				if progress > 0.0:
					draw_texture_rect_region(clean, r, r, Color(1, 1, 1, progress))

	# Bordes de las cuatro zonas para que el jugador sepa qué falta limpiar.
	for i in range(ZONES.size()):
		var r: Rect2 = ZONES[i]
		var progress := zone_progress[i]
		if cleared[i]:
			draw_rect(r, Color("36d98b"), false, 4)
			draw_line(r.position + Vector2(28, 48), r.position + Vector2(46, 66), Color("2ecf79"), 7)
			draw_line(r.position + Vector2(46, 66), r.position + Vector2(80, 26), Color("2ecf79"), 7)
		else:
			draw_rect(r, Color("ff3d6e").lerp(Color("36d98b"), progress), false, 4)
