extends RefCounted
class_name LevelRun
## Reglas de UN intento de un nivel. No conoce nodos ni escenas: solo datos.
## BattleArena (la vista) le pide el estado y le informa las respuestas.
##
## Estructura: nivel -> oleadas -> enemigos -> turnos (un turno = una pregunta).
## Cada enemigo tiene un carril (columna) y una distancia (fila: LEJOS/MEDIO/FRENTE).
## Solo se ataca al enemigo de FRENTE mas a la izquierda.

const LEJOS := 0
const MEDIO := 1
const FRENTE := 2

var nivel: int = 1
var cfg: Dictionary = {}
var pool: Array = []
var exposicion: Dictionary = {}     # referencia al perfil: "id" -> {"vistos": n, "fallos": m}
var rng := RandomNumberGenerator.new()

var vidas_iniciales: int = 5
var vidas: int = 5
var puntaje: int = 0
var racha: int = 0
var racha_maxima: int = 0
var oleada_idx: int = -1            # 0-based; -1 = aun no empieza
var derrotados_en_oleada: int = 0   # indice dentro de la secuencia de tipos
var derrotados_total: int = 0
var total_enemigos: int = 0
var errores_oleada: int = 0
var errores_total: int = 0
var aciertos_total: int = 0
var tiempo_total: float = 0.0
var enemigos: Array = []            # [{"carril": int, "distancia": int, "vivo": bool}]
var objetivo_idx: int = -1
var pregunta_actual: Dictionary = {}
var usados: Array = []              # ids mostrados en este intento
var fallados: Array = []            # ids fallados en este intento
var historial: Array = []           # una entrada por pregunta respondida (para el KCR)
var insignias_nuevas: Array = []
var numero_intento: int = 1
var terminado: bool = false
var completado: bool = false

# ---------------------------------------------------------------- inicio

## Devuelve false si el banco esta vacio.
func iniciar(p_nivel: int, p_pool: Array, p_exposicion: Dictionary, semilla: int = -1) -> bool:
	nivel = p_nivel
	
	# Mapeamos los datos desde nuestro Autoload 'Config'
	cfg = {
		"vidas": Config.VIDAS_INICIALES,
		"oleadas": Config.OLEADAS_POR_NIVEL,
		"enemigos_por_oleada": Config.ENEMIGOS_POR_OLEADA,
		"carriles": Config.CARRILES,
		"puntos_por_tipo": Config.PUNTOS_POR_TIPO,
		"bono_racha": {"cada": Config.ACERTOS_PARA_RACHA, "puntos": Config.BONO_RACHA},
		"bono_oleada_sin_errores": Config.BONO_OLEADA_PERFECTA,
		"bono_por_vida_restante": Config.BONO_VIDA_RESTANTE,
		"dificultad_por_tipo": {"teorico": "facil", "completar": "facil", "practico": "media", "multi": "dificil"},
		"secuencias": Config.SECUENCIAS_OLEADA_NIVEL1 if nivel == 1 else []
	}
	
	pool = p_pool
	exposicion = p_exposicion
	if semilla >= 0:
		rng.seed = semilla
	else:
		rng.randomize()
		
	vidas_iniciales = int(cfg.get("vidas", 5))
	vidas = vidas_iniciales
	total_enemigos = n_oleadas() * enemigos_por_oleada()
	return not pool.is_empty()

func n_oleadas() -> int:
	return int(cfg.get("oleadas", 3))

func enemigos_por_oleada() -> int:
	return int(cfg.get("enemigos_por_oleada", 5))

func secuencia_oleada(idx: int) -> Array:
	var secuencias: Array = cfg.get("secuencias", [])
	if secuencias.is_empty():
		return ["teorico"]
	return secuencias[clampi(idx, 0, secuencias.size() - 1)]

func dificultad_de_tipo(tipo: String) -> String:
	var mapa: Dictionary = cfg.get("dificultad_por_tipo", {})
	return str(mapa.get(tipo, "facil"))

