extends Node2D
## Script raiz de la escena Main. Conecta enemigo, jugador, panel de input,
## validador y log en un ciclo de turno simplificado.
##
## OJO: esta es la BASE del proyecto, no la version final. El avance de
## enemigos lejos -> medio -> frente (TurnManager.Estado.AVANCE_ENEMIGOS)
## todavia no esta conectado a un timer/turno real: por ahora los enemigos
## nacen directo en FRENTE para que el loop principal sea jugable de inmediato.
## Siguiente paso: implementar el avance por oleadas antes de que llegue a FRENTE.

const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")

@export var nivel_actual: int = 1
@export var id_jugador: String = "jugador_demo@alumnos.ucv.cl"

var ejercicios: Array = []
var enemigo_objetivo: Enemy = null

@onready var player: Player = $Player
@onready var enemy_row: Node2D = $EnemyRow
@onready var hud: Label = $UI/HUD
@onready var input_panel: InputPanel = $UI/InputPanel

func _ready() -> void:
	input_panel.respuesta_enviada.connect(_on_respuesta_enviada)
	_cargar_ejercicios(nivel_actual)
	_spawn_oleada()
	_actualizar_hud()

func _cargar_ejercicios(nivel: int) -> void:
	var path := "res://data/ejercicios_nivel%d.json" % nivel
	if not FileAccess.file_exists(path):
		push_warning("No existe banco de ejercicios: %s" % path)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	ejercicios = JSON.parse_string(f.get_as_text())
	f.close()

func _spawn_oleada() -> void:
	TurnManager.iniciar_avance()
	var carriles := [0, 1, 2]
	for carril in carriles:
		var e: Enemy = ENEMY_SCENE.instantiate()
		var ej: Dictionary = ejercicios[randi() % ejercicios.size()]
		e.propiedad_requerida = ej.get("propiedad", "color")
		e.valor_requerido = ej.get("valor", "red")
		e.carril = carril
		e.distancia = Enemy.Distancia.FRENTE  # TODO: iniciar en LEJOS cuando exista el avance por turnos
		e.position = Vector2((carril - 1) * 150, 0)
		enemy_row.add_child(e)
	_elegir_objetivo()
	_mostrar_ejercicio_actual()

func _elegir_objetivo() -> void:
	# Regla "solo fila del frente" (Nivel 3, ver notas de diseno Seccion 3).
	for hijo in enemy_row.get_children():
		if hijo is Enemy and hijo.distancia == Enemy.Distancia.FRENTE:
			enemigo_objetivo = hijo
			return
	enemigo_objetivo = null

func _mostrar_ejercicio_actual() -> void:
	if enemigo_objetivo == null:
		return
	TurnManager.iniciar_turno_jugador()
	var correcta_str := "%s: %s;" % [enemigo_objetivo.propiedad_requerida, enemigo_objetivo.valor_requerido]
	input_panel.mostrar_ejercicio({
		"propiedad": enemigo_objetivo.propiedad_requerida,
		"modo": "seleccion" if nivel_actual < 3 else "texto",
		"alternativas": [correcta_str, "opacity: 0.5;", "width: 50px;", "border-color: black;"],
	})

func _on_respuesta_enviada(propiedad: String, valor: String) -> void:
	if enemigo_objetivo == null:
		return
	var alternativas: Array = []
	var correcta := TurnManager.resolver_respuesta(enemigo_objetivo, propiedad, valor, id_jugador, alternativas)
	if correcta:
		player.actualizar_arma(propiedad, valor)
		enemigo_objetivo.recibir_impacto()
		player.puntaje += 10
	else:
		player.perder_vida()
	_actualizar_hud()
	_elegir_objetivo()
	if enemigo_objetivo == null:
		if enemy_row.get_child_count() == 0:
			_spawn_oleada()
		else:
			TurnManager.terminar_nivel()
	else:
		_mostrar_ejercicio_actual()

func _actualizar_hud() -> void:
	hud.text = "Vidas: %d   Puntaje: %d   Nivel %d" % [player.vidas, player.puntaje, nivel_actual]
