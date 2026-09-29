extends Node
## Autoload: TurnManager
## Máquina de estados del turno de batalla. Solo guarda y anuncia el estado actual;
## las reglas viven en LevelRun y el orquestador es la escena Nivel.
##
## Ciclo: PREPARANDO_OLEADA -> ELIGIENDO_OBJETIVO -> ESPERANDO_RESPUESTA -> RESOLVIENDO
##        -> MOSTRANDO_FEEDBACK -> AVANZANDO -> (siguiente turno | FIN_OLEADA | FIN_NIVEL | GAME_OVER)

enum Estado {
	PREPARANDO_OLEADA,
	ELIGIENDO_OBJETIVO,
	ESPERANDO_RESPUESTA,
	RESOLVIENDO,
	MOSTRANDO_FEEDBACK,
	AVANZANDO,
	FIN_OLEADA,
	FIN_NIVEL,
	GAME_OVER,
}

signal estado_cambio(nuevo_estado: int)

var estado: int = Estado.PREPARANDO_OLEADA


func cambiar_estado(nuevo: int) -> void:
	estado = nuevo
	estado_cambio.emit(estado)


## Deja la máquina lista para un intento nuevo (sin emitir señal).
func reiniciar() -> void:
	estado = Estado.PREPARANDO_OLEADA
