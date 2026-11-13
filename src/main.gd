extends Node
## Root of the game. Builds the environment, the campus, the player, the NPCs
## and the HUD; runs the Day 1 mission.
##
##   godot --path <project>                 -> normal run (front end -> campus)
##   godot --path <project> -- --check      -> scripted verification tour with
##                                             screenshots (see --check below)

const PLAYER_SCRIPT := preload("res://src/actors/player.gd")
const NPC_SCRIPT := preload("res://src/actors/npc.gd")
const CAMPUS_SCRIPT := preload("res://src/world/campus_builder.gd")
const HUD_SCRIPT := preload("res://src/ui/hud.gd")
const MENU_SCRIPT := preload("res://src/ui/main_menu.gd")
const TOUCH_SCRIPT := preload("res://src/ui/touch_controls.gd")
const SKY3D_SCRIPT := preload("res://addons/sky_3d/src/Sky3D.gd")
const ADMIN_OFFICE_SCRIPT := preload("res://src/world/admin_office.gd")

var world: Node3D
var campus: Node3D
var admin_office: AdminOffice
var player: CharacterBody3D
var hud: CanvasLayer
var menu: CanvasLayer
var touch_controls: CanvasLayer
var npcs: Array = []
var mission_marker: Node3D
var marker_target: Node3D = null
var marker_pulse: MeshInstance3D = null
var in_office: bool = false
var _marker_time: float = 0.0
var _check_mode: bool = false
var _beauty_mode: bool = false
var _menu_shot_mode: bool = false
var _touch_mode: bool = false
var _mobile_gpu: bool = false
var _check_report: Array = []
var _sun: DirectionalLight3D = null
var _shadow_frame: int = 0
var _low_fps_time: float = 0.0
var _quality_step: int = 0


func _ready() -> void:
	Engine.max_fps = 60
	_mobile_gpu = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
	_check_mode = OS.get_cmdline_user_args().has("--check")
	_beauty_mode = OS.get_cmdline_user_args().has("--beauty")
	_menu_shot_mode = OS.get_cmdline_user_args().has("--menu-shot")
	# Desktop screenshots stay clean; `--touch-preview` forces the phone layout.
	_touch_mode = Settings.is_touch_mode() if Settings else false
	if (_check_mode or _beauty_mode) and not OS.get_cmdline_user_args().has("--touch-preview"):
		_touch_mode = false
	_apply_mobile_quality()
	_build_environment()
	menu = CanvasLayer.new()
	menu.set_script(MENU_SCRIPT)
	add_child(menu)
	menu.start_requested.connect(_on_start)
	if _check_mode:
		_run_check()
	elif _beauty_mode:
		_run_beauty()
	elif _menu_shot_mode:
		_run_menu_shots()


func _apply_mobile_quality() -> void:
	## 60 fps target: render 3D below native and skip AA, on phones and on
	## integrated laptop GPUs alike. Phones start lower and can step down further
	## through `_adaptive_quality()`.
	var viewport := get_viewport()
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	viewport.scaling_3d_scale = 0.78 if _mobile_gpu else 0.88
	Engine.max_fps = 60


