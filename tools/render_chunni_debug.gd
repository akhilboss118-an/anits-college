extends SceneTree


func _initialize() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(480, 640)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.07, 0.10)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.85, 1.0)
	e.ambient_light_energy = 1.3
	env.environment = e
	vp.add_child(env)
	var key := DirectionalLight3D.new()
	key.light_energy = 1.6
	key.rotation_degrees = Vector3(-32, 30, 0)
	vp.add_child(key)
	var visual := CharacterVisual.create("girl", 1.65, Color.WHITE)
	vp.add_child(visual)
	visual.apply_uniform(2025)
	visual.rotation.y = PI
	var chunni := visual.get("_chunni") as MeshInstance3D
	if chunni:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.0, 1.0)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.no_depth_test = true
		chunni.material_override = mat
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.0, -4.5)
	vp.add_child(cam)
	cam.look_at_from_position(cam.position, Vector3(0, 0.95, 0), Vector3.UP)
	for i in 12:
		await process_frame
	vp.get_texture().get_image().save_png("res://docs/screenshots/godot/chunni_debug.png")
	quit(0)
