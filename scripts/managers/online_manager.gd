extends Node

signal global_ranking_received(rows: Array)
signal global_ranking_failed(message: String)
signal upload_status(message: String, success: bool)

const API_URL := "https://script.google.com/macros/s/AKfycbzL5GKEfsljb1Nc6wbu5YytI-pOjWQrEm8fo17zG2Tyw35f1zoSKLYMZLLtI963cgBs/exec"
const PENDING_PATH := "user://pending_uploads.json"
const FAILED_PATH := "user://failed_uploads.json"
const REQUEST_TIMEOUT := 20.0

var upload_http: HTTPRequest
var upload_response_http: HTTPRequest
var ranking_http: HTTPRequest
var pending_uploads: Array = []
var failed_uploads: Array = []
var upload_busy: bool = false
var ranking_busy: bool = false
var ranking_waiting_for_sync: bool = false

func _ready() -> void:
	upload_http = HTTPRequest.new()
	upload_http.name = "UploadHTTPRequest"
	upload_http.timeout = REQUEST_TIMEOUT
	upload_http.max_redirects = 0
	upload_http.use_threads = true
	add_child(upload_http)
	upload_http.request_completed.connect(_on_upload_completed)

	# Apps Script ContentService responde a los POST con una redirección a
	# script.googleusercontent.com. Godot 4.2 puede conservar POST al seguirla,
	# lo que produce HTTP 405. Por eso la seguimos manualmente como GET.
	upload_response_http = HTTPRequest.new()
	upload_response_http.name = "UploadResponseHTTPRequest"
	upload_response_http.timeout = REQUEST_TIMEOUT
	upload_response_http.max_redirects = 8
	upload_response_http.use_threads = true
	add_child(upload_response_http)
	upload_response_http.request_completed.connect(_on_upload_response_completed)

	ranking_http = HTTPRequest.new()
	ranking_http.name = "RankingHTTPRequest"
	ranking_http.timeout = REQUEST_TIMEOUT
	ranking_http.max_redirects = 8
	ranking_http.use_threads = true
	add_child(ranking_http)
	ranking_http.request_completed.connect(_on_ranking_completed)

	_load_pending()
	_load_failed()
	# Reintenta automáticamente cualquier resultado que haya quedado pendiente
	# de una ejecución anterior. Se difiere un frame para asegurar que HTTPRequest
	# ya esté completamente listo dentro del árbol.
	call_deferred("_try_upload_next")

func submit_attempt(payload: Dictionary) -> void:
	if payload.is_empty():
		return
	_enqueue(payload)
	_try_upload_next()

# El ranking global solo se consulta cuando el usuario pulsa CONECTAR/ACTUALIZAR.
# Antes de leerlo se intenta sincronizar cualquier intento que haya quedado pendiente.
func request_global_ranking(snapshot_payload: Dictionary = {}) -> void:
	if ranking_busy:
		return
	if not snapshot_payload.is_empty():
		_enqueue(snapshot_payload)
	ranking_waiting_for_sync = true
	if pending_uploads.is_empty():
		_start_ranking_request()
	else:
		_try_upload_next()

func pending_count() -> int:
	return pending_uploads.size()

func _enqueue(payload: Dictionary) -> void:
	var action: String = str(payload.get("action", ""))
	if action == "sync_ranking":
		var ranking: Dictionary = payload.get("ranking", {}) as Dictionary
		var player_id: String = str(ranking.get("id_jugador", ""))
		# Mantiene solo el snapshot de ranking más reciente por jugador.
		for i in range(pending_uploads.size() - 1, -1, -1):
			var queued: Dictionary = pending_uploads[i] as Dictionary
			if str(queued.get("action", "")) != "sync_ranking":
				continue
			var queued_ranking: Dictionary = queued.get("ranking", {}) as Dictionary
			if str(queued_ranking.get("id_jugador", "")) == player_id:
				pending_uploads.remove_at(i)
	else:
		var attempt: Dictionary = payload.get("intento", {}) as Dictionary
		var new_id: String = str(attempt.get("id_intento", ""))
		if not new_id.is_empty():
			for value in pending_uploads:
				var queued: Dictionary = value as Dictionary
				var queued_attempt: Dictionary = queued.get("intento", {}) as Dictionary
				if str(queued_attempt.get("id_intento", "")) == new_id:
					return
	pending_uploads.append(payload.duplicate(true))
	_save_pending()