func _build_environment() -> void:
	## Sky3D (downloaded asset) replaces the old procedural sky: it owns the
	## sky dome, atmosphere, clouds, sun, moon and time of day. Time is frozen
	## at the web build's morning look and only the visual side is used.
	var sky3d := SKY3D_SCRIPT.new() as Sky3D
	sky3d.name = "WorldEnvironment"
	add_child(sky3d)

	sky3d.game_time_enabled = false
	sky3d.editor_time_enabled = false
	sky3d.current_time = 9.35
	sky3d.sky_contribution = 0.42
	sky3d.ambient_energy = 0.48
	sky3d.sun_energy = 1.18
	sky3d.skydome_energy = 0.78
	sky3d.cloud_intensity = 0.72
	sky3d.wind_speed = 4.6
	sky3d.wind_direction = deg_to_rad(118.0)
	sky3d.fog_enabled = true

	var dome := sky3d.sky
	if dome:
		dome.atm_sun_intensity = 16.0
		dome.atm_darkness = 0.42
		dome.atm_thickness = 0.62
		dome.atm_mie = 0.035
		dome.atm_day_tint = Color(0.62, 0.82, 1.0)
		dome.ground_color = Color(0.20, 0.34, 0.14)
		dome.cirrus_coverage = 0.36
		dome.cirrus_intensity = 1.2
		dome.cumulus_coverage = 0.36
		dome.cumulus_thickness = 0.02
		dome.fog_density = 0.00035
		dome.fog_start = 150.0
		dome.fog_end = 760.0
		dome.fog_falloff = 2.1
		dome.sun_light_color = Color.html("#fff1d6")
		dome.sun_horizon_light_color = Color.html("#ffb877")

	var e := sky3d.environment
	if e:
		e.background_mode = Environment.BG_SKY
		e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		e.ambient_light_sky_contribution = 0.48
		e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		e.tonemap_mode = Environment.TONE_MAPPER_ACES
		e.tonemap_exposure = 0.88
		e.tonemap_white = 1.6
		e.glow_enabled = true
		e.glow_intensity = 0.14
		e.glow_bloom = 0.03
		e.glow_hdr_threshold = 1.25
		# Sky3D draws its own screen-space atmospheric fog.
		e.fog_enabled = false

	var sun := sky3d.sun
	if sun:
		sun.shadow_enabled = true
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		sun.directional_shadow_max_distance = 112.0
		sun.shadow_bias = 0.0008
		sun.shadow_blur = 0.9
		_sun = sun

	if _mobile_gpu:
		if dome:
			dome.cumulus_coverage = 0.0
			dome.cirrus_coverage = 0.28
			dome.fog_end = 520.0
		if e:
			e.glow_enabled = false
		if sun:
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			sun.directional_shadow_max_distance = 92.0
			sun.shadow_blur = 0.8

func _on_start(profile: Dictionary) -> void:
	GameState.profile = profile
	GameState.is_girl = profile.get("char", "boy") == "girl"
	GameState.uniform_year = int(profile.get("year", 2024))
	_build_campus()
	_build_player()
	_build_npcs()
	_build_hud()
	# The level grid starts any unlocked day; Day 1 is the tutorial.
	GameState.current_day = clampi(int(profile.get("day", 1)), 1, GameState.MAX_DAYS)
	Mission.start_day(GameState.current_day)
	Mission.step_changed.connect(_on_step_changed)
	Dialogue.line_shown.connect(_on_line)
	Dialogue.dialogue_started.connect(_on_dialogue_started)
	Dialogue.dialogue_ended.connect(_on_dialogue_ended)
	EventBus.notification.connect(_on_notification)
	_on_step_changed(0, Mission.steps.size(), str(Mission.current().get("text", "")))


func _build_campus() -> void:
	world = Node3D.new()
	world.name = "World"
	add_child(world)
	campus = Node3D.new()
	campus.set_script(CAMPUS_SCRIPT)
	world.add_child(campus)
	campus.build(CampusDB.campus)
	admin_office = ADMIN_OFFICE_SCRIPT.new()
	admin_office.name = "AdminOffice"
	world.add_child(admin_office)
	admin_office.build()
	var admin_building: Dictionary = CampusDB.building_by_name("ADMIN BLOCK")
	if not admin_building.is_empty():
		var r: Array = admin_building.get("rect", [0, 0, 1, 1])
		var admin_centre := Campus.map_to_world(Vector2((r[0] + r[2]) * 0.5, (r[1] + r[3]) * 0.5))
		var k := OriginalModels.scale_for("admin",
			Vector2(r[2] - r[0], r[3] - r[1]))
		admin_office.build_hall_door(Vector3(admin_centre.x, 0.0, admin_centre.y), k)
	mission_marker = Node3D.new()
	mission_marker.name = "MissionMarker"
	mission_marker.position.y = 0.09
	world.add_child(mission_marker)
	# flat yellow disc + ring on the ground, like the web build's marker
	var disc := MeshInstance3D.new()
	disc.name = "MarkerDisc"
	disc.mesh = _marker_disc_mesh(1.05)
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(1.0, 0.82, 0.22, 0.46)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.cull_mode = BaseMaterial3D.CULL_DISABLED
	dm.disable_receive_shadows = true
	disc.material_override = dm
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mission_marker.add_child(disc)
	var rim := MeshInstance3D.new()
	rim.name = "MarkerRim"
	rim.mesh = _marker_ring_mesh(1.05, 1.35)
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(1.0, 0.76, 0.12, 0.95)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.cull_mode = BaseMaterial3D.CULL_DISABLED
	rm.disable_receive_shadows = true
	rim.material_override = rm
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mission_marker.add_child(rim)
	# a small floating diamond so the marker reads from a distance
	var diamond := MeshInstance3D.new()
	diamond.name = "MarkerDiamond"
	var dm_mesh := BoxMesh.new()
	dm_mesh.size = Vector3(0.3, 0.3, 0.3)
	diamond.mesh = dm_mesh
	diamond.rotation_degrees = Vector3(0, 45, 45)
	diamond.position.y = 1.75
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(1.0, 0.82, 0.22)
	dmat.emission_enabled = true
	dmat.emission = Color(1.0, 0.78, 0.18)
	dmat.emission_energy_multiplier = 1.4
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	diamond.material_override = dmat
	diamond.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mission_marker.add_child(diamond)
	marker_pulse = diamond


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.set_script(PLAYER_SCRIPT)
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	player.add_child(cam)
	world.add_child(player)
	var spawn: Array = CampusDB.campus.get("spawn", {}).get("pos", [350, 1000])
	player.teleport_to_plan(spawn[0], spawn[1])
	player.yaw = PI


