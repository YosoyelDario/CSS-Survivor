extends Control
## Pantalla de Registro / inicio de sesión por correo.
##
## Flujo:
##  1. El jugador escribe su correo y pulsa "Continuar".
##  2. Correo mal formado -> mensaje de error.
##  3. Correo con perfil -> entra directo al menú.
##  4. Correo nuevo -> aparecen alias y consentimiento; al aceptar se crea el perfil y entra.

const ALIAS_MIN := 2
const ALIAS_MAX := 20

## Texto PROVISIONAL: el equipo debe reemplazarlo por el consentimiento informado oficial.
const TEXTO_CONSENTIMIENTO := "Participo voluntariamente en esta actividad educativa. Entiendo que el juego registrará mis respuestas y mi correo con fines de investigación educativa, y que mi correo no se mostrará a otros jugadores."

@onready var campo_correo: LineEdit = %CampoCorreo
@onready var seccion_nuevo: VBoxContainer = %SeccionNuevo
@onready var campo_alias: LineEdit = %CampoAlias
@onready var texto_consentimiento: Label = %TextoConsentimiento
@onready var casilla_consentimiento: CheckBox = %CasillaConsentimiento
@onready var mensaje: Label = %Mensaje
@onready var boton_continuar: Button = %BotonContinuar

var _regex_correo := RegEx.create_from_string("^[^\\s@]+@[^\\s@]+\\.[^\\s@]{2,}$")
var _es_nuevo := false


func _ready() -> void:
	# Al llegar aquí (inicio del juego o "Cambiar jugador") no debe quedar nadie con sesión.
	SessionManager.cerrar_sesion()

	texto_consentimiento.text = TEXTO_CONSENTIMIENTO
	campo_alias.max_length = ALIAS_MAX
	_mostrar_seccion_nuevo(false)
	_mensaje("")

	boton_continuar.pressed.connect(_on_continuar)
	campo_correo.text_changed.connect(_on_correo_cambiado)
	campo_correo.text_submitted.connect(func(_t: String) -> void: _on_continuar())
	campo_alias.text_submitted.connect(func(_t: String) -> void: _on_continuar())
	campo_correo.grab_focus()


func _on_correo_cambiado(_texto: String) -> void:
	# Si el jugador corrige el correo, se vuelve al paso 1.
	if _es_nuevo:
		_mostrar_seccion_nuevo(false)
	_mensaje("")


func _on_continuar() -> void:
	var correo := campo_correo.text.strip_edges().to_lower()

	if not _correo_valido(correo):
		_mensaje("Escribe un correo válido, por ejemplo nombre@dominio.com")
		return

	# Paso 1: ¿tiene perfil?
	if not _es_nuevo:
		if SessionManager.existe_perfil(correo):
			_entrar(correo, "", false)
		else:
			_mostrar_seccion_nuevo(true)
			_mensaje("No encontramos un perfil con este correo. Elige un alias para crearlo.")
			campo_alias.grab_focus()
		return

	# Paso 2: perfil nuevo
	var alias := campo_alias.text.strip_edges()
	if alias.length() < ALIAS_MIN or alias.length() > ALIAS_MAX:
		_mensaje("El alias debe tener entre %d y %d caracteres." % [ALIAS_MIN, ALIAS_MAX])
		return
	if not casilla_consentimiento.button_pressed:
		_mensaje("Debes aceptar el consentimiento para continuar.")
		return
	_entrar(correo, alias, true)


func _entrar(correo: String, alias: String, consentimiento: bool) -> void:
	if not SessionManager.iniciar_sesion(correo, alias, consentimiento):
		_mensaje("No se pudo iniciar sesión. Revisa los datos e inténtalo de nuevo.")
		return
	if not Navegacion.ir_a("menu"):
		# El menú aún no existe (se construye en el siguiente paso).
		_mensaje("Sesión iniciada como %s. El menú principal aún no está disponible." % SessionManager.alias())


func _correo_valido(correo: String) -> bool:
	return _regex_correo.search(correo) != null


func _mostrar_seccion_nuevo(visible_: bool) -> void:
	_es_nuevo = visible_
	seccion_nuevo.visible = visible_
	boton_continuar.text = "Crear perfil" if visible_ else "Continuar"


func _mensaje(texto: String) -> void:
	mensaje.text = texto
	mensaje.visible = texto != ""
