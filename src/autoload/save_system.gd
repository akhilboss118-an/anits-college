extends Node
## Per-day autosave. Mirrors js/save.js: one slot per level, written every 4 s
## and on focus loss, with strict validation on load.

const AUTOSAVE_INTERVAL := 4.0
const PROFILE_PATH := "user://profile.json"
const ITEMS_PATH := "user://items.json"
const SAVE_DIR := "user://saves"

var _timer: float = 0.0
var _snapshot_provider: Callable = Callable()
var _enabled: bool = false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	# GameState is declared before SaveSystem in project.godot, so it is ready
	# by now. Restore the collected documents (ID, fee receipt, library card,
	# lab manual) that give_item() persisted.
	var gs: Node = get_node_or_null("/root/GameState")
	if gs:
		var saved: Variant = load_items()
		if saved is Dictionary:
			gs.items = saved
		# Restore campaign progress. Without this, unlocking a day or using
		# developer mode would only last until the game was closed.
		var profile_data: Dictionary = load_profile()
		if not profile_data.is_empty():
			gs.unlocked_day = clampi(int(profile_data.get("unlocked", 1)), 1, MAX_DAY_SLOTS)
	set_process(true)


func _process(delta: float) -> void:
	if not _enabled or not _snapshot_provider.is_valid():
		return
	_timer += delta
	if _timer >= AUTOSAVE_INTERVAL:
		_timer = 0.0
		save_now()


func start(provider: Callable) -> void:
	_snapshot_provider = provider
	_enabled = true
	_timer = 0.0


func stop() -> void:
	_enabled = false
	_snapshot_provider = Callable()


func save_path(day: int) -> String:
	return "%s/day_%02d.json" % [SAVE_DIR, day]


func save_now() -> bool:
	if not _snapshot_provider.is_valid():
		return false
	var data: Dictionary = _snapshot_provider.call()
	if data.is_empty():
		return false
	data["v"] = 1
	data["t"] = Time.get_unix_time_from_system()
	if not is_valid(data):
		push_warning("SaveSystem: snapshot failed validation, not written.")
		return false
	var file := FileAccess.open(save_path(int(data.get("day", 1))), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true


func has_save(day: int) -> bool:
	return FileAccess.file_exists(save_path(day)) and not load_day(day).is_empty()


func load_day(day: int) -> Dictionary:
	if not FileAccess.file_exists(save_path(day)):
		return {}
	var text := FileAccess.get_file_as_string(save_path(day))
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = parsed
	return data if is_valid(data) else {}


func is_valid(data: Dictionary) -> bool:
	if int(data.get("v", 0)) != 1:
		return false
	for key in ["wallet", "bank", "energy", "step", "x", "z", "yaw"]:
		if not data.has(key):
			return false
	var wallet := float(data["wallet"])
	var bank := float(data["bank"])
	var energy := float(data["energy"])
	if wallet < 0.0 or bank < 0.0:
		return false
	if energy < 0.0 or energy > 100.0:
		return false
	return true


func save_profile(profile: Dictionary, unlocked_day: int) -> void:
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"profile": profile, "unlocked": unlocked_day}))
	file.close()


func load_profile() -> Dictionary:
	if not FileAccess.file_exists(PROFILE_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROFILE_PATH))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func save_items(items: Dictionary) -> void:
	var file := FileAccess.open(ITEMS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(items))
	file.close()


func load_items() -> Dictionary:
	if not FileAccess.file_exists(ITEMS_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ITEMS_PATH))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func clear_all() -> void:
	for day in range(1, MAX_DAY_SLOTS + 1):
		DirAccess.remove_absolute(save_path(day))
	DirAccess.remove_absolute(PROFILE_PATH)
	DirAccess.remove_absolute(ITEMS_PATH)


const MAX_DAY_SLOTS := 10
