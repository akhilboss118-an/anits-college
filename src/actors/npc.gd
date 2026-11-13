extends Node3D
## An NPC driven by the ORIGINAL web-game character models:
##   guard (Bajirao), Laksmi, Colonel Singh, NCC cadets, girl students and the
##   shared Remy student model - all with their original animations.
##
## The campus still treats an NPC as a point (no collision), exactly like the
## original web build.

## Name tag sizing. The web build scales the label sprite with the distance to
## the camera (js/game.js: w = clamp(d * k, min, max)), so a tag stays
## readable far away but shrinks again once the clamp kicks in. The same idea
## is used here: the text grows with the distance up to a limit.
const LABEL_FONT_SIZE := 22
const LABEL_HEIGHT_RATE := 0.022   ## metres of text per metre of distance
const LABEL_MIN_HEIGHT := 0.08
const LABEL_MAX_HEIGHT := 0.30
const LABEL_HEIGHT_STEP := 0.02    ## quantisation: the text mesh is rebuilt rarely
const LABEL_NEAR_DIST := 1.4       ## closer than this the tag fades away
const LABEL_FADE := 0.9            ## fade distance behind LABEL_NEAR_DIST
const LABEL_FAR_DIST := 62.0        ## tag culling range (metres)
## The web build hides the name tags of the cadets at 5 m and of the students
## at 14 m, so a parade ground does not turn into a wall of text.
const LABEL_FAR_DIST_CADET := 6.0
const LABEL_FAR_DIST_STUDENT := 16.0

## Distance culling of the model itself (the web build uses 90 - 100 m).
const VISUAL_FAR_DIST := 95.0

## How often the camera is looked up again (it rarely changes).
const CAMERA_REFRESH := 0.5

var npc_id: String = ""
var display_name: String = "Student"
var lines: Dictionary = {}
var group_name: String = "student"
var is_talking: bool = false
var home_position: Vector3 = Vector3.ZERO
var route: Array = []
var route_index: int = 0
var route_dir: int = 1
var walk_speed: float = 1.2
var base_facing: float = 0.0

var _visual: CharacterVisual
var _label: Label3D
var _label_height: float = LABEL_MIN_HEIGHT
var _label_alpha: float = -1.0
var _camera: Camera3D = null
var _camera_timer: float = 0.0


func setup(data: Dictionary) -> void:
	npc_id = str(data.get("id", "npc"))
	display_name = str(data.get("name", "Student"))
	lines = data.get("lines", {})
	group_name = str(data.get("group", "student"))
	route = data.get("route", [])
	base_facing = float(data.get("facing", 0.0))
	if data.has("walk"):
		## Girls from girls.js: the racers run, the rest stand and chat.
		walk_speed = 3.4 if bool(data.get("walk")) else 1.2
	else:
		walk_speed = 1.5
	add_to_group("npcs")
	_build_visual(data)
	if data.has("pos"):
		var p: Array = data["pos"]
		var w := Campus.map_to_world(Vector2(p[0], p[1]))
		position = Vector3(w.x, 0.0, w.z)
	home_position = position
	if route.size() > 0:
		_set_route_point(0)
	elif _visual:
		_visual.rotation.y = base_facing


## Picks the original model for this NPC.
func _model_id(data: Dictionary) -> String:
	var kind := str(data.get("model", "student"))
	if kind == "guard" or npc_id == "guard":
		return "guard"
	if kind == "clerk" or npc_id == "clerk":
		return "laksmi"
	if npc_id == "colonel":
		return "colonel"
	if kind == "cadet":
		# alternate the two NCC rigs down the parade line
		var n := 0
		var digits := npc_id.split("_")
		if digits.size() > 1:
			n = int(digits[1])
		return "cadet_girl" if n % 3 == 1 else "cadet_boy"
	if kind == "girl":
		return "girl"
	return "remy"


