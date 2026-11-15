class_name PropsFactory
extends RefCounted
## Instanced campus scenery built from the asset packs downloaded for this
## project, so nothing is downloaded at runtime:
##
##   * Quaternius "Stylized Nature MegaKit" (CC0) - res://glTF:
##       CommonTree / Pine / TwistedTree / DeadTree, bushes, ferns, clover,
##       flowers, grass, rocks and pebbles.  Meshes keep the pack's vertex
##       colours; foliage gets a small wind shader.
##   * Road Generator pack - its two-lane asphalt texture drives the roads.
##   * SimpleGrassTextured pack - its grass card texture is used for the
##       denser roadside tufts.
##   * Controller Icons - keyboard key art for the HUD (read by hud.gd).
##
## Everything is cached.  Repeated props are MultiMeshes, so a whole species is
## one draw call per surface.
##
## Renderer notes - every shader in this file must work in BOTH Forward+ and
## the GL Compatibility renderer (mobile / web):
##   * Only plain spatial shaders are used.  There is no depth texture, no
##     screen texture, no normal/roughness texture, no custom light() or
##     fwd_light() functions and no extra lights: all of those are either
##     unsupported in Compatibility mode or far too expensive on a phone.
##   * What IS used is supported by both renderers: varyings, value noise,
##     CAMERA_POSITION_WORLD, TIME, dFdx()/dFdy(), vertex colours and
##     MultiMesh instance colours.
##   * All procedural detail is static (no TIME term), so the ground, roads
##     and sand never shimmer and cost nothing extra per frame.
##   * Noise is limited to a few taps per pixel; the ground uses three, the
##     asphalt two, the road two and the sand two.

const NATURE_DIR := "res://glTF/"
const ROAD_TEXTURE := "res://addons/road-generator/resources/road_texture.png"
const GRASS_CARD_TEXTURE := "res://addons/simplegrasstextured/textures/grassbushcc008.png"

## Court texture layout: a 30 x 17 m plane with the 28 x 15 m court painted
## inside it.  One texture keeps every line, key and arc in a single draw call.
const COURT_TEX_W := 512
const COURT_TEX_H := 290
const COURT_TEX_X0 := -15.0
const COURT_TEX_Z0 := -8.5
const COURT_TEX_W_M := 30.0
const COURT_TEX_H_M := 17.0

## Species names must match the glTF files in res://glTF.
const SPECIES := {
	"tree": ["CommonTree_1", "CommonTree_2", "CommonTree_3", "CommonTree_4", "CommonTree_5"],
	"pine": ["Pine_1", "Pine_2", "Pine_3", "Pine_4", "Pine_5"],
	"twisted": ["TwistedTree_1", "TwistedTree_2", "TwistedTree_3", "TwistedTree_4", "TwistedTree_5"],
	"dead": ["DeadTree_1", "DeadTree_2", "DeadTree_3", "DeadTree_4", "DeadTree_5"],
	"bush": ["Bush_Common"],
	"flower_bush": ["Bush_Common_Flowers"],
	"fern": ["Fern_1"],
	"clover": ["Clover_1", "Clover_2"],
	"flower": ["Flower_3_Group", "Flower_4_Group"],
	"grass": ["Grass_Common_Short", "Grass_Common_Tall", "Grass_Wispy_Short", "Grass_Wispy_Tall"],
	"rock": ["Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"],
	"pebble": ["Pebble_Round_1", "Pebble_Round_2", "Pebble_Square_1"],
	"stepping_stone": ["RockPath_Round_Wide", "RockPath_Square_Wide"],
}

## Cheapest species for the mobile / GL-Compatibility pass.  The twisted and
## dead trees are 9-10 k triangles each, so they stay desktop-only.
const LOW_POLY_SPECIES := {
	"tree": ["CommonTree_3", "CommonTree_5"],
	"pine": ["Pine_4", "Pine_5"],
	"bush": ["Bush_Common"],
	"flower_bush": ["Bush_Common_Flowers"],
}

static var _models: Dictionary = {}
static var _materials: Dictionary = {}
static var _meshes: Dictionary = {}
static var _textures: Dictionary = {}
static var _foliage_shader: Shader = null


# ------------------------------------------------------------------ models

static func model(model_id: String) -> Dictionary:
	if _models.has(model_id):
		return _models[model_id]
	var entry: Dictionary = {"id": model_id, "parts": [], "height": 1.0, "ok": false}
	var path: String = NATURE_DIR + model_id + ".gltf"
	if not ResourceLoader.exists(path):
		_models[model_id] = entry
		return entry
	var packed := load(path) as PackedScene
	if packed == null:
		_models[model_id] = entry
		return entry
	var inst := packed.instantiate()
	var mi := _first_mesh_instance(inst)
	if mi == null or mi.mesh == null:
		inst.free()
		_models[model_id] = entry
		return entry
	var source: Mesh = mi.mesh
	var bounds := source.get_aabb()
	var offset := Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z)
	for surface in source.get_surface_count():
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.append_from(source, surface, Transform3D(Basis(), offset))
		var part_mesh := st.commit()
		entry["parts"].append({
			"mesh": part_mesh,
			"surface": surface,
			"source_material": mi.get_active_material(surface),
		})
	entry["height"] = maxf(bounds.size.y, 0.2)
	entry["ok"] = true
	inst.free()
	_models[model_id] = entry
	return entry


static func model_height(model_id: String) -> float:
	return float(model(model_id).get("height", 1.0))


static func part_mesh(model_id: String, surface: int) -> Mesh:
	var parts: Array = model(model_id).get("parts", [])
	if surface < 0 or surface >= parts.size():
		return null
	return parts[surface]["mesh"] as Mesh


