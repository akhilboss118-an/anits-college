extends SceneTree
## Debug probe for the year-based uniform hook: applies all three years and
## dumps each body surface's texture, plus the girl's chunni state.


func _initialize() -> void:
	for m in ["boy", "girl"]:
		print("=== %s ===" % m)
		var visual := CharacterVisual.create(m, 1.75 if m == "boy" else 1.65, Color.WHITE)
		for year in [2023, 2024, 2025]:
			visual.apply_uniform(year)
			var body: Array[String] = []
			var chunni := ""
			_dump_body(visual, body, func(v: Node) -> void:
				if v is MeshInstance3D and (v as MeshInstance3D).name == "Chunni":
					chunni = "visible" if (v as MeshInstance3D).visible else "hidden")
			print("  %d body=%s chunni=%s" % [year, str(body), chunni])
		visual.queue_free()
	await process_frame
	quit(0)


func _dump_body(node: Node, out: Array[String], visit: Callable) -> void:
	visit.call(node)
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(i) as StandardMaterial3D
				if mat and mat.resource_name.to_lower().contains("body"):
					var tex := "<none>"
					if mat.albedo_texture:
						tex = mat.albedo_texture.resource_path.get_file()
					out.append(tex)
	for c in node.get_children():
		_dump_body(c, out, visit)
