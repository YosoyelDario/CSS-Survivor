extends Node
## Autoload: Config
## Contiene todos los valores por defecto [DEFECTO] definidos por diseño.

const VIDAS_INICIALES: int = 5
const OLEADAS_POR_NIVEL: int = 3
const ENEMIGOS_POR_OLEADA: int = 5
const CARRILES: int = 3

const PUNTOS_POR_TIPO := {
	"teorico": 10,
	"completar": 15,
	"practico": 20,
	"multi": 30
}

const BONO_RACHA: int = 10
const ACERTOS_PARA_RACHA: int = 3
const BONO_OLEADA_PERFECTA: int = 25
const BONO_VIDA_RESTANTE: int = 20

const SECUENCIAS_OLEADA_NIVEL1 := [
	["teorico", "completar", "teorico", "practico", "teorico"], # Oleada 1 (Fácil)
	["practico", "teorico", "practico", "completar", "practico"], # Oleada 2 (Media)
	["multi", "practico", "multi", "completar", "multi"] # Oleada 3 (Difícil)
]

const INSIGNIAS_NIVEL_1 := {
	"primer_bug": {"nombre": "Primer bug eliminado", "desc": "Primera respuesta correcta."},
	"racha_imparable": {"nombre": "Racha imparable", "desc": "5 aciertos consecutivos."},
	"impecable": {"nombre": "Impecable", "desc": "Completar el nivel sin perder vidas."},
	"maestro_color": {"nombre": "Maestro del Color", "desc": "Dominaste color, transparencia y tipografía."}
}