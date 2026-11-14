class_name CampusBuilder
extends Node3D
## Builds the entire ANITS campus from src/data/campus_data.json.
##
## Everything (ground, roads, walls, gates, building masses, props, zones) is
## generated, so the campus plan is a DATA change, never a code change.
##
## Performance (mobile + PC):
##   - every repeated prop is a MultiMeshInstance3D (1 draw call per type)
##   - grass is chunked and hidden past its radius
##   - small props cast no shadows
##   - one shared static body holds all the small prop colliders

const KEY_BUILDINGS := "buildings"
const KEY_ROADS := "roads"
const KEY_ZONES := "zones"
const KEY_WALLS := "walls"
const KEY_GATES := "gates"
const KEY_PROPS := "props"
const KEY_LAMPS := "lamps"
const KEY_BENCHES := "benches"
const KEY_VENDING := "vending_machines"
const KEY_SERVICES := "services"
const KEY_SPECIALS := "specials"

var campus: Dictionary = {}
var gate_leaves: Array = []          ## hinged leaves of the main gate
var _gate_shape: CollisionShape3D    ## invisible barrier while the gate is locked
var building_meshes: Dictionary = {} ## name -> MeshInstance3D
var label_nodes: Array = []
var _prop_body: StaticBody3D = null
var _grass_chunks: Array = []       ## [{node, center}] hidden by distance


func build(data: Dictionary) -> void:
	campus = data
	_clear()
	_build_ground()
	_build_roads()
	_build_zones()
	_build_walls()
	_build_gates()
	_build_buildings()
	_build_specials()
	_build_props()
	_build_lamps()
	_build_benches()
	_build_vending_machines()


func _clear() -> void:
	for child in get_children():
		child.queue_free()


# ------------------------------------------------------------------ helpers

static func mat(color: Color, rough := 1.0, emis := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = 0.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if emis > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emis
	return m


static func box(parent: Node, size: Vector3, pos: Vector3, material: Material, name_hint := "") -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	if name_hint != "":
		mi.name = name_hint
	parent.add_child(mi)
	return mi


static func _rect_world(r: Array) -> Rect2:
	return Campus.map_rect_to_world(Rect2(r[0], r[1], r[2] - r[0], r[3] - r[1]))


## A static box collider (the campus is made of axis-aligned boxes, exactly like
## the original's `colliders` list).
static func add_collider(parent: Node, size: Vector3, pos: Vector3, name_hint := "Collider") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name_hint
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(maxf(size.x, 0.05), maxf(size.y, 0.05), maxf(size.z, 0.05))
	shape.shape = box
	shape.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(shape)
	body.position = Vector3(pos.x, pos.y, pos.z)
	parent.add_child(body)
	return body


## One shared static body holds every small prop collider (trees, cars...) so the
## campus stays at a few dozen physics bodies instead of hundreds.
func _prop_collider(size: Vector3, pos: Vector3) -> void:
	if _prop_body == null:
		_prop_body = StaticBody3D.new()
		_prop_body.name = "PropColliders"
		add_child(_prop_body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(maxf(size.x, 0.05), maxf(size.y, 0.05), maxf(size.z, 0.05))
	shape.shape = box
	shape.position = Vector3(pos.x, pos.y + size.y * 0.5, pos.z)
	_prop_body.add_child(shape)


# ------------------------------------------------------------------ ground

func _build_ground() -> void:
	var extent := _rect_world(campus.get("extent_plan_px", [0, 0, 100, 100]))
	var size := extent.size
	var centre := extent.position + size * 0.5
	# the ground extends far past the campus so the horizon is never empty
	var ground := box(self, Vector3(size.x + 1400.0, 0.4, size.y + 1400.0), Vector3(centre.x, -0.2, centre.y),
		PropsFactory.ground_material(), "Ground")
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# a lighter, mown campus lawn sits just above it
	var lawn := box(self, Vector3(size.x, 0.06, size.y), Vector3(centre.x, 0.01, centre.y),
		PropsFactory.ground_material(), "CampusLawn")
	lawn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# the ground must be solid, otherwise the player falls through the world
	add_collider(self, Vector3(size.x + 1400.0, 0.4, size.y + 1400.0),
		Vector3(centre.x, -0.4, centre.y), "GroundCol")


func _build_roads() -> void:
	## Narrow streets use the Road Generator pack's real two-lane asphalt
	## texture; the wide parking apron / entrance boulevard stay plain asphalt.
	for r in campus.get(KEY_ROADS, []):
		var wr := _rect_world(r)
		var w := wr.size.x
		var d := wr.size.y
		var short_m := minf(w, d)
		var long_m := maxf(w, d)
		var centre := Vector3(wr.position.x + w * 0.5, 0.0, wr.position.y + d * 0.5)
		if short_m >= 16.0 or long_m < 0.5:
			var road := box(self, Vector3(w, 0.08, d), Vector3(centre.x, 0.04, centre.z),
				PropsFactory.asphalt_material(), "Road")
			road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			continue
		var vertical := d >= w
		var mi := MeshInstance3D.new()
		mi.name = "Road"
		mi.mesh = PropsFactory.road_mesh(w if vertical else d, d if vertical else w)
		mi.rotation.y = 0.0 if vertical else PI * 0.5
		mi.position = Vector3(centre.x, 0.055, centre.z)
		mi.material_override = PropsFactory.road_material()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	_build_sidewalks()
	_build_kerbs()
	_build_road_markings()
	_build_crosswalk()


## Paved footpaths outside both long edges of every street (the wide parking
## apron is left as plain asphalt).
func _build_sidewalks() -> void:
	var m := PropsFactory.paving_material()
	for r in campus.get(KEY_ROADS, []):
		var rect := Rect2(r[0], r[1], r[2] - r[0], r[3] - r[1])
		var short_m := minf(rect.size.x, rect.size.y) * Campus.MAP_SCALE
		var long_m := maxf(rect.size.x, rect.size.y) * Campus.MAP_SCALE
		if short_m > 20.0 or long_m < 14.0:
			continue
		var wr := _rect_world(r)
		if rect.size.y >= rect.size.x:
			for side in [-1.0, 1.0]:
				var s := float(side)
				var x: float = wr.position.x - 2.2 if s < 0.0 else wr.end.x
				var path := box(self, Vector3(2.2, 0.14, wr.size.y + 2.2),
					Vector3(x + 1.1, 0.07, wr.position.y + wr.size.y * 0.5), m, "Footpath")
				path.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			for side in [-1.0, 1.0]:
				var s := float(side)
				var z: float = wr.position.y - 2.2 if s < 0.0 else wr.end.y
				var path := box(self, Vector3(wr.size.x + 2.2, 0.14, 2.2),
					Vector3(wr.position.x + wr.size.x * 0.5, 0.07, z + 1.1), m, "Footpath")
				path.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_kerbs() -> void:
	## Alternating yellow / white kerb blocks along both long edges of every road,
	## exactly like the original (1.5 m long, 0.5 m wide, 0.14 m high). They are
	## two MultiMeshes now instead of ~1000 individual nodes. Blocks that would
	## land inside a building or inside another road are skipped, like the web.
	var yellow: Array = []
	var white: Array = []
	var step := 1.5 / Campus.MAP_SCALE
	var roads: Array = campus.get(KEY_ROADS, [])
	for ri in roads.size():
		var r: Array = roads[ri]
		var rect := Rect2(r[0], r[1], r[2] - r[0], r[3] - r[1])
		if minf(rect.size.x, rect.size.y) * Campus.MAP_SCALE > 20.0:
			continue
		var vertical := rect.size.y >= rect.size.x
		var a0 := rect.position.y if vertical else rect.position.x
		var a1 := rect.end.y if vertical else rect.end.x
		var i := 0
		var a := a0 + step * 0.5
		while a < a1:
			for edge in [rect.position.x, rect.end.x] if vertical else [rect.position.y, rect.end.y]:
				var px: float = float(edge) if vertical else a
				var py: float = a if vertical else float(edge)
				if _kerb_blocked(px, py, ri):
					continue
				var w := Campus.map_to_world(Vector2(px, py))
				var basis := Basis() if vertical else Basis(Vector3.UP, PI * 0.5)
				var xform := Transform3D(basis, Vector3(w.x, 0.07, w.z))
				if i % 2 == 0:
					yellow.append(xform)
				else:
					white.append(xform)
			a += step
			i += 1
	_kerb_batch("KerbsYellow", yellow, mat(Color.html("#f2c94c")))
	_kerb_batch("KerbsWhite", white, mat(Color.html("#f4f4ee")))


## True when a kerb block would sit inside a building or another road.
func _kerb_blocked(px: float, py: float, road_index: int) -> bool:
	for b in campus.get(KEY_BUILDINGS, []):
		var r: Array = b.get("rect", [])
		if px > r[0] and px < r[2] and py > r[1] and py < r[3]:
			return true
	var roads: Array = campus.get(KEY_ROADS, [])
	for i in roads.size():
		if i == road_index:
			continue
		var r: Array = roads[i]
		if px > r[0] - 0.6 and px < r[2] + 0.6 and py > r[1] - 0.6 and py < r[3] + 0.6:
			return true
	return false


func _kerb_batch(batch_name: String, transforms: Array, material: Material) -> void:
	if transforms.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.5, 0.14, 1.5)
	_add_multimesh(batch_name, mesh, transforms, material, [], false)


func _build_road_markings() -> void:
	## Dashed centre line on the wide entrance boulevard (the narrow roads
	## already carry lane markings in their texture).
	var dashes: Array = []
	var gap := 6.0
	var dash := 2.4
	var parking: Array = (campus.get(KEY_ZONES, {}) as Dictionary).get("parking", [])
	for r in campus.get(KEY_ROADS, []):
		var rect := Rect2(r[0], r[1], r[2] - r[0], r[3] - r[1])
		if minf(rect.size.x, rect.size.y) * Campus.MAP_SCALE < 18.0:
			continue
		if parking.size() == 4:
			var park := Rect2(parking[0], parking[1], parking[2] - parking[0], parking[3] - parking[1])
			if rect.intersects(park):
				continue
		var vertical := rect.size.y >= rect.size.x
		var length := rect.size.y if vertical else rect.size.x
		if length * Campus.MAP_SCALE < 30.0:
			continue
		var a := gap * 0.5
		while a + dash < length:
			var p := Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + a + dash * 0.5) if vertical \
				else Vector2(rect.position.x + a + dash * 0.5, rect.position.y + rect.size.y * 0.5)
			var w := Campus.map_to_world(p)
			var basis := Basis() if vertical else Basis(Vector3.UP, PI * 0.5)
			dashes.append(Transform3D(basis, Vector3(w.x, 0.095, w.z)))
			a += gap + dash
	if dashes.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.16, 0.02, dash)
	_add_multimesh("RoadDashes", mesh, dashes, mat(Color.html("#e8e4d2")), [], false)


