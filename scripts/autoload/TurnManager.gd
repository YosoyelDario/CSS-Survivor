extends Node
## Autoload: TurnManager
## Maquina de estados del ciclo de turno (ver notas de diseno, Seccion 3):
## AVANCE_ENEMIGOS -> TURNO_JUGADOR -> RESOLVIENDO -> (loop o FIN_NIVEL)

enum Estado { AVANCE_ENEMIGOS, TURNO_JUGADOR, RESOLVIENDO, FIN_NIVEL }

var estado: int = Estado.AVANCE_ENEMIGOS
var _tiempo_inicio_turno_ms: int = 0

signal estado_cambio(nuevo_estado)
signal turno_resuelto(fue_correcta)

func iniciar_avance() -> void:
	estado = Estado.AVANCE_ENEMIGOS
	estado_cambio.emit(estado)

func iniciar_turno_jugador() -> void:
	estado = Estado.TURNO_JUGADOR
	_tiempo_inicio_turno_ms = Time.get_ticks_msec()
	estado_cambio.emit(estado)

## Valida la respuesta, registra el log y devuelve si fue correcta.
func resolver_respuesta(enemy, propiedad: String, valor: String, id_jugador: String, alternativas: Array) -> bool:
	estado = Estado.RESOLVIENDO
	estado_cambio.emit(estado)
	var tiempo_seg := (Time.get_ticks_msec() - _tiempo_inicio_turno_ms) / 1000.0
	var correcta := Validator.es_correcta(enemy, propiedad, valor)
	LogManager.log_evento(
		id_jugador,
		enemy.propiedad_requerida,
		alternativas,
		"%s: %s;" % [propiedad, valor],
		correcta,
		tiempo_seg
	)
	turno_resuelto.emit(correcta)
	return correcta

func terminar_nivel() -> void:
	estado = Estado.FIN_NIVEL
	estado_cambio.emit(estado)