func _build_npcs() -> void:
	for data in CampusDB.npc_list:
		var npc := Node3D.new()
		npc.set_script(NPC_SCRIPT)
		world.add_child(npc)
		npc.setup(data)
		# Ms. Laksmi works inside the sealed Admin Office, behind her desk.
		if npc.npc_id == "clerk" and admin_office:
			npc.place_at(admin_office.laksmi_seat, 0.0)
		npcs.append(npc)


func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.set_script(HUD_SCRIPT)
	hud.set("touch_mode_override", 1 if _touch_mode else 0)
	add_child(hud)
	hud.update_wallet(GameState.wallet, GameState.bank)
	hud.update_energy(GameState.energy)
	if _touch_mode:
		_build_touch_controls()


func _build_touch_controls() -> void:
	touch_controls = CanvasLayer.new()
	touch_controls.set_script(TOUCH_SCRIPT)
	add_child(touch_controls)
	touch_controls.move_changed.connect(_on_touch_move)
	touch_controls.look_dragged.connect(_on_touch_look)
	touch_controls.run_changed.connect(_on_touch_run)
	touch_controls.interact_pressed.connect(_interact)
	touch_controls.salute_pressed.connect(_salute)
	touch_controls.tapped.connect(_on_touch_tap)


func _on_touch_move(value: Vector2) -> void:
	if player:
		player.touch_move = value


func _on_touch_look(relative: Vector2) -> void:
	if player:
		player.add_touch_look(relative)


func _on_touch_run(running: bool) -> void:
	if player:
		player.touch_run = running


func _on_touch_tap() -> void:
	if Dialogue.active:
		Dialogue.skip()


func _on_step_changed(index: int, total: int, text: String) -> void:
	if hud:
		hud.set_mission(index, total, text)
	if campus and campus.has_method("set_gate_open"):
		## The gate swings open once the guard has been spoken to (step 1+).
		campus.set_gate_open(index >= 1)
	_update_marker()


func _update_marker() -> void:
	if mission_marker == null:
		return
	marker_target = null
	var s := Mission.current()
	if s.is_empty():
		mission_marker.visible = false
		return
	mission_marker.visible = true
	if s.has("pos"):
		var p: Array = s["pos"]
		var w := Campus.map_to_world(Vector2(p[0], p[1]))
		mission_marker.position = Vector3(w.x, 0.09, w.z)
	else:
		var target := _npc_by_id(str(s.get("npc", "")))
		if target:
			if target.npc_id == "clerk" and not in_office and admin_office:
				# Point at the Admin hall door, not at Laksmi inside the sealed room.
				var door := admin_office.hall_door_pos
				mission_marker.position = Vector3(door.x, 0.09, door.z)
			else:
				marker_target = target
				mission_marker.position = Vector3(target.global_position.x, 0.09,
					target.global_position.z)
		else:
			mission_marker.visible = false


func _npc_by_id(npc_id: String) -> Node3D:
	for n in npcs:
		if (n as Node3D).npc_id == npc_id:
			return n
	return null


