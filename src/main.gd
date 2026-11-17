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
const LIBRARY_SCRIPT := preload("res://src/world/library_interior.gd")
const CLASSROOM_SCRIPT := preload("res://src/world/classroom_interior.gd")
const CANTEEN_SCRIPT := preload("res://src/world/canteen_interior.gd")
const MINIGAME_SCRIPT := preload("res://src/ui/minigame_overlay.gd")
const INVENTORY_SCRIPT := preload("res://src/ui/inventory_panel.gd")
const LEVEL_COMPLETE_SCRIPT := preload("res://src/ui/level_complete_dialog.gd")

var world: Node3D
var campus: Node3D
var admin_office: AdminOffice
var library_interior: LibraryInterior
var classroom_interior: ClassroomInterior
var canteen_interior: CanteenInterior
## Room contents are hidden while the player is outside, so the four dressed
## interiors (1326 meshes, 20 lights) cost nothing during normal play.
var admin_room: Node3D
var library_room: Node3D
var classroom_room: Node3D
var canteen_room: Node3D
var minigame_overlay: MinigameOverlay
var inventory_panel: InventoryPanel
var level_complete_dialog: LevelCompleteDialog
var atm_kiosk: Node3D
var player: CharacterBody3D
var hud: CanvasLayer
var menu: CanvasLayer
var touch_controls: CanvasLayer
var npcs: Array = []
var mission_marker: Node3D
var marker_target: Node3D = null
var marker_pulse: Label3D = null
var marker_distance_badge: Label3D = null
var _dust_particles: CPUParticles3D = null
var _leaf_particles: CPUParticles3D = null
var in_office: bool = false
var current_interior: String = ""
var _marker_time: float = 0.0
## Cached marker badge text state so `_process` never builds strings per frame.
var _marker_title: String = ""
var _marker_last_dist: int = -1
var _marker_step: int = -1
var _marker_interior: String = ""
var _check_mode: bool = false
var _beauty_mode: bool = false
var _menu_shot_mode: bool = false
var _intro_shot_mode: bool = false
var _flow_shot_mode: bool = false
var _touch_mode: bool = false
var _mobile_gpu: bool = false
## Phone-class rendering profile.  True on a real phone and for the
## `--low-poly` benchmark, so the desktop bench measures the phone build.
var _phone_profile: bool = false
## Reduced-density props: phones, the web GL build and `--low-poly`.
var _low_poly: bool = false
## The Sky3D atmosphere shader is a full-screen raymarch; phones get a
## procedural gradient sky instead (same palette, a fraction of the cost).
var _cheap_sky: bool = false
var _check_report: Array = []
var _sun: DirectionalLight3D = null
var _shadow_frame: int = 0
var _low_fps_time: float = 0.0
var _quality_step: int = 0
var _renderer: String = "forward_plus"
var _post_layer: CanvasLayer = null
var _vignette: ColorRect = null
var _ssao: bool = false
var _env: Environment = null
## Test hook: the benchmark freezes the adaptive quality ladder so every run
## measures the same fixed quality level.
var bench_mode: bool = false


func _ready() -> void:
	Engine.max_fps = 60
	_mobile_gpu = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
	_renderer = RenderingServer.get_current_rendering_method()
	var args := OS.get_cmdline_user_args()
	_check_mode = args.has("--check")
	_beauty_mode = args.has("--beauty") or args.has("--beauty-low")
	_menu_shot_mode = args.has("--menu-shot")
	_intro_shot_mode = args.has("--intro-shot")
	_flow_shot_mode = args.has("--flow-shot")
	# A phone browser reports neither `mobile` nor `android`, so touch input on
	# the web build is the signal that the phone profile is needed there.
	var touch_device := Settings.is_touch_mode() if Settings else false
	# Settings can force the fast or high profile; "auto" picks fast on an
	# integrated laptop GPU, which cannot hold 60 fps with the high profile.
	# Screenshot/bench modes pin their profile so captures stay repeatable.
	var graphics := Settings.graphics_mode if Settings else "auto"
	var force_fast := args.has("--low-poly") or args.has("--beauty-low") \
		or args.has("--quality-fast") or args.has("--bench-profile=mobile")
	var force_high := args.has("--quality-high") or args.has("--bench-profile=desktop") \
		or (_beauty_mode and not args.has("--beauty-low")) \
		or _check_mode or _menu_shot_mode or _intro_shot_mode or _flow_shot_mode
	var fast_graphics := graphics == "fast" \
		or (graphics == "auto" and _renderer == "forward_plus" and _is_integrated_gpu())
	if force_high:
		fast_graphics = false
	if force_fast:
		fast_graphics = true
	_phone_profile = _mobile_gpu or (touch_device and OS.has_feature("web")) or fast_graphics
	_low_poly = _phone_profile or _renderer == "gl_compatibility"
	_cheap_sky = _phone_profile
	# Desktop screenshots stay clean; `--touch-preview` forces the phone layout.
	_touch_mode = Settings.is_touch_mode() if Settings else false
	if (_check_mode or _beauty_mode) and not OS.get_cmdline_user_args().has("--touch-preview"):
		_touch_mode = false
	_apply_mobile_quality()
	# Report screenshots render at full 3D scale with MSAA so the captured
	# frames are crisp; gameplay keeps the 60 fps quality ladder.
	if _check_mode or _beauty_mode:
		var shot_viewport := get_viewport()
		shot_viewport.scaling_3d_scale = 1.0
		shot_viewport.msaa_3d = Viewport.MSAA_4X
	_build_environment()
	_build_post_process()
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
	elif _intro_shot_mode:
		_run_intro_shots()
	elif _flow_shot_mode:
		_run_flow_shot()


## Heuristic for laptop iGPUs. "auto" only applies it on the Forward+ desktop
## renderer; discrete cards keep the high profile and the player can override
## either way in Settings.
func _is_integrated_gpu() -> bool:
	var adapter := RenderingServer.get_video_adapter_name().to_lower()
	if adapter.contains("llvmpipe") or adapter.contains("swiftshader") \
			or adapter.contains("microsoft basic render"):
		return true
	if adapter.contains("intel") and not adapter.contains("arc"):
		return true
	if adapter.contains("radeon") and not adapter.contains("rx ") \
			and not adapter.contains("pro "):
		return true
	return false


func _apply_mobile_quality() -> void:
	## 60 fps target: render 3D below native and skip AA, on phones and on
	## integrated laptop GPUs alike. Phones start lower and can step down further
	## through `_adaptive_quality()`.
	##
	## The web export runs on the GL Compatibility renderer, where FXAA and SSAO
	## do not exist.  There the edges are cleaned with 2x MSAA instead, and the
	## cinematic look comes from the colour grade and the vignette pass, which
	## work on every renderer.
	var viewport := get_viewport()
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	# Phones start at 60% internal resolution and the adaptive ladder can take
	# them to 50%; the web build starts at 78% and desktops at 88%.
	if _phone_profile:
		viewport.scaling_3d_scale = 0.60
	elif _renderer == "gl_compatibility":
		viewport.scaling_3d_scale = 0.78
	else:
		viewport.scaling_3d_scale = 0.88
	if _renderer == "forward_plus":
		# Desktop / the signed APK on a Vulkan-capable phone.
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	elif not _mobile_gpu:
		# Web (GL Compatibility): cheap hardware anti-aliasing.
		viewport.msaa_3d = Viewport.MSAA_2X
	Engine.max_fps = 60


