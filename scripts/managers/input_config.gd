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

static func _bind_key(action: StringName, key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	for existing in InputMap.action_get_events(action):
		if existing is InputEventKey:
			var key_event := existing as InputEventKey
			if key_event.physical_keycode == key:
				return
	InputMap.action_add_event(action, event)
