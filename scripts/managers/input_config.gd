extends RefCounted

static func configure() -> void:
	_bind_key("move_up", KEY_W)
	_bind_key("move_up", KEY_UP)
	_bind_key("move_down", KEY_S)
	_bind_key("move_down", KEY_DOWN)
	_bind_key("move_left", KEY_A)
	_bind_key("move_left", KEY_LEFT)
	_bind_key("move_right", KEY_D)
	_bind_key("move_right", KEY_RIGHT)
	_bind_key("interact", KEY_E)
	_bind_key("interact", KEY_SPACE)
	_bind_key("interact", KEY_ENTER)
	_bind_key("answer_1", KEY_1)
	_bind_key("answer_2", KEY_2)
	_bind_key("answer_3", KEY_3)
	_bind_key("answer_4", KEY_4)
	_bind_key("pause_game", KEY_ESCAPE)

static func _bind_key(action: StringName, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventKey and (existing as InputEventKey).physical_keycode == key:
			return
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)
