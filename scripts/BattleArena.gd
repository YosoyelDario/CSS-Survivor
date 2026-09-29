extends Node2D
## Script raíz de la escena de Batalla. 
## Funciona como la vista del juego: dibuja los enemigos y el UI
## basándose en las decisiones lógicas de TurnManager y LevelRun.

const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")

@export var nivel_actual: int = 1
var partida: LevelRun 
var nodos_enemigos: Array = [] # Nodos instanciados, alineados al array lógico 'partida.enemigos'
var _tiempo_inicio_turno_ms: int = 0

@onready var player: Player = $Player
@onready var enemy_row: Node2D = $EnemyRow
@onready var hud: Label = $UI/HUD
@onready var input_panel: InputPanel = $UI/InputPanel

func _ready() -> void:
	# El InputPanel emitirá un índice (0 a 3) tras la Fase 4.
	input_panel.opcion_elegida.connect(_on_opcion_elegida)
	
	_iniciar_partida()

func _iniciar_partida() -> void:
	partida = LevelRun.new()
	
	# Fallback de seguridad: por si se ejecuta Nivel.tscn directamente desde el editor (F6)
	if SessionManager.jugador_actual.is_empty():
		push_warning("ADVERTENCIA: Ejecutando Nivel directamente sin pasar por Registro. Iniciando sesión de pruebas temporal.")
		SessionManager.iniciar_sesion("test@debug.com", "Tester", true)

	var exposicion = SessionManager.jugador_actual.get("contadores_ejercicios", {})
	var pool_ejercicios = _cargar_ejercicios_json(nivel_actual) 
	
	partida.iniciar(nivel_actual, pool_ejercicios, exposicion)
	
	TurnManager.estado_cambio.connect(_on_cambio_estado)
	TurnManager.cambiar_estado(TurnManager.Estado.PREPARANDO_OLEADA)
	_actualizar_hud()

func _cargar_ejercicios_json(nivel: int) -> Array:
	var path := "res://data/ejercicios_nivel%d.json" % nivel
	if not FileAccess.file_exists(path):
		push_warning("No existe banco de ejercicios en: %s" % path)
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) == TYPE_ARRAY:
		return data
	return []

# --- ORQUESTADOR (Máquina de Estados) ---
func _on_cambio_estado(nuevo_estado: int) -> void:
	match nuevo_estado:
		TurnManager.Estado.PREPARANDO_OLEADA:
			if partida.siguiente_oleada():
				_instanciar_enemigos_visuales()
				TurnManager.cambiar_estado(TurnManager.Estado.ELIGIENDO_OBJETIVO)
			else:
				TurnManager.cambiar_estado(TurnManager.Estado.FIN_NIVEL)
				
		TurnManager.Estado.ELIGIENDO_OBJETIVO:
			partida.elegir_objetivo()
			_sincronizar_enemigos_visuales() # Actualiza distancias y marca objetivo
			partida.asignar_pregunta_objetivo()
			TurnManager.cambiar_estado(TurnManager.Estado.ESPERANDO_RESPUESTA)
			
		TurnManager.Estado.ESPERANDO_RESPUESTA:
			input_panel.mostrar_ejercicio(partida.pregunta_actual)
			_tiempo_inicio_turno_ms = Time.get_ticks_msec()

		TurnManager.Estado.AVANZANDO:
			_sincronizar_enemigos_visuales()
			# Si quedan enemigos, elige el siguiente objetivo. Si no, fin de oleada.
			if partida.enemigos_vivos() > 0:
				TurnManager.cambiar_estado(TurnManager.Estado.ELIGIENDO_OBJETIVO)
			else:
				TurnManager.cambiar_estado(TurnManager.Estado.PREPARANDO_OLEADA)

		TurnManager.Estado.FIN_NIVEL:
			var resumen = partida.resumen()
			print("--- FIN DEL NIVEL ---")
			print("Puntos: ", resumen["puntaje"])
			print("Completado: ", resumen["completado"])
			# (Fase 7) Aquí se llamará a la pantalla de Resultados de Nivel.