## The zebra crossing just inside the main gate.
func _build_crosswalk() -> void:
	var stripes: Array = []
	for i in 7:
		var px := 102.0 + 2.0 + float(i) * 5.6
		var w := Campus.map_to_world(Vector2(px, 423.0))
		stripes.append(Transform3D(Basis(), Vector3(w.x, 0.095, w.z)))
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.0, 0.02, 3.2)
	_add_multimesh("Crosswalk", mesh, stripes, mat(Color.html("#f0eee2")), [], false)


func _build_zones() -> void:
	var zones: Dictionary = campus.get(KEY_ZONES, {})
	if zones.has("basketball"):
		_build_court(_rect_world(zones["basketball"]))
	if zones.has("track"):
		var r := _rect_world(zones["track"])
		box(self, Vector3(r.size.x, 0.1, r.size.y), Vector3(r.position.x + r.size.x * 0.5, 0.05, r.position.y + r.size.y * 0.5),
			mat(Color.html("#2f6b3a")), "TrackGround")
		_build_track_oval(r)
	if zones.has("parade_ground"):
		var r := _rect_world(zones["parade_ground"])
		box(self, Vector3(r.size.x, 0.1, r.size.y), Vector3(r.position.x + r.size.x * 0.5, 0.05, r.position.y + r.size.y * 0.5),
			PropsFactory.sand_material(), "ParadeGround")
		# Raised paved footpath framing the NCC ground, like the web build.
		var path_w := 1.3
		var pave := PropsFactory.paving_material()
		var c := r.position + r.size * 0.5
		box(self, Vector3(r.size.x, 0.08, path_w), Vector3(c.x, 0.105, r.position.y + path_w * 0.5), pave, "ParadeFootpath")
		box(self, Vector3(r.size.x, 0.08, path_w), Vector3(c.x, 0.105, r.end.y - path_w * 0.5), pave, "ParadeFootpath")
		box(self, Vector3(path_w, 0.08, r.size.y), Vector3(r.position.x + path_w * 0.5, 0.105, c.y), pave, "ParadeFootpath")
		box(self, Vector3(path_w, 0.08, r.size.y), Vector3(r.end.x - path_w * 0.5, 0.105, c.y), pave, "ParadeFootpath")
	if zones.has("central_lawn"):
		var r := _rect_world(zones["central_lawn"])
		box(self, Vector3(r.size.x, 0.1, r.size.y), Vector3(r.position.x + r.size.x * 0.5, 0.05, r.position.y + r.size.y * 0.5),
			PropsFactory.ground_material(), "CentralLawn")
	if zones.has("parking"):
		var r := _rect_world(zones["parking"])
		box(self, Vector3(r.size.x, 0.09, r.size.y), Vector3(r.position.x + r.size.x * 0.5, 0.045, r.position.y + r.size.y * 0.5),
			PropsFactory.asphalt_material(), "Parking")
	if zones.has("power_supply"):
		_build_power_supply(_rect_world(zones["power_supply"]))


## The 11 kV substation on the east side of the campus: a raised concrete
## plinth with three transformers, ceramic bushings, a red danger band and a
## fenced yard (the web build's "Power Supply Room").
func _build_power_supply(r: Rect2) -> void:
	# green compound ground
	box(self, Vector3(r.size.x, 0.1, r.size.y), Vector3(r.position.x + r.size.x * 0.5, 0.05, r.position.y + r.size.y * 0.5),
		mat(Color.html("#2d6e33")), "PowerSupplyGround")
	var centre := Vector3(r.position.x + r.size.x * 0.5, 0.0, r.position.y + r.size.y * 0.5)
	# concrete plinth
	box(self, Vector3(r.size.x * 0.55, 0.5, r.size.y * 0.42), Vector3(centre.x, 0.3, centre.z),
		mat(Color.html("#9a978d")), "SubstationPlinth")
	# three transformers
	for i in 3:
		var x := centre.x - r.size.x * 0.18 + float(i) * r.size.x * 0.18
		var body := box(self, Vector3(4.2, 3.4, 3.2), Vector3(x, 2.2, centre.z),
			mat(Color.html("#7c8b93")), "Transformer")
		body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		# cooling fins
		for f in 4:
			box(self, Vector3(0.25, 2.6, 3.6), Vector3(x - 1.5 + float(f) * 1.0, 2.2, centre.z),
				mat(Color.html("#5f6d75")), "TransformerFin")
		# ceramic bushings
		for b in 3:
			var bx := x - 1.2 + float(b) * 1.2
			var bush := CylinderMesh.new()
			bush.top_radius = 0.16
			bush.bottom_radius = 0.24
			bush.height = 1.1
			bush.radial_segments = 8
			var bmi := MeshInstance3D.new()
			bmi.mesh = bush
			bmi.material_override = mat(Color.html("#d8cfc0"))
			bmi.position = Vector3(bx, 4.4, centre.z)
			add_child(bmi)
	# red danger band along the plinth
	box(self, Vector3(r.size.x * 0.55, 0.16, 0.18), Vector3(centre.x, 0.56, centre.z - r.size.y * 0.21),
		mat(Color.html("#c62828")), "DangerBand")
	# fence posts + rails
	var fence := mat(Color.html("#6f7a72"))
	var posts: Array = []
	var step := 4.0
	var fx := r.position.x + 2.0
	while fx < r.end.x - 1.0:
		posts.append(Vector3(fx, 1.1, r.position.y + 1.0))
		posts.append(Vector3(fx, 1.1, r.end.y - 1.0))
		fx += step
	var fy := r.position.y + 1.0
	while fy < r.end.y - 1.0:
		posts.append(Vector3(r.position.x + 1.0, 1.1, fy))
		posts.append(Vector3(r.end.x - 1.0, 1.1, fy))
		fy += step
	_add_multimesh("SubstationFencePosts", _post_mesh(), posts, fence, [], false)
	for y in [0.7, 1.5]:
		box(self, Vector3(r.size.x - 2.0, 0.1, 0.1), Vector3(centre.x, y, r.position.y + 1.0), fence, "FenceRail")
		box(self, Vector3(r.size.x - 2.0, 0.1, 0.1), Vector3(centre.x, y, r.end.y - 1.0), fence, "FenceRail")
		box(self, Vector3(0.1, 0.1, r.size.y - 2.0), Vector3(r.position.x + 1.0, y, centre.z), fence, "FenceRail")
		box(self, Vector3(0.1, 0.1, r.size.y - 2.0), Vector3(r.end.x - 1.0, y, centre.z), fence, "FenceRail")
	# warning sign
	var sign := Label3D.new()
	sign.text = "11 kV HIGH VOLTAGE"
	sign.font_size = 30
	sign.pixel_size = 0.006
	sign.modulate = Color.html("#ffd24a")
	sign.outline_size = 6
	sign.outline_modulate = Color(0.08, 0.06, 0.02)
	sign.position = Vector3(centre.x, 4.2, r.position.y + 1.4)
	add_child(sign)


func _post_mesh() -> Mesh:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.22, 2.2, 0.22)
	return mesh


func _build_track_oval(r: Rect2) -> void:
	## Orange oval running track drawn as flat boxes around the perimeter.
	var centre := r.position + r.size * 0.5
	var rx := r.size.x * 0.42
	var rz := r.size.y * 0.40
	var m := mat(Color.html("#c05a36"))
	var seg := 24
	for i in seg:
		var a := TAU * float(i) / float(seg)
		var p := Vector3(centre.x + cos(a) * rx, 0.11, centre.y + sin(a) * rz)
		var next_a := TAU * float(i + 1) / float(seg)
		var q := Vector3(centre.x + cos(next_a) * rx, 0.11, centre.y + sin(next_a) * rz)
		var mid := (p + q) * 0.5
		var length := p.distance_to(q)
		var mi := box(self, Vector3(length + 1.2, 0.06, 3.0), mid, m, "Track")
		mi.rotation.y = atan2(q.z - p.z, q.x - p.x)


