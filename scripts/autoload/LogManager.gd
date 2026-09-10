extends Node
## Autoload: LogManager
## Escribe un evento por turno (timestamp, idJugador, pregunta, alternativas,
## respuestaJugador, siFueCorrectaoNo, tiempoDeRespuesta) en user://logs/log.jsonl
## Campos definidos por el enunciado del curso (Etapa 3.3).

const LOG_PATH := "user://logs/log.jsonl"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://logs")

func log_evento(id_jugador: String, pregunta: String, alternativas: Array,
		respuesta_jugador: String, fue_correcta: bool, tiempo_respuesta: float) -> void:
	var evento := {
		"timestamp": Time.get_datetime_string_from_system(),
		"idJugador": id_jugador,
		"pregunta": pregunta,
		"alternativas": alternativas,
		"respuestaJugador": respuesta_jugador,
		"siFueCorrectaoNo": fue_correcta,
		"tiempoDeRespuesta": tiempo_respuesta,
	}
	var f := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	else:
		f.seek_end()
	f.store_line(JSON.stringify(evento))
	f.close()

## Util para la etapa de Prueba con Usuarios: vuelca el log completo como Array.
func leer_log_completo() -> Array:
	var resultado := []
	if not FileAccess.file_exists(LOG_PATH):
		return resultado
	var f := FileAccess.open(LOG_PATH, FileAccess.READ)
	while not f.eof_reached():
		var linea := f.get_line()
		if linea.strip_edges() != "":
			resultado.append(JSON.parse_string(linea))
	f.close()
	return resultado