func _build_visual(data: Dictionary) -> void:
	var height := float(data.get("height", 1.7))
	var model := _model_id(data)
	var tint := Color.WHITE
	if model == "remy":
		height = maxf(height, 1.75)
	elif model == "colonel":
		height = 1.85
	elif model == "girl":
		height = float(data.get("height", 1.62))
		## Every girl has her own tint in girls.js so they do not look alike.
		var t: Array = data.get("tint", [1.0, 1.0, 1.0])
		tint = Color(float(t[0]), float(t[1]), float(t[2]))
	elif model == "cadet_boy":
		height = 1.74
	elif model == "cadet_girl":
		height = 1.64
	_visual = CharacterVisual.create(model, height, tint)
	if _visual:
		add_child(_visual)
		_visual.rotation.y = base_facing
		## The NCC kit (beret + belt) the web build bolts onto the cadets.
		var beret := str(data.get("beret", ""))
		if beret != "":
			_visual.set_beret_colour(Color.html(beret))

	_label = Label3D.new()
	_label.text = display_name
	_label.font_size = LABEL_FONT_SIZE
	_label.pixel_size = LABEL_MIN_HEIGHT / float(LABEL_FONT_SIZE)
	_label.position = Vector3(0, height + 0.55, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.outline_size = 6
	_label.outline_modulate = Color(0.08, 0.1, 0.14)
	_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	# the tag is depth tested, so a wall or the player hides it
	_label.no_depth_test = false
	_label.fixed_size = false
	add_child(_label)
	_label_height = LABEL_MIN_HEIGHT
	_label_alpha = -1.0

	# NPCs are not solid in the original game (you can walk through them),
	# so they carry no collision shape and never block the camera boom.


func _process(delta: float) -> void:
	if route.size() > 1 and not is_talking:
		_walk_route(delta)
	elif _visual:
		_visual.set_moving(false)
	var cam := _camera_3d(delta)
	if cam == null or _visual == null:
		return
	var d := global_position.distance_to(cam.global_position)
	# distance culling: the campus has 64 animated skeletons
	_visual.set_active(d < VISUAL_FAR_DIST)
	_update_label(d)


## The camera hardly ever changes, so it is only looked up twice a second.
func _camera_3d(delta: float) -> Camera3D:
	_camera_timer -= delta
	if _camera == null or not is_instance_valid(_camera) or _camera_timer <= 0.0:
		_camera_timer = CAMERA_REFRESH
		if is_inside_tree():
			_camera = get_viewport().get_camera_3d()
	return _camera


## Keeps the name tag legible: it grows with the distance (like the web
## build's label sprite) but never past LABEL_MAX_HEIGHT, and it fades out
## when the NPC is right in front of the camera.
func _update_label(distance: float) -> void:
	if _label == null:
		return
	var far := LABEL_FAR_DIST
	if group_name == "cadet":
		far = LABEL_FAR_DIST_CADET
	elif group_name != "guard" and group_name != "clerk" and group_name != "colonel":
		far = LABEL_FAR_DIST_STUDENT
	var in_range := distance < far
	var alpha := clampf((distance - LABEL_NEAR_DIST) / LABEL_FADE, 0.0, 1.0)
	if in_range:
		# the text mesh is only rebuilt when the size really changes
		var h := snappedf(clampf(distance * LABEL_HEIGHT_RATE, LABEL_MIN_HEIGHT,
			LABEL_MAX_HEIGHT), LABEL_HEIGHT_STEP)
		if not is_equal_approx(h, _label_height):
			_label_height = h
			_label.pixel_size = h / float(LABEL_FONT_SIZE)
	if not is_equal_approx(alpha, _label_alpha):
		_label_alpha = alpha
		_label.modulate = Color(1.0, 1.0, 1.0, alpha)
	_label.visible = in_range and alpha > 0.01


func _walk_route(delta: float) -> void:
	var point: Array = route[(route_index + route_dir + route.size()) % route.size()]
	var w := Campus.map_to_world(Vector2(point[0], point[1]))
	var to := Vector3(w.x, 0.0, w.z) - position
	to.y = 0.0
	if to.length() < 0.4:
		route_index += route_dir
		if route_index >= route.size():
			route_index = route.size() - 2
			route_dir = -1
		elif route_index < 0:
			route_index = 1
			route_dir = 1
		return
	var dir := to.normalized()
	position += dir * walk_speed * delta
	if _visual:
		_visual.rotation.y = atan2(dir.x, dir.z)
		_visual.set_moving(true, walk_speed)


func _set_route_point(index: int) -> void:
	if route.size() == 0:
		return
	var p: Array = route[clampi(index, 0, route.size() - 1)]
	var w := Campus.map_to_world(Vector2(p[0], p[1]))
	position = Vector3(w.x, 0.0, w.z)
	if _visual:
		var point: Array = route[mini(index + 1, route.size() - 1)]
		var n := Campus.map_to_world(Vector2(point[0], point[1]))
		var dir := (Vector3(n.x, 0.0, n.z) - position).normalized()
		if dir.length() > 0.01:
			_visual.rotation.y = atan2(dir.x, dir.z)


func face_towards(target: Vector3) -> void:
	var d := target - global_position
	if _visual and Vector2(d.x, d.z).length() > 0.01:
		_visual.rotation.y = atan2(d.x, d.z)


## Moves a static NPC (e.g. Laksmi in the Admin Office) and locks its facing.
func place_at(world_pos: Vector3, facing: float) -> void:
	position = world_pos
	home_position = world_pos
	route.clear()
	base_facing = facing
	if _visual:
		_visual.rotation.y = facing


func set_talking(talking: bool) -> void:
	is_talking = talking
	if _visual:
		_visual.set_talking(talking)
	if not talking and _visual and route.size() < 2:
		_visual.rotation.y = base_facing


func play_salute(delay := 0.0) -> void:
	if _visual:
		_visual.play_salute(delay)


func idle_lines() -> Array:
	return lines.get("idle", [])


func lines_for(key: String) -> Array:
	if lines.has("steps") and (lines["steps"] as Dictionary).has(key):
		return (lines["steps"] as Dictionary)[key]
	return idle_lines()
