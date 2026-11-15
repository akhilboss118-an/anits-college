extends SceneTree
## ANITS benchmark harness  (tests/bench.gd)
##
##   godot --path <project> --script res://tests/bench.gd -- [options]
##
## Loads the game scene, builds the campus exactly like a normal play session
## (17 buildings, 150 trees, 4200 grass tufts, 91 cars, 64 animated NPCs),
## samples the renderer for a fixed window and prints a compact `key=value`
## summary block that can be grepped, diffed or parsed by CI.
##
## The script is headless-safe: every Performance / RenderingServer query is
## optional, a missing monitor simply reports 0 and never aborts the run.
## In headless mode the render monitors are meaningless (dummy renderer), so
## the summary is flagged `render_valid=false` and only the CPU numbers count.
##
## Options (everything after the `--` separator, all optional):
##   --bench-label=NAME     label printed in the summary        (default "default")
##   --bench-mode=MODE      game | load | empty                 (default "game")
##   --bench-seconds=N      measurement window in seconds        (default 10)
##   --bench-warmup=N       warm-up seconds before measuring    (default 3)
##   --bench-profile=P      desktop | mobile                    (default "desktop")
##   --bench-adaptive       let the quality ladder settle instead of pinning it
##   --bench-scale=S        pin the 3D render scale (desktop or mobile)
##   --bench-target=FPS     fps target used for the verdict     (default 60)
##   --bench-orbit          orbit the camera over the campus while measuring
##   --bench-vsync=on|off   default "off" (uncapped) when a window exists
##   --bench-verbose        print one line per second of the run
##   --bench-out=PATH       also write the summary block to a file
##   --bench-scene=PATH     scene to bench (default res://src/main.tscn)
##   --bench-spot=NAME      worst-case viewpoint, in plan pixels or by name:
##                           spawn | gate | admin | parade | court | parking |
##                           lawn | X,Y
##
## Exit code: 0 = PASS, 1 = FAIL (below the fps target), 2 = could not bench.

const MAIN_SCENE := "res://src/main.tscn"
## World centre of the campus plan (plan px 213,245 -> metres).
const CAMPUS_CENTRE := Vector3(-1.4, 0.0, -3.5)
const ORBIT_RADIUS := 62.0
const ORBIT_HEIGHT := 26.0
const ORBIT_SPEED_DEG := 14.0
## Worst-case viewpoints, in campus plan pixels (see src/data/campus_data.json).
const SPOTS := {
	"spawn": Vector2(122, 448),
	"gate": Vector2(122, 396),
	"admin": Vector2(174, 337),
	"parade": Vector2(214, 396),
	"court": Vector2(290, 275),
	"canteen": Vector2(268, 145),
	"parking": Vector2(81, 225),
	"lawn": Vector2(122, 340),
}

var _label := "default"
var _mode := "game"
var _measure_seconds := 10.0
var _warmup_seconds := 3.0
var _profile := "desktop"
var _target_fps := 60.0
var _orbit := false
var _vsync := "auto"
var _verbose := false
var _out_path := ""
var _scene_path := MAIN_SCENE
var _spot := ""
var _hide: Array = []
var _scale_override := 0.0
var _adaptive := false

var _frame_ms: Array = []
var _draw_max := 0
var _draw_sum := 0.0
var _draw_n := 0
var _objects_max := 0
var _primitives_max := 0
var _video_mem_mb := 0.0
var _cpu_process_ms := 0.0
var _cpu_physics_ms := 0.0
var _cpu_process_sum := 0.0
var _cpu_physics_sum := 0.0
var _main: Node = null
var _orbit_angle := 0.0
var _game_started := false
var _fatal := false
var _notes: Array = []
var _rows := PackedStringArray()


# ------------------------------------------------------------------ entry

func _initialize() -> void:
	_parse_args()
	_run()


