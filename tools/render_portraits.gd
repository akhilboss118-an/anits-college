extends SceneTree
## Renders the dialogue portraits for the HUD straight from the game's own
## 3D character assets, because the online image service was unavailable.
## Run windowed (needs a real renderer):
##   godot --path <project> --script res://tools/render_portraits.gd
##
## Each portrait is a 512x512 head-and-shoulders render on a dark
## charcoal backdrop with a warm key and a cool rim, saved to
## assets/ui/portraits/<npc-id>.png and imported on the next run.

const OUT_DIR := "res://assets/ui/portraits"
const SIZE := 512

const PORTRAITS := [
	{"file": "guard.png",   "model": "guard",   "h": 1.70, "tint": Color(1, 1, 1)},
	{"file": "clerk.png",   "model": "laksmi",  "h": 1.70, "tint": Color(1, 1, 1)},
	{"file": "prof.png",    "model": "remy",    "h": 1.70, "tint": Color(0.416, 0.353, 0.227)},
	{"file": "suresh.png",  "model": "remy",    "h": 1.70, "tint": Color(0.227, 0.541, 0.478)},
	{"file": "arjun.png",   "model": "remy",    "h": 1.70, "tint": Color(0.878, 0.533, 0.227)},
	{"file": "colonel.png", "model": "colonel", "h": 1.85, "tint": Color(1, 1, 1)},
	{"file": "student.png", "model": "boy",     "h": 1.75, "tint": Color(1, 1, 1)},
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	for spec in PORTRAITS:
		await _render_one(spec)
	print("=== PORTRAITS DONE ===")
	quit(0)


func _render_one(spec: Dictionary) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(SIZE, SIZE)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	root.add_child(vp)

	# --- world ---
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.045, 0.05, 0.055)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.52, 0.46, 0.40)
	e.ambient_light_energy = 0.85
	e.glow_enabled = true
	e.glow_intensity = 0.25
	e.glow_bloom = 0.15
	e.glow_hdr_threshold = 1.15
	env.environment = e
	vp.add_child(env)

	var key_light := DirectionalLight3D.new()
	key_light.light_color = Color(1.05, 0.92, 0.78)
	key_light.light_energy = 1.7
	key_light.shadow_enabled = true
	key_light.directional_shadow_max_distance = 6.0
	key_light.shadow_blur = 1.5
	key_light.rotation_degrees = Vector3(-38.0, 26.0, 0.0)
	vp.add_child(key_light)

	var rim_light := DirectionalLight3D.new()
	rim_light.light_color = Color(0.55, 0.68, 0.95)
	rim_light.light_energy = 1.5
	rim_light.shadow_enabled = false
	rim_light.rotation_degrees = Vector3(-24.0, 205.0, 0.0)
	vp.add_child(rim_light)

	var fill_light := OmniLight3D.new()
	fill_light.light_color = Color(0.9, 0.85, 0.75)
	fill_light.light_energy = 1.1
	fill_light.omni_range = 4.0
	fill_light.position = Vector3(0.55, 1.35, 1.1)
	vp.add_child(fill_light)

	# --- character ---
	var height: float = float(spec["h"])
	var visual := CharacterVisual.create(str(spec["model"]), height, spec["tint"] as Color)
	vp.add_child(visual)

	# --- camera: head and shoulders ---
	var cam := Camera3D.new()
	cam.fov = 27.0
	var target := Vector3(0.0, height * 0.80, 0.0)
	cam.position = Vector3(0.14 * height, height * 0.92, height * 1.18)
	vp.add_child(cam)
	if cam.is_inside_tree():
		cam.look_at(target, Vector3.UP)
	else:
		cam.look_at_from_position(cam.position, target, Vector3.UP)

	# Let the idle animation settle into a natural pose.
	for i in 30:
		await process_frame

	var img := vp.get_texture().get_image()
	var out_path := "%s/%s" % [OUT_DIR, str(spec["file"])]
	var err := img.save_png(out_path)
	vp.queue_free()
	print("  portrait %s -> %s (%d KB)" % [str(spec["file"]), out_path,
			int(float(ResourceLoader.exists(out_path)))])


func _safe_quit() -> void:
	pass
