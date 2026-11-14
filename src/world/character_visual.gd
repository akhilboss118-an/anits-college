class_name CharacterVisual
extends Node3D
## The original web-game characters, imported from third_party/anits_original:
##   boy / girl (player, walk + salute)
##   remy (students, walk)
##   cadet_boy / cadet_girl (NCC, idle + salute)
##   colonel (idle + salute), laksmi, guard (static)
##
## Each visual normalises the model to a target height, tweaks the materials the
## same way the web build does (matte, lightly emissive, no metalness), finds the
## AnimationPlayer and exposes simple play/stop/salute calls.
##
## Everything below mirrors js/game.js of the original web build:
##   * every textured surface keeps its own texture and its own base colour;
##     only the NPC tint multiplies it,
##   * the Mixamo facial morph cards (BLEND materials named Eyes / Brows /
##     Mouth) are hidden - Remy's real eyes and eyelashes are NOT,
##   * the guard gets the web palette applied by material name,
##   * the cadets get the NCC beret + belt, rigged to their head / spine bone,
##   * the animations are paused while the NPC is far away.

const DIR := "res://third_party/anits_original/"

## model id -> forward travel of its walk cycle, in model units. Measured once,
## because the imported Animation resources are shared between all instances.
static var _stride_cache: Dictionary = {}

## The web build's guard colours (js/game.js). The guard is the original OBJ
## (guard.obj + guard.mtl), so the palette is reapplied by material name.
const GUARD_PALETTE := {
	"Vaquero": "#2d4061",
	"Piel": "#f8b48d",
	"Camisa": "#74a6fd",
	"Botas": "#1a1a1e",
	"Chaleco": "#2c2f35",
}

## The guard's boots and vest are the only shiny parts of the web model
## (MeshPhongMaterial with a dark specular), the rest is matte Lambert.
const GUARD_SHINY := ["Botas", "Chaleco"]

## Surface order of the guard OBJ, used only if the importer ever drops the
## material names (the names do survive the OBJ import).
const GUARD_ORDER := ["Vaquero", "Piel", "Botas", "Camisa", "Chaleco"]

## The NCC kit the web build bolts onto the cadets (js/game.js): a beret with a
## brass badge plus a leather belt with a brass buckle.
const NCC_BERET := "#1a2a5a"
const NCC_BELT := "#2a1c10"
const NCC_BUCKLE := "#c9a227"
const NCC_BADGE := "#d8c24a"

## Material names that only exist to drive the three.js facial morph targets.
## In Godot they render as white glasses / moustache cards, so the meshes that
## use them are hidden - exactly like the web build does (js/game.js hides any
## mesh whose material is BLEND or is named Eyes / Brows / Mouth).
const OVERLAY_KEYS := ["eyes", "brows", "mouth"]

const MODELS := {
	"boy":         {"file": "b_walk.glb", "walk": "walk", "idle": "", "talk": "talk", "salute": "salute"},
	"girl":        {"file": "cadet_amy.glb", "walk": "walk", "idle": "", "talk": "talk", "salute": "salute"},
	"remy":        {"file": "b_remy.glb", "walk": "mixamo_com", "idle": "", "talk": "", "salute": ""},
	"cadet_boy":   {"file": "cadet_boy.glb", "walk": "", "idle": "idle", "talk": "", "salute": "salute"},
	"cadet_girl":  {"file": "cadet_girl.glb", "walk": "", "idle": "idle", "talk": "", "salute": "salute"},
	"colonel":     {"file": "b_colonel.glb", "walk": "", "idle": "idle", "talk": "", "salute": "salute"},
	"laksmi":      {"file": "laksmi.glb", "walk": "", "idle": "", "talk": "", "salute": ""},
	"guard":       {"file": "guard.obj", "walk": "", "idle": "", "talk": "", "salute": ""},
}

## Per model surface setup, taken from the web build's material fixes:
## matte (roughness .9 / .85), no metalness, a soft self-illumination so the
## characters do not go dark in shadow, and half strength normal maps.
const SURFACE := {
	"boy":        {"roughness": 0.9, "emission": 0.05, "normal_scale": 0.5},
	"girl":       {"roughness": 0.9, "emission": 0.05, "normal_scale": 0.5},
	"remy":       {"roughness": 0.8, "emission": 0.04, "normal_scale": 1.0},
	"cadet_boy":  {"roughness": 0.9, "emission": 0.05, "normal_scale": 1.0},
	"cadet_girl": {"roughness": 0.9, "emission": 0.05, "normal_scale": 1.0},
	"colonel":    {"roughness": 0.9, "emission": 0.05, "normal_scale": 1.0},
	"laksmi":     {"roughness": 0.85, "emission": 0.05, "normal_scale": 1.0},
	"guard":      {"roughness": 0.9, "emission": 0.0, "normal_scale": 1.0},
}

## Year-based uniforms, exactly the three body textures used by the web build
## (js/uniform.js). 2024 is the original cream/brown texture that ships with
## the two player models; 2023 and 2025 replace it with the rose and sky-blue
## sheets. The paths are relative to the project root, not the web folder.
const UNIFORM_TEXTURES := {
	2023: {
		"boy": "res://third_party/anits_original/uni2023_boy.jpg",
		"girl": "res://third_party/anits_original/uni2023_amy.jpg",
	},
	2025: {
		"boy": "res://third_party/anits_original/uni2025_boy.jpg",
		"girl": "res://third_party/anits_original/uni2025_amy.jpg",
	},
}

