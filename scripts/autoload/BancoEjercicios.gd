extends Node
## Autoload: BancoEjercicios
## Carga el banco de ejercicios de un nivel desde res://data/ejercicios_nivelN.json
## y lo valida. Los ejercicios con errores NO entran al pool (se avisa por consola).
##
## Uso:
##   var pool: Array = BancoEjercicios.cargar(1)
##
## Este servicio no conoce nodos ni escenas: solo datos.

const RUTA_BANCO := "res://data/ejercicios_nivel%d.json"

const TIPOS_VALIDOS: Array[String] = ["teorico", "practico", "completar", "multi"]

## Dificultad derivada del tipo (ver tabla de valores por defecto del diseño).
const DIFICULTAD_POR_TIPO := {
	"teorico": "facil",
	"completar": "facil",
	"practico": "media",
	"multi": "dificil",
}

const CAMPOS_OBLIGATORIOS: Array[String] = [
	"id", "nivel", "tipo", "dificultad", "propiedad_principal",
	"enunciado", "opciones", "correcta", "pista", "explicacion", "efecto_visual",
]

const OPCIONES_POR_PREGUNTA := 4
const MINIMO_POOL := 15  # ejercicios que se juegan por intento

var _cache: Dictionary = {}  # nivel (int) -> Array de ejercicios válidos


func _ready() -> void:
	# Valida el Nivel 1 al iniciar el juego para ver los problemas en consola cuanto antes.
	cargar(1)


## Devuelve el pool validado del nivel. Array vacío si el archivo no existe o no se puede leer.
## Cada llamada devuelve el mismo Array cacheado; usa forzar = true para releer del disco.
func cargar(nivel: int, forzar: bool = false) -> Array:
	if not forzar and _cache.has(nivel):
		return _cache[nivel]

	var ruta: String = RUTA_BANCO % nivel
	if not FileAccess.file_exists(ruta):
		push_error("BancoEjercicios: no existe el banco del nivel %d (%s)" % [nivel, ruta])
		return []

	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		push_error("BancoEjercicios: no se pudo abrir %s" % ruta)
		return []
	var texto: String = archivo.get_as_text()
	archivo.close()

	var datos: Variant = JSON.parse_string(texto)
	if not (datos is Array):
		push_error("BancoEjercicios: %s no contiene una lista de ejercicios (revisa el JSON)" % ruta)
		return []

	var validos: Array = []
	var ids_vistos: Dictionary = {}
	var descartados := 0

	for i in datos.size():
		var e: Variant = datos[i]
		var errores := _validar(e, nivel)

		# id duplicado (solo se puede comprobar si el ejercicio tiene id)
		if errores.is_empty():
			var id := int(e["id"])
			if ids_vistos.has(id):
				errores.append("id %d repetido" % id)
			else:
				ids_vistos[id] = true

		if errores.is_empty():
			validos.append(_normalizar(e))
		else:
			descartados += 1
			var etiqueta := "posición %d" % i
			if e is Dictionary and e.has("id"):
				etiqueta = "id %s" % str(e["id"])
			push_error("BancoEjercicios [nivel %d, %s] descartado: %s" % [nivel, etiqueta, "; ".join(errores)])

	_resumir(nivel, validos, descartados)
	_cache[nivel] = validos
	return validos


## Devuelve un ejercicio por id (diccionario vacío si no existe en el nivel).
func obtener(nivel: int, id: int) -> Dictionary:
	for e in cargar(nivel):
		if int(e["id"]) == id:
			return e
	return {}


# ---------------------------------------------------------------- validación

