extends SceneTree


func _initialize() -> void:
	var visual := CharacterVisual.create("girl", 1.65, Color.WHITE)
	var mi := _find_mesh(visual)
	var mesh := mi.mesh as ArrayMesh
	print("surfaces=", mesh.get_surface_count(), " blend_shapes=", mesh.get_blend_shape_count())
	for s in mesh.get_surface_count():
		print(" surface ", s, " name=", mesh.surface_get_name(s), " prim=", mesh.surface_get_primitive_type(s),
				" fmt=", mesh.surface_get_format(s), " mat=", mesh.surface_get_material(s))
		var arrays := mesh.surface_get_arrays(s)
		print("   arrays=", arrays.size())
		for i in arrays.size():
			if arrays[i] != null:
				print("     ", i, " ", typeof(arrays[i]))
	quit(0)


func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh:
		return node
	for c in node.get_children():
		var m := _find_mesh(c)
		if m:
			return m
	return null
