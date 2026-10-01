extends RefCounted

const LOG_PATH := "user://css_survivor_log.json"

func append(record: Dictionary) -> void:
	var data: Array = []
	if FileAccess.file_exists(LOG_PATH):
		var read_file := FileAccess.open(LOG_PATH, FileAccess.READ)
		var parsed = JSON.parse_string(read_file.get_as_text())
		if typeof(parsed) == TYPE_ARRAY:
			data = parsed
	data.append(record)
	var write_file := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	write_file.store_string(JSON.stringify(data, "  "))

func full_path() -> String:
	return ProjectSettings.globalize_path(LOG_PATH)