func _parse_args() -> void:
	var args: Array = OS.get_cmdline_user_args()
	if args.is_empty():
		args = OS.get_cmdline_args()
	for raw in args:
		var arg := str(raw)
		if not arg.begins_with("--bench-"):
			continue
		var body := arg.substr(8)
		var key := body
		var value := ""
		var eq := body.find("=")
		if eq >= 0:
			key = body.substr(0, eq)
			value = body.substr(eq + 1)
		match key:
			"label":
				_label = value
			"mode":
				_mode = value.to_lower()
			"seconds":
				_measure_seconds = maxf(0.5, value.to_float())
			"warmup":
				_warmup_seconds = maxf(0.0, value.to_float())
			"profile":
				_profile = value.to_lower()
			"target":
				_target_fps = maxf(1.0, value.to_float())
			"orbit":
				_orbit = true
			"vsync":
				_vsync = value.to_lower()
			"verbose":
				_verbose = true
			"out":
				_out_path = value
			"scene":
				_scene_path = value
			"spot":
				_spot = value
			"hide":
				_hide = value.split(",", false)
			"scale":
				_scale_override = clampf(value.to_float(), 0.25, 1.0)
			"adaptive":
				_adaptive = true


# ------------------------------------------------------------------ run

func _run() -> void:
	print("=== ANITS BENCH ===")
	await _setup_scene()
	await process_frame
	await process_frame
	_apply_profile()
	await process_frame
	_apply_spot()
	await process_frame
	_apply_hide()
	await process_frame
	if _orbit:
		_free_camera()
	await _warmup()
	await _measure()
	var ok := _report()
	if _fatal:
		quit(2)
	else:
		quit(0 if ok else 1)


func _setup_scene() -> void:
	if _mode == "empty":
		_notes.append("mode=empty")
		return
	if not ResourceLoader.exists(_scene_path):
		_notes.append("scene_missing=%s" % _scene_path)
		_fatal = true
		return
	var packed := load(_scene_path) as PackedScene
	if packed == null:
		_notes.append("scene_load_failed=%s" % _scene_path)
		_fatal = true
		return
	_main = packed.instantiate()
	root.add_child(_main)
	# The ladder is frozen by default so a run is repeatable; --bench-adaptive
	# leaves it running through the warm-up so the settled quality is measured.
	if not _adaptive:
		_main.set("bench_mode", true)
	# Autoloads are added to the tree before this script runs, but their _ready
	# (and CampusDB's JSON load) may still be pending.  Wait one frame so the
	# bench measures the real campus, not an empty one.
	await process_frame
	if _mode != "game":
		_notes.append("mode=%s" % _mode)
		return
	# Start the game the way the main menu does, so the campus, the player and
	# all 64 NPCs exist while we measure.
	if not _autoload_present("CampusDB"):
		_notes.append("autoloads_missing")
		return
	var db := root.get_node_or_null("CampusDB")
	if db != null and not bool(db.get("loaded")):
		db.call("load_all")
	if not _main.has_method("_on_start"):
		_notes.append("no_start_method")
		return
	_main.call("_on_start", {"name": "Bench", "char": "boy", "year": 2024})
	_game_started = true
	if _main.get("campus") == null:
		_notes.append("game_start_incomplete")
		_game_started = false


func _autoload_present(singleton_name: String) -> bool:
	if Engine.has_singleton(singleton_name):
		return true
	return root.get_node_or_null(NodePath(singleton_name)) != null


## Applies the phone quality profile when asked, so the desktop can be used
## as an A/B rig.  On a real phone src/main.gd already did this in _ready();
## with `--low-poly` it also builds the phone sky and shadow profile, so this
## only pins the internal resolution for repeatable runs.
func _apply_profile() -> void:
	var mobile := _profile == "mobile" or OS.has_feature("mobile")
	if not mobile:
		# The adaptive ladder settles here on the dev laptop; pin it so the
		# settled desktop look can be measured repeatably.
		if _scale_override > 0.0:
			root.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			root.scaling_3d_scale = _scale_override
			Engine.max_fps = 60
		return
	root.msaa_3d = Viewport.MSAA_DISABLED
	root.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	root.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	root.scaling_3d_scale = _scale_override if _scale_override > 0.0 else 0.60
	Engine.max_fps = 60


