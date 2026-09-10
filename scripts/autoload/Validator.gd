extends Node
## Autoload: Validator
## Normaliza texto y valida si una respuesta coincide con lo que exige un enemigo.
## No interpreta CSS real -- solo compara strings normalizados (ver informe, Seccion V).

func normalizar(texto: String) -> String:
	var t := texto.strip_edges().to_lower()
	t = t.replace(" ", "")
	if t.ends_with(";"):
		t = t.substr(0, t.length() - 1)
	return t

## Recibe algo como "color: red;" y devuelve ["color", "red"]
func extraer_propiedad_valor(declaracion: String) -> Array:
	var d := normalizar(declaracion)
	var partes := d.split(":")
	if partes.size() != 2:
		return ["", ""]
	return [partes[0], partes[1]]

func es_correcta(enemy, propiedad: String, valor: String) -> bool:
	var prop_norm := propiedad.strip_edges().to_lower()
	var val_norm := normalizar(valor)
	var val_esperado := normalizar(enemy.valor_requerido)
	return prop_norm == enemy.propiedad_requerida and val_norm == val_esperado
