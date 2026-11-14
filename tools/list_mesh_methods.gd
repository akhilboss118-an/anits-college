extends SceneTree


func _initialize() -> void:
	for m in ClassDB.class_get_method_list("ArrayMesh", true):
		var n := str(m["name"])
		if n.contains("surface") or n.contains("attribute") or n.contains("clear"):
			print(n, " ", m["args"])
	quit(0)
