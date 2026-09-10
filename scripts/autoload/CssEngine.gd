extends Node
## Autoload: CssEngine
## Traduce una propiedad/valor CSS a un efecto visual sobre un nodo Enemy.
## Referencia de qué capa controla cada propiedad: ver Guia_Visual_Propiedades_CSS.md

var aplicadores := {
	"color": Callable(self, "_aplicar_color"),
	"background-color": Callable(self, "_aplicar_background_color"),
	"border-color": Callable(self, "_aplicar_border_color"),
	"opacity": Callable(self, "_aplicar_opacidad"),
	"font-size": Callable(self, "_aplicar_font_size"),
	"width": Callable(self, "_aplicar_width"),
	"height": Callable(self, "_aplicar_height"),
	"border-radius": Callable(self, "_aplicar_border_radius"),
	"transform": Callable(self, "_aplicar_transform"),
}

func aplicar(objetivo: Node, propiedad: String, valor: String) -> bool:
	if not aplicadores.has(propiedad):
		push_warning("CssEngine: propiedad sin aplicador todavia -> %s" % propiedad)
		return false
	aplicadores[propiedad].call(objetivo, valor)
	return true

func _aplicar_color(objetivo: Node, valor: String) -> void:
	# Capa: cuerpo/relleno del enemigo
	if objetivo.has_node("Cuerpo"):
		objetivo.get_node("Cuerpo").color = Color(valor)

func _aplicar_background_color(objetivo: Node, valor: String) -> void:
	# Capa: aura / armadura. TODO: agregar nodo "Aura" en Enemy.tscn cuando exista el arte.
	if objetivo.has_node("Aura"):
		objetivo.get_node("Aura").color = Color(valor)

func _aplicar_border_color(objetivo: Node, valor: String) -> void:
	# Capa: contorno. TODO: agregar nodo "Contorno" cuando exista el arte.
	if objetivo.has_node("Contorno"):
		objetivo.get_node("Contorno").color = Color(valor)

func _aplicar_opacidad(objetivo: Node, valor: String) -> void:
	var v := valor.replace("%", "")
	var f := v.to_float()
	if valor.ends_with("%"):
		f = f / 100.0
	objetivo.modulate.a = f

func _aplicar_font_size(objetivo: Node, valor: String) -> void:
	# Capa: etiqueta de texto (ej. "BUG"), NO el cuerpo del enemigo.
	if objetivo.has_node("Etiqueta"):
		var tam := valor.replace("px", "").to_float()
		objetivo.get_node("Etiqueta").add_theme_font_size_override("font_size", int(tam))

func _aplicar_width(objetivo: Node, valor: String) -> void:
	_escalar_cuerpo(objetivo, valor, true)

func _aplicar_height(objetivo: Node, valor: String) -> void:
	_escalar_cuerpo(objetivo, valor, false)

func _escalar_cuerpo(objetivo: Node, valor: String, es_ancho: bool) -> void:
	if not objetivo.has_node("Cuerpo"):
		return
	var px := valor.replace("px", "").to_float()
	var cuerpo: ColorRect = objetivo.get_node("Cuerpo")
	var tam := cuerpo.size
	if es_ancho:
		tam.x = px
	else:
		tam.y = px
	cuerpo.size = tam
	cuerpo.position = -tam / 2.0

func _aplicar_border_radius(_objetivo: Node, _valor: String) -> void:
	# Simulacion pendiente: Godot no tiene "border-radius" nativo en ColorRect.
	# TODO: migrar "Cuerpo" a un Panel con StyleBoxFlat para soportar corner_radius real.
	pass

func _aplicar_transform(objetivo: Node, valor: String) -> void:
	if valor.begins_with("rotate("):
		var grados := valor.replace("rotate(", "").replace("deg)", "").to_float()
		objetivo.rotation_degrees = grados