func _build_court(r: Rect2) -> void:
	## 28 x 15 m court painted inside the ground zone.
	var ground := PropsFactory.court_material()
	box(self, Vector3(r.size.x, 0.1, r.size.y), Vector3(r.position.x + r.size.x * 0.5, 0.05, r.position.y + r.size.y * 0.5), ground, "CourtGround")
	var lines := mat(Color.html("#f3e2c8"))
	var centre := r.position + r.size * 0.5
	var court_w := 28.0
	var court_d := 15.0
	var paint := 0.12
	box(self, Vector3(court_w, 0.02, paint), Vector3(centre.x, 0.12, centre.y - court_d * 0.5), lines, "CourtLine")
	box(self, Vector3(court_w, 0.02, paint), Vector3(centre.x, 0.12, centre.y + court_d * 0.5), lines, "CourtLine")
	box(self, Vector3(paint, 0.02, court_d), Vector3(centre.x - court_w * 0.5, 0.12, centre.y), lines, "CourtLine")
	box(self, Vector3(paint, 0.02, court_d), Vector3(centre.x + court_w * 0.5, 0.12, centre.y), lines, "CourtLine")
	box(self, Vector3(paint, 0.02, court_d), Vector3(centre.x, 0.12, centre.y), lines, "CourtCentreLine")
	for side in [-1.0, 1.0]:
		var s := float(side)
		var hx := centre.x + s * (court_w * 0.5 + 1.2)
		box(self, Vector3(0.25, 3.05, 0.25), Vector3(hx, 1.6, centre.y), mat(Color.html("#33363c")), "HoopPost")
		box(self, Vector3(0.12, 1.1, 1.84), Vector3(hx - s * 0.1, 3.2, centre.y), mat(Color.html("#f0f0f0")), "HoopBoard")
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.20
		torus.outer_radius = 0.24
		ring.mesh = torus
		ring.material_override = mat(Color.html("#e05030"))
		ring.position = Vector3(hx, 3.05, centre.y)
		ring.rotation_degrees = Vector3(90, 0, 0)
		add_child(ring)


# ------------------------------------------------------------------ walls

func _build_walls() -> void:
	var m := mat(Color.html("#b3a795"))
	var top := mat(Color.html("#c9beac"))
	var h := float(campus.get("wall_height", 2.4))
	for w in campus.get(KEY_WALLS, []):
		var r := _rect_world(w)
		var size := r.size
		var horizontal := size.x >= size.y
		var thick := maxf(size.y if horizontal else size.x, 0.4)
		var length := maxf(size.x, size.y)
		var cx := r.position.x + size.x * 0.5
		var cz := r.position.y + size.y * 0.5
		var mi := box(self, Vector3(maxf(size.x, 0.5), h, maxf(size.y, 0.5)),
			Vector3(cx, h * 0.5, cz), m, "Wall")
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var cap := box(self, Vector3(maxf(size.x, 0.5) + 0.18, 0.16, maxf(size.y, 0.5) + 0.18),
			Vector3(cx, h + 0.08, cz), top, "WallCap")
		cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# stone pillars every 12 m make the boundary read as a campus wall
		var n := maxi(1, int(length / 12.0))
		for i in n + 1:
			var along := length * float(i) / float(n)
			var px := r.position.x + (along if horizontal else size.x * 0.5)
			var pz := r.position.y + (size.y * 0.5 if horizontal else along)
			var pillar := box(self, Vector3(thick + 0.25, h + 0.55, thick + 0.25),
				Vector3(px, (h + 0.55) * 0.5, pz), top, "WallPillar")
			pillar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_collider(self, Vector3(maxf(size.x, 0.5), h, maxf(size.y, 0.5)),
			Vector3(cx, 0.0, cz), "WallCol")
	# The stone pillars are one MultiMesh instead of ~100 separate meshes.
	var pillars: Array = []
	var pillar_mesh := BoxMesh.new()
	for w in campus.get(KEY_WALLS, []):
		var r := _rect_world(w)
		var size := r.size
		var horizontal := size.x >= size.y
		var thick := maxf(size.y if horizontal else size.x, 0.4)
		var length := maxf(size.x, size.y)
		var n := maxi(1, int(length / 12.0))
		for i in n + 1:
			var along := length * float(i) / float(n)
			var px := r.position.x + (along if horizontal else size.x * 0.5)
			var pz := r.position.y + (size.y * 0.5 if horizontal else along)
			pillars.append(Transform3D(Basis(), Vector3(px, (h + 0.55) * 0.5, pz)))
	pillar_mesh.size = Vector3(0.9, h + 0.55, 0.9)
	_add_multimesh("WallPillars", pillar_mesh, pillars, top, [], false)


# ------------------------------------------------------------------ gates

func _build_gates() -> void:
	for g in campus.get(KEY_GATES, []):
		if g.get("type", "") == "hinged":
			_build_main_gate(g)
		else:
			_build_back_gate(g)


func _build_main_gate(g: Dictionary) -> void:
	var r := _rect_world(g.get("rect", [0, 0, 1, 1]))
	var centre := Vector3(r.position.x + r.size.x * 0.5, 0.0, r.position.y + r.size.y * 0.5)
	var pillar_h := float(g.get("pillar_height", 8.2))
	var stone := mat(Color.html("#d8d2c4"))
	var stone_top := mat(Color.html("#efe9da"))
	var metal := mat(Color.html("#2a3038"))
	var gold := mat(Color.html("#e2b33c"), 0.6, 0.25)
	for side in [-1.0, 1.0]:
		var s := float(side)
		var px: float = centre.x + s * (r.size.x * 0.5 - 0.8)
		box(self, Vector3(1.6, pillar_h, 1.6), Vector3(px, pillar_h * 0.5, centre.z), stone, "GatePillar")
		box(self, Vector3(2.1, 0.4, 2.1), Vector3(px, pillar_h + 0.1, centre.z), stone_top, "GatePillarCap")
		box(self, Vector3(1.9, 0.22, 1.9), Vector3(px, 0.35, centre.z), stone_top, "GatePillarBase")
		add_collider(self, Vector3(1.6, pillar_h, 1.6), Vector3(px, 0.0, centre.z), "GatePillarCol")
		var leaf := Node3D.new()
		leaf.name = "GateLeaf"
		leaf.position = Vector3(px - s * 0.8, 0.0, centre.z)
		add_child(leaf)
		var leaf_w := r.size.x * 0.5 - 0.4
		var rails := box(leaf, Vector3(leaf_w, 0.16, 0.16), Vector3(-s * leaf_w * 0.5, 2.65, 0.0), metal, "LeafTop")
		rails.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		box(leaf, Vector3(leaf_w, 0.16, 0.16), Vector3(-s * leaf_w * 0.5, 0.45, 0.0), metal, "LeafBottom")
		var bars := 15
		for i in bars:
			var bx := (float(i) + 0.5) / float(bars) * leaf_w * -s
			var bar := box(leaf, Vector3(0.09, 2.3, 0.09), Vector3(bx, 1.55, 0.0), metal, "LeafBar")
			bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		gate_leaves.append({"node": leaf, "side": s})
	box(self, Vector3(r.size.x, 0.62, 0.8), Vector3(centre.x, pillar_h - 0.31, centre.z), stone, "GateLintel")
	# Invisible barrier across the opening while the gate is locked; the
	# collision shape is disabled the moment the guard unlocks the gate.
	var blocker := add_collider(self, Vector3(r.size.x - 3.0, 3.0, 0.5),
			Vector3(centre.x, 0.0, centre.z), "GateBlocker")
	_gate_shape = blocker.get_child(0) as CollisionShape3D
	var sign := box(self, Vector3(9.0, 1.5, 0.35), Vector3(centre.x, pillar_h - 0.31, centre.z + 0.5), gold, "GateSign")
	sign.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var label := Label3D.new()
	label.text = "ANITS"
	label.font_size = 110
	label.pixel_size = 0.0085
	label.modulate = Color(0.10, 0.16, 0.28)
	label.position = Vector3(centre.x, pillar_h - 0.31, centre.z + 0.70)
	label.outline_size = 0
	add_child(label)
	var sub := Label3D.new()
	sub.text = "ANIL NEERUKONDA INSTITUTE OF TECHNOLOGY & SCIENCES"
	sub.font_size = 30
	sub.pixel_size = 0.0045
	sub.modulate = Color(0.96, 0.95, 0.9)
	sub.position = Vector3(centre.x, pillar_h - 1.4, centre.z + 0.55)
	sub.outline_size = 4
	sub.outline_modulate = Color(0.1, 0.12, 0.18)
	add_child(sub)


var _gate_open_target := false


