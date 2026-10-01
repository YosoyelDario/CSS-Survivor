extends RefCounted

var zone_index: int = 0
var total_rows: int = 0
var lanes: int = 3
var visible_rows: int = 3
var attack_mode: String = "adjacent"
var _rows: Array = []
var _next_enemy_id: int = 1

func setup(index: int, row_count: int, lane_count: int = 3, visible_count: int = 3, mode: String = "adjacent") -> void:
	zone_index = index
	total_rows = maxi(0, row_count)
	lanes = maxi(1, lane_count)
	visible_rows = maxi(1, visible_count)
	attack_mode = mode
	_rows.clear()
	_next_enemy_id = 1
	for row_index in range(total_rows):
		var enemies: Array = []
		for lane in range(lanes):
			enemies.append({"id": _next_enemy_id, "lane": lane, "alive": true, "source_row": row_index})
			_next_enemy_id += 1
		_rows.append({"source_row": row_index, "enemies": enemies})

func rows_left() -> int:
	return _rows.size()

func rows_total() -> int:
	return total_rows

func is_clean() -> bool:
	return _rows.is_empty()

func front_row() -> Dictionary:
	return _rows[0] if not _rows.is_empty() else {}

func visible_state() -> Array:
	var state: Array = []
	for i in range(mini(visible_rows, _rows.size())):
		state.append({"depth": i, "row": _rows[i].duplicate(true)})
	return state

func queue_count() -> int:
	return maxi(0, _rows.size() - visible_rows)

func target_and_neighbors() -> Dictionary:
	if attack_mode != "adjacent":
		push_error("attack_mode no soportado todavía: %s" % attack_mode)
		return {"target": {}, "neighbors": [], "affected": []}
	var row := front_row()
	if row.is_empty():
		return {"target": {}, "neighbors": [], "affected": []}
	var alive: Array = []
	for enemy in row.get("enemies", []):
		if bool(enemy.get("alive", false)):
			alive.append(enemy)
	if alive.is_empty():
		return {"target": {}, "neighbors": [], "affected": []}
	var center_lane := int(floor(float(lanes - 1) / 2.0))
	var target: Dictionary = alive[0]
	var best_distance := 999999
	for enemy in alive:
		var distance := absi(int(enemy.get("lane", 0)) - center_lane)
		if distance < best_distance:
			best_distance = distance
			target = enemy
	var neighbors: Array = []
	for enemy in alive:
		if int(enemy.get("id", -1)) != int(target.get("id", -1)):
			neighbors.append(enemy)
	return {"target": target.duplicate(true), "neighbors": neighbors.duplicate(true), "affected": alive.duplicate(true)}

func resolve_success() -> Array:
	var selection := target_and_neighbors()
	var affected: Array = selection.get("affected", [])
	if affected.is_empty():
		return affected
	if _rows.is_empty():
		return []
	for i in range(_rows[0]["enemies"].size()):
		var enemy: Dictionary = _rows[0]["enemies"][i]
		for hit_enemy in affected:
			if int(enemy.get("id", -1)) == int(hit_enemy.get("id", -2)):
				enemy["alive"] = false
				_rows[0]["enemies"][i] = enemy
	return affected

func front_cleared() -> bool:
	if _rows.is_empty():
		return true
	for enemy in _rows[0].get("enemies", []):
		if bool(enemy.get("alive", false)):
			return false
	return true

func advance_rows() -> Array:
	var movements: Array = []
	if _rows.is_empty() or not front_cleared():
		return movements
	_rows.pop_front()
	for new_depth in range(mini(visible_rows, _rows.size())):
		movements.append({"source_row": int(_rows[new_depth].get("source_row", -1)), "to_depth": new_depth})
	return movements
