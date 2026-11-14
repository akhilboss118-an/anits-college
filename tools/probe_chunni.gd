extends SceneTree


func _initialize() -> void:
	var visual := CharacterVisual.create("girl", 1.65, Color.WHITE)
	var skel := _find_skel(visual)
	if skel:
		for n in ["mixamorig_Spine2", "mixamorig_Neck", "mixamorig_LeftArm",
				"mixamorig_RightArm", "mixamorig_Hips"]:
			for i in skel.get_bone_count():
				if skel.get_bone_name(i) == n:
					print("%s idx=%d rest=%s" % [n, i, str(skel.get_bone_global_rest(i).origin)])
	print("chunni=", visual.get("_chunni"))
	visual.apply_uniform(2025)
	print("after apply chunni=", visual.get("_chunni"))
	await process_frame
	quit(0)


func _find_skel(node: Node) -> Skeleton3D:
	for c in node.get_children():
		if c is Skeleton3D:
			return c
		var s := _find_skel(c)
		if s:
			return s
	return null
