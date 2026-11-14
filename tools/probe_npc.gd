extends SceneTree
## Debug probe: dump every MeshInstance3D under a character visual so we can
## see which parts render and which were hidden by the facial-overlay filter.
const MODELS := ["colonel", "cadet_boy", "laksmi", "guard", "remy"]


func _initialize() -> void:
	for m in MODELS:
		print("=== %s ===" % m)
		var visual := CharacterVisual.create(m, 1.75, Color.WHITE)
		_dump(visual, 0)
		visual.queue_free()
	await process_frame
	quit(0)


func _dump(node: Node, depth: int) -> void:
	var pad := "  ".repeat(depth)
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mesh_name: String = ""
		if mi.mesh:
			mesh_name = mi.mesh.resource_name if mi.mesh.resource_name != "" else str(mi.mesh)
		else:
			mesh_name = "<null-mesh>"
		print("%sMeshInstance3D '%s' visible=%s mesh=%s" % [pad, mi.name, str(mi.visible), mesh_name])
		if (node as MeshInstance3D).mesh:
			for i in (node as MeshInstance3D).mesh.get_surface_count():
				var m = (node as MeshInstance3D).mesh.surface_get_material(i)
				var mname: String = "<null>"
				if m:
					mname = str(m.resource_name) + " (" + m.get_class() + ")"
				print("%s    surface %d material=%s" % [pad, i, mname])
	for child in node.get_children():
		_dump(child, depth + 1)
