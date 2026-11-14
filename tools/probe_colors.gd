extends SceneTree


func _initialize() -> void:
	var visual := CharacterVisual.create("girl", 1.65, Color.WHITE)
	_walk(visual)
	await process_frame
	quit(0)


func _walk(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				var fmt: int = mi.mesh.surface_get_format(i)
				if not (fmt & Mesh.ARRAY_FORMAT_COLOR):
					continue
				var arrays := mi.mesh.surface_get_arrays(i)
				var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
				var hist := {}
				for c in cols:
					var key := "%.2f,%.2f,%.2f" % [c.r, c.g, c.b]
					hist[key] = int(hist.get(key, 0)) + 1
				var keys := hist.keys()
				keys.sort_custom(func(a, b): return int(hist[a]) > int(hist[b]))
				print("surface %d colors=%d unique=%d" % [i, cols.size(), keys.size()])
				for k in keys.slice(0, 16):
					print("   %s x%d" % [k, hist[k]])
	for c in node.get_children():
		_walk(c)
