extends PanelContainer
class_name PanelPregunta
## Panel de pregunta + feedback. Es solo vista: recibe la pregunta que sortea LevelRun
## ({"ejercicio", "opciones", "indice_correcto"}) y emite lo que el jugador elige.
## Nunca muestra cuál es la respuesta correcta ni la pista antes de fallar.
##
## Presentación por tipo (siempre 4 alternativas, sin texto libre):
##   teorico   -> enunciado + 4 alternativas; al pulsar una se responde.
##   practico  -> enunciado (defecto del enemigo) + 4 declaraciones; al pulsar se responde.
##   multi     -> enunciado + 4 combos completos; al pulsar se responde.
##   completar -> enunciado + fragmento de código con espacio en blanco + 4 propiedades.
##                Pulsar una rellena el espacio; "VERIFICAR CÓDIGO" confirma la respuesta.
##
## Flujo desde la arena:
##   panel.mostrar_pregunta(partida.pregunta_actual)      # oculta el feedback anterior
##   panel.opcion_elegida  -> arena resuelve
##   panel.mostrar_feedback(correcta, pista)              # pista y Continuar solo si falló
##   panel.continuar_pulsado -> arena repone la pregunta

signal opcion_elegida(indice: int)
signal continuar_pulsado

const LETRAS: Array[String] = ["A", "B", "C", "D"]
const NOMBRES_TIPO := {
	"teorico": "Teórico",
	"practico": "Práctico",
	"completar": "Completar código",
	"multi": "Multi-objetivo",
}
const HUECO := "____"
const COLOR_ACIERTO := Color(0.6, 1.0, 0.6)
const COLOR_ERROR := Color(1.0, 0.6, 0.6)

@onready var etiqueta_tipo: Label = %EtiquetaTipo
@onready var texto_pausa: Label = %TextoPausa
@onready var cuerpo: VBoxContainer = %CuerpoPregunta
@onready var enunciado: Label = %Enunciado
@onready var bloque_codigo: PanelContainer = %BloqueCodigo
@onready var codigo: Label = %Codigo
@onready var opciones_grid: GridContainer = %Opciones
@onready var boton_verificar: Button = %BotonVerificar
@onready var panel_feedback: VBoxContainer = %PanelFeedback
@onready var resultado: Label = %Resultado
@onready var pista: Label = %Pista
@onready var boton_continuar: Button = %BotonContinuar

var _botones: Array[Button] = []
var _opciones: Array = []
var _es_completar := false
var _codigo_base := ""
var _seleccion := -1   # opción marcada (solo en "completar", antes de verificar)
var _elegida := -1     # opción ya enviada
var _bloqueado := false


func _ready() -> void:
	boton_verificar.pressed.connect(_on_verificar)
	boton_continuar.pressed.connect(func() -> void: continuar_pulsado.emit())
	panel_feedback.visible = false
	pista.text = ""


# ---------------------------------------------------------------- API pública

## Muestra una pregunta nueva (y borra cualquier feedback anterior).
func mostrar_pregunta(pregunta: Dictionary) -> void:
	_limpiar_opciones()
	ocultar_feedback()

	var ej: Dictionary = pregunta.get("ejercicio", {})
	_opciones = pregunta.get("opciones", [])
	var tipo := str(ej.get("tipo", "teorico"))
	_es_completar = tipo == "completar"
	_seleccion = -1
	_elegida = -1
	_bloqueado = false

	etiqueta_tipo.text = "%s  |  Selección múltiple" % NOMBRES_TIPO.get(tipo, tipo)

	var texto := str(ej.get("enunciado", ""))
	_codigo_base = str(ej.get("codigo", ""))
	if _es_completar and _codigo_base == "" and texto.contains("\n"):
		# El banco guarda el código después del primer salto de línea del enunciado.
		var corte := texto.find("\n")
		_codigo_base = texto.substr(corte + 1).strip_edges()
		texto = texto.substr(0, corte).strip_edges()
	enunciado.text = texto

	bloque_codigo.visible = _es_completar and _codigo_base != ""
	_actualizar_codigo()
	boton_verificar.visible = _es_completar
	boton_verificar.disabled = true

	var grupo: ButtonGroup = ButtonGroup.new() if _es_completar else null
	for i in _opciones.size():
		var b := Button.new()
		b.text = "%s. %s" % [LETRAS[i] if i < LETRAS.size() else str(i + 1), str(_opciones[i])]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(220, 56)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if _es_completar:
			b.toggle_mode = true
			b.button_group = grupo
		b.pressed.connect(_on_opcion_pulsada.bind(i))
		opciones_grid.add_child(b)
		_botones.append(b)


## Resultado del turno. La pista y el botón Continuar solo aparecen si el jugador falló.
## No revela cuál era la opción correcta.
func mostrar_feedback(correcta: bool, texto_pista: String = "") -> void:
	_bloquear(true)
	if _elegida >= 0 and _elegida < _botones.size():
		_botones[_elegida].modulate = COLOR_ACIERTO if correcta else COLOR_ERROR

	panel_feedback.visible = true
	resultado.text = "¡Correcto!" if correcta else "Incorrecto"
	pista.visible = not correcta and texto_pista.strip_edges() != ""
	pista.text = "Pista: %s" % texto_pista if pista.visible else ""
	boton_continuar.visible = not correcta
	if not correcta:
		boton_continuar.grab_focus()


func ocultar_feedback() -> void:
	panel_feedback.visible = false
	resultado.text = ""
	pista.text = ""
	pista.visible = false


## Pausa: tapa la pregunta (para que no se pueda pensar con el reloj detenido).
func set_pausado(pausado: bool) -> void:
	cuerpo.visible = not pausado
	texto_pausa.visible = pausado


## Vacía el panel (por ejemplo, entre oleadas o al terminar el nivel).
func limpiar() -> void:
	_limpiar_opciones()
	ocultar_feedback()
	etiqueta_tipo.text = ""
	enunciado.text = ""
	bloque_codigo.visible = false
	boton_verificar.visible = false


# ---------------------------------------------------------------- internos

func _on_opcion_pulsada(indice: int) -> void:
	if _bloqueado:
		return
	if _es_completar:
		# Solo marca; la respuesta se envía con "VERIFICAR CÓDIGO".
		_seleccion = indice
		_actualizar_codigo()
		boton_verificar.disabled = false
	else:
		_enviar(indice)


func _on_verificar() -> void:
	if _bloqueado or _seleccion < 0:
		return
	_enviar(_seleccion)


func _enviar(indice: int) -> void:
	_elegida = indice
	_bloquear(true)
	opcion_elegida.emit(indice)


func _bloquear(valor: bool) -> void:
	_bloqueado = valor
	for b in _botones:
		b.disabled = valor
	boton_verificar.disabled = valor or _seleccion < 0


## Muestra el código con el hueco, o con la propiedad elegida ya escrita.
func _actualizar_codigo() -> void:
	var texto := _codigo_base
	if _seleccion >= 0 and _seleccion < _opciones.size():
		texto = texto.replace(HUECO, str(_opciones[_seleccion]))
	codigo.text = texto


func _limpiar_opciones() -> void:
	for b in _botones:
		if is_instance_valid(b):
			opciones_grid.remove_child(b)
			b.queue_free()
	_botones.clear()