# ---------------------------------------------------------------- oleadas y enemigos

## Prepara la siguiente oleada. Devuelve false si ya no quedan.
func siguiente_oleada() -> bool:
	if oleada_idx + 1 >= n_oleadas():
		return false
	oleada_idx += 1
	derrotados_en_oleada = 0
	errores_oleada = 0
	objetivo_idx = -1
	pregunta_actual = {}
	enemigos.clear()
	var carriles := maxi(1, int(cfg.get("carriles", 3)))
	for i in enemigos_por_oleada():
		var fila := floori(float(i) / float(carriles))
		var dist := clampi(FRENTE - fila, LEJOS, FRENTE)
		enemigos.append({"carril": i % carriles, "distancia": dist, "vivo": true})
	return true

func enemigos_vivos() -> int:
	var n := 0
	for e in enemigos:
		if e["vivo"]:
			n += 1
	return n

## Elige al enemigo de FRENTE mas a la izquierda. Devuelve su indice o -1.
func elegir_objetivo() -> int:
	objetivo_idx = -1
	var mejor := 9999
	for i in enemigos.size():
		var e: Dictionary = enemigos[i]
		if e["vivo"] and e["distancia"] == FRENTE and e["carril"] < mejor:
			mejor = e["carril"]
			objetivo_idx = i
	return objetivo_idx

func _avanzar_carril(idx_muerto: int) -> void:
	var muerto: Dictionary = enemigos[idx_muerto]
	for e in enemigos:
		if e["vivo"] and e["carril"] == muerto["carril"] and e["distancia"] < muerto["distancia"]:
			e["distancia"] += 1

# ---------------------------------------------------------------- seleccion de ejercicios

## Tipo que corresponde al enemigo actual segun la secuencia de la oleada.
## El indice solo avanza cuando un enemigo muere (no con los errores).
func tipo_esperado() -> String:
	var seq := secuencia_oleada(oleada_idx)
	return str(seq[mini(derrotados_en_oleada, seq.size() - 1)])

## Sortea la pregunta del objetivo actual segun la secuencia de tipos.
func asignar_pregunta_objetivo() -> Dictionary:
	pregunta_actual = _sortear(tipo_esperado(), "", -1)
	return pregunta_actual

## Tras un error: nuevo ejercicio del MISMO tipo, prefiriendo la misma
## propiedad_principal y sin repetir el ejercicio fallado.
func reponer_pregunta() -> Dictionary:
	var previo: Dictionary = pregunta_actual.get("ejercicio", {})
	pregunta_actual = _sortear(tipo_esperado(), str(previo.get("propiedad_principal", "")), int(previo.get("id", -1)))
	return pregunta_actual

func _sortear(tipo: String, preferir_prop: String, excluir_id: int) -> Dictionary:
	var ej := _elegir_ejercicio(tipo, preferir_prop, excluir_id)
	if ej.is_empty():
		return {}
	return _presentar(ej)

func _elegir_ejercicio(tipo: String, preferir_prop: String, excluir_id: int) -> Dictionary:
	# 1) mismo tipo, aun no mostrado en este intento
	var c := _candidatos([tipo], true, excluir_id)
	if not c.is_empty():
		if preferir_prop != "":
			var mismos := c.filter(func(e): return str(e.get("propiedad_principal", "")) == preferir_prop)
			if not mismos.is_empty():
				c = mismos
		return _menos_vistos(c)
	# 2) tipos de dificultad mas cercana, aun no mostrados
	for t in _tipos_por_cercania(tipo):
		c = _candidatos([t], true, excluir_id)
		if not c.is_empty():
			push_warning("LevelRun: sin ejercicios '%s' disponibles; se usa '%s'" % [tipo, t])
			return _menos_vistos(c)
	# 3) repetir ejercicios fallados en este intento
	c = pool.filter(func(e): return fallados.has(int(e.get("id", -1))) and int(e.get("id", -1)) != excluir_id)
	if not c.is_empty():
		push_warning("LevelRun: pool agotado; se repite un ejercicio fallado")
		return _menos_vistos(c)
	# 4) ultimo recurso: cualquiera
	c = pool.filter(func(e): return int(e.get("id", -1)) != excluir_id)
	if c.is_empty():
		c = pool.duplicate()
	if c.is_empty():
		return {}
	push_warning("LevelRun: pool agotado; se repite un ejercicio")
	return _menos_vistos(c)

