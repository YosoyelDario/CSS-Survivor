extends Control
## Ranking local: perfiles guardados en este equipo, ordenados por puntaje total
## (suma de los mejores puntajes por nivel). Desempate: menos errores, luego menor tiempo.
## Muestra solo el alias, nunca el correo.

const MAXIMO_FILAS := 10
const SIN_MARCA_ERRORES := 1000000
const SIN_MARCA_TIEMPO := 1.0e12
const COLOR_JUGADOR := Color(1.0, 0.85, 0.3)

@onready var boton_volver: Button = %BotonVolver
@onready var tabla: GridContainer = %Tabla
@onready var posicion: Label = %Posicion


func _ready() -> void:
	if not SessionManager.hay_sesion():
		Navegacion.ir_a("registro")
		return

	boton_volver.pressed.connect(func() -> void: Navegacion.ir_a("menu"))
	_construir_tabla()


func _construir_tabla() -> void:
	var filas: Array = []
	for perfil in SessionManager.listar_perfiles():
		filas.append(_resumir(perfil))
	filas.sort_custom(_es_mejor)

	# Encabezado
	tabla.add_child(_celda("#"))
	tabla.add_child(_celda("Jugador", false, true))
	tabla.add_child(_celda("Puntos"))
	tabla.add_child(_celda("Insignias"))

	var correo_actual := SessionManager.correo()
	var mi_posicion := -1
	for i in filas.size():
		var f: Dictionary = filas[i]
		var soy_yo: bool = f["correo"] == correo_actual
		if soy_yo:
			mi_posicion = i + 1
		if i < MAXIMO_FILAS:
			_agregar_fila(i + 1, f, soy_yo)
		elif soy_yo:
			# Fuera del Top 10: se muestra igual con su posición real.
			for k in 4:
				tabla.add_child(_celda("..."))
			_agregar_fila(i + 1, f, true)

	posicion.text = "Tu posición: #%d de %d" % [mi_posicion, filas.size()] if mi_posicion > 0 else ""


func _agregar_fila(pos: int, f: Dictionary, soy_yo: bool) -> void:
	var alias: String = str(f["alias"]) + (" (tú)" if soy_yo else "")
	tabla.add_child(_celda(str(pos), soy_yo))
	tabla.add_child(_celda(alias, soy_yo, true))
	tabla.add_child(_celda(str(f["puntos"]), soy_yo))
	tabla.add_child(_celda(str(f["insignias"]), soy_yo))


func _celda(texto: String, resaltar: bool = false, expandir: bool = false) -> Label:
	var l := Label.new()
	l.text = texto
	if expandir:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if resaltar:
		l.add_theme_color_override("font_color", COLOR_JUGADOR)
	return l


## Datos del perfil que importan para ordenar y mostrar (el correo solo sirve para reconocer al jugador actual).
func _resumir(perfil: Dictionary) -> Dictionary:
	var puntos := 0
	var errores := 0
	var tiempo := 0.0
	var con_marca := false
	var niveles: Dictionary = perfil.get("niveles", {})
	for n in niveles.keys():
		var d: Dictionary = niveles[n]
		puntos += int(d.get("mejor_puntaje", 0))
		if int(d.get("menos_errores", -1)) >= 0:
			errores += int(d["menos_errores"])
			tiempo += float(d.get("mejor_tiempo", 0.0))
			con_marca = true
	return {
		"correo": str(perfil.get("correo", "")),
		"alias": str(perfil.get("alias", "?")),
		"puntos": puntos,
		"errores": errores if con_marca else SIN_MARCA_ERRORES,
		"tiempo": tiempo if con_marca else SIN_MARCA_TIEMPO,
		"insignias": (perfil.get("insignias", []) as Array).size(),
	}


func _es_mejor(a: Dictionary, b: Dictionary) -> bool:
	if a["puntos"] != b["puntos"]:
		return a["puntos"] > b["puntos"]
	if a["errores"] != b["errores"]:
		return a["errores"] < b["errores"]
	return a["tiempo"] < b["tiempo"]
