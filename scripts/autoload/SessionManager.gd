extends Node
## Autoload: SessionManager
## Maneja el perfil persistente del jugador usando el correo como ID.

const RUTA_PERFILES := "user://perfiles/"
const NIVELES_TOTALES: int = 3

var jugador_actual: Dictionary = {}

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(RUTA_PERFILES)

func iniciar_sesion(correo: String, alias_jugador: String, consentimiento_aceptado: bool = false) -> bool:
	var correo_limpio = correo.strip_edges().to_lower()
	if correo_limpio == "": return false
	
	var ruta := RUTA_PERFILES + correo_limpio.md5_text() + ".json"
	
	if FileAccess.file_exists(ruta):
		var f := FileAccess.open(ruta, FileAccess.READ)
		jugador_actual = JSON.parse_string(f.get_as_text())
		f.close()
		# Actualizar última sesión
		jugador_actual["ultima_sesion"] = Time.get_datetime_string_from_system()
	else:
		# Crear nuevo perfil
		if not consentimiento_aceptado:
			return false # No puede continuar sin consentimiento
			
		jugador_actual = {
			"correo": correo_limpio,
			"alias": alias_jugador,
			"consentimiento_fecha": Time.get_datetime_string_from_system(),
			"fecha_creacion": Time.get_datetime_string_from_system(),
			"ultima_sesion": Time.get_datetime_string_from_system(),
			"puntos_totales": 0,
			"niveles": {
				"1": {"desbloqueado": true, "completado": false, "mejor_puntaje": 0, "intentos": 0}
			},
			"insignias": [],
			"contadores_ejercicios": {} # id_ejercicio: {vistos: 0, fallados: 0}
		}
	guardar_perfil()
	return true

func guardar_perfil() -> void:
	if jugador_actual.is_empty(): return
	var ruta := RUTA_PERFILES + str(jugador_actual["correo"]).md5_text() + ".json"
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string(JSON.stringify(jugador_actual))
	f.close()

func registrar_ejercicio_visto(id_ejercicio: int, fallado: bool = false) -> void:
	var id_str := str(id_ejercicio)
	
	# Asegurar que el diccionario existe (retrocompatibilidad)
	if not jugador_actual.has("contadores_ejercicios"):
		jugador_actual["contadores_ejercicios"] = {}
		
	if not jugador_actual["contadores_ejercicios"].has(id_str):
		jugador_actual["contadores_ejercicios"][id_str] = {"vistos": 0, "fallados": 0}
	
	jugador_actual["contadores_ejercicios"][id_str]["vistos"] += 1
	if fallado:
		jugador_actual["contadores_ejercicios"][id_str]["fallados"] += 1
	guardar_perfil()

# --- SISTEMA DE INSIGNIAS ---

func tiene_insignia(id_insignia: String) -> bool:
	if jugador_actual.is_empty() or not jugador_actual.has("insignias"):
		return false
	
	for ins in jugador_actual["insignias"]:
		if ins["id"] == id_insignia:
			return true
	return false

func otorgar_insignia(id_insignia: String) -> bool:
	if tiene_insignia(id_insignia):
		return false
		
	var nueva_insignia := {
		"id": id_insignia,
		"fecha": Time.get_datetime_string_from_system()
	}
	
	if not jugador_actual.has("insignias"):
		jugador_actual["insignias"] = []
		
	jugador_actual["insignias"].append(nueva_insignia)
	guardar_perfil()
	return true

# --- FUNCIONES DE ESTADO Y CONSULTA ---

func cerrar_sesion() -> void:
	jugador_actual.clear()

func existe_perfil(correo_check: String) -> bool:
	var correo_limpio = correo_check.strip_edges().to_lower()
	var ruta := RUTA_PERFILES + correo_limpio.md5_text() + ".json"
	return FileAccess.file_exists(ruta)

func hay_sesion() -> bool:
	return not jugador_actual.is_empty()

func alias() -> String:
	return str(jugador_actual.get("alias", "Desconocido"))

func puntos_totales() -> int:
	return int(jugador_actual.get("puntos_totales", 0))

func nivel_actual() -> int:
	# Busca el nivel más alto desbloqueado. Por ahora, forzamos 1.
	var nivel_max = 1
	var niveles_data = jugador_actual.get("niveles", {})
	for num_nivel in niveles_data.keys():
		if niveles_data[num_nivel].get("desbloqueado", false):
			var n = num_nivel.to_int()
			if n > nivel_max:
				nivel_max = n
	return nivel_max

func progreso_general() -> float:
	var completados := 0
	var niveles_data = jugador_actual.get("niveles", {})
	for num_nivel in niveles_data.keys():
		if niveles_data[num_nivel].get("completado", false):
			completados += 1
	return float(completados) / float(NIVELES_TOTALES)