func _build_back_gate(g: Dictionary) -> void:
	var centre_px: Array = g.get("center", [0, 0])
	var c := Campus.map_to_world(Vector2(centre_px[0], centre_px[1]))
	var half := float(g.get("half", 15)) * Campus.MAP_SCALE
	var m := mat(Color(str(g.get("color", "#3a5f9a"))))
	var h := float((g.get("pillar_size", [2.2, 9.0]))[1])
	for side in [-1.0, 1.0]:
		var s := float(side)
		box(self, Vector3(2.2, h, 2.2), Vector3(c.x + s * half, h * 0.5, c.z), m, "BackGatePillar")
		box(self, Vector3(2.6, 0.3, 2.6), Vector3(c.x + s * half, h + 0.15, c.z), m, "BackGateCap")
	box(self, Vector3(half * 2.0 + 2.2, 1.8, 2.0), Vector3(c.x, h - 0.9, c.z), m, "BackGateLintel")
	var label := Label3D.new()
	label.text = str(g.get("label", "Back Gate"))
	label.font_size = 56
	label.pixel_size = 0.009
	label.modulate = Color(1.0, 0.9, 0.55)
	label.position = Vector3(c.x, h - 0.9, c.z + 1.05)
	label.outline_size = 6
	label.outline_modulate = Color(0.05, 0.08, 0.16)
	add_child(label)


func set_gate_open(value: bool) -> void:
	_gate_open_target = value
	if _gate_shape:
		_gate_shape.set_deferred("disabled", value)


func _process(delta: float) -> void:
	for leaf in gate_leaves:
		var node: Node3D = leaf["node"]
		var side: float = leaf["side"]
		var target := deg_to_rad(78.0) * side if _gate_open_target else 0.0
		node.rotation.y = lerpf(node.rotation.y, target, minf(1.0, delta * 2.6))
	# distance-cull the grass chunks (32 MultiMeshes)
	var cam := get_viewport().get_camera_3d()
	if cam:
		for chunk in _grass_chunks:
			var c: Dictionary = chunk
			(c["node"] as Node3D).visible = (c["center"] as Vector3).distance_to(cam.global_position) < 85.0


# ------------------------------------------------------------------ buildings

func _build_buildings() -> void:
	for b in campus.get(KEY_BUILDINGS, []):
		var wr := _rect_world(b.get("rect", [0, 0, 1, 1]))
		var centre := Vector3(wr.position.x + wr.size.x * 0.5, 0.0, wr.position.y + wr.size.y * 0.5)
		var height := float(b.get("height", 8.0))
		var colour := Color(str(b.get("color", "#cccccc")))
		var model_kind := str(b.get("model", ""))
		var face := str(b.get("face", "S"))

		# ---- the ORIGINAL web-game model, when it exists ----
		var model_id := _model_for(model_kind)
		if model_id != "" and OriginalModels.scene_for(model_id) != null:
			match model_kind:
				"lowpoly_row":
					_build_lowpoly_row(b, wr, colour, height, face)
				"panel_block":
					_build_panel_block(b, wr, colour, height, face)
				_:
					_build_single_model(b, wr, colour, height, face, model_id)
			continue

		# ---- procedural fallback ----
		if model_kind == "admin_block":
			_build_admin_block(b)
			continue
		if model_kind == "noodle_bar":
			_build_noodle_bar(b, wr, colour, height, face)
			continue
		var m := mat(colour)
		m.emission_enabled = true
		m.emission = colour
		m.emission_energy_multiplier = 0.12
		var body := box(self, Vector3(wr.size.x, height, wr.size.y), Vector3(centre.x, height * 0.5, centre.z), m, b.get("name", "Building"))
		building_meshes[b.get("name", "")] = body
		var roof := box(self, Vector3(wr.size.x + 0.6, 0.4, wr.size.y + 0.6), Vector3(centre.x, height + 0.2, centre.z),
			mat(colour.darkened(0.12)), "Roof")
		roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var door := Vector3.ZERO
		if face.begins_with("E") or face.begins_with("W"):
			door = Vector3(wr.size.x * 0.5 if face.begins_with("E") else -wr.size.x * 0.5, 0.0, 0.0)
		else:
			door = Vector3(0.0, 0.0, wr.size.y * 0.5 if face.begins_with("S") else -wr.size.y * 0.5)
		var canopy := box(self, Vector3(4.0, 0.35, 3.0), Vector3(centre.x + door.x, 3.6, centre.z + door.z),
			mat(Color.html("#3b2616")), "Canopy")
		canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_add_building_label(str(b.get("name", "")), wr, height, face)
		add_collider(self, Vector3(wr.size.x, height, wr.size.y), Vector3(centre.x, 0.0, centre.z), "BuildingCol")


## Maps a building kind to the original model id.
func _model_for(kind: String) -> String:
	match kind:
		"admin_block": return "admin"
		"panel_block": return "brez"
		"lowpoly_row": return "lp"
		"stair_auditorium": return "stairaud"
		"workshop": return "workshop"
		"cafe": return "cafe"
		"bank": return "bank"
		"temple": return "temple"
	return ""


## One model fitted to the whole plot (admin, auditorium, cafe, bank, workshop, temple).
func _build_single_model(b: Dictionary, wr: Rect2, colour: Color, height: float, face: String, model_id: String) -> void:
	var centre := Vector3(wr.position.x + wr.size.x * 0.5, 0.0, wr.position.y + wr.size.y * 0.5)
	var yaw := 0.0
	if face.begins_with("W"):
		yaw = PI
	elif face.begins_with("N"):
		yaw = PI * 0.5
	elif face.begins_with("S"):
		yaw = -PI * 0.5
	if model_id == "admin":
		yaw = 0.0
	if model_id == "temple":
		yaw = PI * 0.5
	var target := Vector2(wr.size.x, wr.size.y)
	var node := OriginalModels.place(model_id, self, centre, target, yaw)
	if node == null:
		return
	node.name = str(b.get("name", "Building"))
	building_meshes[b.get("name", "")] = node
	_add_building_label(str(b.get("name", "")), wr, height, face)
	var box2 := OriginalModels.bounds_for(model_id)
	var scale := OriginalModels.scale_for(model_id, target)
	if model_id == "admin":
		# The original Admin Block has an open central hallway (model x -4.9..4.9)
		# running front-to-back. Only the two wings, the devotional statue and
		# the porch columns collides - exactly like the web build.
		var k := scale
		var wing_h := 14.0
		var inner := 5.0 * k
		var outer := 47.7 * k
		var depth := 29.0 * k
		var wing_w := outer - inner
		var wing_x := (inner + outer) * 0.5
		add_collider(self, Vector3(wing_w, wing_h, depth),
			Vector3(centre.x - wing_x, 0.0, centre.z), "AdminWestWing")
		add_collider(self, Vector3(wing_w, wing_h, depth),
			Vector3(centre.x + wing_x, 0.0, centre.z), "AdminEastWing")
		add_collider(self, Vector3(1.9 * k, 2.3, 1.9 * k), centre, "AdminStatue")
		for side in [-5.5, 5.5]:
			add_collider(self, Vector3(0.6 * k, 4.0, 0.6 * k),
				Vector3(centre.x + side * k, 0.0, centre.z + 19.65 * k), "AdminPorchColumn")
		return
	add_collider(self, Vector3(box2.size.x * scale, maxf(height, box2.size.y * scale), box2.size.z * scale),
		Vector3(centre.x, 0.0, centre.z), "BuildingCol")


## A row of low-poly block units, all entrances on the same face (as in the web game).
## The placement follows js/game.js `lpRow()` exactly: the unit depth sits
## flush against the far edge of the plot, the units are distributed along the
## plot with the web's gap, and each unit gets the web's collider size.
func _build_lowpoly_row(b: Dictionary, wr: Rect2, colour: Color, height: float, face: String) -> void:
	var centre := Vector3(wr.position.x + wr.size.x * 0.5, 0.0, wr.position.y + wr.size.y * 0.5)
	var box2 := OriginalModels.bounds_for("lp")
	if box2.size.y <= 0.001:
		return
	var packed := OriginalModels.scene_for("lp")
	if packed == null:
		return
	var ys := height / box2.size.y          # height scale
	var s := ys * 1.4                      # the web stretches the unit in X and Z
	var dep := box2.size.x * s             # depth across the building (entrance side)
	var unit_w := box2.size.z * s          # length of one unit along the row
	var along_x := face == "N" or face == "S"
	var length := wr.size.x if along_x else wr.size.y
	var n := maxi(1, int(floor((length - 1.0) / maxf(unit_w, 0.5))))
	var gap := (length - n * unit_w) / float(n + 1)
	var yaw: float = {"E": 0.0, "W": PI, "S": -PI * 0.5, "N": PI * 0.5}.get(face, 0.0)
	var inset := 0.6 * Campus.MAP_SCALE
	var c := Vector3((box2.position.x + box2.size.x * 0.5) * s, 0.0,
		(box2.position.z + box2.size.z * 0.5) * s)
	for i in n:
		var along := gap * (i + 1) + unit_w * (i + 0.5)
		var pos := centre
		if along_x:
			pos.x = wr.position.x + along
			pos.z = (wr.end.y - inset - dep * 0.5) if face == "S" else (wr.position.y + inset + dep * 0.5)
		else:
			pos.z = wr.position.y + along
			pos.x = (wr.end.x - inset - dep * 0.5) if face == "E" else (wr.position.x + inset + dep * 0.5)
		# wrapper -> rotated unit -> model, exactly like the web build
		var wrapper := Node3D.new()
		wrapper.name = "LowPolyUnit"
		wrapper.position = pos
		wrapper.rotation.y = yaw
		add_child(wrapper)
		var inst := packed.instantiate()
		wrapper.add_child(inst)
		inst.scale = Vector3(s, ys, s)
		inst.position = Vector3(-c.x, -box2.position.y * ys / s, -c.z)
		_apply_palette_skin(inst, colour)
		var col_size := Vector3(unit_w, height, dep) if along_x else Vector3(dep, height, unit_w)
		add_collider(self, col_size, Vector3(pos.x, 0.0, pos.z), "BuildingCol")
	_add_building_label(str(b.get("name", "")), wr, height, face)