static func part_material(model_id: String, surface: int) -> Material:
	var key := model_id + "#" + str(surface)
	if _materials.has(key):
		return _materials[key]
	var entry := model(model_id)
	var parts: Array = entry.get("parts", [])
	if surface < 0 or surface >= parts.size():
		return null
	var source_material: Material = parts[surface]["source_material"]
	var height := float(entry.get("height", 1.0))
	var mat := _make_material(model_id, surface, source_material, height)
	_materials[key] = mat
	return mat


static func _first_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _first_mesh_instance(child)
		if found:
			return found
	return null


static func _make_material(model_id: String, surface: int, source: Material, height: float) -> Material:
	var foliage := _is_foliage(model_id, surface)
	var tex: Texture2D = null
	if source is StandardMaterial3D:
		tex = (source as StandardMaterial3D).albedo_texture
	if foliage and tex != null:
		return _foliage_material(tex, height, _wind_for(model_id), _alpha_for(model_id),
				_ao_for(model_id))
	var m := StandardMaterial3D.new()
	if source is StandardMaterial3D:
		m = (source as StandardMaterial3D).duplicate() as StandardMaterial3D
	# The pack's own vertex colours stay untouched: they carry the bark and
	# leaf tinting, and the MultiMesh instance colour (the per-prop tint) is
	# multiplied on top of them by the engine.
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color.WHITE
	m.roughness = 0.95
	m.metallic = 0.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


static func _is_foliage(model_id: String, surface: int) -> bool:
	if model_id.begins_with("Grass") or model_id.begins_with("Fern"):
		return true
	if model_id.begins_with("Clover") or model_id.begins_with("Flower") or model_id.begins_with("Plant"):
		return true
	if model_id.begins_with("Bush"):
		return true
	if model_id.contains("Tree") and surface > 0:
		return true
	return false


static func _wind_for(model_id: String) -> float:
	if model_id.begins_with("Grass_Wispy"):
		return 0.18
	if model_id.begins_with("Grass"):
		return 0.12
	if model_id.begins_with("Fern"):
		return 0.08
	if model_id.begins_with("Flower"):
		return 0.06
	if model_id.begins_with("Bush"):
		return 0.085
	if model_id.begins_with("Pine"):
		return 0.14
	if model_id.contains("Tree"):
		return 0.22
	return 0.08


static func _alpha_for(model_id: String) -> float:
	if model_id.begins_with("Grass"):
		return 0.0
	if model_id.begins_with("Fern") or model_id.begins_with("Clover"):
		return 0.30
	if model_id.begins_with("Flower"):
		return 0.28
	if model_id.begins_with("Bush"):
		return 0.35
	return 0.35


## How strongly the bottom of a plant is darkened (fake ambient occlusion).
## Canopies get the most, small ground plants almost none.
static func _ao_for(model_id: String) -> float:
	if model_id.begins_with("Grass") or model_id.begins_with("Clover"):
		return 0.08
	if model_id.begins_with("Fern"):
		return 0.12
	if model_id.begins_with("Flower"):
		return 0.16
	if model_id.begins_with("Bush"):
		return 0.22
	return 0.26