## Chunni (dupatta) colours for the girl rig: [fabric, emissive], taken from
## js/uniform.js. 2024 has no chunni, like the web build.
const CHUNNI_COLOURS := {
	2023: [Color(0.086, 0.086, 0.106), Color(0.020, 0.020, 0.027)],
	2025: [Color(0.043, 0.082, 0.267), Color(0.016, 0.039, 0.157)],
}

## The girl's clothing panels live in the Acc_MAT surface's COLOR_0 array, not
## in the body texture. These are the exact three source/target pairs from
## js/uniform.js (cream, brown, tan -> rose/black or sky/navy).
const UNIFORM_VCOL := {
	2023: [
		[Color(0.86, 0.80, 0.68), Color(0.60, 0.32, 0.42)],
		[Color(0.30, 0.21, 0.15), Color(0.48, 0.24, 0.33)],
		[Color(0.54, 0.42, 0.29), Color(0.03, 0.03, 0.04)],
	],
	2025: [
		[Color(0.86, 0.80, 0.68), Color(0.22, 0.45, 0.68)],
		[Color(0.30, 0.21, 0.15), Color(0.19, 0.35, 0.55)],
		[Color(0.54, 0.42, 0.29), Color(0.04, 0.07, 0.20)],
	],
}

## How fast the idle loop runs. The web build plays the cadet idle at 0.12
## ("same pose for everyone, only a very slow breath") and everything else at
## a slow sway - never at full speed.
const IDLE_SPEED := 0.15
const IDLE_SPEED_CADET := 0.12



## Bones the NCC kit is rigged to.
const HEAD_BONES := ["mixamorighead", "head"]
const SPINE_BONES := ["mixamorigspine1", "mixamorigspine"]

var model_id: String = ""
var height: float = 1.75
var anim: AnimationPlayer = null
var holder: Node3D = null
var walk_clip: String = ""
var idle_clip: String = ""
var talk_clip: String = ""
var salute_clip: String = ""

var _walking := false
var _talking := false
var _saluting := false
var _breath := 0.0
var _has_anim := false
var _tint := Color.WHITE
var _idle_speed := IDLE_SPEED
var _frozen := false
var _frozen_anim := ""
var _frozen_pos := 0.0
var _walk_speed := 1.4
var _run_lean := 0.0
## Metres the walk cycle covers in one loop, measured from the imported Hips
## track exactly like the web build's `stride * pk`. Playback is driven from
## this so the feet always move at the same speed as the character.
var _stride_m := 1.4

# --- year-based uniform (player + menu previews) --------------------------
var _uniform_year := 2024
var _body_surfaces: Array = []      ## body material copies + original textures
var _vertex_surfaces: Array = []    ## girl clothing surfaces + COLOR_0 arrays
var _chunni: MeshInstance3D = null  ## girl-only dupatta for 2023 / 2025
var _chunni_attach: BoneAttachment3D = null

# --- NCC kit (cadets only) -----------------------------------------------
var _kit_beret: Node3D = null
var _kit_belt: Node3D = null
var _kit_skel: Skeleton3D = null
var _kit_head := -1
var _kit_spine := -1
var _kit_rel := Transform3D.IDENTITY
var _kit_head_rest := Transform3D.IDENTITY
var _kit_spine_rest := Transform3D.IDENTITY
var _kit_beret_rest := Transform3D.IDENTITY
var _kit_belt_rest := Transform3D.IDENTITY


static func create(new_id: String, target_height: float, tint: Color = Color.WHITE) -> CharacterVisual:
	var v := CharacterVisual.new()
	v.model_id = new_id
	v.height = target_height
	v._tint = tint
	v.build()
	return v