func _try_upload_next() -> void:
	if upload_busy:
		return
	if pending_uploads.is_empty():
		if ranking_waiting_for_sync:
			_start_ranking_request()
		return

	var payload: Dictionary = pending_uploads[0] as Dictionary
	var body: String = JSON.stringify(payload)
	var headers := PackedStringArray(["Content-Type: application/json; charset=utf-8", "Accept: application/json"])
	var action: String = str(payload.get("action", ""))
	var attempt: Dictionary = payload.get("intento", {}) as Dictionary
	print("[SYNC] Enviando action=", action, " id=", str(attempt.get("id_intento", "-")), " pendientes=", pending_uploads.size())
	upload_busy = true
	var error: int = upload_http.request(API_URL, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		upload_busy = false
		print("[SYNC] No se pudo iniciar HTTPRequest. Error=", error)
		upload_status.emit("No se pudo iniciar el envío; quedó guardado localmente.", false)
		if ranking_waiting_for_sync:
			ranking_waiting_for_sync = false
			global_ranking_failed.emit("No se pudo sincronizar antes de abrir el ranking. Error local %d." % error)

func _on_upload_completed(result: int, response_code: int, response_headers: PackedStringArray, body: PackedByteArray) -> void:
	var body_text: String = body.get_string_from_utf8()
	print("[SYNC] POST result=", result, " http=", response_code, " body=", body_text.left(300))

	# ContentService de Apps Script entrega el cuerpo mediante una URL temporal.
	# No dejamos que HTTPRequest siga automáticamente el redirect porque en Godot
	# 4.2 puede repetir el POST contra googleusercontent y Google responde 405.
	if response_code in [301, 302, 303, 307, 308]:
		var redirect_url: String = _header_value(response_headers, "location")
		if redirect_url.is_empty():
			upload_busy = false
			upload_status.emit("Google redirigió el envío sin entregar una URL de respuesta.", false)
			if ranking_waiting_for_sync:
				ranking_waiting_for_sync = false
				global_ranking_failed.emit("Google devolvió una redirección inválida (HTTP %d)." % response_code)
			return

		print("[SYNC] Siguiendo respuesta de Google como GET: ", redirect_url.left(120), "...")
		var redirect_error: int = upload_response_http.request(
			redirect_url,
			PackedStringArray(["Accept: application/json"]),
			HTTPClient.METHOD_GET
		)
		if redirect_error != OK:
			upload_busy = false
			upload_status.emit("No se pudo leer la respuesta final de Google; el envío quedó pendiente.", false)
			if ranking_waiting_for_sync:
				ranking_waiting_for_sync = false
				global_ranking_failed.emit("No se pudo seguir la respuesta de Google. Error local %d." % redirect_error)
		return

	upload_busy = false
	_process_upload_response(result, response_code, body_text)

func _on_upload_response_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	upload_busy = false
	var body_text: String = body.get_string_from_utf8()
	print("[SYNC] Respuesta final result=", result, " http=", response_code, " body=", body_text.left(500))
	_process_upload_response(result, response_code, body_text)

func _process_upload_response(result: int, response_code: int, body_text: String) -> void:
	# Fallo real de red/timeout/servidor: conservar para reintentar luego.
	if result != HTTPRequest.RESULT_SUCCESS or response_code >= 500 or response_code == 0:
		upload_status.emit("No se pudo conectar con Google; el envío quedó pendiente.", false)
		if ranking_waiting_for_sync:
			ranking_waiting_for_sync = false
			global_ranking_failed.emit("Google no respondió a la sincronización (HTTP %d, resultado %d)." % [response_code, result])
		return

	var parsed: Variant = JSON.parse_string(body_text)
	if typeof(parsed) == TYPE_DICTIONARY:
		var data: Dictionary = parsed as Dictionary
		if bool(data.get("ok", false)):
			if not pending_uploads.is_empty():
				pending_uploads.remove_at(0)
				_save_pending()
			upload_status.emit("Resultados sincronizados con Google Sheets.", true)
			_try_upload_next()
			return

		var server_error: String = str(data.get("error", "El servidor rechazó el paquete."))
		_quarantine_current("Servidor: " + server_error)
		upload_status.emit("Un envío inválido fue apartado; se continuó con los siguientes.", false)
		_try_upload_next()
		return

	# Una respuesta no JSON indica despliegue/permisos inesperados o una URL incorrecta.
	_quarantine_current("Respuesta no JSON. HTTP %d: %s" % [response_code, body_text.left(300)])
	upload_status.emit("Google respondió con un formato inesperado; el paquete fue apartado.", false)
	_try_upload_next()

func _header_value(headers: PackedStringArray, wanted_name: String) -> String:
	var prefix: String = wanted_name.to_lower() + ":"
	for header in headers:
		var line: String = str(header)
		if line.to_lower().begins_with(prefix):
			return line.substr(line.find(":") + 1).strip_edges()
	return ""

func _quarantine_current(reason: String) -> void:
	if pending_uploads.is_empty():
		return
	failed_uploads.append({
		"failed_at": Time.get_datetime_string_from_system(),
		"reason": reason,
		"payload": (pending_uploads[0] as Dictionary).duplicate(true)
	})
	pending_uploads.remove_at(0)
	_save_pending()
	_save_failed()
	print("[SYNC] Paquete apartado: ", reason)

func _start_ranking_request() -> void:
	ranking_waiting_for_sync = false
	if ranking_busy:
		return
	ranking_busy = true
	var error: int = ranking_http.request(API_URL + "?action=ranking")
	if error != OK:
		ranking_busy = false
		global_ranking_failed.emit("No se pudo iniciar la conexión con el ranking global.")

func _on_ranking_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	ranking_busy = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		global_ranking_failed.emit("No se pudo conectar. Revisa tu conexión a Internet e inténtalo de nuevo.")
		return

	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		global_ranking_failed.emit("Google respondió con un formato inesperado.")
		return

	var data: Dictionary = parsed as Dictionary
	if not bool(data.get("ok", false)):
		global_ranking_failed.emit(str(data.get("error", "No se pudo obtener el ranking.")))
		return

	var rows: Array = data.get("ranking", []) as Array
	global_ranking_received.emit(rows)

func _load_pending() -> void:
	pending_uploads = []
	if not FileAccess.file_exists(PENDING_PATH):
		return
	var file := FileAccess.open(PENDING_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_ARRAY:
		pending_uploads = parsed as Array

func _save_pending() -> void:
	var file := FileAccess.open(PENDING_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo guardar la cola de sincronización.")
		return
	file.store_string(JSON.stringify(pending_uploads, "  "))

func _load_failed() -> void:
	failed_uploads = []
	if not FileAccess.file_exists(FAILED_PATH):
		return
	var file := FileAccess.open(FAILED_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_ARRAY:
		failed_uploads = parsed as Array

func _save_failed() -> void:
	var file := FileAccess.open(FAILED_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo guardar la cola de envíos rechazados.")
		return
	file.store_string(JSON.stringify(failed_uploads, "  "))
