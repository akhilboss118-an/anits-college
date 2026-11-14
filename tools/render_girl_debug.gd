extends SceneTree
## Diagnostic: renders the girl's vertex-coloured Acc_MAT surface unshaded, so
## the raw COLOR_0 values are visible without lighting or texture. Run with a
## real renderer:
##   godot --path <project> --script res://tools/render_girl_debug.gd


func _initialize() -> void:
	for year in [2024, 2025]:
		await _render(year)
	quit(0)


func _render(year: int) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(360, 480)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.07, 0.10)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.85, 1.0)
	e.ambient_light_energy = 1.0
	env.environment = e
	vp.add_child(env)
	var key := DirectionalLight3D.new()
	key.light_energy = 0.4
	key.rotation_degrees = Vector3(-32, 30, 0)
	vp.add_child(key)

	var visual := CharacterVisual.create("girl", 1.65, Color.WHITE)
	vp.add_child(visual)
	visual.apply_uniform(year)
	visual.rotation.y = 0.0
	_make_unshaded(visual)

	var cam := Camera3D.new()
	cam.fov = 26.0
	cam.position = Vector3(0.0, 1.0, 4.5)
	vp.add_child(cam)
	cam.look_at_from_position(cam.position, Vector3(0.0, 0.92, 0.0), Vector3.UP)

	for i in 12:
		await process_frame
	vp.get_texture().get_image().save_png(
		"res://docs/screenshots/godot/girl_debug_%d.png" % year)
	print("  girl debug %d" % year)
	vp.queue_free()


func _make_unshaded(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(i) as StandardMaterial3D
				if mat and mat.vertex_color_use_as_albedo:
					var dbg := StandardMaterial3D.new()
					dbg.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					dbg.vertex_color_use_as_albedo = true
					dbg.albedo_color = Color.WHITE
					dbg.cull_mode = BaseMaterial3D.CULL_DISABLED
					mi.set_surface_override_material(i, dbg)
	for c in node.get_children():
		_make_unshaded(c)