func _enter_office() -> void:
	if admin_office == null or player == null:
		return
	in_office = true
	player.global_position = admin_office.entry_pos
	player.velocity = Vector3.ZERO
	player.yaw = PI
	player.pitch = 0.20
	# The waiting room is only 10 m deep, so use a shorter dialogue-style boom
	# that stays inside the room instead of clipping through the south wall.
	player.camera_distance_override = 3.1
	player.snap_camera()
	_update_marker()
	if hud and not _check_mode:
		hud.toast("Admin Office - waiting room. Ms. Laksmi is at her desk.", 2.6)


func _exit_office() -> void:
	if admin_office == null or player == null:
		return
	in_office = false
	player.global_position = admin_office.hall_return_pos
	player.velocity = Vector3.ZERO
	player.yaw = PI * 0.5
	player.pitch = 0.24
	player.camera_distance_override = 0.0
	player.snap_camera()
	_update_marker()


func _marker_disc_mesh(radius: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 40
	for i in segments:
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		var p0 := Vector3(cos(a0) * radius, 0.0, sin(a0) * radius)
		var p1 := Vector3(cos(a1) * radius, 0.0, sin(a1) * radius)
		for v in [Vector3.ZERO, p1, p0]:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(v.x, v.z) * 0.2)
			st.add_vertex(v)
	return st.commit()


func _marker_ring_mesh(inner: float, outer: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 40
	for i in segments:
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		var i0 := Vector3(cos(a0) * inner, 0.0, sin(a0) * inner)
		var i1 := Vector3(cos(a1) * inner, 0.0, sin(a1) * inner)
		var o0 := Vector3(cos(a0) * outer, 0.0, sin(a0) * outer)
		var o1 := Vector3(cos(a1) * outer, 0.0, sin(a1) * outer)
		for tri in [[i0, o0, o1], [i0, o1, i1]]:
			for v in tri:
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(v.x, v.z) * 0.2)
				st.add_vertex(v)
	return st.commit()


func _on_dialogue_started(speaker: String) -> void:
	if player:
		player.input_enabled = false
		player.set_talking(true)
		player.touch_move = Vector2.ZERO
		player.touch_run = false
	var npc := _npc_by_id(Dialogue.speaker_key)
	if npc:
		npc.set_talking(true)
		if player:
			npc.face_towards(player.global_position)
	if hud:
		hud.set_prompt("")


func _on_line(speaker: String, text: String, telugu := "") -> void:
	if hud:
		hud.show_dialogue(speaker, text)
		var use_telugu := Settings.is_telugu() if Settings else false
		hud.show_subtitle(telugu if (use_telugu and telugu != "") else text)


func _on_dialogue_ended() -> void:
	if hud:
		hud.hide_dialogue()
		hud.show_subtitle("")
	if player:
		player.input_enabled = true
		player.set_talking(false)
		player.touch_move = Vector2.ZERO
		player.touch_run = false
	var npc := _npc_by_id(Dialogue.speaker_key)
	if npc:
		npc.set_talking(false)


func _on_notification(text: String, seconds: float) -> void:
	if hud:
		hud.toast(text, seconds)


func _process(delta: float) -> void:
	if player == null or hud == null:
		return
	hud.update_player_marker(player.global_position)
	Mission.notify_position(player.global_position)
	_update_prompt()
	_marker_time += delta
	if mission_marker and mission_marker.visible:
		if marker_target and is_instance_valid(marker_target):
			mission_marker.position.x = marker_target.global_position.x
			mission_marker.position.z = marker_target.global_position.z
		var pulse := 1.0 + sin(_marker_time * 2.4) * 0.045
		var marker_scale := 0.58 if in_office else 1.0
		mission_marker.scale = Vector3(pulse * marker_scale, marker_scale, pulse * marker_scale)
		if marker_pulse:
			marker_pulse.rotation.y += delta * 1.8
			marker_pulse.position.y = 1.75 + sin(_marker_time * 2.0) * 0.12
	_adaptive_quality(delta)

## The frame rate is watched on every platform: if the device cannot hold 55 fps
## the 3D resolution and then the sun shadows are reduced automatically, so the
## game keeps a smooth 60 fps target on mid-range laptops and phones alike.
func _adaptive_quality(delta: float) -> void:
	var fps := Engine.get_frames_per_second()
	if fps <= 0:
		return
	if fps < 58.0:
		_low_fps_time += delta
		if _low_fps_time > 3.0:
			_low_fps_time = 0.0
			_degrade_quality()
	else:
		_low_fps_time = 0.0