func build() -> void:
	var cfg: Dictionary = MODELS.get(model_id, {})
	if cfg.is_empty():
		return
	var path := DIR + str(cfg.get("file", ""))
	if not ResourceLoader.exists(path):
		return
	var res := load(path)
	if res == null:
		return
	holder = Node3D.new()
	holder.name = "Model"
	add_child(holder)
	var inst: Node3D
	if res is PackedScene:
		inst = (res as PackedScene).instantiate() as Node3D
	elif res is Mesh:
		# The guard is an OBJ: it imports as a Mesh resource, not a scene.
		var mi := MeshInstance3D.new()
		mi.mesh = res as Mesh
		inst = mi
	else:
		return
	holder.add_child(inst)

	var model_scale := 1.0
	var box := _bounds(inst)
	if box.size.y > 0.001:
		var s := height / box.size.y
		model_scale = s
		inst.scale = Vector3(s, s, s)
		inst.position.y = -box.position.y * s
	anim = _find_anim(inst)
	walk_clip = _resolve_clip(anim, str(cfg.get("walk", "")))
	idle_clip = _resolve_clip(anim, str(cfg.get("idle", "")))
	talk_clip = _resolve_clip(anim, str(cfg.get("talk", "")))
	salute_clip = _resolve_clip(anim, str(cfg.get("salute", "")))
	_idle_speed = IDLE_SPEED_CADET if model_id.begins_with("cadet") else IDLE_SPEED
	if anim and walk_clip != "":
		# The Mixamo walk travels forward on the Hips track. Strip that motion
		# (the web build zeroes it too) and keep its length as the stride. The
		# Animation is a shared resource, so the travel is measured once per
		# model and cached in model units.
		if _stride_cache.has(model_id):
			var travel: float = float(_stride_cache[model_id])
			if travel > 0.05:
				_stride_m = travel * model_scale
		else:
			var measured := _bake_in_place(anim, walk_clip)
			_stride_cache[model_id] = measured
			if measured > 0.05:
				_stride_m = measured * model_scale

	if anim:
		_has_anim = true
		if idle_clip != "" and anim.has_animation(idle_clip):
			anim.play(idle_clip)
			anim.speed_scale = _idle_speed
			# the web build starts the commander idle on a random frame so the
			# NPCs are not all breathing in lockstep
			if not model_id.begins_with("cadet"):
				var clip := anim.get_animation(idle_clip)
				if clip and clip.length > 0.0:
					anim.seek(randf() * clip.length, true)
		elif walk_clip != "" and anim.has_animation(walk_clip):
			anim.play(walk_clip)
			anim.speed_scale = 0.0
		anim.animation_finished.connect(_on_anim_finished)

	_tweak_materials(inst)
	_collect_uniform_surfaces(inst)


## Bakes every Hips position track in place: X/Z are pinned to the first key
## (the Y bob stays), exactly like the web build's `v[i*3]=v[0]; v[i*3+2]=v[2]`.
## Returns the forward travel of `walk_name` in model units so the caller can
## convert it to the real stride of the cycle.
func _bake_in_place(player: AnimationPlayer, walk_name: String) -> float:
	var travel := 0.0
	for clip_name in player.get_animation_list():
		var a := player.get_animation(clip_name)
		if a == null:
			continue
		for t in a.get_track_count():
			if a.track_get_type(t) != Animation.TYPE_POSITION_3D:
				continue
			var track_path := str(a.track_get_path(t))
			if track_path.findn("Hips") < 0:
				continue
			var keys := a.track_get_key_count(t)
			if keys == 0:
				continue
			var first: Vector3 = a.track_get_key_value(t, 0)
			if str(clip_name) == walk_name:
				var last: Vector3 = a.track_get_key_value(t, keys - 1)
				travel = maxf(travel, absf(last.z - first.z))
				travel = maxf(travel, absf(last.x - first.x))
			for k in keys:
				var v: Vector3 = a.track_get_key_value(t, k)
				a.track_set_key_value(t, k, Vector3(first.x, v.y, first.z))
	return travel


## Finds the imported clip. Godot may sanitise the glTF animation name (the
## Remy walk is "mixamo.com" in the file), so the usual spellings are tried.
func _resolve_clip(anim: AnimationPlayer, wanted: String) -> String:
	if anim == null or wanted == "":
		return ""
	if anim.has_animation(wanted):
		return wanted
	var variants := [wanted.replace("_", "."), wanted.replace("_", ""), wanted.replace(".", "_")]
	for v in variants:
		var name := str(v)
		if name != "" and name != wanted and anim.has_animation(name):
			return name
	return ""


func _process(delta: float) -> void:
	if not visible:
		return
	if _kit_beret != null:
		_update_kit()
	if holder and _has_anim:
		# The original run clip is not in the exported character files, so the
		# walk cycle is driven fast for running and the body leans into it.
		holder.rotation.x = lerpf(holder.rotation.x, _run_lean, minf(1.0, delta * 6.0))
	if holder and not _has_anim:
		# static models breathe very slightly, like the web build
		_breath += delta
		holder.scale.y = 1.0 + sin(_breath * 1.6) * 0.004
		if model_id == "guard":
			# slow weight shift
			holder.rotation.z = sin(_breath * 0.55) * 0.014


## Bounding box of everything under `node`, in `node`'s own space. The node
## transforms are accumulated so a model nested under a helper node still
## measures its real height.
func _bounds(node: Node, xform: Transform3D = Transform3D.IDENTITY) -> AABB:
	var box := AABB()
	var has := false
	for child in node.get_children():
		var t: Transform3D = xform
		if child is Node3D:
			t = xform * (child as Node3D).transform
		var mi := child as MeshInstance3D
		if mi and mi.mesh:
			var local := mi.get_aabb()
			for p in [local.position, local.position + local.size]:
				var world: Vector3 = t * p
				if has:
					box = box.expand(world)
				else:
					box = AABB(world, Vector3.ZERO)
					has = true
		var sub := _bounds(child, t)
		if sub.size != Vector3.ZERO:
			if has:
				box = box.expand(sub.position)
				box = box.expand(sub.position + sub.size)
			else:
				box = sub
				has = true
	return box


func _find_anim(node: Node) -> AnimationPlayer:
	for child in node.get_children():
		if child is AnimationPlayer:
			return child
		var found := _find_anim(child)
		if found:
			return found
	return null


