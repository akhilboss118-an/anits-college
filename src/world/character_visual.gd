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

## How fast the idle loop runs. The web build plays the cadet idle at 0.12
## ("same pose for everyone, only a very slow breath") and everything else at
## a slow sway - never at full speed.
const IDLE_SPEED := 0.15
const IDLE_SPEED_CADET := 0.12

## The web build tints the girl rig warm so she does not look like a twin of
## the boy player (js/game.js: m.color.setRGB(1,.74,.6)).
const GIRL_TINT := Color(1.0, 0.74, 0.6)

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
	if model_id == "girl" and _tint == Color.WHITE:
		_tint = GIRL_TINT

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
		self_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if _is_overlay_mesh(self_mi):
			# facial morph card - it renders as a white patch in Godot
			self_mi.visible = false
		else:
			for i in self_mi.mesh.get_surface_count():
				_tweak_surface(self_mi, i)
	for child in node.get_children():
		var mi := child as MeshInstance3D
		if mi and mi.mesh:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			if _is_overlay_mesh(mi):
				# facial morph card - it renders as a white patch in Godot
				mi.visible = false
			else:
				for i in mi.mesh.get_surface_count():
					_tweak_surface(mi, i)
		_tweak_materials(child)


## True when one of the mesh surfaces uses a material that only exists for the
## three.js face morphs. Remy's "Eyes" and "Eyelashes" meshes use the body
## atlas, so they stay visible.
func _is_overlay_mesh(mi: MeshInstance3D) -> bool:
	for i in mi.mesh.get_surface_count():
		var mat := mi.get_active_material(i)
		if mat is StandardMaterial3D:
			if _is_overlay_material(mat as StandardMaterial3D):
				return true
	return false


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

	if model_id == "colonel" and lower.contains("eyelash"):
		# b_colonel.glb repeats the whole body mesh under an "eyelashes"
		# material; drawing it twice only z-fights, so it is made invisible.
		copy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		copy.albedo_color = Color(1, 1, 1, 0)
		copy.albedo_texture = null
		copy.emission_enabled = false
		copy.emission_energy_multiplier = 0.0
		mi.set_surface_override_material(surface, copy)
		return

	# Keep the authored base colour; only the NPC tint multiplies it.
	if copy.albedo_texture == null:
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
