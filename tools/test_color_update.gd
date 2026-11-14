extends SceneTree


func _initialize() -> void:
	var visual := CharacterVisual.create("girl", 1.65, Color.WHITE)
	var mi := _find_mesh(visual)
	if mi == null:
		print("no mesh")
		quit(1)
		return
	var mesh := mi.mesh as ArrayMesh
	var copy := mesh.duplicate() as ArrayMesh
	var s := 1
	var arrays := copy.surface_get_arrays(s)
	var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	print("before ", cols[0])
	var out := PackedColorArray()
	out.resize(cols.size())
	for i in cols.size():
		out[i] = Color(1, 0, 1, cols[i].a)
	var bytes := out.to_byte_array()
	print("bytes=", bytes.size(), " expected=", cols.size() * 16)
	copy.surface_update_attribute_region(s, 0, bytes)
	var after := copy.surface_get_arrays(s)[Mesh.ARRAY_COLOR] as PackedColorArray
	print("after ", after[0], " count=", after.size())
	quit(0)


func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh:
		return node
	for c in node.get_children():
		var m := _find_mesh(c)
		if m:
			return m
	return null