func _find_skeleton(node: Node) -> Skeleton3D:
	for child in node.get_children():
		if child is Skeleton3D:
			return child
		var found := _find_skeleton(child)
		if found:
			return found
	return null


# ---------------------------------------------------------------- materials

func _tweak_materials(node: Node) -> void:
	# The node itself may already be the mesh (the OBJ guard), so it is handled
	# here as well as its children.
	var self_mi := node as MeshInstance3D
	if self_mi and self_mi.mesh:
		_tweak_mesh(self_mi)
	for child in node.get_children():
		var mi := child as MeshInstance3D
		if mi and mi.mesh:
			_tweak_mesh(mi)
		_tweak_materials(child)


func _tweak_mesh(mi: MeshInstance3D) -> void:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var surface_count := mi.mesh.get_surface_count()
	# Only hide the whole mesh when EVERY surface is a facial morph card.
	# b_colonel.glb repeats his body under a transparent eyelash material on
	# the same mesh; hiding the mesh removes the real body and head, so the
	# overlay surfaces are hidden individually instead.
	var all_overlay := surface_count > 0
	for i in surface_count:
		var mat := mi.get_active_material(i)
		var overlay := false
		if mat is StandardMaterial3D and _is_overlay_material(mat as StandardMaterial3D):
			overlay = true
		if not overlay:
			all_overlay = false
	if all_overlay:
		# Facial morph card - it renders as a white patch in Godot.
		mi.visible = false
		return
	for i in surface_count:
		_tweak_surface(mi, i)


## True when the surface is a facial morph card (e.g. the transparent BLEND
## materials Mixamo bakes for eyes / brows / mouth).
func _is_overlay_material(mat: StandardMaterial3D) -> bool:
	# a fully transparent BLEND card (the Mixamo FacialAnimMap materials)
	if mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and mat.albedo_color.a <= 0.02:
		return true
	var lower := mat.resource_name.to_lower()
	for key in OVERLAY_KEYS:
		if lower.contains(key):
			return true
	return false


func _tweak_surface(mi: MeshInstance3D, surface: int) -> void:
	var mat := mi.get_active_material(surface)
	if not (mat is StandardMaterial3D):
		return
	var src := mat as StandardMaterial3D
	var copy := src.duplicate() as StandardMaterial3D
	var mat_name := src.resource_name
	var lower := mat_name.to_lower()
	var cfg: Dictionary = SURFACE.get(model_id, {})

	copy.metallic = 0.0
	copy.roughness = float(cfg.get("roughness", 0.9))
	# a little less than the default sheen: cloth, not plastic
	copy.metallic_specular = 0.35
	copy.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if copy.normal_enabled and copy.normal_texture:
		copy.normal_scale = float(cfg.get("normal_scale", 1.0))

	if model_id == "guard":
		# the guard palette is applied by material name, like the web build
		var key := _guard_key(mat_name, surface)
		if key != "":
			copy.albedo_color = Color.html(str(GUARD_PALETTE[key]))
			copy.albedo_texture = null
			copy.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			copy.emission_enabled = false
			copy.emission_energy_multiplier = 0.0
			if key in GUARD_SHINY:
				# boots and vest: a little sheen, like the web Phong material
				copy.roughness = 0.35
				copy.metallic_specular = 0.5
			else:
				copy.roughness = 0.9
				copy.metallic_specular = 0.15
		mi.set_surface_override_material(surface, copy)
		return

	if _is_overlay_material(src):
		# Facial morph cards (eyes / brows / mouth / the colonel's duplicated
		# transparent eyelash body) are invisible, per surface.
		copy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		copy.albedo_color = Color(1, 1, 1, 0)
		copy.albedo_texture = null
		copy.emission_enabled = false
		copy.emission_energy_multiplier = 0.0
		mi.set_surface_override_material(surface, copy)
		return

	# Keep the authored base colour; only the NPC tint multiplies it. The girl
	# GLB is the exception: its authored albedo is a leftover orange FBX
	# colour (1, 0.548, 0.36). The web build throws it away - white for the
	# player, g.tint for the girl students - so use the tint alone there.
	if model_id == "girl":
		copy.albedo_color = Color(_tint.r, _tint.g, _tint.b, src.albedo_color.a)
	elif copy.albedo_texture == null:
		copy.albedo_color = Color(src.albedo_color.r * _tint.r,
			src.albedo_color.g * _tint.g, src.albedo_color.b * _tint.b, 1.0)
	else:
		copy.albedo_color = Color(src.albedo_color.r * _tint.r,
			src.albedo_color.g * _tint.g, src.albedo_color.b * _tint.b,
			src.albedo_color.a)
	var fmt: int = int(mi.mesh.surface_get_format(surface))
	if fmt & Mesh.ARRAY_FORMAT_COLOR:
		# COLOR_0 carries the original hair / accessory / clothing colours.
		copy.vertex_color_use_as_albedo = true
	var emit := float(cfg.get("emission", 0.05))
	if copy.albedo_texture and emit > 0.0:
		# a whisper of self-illumination so the characters keep their colour in
		# shadow (the web build does the same with emissiveMap = map)
		copy.emission_enabled = true
		copy.emission = Color(emit * _tint.r, emit * _tint.g, emit * _tint.b)
		copy.emission_texture = copy.albedo_texture
		copy.emission_energy_multiplier = 1.0
	else:
		copy.emission_enabled = false
		copy.emission_energy_multiplier = 0.0
	mi.set_surface_override_material(surface, copy)