## The classroom-panel block (CSE / ECE / EEE / Chemical) with its recoloured walls.
func _build_panel_block(b: Dictionary, wr: Rect2, colour: Color, height: float, face: String) -> void:
	var centre := Vector3(wr.position.x + wr.size.x * 0.5, 0.0, wr.position.y + wr.size.y * 0.5)
	var box2 := OriginalModels.bounds_for("brez")
	if box2.size.z <= 0.001:
		return
	# the web game scales so the block's LENGTH fits the plot depth, and stretches X by 1.3
	var z := minf(height * 2.1, wr.size.y - 0.8) / box2.size.z
	var yaw := 0.0 if face == "E" else PI
	var node := OriginalModels.place("brez", self, centre, Vector2(wr.size.x, wr.size.y), yaw)
	if node:
		node.scale = Vector3(z * 1.3, z, z)
		node.rotation.y = yaw
		node.position = centre
		node.position.y = -box2.position.y * z
		_tint_model(node, Color(str(b.get("tint", "#ffffff"))))
	# Entrance: dark door leaf, two side posts, a canopy and a step, exactly
	# like the web build's `door()` helper.
	var half_depth := box2.size.x * 0.5 * z * 1.3
	var side := 1.0 if face == "E" else -1.0
	var door_x := centre.x + side * (half_depth + 0.12)
	box(self, Vector3(0.26, 3.4, 3.0), Vector3(door_x, 1.7, centre.z),
		mat(Color.html("#2a2a30")), "BlockDoor")
	for offset in [-1.6, 1.6]:
		box(self, Vector3(0.5, 3.4, 0.26), Vector3(door_x + side * 0.05, 1.7, centre.z + offset),
			mat(Color.html("#3b2616")), "BlockDoorPost")
	box(self, Vector3(2.4, 0.28, 5.0), Vector3(door_x + side * 1.1, 3.6, centre.z),
		mat(Color.html("#55585f")), "BlockCanopy")
	box(self, Vector3(1.8, 0.3, 4.0), Vector3(door_x + side * 0.9, 0.15, centre.z),
		mat(Color.html("#b0aca0")), "BlockSteps")
	add_collider(self, Vector3(box2.size.x * z * 1.3, height, box2.size.z * z),
		Vector3(centre.x, 0.0, centre.z), "BuildingCol")
	_add_building_label(str(b.get("name", "")), wr, height, face)


## The "Magic Spot" noodle bar: a small neon kiosk with a pink body, a striped
## awning, a glowing sign and a tiled forecourt (the web build's voxel shop).
func _build_noodle_bar(b: Dictionary, wr: Rect2, colour: Color, height: float, face: String) -> void:
	var centre := Vector3(wr.position.x + wr.size.x * 0.5, 0.0, wr.position.y + wr.size.y * 0.5)
	var pink := mat(Color.html("#e05a9a"))
	pink.emission_enabled = true
	pink.emission = Color.html("#e05a9a")
	pink.emission_energy_multiplier = 0.22
	var cyan := mat(Color.html("#49d8e8"))
	cyan.emission_enabled = true
	cyan.emission = Color.html("#49d8e8")
	cyan.emission_energy_multiplier = 0.35
	var dark := mat(Color.html("#3a2338"))
	var body := box(self, Vector3(wr.size.x, height, wr.size.y),
		Vector3(centre.x, height * 0.5, centre.z), dark, "NoodleBar")
	building_meshes[b.get("name", "")] = body
	# counter window facing the road
	var side := 1.0 if face.begins_with("E") else -1.0
	var front_x := centre.x + side * (wr.size.x * 0.5 + 0.06)
	box(self, Vector3(0.16, 1.9, wr.size.y * 0.7), Vector3(front_x, 1.5, centre.z),
		cyan, "NoodleBarWindow")
	# striped awning
	for i in 5:
		var z := centre.z - wr.size.y * 0.42 + float(i) * wr.size.y * 0.21
		box(self, Vector3(1.9, 0.16, wr.size.y * 0.2),
			Vector3(front_x + side * 0.95, 2.85, z),
			pink if i % 2 == 0 else mat(Color.html("#f6f2e6")), "NoodleBarAwning")
	# neon sign
	var sign := Label3D.new()
	sign.text = "MAGIC SPOT"
	sign.font_size = 42
	sign.pixel_size = 0.007
	sign.modulate = Color.html("#ff9ad8")
	sign.outline_size = 7
	sign.outline_modulate = Color(0.12, 0.04, 0.12)
	sign.position = Vector3(front_x + side * 0.12, height - 0.6, centre.z)
	sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(sign)
	# tiled forecourt
	var tiles := mat(Color.html("#cfcac0"))
	box(self, Vector3(4.2, 0.08, wr.size.y + 1.6),
		Vector3(front_x + side * 2.1, 0.04, centre.z), tiles, "NoodleBarForecourt")
	add_collider(self, Vector3(wr.size.x, height, wr.size.y), Vector3(centre.x, 0.0, centre.z), "BuildingCol")
	_add_building_label(str(b.get("name", "")), wr, height, face)


## Recolours every material of an imported model (the web game does the same with
## its palette trick).
func _tint_model(node: Node, colour: Color) -> void:
	for child in node.get_children():
		var mi := child as MeshInstance3D
		if mi and mi.mesh:
			var mat := mi.material_override
			if mat == null and mi.get_surface_override_material_count() > 0:
				mat = mi.get_surface_override_material(0)
			if mat is StandardMaterial3D:
				var copy := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
				copy.albedo_color = colour
				copy.roughness = 0.9
				copy.metallic = 0.0
				copy.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
				mi.material_override = copy
		_tint_model(child, colour)


## The original low-poly pack uses one 256x256 palette atlas; the web game
## recolours the 32x32 wall swatch at (32, 64) for each building. Reproducing
## that keeps the roof, windows and door colours while making the walls match
## the web build (peach IT block, brown Civil blocks, sandy CSM block).
static var _palette_base: Image = null
static var _palette_cache: Dictionary = {}

static func _palette_texture(colour: Color) -> Texture2D:
	var key := colour.to_html()
	if _palette_cache.has(key):
		return _palette_cache[key] as Texture2D
	if _palette_base == null:
		var palette := load("res://textures/palette_buildings.png") as Texture2D
		if palette:
			_palette_base = palette.get_image()
	if _palette_base == null or _palette_base.is_empty():
		return null
	var img := _palette_base.duplicate() as Image
	img.fill_rect(Rect2i(32, 64, 32, 32), colour)
	var tex := ImageTexture.create_from_image(img)
	_palette_cache[key] = tex
	return tex


func _apply_palette_skin(node: Node, colour: Color) -> void:
	var tex := _palette_texture(colour)
	if tex == null:
		return
	var material := StandardMaterial3D.new()
	material.albedo_texture = tex
	material.albedo_color = Color.WHITE
	material.roughness = 0.88
	material.metallic = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.emission_enabled = true
	material.emission_texture = tex
	material.emission = Color(0.20, 0.20, 0.20)
	_apply_palette_recursive(node, material)


func _apply_palette_recursive(node: Node, material: StandardMaterial3D) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh:
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_palette_recursive(child, material)


## The Admin Block: two solid wings with a walkable corridor between them,
## exactly like the original's central hallway.
func _build_admin_block(b: Dictionary) -> void:
	var wr := _rect_world(b.get("rect", [0, 0, 1, 1]))
	var centre := Vector3(wr.position.x + wr.size.x * 0.5, 0.0, wr.position.y + wr.size.y * 0.5)
	var height := float(b.get("height", 12.0))
	var colour := Color(str(b.get("color", "#d84b4b")))
	var wall := mat(colour)
	wall.emission_enabled = true
	wall.emission = colour
	wall.emission_energy_multiplier = 0.12
	var corridor_w := 9.56
	var depth := (wr.size.y - corridor_w) * 0.5
	for wing_side in [-1.0, 1.0]:
		var s := float(wing_side)
		var wing_centre := Vector3(centre.x, 0.0, centre.y + s * (corridor_w * 0.5 + depth * 0.5))
		var wing := box(self, Vector3(wr.size.x, height, depth), Vector3(wing_centre.x, height * 0.5, wing_centre.z), wall, "AdminWing")
		building_meshes[b.get("name", "")] = wing
		var roof := box(self, Vector3(wr.size.x + 0.6, 0.4, depth + 0.4), Vector3(wing_centre.x, height + 0.2, wing_centre.z),
			mat(colour.darkened(0.12)), "Roof")
		roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_collider(self, Vector3(wr.size.x, height, depth), Vector3(wing_centre.x, 0.0, wing_centre.z), "AdminWingCol")
	box(self, Vector3(wr.size.x, 0.14, corridor_w), Vector3(centre.x, 0.07, centre.y), mat(Color.html("#e9e6d8")), "AdminCorridor")
	for end_side in [-1.0, 1.0]:
		var s := float(end_side)
		box(self, Vector3(0.5, height, corridor_w + 0.8),
			Vector3(centre.x + s * (wr.size.x * 0.5 - 0.25), height * 0.5, centre.y), wall, "AdminDoorFrame")
	# The web build's "Admissions Office" is inside this block, so the facade
	# sign names both functions (the JSON name stays "ADMIN BLOCK" because the
	# office door and the NPC anchors look it up by that key).
	_add_building_label("ADMIN & ADMISSIONS", wr, height, "NS")


