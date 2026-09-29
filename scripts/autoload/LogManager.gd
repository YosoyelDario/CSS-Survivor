extends Node
## Autoload: LogManager
## Escribe el log en user://logs/log.jsonl asegurando los 7 campos obligatorios.

const LOG_PATH := "user://logs/log.jsonl"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://logs")

# BUG CORREGIDO: Se asegura que se reciben las 'alternativas' mostradas y el 'correo' dinámico
func log_evento(pregunta: String, alternativas: Array, respuesta_jugador: String, fue_correcta: bool, tiempo_respuesta: float, datos_extra: Dictionary = {}) -> void:
	# Rescatar el ID del jugador desde la sesión actual
	var id_jugador := "desconocido"
	if SessionManager.jugador_actual.has("correo"):
		id_jugador = SessionManager.jugador_actual["correo"]
		
	var evento := {
		"timestamp": Time.get_datetime_string_from_system(),
		"idJugador": id_jugador,
		"pregunta": pregunta,
		"alternativas": alternativas,
		"respuestaJugador": respuesta_jugador,
		"siFueCorrectaoNo": fue_correcta,
		"tiempoDeRespuesta": tiempo_respuesta
	}
	
	# Añadir campos extra requeridos sin alterar los 7 principales
	for key in datos_extra:
		evento[key] = datos_extra[key]

	var f := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	else:
		f.seek_end()
	f.store_line(JSON.stringify(evento))
	f.close()