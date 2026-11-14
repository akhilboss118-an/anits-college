extends SceneTree


func _initialize() -> void:
	var visual := CharacterVisual.create("girl", 1.65, Color.WHITE)
	_walk(visual)
	visual.apply_uniform(2025)
	print("--- after apply 2025 ---")
	_walk2(visual)
	await process_frame
	quit(0)


func _walk(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(i) as StandardMaterial3D
				if mat == null:
					continue
				print("MI '%s' s%d mat='%s' albedo=%s tex=%s vcol=%s emission=%s" % [
					mi.name, i, mat.resource_name, str(mat.albedo_color),
					mat.albedo_texture.resource_path.get_file() if mat.albedo_texture else "<none>",
					str(mat.vertex_color_use_as_albedo), str(mat.emission)])
	for c in node.get_children():
		_walk(c)


func _walk2(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(i) as StandardMaterial3D
				if mat == null:
					continue
				print("MI '%s' s%d mat='%s' albedo=%s tex=%s vcol=%s" % [
					mi.name, i, mat.resource_name, str(mat.albedo_color),
					mat.albedo_texture.resource_path.get_file() if mat.albedo_texture else "<none>",
					str(mat.vertex_color_use_as_albedo)])
	for c in node.get_children():
		_walk2(c)