## The guard palette key for a surface: the material name first (the names do
## survive the glTF import), the surface order as a safety net.
func _guard_key(mat_name: String, surface: int) -> String:
	var lower := mat_name.strip_edges().to_lower()
	for part in GUARD_PALETTE:
		if lower == part.to_lower():
			return str(part)
	if surface >= 0 and surface < GUARD_ORDER.size():
		return GUARD_ORDER[surface]
	return ""


# ---------------------------------------------------------------- uniforms

## Applies one of the three joining-year uniforms to this visual. Only the two
## player models have uniforms; NPCs keep their authored clothes.
func apply_uniform(year: int) -> void:
	if year != 2023 and year != 2024 and year != 2025:
		year = 2024
	_uniform_year = year

	var tex: Texture2D = null
	if year != 2024:
		tex = _uniform_texture(year)
		if tex == null:
			push_warning("Uniform %d texture missing for model '%s'" % [year, model_id])

	for part in _body_surfaces:
		var mat := part.get("material") as StandardMaterial3D
		if mat == null:
			continue
		var use: Texture2D = tex
		if use == null:
			use = part.get("original") as Texture2D
		mat.albedo_texture = use
		if mat.emission_enabled:
			mat.emission_texture = use

	_apply_vertex_colours(year)
	_apply_chunni(year)


func _uniform_texture(year: int) -> Texture2D:
	var table: Dictionary = UNIFORM_TEXTURES.get(year, {})
	var path := str(table.get(model_id, ""))
	if path == "" or not ResourceLoader.exists(path):
		return null
	var res := load(path)
	return res as Texture2D


## Remembers the body surface and its original cream/brown texture, plus the
## girl's vertex-coloured clothing surface. The materials are the duplicates
## made by `_tweak_surface`, so changing them only affects this character.
func _collect_uniform_surfaces(node: Node) -> void:
	if not _body_surfaces.is_empty() or not _vertex_surfaces.is_empty():
		return
	var mi := node as MeshInstance3D
	if mi and mi.mesh:
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(i) as StandardMaterial3D
			if mat == null:
				continue
			var fmt: int = mi.mesh.surface_get_format(i)
			if mat.resource_name.to_lower().contains("body"):
				_body_surfaces.append({
					"mesh": mi,
					"surface": i,
					"material": mat,
					"original": mat.albedo_texture,
				})
			if model_id == "girl" and mat.vertex_color_use_as_albedo \
					and (fmt & Mesh.ARRAY_FORMAT_COLOR):
				var arrays := mi.mesh.surface_get_arrays(i)
				_vertex_surfaces.append({
					"mesh": mi,
					"surface": i,
					"original_mesh": mi.mesh,
					"original_colors": arrays[Mesh.ARRAY_COLOR],
					"mesh_copy": null,
				})
	for child in node.get_children():
		_collect_uniform_surfaces(child)


## Recolours the girl's cream/brown/tan clothing panels by rewriting the
## COLOR_0 array. The mesh is duplicated first, because the imported mesh is
## shared with the menu preview and any other instance.
func _apply_vertex_colours(year: int) -> void:
	for part in _vertex_surfaces:
		var mi := part.get("mesh") as MeshInstance3D
		if mi == null or not is_instance_valid(mi):
			continue
		var original_mesh := part.get("original_mesh") as ArrayMesh
		if original_mesh == null:
			continue
		if year == 2024:
			mi.mesh = original_mesh
			continue
		# The year slider can fire dozens of times, so each recoloured mesh is
		# built once and cached on the part.
		var copies: Dictionary = part.get("mesh_copies", {})
		part["mesh_copies"] = copies
		var copy := copies.get(year) as ArrayMesh
		if copy == null:
			var surface := int(part.get("surface", 0))
			var source := part.get("original_colors") as PackedColorArray
			var cols := PackedColorArray()
			cols.resize(source.size())
			for i in source.size():
				cols[i] = _map_uniform_colour(source[i], year)
			# ArrayMesh has no surface_set_arrays() in Godot 4.7, so the
			# duplicate is rebuilt surface by surface with the recoloured
			# COLOR_0 array.
			copy = ArrayMesh.new()
			for s in original_mesh.get_surface_count():
				var arrays := original_mesh.surface_get_arrays(s)
				if s == surface:
					arrays[Mesh.ARRAY_COLOR] = cols
				copy.add_surface_from_arrays(original_mesh.surface_get_primitive_type(s), arrays)
				copy.surface_set_name(s, original_mesh.surface_get_name(s))
				copy.surface_set_material(s, original_mesh.surface_get_material(s))
			copies[year] = copy
		mi.mesh = copy