func _add_building_label(text: String, wr: Rect2, height: float, face := "S") -> void:
	## A solid navy signboard bolted to the facade, instead of a floating label.
	if text.strip_edges() == "":
		return
	var side := face.strip_edges().to_upper()
	if side == "" or side == "NS" or side == "SN":
		side = "S"
	elif side == "WE" or side == "EW":
		side = "E"
	side = side.left(1)
	if side != "N" and side != "E" and side != "W":
		side = "S"
	var normal := Vector3.BACK
	var rot := 0.0
	var facade_len := wr.size.x
	match side:
		"N":
			normal = Vector3.FORWARD
			rot = PI
		"E":
			normal = Vector3.RIGHT
			rot = PI * 0.5
			facade_len = wr.size.y
		"W":
			normal = Vector3.LEFT
			rot = -PI * 0.5
			facade_len = wr.size.y
		_:
			normal = Vector3.BACK
			rot = 0.0
			facade_len = wr.size.x
	var centre := Vector3(wr.position.x + wr.size.x * 0.5, 0.0, wr.position.y + wr.size.y * 0.5)
	var face_pos := centre + normal * 0.0
	match side:
		"N":
			face_pos.z = wr.position.y
		"S":
			face_pos.z = wr.end.y
		"E":
			face_pos.x = wr.end.x
		"W":
			face_pos.x = wr.position.x
	var sign_w := clampf(float(text.length()) * 0.34, 3.0, minf(facade_len * 0.72, 12.0))
	var sign_y := minf(maxf(height * 0.60, 2.2), maxf(height - 1.0, 1.5))
	var board_pos := Vector3(face_pos.x, sign_y, face_pos.z) + normal * 0.10
	var board := box(self, Vector3(sign_w + 0.34, 1.08, 0.14), board_pos,
		mat(Color.html("#0e2a4f")), "SignBoard")
	board.rotation.y = rot
	board.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var trim := box(self, Vector3(sign_w + 0.34, 0.06, 0.16),
		Vector3(board_pos.x, board_pos.y + 0.56, board_pos.z), mat(Color.html("#d7b04a")), "SignTrim")
	trim.rotation.y = rot
	trim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var label := Label3D.new()
	label.text = text.to_upper()
	label.font_size = 64
	label.pixel_size = 0.0072
	label.modulate = Color.html("#f2f5ff")
	label.outline_size = 0
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.rotation.y = rot
	label.position = board_pos + normal * 0.09
	add_child(label)
	label_nodes.append(label)


# ------------------------------------------------------------------ specials

func _build_specials() -> void:
	for s in campus.get(KEY_SPECIALS, []):
		if s.has("rect"):
			var wr := _rect_world(s["rect"])
			var centre := Vector3(wr.position.x + wr.size.x * 0.5, 0.0, wr.position.y + wr.size.y * 0.5)
			if str(s.get("name", "")) == "Open Auditorium" and OriginalModels.scene_for("aud") != null:
				# The original blue-roofed open-air pavilion from the web game.
				var node := OriginalModels.place("aud", self, centre,
					Vector2(wr.size.x, wr.size.y), PI)
				if node:
					node.name = "OpenAuditorium"
					node.position.y += 0.05
					var k := OriginalModels.scale_for("aud", Vector2(wr.size.x, wr.size.y))
					# Eight column colliders, exactly where the web build places them.
					for offset in [[3.42, -1.42], [1.42, -3.42], [-1.42, -3.42],
							[-3.42, -1.42], [-3.42, 1.42], [-1.42, 3.42],
							[1.42, 3.42], [3.42, 1.42]]:
						add_collider(self, Vector3(0.95, 3.0, 0.95),
							Vector3(centre.x + float(offset[0]) * k, 0.0,
								centre.z + float(offset[1]) * k), "AuditoriumColumn")
					var label := Label3D.new()
					label.text = "Open Auditorium"
					label.font_size = 44
					label.pixel_size = 0.011
					label.modulate = Color(1.0, 0.96, 0.78)
					label.outline_size = 7
					label.outline_modulate = Color(0.05, 0.08, 0.16)
					label.position = Vector3(centre.x, 13.8, centre.z)
					add_child(label)
				continue
			var pavilion := CylinderMesh.new()
			pavilion.top_radius = wr.size.x * 0.5
			pavilion.bottom_radius = wr.size.x * 0.5
			pavilion.height = 3.4
			pavilion.radial_segments = 12
			var mi := MeshInstance3D.new()
			mi.mesh = pavilion
			mi.material_override = mat(Color.html("#8a5a45"))
			mi.position = Vector3(centre.x, 1.7, centre.z)
			mi.name = str(s.get("name", "Special"))
			add_child(mi)
			var roof := CylinderMesh.new()
			roof.top_radius = 0.0
			roof.bottom_radius = wr.size.x * 0.62
			roof.height = 2.2
			roof.radial_segments = 12
			var rmi := MeshInstance3D.new()
			rmi.mesh = roof
			rmi.material_override = mat(Color.html("#6b3f2f"))
			rmi.position = Vector3(centre.x, 4.2, centre.z)
			add_child(rmi)
			add_collider(self, Vector3(wr.size.x * 0.8, 3.4, wr.size.x * 0.8), Vector3(centre.x, 0.0, centre.z), "PavilionCol")
		elif s.has("pos") and str(s.get("name", "")) == "Fountain":
			var p: Array = s["pos"]
			var w := Campus.map_to_world(Vector2(p[0], p[1]))
			var radius := float(s.get("radius", 45)) * Campus.MAP_SCALE
			var basin := CylinderMesh.new()
			basin.top_radius = radius
			basin.bottom_radius = radius
			basin.height = 0.5
			basin.radial_segments = 20
			var mi := MeshInstance3D.new()
			mi.mesh = basin
			mi.material_override = mat(Color.html("#a8c8d8"))
			mi.position = Vector3(w.x, 0.25, w.z)
			add_child(mi)
			var column := CylinderMesh.new()
			column.top_radius = 0.25
			column.bottom_radius = 0.5
			column.height = 2.4
			var cmi := MeshInstance3D.new()
			cmi.mesh = column
			cmi.material_override = mat(Color.html("#d8d8d0"))
			cmi.position = Vector3(w.x, 1.2, w.z)
			add_child(cmi)
		elif s.has("pos") and str(s.get("name", "")) == "Indian Flag":
			var p: Array = s["pos"]
			var w := Campus.map_to_world(Vector2(p[0], p[1]))
			var h := float(s.get("pole_height", 14.0))
			var pole := CylinderMesh.new()
			pole.top_radius = 0.08
			pole.bottom_radius = 0.12
			pole.height = h
			var mi := MeshInstance3D.new()
			mi.mesh = pole
			mi.material_override = mat(Color.html("#d0d0d0"))
			mi.position = Vector3(w.x, h * 0.5, w.z)
			add_child(mi)
			# Tricolour: saffron, white and green bands with a small chakra.
			var flag_y := h - 1.5
			var band_h := 0.92
			var colours := [Color.html("#ff9933"), Color.html("#ffffff"), Color.html("#138808")]
			for i in 3:
				var flag := QuadMesh.new()
				flag.size = Vector2(4.2, band_h)
				var fmi := MeshInstance3D.new()
				fmi.mesh = flag
				fmi.material_override = mat(colours[i], 1.0, 0.30)
				fmi.position = Vector3(w.x + 2.1, flag_y + (1 - i) * band_h, w.z)
				fmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				add_child(fmi)
			var chakra := CylinderMesh.new()
			chakra.top_radius = 0.36
			chakra.bottom_radius = 0.36
			chakra.height = 0.03
			chakra.radial_segments = 20
			var cmi := MeshInstance3D.new()
			cmi.mesh = chakra
			cmi.material_override = mat(Color.html("#0a2a7a"), 1.0, 0.2)
			cmi.rotation.x = PI * 0.5
			cmi.position = Vector3(w.x + 2.1, flag_y, w.z + 0.02)
			cmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(cmi)


# ------------------------------------------------------------------ props

func _build_props() -> void:
	var props: Dictionary = campus.get(KEY_PROPS, {})
	var rng := LCG.new(int(props.get("seed", 5)))
	_build_trees(int(props.get("trees", 150)), float(props.get("tree_pine_ratio", 0.26)), rng)
	_build_bushes(int(props.get("bushes", 130)), rng)
	_build_grass(int(props.get("grass_instances", 4200)), int(props.get("grass_chunks", 32)), rng)
	_build_ground_cover(rng)
	_build_cars(int(props.get("cars", 91)), rng)