# --- RESPUESTA DEL JUGADOR ---
func _on_opcion_elegida(indice: int) -> void:
	if TurnManager.estado != TurnManager.Estado.ESPERANDO_RESPUESTA: return
	
	TurnManager.cambiar_estado(TurnManager.Estado.RESOLVIENDO)
	
	var tiempo = (Time.get_ticks_msec() - _tiempo_inicio_turno_ms) / 1000.0
	var resultado = partida.responder(indice, tiempo)
	
	var ej = partida.pregunta_actual["ejercicio"]
	var opciones_mostradas = partida.pregunta_actual["opciones"]
	var respuesta_txt = opciones_mostradas[indice] if indice >= 0 else ""
	
	# Guardamos el Log (Bug #3 y #4 corregido y adaptado al Nivel 1)
	LogManager.log_evento(
		ej["enunciado"], 
		opciones_mostradas, 
		respuesta_txt, 
		resultado["correcta"], 
		tiempo,
		{"nivel": nivel_actual, "tipo": ej["tipo"], "vidas_restantes": partida.vidas}
	)
	
	SessionManager.guardar_perfil()
	_mostrar_feedback_visual(resultado)

func _mostrar_feedback_visual(resultado: Dictionary) -> void:
	TurnManager.cambiar_estado(TurnManager.Estado.MOSTRANDO_FEEDBACK)
	_actualizar_hud()
	
	# Mostrar notificaciones de insignias (Gamificación)
	if not partida.insignias_nuevas.is_empty():
		for id_insignia in partida.insignias_nuevas:
			var info_insignia = Config.INSIGNIAS_NIVEL_1.get(id_insignia, {})
			print("¡NUEVA INSIGNIA DESBLOQUEADA!: ", info_insignia.get("nombre", id_insignia))
		# Limpiar para no repetirlas en el siguiente turno
		partida.insignias_nuevas.clear() 
	
	var ej = partida.pregunta_actual["ejercicio"]
	
	if resultado["correcta"]:
		# El enemigo se marca como muerto instantáneamente en la lógica, visualmente lo escondemos/eliminamos
		if partida.objetivo_idx >= 0 and partida.objetivo_idx < nodos_enemigos.size():
			var obj = nodos_enemigos[partida.objetivo_idx]
			if is_instance_valid(obj):
				# Si hay efecto visual de acierto, lo aplicamos (Ej: tintarlo)
				if ej.has("efecto_visual"):
					CssEngine.aplicar_diccionario(obj, ej["efecto_visual"])
				# Pequeña pausa de celebración antes de borrarlo y avanzar
				await get_tree().create_timer(0.6).timeout
				obj.queue_free() 
		
		TurnManager.cambiar_estado(TurnManager.Estado.AVANZANDO)
	else:
		if resultado["game_over"]:
			TurnManager.cambiar_estado(TurnManager.Estado.FIN_NIVEL)
		else:
			# Si falló, mostrar pista
			print("INCORRECTO! Pista: ", ej.get("pista", ""))
			# (Fase 4) Esperar que el InputPanel (botón "Continuar") emita señal
			await get_tree().create_timer(1.5).timeout 
			partida.reponer_pregunta()
			TurnManager.cambiar_estado(TurnManager.Estado.ESPERANDO_RESPUESTA)

func _actualizar_hud() -> void:
	# Agregamos la Barra de Reparación como texto (placeholder)
	var porcentaje_rep = partida.reparacion()
	hud.text = "Vidas: %d | Puntaje: %d | Racha: %d | Reparación: %d%%\nNivel %d" % [
		partida.vidas, 
		partida.puntaje, 
		partida.racha, 
		int(porcentaje_rep),
		nivel_actual
	]

# --- VISUALES DE ENEMIGOS ---
func _instanciar_enemigos_visuales() -> void:
	# Limpiar enemigos de la oleada anterior
	for child in enemy_row.get_children():
		child.queue_free()
	nodos_enemigos.clear()
	
	# Instanciar basándose en la lista lógica
	for e_logico in partida.enemigos:
		var e_visual = ENEMY_SCENE.instantiate()
		enemy_row.add_child(e_visual)
		nodos_enemigos.append(e_visual)

func _sincronizar_enemigos_visuales() -> void:
	# Actualiza la posición Y y X según la distancia y carril lógico de LevelRun
	for i in range(partida.enemigos.size()):
		var e_logico = partida.enemigos[i]
		var e_visual = nodos_enemigos[i]
		if is_instance_valid(e_visual):
			if e_logico["vivo"]:
				e_visual.distancia = e_logico["distancia"]
				e_visual.carril = e_logico["carril"]
				# Posicionamiento: carril (0, 1, 2) centrado y Y por distancia
				e_visual.position = Vector2((e_logico["carril"] - 1) * 150, Enemy.Y_POR_DISTANCIA[e_logico["distancia"]])
				
				# Marcar objetivo (bug visual 8.2: flecha o contorno)
				if i == partida.objetivo_idx:
					e_visual.modulate = Color(1, 0.5, 0.5) # Ejemplo temporal para resaltar
				else:
					e_visual.modulate = Color(1, 1, 1)
			else:
				e_visual.hide()