static func _foliage_material(tex: Texture2D, height: float, wind: float, alpha_cut: float,
		ao_strength: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _get_foliage_shader()
	m.set_shader_parameter("albedo_tex", tex)
	m.set_shader_parameter("model_height", maxf(height, 0.2))
	m.set_shader_parameter("wind_strength", wind)
	m.set_shader_parameter("alpha_cut", alpha_cut)
	m.set_shader_parameter("ao_strength", ao_strength)
	return m


static func _get_foliage_shader() -> Shader:
	if _foliage_shader != null:
		return _foliage_shader
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley, specular_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float model_height = 1.0;
uniform float wind_strength = 0.05;
uniform float wind_speed = 1.2;
uniform float alpha_cut = 0.35;
uniform float ao_strength = 0.26;
uniform float tint_jitter = 0.09;
uniform vec3 base_tint : source_color = vec3(1.0);

varying float v_height;
varying float v_jitter;

// One cheap hash, used to give every instance its own static colour jitter.
float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float phase = origin.x * 0.31 + origin.z * 0.23;
	float h = clamp(VERTEX.y / max(model_height, 0.05), 0.0, 1.0);
	v_height = h;
	// Static per-instance value: two trees of the same species never look
	// stamped out of the same mould.  One hash per vertex, no time term.
	v_jitter = hash11(dot(origin.xz, vec2(12.9898, 78.233)) + origin.y * 0.37);
	float bend = pow(h, 1.5);
	float gust = sin(TIME * wind_speed + phase) * 0.65
		+ sin(TIME * wind_speed * 0.38 + phase * 1.7) * 0.25
		+ sin(TIME * wind_speed * 1.82 + phase * 3.1) * 0.10;
	float gust_z = cos(TIME * wind_speed * 0.76 + phase * 1.1) * 0.65
		+ sin(TIME * wind_speed * 1.4 + phase * 2.3) * 0.20;
	VERTEX.x += gust * wind_strength * bend;
	VERTEX.z += gust_z * wind_strength * 0.65 * bend;
}

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	if (tex.a < alpha_cut) {
		discard;
	}
	// COLOR carries the pack's own vertex colours multiplied by the
	// MultiMesh instance tint, so the original colouring is preserved.
	vec3 col = tex.rgb * COLOR.rgb * base_tint;
	// Gentle per-instance colour jitter for depth.
	col *= mix(1.0 - tint_jitter, 1.0 + tint_jitter, v_jitter);
	// Cheap fake ambient occlusion: the base of a bush or of a canopy is
	// darker than its top, which is what gives the props their volume.
	float ao = 1.0 - ao_strength * (1.0 - smoothstep(0.0, 0.55, v_height));
	col *= ao;
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	BACKLIGHT = col * 0.3;
}
"""
	_foliage_shader = sh
	return sh


# ------------------------------------------------------------------ grass cards

## Three crossed alpha cards (6 triangles) replace the 155-622 triangle glTF
## grass tufts.  At 2-4 k instances this is the single biggest triangle cut in
## the scene while actually looking denser than the old thin meshes.
static func grass_card_mesh() -> Mesh:
	if _meshes.has("grass_card"):
		return _meshes["grass_card"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 3:
		var yaw := float(i) * PI / 3.0
		var right := Vector3(cos(yaw), 0.0, sin(yaw)) * 0.55
		var bl := -right
		var br := right
		var tl := -right + Vector3.UP
		var tr := right + Vector3.UP
		# Normal points up so the card catches the same light as the lawn
		# instead of turning black when the camera looks at its back face.
		var n := Vector3.UP
		st.set_normal(n); st.set_uv(Vector2(0.0, 1.0)); st.add_vertex(bl)
		st.set_normal(n); st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(br)
		st.set_normal(n); st.set_uv(Vector2(1.0, 0.0)); st.add_vertex(tr)
		st.set_normal(n); st.set_uv(Vector2(0.0, 1.0)); st.add_vertex(bl)
		st.set_normal(n); st.set_uv(Vector2(1.0, 0.0)); st.add_vertex(tr)
		st.set_normal(n); st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(tl)
	var mesh := st.commit()
	_meshes["grass_card"] = mesh
	return mesh


static func grass_card_material() -> ShaderMaterial:
	if _materials.has("grass_card_mat"):
		return _materials["grass_card_mat"]
	var tex := load(GRASS_CARD_TEXTURE) as Texture2D
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley, specular_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear, repeat_disable;
uniform float alpha_cut = 0.35;
uniform float wind_strength = 0.055;
uniform float wind_speed = 1.45;

varying float v_height;

void vertex() {
	float h = clamp(VERTEX.y, 0.0, 1.0);
	v_height = h;
	vec3 origin = MODEL_MATRIX[3].xyz;
	float phase = origin.x * 0.31 + origin.z * 0.23;
	float gust = sin(TIME * wind_speed + phase) * 0.72
		+ sin(TIME * wind_speed * 0.41 + phase * 1.7) * 0.28;
	float bend = pow(h, 1.35);
	VERTEX.x += gust * wind_strength * bend;
	VERTEX.z += cos(TIME * wind_speed * 0.83 + phase * 1.1) * wind_strength * 0.35 * bend;
}

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	if (tex.a < alpha_cut) {
		discard;
	}
	vec3 col = tex.rgb * COLOR.rgb;
	// Slightly darker roots, brighter tips: cheap depth without another pass.
	col *= mix(0.74, 1.05, v_height);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	BACKLIGHT = col * 0.35;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("albedo_tex", tex)
	_materials["grass_card_mat"] = m
	return m


# ------------------------------------------------------------------ basketball net

## A low-poly net for the campus hoops: ten cords and three rings as thin
## triangles.  Both hoops share this one mesh, so the whole net costs two draw
## calls and a few hundred triangles.
static func hoop_net_mesh() -> Mesh:
	if _meshes.has("hoop_net"):
		return _meshes["hoop_net"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top_r := 0.225
	var bottom_r := 0.135
	var drop := 0.46
	for i in 10:
		var a := TAU * float(i) / 10.0
		var b := a + 0.24
		var top := Vector3(cos(a) * top_r, 0.0, sin(a) * top_r)
		var bottom := Vector3(cos(b) * bottom_r, -drop, sin(b) * bottom_r)
		var side := (bottom - top).normalized().cross(Vector3.UP).normalized() * 0.009
		var n := Vector3(cos(a), 0.0, sin(a))
		_net_quad(st, top - side, top + side, bottom + side, bottom - side, n)
	for ring_i in 3:
		var t := float(ring_i + 1) / 4.0
		var y := -drop * t
		var radius := lerpf(top_r, bottom_r, t)
		var segments := 18
		for i in segments:
			var a0 := TAU * float(i) / float(segments)
			var a1 := TAU * float(i + 1) / float(segments)
			var inner0 := Vector3(cos(a0) * (radius - 0.008), y, sin(a0) * (radius - 0.008))
			var outer0 := Vector3(cos(a0) * (radius + 0.008), y, sin(a0) * (radius + 0.008))
			var inner1 := Vector3(cos(a1) * (radius - 0.008), y, sin(a1) * (radius - 0.008))
			var outer1 := Vector3(cos(a1) * (radius + 0.008), y, sin(a1) * (radius + 0.008))
			_net_quad(st, inner0, outer0, outer1, inner1, Vector3.UP)
	var mesh := st.commit()
	_meshes["hoop_net"] = mesh
	return mesh


static func _net_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		n: Vector3) -> void:
	for v in [a, b, c, a, c, d]:
		st.set_normal(n)
		st.add_vertex(v)


static func hoop_net_material() -> StandardMaterial3D:
	if _materials.has("hoop_net"):
		return _materials["hoop_net"]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.html("#f4f2e6")
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials["hoop_net"] = m
	return m


# ------------------------------------------------------------------ props

## One InstancedMesh batch with optional per-instance tint.
static func batch(name: String, mesh: Mesh, transforms: Array, material: Material,
		colors: Array = [], cast_shadow := true) -> MultiMeshInstance3D:
	if transforms.is_empty() or mesh == null:
		return null
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colors.is_empty()
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		var raw: Variant = transforms[i]
		var xf := Transform3D.IDENTITY
		if raw is Transform3D:
			xf = raw
		elif raw is Vector3:
			xf = Transform3D(Basis(), raw)
		elif raw is Vector2:
			xf = Transform3D(Basis(), Vector3(raw.x, 0.0, raw.y))
		mm.set_instance_transform(i, xf)
		if not colors.is_empty():
			mm.set_instance_color(i, colors[i % colors.size()])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = name
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mmi


# ------------------------------------------------------------------ cars

static func car_body() -> Mesh:
	if _meshes.has("car_body"):
		return _meshes["car_body"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(st, Vector3(1.86, 0.58, 4.18), Vector3(0, 0.79, 0))
	_add_box(st, Vector3(1.72, 0.20, 1.18), Vector3(0, 1.06, 1.42))
	_add_box(st, Vector3(1.72, 0.18, 1.00), Vector3(0, 1.06, -1.55))
	_add_box(st, Vector3(1.62, 0.10, 2.02), Vector3(0, 1.63, -0.22))
	for side in [-1.0, 1.0]:
		_add_box(st, Vector3(0.06, 0.42, 1.88), Vector3(0.92 * float(side), 1.32, -0.22))
	var mesh := st.commit()
	_meshes["car_body"] = mesh
	return mesh


static func car_glass() -> Mesh:
	if _meshes.has("car_glass"):
		return _meshes["car_glass"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(st, Vector3(1.56, 0.46, 1.92), Vector3(0, 1.34, -0.22))
	_add_box(st, Vector3(1.46, 0.30, 0.90), Vector3(0, 1.34, 0.95))
	var mesh := st.commit()
	_meshes["car_glass"] = mesh
	return mesh


static func car_wheels() -> Mesh:
	if _meshes.has("car_wheels"):
		return _meshes["car_wheels"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in [-0.94, 0.94]:
		for z in [-1.38, 1.38]:
			var wheel := CylinderMesh.new()
			wheel.top_radius = 0.35
			wheel.bottom_radius = 0.35
			wheel.height = 0.26
			wheel.radial_segments = 10
			var basis := Basis(Vector3(0, 0, 1), PI * 0.5)
			st.append_from(wheel, 0, Transform3D(basis, Vector3(float(x), 0.36, float(z))))
	var mesh := st.commit()
	_meshes["car_wheels"] = mesh
	return mesh


static func _add_box(st: SurfaceTool, size: Vector3, pos: Vector3) -> void:
	var box := BoxMesh.new()
	box.size = size
	st.append_from(box, 0, Transform3D(Basis(), pos))


static func car_material() -> Material:
	if _materials.has("car"):
		return _materials["car"]
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.35
	m.metallic = 0.18
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	_materials["car"] = m
	return m


static func glass_material() -> Material:
	if _materials.has("glass"):
		return _materials["glass"]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.09, 0.14, 0.19)
	m.metallic = 0.45
	m.roughness = 0.15
	_materials["glass"] = m
	return m


static func wheel_material() -> Material:
	if _materials.has("wheel"):
		return _materials["wheel"]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.html("#1b1d21")
	m.roughness = 0.95
	_materials["wheel"] = m
	return m


# ------------------------------------------------------------------ ground

static func ground_material() -> ShaderMaterial:
	if _materials.has("ground"):
		return _materials["ground"]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode diffuse_burley, specular_disabled;

varying vec3 world_pos;

uniform vec3 grass_dark : source_color = vec3(0.17, 0.27, 0.10);
uniform vec3 grass_light : source_color = vec3(0.34, 0.46, 0.20);
uniform vec3 grass_dry : source_color = vec3(0.46, 0.43, 0.24);
uniform vec3 grass_haze : source_color = vec3(0.38, 0.45, 0.34);
uniform float stripe_amount = 0.11;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float dist = distance(world_pos, CAMERA_POSITION_WORLD);
	// Fine detail is faded out with distance so the far lawn never shimmers
	// or crawls as the camera moves.
	float detail = 1.0 - smoothstep(18.0, 110.0, dist);

	// Three octaves: broad patches (26 m), mid clumps (6 m), fine mottling.
	float n_wide = vnoise(p * 0.038);
	float n_mid = vnoise(p * 0.155);
	float n_fine = mix(0.5, vnoise(p * 0.78), detail);

	// Two saturated greens, mixed by the mid and wide noise.
	vec3 col = mix(grass_dark, grass_light, smoothstep(0.22, 0.80, n_mid * 0.62 + n_wide * 0.38));
	// Sun-bleached / dry patches.
	float dry = smoothstep(0.64, 0.92, n_wide * 0.65 + n_mid * 0.35);
	col = mix(col, grass_dry, dry * 0.45);
	// Fine mottling so the lawn never reads as flat paint.
	col *= 0.88 + n_fine * 0.24;
	col *= 0.97 + vnoise(p * 2.7) * 0.06 * detail;

	// Gentle mowing stripes (diagonal, very low contrast).
	float stripe = sin(p.x * 0.16 + p.y * 0.05) * 0.5 + 0.5;
	col *= 1.0 - stripe_amount + stripe * stripe_amount * 2.0;

	// The mown campus lawn sits a few centimetres above the outer field
	// (CampusBuilder puts the field at y = 0 and the lawn at y = 0.04), so
	// the height tells the two apart: keep the lawn fresher and let the
	// field drift a little drier.  If those heights ever change, this split
	// has to change with them.
	float mown = smoothstep(0.005, 0.03, world_pos.y);
	col = mix(col, mix(col, grass_dry, 0.18), 1.0 - mown);
	col = mix(col, col * vec3(1.03, 1.05, 0.98), mown);

	// Aerial perspective: desaturate and lift the far tone.
	float haze = smoothstep(60.0, 320.0, dist);
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, mix(vec3(lum), grass_haze, 0.55), haze * 0.40);

	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	_materials["ground"] = m
	return m


## Plain asphalt for the wide roads and the parking apron.
## Returns a ShaderMaterial now (it used to be a StandardMaterial3D): the
## extra wear, the polished tyre streaks and the grime along the slab borders
## all need the world position, which a StandardMaterial3D cannot express.
## Only campus_builder.gd consumes it, and it just hands it to a mesh.
static func asphalt_material() -> Material:
	if _materials.has("asphalt"):
		return _materials["asphalt"]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode diffuse_burley;

uniform sampler2D asphalt_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float texture_scale = 0.22;
uniform vec3 dirt_tint : source_color = vec3(0.34, 0.29, 0.22);
uniform float edge_width = 0.85;

varying vec3 world_pos;
varying vec3 world_normal;
varying vec2 face_uv;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	face_uv = UV;
}

// How many metres one full 0..1 UV range covers on this face.  Rebuilt from
// screen-space derivatives, so the grime band keeps a constant width in
// metres whether it sits on a 12 m street or on the whole parking apron.
float uv_span_metres(float u, vec3 wp) {
	vec2 duv = vec2(dFdx(u), dFdy(u));
	vec3 dwx = dFdx(wp);
	vec3 dwy = dFdy(wp);
	float den = dot(duv, duv);
	if (den < 1e-9) {
		return 0.0;
	}
	float mx = (dwx.x * duv.x + dwy.x * duv.y) / den;
	float mz = (dwx.z * duv.x + dwy.z * duv.y) / den;
	// A slab is never hundreds of metres wide; the clamp keeps a broken UV
	// layout from turning the whole surface into grime.
	return min(length(vec2(mx, mz)), 400.0);
}

void fragment() {
	// --- base asphalt, triplanar so no slab ever shows a stretched face ---
	vec3 n = abs(world_normal);
	n = pow(n, vec3(6.0));
	n /= max(n.x + n.y + n.z, 0.0001);
	vec3 cx = texture(asphalt_tex, world_pos.zy * texture_scale).rgb;
	vec3 cy = texture(asphalt_tex, world_pos.xz * texture_scale).rgb;
	vec3 cz = texture(asphalt_tex, world_pos.xy * texture_scale).rgb;
	vec3 base = cx * n.x + cy * n.y + cz * n.z;

	// --- patchy asphalt: old repairs, oil stains, bleached spots ---
	float m = vnoise(world_pos.xz * 0.45);
	base *= 0.86 + m * 0.26;

	// --- tyre wear: long polished streaks, a touch darker and much smoother ---
	float streak = vnoise(world_pos.xz * vec2(0.07, 0.55));
	float polish = smoothstep(0.35, 0.85, streak);

	// --- grime along the borders of the slab, measured in metres ---
	float span_u = uv_span_metres(face_uv.x, world_pos);
	float span_v = uv_span_metres(face_uv.y, world_pos);
	float du = min(face_uv.x, 1.0 - face_uv.x) * span_u;
	float dv = min(face_uv.y, 1.0 - face_uv.y) * span_v;
	float edge = 1.0 - smoothstep(0.0, edge_width, min(du, dv));
	edge *= step(0.7, abs(world_normal.y));

	ALBEDO = mix(base, dirt_tint, edge * 0.55);
	ROUGHNESS = mix(0.97, 0.74, polish);
	SPECULAR = 0.16;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	var tex := tiling_texture(128, Color.html("#454a52"), 0.09, 23, "asphalt")
	if tex:
		m.set_shader_parameter("asphalt_tex", tex)
	_materials["asphalt"] = m
	return m


## Two-lane road surface using the Road Generator pack's actual road texture.
## The lane markings live in that texture and are kept exactly as they are;
## everything else (tyre wear, patchy asphalt, kerb-side grime) is layered on
## top of them in UV space.  U runs across the width of the road (0 = left
## kerb, 1 = right kerb) and V along its length, which is what road_mesh()
## bakes in - so the tyre tracks always follow the road, whatever way it is
## turned.
static func road_material() -> ShaderMaterial:
	if _materials.has("road_surface"):
		return _materials["road_surface"]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
// Double-sided: the generated road quad is a single flat surface and Godot's
// clockwise front-face rule made it invisible from above (grass showed through
// between the footpaths). Culling it off is cheaper than risking the winding.
render_mode diffuse_burley, cull_disabled;

uniform sampler2D road_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint : source_color = vec3(0.98, 0.99, 1.0);
uniform vec3 dirt_tint : source_color = vec3(0.52, 0.45, 0.35);

varying vec3 world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 c = texture(road_tex, UV);
	vec3 col = c.rgb * tint;

	// --- tyre tracks: four narrow polished bands, one pair either side of
	// the dashed lane line (U = 0.36) and one pair either side of the solid
	// line (U = 0.63) of the pack texture - which is exactly where traffic
	// wears the tarmac.  The double yellow in the middle stays untouched. ---
	float wear = 0.0;
	wear += 1.0 - smoothstep(0.0, 0.035, abs(UV.x - 0.310));
	wear += 1.0 - smoothstep(0.0, 0.035, abs(UV.x - 0.390));
	wear += 1.0 - smoothstep(0.0, 0.035, abs(UV.x - 0.610));
	wear += 1.0 - smoothstep(0.0, 0.035, abs(UV.x - 0.690));
	wear = clamp(wear, 0.0, 1.0);
	// Worn tarmac is a touch darker and much smoother than the rest.
	col *= 1.0 - wear * 0.09;

	// --- patchy asphalt, in world space so it never tiles with the road ---
	float m = vnoise(world_pos.xz * 0.45) * 0.6 + vnoise(world_pos.xz * 1.7) * 0.4;
	col *= 0.94 + m * 0.16;

	// --- dust and grit along both kerbs ---
	float edge = 1.0 - smoothstep(0.0, 0.09, min(UV.x, 1.0 - UV.x));
	col = mix(col, dirt_tint, edge * 0.5);

	ALBEDO = col;
	ROUGHNESS = mix(0.95, 0.78, wear);
	SPECULAR = 0.10;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	var tex := load(ROAD_TEXTURE) as Texture2D
	if tex:
		m.set_shader_parameter("road_tex", tex)
	_materials["road_surface"] = m
	return m


## A quad whose U spans the road width and V repeats along its length.
static func road_mesh(width: float, length: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := width * 0.5
	var hl := length * 0.5
	var repeat := maxf(length / 9.0, 1.0)
	var points := [Vector3(-hw, 0.0, -hl), Vector3(hw, 0.0, -hl), Vector3(hw, 0.0, hl), Vector3(-hw, 0.0, hl)]
	var uvs := [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, repeat), Vector2(0.0, repeat)]
	for i in 4:
		st.set_normal(Vector3.UP)
		st.set_uv(uvs[i])
		st.add_vertex(points[i])
	st.add_index(0)
	st.add_index(2)
	st.add_index(1)
	st.add_index(0)
	st.add_index(3)
	st.add_index(2)
	return st.commit()


## Footpaths and the paved apron around the parade ground.
## The paver pattern is baked into the texture (per-paver stone tones, grout
## joints, a weathered bevel and aggregate speckle) so the paths read as
## paving instead of flat grey without spending a single fragment shader.
static func paving_material() -> StandardMaterial3D:
	if _materials.has("paving"):
		return _materials["paving"]
	var m := StandardMaterial3D.new()
	m.albedo_texture = paving_texture()
	m.roughness = 0.88
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.5, 0.5, 0.5)
	_materials["paving"] = m
	return m


static func court_material() -> StandardMaterial3D:
	if _materials.has("court"):
		return _materials["court"]
	var m := StandardMaterial3D.new()
	m.albedo_texture = tiling_texture(128, Color.html("#b96a45"), 0.09, 31, "court")
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.35, 0.35, 0.35)
	_materials["court"] = m
	return m


## The whole 28 x 15 m court painted into one 512 x 290 texture: wood planks,
## keys, free-throw circles, three-point arcs and the centre logo.  Replacing
## the old handful of thin boxes with this one texture removes the z-fighting
## and gives the court real painted markings.
static func court_texture() -> Texture2D:
	if _textures.has("court_texture"):
		return _textures["court_texture"]
	var img := Image.create(COURT_TEX_W, COURT_TEX_H, false, Image.FORMAT_RGB8)
	img.fill(Color.html("#b96f43"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210
	# Plank rows with subtle tonal variation and dark seams.
	for row in 34:
		var y0 := int(float(row) / 34.0 * float(COURT_TEX_H))
		var y1 := int(float(row + 1) / 34.0 * float(COURT_TEX_H))
		var tone := Color.html("#b96f43").lerp(Color.html("#c98252"), rng.randf())
		img.fill_rect(Rect2i(0, y0, COURT_TEX_W, maxi(1, y1 - y0)), tone)
		_img_hline(img, y0, 0, COURT_TEX_W, Color.html("#9a5734"), 1)
	# Grain: short low-contrast strokes, deterministic so the court never
	# changes between launches.
	for i in 360:
		var gx := rng.randf_range(0.0, float(COURT_TEX_W))
		var gy := rng.randf_range(0.0, float(COURT_TEX_H))
		var length := rng.randf_range(6.0, 26.0)
		var tone := Color.html("#a86139") if rng.randf() < 0.5 else Color.html("#d08a55")
		_img_line(img, Vector2(gx, gy), Vector2(gx + length, gy + rng.randf_range(-2.0, 2.0)), tone, 1)

	var line := Color.html("#f4e6cc")
	var key_blue := Color.html("#1d4a66")
	# Painted keys at both ends.
	_img_rect(img, -14.0, -2.45, -8.2, 2.45, key_blue)
	_img_rect(img, 8.2, -2.45, 14.0, 2.45, key_blue)
	# Boundary, centre line and centre circle.
	_img_rect_outline(img, -14.0, -7.5, 14.0, 7.5, line, 2)
	_img_line(img, _court_px(0.0, -7.5), _court_px(0.0, 7.5), line, 2)
	_img_ring(img, 0.0, 0.0, 1.8, line, 2)
	# Free-throw circles sit on the top of each key.
	_img_ring(img, -8.2, 0.0, 1.8, line, 2)
	_img_ring(img, 8.2, 0.0, 1.8, line, 2)
	_img_rect_outline(img, -14.0, -2.45, -8.2, 2.45, line, 2)
	_img_rect_outline(img, 8.2, -2.45, 14.0, 2.45, line, 2)
	# Three-point arcs (radius 6.75 m around each hoop) with the short
	# straight corner segments.
	for side in [-1.0, 1.0]:
		var s := float(side)
		var cx := s * 12.425
		var half := 1.393
		var a0 := -half if s < 0.0 else PI - half
		var a1 := half if s < 0.0 else PI + half
		_img_ring(img, cx, 0.0, 6.75, line, 2, a0, a1)
		var sx0 := -14.0 if s < 0.0 else 11.0
		var sx1 := -11.0 if s < 0.0 else 14.0
		_img_line(img, _court_px(sx0, -6.6), _court_px(sx1, -6.6), line, 2)
		_img_line(img, _court_px(sx0, 6.6), _court_px(sx1, 6.6), line, 2)
	# Centre-court logo: a simple navy disc with a red ring and a gold pip.
	_img_disc(img, _court_px(0.0, 0.0), 18, Color.html("#1d4a66"))
	_img_ring(img, 0.0, 0.0, 1.15, Color.html("#c23b3b"), 3)
	_img_disc(img, _court_px(0.0, 0.0), 5, Color.html("#f2c14e"))
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_textures["court_texture"] = tex
	return tex


static func court_texture_material() -> StandardMaterial3D:
	if _materials.has("court_texture_mat"):
		return _materials["court_texture_mat"]
	var m := StandardMaterial3D.new()
	m.albedo_texture = court_texture()
	m.roughness = 0.86
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_materials["court_texture_mat"] = m
	return m


static func _court_px(x: float, z: float) -> Vector2:
	return Vector2(
		(x - COURT_TEX_X0) / COURT_TEX_W_M * float(COURT_TEX_W),
		(z - COURT_TEX_Z0) / COURT_TEX_H_M * float(COURT_TEX_H))


static func _img_rect(img: Image, x0: float, z0: float, x1: float, z1: float, color: Color) -> void:
	var a := _court_px(minf(x0, x1), minf(z0, z1))
	var b := _court_px(maxf(x0, x1), maxf(z0, z1))
	img.fill_rect(Rect2i(int(a.x), int(a.y), maxi(1, int(b.x - a.x)), maxi(1, int(b.y - a.y))), color)


static func _img_rect_outline(img: Image, x0: float, z0: float, x1: float, z1: float,
		color: Color, width: int) -> void:
	_img_line(img, _court_px(x0, z0), _court_px(x1, z0), color, width)
	_img_line(img, _court_px(x0, z1), _court_px(x1, z1), color, width)
	_img_line(img, _court_px(x0, z0), _court_px(x0, z1), color, width)
	_img_line(img, _court_px(x1, z0), _court_px(x1, z1), color, width)


static func _img_hline(img: Image, y: int, x0: int, x1: int, color: Color, width: int) -> void:
	if y < 0 or y >= img.get_height():
		return
	var a := maxi(0, x0)
	var b := mini(img.get_width() - 1, x1)
	for x in range(a, b + 1):
		for dy in range(-width + 1, width):
			var py := y + dy
			if py >= 0 and py < img.get_height():
				img.set_pixel(x, py, color)


static func _img_line(img: Image, a: Vector2, b: Vector2, color: Color, width: int) -> void:
	var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
	if steps <= 0:
		_img_dot(img, a, width, color)
		return
	for i in steps + 1:
		_img_dot(img, a.lerp(b, float(i) / float(steps)), width, color)


static func _img_dot(img: Image, p: Vector2, width: int, color: Color) -> void:
	var r := maxi(0, width - 1)
	var cx := int(p.x)
	var cy := int(p.y)
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy > r * r:
				continue
			var px := cx + dx
			var py := cy + dy
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, color)


static func _img_disc(img: Image, p: Vector2, radius: int, color: Color) -> void:
	var cx := int(p.x)
	var cy := int(p.y)
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx * dx + dy * dy > radius * radius:
				continue
			var px := cx + dx
			var py := cy + dy
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, color)


static func _img_ring(img: Image, cx: float, cz: float, radius: float, color: Color,
		width: int, a0: float = 0.0, a1: float = TAU) -> void:
	var steps := 128
	for i in steps + 1:
		var a := lerpf(a0, a1, float(i) / float(steps))
		_img_dot(img, _court_px(cx + cos(a) * radius, cz + sin(a) * radius), width, color)


## The NCC parade ground.
## Returns a ShaderMaterial now (it used to be a StandardMaterial3D): the
## broad tonal drift and the darker damp patches have to live in world space,
## otherwise the tiled sand texture repeats every 3 m and the big parade
## ground reads as wallpaper.
static func sand_material() -> Material:
	if _materials.has("sand"):
		return _materials["sand"]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform sampler2D sand_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float texture_scale = 0.30;
uniform vec3 sand_tint : source_color = vec3(1.0, 0.98, 0.92);
uniform vec3 damp_tint : source_color = vec3(0.63, 0.56, 0.41);

varying vec3 world_pos;
varying vec3 world_normal;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// --- triplanar sand grain, same scale as the old StandardMaterial3D ---
	vec3 n = abs(world_normal);
	n = pow(n, vec3(6.0));
	n /= max(n.x + n.y + n.z, 0.0001);
	vec3 cx = texture(sand_tex, world_pos.zy * texture_scale).rgb;
	vec3 cy = texture(sand_tex, world_pos.xz * texture_scale).rgb;
	vec3 cz = texture(sand_tex, world_pos.xy * texture_scale).rgb;
	vec3 base = (cx * n.x + cy * n.y + cz * n.z) * sand_tint;

	// --- broad tonal drift, so the big parade ground never looks tiled ---
	float broad = vnoise(world_pos.xz * 0.045);
	base *= 0.90 + broad * 0.22;

	// --- a few damp, darker patches ---
	float patch = vnoise(world_pos.xz * 0.16);
	float damp = smoothstep(0.62, 0.88, patch);
	base = mix(base, base * damp_tint, damp * 0.45);

	ALBEDO = base;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	var tex := tiling_texture(128, Color.html("#cdb784"), 0.10, 37, "sand")
	if tex:
		m.set_shader_parameter("sand_tex", tex)
	_materials["sand"] = m
	return m


## A seamless, multi-octave surface texture.
##
## The old version used three sines, which produced a very regular, flat
## looking pattern.  This one layers three octaves of seamless value noise
## (so the texture tiles without a visible seam) and then adds the surface
## specific detail: pale aggregate in the asphalt, damp clumps and grain in
## the sand, worn patches on the court.  Generated once and cached.
static func tiling_texture(size: int, base: Color, variation: float, seed_value: int,
		kind: String) -> ImageTexture:
	if _textures.has(kind):
		return _textures[kind]
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	var rng := LCG.new(seed_value)
	for y in size:
		for x in size:
			var fx := float(x) / float(size)
			var fy := float(y) / float(size)
			# three octaves of seamless value noise
			var n := _value_noise(fx * 3.0, fy * 3.0, seed_value + 11, 3) * 0.55
			n += _value_noise(fx * 9.0, fy * 9.0, seed_value + 29, 9) * 0.30
			n += _value_noise(fx * 27.0, fy * 27.0, seed_value + 47, 27) * 0.15
			var f := 1.0 + (n - 0.5) * variation * 2.0
			var c := Color(base.r * f, base.g * f, base.b * f)
			match kind:
				"asphalt":
					# a few pale stones and a few fresh tar patches
					if rng.randf() < 0.010:
						c = c.lightened(0.07)
					elif rng.randf() < 0.006:
						c = c.darkened(0.08)
				"sand":
					# coarse grains and small damp specks
					if rng.randf() < 0.05:
						c = c.darkened(0.05)
					elif rng.randf() < 0.04:
						c = c.lightened(0.05)
				"court":
					if rng.randf() < 0.02:
						c = c.darkened(0.04)
				"grass":
					if rng.randf() < 0.06:
						c = c.darkened(0.05)
			# a couple of larger, soft blotches so the surface is not uniform
			if kind == "sand" or kind == "court":
				var blotch := _value_noise(fx * 2.0, fy * 2.0, seed_value + 71, 2)
				if blotch > 0.66:
					c = c.darkened(0.09 * (blotch - 0.66) / 0.34)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_textures[kind] = tex
	return tex


## A tiled paver pattern: every stone gets its own tone, the joints are
## filled with grout and each paver is slightly bevelled and speckled, so a
## footpath reads as paving rather than as flat grey.
static func paving_texture() -> ImageTexture:
	if _textures.has("paving"):
		return _textures["paving"]
	var size := 64
	var tile := 16
	var base := Color.html("#bcb7ac")
	var grout := Color.html("#8e8a7f")
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var c := base
			var tx := (x / tile) % 4
			var ty := (y / tile) % 4
			# every paver is cut from its own stone: a slightly different
			# tone and a slightly different warmth
			var tone := _hash2(tx, ty, 7, 4)
			var warm := _hash2(tx, ty, 19, 4)
			c = Color(base.r * (0.93 + tone * 0.13),
					base.g * (0.93 + tone * 0.12),
					base.b * (0.92 + tone * 0.11) * (0.97 + warm * 0.06))
			# faint chequer, so the pattern still reads from far away
			if (tx + ty) % 2 == 1:
				c = c.darkened(0.025)
			# aggregate speckle
			var g := _hash2(x, y, 41, size)
			c = Color(c.r * (0.96 + g * 0.08), c.g * (0.96 + g * 0.08), c.b * (0.96 + g * 0.08))
			# grout joints, then a weathered bevel around every paver
			if x % tile < 2 or y % tile < 2:
				c = grout
			elif x % tile < 3 or y % tile < 3 or x % tile > tile - 3 or y % tile > tile - 3:
				c = c.darkened(0.055)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_textures["paving"] = tex
	return tex


## Deterministic 2D hash -> 0..1.  `period` makes it wrap, which is what
## keeps the generated textures seamless.  Plain arithmetic only, so it is
## identical on every platform.
static func _hash2(x: int, y: int, seed_value: int, period: int) -> float:
	var xi := posmod(x, period)
	var yi := posmod(y, period)
	var n := (xi * 73856093 + yi * 19349663 + seed_value * 83492791) % 2147483647
	n = (n * 1274126177 + 1013904223) % 2147483647
	return float(n) * (1.0 / 2147483647.0)


## Smooth value noise on a wrapping lattice.
static func _value_noise(x: float, y: float, seed_value: int, period: int) -> float:
	var xi := int(floor(x))
	var yi := int(floor(y))
	var xf := x - float(xi)
	var yf := y - float(yi)
	var u := xf * xf * (3.0 - 2.0 * xf)
	var v := yf * yf * (3.0 - 2.0 * yf)
	var a := _hash2(xi, yi, seed_value, period)
	var b := _hash2(xi + 1, yi, seed_value, period)
	var c := _hash2(xi, yi + 1, seed_value, period)
	var d := _hash2(xi + 1, yi + 1, seed_value, period)
	return lerpf(lerpf(a, b, u), lerpf(c, d, u), v)