func _scatter_ok(px: float, py: float, margin: float, allow_lawn := false) -> bool:
	for b in campus.get(KEY_BUILDINGS, []):
		var r: Array = b["rect"]
		if px > r[0] - margin and px < r[2] + margin and py > r[1] - margin and py < r[3] + margin:
			return false
	for r in campus.get(KEY_ROADS, []):
		if px > r[0] - margin and px < r[2] + margin and py > r[1] - margin and py < r[3] + margin:
			return false
	var zones: Dictionary = campus.get(KEY_ZONES, {})
	for key in zones:
		if allow_lawn and key == "central_lawn":
			continue
		var z: Array = zones[key]
		if px > z[0] - margin and px < z[2] + margin and py > z[1] - margin and py < z[3] + margin:
			return false
	return true


func _plan_pos(px: float, py: float, y := 0.0) -> Vector3:
	var w := Campus.map_to_world(Vector2(px, py))
	return Vector3(w.x, y, w.z)


func _inside_building(px: float, py: float, margin: float) -> bool:
	for b in campus.get(KEY_BUILDINGS, []):
		var r: Array = b.get("rect", [])
		if r.size() >= 4 and px > float(r[0]) - margin and px < float(r[2]) + margin \
				and py > float(r[1]) - margin and py < float(r[3]) + margin:
			return true
	return false


func _inside_road(px: float, py: float, margin: float) -> bool:
	for r in campus.get(KEY_ROADS, []):
		if r.size() >= 4 and px > float(r[0]) - margin and px < float(r[2]) + margin \
				and py > float(r[1]) - margin and py < float(r[3]) + margin:
			return true
	return false


func _too_close_plan(spots: Array, px: float, py: float, min_px: float) -> bool:
	var min_sq := min_px * min_px
	for s in spots:
		var p: Vector2 = s
		var dx := p.x - px
		var dy := p.y - py
		if dx * dx + dy * dy < min_sq:
			return true
	return false


func _add_multimesh(batch_name: String, mesh: Mesh, transforms: Array, material: Material,
		colors := [], cast_shadow := false) -> MultiMeshInstance3D:
	var mmi := PropsFactory.batch(batch_name, mesh, transforms, material, colors, cast_shadow)
	if mmi:
		add_child(mmi)
	return mmi


func _add_instance(groups: Dictionary, species: String, xform: Transform3D, tint: Color) -> void:
	if not groups.has(species):
		groups[species] = {"transforms": [], "colors": []}
	groups[species]["transforms"].append(xform)
	groups[species]["colors"].append(tint)


func _flush_groups(groups: Dictionary, prefix: String, cast_shadow: bool) -> void:
	for species in groups.keys():
		var entry: Dictionary = groups[species]
		var transforms: Array = entry["transforms"]
		var colors: Array = entry["colors"]
		var parts: Array = PropsFactory.model(str(species)).get("parts", [])
		for surface in parts.size():
			var mmi := PropsFactory.batch("%s_%s_%d" % [prefix, str(species), surface],
				PropsFactory.part_mesh(str(species), surface), transforms,
				PropsFactory.part_material(str(species), surface), colors, cast_shadow)
			if mmi:
				add_child(mmi)


func _pick_species(kind: String, rng: LCG) -> String:
	var list: Array = PropsFactory.SPECIES.get(kind, ["CommonTree_1"])
	return str(list[rng.randi_range(0, list.size() - 1)])


func _leaf_tint(kind: String, rng: LCG) -> Color:
	match kind:
		"pine":
			return Color(0.84, 0.96, 0.88).lerp(Color(1.0, 1.0, 0.95), rng.randf())
		"twisted":
			return Color(1.0, 0.90, 0.78).lerp(Color(1.0, 0.98, 0.90), rng.randf())
		"dead":
			return Color.WHITE
	return Color(0.92, 1.0, 0.90).lerp(Color(1.0, 1.0, 0.94), rng.randf())


func _add_tree(groups: Dictionary, species: String, world_pos: Vector3, target_height: float,
		yaw: float, tint: Color) -> void:
	var model := PropsFactory.model(species)
	if not model.get("ok", false):
		return
	var scale := target_height / maxf(float(model.get("height", 1.0)), 0.2)
	# slightly slimmer trunks than the pack's default - reads closer to the
	# web build's low-poly trees and keeps canopies from swallowing the camera.
	var xform := Transform3D(Basis(Vector3.UP, yaw).scaled(
		Vector3(scale * 0.8, scale, scale * 0.8)), world_pos)
	_add_instance(groups, species, xform, tint)
	_prop_collider(Vector3(0.55, 2.4, 0.55), world_pos)


## True when a tree can stand here without covering an NPC, the spawn, the gate
## or a mission marker. The web build also keeps its trees clear of people.
func _tree_spot_ok(px: float, py: float) -> bool:
	# gate + spawn apron + ANITS sign
	if px > 78.0 and px < 168.0 and py > 406.0:
		return false
	var metres := 1.0 / Campus.MAP_SCALE
	for npc in CampusDB.npc_list:
		var p: Array = npc.get("pos", [])
		if p.size() >= 2:
			var d := Vector2(px - float(p[0]), py - float(p[1])).length()
			if d < 5.0 * metres:
				return false
		for point in npc.get("route", []):
			var rp: Array = point
			if rp.size() >= 2:
				var rd := Vector2(px - float(rp[0]), py - float(rp[1])).length()
				if rd < 3.0 * metres:
					return false
	# mission anchors (gate crossing, Admin front, block entrances, parade)
	for anchor in [[122, 396], [164, 337], [164, 311], [154, 262], [134, 438],
			[211, 397], [236, 377], [174, 300], [282, 190]]:
		var ap: Array = anchor
		if Vector2(px - float(ap[0]), py - float(ap[1])).length() < 4.5 * metres:
			return false
	return true


## 150 trees: deliberate avenue rows framing the gate and long streets, then a
## deterministic scatter over every open lawn and gap.
func _build_trees(total: int, pine_ratio: float, rng: LCG) -> void:
	var groups: Dictionary = {}
	var occupied: Array = []
	var placed := 0
	var avenue: Array = []
	for z in range(356, 414, 9):
		avenue.append(Vector2(102.0, float(z)))
		avenue.append(Vector2(144.0, float(z)))
	for z in range(78, 340, 22):
		avenue.append(Vector2(257.0, float(z)))
	for z in range(360, 431, 16):
		avenue.append(Vector2(78.0, float(z)))
	for p in avenue:
		if _inside_building(p.x, p.y, 1.5) or _inside_road(p.x, p.y, -1.0):
			continue
		if not _tree_spot_ok(p.x, p.y):
			continue
		var kind := "tree"
		if rng.randf() < 0.34:
			kind = "pine"
		var target := rng.randf_range(5.4, 7.6)
		if kind == "pine":
			target = rng.randf_range(6.0, 8.4)
		_add_tree(groups, _pick_species(kind, rng), _plan_pos(p.x, p.y), target,
			rng.randf() * TAU, _leaf_tint(kind, rng))
		occupied.append(p)
		placed += 1

	var attempts := 0
	while placed < total and attempts < total * 80:
		attempts += 1
		var px := rng.randf_range(62.0, 364.0)
		var py := rng.randf_range(62.0, 428.0)
		if not _scatter_ok(px, py, 4.0, false):
			continue
		if not _tree_spot_ok(px, py):
			continue
		if _too_close_plan(occupied, px, py, 7.0 / Campus.MAP_SCALE):
			continue
		var kind := "tree"
		if rng.randf() < pine_ratio:
			kind = "pine"
		var target := rng.randf_range(4.8, 7.4)
		if kind == "pine":
			target = rng.randf_range(5.6, 8.2)
		_add_tree(groups, _pick_species(kind, rng), _plan_pos(px, py), target,
			rng.randf() * TAU, _leaf_tint(kind, rng))
		occupied.append(Vector2(px, py))
		placed += 1
	_flush_groups(groups, "Tree", true)


func _build_bushes(count: int, rng: LCG) -> void:
	var groups: Dictionary = {}
	var spots: Array = []
	var attempts := 0
	while spots.size() < count and attempts < count * 80:
		attempts += 1
		var px := rng.randf_range(61.0, 365.0)
		var py := rng.randf_range(61.0, 429.0)
		if not _scatter_ok(px, py, 1.2, true):
			continue
		if _too_close_plan(spots, px, py, 2.4 / Campus.MAP_SCALE):
			continue
		var species := "flower_bush" if rng.randf() < 0.34 else "bush"
		var model_id := _pick_species(species, rng)
		var target := rng.randf_range(0.8, 1.35)
		var scale := target / maxf(PropsFactory.model_height(model_id), 0.2)
		var world := _plan_pos(px, py)
		var tint := Color(0.9, 1.0, 0.88).lerp(Color(1.0, 1.0, 0.9), rng.randf())
		_add_instance(groups, model_id,
			Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(scale, scale, scale)), world),
			tint)
		spots.append(Vector2(px, py))
	_flush_groups(groups, "Bush", false)


