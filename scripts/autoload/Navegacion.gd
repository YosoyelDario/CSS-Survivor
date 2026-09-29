extends Node
## Autoload: Navegacion
## Controla el cambio de escenas centralizado y el paso de parámetros.

const ESCENAS := {
	"registro": "res://scenes/Registro.tscn",
	"menu": "res://scenes/MenuPrincipal.tscn",
	"nivel": "res://scenes/Nivel.tscn",
	"niveles": "res://scenes/Niveles.tscn",
	"logros": "res://scenes/Logros.tscn",
	"como_jugar": "res://scenes/ComoJugar.tscn",
	"ranking": "res://scenes/Ranking.tscn"
}

# Diccionario global para retener los datos entre cambios de escena
var parametros: Dictionary = {}

## Cambia a la escena solicitada. Retorna false si no existe.
func ir_a(nombre_escena: String, nuevos_parametros: Dictionary = {}) -> bool:
	if ESCENAS.has(nombre_escena) and FileAccess.file_exists(ESCENAS[nombre_escena]):
		parametros = nuevos_parametros
		get_tree().change_scene_to_file(ESCENAS[nombre_escena])
		return true
	
	push_warning("Navegacion: Escena no encontrada o en construcción -> " + nombre_escena)
	return false

## Cierra la aplicación.
func salir() -> void:
	get_tree().quit()

## Recupera un parámetro guardado. Si no existe, devuelve el valor por defecto.
func obtener_parametro(clave: String, valor_por_defecto: Variant = null) -> Variant:
	if parametros.has(clave):
		return parametros[clave]
	return valor_por_defecto

## Limpia el diccionario de parámetros.
func limpiar_parametros() -> void:
	parametros.clear()
