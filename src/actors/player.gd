extends CharacterBody3D
## Player controller + third-person camera rig.
##
## Values are taken verbatim from the original web build (js/game.js):
##   walk 2.4 m/s, run 5.6 m/s, energy-drink boost x1.3 (30 s), no jump,
##   step-up 1.3 m, camera 5.4 m behind (3.2 m in dialogue), eye +1.5 m,
##   look at +1.35 m, avoidance in 0.4 m steps down to 1.2 m, pitch 0.05-1.1.

@onready var camera: Camera3D = $Camera3D

var tuning: Dictionary = {}
var yaw: float = PI
var pitch: float = 0.3
var speed: float = 0.0
var look_sensitivity: float = 1.0
var input_enabled: bool = true
var dialogue_nearby: Node = null
var interact_target: Node = null
var touch_move := Vector2.ZERO
var touch_run: bool = false
var camera_distance_override: float = 0.0

var _keys := {}
var _drag := false
var _yaw_accel := 0.0
var _visual: CharacterVisual
var _npc_cache: Array[Node3D] = []
var _interact_cache: Array[Node3D] = []
var _cache_timer: float = 0.0
var _boom_distance: float = -1.0
var _boom_timer: float = 0.0


func _ready() -> void:
	tuning = CampusDB.player_tuning() if CampusDB else {}
	look_sensitivity = Settings.look_sensitivity if Settings else 1.0
	if tuning.is_empty():
		tuning = {
			"walk_speed": 2.4, "run_speed": 5.6, "boost_multiplier": 1.3,
			"camera_distance": 5.4, "camera_distance_dialogue": 3.2,
			"camera_height": 1.5, "camera_look_height": 1.35,
			"camera_min_distance": 1.2, "camera_lerp": 10.0,
			"pitch_min": 0.05, "pitch_max": 1.1,
			"mouse_yaw": 0.006, "mouse_pitch": 0.004, "key_rotate": 1.8,
			"step_up": 1.3, "speed_lerp": 9.0,
		}
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.38
	cap.height = 1.8
	shape.shape = cap
	shape.position = Vector3(0, 0.9, 0)
	add_child(shape)
	_build_visual()
	camera.fov = 60.0
	camera.far = 800.0
	camera.top_level = true


## The visible player: the ORIGINAL Mixamo character (b_walk for the boy,
## cadet_amy for the girl) with its walk and salute animations.
func _build_visual() -> void:
	add_to_group("player")
	var is_girl := GameState.is_girl if GameState else false
	_visual = CharacterVisual.create("girl" if is_girl else "boy", 1.65 if is_girl else 1.75)
	if _visual:
		add_child(_visual)
		_visual.rotation.y = yaw
		_visual.apply_uniform(int(GameState.uniform_year) if GameState else 2024)


func _physics_process(delta: float) -> void:
	_read_input(delta)
	_update_camera(delta)
	_refresh_nearby_cache(delta)


## The campus holds 64 NPCs and a handful of interactables. Walking
## `get_nodes_in_group()` every physics frame allocated two arrays per frame,
## so the lists are refreshed a few times a second instead.
func _refresh_nearby_cache(delta: float) -> void:
	_cache_timer -= delta
	if _cache_timer > 0.0:
		return
	_cache_timer = 0.25
	_npc_cache.clear()
	for node in get_tree().get_nodes_in_group("npcs"):
		var n := node as Node3D
		if n != null and is_instance_valid(n):
			_npc_cache.append(n)
	_interact_cache.clear()
	for node in get_tree().get_nodes_in_group("interactables"):
		var n := node as Node3D
		if n != null and is_instance_valid(n):
			_interact_cache.append(n)


# ------------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
		_look(event.relative)
	if event is InputEventMouseButton and event.pressed:
		_drag = true
	if event is InputEventMouseButton and not event.pressed:
		_drag = false


func _look(relative: Vector2) -> void:
	# Read live so the Settings slider takes effect immediately, including
	# while a level is already running.
	var mult: float = Settings.look_sensitivity if Settings else look_sensitivity
	look_sensitivity = mult
	var sens := float(tuning.get("mouse_yaw", 0.006)) * mult
	yaw -= relative.x * sens
	pitch = clampf(pitch + relative.y * float(tuning.get("mouse_pitch", 0.004)) * mult,
		float(tuning.get("pitch_min", 0.05)), float(tuning.get("pitch_max", 1.1)))


## Called by the on-screen touch layer: drag anywhere on the right to orbit.
func add_touch_look(relative: Vector2) -> void:
	if not input_enabled:
		return
	_look(relative * 1.35)


func _read_input(delta: float) -> void:
	if not input_enabled:
		speed = 0.0
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var forward := 0.0
	var strafe := 0.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		forward += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		forward -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		strafe += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		strafe -= 1.0
	# Virtual joystick: +x is right, -y is forward.
	forward += -touch_move.y
	strafe += touch_move.x
	var run := Input.is_key_pressed(KEY_SHIFT) or touch_run
	if Input.is_key_pressed(KEY_Q):
		yaw += delta * float(tuning.get("key_rotate", 1.8))
	if Input.is_key_pressed(KEY_Z):
		yaw -= delta * float(tuning.get("key_rotate", 1.8))
	var wish := Vector3(sin(yaw) * forward - cos(yaw) * strafe, 0.0, cos(yaw) * forward + sin(yaw) * strafe)
	if wish.length() > 0.001:
		wish = wish.normalized()
	var boost := 1.0
	if GameState and GameState.boost_seconds > 0.0:
		boost = float(tuning.get("boost_multiplier", 1.3))
	var target := 0.0
	if wish.length() > 0.0:
		target = (float(tuning.get("run_speed", 5.6)) if run else float(tuning.get("walk_speed", 2.4))) * boost
	speed = lerpf(speed, target, minf(1.0, delta * float(tuning.get("speed_lerp", 9.0))))
	velocity.x = wish.x * speed
	velocity.z = wish.z * speed
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = -0.1
	move_and_slide()
	_find_nearby()
	_update_visual()