## Devuelve la lista de problemas del ejercicio (vacía = válido).
func _validar(e: Variant, nivel: int) -> Array[String]:
	var errores: Array[String] = []

	if not (e is Dictionary):
		errores.append("no es un objeto")
		return errores

	for campo in CAMPOS_OBLIGATORIOS:
		if not e.has(campo):
			errores.append("falta el campo '%s'" % campo)
	if not errores.is_empty():
		return errores

	# nivel
	if int(e["nivel"]) != nivel:
		errores.append("nivel %s en un banco del nivel %d" % [str(e["nivel"]), nivel])

	# tipo y dificultad
	var tipo := str(e["tipo"])
	if not TIPOS_VALIDOS.has(tipo):
		errores.append("tipo desconocido '%s'" % tipo)
	elif str(e["dificultad"]) != DIFICULTAD_POR_TIPO[tipo]:
		errores.append("dificultad '%s' no corresponde al tipo '%s' (debería ser '%s')" % [
			str(e["dificultad"]), tipo, DIFICULTAD_POR_TIPO[tipo]])

	# textos que no pueden venir vacíos
	for campo in ["propiedad_principal", "enunciado", "pista", "explicacion"]:
		if str(e[campo]).strip_edges() == "":
			errores.append("'%s' está vacío" % campo)

	# opciones: exactamente 4, textos únicos, una sola correcta
	var opciones: Variant = e["opciones"]
	if not (opciones is Array):
		errores.append("'opciones' debe ser una lista")
	else:
		if opciones.size() != OPCIONES_POR_PREGUNTA:
			errores.append("tiene %d opciones (deben ser %d)" % [opciones.size(), OPCIONES_POR_PREGUNTA])
		var normalizadas: Array[String] = []
		for o in opciones:
			normalizadas.append(str(o).strip_edges())
		var unicas: Dictionary = {}
		for o in normalizadas:
			if o == "":
				errores.append("hay una opción vacía")
			unicas[o] = true
		if unicas.size() != normalizadas.size():
			errores.append("hay opciones repetidas")
		var coincidencias := normalizadas.count(str(e["correcta"]).strip_edges())
		if coincidencias != 1:
			errores.append("'correcta' debe coincidir con exactamente 1 opción (coincide con %d)" % coincidencias)

	# efecto visual
	var efecto: Variant = e["efecto_visual"]
	if not (efecto is Dictionary):
		errores.append("'efecto_visual' debe ser un objeto")
	else:
		if tipo == "teorico" and not efecto.is_empty():
			errores.append("un teórico no debe tener efecto_visual")
		if (tipo == "practico" or tipo == "completar") and efecto.is_empty():
			errores.append("falta efecto_visual")
		if tipo == "multi" and efecto.size() < 2:
			errores.append("un multi necesita al menos 2 propiedades en efecto_visual")
		for propiedad in efecto.keys():
			if not CssEngine.aplicadores.has(str(propiedad)):
				errores.append("efecto_visual usa '%s', que CssEngine no soporta" % str(propiedad))

	return errores


# ---------------------------------------------------------------- utilidades

## Deja los tipos de dato listos para el resto del juego (el JSON entrega números como float).
func _normalizar(e: Dictionary) -> Dictionary:
	var copia: Dictionary = e.duplicate(true)
	copia["id"] = int(copia["id"])
	copia["nivel"] = int(copia["nivel"])
	copia["usable_en_test"] = bool(copia.get("usable_en_test", false))
	return copia


func _resumir(nivel: int, validos: Array, descartados: int) -> void:
	var por_tipo: Dictionary = {}
	for e in validos:
		var t := str(e["tipo"])
		por_tipo[t] = int(por_tipo.get(t, 0)) + 1

	var partes: Array[String] = []
	for t in TIPOS_VALIDOS:
		partes.append("%s %d" % [t, int(por_tipo.get(t, 0))])
	print("BancoEjercicios: nivel %d -> %d ejercicios válidos (%s), %d descartados" % [
		nivel, validos.size(), ", ".join(partes), descartados])

	if validos.size() < MINIMO_POOL:
		push_warning("BancoEjercicios: el nivel %d tiene menos de %d ejercicios; no alcanza para un intento" % [nivel, MINIMO_POOL])
	for t in TIPOS_VALIDOS:
		if int(por_tipo.get(t, 0)) == 0:
			push_warning("BancoEjercicios: el nivel %d no tiene ejercicios de tipo '%s'" % [nivel, t])