func _candidatos(tipos: Array, solo_no_usados: bool, excluir_id: int) -> Array:
	return pool.filter(func(e):
		# Usamos .get() para que no explote si el JSON es viejo
		if not tipos.has(str(e.get("tipo", ""))):
			return false
		var id := int(e.get("id", -1))
		if id == excluir_id:
			return false
		if solo_no_usados and usados.has(id):
			return false
		return true)

## Otros tipos ordenados por cercania de dificultad al tipo pedido.
func _tipos_por_cercania(tipo: String) -> Array:
	var orden := ["facil", "media", "dificil"]
	var base := orden.find(dificultad_de_tipo(tipo))
	var lista: Array = []
	var pos := 0
	
	# Usamos los 4 tipos definidos en el diseño
	var todos_los_tipos := ["teorico", "completar", "practico", "multi"]
	
	for t in todos_los_tipos:
		if t == tipo:
			continue
		var d := absi(orden.find(dificultad_de_tipo(t)) - base)
		lista.append([d, pos, t])
		pos += 1
	lista.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	return lista.map(func(x): return x[2])

## Entre los candidatos, elige al azar uno de los menos vistos por el jugador.
func _menos_vistos(cands: Array) -> Dictionary:
	var minimo := 1 << 30
	for e in cands:
		minimo = mini(minimo, _vistos(int(e.get("id", -1))))
	var mejores := cands.filter(func(e): return _vistos(int(e.get("id", -1))) == minimo)
	return mejores[rng.randi_range(0, mejores.size() - 1)]

## Lectura sin efectos secundarios (no crea contadores para ejercicios no mostrados).
func _vistos(id: int) -> int:
	var ex = exposicion.get(str(id), null)
	return int(ex.get("vistos", 0)) if ex is Dictionary else 0

func _exp(id: int) -> Dictionary:
	var k := str(id)
	if not exposicion.has(k):
		exposicion[k] = {"vistos": 0, "fallos": 0}
	return exposicion[k]