func _map_uniform_colour(colour: Color, year: int) -> Color:
	var table: Array = UNIFORM_VCOL.get(year, [])
	for pair in table:
		var from: Color = pair[0]
		if absf(colour.r - from.r) < 0.04 \
				and absf(colour.g - from.g) < 0.04 \
				and absf(colour.b - from.b) < 0.04:
			var to: Color = pair[1]
			return Color(to.r, to.g, to.b, colour.a)
	return colour


## The girl rig gets a navy/black chunni for 2023 and 2025, mirroring the
## ribbon mesh built by js/uniform.js. It is parented to Spine2 through a
## BoneAttachment3D, so it follows the walk, talk and salute animations.
func _apply_chunni(year: int) -> void:
	if model_id != "girl":
		return
	if year == 2024:
		if _chunni:
			_chunni.visible = false
		return
	if _chunni == null:
		_build_chunni()
	if _chunni == null:
		return
	var colours: Array = CHUNNI_COLOURS.get(year, [])
	if colours.size() >= 2:
		var mat := _chunni.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = colours[0]
			mat.emission = colours[1]
	_chunni.visible = true


func _build_chunni() -> void:
	if holder == null:
		return
	var skel := _find_skeleton(holder)
	if skel == null:
		return
	var spine := _find_bone(skel, ["mixamorigspine2", "spine2"])
	var neck := _find_bone(skel, ["mixamorigneck", "neck"])
	var left_arm := _find_bone(skel, ["mixamorigleftarm", "leftarm"])
	var right_arm := _find_bone(skel, ["mixamorigrightarm", "rightarm"])
	var hips := _find_bone(skel, ["mixamorighips", "hips"])
	if spine < 0 or neck < 0 or left_arm < 0 or right_arm < 0 or hips < 0:
		return

	var neck_t := skel.get_bone_global_rest(neck)
	var left_t := skel.get_bone_global_rest(left_arm)
	var right_t := skel.get_bone_global_rest(right_arm)
	var hips_t := skel.get_bone_global_rest(hips)
	var n := neck_t.origin
	var a := left_t.origin
	var b := right_t.origin
	var h := hips_t.origin
	var w := a.distance_to(b)
	var u := n.y - h.y
	var cx := (a.x + b.x) * 0.5
	var cz := (a.z + b.z) * 0.5
	var s := signf(a.x - b.x)
	if is_zero_approx(s):
		s = 1.0
	if w < 0.001 or absf(u) < 0.001:
		return

	# The control polygon from js/uniform.js, mirrored around the back.
	var half := [
		Vector3(0.20, h.y + 0.04 * u, 0.44),
		Vector3(0.24, h.y + 0.40 * u, 0.45),
		Vector3(0.34, n.y - 0.08 * u, 0.34),
		Vector3(0.44, n.y - 0.01 * u, 0.12),
		Vector3(0.42, n.y + 0.01 * u, -0.12),
		Vector3(0.27, n.y + 0.01 * u, -0.34),
	]
	var pts: Array[Vector3] = []
	for p in half:
		pts.append(Vector3(cx + float(p.x) * w * s, float(p.y), cz + float(p.z) * w))
	pts.append(Vector3(cx, n.y + 0.01 * u, cz - 0.4 * w))
	for i in range(half.size() - 1, -1, -1):
		var p: Vector3 = half[i]
		pts.append(Vector3(cx - float(p.x) * w * s, float(p.y), cz + float(p.z) * w))

	var curve := Curve3D.new()
	curve.bake_interval = 0.01
	for p in pts:
		curve.add_point(p)
	var total := curve.get_baked_length()
	if total < 0.001:
		return

	var spine_inv := skel.get_bone_global_rest(spine).affine_inverse()
	var samples := 90
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in samples + 1:
		var t := float(i) / float(samples)
		var p := curve.sample_baked(total * t)
		var ahead := curve.sample_baked(total * minf(t + 0.004, 1.0))
		var behind := curve.sample_baked(total * maxf(t - 0.004, 0.0))
		var tangent := (ahead - behind).normalized()
		if tangent.length_squared() < 0.5:
			tangent = Vector3(0.0, 0.0, 1.0)
		var ay := minf(p.y, n.y - 0.3 * u)
		var outward := Vector3(p.x - cx, p.y - ay, p.z - cz)
		if outward.length_squared() < 0.0001:
			outward = Vector3(0.0, 0.0, 1.0)
		outward = outward.normalized()
		var side := tangent.cross(outward)
		if side.length_squared() < 0.0001:
			side = Vector3(1.0, 0.0, 0.0)
		side = side.normalized()
		var half_w := w * (0.17 + 0.05 * sin(PI * t))
		var centre := p + outward * 0.02
		st.add_vertex(spine_inv * (centre + side * half_w))
		st.add_vertex(spine_inv * (centre - side * half_w))
	for i in samples:
		var k := i * 2
		st.add_index(k)
		st.add_index(k + 1)
		st.add_index(k + 2)
		st.add_index(k + 1)
		st.add_index(k + 3)
		st.add_index(k + 2)
	st.generate_normals()

	var mat := StandardMaterial3D.new()
	mat.resource_name = "Chunni"
	mat.albedo_color = Color(0.086, 0.086, 0.106)
	mat.roughness = 0.9
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = Color(0.020, 0.020, 0.027)
	mat.emission_energy_multiplier = 0.8

	_chunni = MeshInstance3D.new()
	_chunni.name = "Chunni"
	_chunni.mesh = st.commit()
	_chunni.material_override = mat
	_chunni.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_chunni.visible = false

	_chunni_attach = BoneAttachment3D.new()
	_chunni_attach.name = "ChunniBone"
	_chunni_attach.bone_name = skel.get_bone_name(spine)
	skel.add_child(_chunni_attach)
	_chunni_attach.add_child(_chunni)