func _build_environment() -> void:
	if _cheap_sky:
		_build_low_poly_environment()
		return
	## Sky3D (downloaded asset) replaces the old procedural sky: it owns the
	## sky dome, atmosphere, clouds, sun, moon and time of day. Time is frozen
	## at the web build's morning look and only the visual side is used.
	var sky3d := SKY3D_SCRIPT.new() as Sky3D
	sky3d.name = "WorldEnvironment"
	add_child(sky3d)

	sky3d.game_time_enabled = false
	sky3d.editor_time_enabled = false
	sky3d.current_time = 9.6
	sky3d.sky_contribution = 0.52
	sky3d.ambient_energy = 0.56
	sky3d.sun_energy = 1.05
	sky3d.skydome_energy = 0.82
	sky3d.cloud_intensity = 0.80
	sky3d.wind_speed = 4.6
	sky3d.wind_direction = deg_to_rad(118.0)
	sky3d.fog_enabled = true

	var dome := sky3d.sky
	if dome:
		dome.atm_sun_intensity = 18.0
		dome.atm_darkness = 0.38
		dome.atm_thickness = 0.55
		dome.atm_mie = 0.028
		dome.atm_day_tint = Color(0.58, 0.80, 1.0)
		dome.ground_color = Color(0.19, 0.33, 0.13)
		dome.cirrus_coverage = 0.42
		dome.cirrus_intensity = 1.25
		dome.cumulus_coverage = 0.42
		dome.cumulus_thickness = 0.02
		dome.fog_density = 0.00024
		dome.fog_start = 190.0
		dome.fog_end = 900.0
		dome.fog_falloff = 2.1
		dome.sun_light_color = Color.html("#fff0d0")
		dome.sun_horizon_light_color = Color.html("#ffb26e")

	var e := sky3d.environment
	if e:
		_env = e
		e.background_mode = Environment.BG_SKY
		e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		e.ambient_light_sky_contribution = 0.52
		e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		e.tonemap_mode = Environment.TONE_MAPPER_ACES
		e.tonemap_exposure = 0.86
		e.tonemap_white = 1.55
		# A warmer, filmic image: rich coastal morning contrast and natural saturation,
		# with bloom picking up sun on car glass, metallic rails and the campus road.
		e.adjustment_enabled = true
		e.adjustment_brightness = 1.02
		e.adjustment_contrast = 1.04
		e.adjustment_saturation = 1.05
		e.glow_enabled = true
		e.glow_intensity = 0.30
		e.glow_bloom = 0.08
		e.glow_hdr_threshold = 1.10
		e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
		# Sky3D draws its own screen-space atmospheric fog.
		e.fog_enabled = false
		# Contact shading around buildings, trees and characters. Forward+ only
		# (desktop / Vulkan); skipped on the Mobile and Compatibility renderers.
		if _renderer == "forward_plus" and not _mobile_gpu:
			e.ssao_enabled = true
			e.ssao_radius = 1.5
			e.ssao_intensity = 1.55
			e.ssao_power = 1.35
			e.ssao_detail = 0.55
			e.ssao_horizon = 0.06
			e.ssao_sharpness = 0.96
			e.ssao_light_affect = 0.18
			_ssao = true
			# Volumetric sun shafts / god rays across campus buildings and trees
			e.volumetric_fog_enabled = true
			e.volumetric_fog_density = 0.0032
			e.volumetric_fog_albedo = Color(1.0, 0.95, 0.88)
			e.volumetric_fog_emission = Color(0.12, 0.10, 0.06)
			e.volumetric_fog_emission_energy = 0.35
			e.volumetric_fog_anisotropy = 0.62
			e.volumetric_fog_length = 160.0
			e.volumetric_fog_ambient_inject = 0.25

	var sun := sky3d.sun
	if sun:
		sun.shadow_enabled = true
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		sun.directional_shadow_max_distance = 128.0
		sun.shadow_bias = 0.0014
		sun.shadow_normal_bias = 1.4
		sun.shadow_blur = 1.5
		if _renderer == "forward_plus" and not _mobile_gpu:
			sun.light_volumetric_fog_energy = 1.45
		_sun = sun

	if _mobile_gpu:
		if dome:
			dome.cumulus_coverage = 0.0
			dome.cirrus_coverage = 0.28
			dome.fog_end = 560.0
		if e:
			e.glow_enabled = false
			e.adjustment_contrast = 1.03
			e.adjustment_saturation = 1.02
		if sun:
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			sun.directional_shadow_max_distance = 92.0
			sun.shadow_blur = 0.9

## Phone-class sky: the same warm morning palette as Sky3D, drawn by Godot's
## procedural sky (a few triangles) instead of the raymarched cloud shader.
## Depth fog replaces the screen-space atmospheric pass and gives the campus
## the same sense of distance for almost nothing.
func _build_low_poly_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#3f7fd6")
	sky_mat.sky_horizon_color = Color("#cfe4f5")
	sky_mat.sky_curve = 0.10
	sky_mat.sky_energy_multiplier = 1.0
	sky_mat.ground_bottom_color = Color("#22331c")
	sky_mat.ground_horizon_color = Color("#9fb08c")
	sky_mat.ground_curve = 0.08
	sky_mat.ground_energy_multiplier = 0.55
	sky_mat.sun_angle_max = 22.0
	sky_mat.sun_curve = 0.12
	sky_mat.use_debanding = false
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	sky.process_mode = Sky.PROCESS_MODE_REALTIME

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.55
	env.ambient_light_energy = 1.05
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.90
	env.tonemap_white = 1.50
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.02
	env.adjustment_contrast = 1.03
	env.adjustment_saturation = 1.06
	env.glow_enabled = false
	env.ssao_enabled = false
	env.volumetric_fog_enabled = false
	env.fog_enabled = true
	env.fog_light_color = Color("#c8dcef")
	env.fog_light_energy = 0.62
	env.fog_sun_scatter = 0.14
	env.fog_density = 0.0018
	env.fog_aerial_perspective = 0.35
	env.fog_sky_affect = 0.12

	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	add_child(we)
	_env = env

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-40.0, 47.1, 0.0)
	sun.light_color = Color(1.0, 0.9412, 0.8157)
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 64.0
	sun.shadow_bias = 0.0016
	sun.shadow_blur = 1.25
	add_child(sun)
	_sun = sun


func _build_post_process() -> void:
	## One cheap full-screen pass over the 3D image: a soft cinematic vignette
	## and a gentle bottom-edge gradient that lifts the HUD and dialogue off the
	## scene.  It is a plain canvas_item shader with no screen texture, so it
	## works identically on Forward+, Mobile and the web GL Compatibility
	## renderer.  The HUD (layer 10) and touch controls (layer 20) stay above it.
	_post_layer = CanvasLayer.new()
	_post_layer.name = "PostProcess"
	_post_layer.layer = 2
	add_child(_post_layer)
	_vignette = ColorRect.new()
	_vignette.name = "Vignette"
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;

uniform float edge_strength = 0.34;
uniform float bottom_strength = 0.20;
uniform vec3 tint : source_color = vec3(0.012, 0.026, 0.055);