func _update_visual() -> void:
	if _visual == null:
		return
	if speed > 0.15:
		_visual.set_moving(true, maxf(speed, 0.6))
		var dir := Vector3(velocity.x, 0.0, velocity.z)
		if dir.length() > 0.05:
			_visual.rotation.y = atan2(dir.x, dir.z)
	else:
		_visual.set_moving(false)


func play_salute() -> void:
	if _visual:
		_visual.play_salute()


func set_talking(talking: bool) -> void:
	if _visual:
		_visual.set_talking(talking)


func _find_nearby() -> void:
	dialogue_nearby = null
	interact_target = null
	var radius := float(tuning.get("interact_radius", 3.8))
	var best := radius
	var mission_npc := ""
	if Mission:
		var step: Dictionary = Mission.current()
		if str(step.get("type", "")) == "npc":
			mission_npc = str(step.get("npc", ""))
	var mission_candidate: Node3D = null
	var mission_distance := INF
	for node in _npc_cache:
		var n := node as Node3D
		if n == null or not is_instance_valid(n):
			continue
		var d := global_position.distance_to(n.global_position)
		if mission_npc != "" and str(n.get("npc_id")) == mission_npc and d < radius:
			mission_candidate = n
			mission_distance = d
		if d < best:
			best = d
			dialogue_nearby = n
	# The mission objective wins over a closer bystander: Colonel Singh is
	# surrounded by cadets, and the Admin office has Laksmi at her desk.
	if mission_candidate:
		dialogue_nearby = mission_candidate
		best = mission_distance
	for node in _interact_cache:
		var n := node as Node3D
		if n == null or not is_instance_valid(n):
			continue
		var d := global_position.distance_to(n.global_position)
		if d < float(tuning.get("machine_radius", 3.4)) and d < best:
			best = d
			interact_target = n


# ------------------------------------------------------------------ camera

func _update_camera(delta: float) -> void:
	if camera == null:
		return
	var distance := float(tuning.get("camera_distance", 5.4))
	if camera_distance_override > 0.0:
		distance = camera_distance_override
	if dialogue_nearby != null:
		distance = float(tuning.get("camera_distance_dialogue", 3.2))
	var forward := Vector3(sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch))
	var eye := global_position + Vector3(0, float(tuning.get("camera_height", 1.5)), 0)
	# Building avoidance: shrink the boom in 0.4 m steps until it is clear.
	# The raycast march is expensive, so it only re-runs ~12 times a second
	# (and immediately after a teleport).
	var min_d := float(tuning.get("camera_min_distance", 1.2))
	_boom_timer -= delta
	if _boom_distance < 0.0 or _boom_timer <= 0.0:
		_boom_timer = 0.08
		var probe := distance
		var steps := 0
		while probe > min_d and steps < 12:
			var p := eye - forward * probe
			if not _solid_at(p):
				break
			probe -= 0.4
			steps += 1
		_boom_distance = probe
	var d: float = minf(_boom_distance, distance)
	var target := eye - forward * d
	target.y = maxf(target.y, 0.5)
	# when the boom cannot fit (the player is against a wall) fall back to a
	# first-person style view instead of showing the inside of a building
	if d <= min_d + 0.01:
		target = global_position + Vector3(0, 1.62, 0) - forward * 0.25
		if _visual:
			_visual.visible = false
	elif _visual:
		_visual.visible = true
	camera.global_position = camera.global_position.lerp(target, minf(1.0, delta * float(tuning.get("camera_lerp", 10.0))))
	camera.look_at(global_position + Vector3(0, float(tuning.get("camera_look_height", 1.35)), 0), Vector3.UP)


func _solid_at(p: Vector3) -> bool:
	## The boom must not be blocked by the player's own capsule.
	var params := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 1.9, 0), p)
	params.exclude = [get_rid()]
	params.hit_from_inside = false
	for hit in get_world_3d().direct_space_state.intersect_ray(params):
		return true
	return false


func snap_camera() -> void:
	## Place the camera immediately (used after a teleport and in check mode).
	if camera == null:
		return
	_boom_distance = -1.0
	_boom_timer = 0.0
	var forward := Vector3(sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch))
	var eye := global_position + Vector3(0, float(tuning.get("camera_height", 1.5)), 0)
	camera.global_position = eye - forward * float(tuning.get("camera_distance", 5.4))
	camera.look_at(global_position + Vector3(0, float(tuning.get("camera_look_height", 1.35)), 0), Vector3.UP)


func teleport_to_plan(px: float, py: float) -> void:
	var w := Campus.map_to_world(Vector2(px, py))
	global_position = Vector3(w.x, 0.1, w.z)
	velocity = Vector3.ZERO
	snap_camera()


func face_towards(target: Vector3) -> void:
	var d := target - global_position
	yaw = atan2(d.x, d.z)
