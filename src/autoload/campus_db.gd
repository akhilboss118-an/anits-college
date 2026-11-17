extends Node
## Loads and exposes the authored campus data (src/data/*.json).
## Everything here is a verbatim copy of the original game's tables - see
## docs/CAMPUS_MAP.md and docs/BUILDING_INVENTORY.md.

const DATA_DIR := "res://src/data/"

var campus: Dictionary = {}
var npcs: Dictionary = {}
var economy: Dictionary = {}
var building_list: Array = []
var npc_list: Array = []      ## flattened: 64 entries
var drinks: Array = []
var noodles: Array = []
var items: Array = []
var loaded: bool = false


func _ready() -> void:
	load_all()


func load_all() -> bool:
	campus = _read_json("campus_data.json")
	npcs = _read_json("npcs.json")
	economy = _read_json("economy.json")
	if campus.is_empty() or npcs.is_empty() or economy.is_empty():
		push_error("CampusDB: failed to load one or more data files.")
		return false
	building_list = campus.get("buildings", [])
	drinks = economy.get("drinks", [])
	noodles = economy.get("noodles", [])
	items = economy.get("items", [])
	npc_list = _flatten_npcs()
	loaded = true
	return true


func _read_json(file_name: String) -> Dictionary:
	var path := DATA_DIR + file_name
	if not FileAccess.file_exists(path):
		push_error("CampusDB: missing %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("CampusDB: %s is not a JSON object" % path)
		return {}
	return parsed


## Expands the compact NPC tables into the 64 individual NPCs of the original.
func _flatten_npcs() -> Array:
	var out: Array = []

	for npc in npcs.get("main", []):
		out.append(npc.duplicate(true))

	var cadet_cfg: Dictionary = npcs.get("cadets", {})
	var rows := int(cadet_cfg.get("rows", 0))
	var cols := int(cadet_cfg.get("cols", 0))
	var origin: Array = cadet_cfg.get("origin", [0, 0])
	var row_step := float(cadet_cfg.get("row_step", 0.0))
	var col_step := float(cadet_cfg.get("col_step", 0.0))
	var index := 0
	for r in rows:
		for c in cols:
			out.append({
				"id": "cadet_%02d" % index,
				"name": "NCC Cadet",
				"pos": [float(origin[0]) + row_step * r, float(origin[1]) + col_step * c],
				"color": cadet_cfg.get("color", "#8c8a52"),
				"beret": cadet_cfg.get("beret", "#1a2a5a"),
				"height": 1.7,
				"facing": cadet_cfg.get("facing", 0.0),
				"model": "cadet",
				"group": "cadet",
				"lines": cadet_cfg.get("lines", {}),
			})
			index += 1

	var generic_lines: Array = npcs.get("route_student_lines", [])
	var route_students: Array = npcs.get("route_students", [])
	for i in route_students.size():
		var student: Dictionary = route_students[i]
		out.append({
			"id": "stu_%02d" % i,
			"name": "Student",
			"pos": student.get("route", [[0, 0]])[0],
			"color": student.get("color", "#3b82c4"),
			"height": 1.7,
			"facing": 0.0,
			"model": "student",
			"group": "route_student",
			"route": student.get("route", []),
			"lines": {"idle": [generic_lines[i % generic_lines.size()]] if generic_lines.size() > 0 else []},
		})

	var basketball_lines: Array = npcs.get("basketball_lines", [])
	for i in npcs.get("basketball_players", []).size():
		var player: Dictionary = npcs.get("basketball_players", [])[i]
		out.append({
			"id": "bball_%02d" % i,
			"name": player.get("name", "Basketball Player"),
			"pos": player.get("pos", [0, 0]),
			"color": player.get("color", "#d05030"),
			"height": 1.7,
			"facing": player.get("facing", 0.0),
			"model": "student",
			"group": "basketball",
			"lines": {"idle": basketball_lines},
		})

	for i in npcs.get("named_walkers", []).size():
		var walker: Dictionary = npcs.get("named_walkers", [])[i]
		out.append({
			"id": "walker_%02d" % i,
			"name": walker.get("name", "Student"),
			"pos": walker.get("route", [[0, 0]])[0],
			"color": walker.get("color", "#4a7bd0"),
			"height": 1.7,
			"facing": 0.0,
			"model": "student",
			"group": "named_walker",
			"route": walker.get("route", []),
			"lines": {"idle": walker.get("lines", [])},
		})

	for i in npcs.get("standing", []).size():
		var standing: Dictionary = npcs.get("standing", [])[i]
		out.append({
			"id": "stand_%02d" % i,
			"name": standing.get("name", "Student"),
			"pos": standing.get("pos", [0, 0]),
			"color": standing.get("color", "#d05a3a"),
			"height": 1.7,
			"facing": standing.get("facing", 0.0),
			"model": "student",
			"group": "standing",
			"lines": {"idle": standing.get("lines", [])},
		})

	var remy: Dictionary = npcs.get("remy", {})
	if not remy.is_empty():
		out.append({
			"id": "remy",
			"name": remy.get("name", "Remy (Student)"),
			"pos": remy.get("route", [[0, 0]])[0],
			"color": remy.get("color", "#4a7bd0"),
			"height": remy.get("height", 1.75),
			"facing": remy.get("facing", 0.0),
			"model": "student",
			"group": "remy",
			"route": remy.get("route", []),
			"lines": {"idle": remy.get("lines", [])},
		})

	for i in npcs.get("girls", []).size():
		var girl: Dictionary = npcs.get("girls", [])[i]
		out.append({
			"id": "girl_%02d" % i,
			"name": girl.get("name", "Student"),
			"pos": girl.get("pos", girl.get("route", [[0, 0]])[0]),
			"color": "#c77ba3",
			"tint": girl.get("tint", [1.0, 1.0, 1.0]),
			"height": girl.get("height", 1.6),
			"facing": girl.get("facing", 0.0),
			"model": "girl",
			"group": "girl",
			"walk": girl.get("walk", false),
			"route": girl.get("route", []),
			"lines": {"idle": girl.get("lines", [])},
		})

	return out


func building_by_name(name: String) -> Dictionary:
	for building in building_list:
		if building.get("name", "") == name:
			return building
	return {}


func npc_by_id(id: String) -> Dictionary:
	for npc in npc_list:
		if npc.get("id", "") == id:
			return npc
	return {}


func main_npc(id: String) -> Dictionary:
	for npc in npcs.get("main", []):
		if npc.get("id", "") == id:
			return npc
	return {}


func drink_by_id(id: String) -> Dictionary:
	for drink in drinks:
		if drink.get("id", "") == id:
			return drink
	return {}


## Energy restored by a drink: energy_type 1 = energy drink, 0 = soda.
func energy_per_drink(energy_type: int) -> float:
	var table: Dictionary = economy.get("energy_per_drink", {})
	var key := "energy" if energy_type == 1 else "soda"
	return float(table.get(key, 35.0 if energy_type == 1 else 20.0))


func boost_seconds() -> float:
	return float(economy.get("boost_seconds", 30))


func noodle_by_id(id: String) -> Dictionary:
	for noodle in noodles:
		if noodle.get("id", "") == id:
			return noodle
	return {}


func player_tuning() -> Dictionary:
	return campus.get("player", {})


func economy_tuning() -> Dictionary:
	return campus.get("economy", {})