func _degrade_quality() -> void:
	_quality_step += 1
	var viewport := get_viewport()
	match _quality_step:
		1:
			viewport.scaling_3d_scale = 0.68 if _mobile_gpu else 0.78
			if _sun:
				_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
				_sun.directional_shadow_max_distance = 62.0
				_sun.shadow_blur = 0.6
		2:
			viewport.scaling_3d_scale = 0.58 if _mobile_gpu else 0.68
			if _sun:
				_sun.shadow_enabled = false
		3:
			viewport.scaling_3d_scale = 0.50 if _mobile_gpu else 0.60
			print("  [quality] stepped down to level 3 (fps safety)")


func _update_prompt() -> void:
	if player == null or hud == null:
		return
	if Dialogue.active:
		hud.set_prompt("")
		return
	if in_office and player.global_position.distance_to(admin_office.exit_pos) < 2.4:
		hud.set_prompt("Leave the Admin Office")
		return
	if player.interact_target != null and player.interact_target.is_in_group("admin_office_door"):
		hud.set_prompt("Enter the Admin Office")
		return
	if player.dialogue_nearby != null:
		hud.set_prompt("Talk to %s" % str(player.dialogue_nearby.get("display_name")))
	elif player.interact_target != null:
		hud.set_prompt("Use vending machine")
	else:
		hud.set_prompt("")


func _unhandled_input(event: InputEvent) -> void:
	if player == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_E:
				_interact()
			KEY_G:
				_salute()
			KEY_ESCAPE:
				if Dialogue.active:
					Dialogue.skip()
		if event.keycode == KEY_E and Dialogue.active:
			Dialogue.skip()


func _interact() -> void:
	if Dialogue.active:
		Dialogue.skip()
		return
	if player == null:
		return
	if in_office and admin_office \
			and player.global_position.distance_to(admin_office.exit_pos) < 2.4:
		_exit_office()
		return
	if player.interact_target != null \
			and player.interact_target.is_in_group("admin_office_door"):
		_enter_office()
		return
	if player.dialogue_nearby == null:
		var dbg := ""
		if player:
			var plan := Campus.world_to_map(player.global_position)
			dbg = " pos=%s input_enabled=%s" % [str(plan.round()), str(player.input_enabled)]
			for n in get_tree().get_nodes_in_group("npcs"):
				var nn := n as Node3D
				if nn and nn.npc_id in ["clerk", "prof", "suresh", "arjun", "colonel"]:
					dbg += " [%s wp=%s d=%.1f]" % [nn.npc_id, str(nn.global_position.round()), player.global_position.distance_to(nn.global_position)]
			dbg += " player_wp=" + str(player.global_position.round())
		print("  [interact] no npc nearby" + dbg)
		return
	var npc := player.dialogue_nearby as Node3D
	var step := Mission.current()
	var key := str(step.get("line", "")) if str(step.get("npc", "")) == npc.npc_id else ""
	var lines: Array = npc.lines_for(key) if key != "" else npc.idle_lines()
	if lines.is_empty():
		lines = ["..."]
	Dialogue.start(npc.display_name, lines, npc.npc_id)
	player.face_towards(npc.global_position)
	var advanced := Mission.notify_talked_to(npc.npc_id)
	print("  [interact] %s | step npc=%s | advanced=%s | step=%d" % [npc.npc_id, str(step.get("npc", "")), str(advanced), Mission.index])
	if advanced:
		_update_marker()


func _salute() -> void:
	if player == null:
		return
	player.play_salute()
	var step := Mission.current()
	var colonel := _npc_by_id("colonel")
	var near_parade := colonel != null \
		and player.global_position.distance_to(colonel.global_position) < 20.0
	if str(step.get("type", "")) == "salute" or near_parade:
		if colonel:
			colonel.play_salute()
		var delay := 0.0
		for n in npcs:
			if str(n.group_name) == "cadet":
				n.play_salute(delay)
				delay += 0.11
		# The whole company answers with the original "Jai Hind!" chorus.
		if VoiceBank:
			VoiceBank.play_chorus(player.global_position)
	if str(step.get("type", "")) == "salute":
		if Mission.notify_salute():
			if hud:
				hud.toast("The NCC company returns your salute. Jai Hind!", 3.0)
			_update_marker()


