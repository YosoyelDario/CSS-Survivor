extends Control
## Menú principal.
## Muestra alias, nivel y puntos del jugador (nunca el correo), el progreso general del sitio
## y navega al resto de pantallas mediante Navegacion.
##
## Botones deshabilitados con "Próximamente": Colección, Ajustes, Idioma, Sonido y Música.

@onready var etiqueta_alias: Label = %Alias
@onready var etiqueta_nivel: Label = %Nivel
@onready var etiqueta_puntos: Label = %Puntos
@onready var barra_progreso: ProgressBar = %BarraProgreso
@onready var texto_progreso: Label = %TextoProgreso
@onready var mensaje: Label = %Mensaje

@onready var boton_jugar: Button = %BotonJugar
@onready var boton_niveles: Button = %BotonNiveles
@onready var boton_logros: Button = %BotonLogros
@onready var boton_como_jugar: Button = %BotonComoJugar
@onready var boton_ranking: Button = %BotonRanking
@onready var boton_cambiar_jugador: Button = %BotonCambiarJugador
@onready var boton_salir: Button = %BotonSalir


func _ready() -> void:
	# Sin sesión no hay menú: se vuelve al Registro.
	if not SessionManager.hay_sesion():
		Navegacion.ir_a("registro")
		return

	boton_jugar.pressed.connect(_on_jugar)
	boton_niveles.pressed.connect(_ir.bind("niveles"))
	boton_logros.pressed.connect(_ir.bind("logros"))
	boton_como_jugar.pressed.connect(_ir.bind("como_jugar"))
	boton_ranking.pressed.connect(_ir.bind("ranking"))
	boton_cambiar_jugador.pressed.connect(_ir.bind("registro"))
	boton_salir.pressed.connect(Navegacion.salir)

	_refrescar()
	boton_jugar.grab_focus()


## Vuelve a leer el perfil y actualiza cabecera y progreso.
func _refrescar() -> void:
	etiqueta_alias.text = SessionManager.alias()
	etiqueta_nivel.text = "NV. %d" % SessionManager.nivel_actual()
	etiqueta_puntos.text = "%s PTS" % _formatear_miles(SessionManager.puntos_totales())

	var progreso := SessionManager.progreso_general()
	var completados := roundi(progreso * SessionManager.NIVELES_TOTALES)
	barra_progreso.value = progreso * 100.0
	texto_progreso.text = "%d de %d niveles completados" % [completados, SessionManager.NIVELES_TOTALES]


func _on_jugar() -> void:
	# Por ahora siempre lanza el Nivel 1 (más adelante: el último nivel desbloqueado).
	_ir("nivel", {"nivel": 1})


func _ir(destino: String, parametros: Dictionary = {}) -> void:
	if not Navegacion.ir_a(destino, parametros):
		_mostrar_mensaje("Esa pantalla aún está en construcción.")


func _mostrar_mensaje(texto: String) -> void:
	mensaje.text = texto
	mensaje.visible = texto != ""


## 1250 -> "1,250"
func _formatear_miles(valor: int) -> String:
	var texto := str(absi(valor))
	var resultado := ""
	var contador := 0
	for i in range(texto.length() - 1, -1, -1):
		resultado = texto[i] + resultado
		contador += 1
		if contador % 3 == 0 and i > 0:
			resultado = "," + resultado
	return ("-" if valor < 0 else "") + resultado