## Moves the player to a known worst-case viewpoint before the measurement.
func _apply_spot() -> void:
	if _spot == "":
		return
	var key := _spot.to_lower()
	var plan := Vector2.ZERO
	if SPOTS.has(key):
		plan = SPOTS[key]
	elif _spot.contains(","):
		var parts := _spot.split(",")
		plan = Vector2(float(parts[0]), float(parts[1]))
	else:
		_notes.append("spot_unknown=%s" % _spot)
		return
	var players := get_nodes_in_group("player")
	if players.is_empty():
		_notes.append("spot_no_player")
		return
	var player := players[0] as Node3D
	if player == null:
		_notes.append("spot_no_player")
		return
	if player.has_method("teleport_to_plan"):
		player.call("teleport_to_plan", plan.x, plan.y)
	if player.has_method("snap_camera"):
		player.call("snap_camera")
	_notes.append("spot=%s(%d,%d)" % [key, int(plan.x), int(plan.y)])


## Profiling aid: hides a subsystem so its cost can be isolated.
func _apply_hide() -> void:
	if _hide.is_empty():
		return
	for what in _hide:
		match str(what):
			"npcs":
				for n in get_nodes_in_group("npcs"):
					var node := n as Node3D
					if node:
						node.visible = false
						node.set_process(false)
						node.set_physics_process(false)
			"labels":
				for n in _main.find_children("*", "Label3D", true, false):
					(n as Label3D).visible = false
			"trees":
				for n in _main.find_children("Tree*", "MultiMeshInstance3D", true, false):
					(n as Node3D).visible = false
			"grass":
				for n in _main.find_children("Grass*", "MultiMeshInstance3D", true, false):
					(n as Node3D).visible = false
			"interiors":
				for room_name in ["admin_room", "library_room", "classroom_room", "canteen_room"]:
					var room: Node = _main.get(room_name)
					if room:
						(room as Node3D).visible = false
			"shadows":
				for n in _main.find_children("*", "DirectionalLight3D", true, false):
					(n as DirectionalLight3D).shadow_enabled = false
			"sky":
				var we := _main.find_child("WorldEnvironment", true, false)
				if we:
					var env: Environment = we.get("environment")
					if env:
						env.background_mode = Environment.BG_COLOR
						env.sky = null
						env.glow_enabled = false
						env.ssao_enabled = false
						env.fog_enabled = false
						env.volumetric_fog_enabled = false
			"post":
				var layer: Node = _main.get("_post_layer")
				if layer:
					(layer as CanvasLayer).visible = false
			"hud":
				var hud: Node = _main.get("hud")
				if hud:
					(hud as CanvasLayer).visible = false
			"lights":
				for n in _main.find_children("*", "Light3D", true, false):
					(n as Light3D).visible = false
	_notes.append("hide=" + ",".join(_hide))


## Stops the player rig from driving the camera, so the orbit owns it.
func _free_camera() -> void:
	var players := get_nodes_in_group("player")
	if players.is_empty():
		return
	var player := players[0] as Node
	if player != null:
		player.set_physics_process(false)


func _warmup() -> void:
	var deadline := Time.get_ticks_msec() + int(_warmup_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame


func _measure() -> void:
	var headless := DisplayServer.get_name() == "headless"
	var use_vsync := _vsync
	if use_vsync == "auto":
		use_vsync = "off" if not headless else "on"
	if not headless:
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_DISABLED if use_vsync == "off" else DisplayServer.VSYNC_ENABLED)
	# Uncap the engine so the frame time shows the real GPU + CPU cost.
	Engine.max_fps = 0

	var start_us := Time.get_ticks_usec()
	var last_us := start_us
	var frames := 0
	var second_mark := start_us
	while true:
		await process_frame
		var now := Time.get_ticks_usec()
		var dt_ms := float(now - last_us) / 1000.0
		last_us = now
		if frames == 0:
			frames += 1
			continue
		frames += 1
		_frame_ms.append(dt_ms)
		_sample_monitors()
		_orbit_step(dt_ms)
		if _verbose and now - second_mark >= 1000000:
			second_mark = now
			print("  t=%ds frames=%d fps=%.1f" % [
				int(float(now - start_us) / 1000000.0), frames,
				1000.0 / maxf(dt_ms, 0.001)])
		if float(now - start_us) / 1000000.0 >= _measure_seconds:
			break
	Engine.max_fps = 60


