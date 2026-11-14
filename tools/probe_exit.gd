extends SceneTree
## Minimal shutdown probe for the uniform code path.


func _initialize() -> void:
	var year := 2024
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--year="):
			year = int(a.split("=")[1])
	print("creating girl year ", year)
	var visual := CharacterVisual.create("girl", 1.65, Color.WHITE)
	visual.apply_uniform(year)
	root.add_child(visual)
	await process_frame
	visual.queue_free()
	await process_frame
	print("done")
	quit(0)