void fragment() {
	vec2 uv = UV;
	vec2 p = uv * 2.0 - 1.0;
	// Slightly wider than tall, so the corners darken without eating the
	// centre of the frame.
	float d = length(p * vec2(0.86, 1.0));
	float edge = smoothstep(0.52, 1.38, d);
	float bottom = smoothstep(0.52, 1.02, uv.y);
	float top = smoothstep(0.10, 0.0, uv.y) * 0.35;
	float a = clamp(edge * edge_strength + bottom * bottom_strength + top * 0.10, 0.0, 0.62);
	COLOR = vec4(tint, a);
}
"""
	mat.shader = sh
	if _phone_profile:
		mat.set_shader_parameter("edge_strength", 0.24)
		mat.set_shader_parameter("bottom_strength", 0.15)
	_vignette.material = mat
	_post_layer.add_child(_vignette)

func _on_start(profile: Dictionary) -> void:
	GameState.profile = profile
	GameState.is_girl = profile.get("char", "boy") == "girl"
	GameState.uniform_year = int(profile.get("year", 2024))

	if world == null:
		_build_campus()
		_build_player()
		_build_npcs()
		_build_hud()

		if minigame_overlay == null:
			minigame_overlay = MINIGAME_SCRIPT.new()
			add_child(minigame_overlay)
			minigame_overlay.minigame_completed.connect(_on_minigame_completed)

		if inventory_panel == null:
			inventory_panel = INVENTORY_SCRIPT.new()
			add_child(inventory_panel)
			inventory_panel.id_shown.connect(_on_id_shown)

		if level_complete_dialog == null:
			level_complete_dialog = LEVEL_COMPLETE_SCRIPT.new()
			add_child(level_complete_dialog)
			level_complete_dialog.next_day_requested.connect(_start_next_day)
			level_complete_dialog.menu_requested.connect(_to_main_menu)

		if not Mission.minigame_triggered.is_connected(_on_minigame_triggered):
			Mission.minigame_triggered.connect(_on_minigame_triggered)
		if not Mission.completed.is_connected(_on_mission_completed):
			Mission.completed.connect(_on_mission_completed)
		if not Mission.step_changed.is_connected(_on_step_changed):
			Mission.step_changed.connect(_on_step_changed)
		if not Dialogue.line_shown.is_connected(_on_line):
			Dialogue.line_shown.connect(_on_line)
		if not Dialogue.dialogue_started.is_connected(_on_dialogue_started):
			Dialogue.dialogue_started.connect(_on_dialogue_started)
		if not Dialogue.dialogue_ended.is_connected(_on_dialogue_ended):
			Dialogue.dialogue_ended.connect(_on_dialogue_ended)
		if not EventBus.notification.is_connected(_on_notification):
			EventBus.notification.connect(_on_notification)
	else:
		if hud:
			hud.visible = true
		if player:
			player.teleport_to_plan(122, 448)
			player.input_enabled = true
		current_interior = ""
		in_office = false

	# Gameplay starts here, whether this is a fresh campus build or a return
	# from the main menu, so this is the one place the touch layer appears.
	if _touch_mode and touch_controls:
		touch_controls.visible = true

	# The level grid starts any unlocked day; Day 1 is the tutorial.
	GameState.current_day = clampi(int(profile.get("day", 1)), 1, GameState.MAX_DAYS)
	# Every day after Day 1 opens at the gate ID check. The card is issued on
	# Day 1, but a player who restarts and jumps straight to Day 2 must still
	# have it, otherwise the gate would soft-lock.
	if GameState.current_day >= 2:
		GameState.give_item("id")
	_sync_special_npcs_for_day()
	Mission.start_day(GameState.current_day)
	_on_step_changed(0, Mission.steps.size(), str(Mission.current().get("text", "")))
	# Campus ambience runs under the voice lines for the whole outdoor day.
	if Audio:
		Audio.set_ambience("campus")
	# The menu kept its loading screen up while the campus was built; fade it
	# out now that the first gameplay frame is ready.
	if menu and menu.has_method("dismiss_loading"):
		menu.dismiss_loading()


func _on_minigame_triggered(cfg: Dictionary) -> void:
	if player:
		player.input_enabled = false
	if touch_controls:
		touch_controls.visible = false
	if minigame_overlay:
		minigame_overlay.start_minigame(cfg)


func _on_minigame_completed(won: bool) -> void:
	if player:
		player.input_enabled = true
	if touch_controls:
		touch_controls.visible = true
	if won:
		Mission.notify_minigame_won()
		if hud:
			hud.toast("Challenge Completed! Objective updated.", 3.0)
		_update_marker()


func _on_id_shown() -> void:
	if Mission.current().get("type") == "idcheck":
		Mission.advance()
		if Audio:
			Audio.play("unlock", -10.0)
		if hud:
			hud.toast("Bajirao: \"ID verified! Welcome to ANITS.\" Gate opened.", 3.0)
		_update_marker()


func _on_mission_completed(d: int) -> void:
	if Audio:
		Audio.play("cheer", -9.0)
	if level_complete_dialog:
		level_complete_dialog.show_day_completed(d)


func _start_next_day(next_day: int) -> void:
	GameState.current_day = next_day
	player.teleport_to_plan(122, 448)
	player.snap_camera()
	current_interior = ""
	in_office = false
	_sync_special_npcs_for_day()
	Mission.start_day(next_day)
	_on_step_changed(0, Mission.steps.size(), str(Mission.current().get("text", "")))
	if hud:
		hud.toast("Day %d: %s" % [next_day, Mission.current().get("text", "")], 4.0)


## Wraps everything an interior builds into one child node, so the room can be
## hidden while the player is outside.  The exterior door is added afterwards
## (build_hall_door / build_campus_door), so it stays visible on campus.
func _wrap_interior_room(interior: Node3D, room_name: String) -> Node3D:
	var room := Node3D.new()
	room.name = room_name
	interior.add_child(room)
	for child in interior.get_children():
		if child == room:
			continue
		interior.remove_child(child)
		room.add_child(child)
	room.visible = false
	return room


func _set_room_visible(room: Node3D, value: bool) -> void:
	if room:
		room.visible = value


## Screenshot tours frame the interiors, so they need every room visible.
func _show_all_interiors() -> void:
	for room in [admin_room, library_room, classroom_room, canteen_room]:
		_set_room_visible(room, true)


func _build_campus() -> void:
	world = Node3D.new()
	world.name = "World"
	add_child(world)
	campus = Node3D.new()
	campus.set_script(CAMPUS_SCRIPT)
	world.add_child(campus)
	# Phones (and the GL-Compatibility web build) get the reduced-density,
	# low-poly prop pass.  Desktop Forward+ keeps the full campus; `--low-poly`
	# lets the bench measure the phone density on a desktop GPU.
	campus.low_poly = _low_poly
	campus.build(CampusDB.campus)
	admin_office = ADMIN_OFFICE_SCRIPT.new()
	admin_office.name = "AdminOffice"
	world.add_child(admin_office)
	admin_office.build()
	admin_room = _wrap_interior_room(admin_office, "AdminRoom")
	var admin_building: Dictionary = CampusDB.building_by_name("ADMIN BLOCK")
	if not admin_building.is_empty():
		var r: Array = admin_building.get("rect", [0, 0, 1, 1])
		var admin_centre := Campus.map_to_world(Vector2((r[0] + r[2]) * 0.5, (r[1] + r[3]) * 0.5))
		var k := OriginalModels.scale_for("admin",
			Vector2(r[2] - r[0], r[3] - r[1]))
		admin_office.build_hall_door(Vector3(admin_centre.x, 0.0, admin_centre.z), k)

	# Central Library interior
	library_interior = LIBRARY_SCRIPT.new()
	library_interior.name = "LibraryInterior"
	world.add_child(library_interior)
	library_interior.build()
	library_room = _wrap_interior_room(library_interior, "LibraryRoom")
	var lib_door_pos := Campus.map_to_world(Vector2(99.0, 175.0))
	library_interior.build_campus_door(Vector3(lib_door_pos.x, 0.0, lib_door_pos.z), -PI * 0.5)

	# Room 204 (CSE Lecture Hall) interior
	classroom_interior = CLASSROOM_SCRIPT.new()
	classroom_interior.name = "ClassroomInterior"
	world.add_child(classroom_interior)
	classroom_interior.build()
	classroom_room = _wrap_interior_room(classroom_interior, "ClassroomRoom")
	var room_door_pos := Campus.map_to_world(Vector2(155.0, 263.5))
	classroom_interior.build_campus_door(Vector3(room_door_pos.x, 0.0, room_door_pos.z), PI * 0.5)

	# College Canteen interior
	canteen_interior = CANTEEN_SCRIPT.new()
	canteen_interior.name = "CanteenInterior"
	world.add_child(canteen_interior)
	canteen_interior.build()
	canteen_room = _wrap_interior_room(canteen_interior, "CanteenRoom")
	var can_door_pos := Campus.map_to_world(Vector2(286.0, 126.0))
	canteen_interior.build_campus_door(Vector3(can_door_pos.x, 0.0, can_door_pos.z), -PI * 0.5)

	# Bank ATM kiosk on east wall of Bank building
	var atm_pos := Campus.map_to_world(Vector2(81.0, 408.0))
	atm_kiosk = Node3D.new()
	atm_kiosk.name = "BankATM"
	atm_kiosk.position = Vector3(atm_pos.x, 0.0, atm_pos.z)
	world.add_child(atm_kiosk)

	var atm_mat := CampusBuilder.mat(Color("#1d428a"), 0.4)
	var white_mat := CampusBuilder.mat(Color("#ffffff"), 0.3)
	CampusBuilder.box(atm_kiosk, Vector3(0.9, 2.1, 0.7), Vector3(0, 1.05, 0), atm_mat, "ATMBody")
	CampusBuilder.add_collider(atm_kiosk, Vector3(0.9, 2.1, 0.7), Vector3(0, 0, 0), "ATMCol")

	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color("#00a4e4")
	screen_mat.emission_enabled = true
	screen_mat.emission = Color("#00a4e4")
	screen_mat.emission_energy_multiplier = 0.8
	CampusBuilder.box(atm_kiosk, Vector3(0.5, 0.35, 0.05), Vector3(0.36, 1.45, 0), screen_mat, "ATMScreen")
	CampusBuilder.box(atm_kiosk, Vector3(0.35, 0.15, 0.1), Vector3(0.36, 1.15, 0), white_mat, "Keypad")

	var atm_lbl := Label3D.new()
	atm_lbl.text = "24/7 ATM"
	atm_lbl.font_size = 20
	atm_lbl.modulate = Color("#ffd54a")
	atm_lbl.position = Vector3(0.36, 1.85, 0)
	atm_lbl.rotation.y = PI * 0.5
	atm_kiosk.add_child(atm_lbl)

	atm_kiosk.add_to_group("interactables")
	atm_kiosk.add_to_group("atm")
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
	# a floating gold "!" so the objective reads from anywhere on the campus
	var exclaim := Label3D.new()
	exclaim.name = "MarkerExclaim"
	exclaim.text = "!"
	exclaim.font_size = 96
	exclaim.outline_size = 18
	exclaim.pixel_size = 0.0075
	exclaim.modulate = Color(1.0, 0.83, 0.24)
	exclaim.outline_modulate = Color(0.36, 0.22, 0.02, 0.95)
	exclaim.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	exclaim.no_depth_test = true
	exclaim.render_priority = 20
	exclaim.position.y = 2.55
	exclaim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mission_marker.add_child(exclaim)
	marker_pulse = exclaim

	# A 3D floating distance badge directly beneath the objective beacon
	var dist_badge := Label3D.new()
	dist_badge.name = "MarkerDistanceBadge"
	dist_badge.text = "OBJECTIVE"
	dist_badge.font_size = 30
	dist_badge.pixel_size = 0.0062
	dist_badge.outline_size = 10
	dist_badge.modulate = Color(1.0, 0.94, 0.70)
	dist_badge.outline_modulate = Color(0.04, 0.08, 0.16, 0.95)
	dist_badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dist_badge.no_depth_test = true
	dist_badge.render_priority = 21
	dist_badge.position.y = 1.95
	dist_badge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mission_marker.add_child(dist_badge)
	marker_distance_badge = dist_badge

	_build_ambient_particles()


func _build_ambient_particles() -> void:
	if world == null:
		return
	# 1. Golden morning sunlit dust motes
	_dust_particles = CPUParticles3D.new()
	_dust_particles.name = "DustMotes"
	_dust_particles.amount = 44
	_dust_particles.lifetime = 6.0
	_dust_particles.preprocess = 2.0
	_dust_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_dust_particles.emission_box_extents = Vector3(24.0, 4.0, 24.0)
	_dust_particles.gravity = Vector3(0.04, -0.04, 0.02)
	_dust_particles.initial_velocity_min = 0.15
	_dust_particles.initial_velocity_max = 0.45
	_dust_particles.spread = 180.0

	var dust_mesh := QuadMesh.new()
	dust_mesh.size = Vector2(0.09, 0.09)
	var dust_mat := StandardMaterial3D.new()
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.albedo_color = Color(1.0, 0.94, 0.72, 0.45)
	dust_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	dust_mesh.material = dust_mat
	_dust_particles.mesh = dust_mesh
	world.add_child(_dust_particles)

	# 2. Fluttering amber leaves
	_leaf_particles = CPUParticles3D.new()
	_leaf_particles.name = "FlutteringLeaves"
	_leaf_particles.amount = 24
	_leaf_particles.lifetime = 5.5
	_leaf_particles.preprocess = 1.5
	_leaf_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_leaf_particles.emission_box_extents = Vector3(20.0, 3.5, 20.0)
	_leaf_particles.gravity = Vector3(0.35, -0.55, 0.20)
	_leaf_particles.initial_velocity_min = 0.3
	_leaf_particles.initial_velocity_max = 0.8
	_leaf_particles.angular_velocity_min = -45.0
	_leaf_particles.angular_velocity_max = 45.0
	_leaf_particles.damping_min = 0.2
	_leaf_particles.damping_max = 0.5

	var leaf_mesh := QuadMesh.new()
	leaf_mesh.size = Vector2(0.14, 0.11)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	leaf_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	leaf_mat.albedo_color = Color(0.88, 0.65, 0.28, 0.82)
	leaf_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	leaf_mesh.material = leaf_mat
	_leaf_particles.mesh = leaf_mesh
	world.add_child(_leaf_particles)


func _current_objective_title() -> String:
	var s := Mission.current()
	if s.is_empty():
		return "Objective"
	var text: String = str(s.get("text", ""))
	var npc_id: String = str(s.get("npc", ""))
	if npc_id == "guard":
		return "Guard Bajirao"
	elif npc_id == "clerk":
		return "Admin Office"
	elif npc_id == "prof":
		return "Prof. Rao"
	elif npc_id == "suresh":
		return "Suresh (IT)"
	elif npc_id == "arjun":
		return "Arjun (Canteen)" if current_interior != "classroom" else "Arjun (Room 204)"
	elif npc_id == "colonel":
		return "Col. Singh (NCC)"
	if s.has("pos"):
		var p: Array = s["pos"]
		if float(p[0]) < -200.0 or (s.has("where") and str(s["where"]).contains("204")):
			return "Room 204 (CSE)"
	if str(s.get("type", "")) == "bank":
		return "Bank ATM"
	if str(s.get("type", "")) == "salute":
		return "Parade Ground"
	if text.length() > 22:
		return text.substr(0, 20) + "..."
	return text


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
		npc.set("low_poly", _low_poly)
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
	hud.pause_requested.connect(_toggle_pause)
	hud.resume_requested.connect(_resume_game)
	hud.menu_requested.connect(_to_main_menu)
	hud.update_wallet(GameState.wallet, GameState.bank)
	hud.update_energy(GameState.energy)
	# Keep the wallet and energy pills live: purchases and drinks change the
	# values while the campus is running, and the HUD must follow them.
	EventBus.wallet_changed.connect(hud.update_wallet)
	EventBus.energy_changed.connect(hud.update_energy)
	if _touch_mode:
		_build_touch_controls()


func _build_touch_controls() -> void:
	touch_controls = CanvasLayer.new()
	touch_controls.set_script(TOUCH_SCRIPT)
	add_child(touch_controls)
	# The stick and buttons belong to gameplay only; the main menu, year and
	# character screens must not show them.  _on_start() reveals the layer.
	touch_controls.visible = false
	touch_controls.move_changed.connect(_on_touch_move)
	touch_controls.look_dragged.connect(_on_touch_look)
	touch_controls.run_changed.connect(_on_touch_run)
	touch_controls.interact_pressed.connect(_interact)
	touch_controls.salute_pressed.connect(_salute)
	if touch_controls.has_signal("bag_pressed"):
		touch_controls.bag_pressed.connect(_on_touch_bag)
	touch_controls.tapped.connect(_on_touch_tap)


func _on_touch_bag() -> void:
	if inventory_panel:
		inventory_panel.toggle()


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
		_skip_dialogue()


func _skip_dialogue() -> void:
	## Typewriter-aware: the first press finishes revealing the line, the
	## next one advances to the following line.
	if hud and hud.skip_line():
		return
	Dialogue.skip()


func _on_step_changed(index: int, total: int, text: String) -> void:
	if hud:
		hud.set_mission(index, total, text)
	if index > 0 and not _check_mode and Audio:
		Audio.play("success", -17.0)
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
	_marker_title = _current_objective_title()
	_marker_step = Mission.index
	_marker_interior = current_interior
	_marker_last_dist = -1
	if s.has("pos"):
		var p: Array = s["pos"]
		var is_interior := bool(s.get("world", false))
		if is_interior and current_interior != "classroom" and classroom_interior:
			# Target is inside Classroom 204 while player is outside: point to Room 204 door on campus!
			var door := classroom_interior.hall_door_pos
			mission_marker.position = Vector3(door.x, 0.09, door.z)
		elif is_interior:
			mission_marker.position = Vector3(float(p[0]), 0.09, float(p[1]))
		else:
			var w := Campus.map_to_world(Vector2(p[0], p[1]))
			mission_marker.position = Vector3(w.x, 0.09, w.z)
	else:
		var target := _npc_by_id(str(s.get("npc", "")))
		if target:
			if target.npc_id == "clerk" and not in_office and admin_office:
				# Point at the Admin hall door, not at Laksmi inside the sealed room.
				var door := admin_office.hall_door_pos
				mission_marker.position = Vector3(door.x, 0.09, door.z)
			elif ((target.npc_id == "arjun" and GameState and GameState.current_day == 3) or (target.npc_id == "prof" and GameState and GameState.current_day == 10)) and current_interior != "classroom" and classroom_interior:
				# Point at the Classroom 204 door on campus
				var door := classroom_interior.hall_door_pos
				mission_marker.position = Vector3(door.x, 0.09, door.z)
			else:
				marker_target = target
				mission_marker.position = Vector3(target.global_position.x, 0.09,
					target.global_position.z)
		else:
			mission_marker.visible = false


func _sync_special_npcs_for_day() -> void:
	var arjun_npc := _npc_by_id("arjun")
	var prof_npc := _npc_by_id("prof")
	if GameState and GameState.current_day == 3 and classroom_interior and arjun_npc:
		arjun_npc.place_at(classroom_interior.CENTER + Vector3(1.2, 0.0, 0.6), 0.0)
	elif arjun_npc:
		var d := CampusDB.main_npc("arjun")
		if not d.is_empty():
			var p: Array = d.get("pos", [268, 128])
			var w := Campus.map_to_world(Vector2(p[0], p[1]))
			arjun_npc.place_at(w, float(d.get("facing", 0.0)))

	if GameState and GameState.current_day == 10 and classroom_interior and prof_npc:
		prof_npc.place_at(classroom_interior.lecturer_pos, 0.0)
	elif prof_npc:
		var d := CampusDB.main_npc("prof")
		if not d.is_empty():
			var p: Array = d.get("pos", [129, 287])
			var w := Campus.map_to_world(Vector2(p[0], p[1]))
			prof_npc.place_at(w, float(d.get("facing", 0.0)))


func _npc_by_id(npc_id: String) -> Node3D:
	for n in npcs:
		if (n as Node3D).npc_id == npc_id:
			return n
	return null


func _enter_office() -> void:
	if admin_office == null or player == null:
		return
	current_interior = "admin_office"
	in_office = true
	if Audio:
		Audio.set_ambience("interior")
		Audio.play_ui("ui_back", -16.0)
	_set_room_visible(admin_room, true)
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
	current_interior = ""
	in_office = false
	_set_room_visible(admin_room, false)
	if Audio:
		Audio.set_ambience("campus")
		Audio.play_ui("ui_back", -16.0)
	player.global_position = admin_office.hall_return_pos
	player.velocity = Vector3.ZERO
	player.yaw = PI * 0.5
	player.pitch = 0.24
	player.camera_distance_override = 0.0
	player.snap_camera()
	_update_marker()


func _enter_library() -> void:
	if library_interior == null or player == null:
		return
	current_interior = "library"
	in_office = false
	if Audio:
		Audio.set_ambience("interior")
		Audio.play_ui("ui_back", -16.0)
	_set_room_visible(library_room, true)
	player.global_position = library_interior.entry_pos
	player.velocity = Vector3.ZERO
	player.yaw = PI
	player.pitch = 0.20
	player.camera_distance_override = 3.6
	player.snap_camera()
	_update_marker()
	if hud and not _check_mode:
		hud.toast("Central Library. Quiet study zone & reference stacks.", 2.6)


func _exit_library() -> void:
	if library_interior == null or player == null:
		return
	current_interior = ""
	in_office = false
	_set_room_visible(library_room, false)
	if Audio:
		Audio.set_ambience("campus")
		Audio.play_ui("ui_back", -16.0)
	player.global_position = library_interior.hall_return_pos
	player.velocity = Vector3.ZERO
	player.yaw = -PI * 0.5
	player.pitch = 0.24
	player.camera_distance_override = 0.0
	player.snap_camera()
	_update_marker()


func _enter_classroom() -> void:
	if classroom_interior == null or player == null:
		return
	current_interior = "classroom"
	in_office = false
	if Audio:
		Audio.set_ambience("interior")
		Audio.play_ui("ui_back", -16.0)
	_set_room_visible(classroom_room, true)
	player.global_position = classroom_interior.entry_pos
	player.velocity = Vector3.ZERO
	player.yaw = -PI * 0.5
	player.pitch = 0.20
	player.camera_distance_override = 3.4
	player.snap_camera()
	_update_marker()
	if hud and not _check_mode:
		hud.toast("Room 204 - CSE Lecture Hall.", 2.6)


func _exit_classroom() -> void:
	if classroom_interior == null or player == null:
		return
	current_interior = ""
	in_office = false
	_set_room_visible(classroom_room, false)
	if Audio:
		Audio.set_ambience("campus")
		Audio.play_ui("ui_back", -16.0)
	player.global_position = classroom_interior.hall_return_pos
	player.velocity = Vector3.ZERO
	player.yaw = PI * 0.5
	player.pitch = 0.24
	player.camera_distance_override = 0.0
	player.snap_camera()
	_update_marker()


func _enter_canteen() -> void:
	if canteen_interior == null or player == null:
		return
	current_interior = "canteen"
	in_office = false
	if Audio:
		Audio.set_ambience("interior")
		Audio.play_ui("ui_back", -16.0)
	_set_room_visible(canteen_room, true)
	player.global_position = canteen_interior.entry_pos
	player.velocity = Vector3.ZERO
	player.yaw = PI
	player.pitch = 0.20
	player.camera_distance_override = 3.8
	player.snap_camera()
	_update_marker()
	if hud and not _check_mode:
		hud.toast("ANITS Canteen. Hot snacks, chai & meals counter.", 2.6)


func _exit_canteen() -> void:
	if canteen_interior == null or player == null:
		return
	current_interior = ""
	in_office = false
	_set_room_visible(canteen_room, false)
	if Audio:
		Audio.set_ambience("campus")
		Audio.play_ui("ui_back", -16.0)
	player.global_position = canteen_interior.hall_return_pos
	player.velocity = Vector3.ZERO
	player.yaw = -PI * 0.5
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
		hud.show_dialogue(speaker, text, str(Dialogue.speaker_key))
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
			marker_pulse.position.y = 2.55 + sin(_marker_time * 2.0) * 0.14
		if marker_distance_badge and player:
			# The objective title only changes on a step or interior transition,
			# never per frame.
			if Mission.index != _marker_step or current_interior != _marker_interior:
				_marker_step = Mission.index
				_marker_interior = current_interior
				_marker_title = _current_objective_title()
				_marker_last_dist = -1
			var dist := player.global_position.distance_to(mission_marker.global_position)
			# The badge is a world-space label: hide it up close (it would fill the
			# screen) and far away (it would be an unreadable speck).
			marker_distance_badge.visible = dist >= 3.0 and dist <= 55.0
			if marker_distance_badge.visible:
				marker_distance_badge.position.y = 1.95 + sin(_marker_time * 2.0) * 0.10
				var metres := int(round(dist))
				if metres != _marker_last_dist:
					_marker_last_dist = metres
					marker_distance_badge.text = "◆ %s · %dm" % [_marker_title, metres]
	if player and _dust_particles:
		_dust_particles.global_position = player.global_position + Vector3(0, 2.5, 0)
	if player and _leaf_particles:
		_leaf_particles.global_position = player.global_position + Vector3(0, 3.5, 0)
	_adaptive_quality(delta)

## The frame rate is watched on every platform: if the device cannot hold 55 fps
## the 3D resolution and then the sun shadows are reduced automatically, so the
## game keeps a smooth 60 fps target on mid-range laptops and phones alike.
func _adaptive_quality(delta: float) -> void:
	# Screenshot tours should capture the intended quality, not the transient
	# frame time of a PNG readback, so the ladder is paused in those modes.
	if _check_mode or _beauty_mode or _menu_shot_mode or _intro_shot_mode or _flow_shot_mode:
		return
	if bench_mode:
		return
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
	if _quality_step >= 3:
		return
	_quality_step += 1
	var viewport := get_viewport()
	match _quality_step:
		1:
			viewport.scaling_3d_scale = 0.54 if _phone_profile else 0.78
			# Drop the most expensive post effects first, then shadows.
			if _env:
				if _ssao:
					_env.ssao_enabled = false
					_ssao = false
				_env.volumetric_fog_enabled = false
			viewport.msaa_3d = Viewport.MSAA_DISABLED
		2:
			viewport.scaling_3d_scale = 0.50 if _phone_profile else 0.68
			if _sun:
				_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
				_sun.directional_shadow_max_distance = 56.0 if _phone_profile else 72.0
				_sun.shadow_blur = 0.7
		3:
			viewport.scaling_3d_scale = 0.46 if _phone_profile else 0.60
			if _sun:
				_sun.shadow_enabled = false
			print("  [quality] stepped down to level 3 (fps safety)")


## The next drink a vending machine offers: the first drink in its authored
## stock the player has not tried yet, so a machine never repeats while it
## still has something new. Once the stock is exhausted it repeats the first.
func _vending_offer(machine: Node) -> Dictionary:
	var stock: Array = machine.get_meta("drink_stock", [])
	var fallback: Dictionary = {}
	for raw_id in stock:
		var drink: Dictionary = CampusDB.drink_by_id(str(raw_id))
		if drink.is_empty():
			continue
		if fallback.is_empty():
			fallback = drink
		if not GameState.drinks_tried.has(str(drink.get("id", ""))):
			return drink
	if not fallback.is_empty():
		return fallback
	return {"id": "happy", "name": "Happy Faces Soda", "price": 20,
		"energy_type": 0, "desc": "Sweet strawberry fizz. Instant smile."}


func _buy_vending_drink(machine: Node) -> void:
	var drink := _vending_offer(machine)
	var drink_id := str(drink.get("id", ""))
	var drink_name := str(drink.get("name", "Cold Drink"))
	var price := int(drink.get("price", 20))
	if not GameState.can_afford(price):
		if Audio:
			Audio.play_ui("error", -10.0)
		if hud:
			hud.toast("Not enough cash! %s costs Rs. %d." % [drink_name, price], 3.0)
		return
	var is_new := not GameState.drinks_tried.has(drink_id)
	var energy_type := int(drink.get("energy_type", 0))
	GameState.spend(price)
	GameState.add_energy(CampusDB.energy_per_drink(energy_type))
	if energy_type == 1:
		GameState.start_boost(CampusDB.boost_seconds())
	GameState.try_drink(drink_id)
	if Audio:
		Audio.play("fizz", -8.0)
		Audio.play("coin", -12.0)
	var total := GameState.drinks_tried_count()
	if is_new and total >= 10:
		if hud:
			hud.toast("CAMPUS FOODIE! All 10 drinks tried. Badge added to your bag.", 5.0)
	elif hud:
		var extra := ""
		if is_new:
			extra += "  •  NEW %d/10" % total
		if energy_type == 1:
			extra += "  •  Speed boost %.0fs" % CampusDB.boost_seconds()
		hud.toast("%s%s\n%s" % [drink_name, extra, str(drink.get("desc", ""))], 4.0)
	if total >= 2:
		Mission.notify_check("drinks")


func _update_prompt() -> void:
	if player == null or hud == null:
		return
	# Work out the text and the matching icon first, then hand both to the HUD
	# and the touch pad once. The icon vocabulary is the reference icon set:
	# door, machine, box, cart, bed, talk, loot, wrench, fuel, star.
	var text := ""
	var icon := ""
	if Dialogue.active:
		pass
	# Leaving interiors
	elif in_office and admin_office \
			and player.global_position.distance_to(admin_office.exit_pos) < 2.4:
		text = "Leave the Admin Office"
		icon = "door"
	elif current_interior == "library" and library_interior \
			and player.global_position.distance_to(library_interior.exit_pos) < 2.4:
		text = "Leave Central Library"
		icon = "door"
	elif current_interior == "classroom" and classroom_interior \
			and player.global_position.distance_to(classroom_interior.exit_pos) < 2.4:
		text = "Leave Room 204"
		icon = "door"
	elif current_interior == "canteen" and canteen_interior \
			and player.global_position.distance_to(canteen_interior.exit_pos) < 2.4:
		text = "Leave the Canteen"
		icon = "door"
	# Entering interiors from campus
	elif player.interact_target != null:
		var target: Node = player.interact_target
		if target.is_in_group("admin_office_door"):
			text = "Enter the Admin Office"
			icon = "door"
		elif target.is_in_group("library_door"):
			text = "Enter Central Library"
			icon = "door"
		elif target.is_in_group("classroom_door"):
			text = "Enter Room 204 (CSE)"
			icon = "door"
		elif target.is_in_group("canteen_door"):
			text = "Enter the Canteen"
			icon = "door"
		elif target.is_in_group("classroom_seat"):
			text = "Sit at Desk (Room 204)"
			icon = "bed"
		elif target.is_in_group("atm"):
			text = "Withdraw Rs. 250 (Bank ATM)"
			icon = "loot"
		elif target.name.begins_with("Vending"):
			var offer := _vending_offer(target)
			text = "Buy %s (Rs. %d)" % [str(offer.get("name", "Cold Drink")), int(offer.get("price", 20))]
			icon = "cart"
		elif target.is_in_group("notice_board"):
			var title: String = str(target.get_meta("board_title", "Notice Board"))
			text = "Read %s" % title
			icon = "book"
		elif target.is_in_group("water_cooler"):
			text = "Drink Fresh RO Water (ANITS)"
			icon = "water"
		else:
			text = "Interact"
			icon = "gear"
	elif Mission.current().get("type") == "idcheck" and player.dialogue_nearby != null:
		text = "Show your ID card (press B)"
		icon = "person"
	elif player.dialogue_nearby != null:
		text = "Talk to %s" % str(player.dialogue_nearby.get("display_name"))
		icon = "talk"
	hud.set_prompt(text, icon)
	if touch_controls and touch_controls.has_method("set_action_icon"):
		touch_controls.set_action_icon(icon)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if get_tree().paused:
				_resume_game()
			elif Dialogue.active:
				_skip_dialogue()
			else:
				_pause_game()
			return
	if player == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_E:
				_interact()
			KEY_G:
				_salute()
			KEY_B:
				if inventory_panel:
					var is_id: bool = Mission.current().get("type") == "idcheck"
					inventory_panel.open(is_id)


func _toggle_pause() -> void:
	if get_tree().paused:
		_resume_game()
	else:
		_pause_game()


func _pause_game() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	if Audio:
		Audio.play_ui("ui_click", -12.0)
	if player:
		player.input_enabled = false
	if hud:
		hud.set_paused_visible(true)
	if touch_controls:
		touch_controls.visible = false


func _resume_game() -> void:
	if not get_tree().paused:
		return
	get_tree().paused = false
	if Audio:
		Audio.play_ui("ui_click", -12.0)
	if player:
		player.input_enabled = true
	if hud:
		hud.set_paused_visible(false)
	if touch_controls:
		touch_controls.visible = true


func _to_main_menu() -> void:
	get_tree().paused = false
	if Audio:
		Audio.stop_ambience()
		Audio.play_ui("ui_back", -12.0)
	if hud:
		hud.set_paused_visible(false)
		hud.visible = false
	if touch_controls:
		touch_controls.visible = false
	if level_complete_dialog:
		level_complete_dialog.visible = false
	if minigame_overlay:
		minigame_overlay.visible = false
	if inventory_panel:
		inventory_panel.visible = false
	if player:
		player.input_enabled = false
	if menu:
		menu.visible = true
		menu.show_levels()


func _interact() -> void:
	if Dialogue.active:
		_skip_dialogue()
		return
	if player == null:
		return
	# Leaving interiors
	if in_office and admin_office \
			and player.global_position.distance_to(admin_office.exit_pos) < 2.4:
		_exit_office()
		return
	if current_interior == "library" and library_interior \
			and player.global_position.distance_to(library_interior.exit_pos) < 2.4:
		_exit_library()
		return
	if current_interior == "classroom" and classroom_interior \
			and player.global_position.distance_to(classroom_interior.exit_pos) < 2.4:
		_exit_classroom()
		return
	if current_interior == "canteen" and canteen_interior \
			and player.global_position.distance_to(canteen_interior.exit_pos) < 2.4:
		_exit_canteen()
		return

	# Entering interiors or interactables
	if player.interact_target != null:
		if player.interact_target.is_in_group("admin_office_door"):
			_enter_office()
			return
		if player.interact_target.is_in_group("library_door"):
			_enter_library()
			return
		if player.interact_target.is_in_group("classroom_door"):
			_enter_classroom()
			return
		if player.interact_target.is_in_group("canteen_door"):
			_enter_canteen()
			return
		if player.interact_target.is_in_group("classroom_seat"):
			var seat_pos: Vector3 = player.interact_target.global_position
			player.global_position = Vector3(seat_pos.x, 0.12, seat_pos.z)
			player.rotation.y = PI
			if hud:
				hud.toast("Seated in Room 204. Ready for class lecture!", 3.0)
			return
		if player.interact_target.is_in_group("atm"):
			if GameState.deposit(250):
				if Audio:
					Audio.play("coin", -9.0)
				if hud:
					hud.toast("Withdrew Rs. 250 from ATM. Wallet: Rs. %d" % GameState.wallet, 3.0)
				Mission.notify_check("bank")
			else:
				if Audio:
					Audio.play_ui("error", -10.0)
				if hud:
					hud.toast("Your bank balance is empty.", 3.0)
			return
		if player.interact_target.name.begins_with("Vending"):
			_buy_vending_drink(player.interact_target)
			return
		if player.interact_target.is_in_group("interactables"):
			if player.interact_target.is_in_group("notice_board"):
				var title: String = str(player.interact_target.get_meta("board_title", "Campus Notice"))
				var desc: String = str(player.interact_target.get_meta("board_desc", ""))
				if Audio:
					Audio.play_ui("ui_click", -12.0)
				if hud:
					hud.toast("📋 [%s]\n%s" % [title, desc], 5.0)
				return
			if player.interact_target.is_in_group("water_cooler"):
				GameState.add_energy(20.0)
				if Audio:
					Audio.play("fizz", -11.0)
				if hud:
					hud.toast("💧 Chilled RO Water! Rehydrated and restored +20 Energy.", 3.5)
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
	var lines: Array = []
	if step.has("lines") and (step["lines"] as Dictionary).has(npc.npc_id):
		lines = step["lines"][npc.npc_id]
	else:
		var key := str(step.get("line", "")) if str(step.get("npc", "")) == npc.npc_id else ""
		lines = npc.lines_for(key) if key != "" else npc.idle_lines()
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
	_show_all_interiors()
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
	await get_tree().create_timer(0.9).timeout
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
	if env_node is Sky3D:
		(env_node as Sky3D).fog_enabled = false
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
	current_interior = ""
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
		var right := Vector3(cos(npc.base_facing), 0.0, -sin(npc.base_facing))
		spot = npc.global_position + forward * 2.4 + right * 1.2
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
	if menu and menu.has_method("show_settings"):
		menu.show_settings()
		await get_tree().create_timer(0.5).timeout
		await _shot("%s/menu_settings.png" % out_dir)
	if menu and menu.has_method("show_dev"):
		var dev_before: bool = Settings != null and Settings.is_dev_mode()
		menu.show_dev()
		await get_tree().create_timer(0.5).timeout
		await _shot("%s/menu_dev.png" % out_dir)
		if menu.has_method("show_levels"):
			menu.show_levels()
			await get_tree().create_timer(0.5).timeout
			await _shot("%s/menu_levels_dev.png" % out_dir)
		if not dev_before and Settings:
			Settings.set_dev_mode(false)
			if menu.has_method("_refresh_dev_visibility"):
				menu._refresh_dev_visibility()
	if menu and menu.has_method("_show_loading"):
		menu._show_loading(2)
		await get_tree().create_timer(0.35).timeout
		await _shot("%s/menu_loading.png" % out_dir)
	print("=== MENU SHOTS DONE ===")
	get_tree().quit(0)


func _run_flow_shot() -> void:
	## Exercises the real menu -> loading -> campus handover.
	var out_dir := "res://docs/screenshots/godot"
	DirAccess.make_dir_recursive_absolute(out_dir)
	await get_tree().create_timer(0.4).timeout
	if menu and menu.has_method("_start"):
		menu._start(1)
	await get_tree().create_timer(2.0).timeout
	if menu:
		menu.loading_go.emit()
	await get_tree().create_timer(4.0).timeout
	await _shot("%s/flow_spawn.png" % out_dir)
	# Prove the pause overlay works: pause, capture, resume.
	if hud:
		hud.pause_requested.emit()
	await get_tree().create_timer(0.4).timeout
	await _shot("%s/flow_paused.png" % out_dir)
	print("=== FLOW SHOT DONE ===")
	get_tree().quit(0)


func _run_intro_shots() -> void:
	## Captures the Little Hearts production card for the report.
	var out_dir := "res://docs/screenshots/godot"
	DirAccess.make_dir_recursive_absolute(out_dir)
	await get_tree().create_timer(2.4).timeout
	await _shot("%s/intro_logo.png" % out_dir)
	await get_tree().create_timer(3.2).timeout
	await _shot("%s/intro_studio.png" % out_dir)
	await get_tree().create_timer(3.0).timeout
	await _shot("%s/intro_credit.png" % out_dir)
	print("=== INTRO SHOTS DONE ===")
	get_tree().quit(0)


func _run_beauty() -> void:
	## Free-camera screenshot pass used for the report: the same campus, but
	## framed the way a photographer would frame it.
	await get_tree().process_frame
	GameState.profile = {"name": "Mike", "char": "boy", "year": 2024}
	if menu:
		menu.visible = false
	_build_campus()
	_show_all_interiors()
	_build_player()
	_build_npcs()
	_build_hud()
	Mission.start_day(1)
	var out_dir := "res://docs/screenshots/godot/beauty_low" if _phone_profile \
		else "res://docs/screenshots/godot/beauty"
	DirAccess.make_dir_recursive_absolute(out_dir)
	player.set_physics_process(false)
	hud.visible = false
	mission_marker.visible = false

	# 1 - the main gate from the road outside
	await _beauty_shot("01_main_gate.png", Vector2(122, 470), 7.0, Vector2(122, 400), 4.0)
	# 2 - the Admin Block front
	await _beauty_shot("02_admin_block.png", Vector2(163, 430), 12.0, Vector2(163, 330), 9.0)
	# 3 - the CSE block across the central road
	await _beauty_shot("03_cse_block.png", Vector2(180, 287), 12.0, Vector2(128, 264), 6.0)
	# 4 - the IT block along the main road
	await _beauty_shot("04_it_block.png", Vector2(232, 258), 10.0, Vector2(271, 190), 6.0)
	# 5 - the canteen and the Civil blocks
	await _beauty_shot("05_canteen.png", Vector2(270, 127), 5.0, Vector2(302, 127), 2.8)
	# 6 - the NCC ground with the open auditorium pavilion
	await _beauty_shot("06_ncc_ground.png", Vector2(212, 424), 9.0, Vector2(236, 398), 5.0)
	# 7 - the basketball court
	await _beauty_shot("07_basketball.png", Vector2(300, 320), 16.0, Vector2(300, 282), 1.5)
	# 8 - the temple and the central lawn
	await _beauty_shot("08_temple.png", Vector2(86, 358), 7.0, Vector2(112, 340), 4.5)
	# 9 - the back gate
	await _beauty_shot("09_back_gate.png", Vector2(236, 30), 4.5, Vector2(236, 110), 5.5)
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

	# 13 - inside the Central Library
	if library_interior:
		player.camera.global_position = library_interior.position + Vector3(3.2, 1.85, 4.0)
		player.camera.look_at(library_interior.position + Vector3(-1.8, 1.25, -1.2), Vector3.UP)
		await get_tree().process_frame
		await _shot("%s/13_central_library.png" % out_dir)

	# 14 - inside Room 204 (CSE Lecture Hall)
	if classroom_interior:
		player.camera.global_position = classroom_interior.position + Vector3(2.6, 1.8, 4.0)
		player.camera.look_at(classroom_interior.position + Vector3(0.0, 1.55, -4.2), Vector3.UP)
		await get_tree().process_frame
		await _shot("%s/14_classroom_204.png" % out_dir)

	# 15 - inside the College Canteen
	if canteen_interior:
		player.camera.global_position = canteen_interior.position + Vector3(2.5, 1.85, 4.2)
		player.camera.look_at(canteen_interior.position + Vector3(0.0, 1.5, -3.2), Vector3.UP)
		await get_tree().process_frame
		await _shot("%s/15_campus_canteen.png" % out_dir)

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
	var folder := "beauty_low" if _phone_profile else "beauty"
	await _shot("res://docs/screenshots/godot/%s/%s" % [folder, file_name])
