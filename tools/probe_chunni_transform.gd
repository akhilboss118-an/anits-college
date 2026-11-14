extends SceneTree


func _initialize() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(360, 480)
	root.add_child(vp)
	var visual := CharacterVisual.create("girl", 1.65, Color.WHITE)
	vp.add_child(visual)
	visual.apply_uniform(2025)
	await process_frame
	await process_frame
	var chunni := visual.get("_chunni") as MeshInstance3D
	print("chunni=", chunni, " visible=", chunni.visible if chunni else false)
	if chunni:
		print("  parent=", chunni.get_parent())
		print("  global=", chunni.global_transform)
		print("  aabb=", chunni.get_aabb())
		print("  mesh aabb=", chunni.mesh.get_aabb() if chunni.mesh else "null")
		var attach := chunni.get_parent() as BoneAttachment3D
		if attach:
			print("  attach bone=", attach.bone_name, " transform=", attach.transform)
	var skel := _find_skel(visual)
	if skel:
		for i in skel.get_bone_count():
			if skel.get_bone_name(i).to_lower().contains("spine2"):
				print("  spine pose=", skel.get_bone_global_pose(i), " rest=", skel.get_bone_global_rest(i))
	print("holder scale=", visual.holder.scale if visual.holder else "null")
	quit(0)


func _find_skel(node: Node) -> Skeleton3D:
	for c in node.get_children():
		if c is Skeleton3D:
			return c
		var s := _find_skel(c)
		if s:
			return s
	return null