# ------------------------------------------------------------------ check mode

func _run_check() -> void:
	## Scripted verification tour: build the campus, walk the Day 1 route,
	## capture screenshots and print a report.
	await get_tree().process_frame
	GameState.profile = {"name": "Mike", "char": "boy", "year": 2024}
	if menu:
		menu.visible = false
	_build_campus()
	_build_player()
	_build_npcs()
	_build_hud()
	Mission.start_day(1)
	Mission.step_changed.connect(_on_step_changed)
	Dialogue.line_shown.connect(_on_line)
	Dialogue.dialogue_started.connect(_on_dialogue_started)
	Dialogue.dialogue_ended.connect(_on_dialogue_ended)
	_on_step_changed(0, Mission.steps.size(), str(Mission.current().get("text", "")))
	_check_report.append("campus built: %d buildings, %d npcs" % [CampusDB.building_list.size(), npcs.size()])

	var out_dir := "res://docs/screenshots/godot"
	DirAccess.make_dir_recursive_absolute(out_dir)

	# 1 - the spawn outside the main gate
	await _shot("%s/01_spawn_gate.png" % out_dir)

	# 2 - walk up to the gate and talk to the guard
	await _teleport_near("guard")
	print("CHECK guard npc=", _npc_by_id("guard").global_position,
		" player=", player.global_position,
		" marker=", mission_marker.global_position,
		" marker_visible=", mission_marker.visible)
	await _shot("%s/02_guard.png" % out_dir)
	_interact()
	await get_tree().create_timer(0.4).timeout
	_check_report.append("guard dialogue started: %s" % str(Dialogue.active))
	await _await_dialogue()
	_check_report.append("mission step after guard: %d" % Mission.index)

	# 3 - walk through the main gate (the 'at' objective) and on to the Admin Block
	_teleport_plan(122, 396)
	await get_tree().process_frame
	await get_tree().process_frame
	_check_report.append("mission step after the gate: %d" % Mission.index)
	await _teleport_near("clerk")
	await _shot("%s/03_admin.png" % out_dir)
	_interact()
	await get_tree().create_timer(0.4).timeout
	await _await_dialogue()
	_check_report.append("mission step now: %d" % Mission.index)

	# 4 - the CSE block
	await _teleport_near("prof")
	await _shot("%s/04_cse.png" % out_dir)
	_interact()
	await get_tree().create_timer(0.4).timeout
	await _await_dialogue()
	_check_report.append("mission step now: %d" % Mission.index)

	# 5 - the IT block
	await _teleport_near("suresh")
	await _shot("%s/05_it.png" % out_dir)
	_interact()
	await get_tree().create_timer(0.4).timeout
	await _await_dialogue()
	_check_report.append("mission step now: %d" % Mission.index)

	# 6 - the canteen
	await _teleport_near("arjun")
	await _shot("%s/06_canteen.png" % out_dir)
	_interact()
	await get_tree().create_timer(0.4).timeout
	await _await_dialogue()
	_check_report.append("mission step now: %d" % Mission.index)

	# 7 - the parade ground + salute
	await _teleport_near("colonel")
	await _shot("%s/07_parade_ground.png" % out_dir)
	_salute()
	await get_tree().create_timer(0.4).timeout
	_check_report.append("mission step after salute: %d" % Mission.index)

	# 8 - the colonel
	_interact()
	await get_tree().create_timer(0.6).timeout
	await _shot("%s/08_colonel.png" % out_dir)
	await _await_dialogue()
	_check_report.append("day 1 finished: %s" % str(Mission.finished))

	# 9 - an overview of the whole campus (camera detached from the player rig)
	player.set_physics_process(false)
	var env_node := get_node_or_null("WorldEnvironment")
	var env_res: Environment = env_node.environment if env_node else null
	if env_res:
		env_res.fog_enabled = false
	if env_node:
		env_node.set("fog_enabled", false)
	player.camera.global_position = Vector3(0.0, 165.0, 210.0)
	player.camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	await get_tree().process_frame
	await get_tree().process_frame
	await _shot("%s/09_campus_overview.png" % out_dir)

	# 10 - a top-down plan view
	if env_res:
		env_res.fog_enabled = false
	player.camera.global_position = Vector3(0.0, 260.0, 2.0)
	player.camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	await get_tree().process_frame
	await _shot("%s/10_campus_plan.png" % out_dir)

	print("\n=== ANITS GODOT CHECK ===")
	for line in _check_report:
		print("  " + str(line))
	print("=== END CHECK ===\n")
	get_tree().quit(0)