## 4200 animated grass tufts in 32 distance-culled chunks.
func _build_grass(total: int, chunks: int, rng: LCG) -> void:
	chunks = maxi(chunks, 1)
	var cols := 8
	var rows := maxi(1, int(ceil(float(chunks) / float(cols))))
	var extent: Array = campus.get("extent_plan_px", [58, 58, 368, 432])
	var x0 := float(extent[0])
	var y0 := float(extent[1])
	var x1 := float(extent[2])
	var y1 := float(extent[3])
	var cw := (x1 - x0) / float(cols)
	var ch := (y1 - y0) / float(rows)
	var per := maxi(1, int(round(float(total) / float(cols * rows))))
	var species_list: Array = PropsFactory.SPECIES["grass"]
	for cy in rows:
		for cx in cols:
			var species: String = species_list[(cx + cy * cols) % species_list.size()]
			var transforms: Array = []
			var colors: Array = []
			var attempts := 0
			while transforms.size() < per and attempts < per * 40:
				attempts += 1
				var px := x0 + (float(cx) + rng.randf()) * cw
				var py := y0 + (float(cy) + rng.randf()) * ch
				if not _scatter_ok(px, py, 0.4, true):
					continue
				var h := rng.randf_range(0.45, 0.82) if species.contains("Tall") \
					else rng.randf_range(0.30, 0.62)
				var scale := h / maxf(PropsFactory.model_height(species), 0.1)
				var yaw := rng.randf() * TAU
				var world := _plan_pos(px, py)
				transforms.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(scale, scale, scale)), world))
				colors.append(Color(0.84, 1.0, 0.80).lerp(Color(1.0, 1.0, 0.86), rng.randf()))
			var mmi := PropsFactory.batch("Grass_%02d_%02d" % [cx, cy],
				PropsFactory.part_mesh(species, 0), transforms,
				PropsFactory.part_material(species, 0), colors, false)
			if mmi:
				add_child(mmi)
				var centre := _plan_pos(x0 + (float(cx) + 0.5) * cw, y0 + (float(cy) + 0.5) * ch)
				_grass_chunks.append({"node": mmi, "center": centre})


func _build_ground_cover(rng: LCG) -> void:
	_scatter_simple("Clover_1", 320, rng, 0.6, 0.07, 0.15, [], false, 0.7)
	_scatter_simple("Clover_2", 220, rng, 0.6, 0.07, 0.15, [], false, 0.6)
	var flower_tints := [Color(1.0, 0.92, 0.9), Color(1.0, 0.98, 0.85), Color(0.92, 0.94, 1.0)]
	_scatter_simple("Flower_3_Group", 70, rng, 1.2, 0.35, 0.65, flower_tints, false, 2.0)
	_scatter_simple("Flower_4_Group", 60, rng, 1.2, 0.35, 0.65, flower_tints, false, 2.0)
	_scatter_simple("Fern_1", 55, rng, 1.2, 0.35, 0.70, [], false, 1.8)
	_scatter_simple("Rock_Medium_1", 12, rng, 2.4, 0.55, 1.30, [], true, 4.5)
	_scatter_simple("Rock_Medium_2", 10, rng, 2.4, 0.50, 1.10, [], true, 4.5)
	_scatter_simple("Rock_Medium_3", 8, rng, 2.4, 0.45, 0.95, [], true, 4.5)
	_scatter_simple("Pebble_Round_1", 26, rng, 1.4, 0.15, 0.35, [], false, 1.2)
	_scatter_simple("Pebble_Square_1", 20, rng, 1.4, 0.15, 0.35, [], false, 1.2)


func _scatter_simple(model_id: String, count: int, rng: LCG, margin: float,
		h_min: float, h_max: float, tints: Array, collide: bool, min_dist_m: float) -> void:
	var model := PropsFactory.model(model_id)
	if not model.get("ok", false):
		return
	var transforms: Array = []
	var colors: Array = []
	var spots: Array = []
	var attempts := 0
	var min_px := min_dist_m / Campus.MAP_SCALE
	while transforms.size() < count and attempts < count * 80:
		attempts += 1
		var px := rng.randf_range(60.0, 366.0)
		var py := rng.randf_range(60.0, 430.0)
		if not _scatter_ok(px, py, margin, true):
			continue
		if _too_close_plan(spots, px, py, min_px):
			continue
		var h := rng.randf_range(h_min, h_max)
		var scale := h / maxf(PropsFactory.model_height(model_id), 0.05)
		var world := _plan_pos(px, py)
		transforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(scale, scale, scale)), world))
		if tints.is_empty():
			colors.append(Color.WHITE)
		else:
			colors.append(tints[rng.randi_range(0, tints.size() - 1)])
		spots.append(Vector2(px, py))
		if collide:
			_prop_collider(Vector3(0.9, maxf(h * 0.55, 0.35), 0.9), world)
	var groups := {model_id: {"transforms": transforms, "colors": colors}}
	_flush_groups(groups, "Detail", false)


## 91 parked cars, three neat rows in the parking apron.
func _build_cars(count: int, rng: LCG) -> void:
	if count <= 0:
		return
	var transforms: Array = []
	var colors: Array = []
	var palette := [
		Color.html("#c05040"), Color.html("#3b6fb5"), Color.html("#d8d8d2"),
		Color.html("#2f3a46"), Color.html("#7a8a99"), Color.html("#d9a441"),
		Color.html("#4f7a52"), Color.html("#8b4a7a"), Color.html("#b8c4cc"),
	]
	var zone: Array = (campus.get(KEY_ZONES, {}) as Dictionary).get("parking", [])
	if zone.size() == 4:
		var wr := _rect_world(zone)
		var rows := 3
		var per_row := int(ceil(float(count) / float(rows)))
		var z0 := wr.position.y + 3.0
		var z1 := wr.end.y - 3.0
		var step := minf((z1 - z0) / maxf(float(per_row - 1), 1.0), 3.0)
		var cx := wr.position.x + wr.size.x * 0.5
		var offsets := [-7.6, 0.0, 7.6]
		var made := 0
		for row in rows:
			for i in per_row:
				if made >= count:
					break
				var x := cx + float(offsets[row])
				var z := z0 + step * float(i)
				var yaw := PI * 0.5 if row % 2 == 0 else -PI * 0.5
				transforms.append(Transform3D(Basis(Vector3.UP, yaw), Vector3(x, 0.0, z)))
				colors.append(palette[made % palette.size()])
				made += 1
			if made >= count:
				break
	if transforms.is_empty():
		return
	var body := PropsFactory.batch("CarBodies", PropsFactory.car_body(), transforms,
		PropsFactory.car_material(), colors, true)
	if body:
		add_child(body)
	var glass := PropsFactory.batch("CarGlass", PropsFactory.car_glass(), transforms,
		PropsFactory.glass_material(), [], false)
	if glass:
		add_child(glass)
	var wheels := PropsFactory.batch("CarWheels", PropsFactory.car_wheels(), transforms,
		PropsFactory.wheel_material(), [], true)
	if wheels:
		add_child(wheels)
	for t in transforms:
		_prop_collider(Vector3(4.3, 1.5, 2.0), (t as Transform3D).origin)


func _build_lamps() -> void:
	var m := mat(Color.html("#3a3f4a"))
	var glow := mat(Color.html("#fff0b8"))
	glow.emission_enabled = true
	glow.emission = Color.html("#fff0b8")
	glow.emission_energy_multiplier = 0.9
	for l in campus.get(KEY_LAMPS, []):
		var p: Array = l["pos"]
		var w := Campus.map_to_world(Vector2(p[0], p[1]))
		var face := float(l.get("face", 1))
		var pole := CylinderMesh.new()
		pole.top_radius = 0.07
		pole.bottom_radius = 0.11
		pole.height = 5.2
		var mi := MeshInstance3D.new()
		mi.mesh = pole
		mi.material_override = m
		mi.position = Vector3(w.x, 2.6, w.z)
		add_child(mi)
		var head := box(self, Vector3(0.9, 0.12, 0.3), Vector3(w.x + face * 0.8, 5.05, w.z), glow, "LampHead")
		head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_benches() -> void:
	var wood := mat(Color.html("#6e3f1c"))
	var metal := mat(Color.html("#2d3138"))
	for b in campus.get(KEY_BENCHES, []):
		var p: Array = b["pos"]
		var w := Campus.map_to_world(Vector2(p[0], p[1]))
		var yaw := float(b.get("yaw", 0.0))
		var seat := box(self, Vector3(1.8, 0.12, 0.5), Vector3(w.x, 0.45, w.z), wood, "BenchSeat")
		seat.rotation.y = yaw
		for side in [-0.7, 0.7]:
			var leg := box(self, Vector3(0.12, 0.45, 0.45), Vector3(w.x + cos(yaw) * side, 0.22, w.z - sin(yaw) * side), metal, "BenchLeg")
			leg.rotation.y = yaw
			leg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_vending_machines() -> void:
	for v in campus.get(KEY_VENDING, []):
		var p: Array = v["pos"]
		var w := Campus.map_to_world(Vector2(p[0], p[1]))
		var colour := Color(str(v.get("color", "#c62828")))
		var body := box(self, Vector3(1.1, 2.0, 0.8), Vector3(w.x, 1.0, w.z), mat(colour), "VendingMachine")
		body.add_to_group("interactables")
		add_collider(self, Vector3(1.1, 2.0, 0.8), Vector3(w.x, 0.0, w.z), "VendingCol")
		var glass := box(self, Vector3(0.9, 1.3, 0.84), Vector3(w.x, 1.25, w.z), mat(Color.html("#304050")), "VendingGlass")
		glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var label := Label3D.new()
		label.text = str(v.get("label", ""))
		label.font_size = 28
		label.pixel_size = 0.006
		label.position = Vector3(w.x, 2.3, w.z)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
