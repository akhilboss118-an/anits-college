class_name OriginalModels
extends RefCounted
## Loads the ORIGINAL web-game models (imported from third_party/anits_original)
## and fits them into the campus plots the same way the web game does.
##
## The web game scales each model with its own factor; the imported models are
## already in the same unit space three.js used, so the factors below reproduce
## the original's sizes exactly.

const MODEL_DIR := "res://third_party/anits_original/"

## model id -> [file, scale mode, value, y rotation (rad)]
##   scale mode "fit"  : fit the footprint into the target rect
##   scale mode "fixed": use the value as-is (the web game's own factor)
const MODELS := {
	"admin":   {"file": "b_admin.fbx", "mode": "fixed", "value": 0.98, "rot": 0.0},
	"aud":     {"file": "b_aud.glb", "mode": "fixed", "value": 1.6, "rot": 3.14159},
	"bank":    {"file": "b_bank.glb", "mode": "fit", "value": 1.0, "rot": 1.5708},
	"bench":   {"file": "b_bench.fbx", "mode": "fixed", "value": 0.286, "rot": 0.0},
	"brez":    {"file": "b_brez.glb", "mode": "fit", "value": 1.0, "rot": 0.0},
	"cafe":    {"file": "b_cafe.fbx", "mode": "fit", "value": 1.0, "rot": 0.0},
	"colonel": {"file": "b_colonel.glb", "mode": "height", "value": 1.85, "rot": 0.0},
	"drink":   {"file": "b_drink.fbx", "mode": "fixed", "value": 1.0, "rot": 0.0},
	"gate":    {"file": "b_gate.fbx", "mode": "fixed", "value": 0.95, "rot": 0.0},
	"grass":   {"file": "b_grass.fbx", "mode": "fixed", "value": 1.0, "rot": 0.0},
	"lp":      {"file": "b_lp.glb", "mode": "fit", "value": 1.0, "rot": 0.0},
	"phone":   {"file": "b_phone.fbx", "mode": "fixed", "value": 1.0, "rot": 0.0},
	"remy":    {"file": "b_remy.glb", "mode": "height", "value": 1.75, "rot": 0.0},
	"stairaud": {"file": "b_stairaud.glb", "mode": "fixed", "value": 1.0, "rot": 0.0},
	"temple":  {"file": "temple.glb", "mode": "fixed", "value": 11.0, "rot": 1.5708},
	"guard":   {"file": "guard.obj", "mode": "height", "value": 1.7, "rot": 0.0},
	"cadet_boy": {"file": "cadet_boy.glb", "mode": "height", "value": 1.7, "rot": 0.0},
	"cadet_amy": {"file": "cadet_amy.glb", "mode": "height", "value": 1.62, "rot": 0.0},
	"cadet_girl": {"file": "cadet_girl.glb", "mode": "height", "value": 1.6, "rot": 0.0},
	"laksmi":  {"file": "laksmi.glb", "mode": "height", "value": 1.7, "rot": 0.0},
	"desk":    {"file": "office_desk.glb", "mode": "fit", "value": 1.0, "rot": 0.0},
	"sofa":    {"file": "office_sofa.glb", "mode": "fit", "value": 1.0, "rot": 0.0},
	"toilet":  {"file": "office_toilet.glb", "mode": "fit", "value": 1.0, "rot": 0.0},
	"gattu":   {"file": "tree_gattu.glb", "mode": "fit", "value": 1.0, "rot": 0.0},
	"hoop":    {"file": "basketball_hoop.glb", "mode": "fixed", "value": 1.0, "rot": 0.0},
	"workshop": {"file": "workshop.glb", "mode": "fit", "value": 1.0, "rot": 0.0},
	"walk":    {"file": "b_walk.glb", "mode": "height", "value": 1.8, "rot": 0.0},
}

static var _cache := {}
static var _bounds := {}


## Loads (and caches) an imported model scene.
static func scene_for(model_id: String) -> PackedScene:
	if _cache.has(model_id):
		return _cache[model_id]
	var cfg: Dictionary = MODELS.get(model_id, {})
	if cfg.is_empty():
		return null
	var path := MODEL_DIR + str(cfg["file"])
	if not ResourceLoader.exists(path):
		return null
	var packed := load(path) as PackedScene
	_cache[model_id] = packed
	return packed


## The model's local bounds (computed once).
static func bounds_for(model_id: String) -> AABB:
	if _bounds.has(model_id):
		return _bounds[model_id]
	var packed := scene_for(model_id)
	if packed == null:
		return AABB()
	var inst := packed.instantiate()
	var box := _collect(inst, Transform3D())
	var has := box.size != Vector3.ZERO
	inst.free()
	if has:
		_bounds[model_id] = box
	return box