## Baraja las 4 opciones (Fisher-Yates con el rng del intento) y registra que se mostro.
func _presentar(ej: Dictionary) -> Dictionary:
	var originales: Array = ej.get("opciones", [])
	# Leemos directamente el texto de la respuesta correcta desde el JSON
	var correcta_txt: String = str(ej.get("correcta", "")) 
	
	var mezcla: Array = originales.duplicate()
	for i in range(mezcla.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = mezcla[i]
		mezcla[i] = mezcla[j]
		mezcla[j] = tmp
		
	var id := int(ej.get("id", -1))
	if not usados.has(id):
		usados.append(id)
	var ex := _exp(id)
	ex["vistos"] = int(ex.get("vistos", 0)) + 1
	
	return {"ejercicio": ej, "opciones": mezcla, "indice_correcto": mezcla.find(correcta_txt)}

# ---------------------------------------------------------------- respuesta

## Procesa la respuesta a la pregunta actual.
## Devuelve: correcta, puntos, bonos [{nombre, puntos}], game_over, oleada_completa,
## nivel_completo, indice_correcto.
func responder(indice: int, tiempo: float) -> Dictionary:
	var ej: Dictionary = pregunta_actual["ejercicio"]
	var opciones: Array = pregunta_actual["opciones"]
	var correcta: bool = (indice == int(pregunta_actual["indice_correcto"]))
	var id := int(ej["id"])
	var tipo := str(ej["tipo"])
	tiempo_total += tiempo

	var res := {
		"correcta": correcta, "puntos": 0, "bonos": [],
		"game_over": false, "oleada_completa": false, "nivel_completo": false,
		"indice_correcto": int(pregunta_actual["indice_correcto"]),
	}
	historial.append({
		"id": id, "tipo": tipo, "oleada": oleada_idx + 1,
		"enunciado": str(ej["enunciado"]), "codigo": str(ej.get("codigo", "")),
		"opciones": opciones.duplicate(),
		"elegida": str(opciones[indice]) if indice >= 0 and indice < opciones.size() else "",
		"correcta_texto": str(opciones[int(pregunta_actual["indice_correcto"])]),
		"acierto": correcta, "explicacion": str(ej["explicacion"]), "tiempo": tiempo,
	})

	if correcta:
		var puntos_tipo: Dictionary = cfg.get("puntos_por_tipo", {})
		res["puntos"] += int(puntos_tipo.get(tipo, 0))
		racha += 1
		racha_maxima = maxi(racha_maxima, racha)
		aciertos_total += 1
		
		# --- EVALUACIÓN DE INSIGNIAS (DURANTE LA PARTIDA) ---
		if SessionManager.otorgar_insignia("primer_bug"):
			insignias_nuevas.append("primer_bug")
			
		if racha >= 5 and SessionManager.otorgar_insignia("racha_imparable"):
			insignias_nuevas.append("racha_imparable")

		var br: Dictionary = cfg.get("bono_racha", {})
		var cada := int(br.get("cada", 0))
		if cada > 0 and racha % cada == 0:
			_bono(res, "Racha de %d" % racha, int(br.get("puntos", 0)))
			
		enemigos[objetivo_idx]["vivo"] = false
		_avanzar_carril(objetivo_idx)
		derrotados_en_oleada += 1
		derrotados_total += 1
		
		if enemigos_vivos() == 0:
			res["oleada_completa"] = true
			if errores_oleada == 0:
				_bono(res, "Oleada sin errores", int(cfg.get("bono_oleada_sin_errores", 0)))
				
			if oleada_idx + 1 >= n_oleadas():
				res["nivel_completo"] = true
				completado = true
				terminado = true
				
				# --- EVALUACIÓN DE INSIGNIAS (FIN DE NIVEL) ---
				if SessionManager.otorgar_insignia("maestro_color"):
					insignias_nuevas.append("maestro_color")
					
				if vidas == vidas_iniciales and SessionManager.otorgar_insignia("impecable"):
					insignias_nuevas.append("impecable")
					
				if vidas > 0:
					_bono(res, "Vidas restantes (%d)" % vidas, vidas * int(cfg.get("bono_por_vida_restante", 0)))
	else:
		vidas -= 1
		racha = 0
		errores_oleada += 1
		errores_total += 1
		if not fallados.has(id):
			fallados.append(id)
		var ex := _exp(id)
		ex["fallos"] = int(ex.get("fallos", 0)) + 1
		if vidas <= 0:
			vidas = 0
			res["game_over"] = true
			terminado = true
	puntaje += int(res["puntos"])
	return res

func _bono(res: Dictionary, nombre: String, puntos: int) -> void:
	if puntos <= 0:
		return
	res["bonos"].append({"nombre": nombre, "puntos": puntos})
	res["puntos"] += puntos

# ---------------------------------------------------------------- consultas

## Porcentaje 0-100 de enemigos derrotados sobre el total del nivel.
func reparacion() -> float:
	if total_enemigos <= 0:
		return 0.0
	return 100.0 * float(derrotados_total) / float(total_enemigos)

func resumen() -> Dictionary:
	return {
		"nivel": nivel, "completado": completado, "puntaje": puntaje,
		"vidas": vidas, "vidas_iniciales": vidas_iniciales,
		"errores": errores_total, "aciertos": aciertos_total,
		"tiempo_total": tiempo_total, "reparacion": reparacion(),
		"racha_maxima": racha_maxima, "historial": historial.duplicate(true),
		"insignias_nuevas": insignias_nuevas.duplicate(true),
		"numero_intento": numero_intento,
	}
