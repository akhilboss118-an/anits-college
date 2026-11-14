extends SceneTree
## Renders the three joining-year uniforms for both player models. Run with a
## real renderer:
##   godot --path <project> --script res://tools/render_uniforms.gd
## The PNGs land in docs/screenshots/godot/uniform_<year>_<model>.png and are
## used to check that all three body textures actually load.

const OUT_DIR := "res://docs/screenshots/godot"
const SIZE := Vector2i(360, 480)


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	for year in [2023, 2024, 2025]:
		for model in ["boy", "girl"]:
			await _render(year, model, "front")
		await _render(year, "girl", "back")
	print("=== UNIFORMS DONE ===")
	quit(0)


func _render(year: int, model: String, view: String) -> void:
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	root.add_child(vp)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.055, 0.075, 0.10)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.80, 0.86, 1.0)
	e.ambient_light_energy = 1.25
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	vp.add_child(env)

	var key := DirectionalLight3D.new()
	key.light_energy = 1.8
	key.light_color = Color(1.0, 0.96, 0.90)
	key.rotation_degrees = Vector3(-34.0, 34.0, 0.0)
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 5.0
	vp.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.9
	fill.light_color = Color(0.55, 0.72, 1.0)
	fill.rotation_degrees = Vector3(-18.0, -140.0, 0.0)
	vp.add_child(fill)

	var visual := CharacterVisual.create(model, 1.65 if model == "girl" else 1.75)
	vp.add_child(visual)
	visual.apply_uniform(year)
	visual.rotation.y = PI if view == "back" else 0.0

	var cam := Camera3D.new()
	cam.fov = 26.0
	cam.position = Vector3(0.0, 1.0, 4.5)
	vp.add_child(cam)
	cam.look_at_from_position(cam.position, Vector3(0.0, 0.92, 0.0), Vector3.UP)

	for i in 24:
		await process_frame

	var suffix := "" if view == "front" else "_back"
	var path := "%s/uniform_%d_%s%s.png" % [OUT_DIR, year, model, suffix]
	vp.get_texture().get_image().save_png(path)
	print("  uniform %d %s %s -> %s" % [year, model, view, path])
	vp.queue_free()