# ------------------------------------------------------------------- the NCC kit

## Adds the NCC kit (beret + belt) the web build bolts onto the cadets.
## `colour` is the beret colour from the NPC data (#1a2a5a for the cadets).
func set_beret_colour(colour: Color) -> void:
	if _kit_beret != null or colour.a <= 0.0:
		return
	if not model_id.begins_with("cadet"):
		return
	_build_ncc_kit(colour)


func _build_ncc_kit(colour: Color) -> void:
	var skel := _find_skeleton(holder)
	if skel == null:
		return
	var head := _find_bone(skel, HEAD_BONES)
	var spine := _find_bone(skel, SPINE_BONES)
	if head < 0 or spine < 0:
		return
	if not _is_descendant(skel, holder):
		return
	_kit_skel = skel
	_kit_head = head
	_kit_spine = spine
	_kit_rel = _relative_to(skel, holder)
	_kit_head_rest = _kit_rel * skel.get_bone_global_rest(head)
	_kit_spine_rest = _kit_rel * skel.get_bone_global_rest(spine)
	# the beret sits on top of the head, the belt around the waist
	_kit_beret_rest = Transform3D(Basis.from_euler(Vector3(0.08, 0.0, -0.14)),
		Vector3(_kit_head_rest.origin.x, height - 0.055, _kit_head_rest.origin.z + 0.012))
	_kit_belt_rest = Transform3D(Basis.IDENTITY,
		Vector3(_kit_spine_rest.origin.x, height * 0.585, _kit_spine_rest.origin.z))
	_kit_beret = _make_beret(colour)
	_kit_belt = _make_belt()
	holder.add_child(_kit_beret)
	holder.add_child(_kit_belt)
	_update_kit()


## Finds a bone by (normalised) name, so "mixamorigHead" and "mixamorig:Head"
## both match.
func _find_bone(skel: Skeleton3D, names: Array) -> int:
	var wanted := {}
	for n in names:
		wanted[_normalise_bone(str(n))] = true
	for i in skel.get_bone_count():
		if wanted.has(_normalise_bone(skel.get_bone_name(i))):
			return i
	return -1


func _normalise_bone(bone_name: String) -> String:
	var out := ""
	for c in bone_name.to_lower():
		if c >= "a" and c <= "z" or c >= "0" and c <= "9":
			out += c
	return out