func _sample_monitors() -> void:
	var calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_draw_max = maxi(_draw_max, calls)
	_draw_sum += float(calls)
	_draw_n += 1
	_objects_max = maxi(_objects_max,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
	_primitives_max = maxi(_primitives_max,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	_video_mem_mb = maxf(_video_mem_mb,
		float(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)) / 1048576.0)
	_cpu_process_ms = float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0
	_cpu_physics_ms = float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0
	_cpu_process_sum += _cpu_process_ms
	_cpu_physics_sum += _cpu_physics_ms


## Slow orbit over the whole campus: the worst case for culling, because the
## far side of the campus stays in the frustum for the entire run.
func _orbit_step(dt_ms: float) -> void:
	if not _orbit:
		return
	var cam := root.get_camera_3d()
	if cam == null:
		return
	_orbit_angle += deg_to_rad(ORBIT_SPEED_DEG) * dt_ms / 1000.0
	cam.global_position = CAMPUS_CENTRE + Vector3(
		sin(_orbit_angle) * ORBIT_RADIUS, ORBIT_HEIGHT, cos(_orbit_angle) * ORBIT_RADIUS)
	cam.look_at(CAMPUS_CENTRE, Vector3.UP)


# ------------------------------------------------------------------ report

func _report() -> bool:
	var headless := DisplayServer.get_name() == "headless"
	var render_valid := not headless
	var sorted := _frame_ms.duplicate()
	sorted.sort()
	var n := sorted.size()
	var total_s := 0.0
	for v in sorted:
		total_s += float(v)
	var avg_ms := total_s / maxf(1.0, float(n))
	var p50 := _pct(sorted, 0.50)
	var p95 := _pct(sorted, 0.95)
	var p99 := _pct(sorted, 0.99)
	var worst: float = float(sorted[n - 1]) if n > 0 else 0.0
	var avg_fps := 1000.0 / maxf(avg_ms, 0.001)
	var min_fps := 1000.0 / maxf(worst, 0.001)
	var hitches := 0
	for v in sorted:
		if float(v) > 1000.0 / _target_fps:
			hitches += 1
	var census := _census()
	var draw_avg := _draw_sum / maxf(1.0, float(_draw_n))
	var cpu_process_avg := _cpu_process_sum / maxf(1.0, float(_draw_n))
	var cpu_physics_avg := _cpu_physics_sum / maxf(1.0, float(_draw_n))
	var budget_ms := 1000.0 / _target_fps

	# With a window the verdict is the real frame rate.  Headless only
	# measures the CPU side, so the script time has to fit in the budget.
	var meets := false
	var basis := "fps"
	if render_valid:
		meets = avg_fps >= _target_fps * 0.98
	else:
		basis = "cpu_frame_time"
		meets = (cpu_process_avg + cpu_physics_avg) <= budget_ms
	var verdict := "PASS" if meets else "FAIL"

	_rows = []
	_kv("label", _label)
	_kv("mode", _mode)
	_kv("profile", "mobile" if (_profile == "mobile" or OS.has_feature("mobile")) else "desktop")
	_kv("scene", _scene_path)
	_kv("spot", _spot if _spot != "" else "spawn")
	_kv("game_started", str(_game_started))
	_kv("engine_version", Engine.get_version_info().get("string", "unknown"))
	_kv("rendering_method", _safe_rendering_method())
	_kv("driver", _safe_driver())
	_kv("adapter_api", _safe_adapter_api())
	_kv("display_server", DisplayServer.get_name())
	_kv("headless", str(headless))
	_kv("render_valid", str(render_valid))
	_kv("window", "%dx%d" % [root.size.x, root.size.y])
	_kv("scaling_3d", "%.2f" % root.scaling_3d_scale)
	_kv("adaptive", "on" if _adaptive else "off")
	_kv("quality_step", str(_main.get("_quality_step")) if _main else "-")
	_kv("msaa_3d", str(root.msaa_3d))
	_kv("warmup_s", "%.1f" % _warmup_seconds)
	_kv("window_s", "%.1f" % _measure_seconds)
	_kv("frames", str(n))
	_kv("fps_avg", "%.2f" % avg_fps)
	_kv("fps_min", "%.2f" % min_fps)
	_kv("frame_ms_avg", "%.2f" % avg_ms)
	_kv("frame_ms_p50", "%.2f" % p50)
	_kv("frame_ms_p95", "%.2f" % p95)
	_kv("frame_ms_p99", "%.2f" % p99)
	_kv("frame_ms_max", "%.2f" % worst)
	_kv("frames_over_budget", str(hitches))
	_kv("target_fps", "%.0f" % _target_fps)
	_kv("verdict_basis", basis)
	_kv("meets_target", str(meets))
	_kv("draw_calls_max", str(_draw_max))
	_kv("draw_calls_avg", "%.1f" % draw_avg)
	_kv("objects_max", str(_objects_max))
	_kv("primitives_max", str(_primitives_max))
	_kv("video_mem_mb", "%.1f" % _video_mem_mb)
	_kv("cpu_process_ms", "%.2f" % _cpu_process_ms)
	_kv("cpu_physics_ms", "%.2f" % _cpu_physics_ms)
	_kv("cpu_process_ms_avg", "%.2f" % cpu_process_avg)
	_kv("cpu_physics_ms_avg", "%.2f" % cpu_physics_avg)
	_kv("nodes", str(census["nodes"]))
	_kv("mesh_instances", str(census["mesh_instances"]))
	_kv("multimesh_batches", str(census["multimesh"]))
	_kv("multimesh_instances", str(census["multimesh_total"]))
	_kv("multimesh_visible", str(census["multimesh_visible"]))
	_kv("animation_players", str(census["anim_players"]))
	_kv("skeletons", str(census["skeletons"]))
	_kv("label3d", str(census["labels"]))
	_kv("lights", str(census["lights"]))
	_kv("result", verdict)
	for note in _notes:
		_kv("note", str(note))

	var block := "\n".join(_rows)
	print("--- summary ---")
	print(block)
	print("=== END BENCH ===")
	_write_out(block)
	return verdict == "PASS"


func _pct(sorted: Array, fraction: float) -> float:
	if sorted.is_empty():
		return 0.0
	var idx := int(floor(float(sorted.size()) * fraction))
	idx = clampi(idx, 0, sorted.size() - 1)
	return float(sorted[idx])


func _kv(key: String, value: String) -> void:
	_rows.append("%s=%s" % [key, value])


func _census() -> Dictionary:
	var counts := {
		"nodes": 0, "mesh_instances": 0, "multimesh": 0, "multimesh_total": 0,
		"multimesh_visible": 0, "skeletons": 0, "anim_players": 0, "labels": 0,
		"lights": 0,
	}
	var stack: Array = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		counts["nodes"] += 1
		if node is MeshInstance3D:
			counts["mesh_instances"] += 1
		if node is MultiMeshInstance3D:
			counts["multimesh"] += 1
			var mm := (node as MultiMeshInstance3D).multimesh
			if mm != null:
				counts["multimesh_total"] += mm.instance_count
			if (node as MultiMeshInstance3D).visible:
				counts["multimesh_visible"] += 1
		if node is Skeleton3D:
			counts["skeletons"] += 1
		if node is AnimationPlayer:
			counts["anim_players"] += 1
		if node is Label3D:
			counts["labels"] += 1
		if node is Light3D:
			counts["lights"] += 1
		for child in node.get_children():
			stack.append(child)
	return counts


func _write_out(block: String) -> void:
	if _out_path == "":
		return
	var path := _out_path
	if not path.contains("://"):
		path = "user://" + path
	var dir := path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("  (could not write %s: %s)" % [path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(block + "\n")
	file.close()
	print("  written: %s" % path)


# ------------------------------------------------------------------ safe probes

func _safe_rendering_method() -> String:
	var method := RenderingServer.get_current_rendering_method()
	if method == "":
		return "unknown"
	return method


func _safe_driver() -> String:
	var info := OS.get_video_adapter_driver_info()
	if info.is_empty():
		return "unknown"
	return " ".join(info)


func _safe_adapter_api() -> String:
	var api := RenderingServer.get_video_adapter_api_version()
	if api == "":
		return "unknown"
	return api