func _teleport_plan(px: float, py: float) -> void:
	player.teleport_to_plan(px, py)
	player.snap_camera()

func _teleport_near(npc_id: String) -> void:
	if npc_id == "clerk" and admin_office:
		_enter_office()
		# Step to the side of the glass doors so Laksmi is visible, and let the
		# sliding doors finish opening before the screenshot.
		player.global_position = admin_office.laksmi_seat + Vector3(-0.7, 0.12, 2.9)
		player.face_towards(admin_office.laksmi_seat)
		player.snap_camera()
		await get_tree().create_timer(0.55).timeout
		await get_tree().process_frame
		return
	in_office = false
	player.camera_distance_override = 0.0
	var npc := _npc_by_id(npc_id)
	if npc == null:
		return
	var spot: Vector3
	if npc_id == "guard":
		# Stand to the guard's side so he is not hidden by the player model.
		spot = npc.global_position + Vector3(-2.1, 0.1, 2.2)
	elif npc_id == "colonel":
		# The cadet company stands west of the colonel; approach from the east
		# and look west so the whole formation is in frame instead of filling
		# the camera with the backs of two cadet heads.
		spot = npc.global_position + Vector3(3.1, 0.1, 0.7)
	else:
		# Stand in front of the NPC, using their authored facing. This keeps the
		# camera boom on the road instead of inside the nearest building facade.
		var forward := Vector3(sin(npc.base_facing), 0.0, cos(npc.base_facing))
		spot = npc.global_position + forward * 2.4
		spot.y = 0.1
		if _inside_building(Campus.world_to_map(spot), CampusDB.campus, 1.0):
			spot = _free_spot_near(npc)
	player.global_position = spot
	player.face_towards(npc.global_position)
	player.snap_camera()
	await get_tree().process_frame
	await get_tree().process_frame


## Finds a standable spot next to an NPC (clear of buildings and walls).
func _free_spot_near(npc: Node3D) -> Vector3:
	var plan := Campus.world_to_map(npc.global_position)
	var campus: Dictionary = CampusDB.campus
	var directions := [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0),
		Vector2(-0.7, -0.7), Vector2(0.7, -0.7), Vector2(-0.7, 0.7), Vector2(0.7, 0.7)]
	var margin_px := 1.5 / Campus.MAP_SCALE
	for radius_m in [2.6, 3.6, 4.6, 6.0, 8.0]:
		for dir in directions:
			var candidate: Vector2 = plan + dir * (radius_m / Campus.MAP_SCALE)
			if not _inside_building(candidate, campus, margin_px):
				var w := Campus.map_to_world(candidate)
				return Vector3(w.x, 0.1, w.z)
	return npc.global_position


func _inside_building(plan: Vector2, campus: Dictionary, margin := 2.0) -> bool:
	for b in campus.get("buildings", []):
		var r: Array = b.get("rect", [])
		if plan.x > r[0] - margin and plan.x < r[2] + margin and plan.y > r[1] - margin and plan.y < r[3] + margin:
			return true
	return false


func _await_dialogue() -> void:
	## Wait for the dialogue to finish (capped, then force-ended so the tour keeps moving).
	var waited := 0.0
	while Dialogue.active and waited < 1.5:
		await get_tree().process_frame
		waited += get_process_delta_time()
	if Dialogue.active:
		Dialogue.active = false
		Dialogue.dialogue_ended.emit()
	await get_tree().process_frame


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("  shot: " + path)


# ------------------------------------------------------------------ beauty mode

