extends Node

signal tick(remaining: float, total: float, urgent: bool)
signal expired

var duration: float = 0.0
var remaining: float = 0.0
var urgent_threshold: float = 0.0
var running: bool = false
var paused: bool = false

func _ready() -> void:
	set_process(true)

func start(seconds: float, urgent_seconds: float) -> void:
	duration = maxf(1.0, seconds)
	remaining = duration
	urgent_threshold = clampf(urgent_seconds, 1.0, duration)
	running = true
	paused = false
	tick.emit(remaining, duration, remaining <= urgent_threshold)

func stop() -> void:
	running = false
	paused = false

func set_paused(value: bool) -> void:
	paused = value
	if running:
		tick.emit(remaining, duration, remaining <= urgent_threshold)

func elapsed_seconds() -> float:
	return maxf(0.0, duration - remaining)

func time_left() -> float:
	return maxf(0.0, remaining)

func _process(delta: float) -> void:
	if not running or paused:
		return
	remaining = maxf(0.0, remaining - delta)
	var is_urgent: bool = remaining <= urgent_threshold
	tick.emit(remaining, duration, is_urgent)
	if remaining <= 0.0:
		running = false
		expired.emit()