## Recursively merges every mesh under `node` into one AABB. The previous
## pass-by-value version lost the accumulator, so nested scenes returned an
## empty box and fit-mode buildings silently fell back to scale 1.0.
static func _collect(node: Node, parent_xf: Transform3D) -> AABB:
	var xf := parent_xf
	if node is Node3D:
		xf = parent_xf * (node as Node3D).transform
	var out := AABB()
	var has := false
	var mi := node as MeshInstance3D
	if mi and mi.mesh:
		out = xf * mi.mesh.get_aabb()
		has = true
	for child in node.get_children():
		var sub := _collect(child, xf)
		if sub.size == Vector3.ZERO:
			continue
		if has:
			out = out.merge(sub)
		else:
			out = sub
			has = true
	return out


## The scale the web game effectively used for this model inside the given rect.
static func scale_for(model_id: String, target_size: Vector2) -> float:
	var cfg: Dictionary = MODELS.get(model_id, {})
	if cfg.is_empty():
		return 1.0
	var mode := str(cfg.get("mode", "fit"))
	match mode:
		"fixed":
			return float(cfg.get("value", 1.0))
		"height":
			var box := bounds_for(model_id)
			if box.size.y <= 0.001:
				return 1.0
			return float(cfg.get("value", 1.0)) / box.size.y
		_:
			var b := bounds_for(model_id)
			if b.size.x <= 0.001 or b.size.y <= 0.001:
				return 1.0
			var sx := target_size.x / b.size.x
			var sz := target_size.y / b.size.z
			return minf(sx, sz) * float(cfg.get("value", 1.0))


## Instantiates a model, scaled and placed so its footprint sits on the rect.
static func place(model_id: String, parent: Node, centre: Vector3, target_size: Vector2,
		yaw := 0.0, target_y := 0.0) -> Node3D:
	var packed := scene_for(model_id)
	if packed == null:
		return null
	var inst := packed.instantiate()
	var scale := scale_for(model_id, target_size)
	inst.scale = Vector3(scale, scale, scale)
	inst.rotation.y = yaw
	inst.position = centre
	parent.add_child(inst)
	# sit the model on the ground
	var box := bounds_for(model_id)
	if box.size.y > 0.001:
		inst.position.y = target_y - box.position.y * scale
	return inst


## Merges a static model whose surfaces are all flat, opaque colours into one
## vertex-coloured mesh.  The original Admin model is 218 separate meshes and
## the Workshop 138; this turns each into a single draw call without changing
## the silhouette or the palette.  Textured / transparent models are left alone.
static func merge_flat_model(root: Node3D) -> bool:
	if root is MeshInstance3D:
		return false
	var meshes: Array = []
	_collect_meshes(root, meshes)
	var surfaces := 0
	for raw in meshes:
		var mesh: Mesh = (raw as MeshInstance3D).mesh
		if mesh:
			surfaces += mesh.get_surface_count()
	if surfaces <= 1:
		return false
	# Validate first: a texture, transparency or a shader material means this
	# model must keep its original materials and draw calls.
	for raw in meshes:
		var mi := raw as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var mat: Material = mi.get_active_material(s)
			if mat == null:
				continue
			if not (mat is StandardMaterial3D):
				return false
			var sm := mat as StandardMaterial3D
			if sm.albedo_texture != null:
				return false
			if sm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				return false
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var inv := root.global_transform.affine_inverse()
	for raw in meshes:
		var mi := raw as MeshInstance3D
		var xf := inv * mi.global_transform
		var normal_basis := xf.basis.inverse().transposed()
		for s in mi.mesh.get_surface_count():
			var arrays: Array = mi.mesh.surface_get_arrays(s)
			var sv: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var sn: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var si: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var mat: Material = mi.get_active_material(s)
			var col := Color.WHITE
			if mat is StandardMaterial3D:
				col = (mat as StandardMaterial3D).albedo_color
			var base := verts.size()
			for i in sv.size():
				verts.append(xf * sv[i])
				if i < sn.size():
					normals.append((normal_basis * sn[i]).normalized())
				else:
					normals.append(Vector3.UP)
				colors.append(col)
			if si.size() > 0:
				for idx in si:
					indices.append(base + idx)
			else:
				for i in range(0, sv.size() - 2, 3):
					indices.append(base + i)
					indices.append(base + i + 1)
					indices.append(base + i + 2)
	if verts.is_empty():
		return false
	var arrays_out: Array = []
	arrays_out.resize(Mesh.ARRAY_MAX)
	arrays_out[Mesh.ARRAY_VERTEX] = verts
	arrays_out[Mesh.ARRAY_NORMAL] = normals
	arrays_out[Mesh.ARRAY_COLOR] = colors
	arrays_out[Mesh.ARRAY_INDEX] = indices
	var merged := ArrayMesh.new()
	merged.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays_out)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color.WHITE
	material.roughness = 0.9
	material.metallic = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	var merged_mi := MeshInstance3D.new()
	merged_mi.name = "MergedModel"
	merged_mi.mesh = merged
	merged_mi.material_override = material
	for raw in meshes:
		var mi := raw as Node
		if mi.get_parent():
			mi.get_parent().remove_child(mi)
		mi.free()
	root.add_child(merged_mi)
	return true


static func _collect_meshes(node: Node, out: Array) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		out.append(node)
	for child in node.get_children():
		_collect_meshes(child, out)