func _run_menu_shots() -> void:
	## Captures the front end screens for the report.
	await get_tree().create_timer(0.8).timeout
	var out_dir := "res://docs/screenshots/godot"
	DirAccess.make_dir_recursive_absolute(out_dir)
	await _shot("%s/menu_year.png" % out_dir)
	if menu and menu.has_method("show_character"):
		menu.show_character()
		await get_tree().create_timer(0.9).timeout
		await _shot("%s/menu_character.png" % out_dir)
	if menu and menu.has_method("show_name"):
		menu.show_name()
		await get_tree().create_timer(0.5).timeout
		await _shot("%s/menu_name.png" % out_dir)
	if menu and menu.has_method("show_main"):
		menu.show_main()
		await get_tree().create_timer(0.7).timeout
		await _shot("%s/menu_main.png" % out_dir)
	if menu and menu.has_method("show_levels"):
		menu.show_levels()
		await get_tree().create_timer(0.9).timeout
		await _shot("%s/menu_levels.png" % out_dir)
	print("=== MENU SHOTS DONE ===")
	get_tree().quit(0)


func _run_beauty() -> void:
	## Free-camera screenshot pass used for the report: the same campus, but
	## framed the way a photographer would frame it.
	await get_tree().process_frame
	GameState.profile = {"name": "Mike", "char": "boy", "year": 2024}
	if menu:
		menu.visible = false
	_build_campus()
	_build_player()
	_build_npcs()
	_build_hud()
	Mission.start_day(1)
	var out_dir := "res://docs/screenshots/godot/beauty"
	DirAccess.make_dir_recursive_absolute(out_dir)
	player.set_physics_process(false)
	hud.visible = false
	mission_marker.visible = false

	# 1 - the main gate from the road outside
	await _beauty_shot("01_main_gate.png", Vector2(122, 470), 7.0, Vector2(122, 400), 4.0)
	# 2 - the Admin Block front
	await _beauty_shot("02_admin_block.png", Vector2(163, 352), 13.0, Vector2(163, 318), 7.0)
	# 3 - the CSE block across the central road
	await _beauty_shot("03_cse_block.png", Vector2(128, 268), 8.0, Vector2(152, 264), 6.0)
	# 4 - the IT block along the main road
	await _beauty_shot("04_it_block.png", Vector2(240, 196), 9.0, Vector2(268, 196), 6.0)
	# 5 - the canteen and the Civil blocks
	await _beauty_shot("05_canteen.png", Vector2(272, 133), 7.0, Vector2(292, 128), 4.0)
	# 6 - the NCC ground with the open auditorium pavilion
	await _beauty_shot("06_ncc_ground.png", Vector2(212, 424), 9.0, Vector2(236, 398), 5.0)
	# 7 - the basketball court
	await _beauty_shot("07_basketball.png", Vector2(300, 305), 11.0, Vector2(300, 282), 3.0)
	# 8 - the temple and the central lawn
	await _beauty_shot("08_temple.png", Vector2(96, 341), 7.0, Vector2(112, 340), 4.0)
	# 9 - the back gate
	await _beauty_shot("09_back_gate.png", Vector2(236, 74), 8.0, Vector2(236, 98), 5.0)
	# 10 - the whole campus from the air
	await _beauty_shot("10_campus_aerial.png", Vector2(215, 560), 205.0, Vector2(215, 250), 0.0)
	# 11 - the perimeter road and the boundary wall
	await _beauty_shot("11_perimeter.png", Vector2(46, 240), 10.0, Vector2(66, 240), 4.0)

	# 12 - inside the Admin Office
	if admin_office:
		var seat: Vector3 = admin_office.laksmi_seat
		player.camera.global_position = seat + Vector3(-1.6, 1.75, 3.6)
		player.camera.look_at(seat + Vector3(0.2, 1.25, -1.0), Vector3.UP)
		await get_tree().process_frame
		await _shot("%s/12_admin_office.png" % out_dir)

	print("=== BEAUTY DONE ===")
	get_tree().quit(0)


func _beauty_shot(file_name: String, cam_plan: Vector2, cam_height: float,
		look_plan: Vector2, look_height: float) -> void:
	var cam: Camera3D = player.camera
	var cw := Campus.map_to_world(cam_plan)
	var lw := Campus.map_to_world(look_plan)
	cam.global_position = Vector3(cw.x, cam_height, cw.z)
	cam.look_at(Vector3(lw.x, look_height, lw.z), Vector3.UP)
	cam.fov = 55.0
	await get_tree().process_frame
	await get_tree().process_frame
	await _shot("res://docs/screenshots/godot/beauty/" + file_name)