## Transform of `node` relative to `ancestor`.
func _relative_to(node: Node, ancestor: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != ancestor:
		t = n.transform * t
		n = n.get_parent()
	return t


## True when `node` sits under `ancestor`.
func _is_descendant(node: Node, ancestor: Node) -> bool:
	var n: Node = node
	while n != null:
		if n == ancestor:
			return true
		n = n.get_parent()
	return false


func _make_beret(colour: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Beret"
	var disc := MeshInstance3D.new()
	disc.name = "Disc"
	var sphere := SphereMesh.new()
	sphere.radius = 0.125
	sphere.height = 0.25
	sphere.radial_segments = 18
	sphere.rings = 10
	disc.mesh = sphere
	disc.material_override = _flat_material(colour, 0.95, 0.0)
	disc.scale = Vector3(1.0, 0.42, 1.05)
	root.add_child(disc)
	var nub := MeshInstance3D.new()
	nub.name = "Nub"
	var nub_mesh := CylinderMesh.new()
	nub_mesh.top_radius = 0.008
	nub_mesh.bottom_radius = 0.008
	nub_mesh.height = 0.02
	nub_mesh.radial_segments = 6
	nub.mesh = nub_mesh
	nub.material_override = _flat_material(colour, 0.95, 0.0)
	nub.position = Vector3(0.0, 0.052, 0.0)
	root.add_child(nub)
	var badge := MeshInstance3D.new()
	badge.name = "Badge"
	var badge_mesh := CylinderMesh.new()
	badge_mesh.top_radius = 0.016
	badge_mesh.bottom_radius = 0.016
	badge_mesh.height = 0.006
	badge_mesh.radial_segments = 10
	badge.mesh = badge_mesh
	badge.material_override = _flat_material(Color.html(NCC_BADGE), 0.4, 0.5)
	badge.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	badge.position = Vector3(-0.05, 0.0, 0.1)
	root.add_child(badge)
	return root


func _make_belt() -> Node3D:
	var root := Node3D.new()
	root.name = "Belt"
	var band := MeshInstance3D.new()
	band.name = "Band"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.05
	cyl.radial_segments = 24
	cyl.cap_top = false
	cyl.cap_bottom = false
	band.mesh = cyl
	band.material_override = _flat_material(Color.html(NCC_BELT), 0.75, 0.0)
	band.scale = Vector3(0.175, 1.0, 0.125)
	root.add_child(band)
	var buckle := MeshInstance3D.new()
	buckle.name = "Buckle"
	var box := BoxMesh.new()
	box.size = Vector3(0.05, 0.045, 0.012)
	buckle.mesh = box
	buckle.material_override = _flat_material(Color.html(NCC_BUCKLE), 0.35, 0.6)
	buckle.position = Vector3(0.0, 0.0, 0.128)
	root.add_child(buckle)
	return root


func _flat_material(colour: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = roughness
	m.metallic = metallic
	m.metallic_specular = 0.4
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


## Keeps the beret and the belt glued to the head / spine bone while the drill
## animation runs.
func _update_kit() -> void:
	if _kit_skel == null or _kit_beret == null:
		return
	var head_now := _kit_rel * _kit_skel.get_bone_global_pose(_kit_head)
	_kit_beret.transform = head_now * _kit_head_rest.affine_inverse() * _kit_beret_rest
	if _kit_belt != null:
		var spine_now := _kit_rel * _kit_skel.get_bone_global_pose(_kit_spine)
		_kit_belt.transform = spine_now * _kit_spine_rest.affine_inverse() * _kit_belt_rest


# --------------------------------------------------------------- animations

## walk animation on/off; `speed` is metres per second so the feet match.
func set_moving(moving: bool, speed := 1.4) -> void:
	if not _has_anim or _talking:
		return
	if walk_clip == "" or not anim.has_animation(walk_clip):
		return
	_walk_speed = speed
	_run_lean = 0.12 if (moving and speed > 4.0) else 0.0
	if moving:
		_walking = true
		if _frozen:
			# the AnimationPlayer is paused, the state is all that matters
			return
		if _saluting:
			# the drill is over, let the walk take over
			_saluting = false
		if anim.current_animation != walk_clip or not anim.is_playing():
			anim.play(walk_clip)
		anim.speed_scale = _walk_rate(speed)
	elif _walking:
		# freeze on a "legs passing" pose instead of the mid-air frame
		_walking = false
		if _frozen:
			return
		anim.speed_scale = 0.0
		anim.seek(0.04, true)


## Hides the model and stops its AnimationPlayer when it is far away.
func set_active(active: bool) -> void:
	if visible == active:
		return
	visible = active
	set_process(active)
	if anim == null:
		return
	if active:
		_resume_anim()
	else:
		_freeze_anim()


## Pauses the AnimationPlayer so 64 idle skeletons do not cost anything while
## their NPC is out of sight.
func _freeze_anim() -> void:
	if anim == null or not anim.is_playing():
		return
	_frozen = true
	_frozen_anim = str(anim.current_animation)
	_frozen_pos = anim.current_animation_position
	anim.pause()


func _resume_anim() -> void:
	if anim == null or not _frozen:
		return
	_frozen = false
	if _talking and talk_clip != "" and anim.has_animation(talk_clip):
		anim.play(talk_clip)
		anim.speed_scale = 1.0
		return
	var clip := _frozen_anim
	if clip != "" and anim.has_animation(clip):
		anim.play(clip)
		anim.seek(_frozen_pos, true)
		anim.speed_scale = _current_speed()
	else:
		_restore()


## Cycles per second that make the feet match the ground speed. Mirrors
## js/game.js `clamp(spd / (stride * pk), .5, 3.2)`.
func _walk_rate(speed: float) -> float:
	return clampf(speed / maxf(_stride_m, 0.25), 0.45, 3.2)


## The playback speed the current state asks for.
func _current_speed() -> float:
	if _talking and talk_clip != "" and anim.has_animation(talk_clip):
		return 1.0
	if _walking and walk_clip != "" and anim.has_animation(walk_clip):
		return _walk_rate(_walk_speed)
	if idle_clip != "" and anim.has_animation(idle_clip):
		return _idle_speed
	return 0.0


func set_talking(talking: bool) -> void:
	_talking = talking
	if not _has_anim or _frozen:
		return
	if talking and talk_clip != "" and anim.has_animation(talk_clip):
		anim.play(talk_clip)
		anim.speed_scale = 1.0
	elif not talking:
		_restore()


func play_salute(delay := 0.0) -> void:
	if not _has_anim or salute_clip == "" or not anim.has_animation(salute_clip):
		return
	if not visible:
		# out of sight: there is nobody to salute
		return
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if not is_inside_tree() or not visible:
		return
	_saluting = true
	anim.play(salute_clip)
	anim.speed_scale = 1.0


func _on_anim_finished(name: String) -> void:
	if name == salute_clip:
		_saluting = false
		_restore()
	elif _saluting:
		# the salute was cut short (the NPC started walking or talking)
		_saluting = false


func _restore() -> void:
	if not _has_anim:
		return
	if _talking and talk_clip != "" and anim.has_animation(talk_clip):
		anim.play(talk_clip)
		anim.speed_scale = 1.0
	elif idle_clip != "" and anim.has_animation(idle_clip):
		anim.play(idle_clip)
		anim.speed_scale = _idle_speed
	elif walk_clip != "" and anim.has_animation(walk_clip):
		anim.play(walk_clip)
		anim.speed_scale = 0.0
		anim.seek(0.04, true)
