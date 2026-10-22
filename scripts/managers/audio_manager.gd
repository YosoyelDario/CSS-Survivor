extends Node

signal settings_changed(master: float, music: float, sfx: float, muted: bool)

const SETTINGS_PATH := "user://audio_settings.json"
const MENU_MUSIC: AudioStream = preload("res://assets/audio/menu_music.wav")
const GAME_MUSIC: AudioStream = preload("res://assets/audio/game_music.wav")
const SFX: Dictionary = {
	"shoot": preload("res://assets/audio/shoot.wav"),
	"correct": preload("res://assets/audio/correct.wav"),
	"hit": preload("res://assets/audio/hit.wav"),
	"timeout": preload("res://assets/audio/timeout.wav"),
	"tick": preload("res://assets/audio/tick.wav")
}

var master_volume: float = 0.85
var music_volume: float = 0.65
var sfx_volume: float = 0.85
var muted: bool = false
var urgent: bool = false

var music_player: AudioStreamPlayer
var current_music: String = ""

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	add_child(music_player)

	music_player.finished.connect(_on_music_finished)

	_load_settings()
	_apply_music_volume()

func _on_music_finished() -> void:
	if current_music.is_empty():
		return

	music_player.play()

func settings() -> Dictionary:
	return {
		"master": master_volume,
		"music": music_volume,
		"sfx": sfx_volume,
		"muted": muted
	}

func set_settings(master: float, music: float, sfx: float, is_muted: bool) -> void:
	master_volume = clampf(master, 0.0, 1.0)
	music_volume = clampf(music, 0.0, 1.0)
	sfx_volume = clampf(sfx, 0.0, 1.0)
	muted = is_muted
	_apply_music_volume()
	_save_settings()
	settings_changed.emit(master_volume, music_volume, sfx_volume, muted)

func set_master_volume(value: float) -> void:
	set_settings(value, music_volume, sfx_volume, muted)

func set_music_volume(value: float) -> void:
	set_settings(master_volume, value, sfx_volume, muted)

func set_sfx_volume(value: float) -> void:
	set_settings(master_volume, music_volume, value, muted)

func set_muted(value: bool) -> void:
	set_settings(master_volume, music_volume, sfx_volume, value)

func play_menu_music() -> void:
	_play_music(MENU_MUSIC, "menu")

func play_game_music() -> void:
	_play_music(GAME_MUSIC, "game")

func stop_music() -> void:
	music_player.stop()
	current_music = ""
	urgent = false

func set_urgent(value: bool) -> void:
	if urgent == value:
		return
	urgent = value
	# La música del juego acelera suavemente cuando queda poco tiempo.
	music_player.pitch_scale = 1.16 if urgent and current_music == "game" else 1.0

func play_sfx(name: String) -> void:
	if muted or master_volume <= 0.0 or sfx_volume <= 0.0:
		return
	if not SFX.has(name):
		push_warning("SFX desconocido: %s" % name)
		return
	var player := AudioStreamPlayer.new()
	player.stream = SFX[name]
	player.volume_db = _linear_to_db(master_volume * sfx_volume)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _play_music(stream: AudioStream, key: String) -> void:
	if current_music == key and music_player.playing:
		return

	current_music = key
	urgent = false

	music_player.stop()
	music_player.stream = stream
	music_player.pitch_scale = 1.0

	_apply_music_volume()
	music_player.play()

func _apply_music_volume() -> void:
	if music_player == null:
		return
	var linear: float = 0.0 if muted else master_volume * music_volume
	music_player.volume_db = _linear_to_db(linear)

func _linear_to_db(value: float) -> float:
	if value <= 0.0001:
		return -80.0
	return linear_to_db(value)

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed as Dictionary
	master_volume = clampf(float(data.get("master", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(data.get("music", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(data.get("sfx", sfx_volume)), 0.0, 1.0)
	muted = bool(data.get("muted", muted))

func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo guardar la configuración de audio.")
		return
	file.store_string(JSON.stringify(settings(), "  "))
