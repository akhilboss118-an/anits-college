class_name AdminOffice
extends Node3D
## Ms. Laksmi's Admin Office: the sealed waiting-room + office from the web
## build (js/game.js, "Admin Office"). It is built far west of the campus and
## reached through the door in the Admin Block's central hallway.
##
## The room is a sealed box (four walls, a partition, one exit door) so the
## player can never wander out of it. Everything inside is low-poly boxes with
## procedurally generated textures, a handful of warm omni lights and a few
## Label3D signs, which keeps the draw-call and light budget low enough for
## mobile while still reading as a lit, dressed interior.
##
## PUBLIC API - main.gd and the campus tour rely on these, do not rename or
## change their meaning:
##   entry_pos        world position the player is dropped at when entering
##   exit_pos         world position in front of the exit door
##   laksmi_seat      world position of Ms. Laksmi's chair
##   desk_pos         world position of the reception desk
##   hall_door_pos    world position of the Admin Block hallway door
##   hall_return_pos  world position in the hallway after leaving
##   build_hall_door(admin_centre, k)

const CENTER := Vector3(-320.0, 0.0, 0.0)
const HALF_W := 6.0
const HALF_D := 5.0
const HEIGHT := 3.4
const PARTITION_Z := 0.5
const DOOR_X0 := 1.4
const DOOR_X1 := 3.6

## Height of the painted wainscot band and its wooden rail.
const DADO_TOP := 1.05

## Mobile light budget: six warm omni lights is the ceiling for this room.
const MAX_LIGHTS := 6

# ------------------------------------------------------------------ palette
const CREAM := Color("#ece5d6")
const BLUE := Color("#d7e4ee")
const TRIM := Color("#7a5230")
const WOOD := Color("#6b4a2d")
const CEILING := Color("#e9ecee")
const TILE := Color("#ece9e2")
const GRID := Color("#bfc6c4")
const SOFA := Color("#2f4f7a")
const SOFA_LIGHT := Color("#3b6294")
const METAL := Color("#444a52")

const DADO := Color("#c6d3da")        ## wainscot paint below the dado rail
const DADO_BLUE := Color("#aac3d6")   ## wainscot paint for the blue feature wall
const NAVY := Color("#1d3557")
const GOLD := Color("#ffd54a")
const WARM := Color("#ffe4b8")        ## colour of the ceiling lamps
const WOOD_DARK := Color("#4d3320")

## The reception desk in *room local* space. `desk_pos` below is the same
## point expressed in world space, because the room node itself is placed at
## CENTER - mixing the two up used to park the desk 320 m outside the room.
const DESK_LOCAL := Vector3(0.0, 0.0, -2.7)

# ------------------------------------------------------------------ public
var entry_pos := CENTER + Vector3(2.0, 0.12, 1.9)
var exit_pos := CENTER + Vector3(2.5, 0.12, 4.5)
var laksmi_seat := CENTER + Vector3(0.43, 0.0, -3.5)
var desk_pos := CENTER + DESK_LOCAL
var hall_door_pos := Vector3.ZERO
var hall_return_pos := Vector3.ZERO

var _glass_left: Node3D = null
var _glass_right: Node3D = null
var _door_node: Node3D = null
var _t := 0.0
var _glass_open := 0.0

## Shared materials, keyed by their look so identical surfaces reuse one
## material (and therefore one shader instance).
var _mats := {}
## Upper-wall materials, keyed by the wall colour they were built for.
var _wall_mats := {}


func build() -> void:
	position = CENTER
	_mats.clear()
	_wall_mats.clear()
	_build_materials()
	_build_shell()
	_build_partition()
	_build_waiting_room()
	_build_office_side()
	_build_restroom()
	_build_signs()
	_build_lights()


# ------------------------------------------------------------------ materials

## Builds every textured surface once so the room is made of real materials
## rather than flat coloured boxes.
func _build_materials() -> void:
	# --- floor: 4x4 ceramic tiles with grout lines, projected in world space
	# so the grid stays square and continuous across the whole room.
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_texture = _floor_texture()
	floor_mat.uv1_triplanar = true
	floor_mat.uv1_scale = Vector3(0.5, 0.5, 0.5)
	floor_mat.texture_repeat = true
	floor_mat.roughness = 0.42
	floor_mat.metallic = 0.0
	floor_mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	_mats["floor"] = floor_mat

	# --- ceiling: acoustic panels with recessed seams.
	var ceil_mat := StandardMaterial3D.new()
	ceil_mat.albedo_texture = _ceiling_texture()
	ceil_mat.uv1_triplanar = true
	ceil_mat.uv1_scale = Vector3(0.6, 0.6, 0.6)
	ceil_mat.texture_repeat = true
	ceil_mat.roughness = 0.9
	ceil_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_mats["ceiling"] = ceil_mat

	# --- walls: subtle plaster plus a faint vertical panel seam.
	_wall_mats[CREAM.to_html(false)] = _wall_material(CREAM)
	_wall_mats[BLUE.to_html(false)] = _wall_material(BLUE)
	_mats["dado"] = _wall_material(DADO)
	_mats["dado_blue"] = _wall_material(DADO_BLUE)

	# --- wood: desk, shelves, doors, frames.
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_texture = _wood_texture()
	wood_mat.uv1_triplanar = true
	wood_mat.uv1_scale = Vector3(0.7, 0.7, 0.7)
	wood_mat.texture_repeat = true
	wood_mat.roughness = 0.72
	wood_mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	_mats["wood"] = wood_mat

	# --- glass for the partition doors: thin, cool and slightly reflective.
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.62, 0.80, 0.90, 0.22)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.06
	glass.metallic = 0.3
	glass.metallic_specular = 0.85
	glass.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass.rim_enabled = true
	glass.rim = 0.65
	glass.rim_tint = 0.7
	glass.emission_enabled = true
	glass.emission = Color(0.30, 0.40, 0.50)
	glass.emission_energy_multiplier = 0.14
	_mats["glass"] = glass

	# --- frosted safety band across the glass.
	var frost := StandardMaterial3D.new()
	frost.albedo_color = Color(0.94, 0.97, 0.99, 0.55)
	frost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	frost.roughness = 0.55
	frost.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	frost.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mats["frost"] = frost


## A flat (but cached) material for small parts.
func _flat(color: Color, rough := 1.0, emis := 0.0) -> StandardMaterial3D:
	var key := "f|%s|%.2f|%.2f" % [color.to_html(false), rough, emis]
	if not _mats.has(key):
		_mats[key] = CampusBuilder.mat(color, rough, emis)
	return _mats[key] as StandardMaterial3D


## A glossy variant used for metal, glass and screens.
func _shiny(color: Color, rough := 0.3, metallic := 0.0, emis := 0.0) -> StandardMaterial3D:
	var key := "s|%s|%.2f|%.2f|%.2f" % [color.to_html(false), rough, metallic, emis]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = rough
		m.metallic = metallic
		m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
		if emis > 0.0:
			m.emission_enabled = true
			m.emission = color
			m.emission_energy_multiplier = emis
		_mats[key] = m
	return _mats[key] as StandardMaterial3D


## Typed access to one of the procedural materials built in _build_materials.
## Falls back to a plain material so the hall door can be built on its own.
func _mat(key: String) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key] as StandardMaterial3D
	return _flat(Color("#8a7355"), 0.8)


## Textured wall paint for a given colour.
func _wall_material(base: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _wall_texture(base)
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.5, 0.5, 0.5)
	m.texture_repeat = true
	m.roughness = 0.92
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


## Seamless value noise, used to break up the flat surfaces.
static func _noise(u: float, v: float) -> float:
	var n := sin(u * TAU * 3.0) * cos(v * TAU * 2.0) * 0.5
	n += sin(u * TAU * 7.0 + v * TAU * 3.0) * 0.28
	n += cos(v * TAU * 11.0 - u * TAU * 5.0) * 0.16
	return n


## Deterministic pseudo random in [0, 1).
static func _rand01(a: float) -> float:
	return fposmod(sin(a * 12.9898) * 43758.5453, 1.0)


## 4x4 ceramic tiles with grout lines and a little per-tile tone variation.
func _floor_texture() -> ImageTexture:
	var size := 256
	var cells := 4
	var cell := size / cells
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var u := float(x) / float(size)
			var v := float(y) / float(size)
			var tx := int(x / cell)
			var ty := int(y / cell)
			var px := x % cell
			var py := y % cell
			var tint := _rand01(float(tx) * 7.31 + float(ty) * 19.77) - 0.5
			var shade := 1.0 + tint * 0.09 + _noise(u, v) * 0.035
			var c := Color(TILE.r * shade, TILE.g * shade, TILE.b * shade)
			if px < 2 or py < 2 or px >= cell - 2 or py >= cell - 2:
				c = GRID
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Plaster with a faint vertical panel seam on every repeat.
func _wall_texture(base: Color) -> ImageTexture:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var u := float(x) / float(size)
			var v := float(y) / float(size)
			var shade := 1.0 + _noise(u, v) * 0.05
			var c := Color(base.r * shade, base.g * shade, base.b * shade)
			if x < 2 or x >= size - 2:
				c = c.darkened(0.12)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Suspended ceiling panels with recessed seams.
func _ceiling_texture() -> ImageTexture:
	var size := 128
	var cell := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var u := float(x) / float(size)
			var v := float(y) / float(size)
			var shade := 1.0 + _noise(u, v) * 0.035
			var c := Color(CEILING.r * shade, CEILING.g * shade, CEILING.b * shade)
			var px := x % cell
			var py := y % cell
			if px < 2 or py < 2 or px >= cell - 2 or py >= cell - 2:
				c = c.darkened(0.18)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Wood grain, running across the texture.
func _wood_texture() -> ImageTexture:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var u := float(x) / float(size)
			var v := float(y) / float(size)
			var grain := sin(v * TAU * 6.0 + _noise(u, v) * 2.6) * 0.5 + 0.5
			var shade := 0.88 + grain * 0.22 + _noise(u, v) * 0.06
			var c := Color(WOOD.r * shade, WOOD.g * shade, WOOD.b * shade)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ shell

func _build_shell() -> void:
	# base slab + tiled floor
	CampusBuilder.box(self, Vector3(HALF_W * 2.0 + 0.6, 0.3, HALF_D * 2.0 + 0.6),
		Vector3(0, -0.15, 0), _flat(Color("#9a7a56"), 0.9), "OfficeBase")
	CampusBuilder.box(self, Vector3(HALF_W * 2.0, 0.04, HALF_D * 2.0),
		Vector3(0, 0.02, 0), _mat("floor"), "OfficeFloor")
	CampusBuilder.box(self, Vector3(HALF_W * 2.0 + 0.6, 0.2, HALF_D * 2.0 + 0.6),
		Vector3(0, HEIGHT + 0.06, 0), _mat("ceiling"), "OfficeCeiling")

	# outer walls (south wall leaves the exit doorway open)
	_wall(-HALF_W - 0.24, HALF_W + 0.24, -HALF_D - 0.24, -HALF_D, BLUE, 0.0, HEIGHT, true, DADO_BLUE)
	_wall(-HALF_W - 0.24, -HALF_W, -HALF_D, HALF_D, CREAM)
	_wall(HALF_W, HALF_W + 0.24, -HALF_D, HALF_D, CREAM)
	_wall(-HALF_W - 0.24, DOOR_X0, HALF_D, HALF_D + 0.24, CREAM)
	_wall(DOOR_X1, HALF_W + 0.24, HALF_D, HALF_D + 0.24, CREAM)
	_wall(DOOR_X0, DOOR_X1, HALF_D, HALF_D + 0.24, CREAM, 2.4, HEIGHT, false)
	CampusBuilder.add_collider(self, Vector3(HALF_W * 2.0 + 0.6, 0.3, HALF_D * 2.0 + 0.6),
		Vector3(0, -0.25, 0), "OfficeFloorCol")

	# exit door frame, wooden door, handle and sign
	var center_x := (DOOR_X0 + DOOR_X1) * 0.5
	_frame(center_x, HALF_D + 0.08, 2.2, 2.4)
	CampusBuilder.box(self, Vector3(1.9, 2.25, 0.08), Vector3(center_x, 1.15, HALF_D + 0.02),
		_mat("wood"), "ExitDoor")
	# two recessed panels so the door is not a flat slab
	for py in [0.62, 1.68]:
		CampusBuilder.box(self, Vector3(1.5, 0.78, 0.03), Vector3(center_x, py, HALF_D - 0.035),
			_flat(WOOD_DARK, 0.7), "ExitDoorPanel")
	# brass kick plate
	CampusBuilder.box(self, Vector3(1.78, 0.22, 0.03), Vector3(center_x, 0.2, HALF_D - 0.035),
		_shiny(Color("#c8a24a"), 0.35, 0.7), "ExitKickPlate")
	CampusBuilder.add_collider(self, Vector3(1.9, 2.25, 0.12),
		Vector3(center_x, 0.0, HALF_D + 0.02), "ExitDoorCol")
	var knob := SphereMesh.new()
	knob.radius = 0.055
	knob.height = 0.11
	var kmi := MeshInstance3D.new()
	kmi.mesh = knob
	kmi.material_override = _shiny(Color("#d8b44a"), 0.25, 0.7)
	kmi.position = Vector3(center_x + 0.78, 1.05, HALF_D - 0.03)
	add_child(kmi)
	# door closer above the leaf
	CampusBuilder.box(self, Vector3(0.5, 0.08, 0.08), Vector3(center_x - 0.45, 2.36, HALF_D - 0.06),
		_shiny(METAL, 0.4, 0.6), "ExitDoorCloser")
	_sign("EXIT", "Back to the Admin hall", Vector3(center_x, 2.78, HALF_D - 0.06),
		PI, Vector2(1.5, 0.5), Color("#117a3a"), Color.WHITE)

	# door frames at the outer corners read as trim
	for x in [-HALF_W, HALF_W]:
		CampusBuilder.box(self, Vector3(0.16, HEIGHT, 0.16), Vector3(x, HEIGHT * 0.5, -HALF_D),
			_flat(TRIM, 0.7), "WallTrim")


func _build_partition() -> void:
	_wall(-HALF_W, -1.3, PARTITION_Z - 0.1, PARTITION_Z + 0.1, CREAM)
	_wall(1.3, HALF_W, PARTITION_Z - 0.1, PARTITION_Z + 0.1, CREAM)
	_wall(-1.3, 1.3, PARTITION_Z - 0.1, PARTITION_Z + 0.1, CREAM, 2.4, HEIGHT, false)
	_frame(0.0, PARTITION_Z, 2.6, 2.4)
	# red "busy" lamp removed: in the small waiting room it read as a floating
	# orange rectangle. The desk nameplate carries the office identity instead.

	# sliding glass doors in the partition opening
	_glass_left = _glass_pane(-0.65)
	_glass_right = _glass_pane(0.65)


func _glass_pane(side: float) -> Node3D:
	var root := Node3D.new()
	# The panes ride slightly in front of the opening so they slide past the
	# jambs instead of through them.
	root.position = Vector3(side, 0.0, PARTITION_Z + 0.17)
	add_child(root)
	CampusBuilder.box(root, Vector3(1.3, 2.3, 0.05), Vector3(0, 1.15, 0),
		_mat("glass"), "Glass")
	# frosted safety band, the classic office-glass detail
	CampusBuilder.box(root, Vector3(1.3, 0.34, 0.055), Vector3(0, 1.58, 0),
		_mat("frost"), "GlassFrost")
	var frame := _shiny(METAL, 0.35, 0.6)
	CampusBuilder.box(root, Vector3(1.36, 0.06, 0.08), Vector3(0, 2.33, 0), frame, "GlassFrame")
	CampusBuilder.box(root, Vector3(1.36, 0.06, 0.08), Vector3(0, 0.03, 0), frame, "GlassFrame")
	CampusBuilder.box(root, Vector3(0.07, 2.4, 0.08), Vector3(-0.66, 1.2, 0), frame, "GlassFrame")
	CampusBuilder.box(root, Vector3(0.07, 2.4, 0.08), Vector3(0.66, 1.2, 0), frame, "GlassFrame")
	# a slim pull handle on each leaf
	CampusBuilder.box(root, Vector3(0.05, 0.55, 0.05), Vector3(-0.56, 1.1, 0.07),
		_shiny(Color("#c8a24a"), 0.3, 0.7), "GlassHandle")
	CampusBuilder.box(root, Vector3(0.05, 0.55, 0.05), Vector3(0.56, 1.1, 0.07),
		_shiny(Color("#c8a24a"), 0.3, 0.7), "GlassHandle")
	# "PUSH" hint for the waiting-room side of the door
	_glass_label(root, "PUSH", Vector3(0, 1.0, 0.05), 0.0)
	return root


## Small label stuck on the glass (billboard off so it stays readable).
func _glass_label(parent: Node3D, text: String, pos: Vector3, yaw: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 34
	label.pixel_size = 0.0032
	label.modulate = Color("#f2f7fa")
	label.outline_size = 6
	label.outline_modulate = Color("#1d3557")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.width = 220.0
	label.position = pos
	label.rotation.y = yaw
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.double_sided = false
	parent.add_child(label)


# ------------------------------------------------------------------ rooms

func _build_waiting_room() -> void:
	# rug + coffee table
	CampusBuilder.box(self, Vector3(4.6, 0.03, 2.5), Vector3(-2.9, 0.04, 2.9),
		_flat(Color("#8c2f39"), 0.98), "WaitingRug")
	# a woven border so the rug is not one flat rectangle
	var border := _flat(Color("#d8b26a"), 0.9)
	for bz in [1.68, 4.12]:
		CampusBuilder.box(self, Vector3(4.5, 0.012, 0.09), Vector3(-2.9, 0.06, bz),
			border, "RugBorder")
	for bx in [-5.16, -0.64]:
		CampusBuilder.box(self, Vector3(0.09, 0.012, 2.4), Vector3(bx, 0.06, 2.9),
			border, "RugBorder")
	_coffee_table(Vector3(-3.1, 0.0, 2.9))

	# two sofas, arranged like the web waiting room
	_sofa(Vector3(-5.15, 0.0, 2.9), PI * 0.5)
	_sofa(Vector3(-2.6, 0.0, 4.42), 0.0)

	# plants in two corners and on the partition side
	_plant(Vector3(-5.4, 0.0, 4.5))
	_plant(Vector3(5.4, 0.0, 4.5))
	_plant(Vector3(-5.5, 0.0, -0.2))

	# water cooler, waste bin and a framed notice board dress the room
	_water_cooler(Vector3(-5.45, 0.0, 1.05))
	_bin(Vector3(0.85, 0.0, 4.5))
	_notice_board(Vector3(3.0, 1.85, PARTITION_Z + 0.15), 0.0, 1.5, 1.0)

	# wall clocks: one behind the desk, one in the waiting area
	_wall_clock(Vector3(-3.6, 2.55, -HALF_D + 0.03), 0.0)
	_wall_clock(Vector3(-HALF_W + 0.04, 2.4, 1.05), PI * 0.5)


## Low table with a lower shelf, a tray and magazines.
func _coffee_table(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	CampusBuilder.box(root, Vector3(1.1, 0.07, 0.6), Vector3(0, 0.4, 0),
		_mat("wood"), "CoffeeTableTop")
	CampusBuilder.box(root, Vector3(0.95, 0.04, 0.48), Vector3(0, 0.14, 0),
		_mat("wood"), "CoffeeTableShelf")
	for lx in [-0.48, 0.48]:
		for lz in [-0.24, 0.24]:
			CampusBuilder.box(root, Vector3(0.07, 0.4, 0.07), Vector3(lx, 0.2, lz),
				_flat(WOOD_DARK, 0.7), "CoffeeTableLeg")
	CampusBuilder.box(root, Vector3(0.4, 0.03, 0.3), Vector3(0.0, 0.45, 0.0),
		_flat(Color("#ffd54a"), 0.6), "Tray")
	CampusBuilder.box(root, Vector3(0.26, 0.18, 0.2), Vector3(0.24, 0.53, 0.0),
		_flat(Color("#f5f0e6"), 0.8), "Magazines")
	CampusBuilder.box(root, Vector3(0.23, 0.035, 0.17), Vector3(0.24, 0.63, 0.0),
		_flat(Color("#2e86c1"), 0.6), "Magazines")
	CampusBuilder.add_collider(self, Vector3(1.1, 0.45, 0.6), pos, "CoffeeTableCol")


## Bottle on top of a cabinet - the classic waiting-room water cooler.
func _water_cooler(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	CampusBuilder.box(root, Vector3(0.42, 0.95, 0.4), Vector3(0, 0.475, 0),
		_shiny(Color("#e6eaec"), 0.35, 0.05), "CoolerBody")
	CampusBuilder.box(root, Vector3(0.46, 0.06, 0.44), Vector3(0, 0.03, 0),
		_flat(METAL, 0.5), "CoolerBase")
	var bottle := CylinderMesh.new()
	bottle.top_radius = 0.2
	bottle.bottom_radius = 0.2
	bottle.height = 0.52
	bottle.radial_segments = 14
	var mi := MeshInstance3D.new()
	mi.mesh = bottle
	mi.material_override = _shiny(Color("#5fb7e8"), 0.12, 0.0, 0.3)
	mi.position = Vector3(0, 1.21, 0)
	root.add_child(mi)
	CampusBuilder.box(root, Vector3(0.09, 0.11, 0.09), Vector3(0, 0.76, 0.22),
		_shiny(Color("#2f7fbf"), 0.3, 0.3), "CoolerTap")
	CampusBuilder.box(root, Vector3(0.11, 0.15, 0.11), Vector3(0.21, 0.9, 0.0),
		_flat(Color("#f2f4f6"), 0.6), "CoolerCups")
	CampusBuilder.add_collider(self, Vector3(0.46, 1.5, 0.44), pos, "WaterCoolerCol")


## Cylindrical waste bin.
func _bin(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.2
	mesh.bottom_radius = 0.17
	mesh.height = 0.5
	mesh.radial_segments = 12
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _shiny(Color("#5d6770"), 0.4, 0.4)
	mi.position = Vector3(0, 0.25, 0)
	root.add_child(mi)
	var rim := CylinderMesh.new()
	rim.top_radius = 0.215
	rim.bottom_radius = 0.215
	rim.height = 0.04
	rim.radial_segments = 12
	var rmi := MeshInstance3D.new()
	rmi.mesh = rim
	rmi.material_override = _shiny(Color("#39424a"), 0.35, 0.5)
	rmi.position = Vector3(0, 0.51, 0)
	root.add_child(rmi)
	CampusBuilder.add_collider(self, Vector3(0.42, 0.5, 0.42), pos, "BinCol")


## Cork notice board with a wooden frame and a few pinned coloured sheets.
func _notice_board(pos: Vector3, yaw: float, w: float, h: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	CampusBuilder.box(root, Vector3(w, h, 0.05), Vector3.ZERO,
		_flat(Color("#8a6a44"), 0.98), "NoticeBoard")
	var frame := _flat(Color("#5d3f24"), 0.8)
	CampusBuilder.box(root, Vector3(w + 0.08, 0.06, 0.09), Vector3(0, h * 0.5 + 0.03, 0.01),
		frame, "NoticeFrame")
	CampusBuilder.box(root, Vector3(w + 0.08, 0.06, 0.09), Vector3(0, -h * 0.5 - 0.03, 0.01),
		frame, "NoticeFrame")
	CampusBuilder.box(root, Vector3(0.06, h, 0.09), Vector3(-w * 0.5 - 0.03, 0, 0.01),
		frame, "NoticeFrame")
	CampusBuilder.box(root, Vector3(0.06, h, 0.09), Vector3(w * 0.5 + 0.03, 0, 0.01),
		frame, "NoticeFrame")
	# pinned sheets
	var sheets := [
		[Vector3(-0.42, 0.24, 0.032), Vector2(0.3, 0.36), Color("#f4f1e8")],
		[Vector3(-0.05, 0.22, 0.034), Vector2(0.26, 0.32), Color("#d8e7f2")],
		[Vector3(0.32, 0.26, 0.032), Vector2(0.28, 0.34), Color("#f7e6c8")],
		[Vector3(-0.34, -0.24, 0.034), Vector2(0.32, 0.3), Color("#e8f0dc")],
		[Vector3(0.06, -0.22, 0.032), Vector2(0.3, 0.36), Color("#f2dcdc")],
		[Vector3(0.42, -0.26, 0.034), Vector2(0.22, 0.28), Color("#e2e6f4")],
	]
	for s in sheets:
		var at: Vector3 = s[0]
		var sz: Vector2 = s[1]
		var col: Color = s[2]
		CampusBuilder.box(root, Vector3(sz.x, sz.y, 0.012), at,
			_flat(col, 0.95), "NoticePaper")
		# a coloured pin
		CampusBuilder.box(root, Vector3(0.05, 0.05, 0.02), at + Vector3(0, sz.y * 0.42, 0.01),
			_flat(Color("#c0392b"), 0.5), "NoticePin")


## Wall clock with a face, ticks and two hands.
func _wall_clock(pos: Vector3, yaw: float) -> void:
	var clock := Node3D.new()
	clock.position = pos
	clock.rotation.y = yaw
	add_child(clock)
	var face := CylinderMesh.new()
	face.top_radius = 0.28
	face.bottom_radius = 0.28
	face.height = 0.05
	face.radial_segments = 20
	var face_mi := MeshInstance3D.new()
	face_mi.mesh = face
	face_mi.rotation.x = PI * 0.5
	face_mi.material_override = _flat(Color("#fbfbf7"), 0.7)
	clock.add_child(face_mi)
	# rim so the clock reads as an object, not a disc
	var rim := CylinderMesh.new()
	rim.top_radius = 0.31
	rim.bottom_radius = 0.31
	rim.height = 0.04
	rim.radial_segments = 20
	var rim_mi := MeshInstance3D.new()
	rim_mi.mesh = rim
	rim_mi.rotation.x = PI * 0.5
	rim_mi.position = Vector3(0, 0, -0.01)
	rim_mi.material_override = _shiny(Color("#3a3f45"), 0.4, 0.5)
	clock.add_child(rim_mi)
	for angle in [0.0, 1.5708, 3.14159, 4.71239]:
		var tick := CampusBuilder.box(clock, Vector3(0.025, 0.06, 0.02),
			Vector3(cos(angle) * 0.22, sin(angle) * 0.22, 0.04),
			_flat(Color("#2b2b2b")), "ClockTick")
		tick.rotation.z = angle
	CampusBuilder.box(clock, Vector3(0.02, 0.15, 0.02), Vector3(0, 0.055, 0.05),
		_flat(Color("#2b2b2b")), "ClockHand")
	CampusBuilder.box(clock, Vector3(0.12, 0.02, 0.02), Vector3(0.045, -0.02, 0.05),
		_flat(Color("#2b2b2b")), "ClockHand")
	CampusBuilder.box(clock, Vector3(0.05, 0.05, 0.03), Vector3(0, 0, 0.055),
		_flat(Color("#c0392b"), 0.5), "ClockHub")


func _build_office_side() -> void:
	# Laksmi's desk, facing the glass doors
	var desk := Node3D.new()
	desk.position = DESK_LOCAL
	add_child(desk)
	CampusBuilder.box(desk, Vector3(2.3, 0.08, 1.0), Vector3(0, 0.76, 0),
		_mat("wood"), "DeskTop")
	# a darker apron under the top edge
	CampusBuilder.box(desk, Vector3(2.34, 0.06, 1.04), Vector3(0, 0.70, 0),
		_flat(WOOD_DARK, 0.7), "DeskApron")
	CampusBuilder.box(desk, Vector3(2.3, 0.72, 0.08), Vector3(0, 0.38, 0.46),
		_flat(Color("#5a3d24"), 0.8), "DeskFront")
	for x in [-1.06, 1.06]:
		CampusBuilder.box(desk, Vector3(0.12, 0.72, 0.92), Vector3(x, 0.38, 0),
			_flat(Color("#5a3d24"), 0.8), "DeskSide")
	# vertical grooves + a kick plate so the desk front is not a flat panel
	for gx in [-0.72, 0.0, 0.72]:
		CampusBuilder.box(desk, Vector3(0.04, 0.5, 0.02), Vector3(gx, 0.4, 0.505),
			_flat(Color("#4a3120"), 0.8), "DeskGroove")
	CampusBuilder.box(desk, Vector3(2.24, 0.1, 0.02), Vector3(0, 0.07, 0.505),
		_shiny(Color("#8d9299"), 0.45, 0.5), "DeskKickPlate")
	# the brass "RECEPTION" plate on the visitor side of the desk
	_plate(desk, "RECEPTION", Vector3(0, 0.52, 0.505), Vector3(1.05, 0.2, 0.03),
		NAVY, GOLD, 0.0035)
	CampusBuilder.add_collider(self, Vector3(2.3, 1.0, 1.0), DESK_LOCAL, "DeskCol")

	# monitor, stand, keyboard and mouse on Laksmi's side
	CampusBuilder.box(desk, Vector3(0.32, 0.03, 0.24), Vector3(-0.45, 0.815, -0.16),
		_flat(Color("#20242a"), 0.5), "MonitorFoot")
	CampusBuilder.box(desk, Vector3(0.08, 0.24, 0.07), Vector3(-0.45, 0.93, -0.16),
		_flat(Color("#20242a"), 0.5), "MonitorStem")
	CampusBuilder.box(desk, Vector3(0.72, 0.44, 0.05), Vector3(-0.45, 1.25, -0.16),
		_shiny(Color("#161a1f"), 0.35, 0.1), "Monitor")
	CampusBuilder.box(desk, Vector3(0.62, 0.34, 0.02), Vector3(-0.45, 1.25, -0.185),
		_shiny(Color("#3d7fb5"), 0.2, 0.0, 0.95), "MonitorScreen")
	CampusBuilder.box(desk, Vector3(0.44, 0.025, 0.16), Vector3(-0.45, 0.815, -0.38),
		_flat(Color("#2b3038"), 0.6), "Keyboard")
	CampusBuilder.box(desk, Vector3(0.08, 0.05, 0.12), Vector3(-0.11, 0.83, -0.38),
		_flat(Color("#2b3038"), 0.5), "Mouse")

	# a guest-facing queue screen on the visitor side
	CampusBuilder.box(desk, Vector3(0.14, 0.04, 0.12), Vector3(-0.62, 0.82, 0.3),
		_flat(Color("#20242a"), 0.5), "QueueScreenFoot")
	CampusBuilder.box(desk, Vector3(0.36, 0.24, 0.03), Vector3(-0.62, 0.95, 0.3),
		_shiny(Color("#1a1f26"), 0.3, 0.1), "QueueScreen")
	CampusBuilder.box(desk, Vector3(0.3, 0.18, 0.015), Vector3(-0.62, 0.95, 0.318),
		_shiny(Color("#48c7b8"), 0.2, 0.0, 0.8), "QueueScreenGlow")

	# papers, files, pen cup, mug and the table lamp
	CampusBuilder.box(desk, Vector3(0.6, 0.05, 0.42), Vector3(0.42, 0.82, 0.02),
		_flat(Color("#f5f2ea"), 0.9), "Papers")
	CampusBuilder.box(desk, Vector3(0.56, 0.04, 0.38), Vector3(0.4, 0.87, 0.0),
		_flat(Color("#e8e3d6"), 0.9), "Papers")
	var folder_colors := [Color("#c0392b"), Color("#1f6f8b"), Color("#27ae60")]
	for i in 3:
		CampusBuilder.box(desk, Vector3(0.3, 0.05, 0.38),
			Vector3(-0.02 + i * 0.03, 0.85 + i * 0.055, -0.16),
			_flat(folder_colors[i], 0.85), "Folder")
	CampusBuilder.box(desk, Vector3(0.11, 0.14, 0.11), Vector3(-0.92, 0.87, 0.28),
		_flat(Color("#3f6f8f"), 0.7), "PenCup")
	for i in 3:
		CampusBuilder.box(desk, Vector3(0.02, 0.16, 0.02),
			Vector3(-0.94 + i * 0.02, 0.99, 0.28 + i * 0.015),
			_flat(Color("#2b2b2b"), 0.6), "Pen")
	CampusBuilder.box(desk, Vector3(0.1, 0.12, 0.1), Vector3(0.16, 0.86, -0.3),
		_flat(Color("#f4f1e8"), 0.7), "Mug")
	_table_lamp(desk, Vector3(0.95, 0.8, -0.1))

	# the name plate on the visitor side of the desk
	_plate(desk, "MS. LAKSMI", Vector3(0.58, 0.87, 0.3), Vector3(0.54, 0.13, 0.14),
		NAVY, GOLD, 0.0022)

	# office chair behind the desk and two visitor chairs in front
	_office_chair(Vector3(0.43, 0.0, -3.5), 0.0, Color("#1d3557"))
	_office_chair(Vector3(-0.7, 0.0, -1.15), PI, SOFA_LIGHT)
	_office_chair(Vector3(0.7, 0.0, -1.15), PI, SOFA_LIGHT)

	# a small rug under the desk area
	CampusBuilder.box(self, Vector3(3.4, 0.02, 2.0), Vector3(0.0, 0.035, -3.1),
		_flat(Color("#3d4a5c"), 0.98), "OfficeRug")

	# bookshelves along the north wall
	for lx in [-4.4, -3.15, 3.25, 4.5]:
		_shelf(Vector3(lx, 0.0, -HALF_D + 0.3))

	# filing cabinet and wall poster
	CampusBuilder.box(self, Vector3(0.7, 1.2, 0.5), Vector3(-5.6, 0.6, -HALF_D + 0.3),
		_flat(Color("#7d8791"), 0.7), "FilingCabinet")
	# drawer lines + handles
	for i in 3:
		CampusBuilder.box(self, Vector3(0.62, 0.02, 0.02),
			Vector3(-5.6, 0.26 + i * 0.36, -HALF_D + 0.55), _flat(Color("#5f686f"), 0.7),
			"CabinetDrawer")
		CampusBuilder.box(self, Vector3(0.22, 0.04, 0.04),
			Vector3(-5.6, 0.4 + i * 0.36, -HALF_D + 0.57), _shiny(Color("#9aa3ab"), 0.4, 0.6),
			"CabinetHandle")
	CampusBuilder.add_collider(self, Vector3(0.7, 1.2, 0.5),
		Vector3(-5.6, 0.0, -HALF_D + 0.3), "FilingCabinetCol")

	# poster on the north wall, to the right of the desk (clear of the shelves)
	CampusBuilder.box(self, Vector3(1.9, 1.1, 0.04), Vector3(1.7, 2.2, -HALF_D + 0.03),
		_flat(NAVY, 0.6), "Poster")
	_label_on_wall("ANITS\nADMIN", Vector3(1.7, 2.2, -HALF_D + 0.07), 0.0,
		Vector2(1.7, 0.9), Color("#ffd54a"), Color("#1d3557"))
	# a slim frame around the poster
	for fx in [0.73, 2.67]:
		CampusBuilder.box(self, Vector3(0.05, 1.16, 0.06), Vector3(fx, 2.2, -HALF_D + 0.03),
			_flat(Color("#c8a24a"), 0.5), "PosterFrame")
	for fy in [1.63, 2.77]:
		CampusBuilder.box(self, Vector3(1.99, 0.05, 0.06), Vector3(1.7, fy, -HALF_D + 0.03),
			_flat(Color("#c8a24a"), 0.5), "PosterFrame")


## Small desk lamp with a warm glowing shade.
func _table_lamp(desk: Node3D, pos: Vector3) -> void:
	var base := CylinderMesh.new()
	base.top_radius = 0.11
	base.bottom_radius = 0.12
	base.height = 0.035
	base.radial_segments = 12
	var bmi := MeshInstance3D.new()
	bmi.mesh = base
	bmi.material_override = _shiny(METAL, 0.35, 0.6)
	bmi.position = pos + Vector3(0, 0.017, 0)
	desk.add_child(bmi)
	var stem := CylinderMesh.new()
	stem.top_radius = 0.022
	stem.bottom_radius = 0.022
	stem.height = 0.3
	stem.radial_segments = 8
	var smi := MeshInstance3D.new()
	smi.mesh = stem
	smi.material_override = _shiny(METAL, 0.35, 0.6)
	smi.position = pos + Vector3(0, 0.18, 0)
	desk.add_child(smi)
	var shade := CylinderMesh.new()
	shade.top_radius = 0.14
	shade.bottom_radius = 0.17
	shade.height = 0.2
	shade.radial_segments = 14
	var shmi := MeshInstance3D.new()
	shmi.mesh = shade
	shmi.material_override = _shiny(WARM, 0.4, 0.0, 1.6)
	shmi.position = pos + Vector3(0, 0.41, 0)
	desk.add_child(shmi)


func _build_restroom() -> void:
	# cubicle in the south-east corner
	_wall(3.9, 4.05, PARTITION_Z + 0.1, 1.5, CREAM)
	_wall(3.9, 4.05, 2.7, 3.3, CREAM)
	_wall(3.9, HALF_W, 3.2, 3.35, CREAM)
	_wall(3.9, 4.05, 1.5, 2.7, CREAM, 2.3, HEIGHT, false)
	_sign("RESTROOM", "WC", Vector3(3.84, 2.65, 2.1), -PI * 0.5,
		Vector2(1.3, 0.46), Color("#1f6f8b"), Color.WHITE)

	# the cubicle door: frame, leaf standing open against the wall. It carries
	# no collider, so the room stays exactly as navigable as before.
	CampusBuilder.box(self, Vector3(0.2, 2.3, 0.1), Vector3(3.95, 1.15, 1.48),
		_flat(TRIM, 0.7), "RestroomDoorFrame")
	CampusBuilder.box(self, Vector3(0.2, 2.3, 0.1), Vector3(3.95, 1.15, 2.72),
		_flat(TRIM, 0.7), "RestroomDoorFrame")
	CampusBuilder.box(self, Vector3(0.2, 0.12, 1.34), Vector3(3.95, 2.29, 2.1),
		_flat(TRIM, 0.7), "RestroomDoorFrame")
	var leaf := Node3D.new()
	# Hinged at the near jamb and swung ~75 degrees open into the cubicle, so
	# the leaf stands clear of the doorway instead of covering it.
	leaf.position = Vector3(3.97, 0.0, 1.52)
	leaf.rotation.y = -0.2618
	add_child(leaf)
	CampusBuilder.box(leaf, Vector3(1.2, 2.2, 0.06), Vector3(0.6, 1.1, 0),
		_mat("wood"), "RestroomDoor")
	CampusBuilder.box(leaf, Vector3(0.9, 0.7, 0.02), Vector3(0.6, 1.6, 0.04),
		_flat(Color("#5a3d24"), 0.8), "RestroomDoorPanel")
	CampusBuilder.box(leaf, Vector3(0.9, 0.7, 0.02), Vector3(0.6, 0.6, 0.04),
		_flat(Color("#5a3d24"), 0.8), "RestroomDoorPanel")
	var handle := SphereMesh.new()
	handle.radius = 0.05
	handle.height = 0.1
	var hmi := MeshInstance3D.new()
	hmi.mesh = handle
	hmi.material_override = _shiny(Color("#c8a24a"), 0.3, 0.7)
	hmi.position = Vector3(0.15, 1.02, 0.08)
	leaf.add_child(hmi)

	# floor tile inside the cubicle
	CampusBuilder.box(self, Vector3(1.96, 0.01, 2.5), Vector3(4.95, 0.045, 1.9),
		_mat("floor"), "RestroomFloor")

	# a stall partition inside so the cubicle reads as a restroom
	CampusBuilder.box(self, Vector3(1.0, 1.9, 0.08), Vector3(4.95, 0.95, 0.72),
		_flat(Color("#dbe4e8"), 0.85), "RestroomPartition")
	CampusBuilder.box(self, Vector3(1.05, 0.08, 0.13), Vector3(4.95, 1.9, 0.72),
		_flat(METAL, 0.5), "RestroomPartitionRail")

	# toilet (low-poly: cistern + bowl + seat)
	var toilet := Node3D.new()
	toilet.position = Vector3(HALF_W - 0.2, 0.0, 1.95)
	add_child(toilet)
	var white := _flat(Color("#f7f9fa"), 0.5)
	CampusBuilder.box(toilet, Vector3(0.42, 0.62, 0.2), Vector3(-0.06, 0.62, 0.28), white, "Cistern")
	CampusBuilder.box(toilet, Vector3(0.38, 0.3, 0.5), Vector3(0, 0.28, 0.02), white, "Bowl")
	var seat := CylinderMesh.new()
	seat.top_radius = 0.23
	seat.bottom_radius = 0.23
	seat.height = 0.07
	seat.radial_segments = 14
	var seat_mi := MeshInstance3D.new()
	seat_mi.mesh = seat
	seat_mi.material_override = white
	seat_mi.position = Vector3(0, 0.46, 0.02)
	toilet.add_child(seat_mi)
	# flush button and a small cistern lid
	CampusBuilder.box(toilet, Vector3(0.1, 0.04, 0.04), Vector3(-0.06, 0.93, 0.24),
		_shiny(Color("#9aa3ab"), 0.35, 0.6), "FlushButton")
	CampusBuilder.add_collider(self, Vector3(0.7, 0.8, 0.6),
		Vector3(HALF_W - 0.3, 0.0, 1.95), "ToiletCol")

	# small hand basin and mirror on the east wall
	CampusBuilder.box(self, Vector3(0.42, 0.16, 0.5), Vector3(5.72, 0.85, 0.75),
		_flat(Color("#eef2f4"), 0.4), "Basin")
	CampusBuilder.box(self, Vector3(0.06, 0.78, 0.06), Vector3(5.82, 0.45, 0.75),
		_shiny(Color("#9aa3ab"), 0.35, 0.6), "BasinLeg")
	CampusBuilder.box(self, Vector3(0.04, 0.6, 0.5), Vector3(5.97, 1.5, 0.75),
		_shiny(Color("#cfe3ee"), 0.08, 0.6), "Mirror")


func _build_signs() -> void:
	# Waiting-room sign on the west wall, not in the doorway sightline.
	_sign("WAITING AREA", "Please take a seat", Vector3(-HALF_W + 0.04, 2.42, 2.8), PI * 0.5,
		Vector2(2.0, 0.44), Color("#7a1f2b"), Color.WHITE)
	# "RECEPTION" over the desk, on the north wall.
	_sign("RECEPTION", "", Vector3(-1.7, 2.15, -HALF_D + 0.05), 0.0,
		Vector2(1.3, 0.38), Color("#1f6f8b"), Color.WHITE)
	# One clean line above the glass doors (the desk has its own nameplate).
	# Two plates, one per side, so the sign reads from the waiting room *and*
	# from inside the office.
	_sign("ADMIN OFFICE", "", Vector3(0, 3.02, PARTITION_Z + 0.15),
		0.0, Vector2(2.5, 0.42), Color("#1d3557"), Color("#ffd54a"))
	_sign("ADMIN OFFICE", "", Vector3(0, 3.02, PARTITION_Z - 0.15),
		PI, Vector2(2.5, 0.42), Color("#1d3557"), Color("#ffd54a"))


func _build_lights() -> void:
	# Ceiling fixtures: a housing, a warm emissive diffuser and metal end caps.
	_ceiling_lamp(Vector3(-3.0, HEIGHT - 0.01, 3.0), 1.6)
	_ceiling_lamp(Vector3(3.0, HEIGHT - 0.01, 3.0), 1.6)
	_ceiling_lamp(Vector3(-3.0, HEIGHT - 0.01, -2.0), 1.6)
	_ceiling_lamp(Vector3(3.0, HEIGHT - 0.01, -2.0), 1.6)
	_ceiling_lamp(Vector3(0.0, HEIGHT - 0.01, -3.0), 1.4)
	# a frosted skylight strip over the waiting area
	_skylight(Vector3(-1.5, HEIGHT - 0.02, 1.9), Vector3(4.0, 0.7, 0.0))

	# Six warm omni lights is the mobile budget for this room.
	var lights := [
		# pos, colour, energy, range, shadow
		[Vector3(-3.2, 3.15, 2.6), Color("#ffe2b4"), 1.6, 8.5, true],
		[Vector3(2.4, 3.15, 3.0), Color("#ffe2b4"), 1.35, 8.0, false],
		[Vector3(-2.4, 3.15, -2.6), Color("#ffdca8"), 1.45, 8.0, false],
		[Vector3(2.2, 3.15, -2.4), Color("#ffdca8"), 1.35, 8.0, false],
		[Vector3(0.0, 2.55, -2.3), Color("#ffe8c4"), 1.1, 4.6, true],
		[Vector3(5.0, 2.7, 1.9), Color("#fff0d0"), 0.9, 3.6, false],
	]
	var count := 0
	for spec in lights:
		if count >= MAX_LIGHTS:
			break
		count += 1
		var light := OmniLight3D.new()
		light.position = spec[0]
		light.light_color = spec[1]
		light.light_energy = spec[2]
		light.omni_range = spec[3]
		light.shadow_enabled = spec[4]
		light.light_specular = 0.4
		add_child(light)


## Suspended ceiling lamp: housing + emissive diffuser + end caps.
func _ceiling_lamp(pos: Vector3, length: float) -> void:
	CampusBuilder.box(self, Vector3(length + 0.14, 0.12, 0.66), pos + Vector3(0, 0.06, 0),
		_flat(Color("#f2f4f3"), 0.8), "LampHousing")
	CampusBuilder.box(self, Vector3(length, 0.05, 0.5), pos,
		_shiny(WARM, 0.4, 0.0, 1.35), "LampDiffuser")
	for sx in [-1.0, 1.0]:
		CampusBuilder.box(self, Vector3(0.06, 0.14, 0.66),
			pos + Vector3(sx * (length * 0.5 + 0.04), 0.06, 0),
			_shiny(METAL, 0.35, 0.6), "LampEnd")
	# a thin suspension rod
	CampusBuilder.box(self, Vector3(0.04, 0.12, 0.04), pos + Vector3(0, 0.11, 0),
		_shiny(METAL, 0.4, 0.6), "LampRod")


## Frosted daylight panel let into the ceiling.
func _skylight(pos: Vector3, size: Vector3) -> void:
	CampusBuilder.box(self, Vector3(size.x + 0.16, 0.08, size.z + 0.16),
		pos + Vector3(0, 0.04, 0), _flat(Color("#dfe7ee"), 0.7), "SkylightFrame")
	CampusBuilder.box(self, Vector3(size.x, 0.05, size.z), pos,
		_shiny(Color("#eaf4ff"), 0.25, 0.0, 1.5), "SkylightPanel")


# ------------------------------------------------------------------ hall door

## Builds the "ADMIN OFFICE" door in the Admin Block hallway and the interact
## target that teleports the player into this room.
func build_hall_door(admin_centre: Vector3, k: float) -> void:
	var local_x := -4.88 * k + 0.55
	hall_door_pos = admin_centre + Vector3(local_x, 0.0, 7.0 * k)
	hall_return_pos = admin_centre + Vector3(-4.88 * k + 1.7, 0.12, 7.0 * k)
	var root := Node3D.new()
	root.name = "AdminOfficeDoor"
	root.position = hall_door_pos - position
	add_child(root)

	CampusBuilder.box(root, Vector3(0.1, 2.2, 1.15), Vector3(0, 1.1, 0),
		_mat("wood"), "DoorPanel")
	# a raised panel detail on the hallway door
	CampusBuilder.box(root, Vector3(0.02, 1.5, 0.8), Vector3(-0.055, 1.2, 0),
		_flat(Color("#5a3d24"), 0.8), "DoorPanelDetail")
	var frame := _flat(Color("#3e2410"), 0.8)
	CampusBuilder.box(root, Vector3(0.14, 2.3, 0.1), Vector3(0, 1.15, -0.62), frame, "DoorFrame")
	CampusBuilder.box(root, Vector3(0.14, 2.3, 0.1), Vector3(0, 1.15, 0.62), frame, "DoorFrame")
	CampusBuilder.box(root, Vector3(0.14, 0.12, 1.34), Vector3(0, 2.28, 0), frame, "DoorFrame")
	var knob := SphereMesh.new()
	knob.radius = 0.055
	knob.height = 0.11
	var kmi := MeshInstance3D.new()
	kmi.mesh = knob
	kmi.material_override = _shiny(Color("#d8b44a"), 0.25, 0.7)
	kmi.position = Vector3(0.09, 1.05, 0.42)
	root.add_child(kmi)
	_sign("ADMIN OFFICE", "Waiting room", Vector3(0.0, 2.78, 0.0), PI * 0.5,
		Vector2(1.9, 0.55), Color("#1d3557"), Color("#ffd54a"), root)

	# the interact prompt rides on an invisible node just inside the hallway
	_door_node = Node3D.new()
	_door_node.name = "AdminOfficeHallDoor"
	_door_node.position = hall_door_pos - position + Vector3(0.55, 0, 0)
	_door_node.add_to_group("interactables")
	_door_node.add_to_group("admin_office_door")
	add_child(_door_node)

	# Additional entrance trigger on the front south porch of Admin Block
	var porch_door := Node3D.new()
	porch_door.name = "AdminOfficePorchDoor"
	porch_door.position = admin_centre - position + Vector3(0.0, 0.0, 13.0 * k)
	porch_door.add_to_group("interactables")
	porch_door.add_to_group("admin_office_door")
	add_child(porch_door)


# ------------------------------------------------------------------ animation

func _process(delta: float) -> void:
	_t += delta
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var want_open := false
	if player:
		want_open = player.global_position.distance_to(to_global(Vector3(0, 0, PARTITION_Z))) < 3.0
	_glass_open = move_toward(_glass_open, 1.0 if want_open else 0.0, delta * 3.2)
	var side := lerpf(0.65, 1.42, _glass_open)
	if _glass_left:
		_glass_left.position.x = -side
	if _glass_right:
		_glass_right.position.x = side


# ------------------------------------------------------------------ helpers

## A wall segment between two X/Z bounds.
##
## The wall is split into a painted wainscot band (up to DADO_TOP), a wooden
## dado rail and a skirting board, plus a textured plaster band above. The
## collider is byte-for-byte the same as before, so the room stays sealed.
func _wall(x0: float, x1: float, z0: float, z1: float, color: Color,
		y0 := 0.0, y1 := HEIGHT, collide := true, dado_color := DADO) -> void:
	var size := Vector3(x1 - x0, y1 - y0, z1 - z0)
	var centre := Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5)
	if y0 < DADO_TOP - 0.01:
		var band_top := minf(DADO_TOP, y1)
		var dado_mat := _mat("dado")
		if dado_color != DADO:
			dado_mat = _mat("dado_blue")
		CampusBuilder.box(self, Vector3(size.x, band_top - y0, size.z),
			Vector3(centre.x, (y0 + band_top) * 0.5, centre.z),
			dado_mat, "OfficeDado")
		var upper_mat: StandardMaterial3D = _wall_mats.get(color.to_html(false), null) as StandardMaterial3D
		if upper_mat == null:
			upper_mat = _flat(color)
		CampusBuilder.box(self, Vector3(size.x, y1 - band_top, size.z),
			Vector3(centre.x, (band_top + y1) * 0.5, centre.z),
			upper_mat, "OfficeWall")
		# wooden rail on top of the wainscot and a skirting at the floor
		_trim_strip(Vector3(size.x, 0.09, size.z), Vector3(centre.x, band_top + 0.045, centre.z),
			0.07, _flat(TRIM, 0.7))
		_trim_strip(Vector3(size.x, 0.13, size.z), Vector3(centre.x, y0 + 0.065, centre.z),
			0.06, _flat(WOOD_DARK, 0.8))
	else:
		var plain_mat: StandardMaterial3D = _wall_mats.get(color.to_html(false), null) as StandardMaterial3D
		if plain_mat == null:
			plain_mat = _flat(color)
		CampusBuilder.box(self, size, centre, plain_mat, "OfficeWall")
	if collide:
		CampusBuilder.add_collider(self, size, Vector3(centre.x, y0, centre.z), "OfficeWallCol")


## A thin strip laid along a wall face: the dado rail and the skirting board.
## It is pushed slightly proud of the wall on both sides so it reads as trim
## without changing the wall footprint (and therefore without touching the
## colliders).
func _trim_strip(size: Vector3, centre: Vector3, proud: float, material: Material) -> void:
	var s := size
	var p := centre
	if size.x < size.z:
		s.x += proud
	else:
		s.z += proud
	CampusBuilder.box(self, s, p, material, "WallTrim")


## Door frame: two jambs and a lintel, with a lighter inner reveal.
func _frame(center_x: float, z: float, width: float, height: float) -> void:
	var frame := _flat(TRIM, 0.8)
	CampusBuilder.box(self, Vector3(0.12, height, 0.25), Vector3(center_x - width * 0.5, height * 0.5, z), frame, "DoorFrame")
	CampusBuilder.box(self, Vector3(0.12, height, 0.25), Vector3(center_x + width * 0.5, height * 0.5, z), frame, "DoorFrame")
	CampusBuilder.box(self, Vector3(width + 0.12, 0.12, 0.25), Vector3(center_x, height, z), frame, "DoorFrame")
	# a slim brass threshold strip at the bottom of the opening
	CampusBuilder.box(self, Vector3(width, 0.03, 0.26), Vector3(center_x, 0.015, z),
		_shiny(Color("#a58a52"), 0.4, 0.6), "DoorThreshold")


## Waiting-room sofa. The collider is unchanged so the layout still behaves
## exactly like the web build.
func _sofa(pos: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	var body := _flat(SOFA, 0.95)
	var cushion := _flat(SOFA_LIGHT, 0.95)
	CampusBuilder.box(root, Vector3(2.5, 0.34, 0.9), Vector3(0, 0.28, 0), body, "SofaBase")
	CampusBuilder.box(root, Vector3(2.5, 0.62, 0.22), Vector3(0, 0.68, -0.34), body, "SofaBack")
	for x in [-1.14, 1.14]:
		CampusBuilder.box(root, Vector3(0.22, 0.52, 0.9), Vector3(x, 0.54, 0), body, "SofaArm")
	for x in [-0.58, 0.58]:
		CampusBuilder.box(root, Vector3(1.1, 0.16, 0.72), Vector3(x, 0.5, 0.03), cushion, "SofaCushion")
		CampusBuilder.box(root, Vector3(1.1, 0.46, 0.14), Vector3(x, 0.77, -0.29), cushion, "SofaCushion")
	# accent throw pillows
	CampusBuilder.box(root, Vector3(0.42, 0.1, 0.42), Vector3(-0.86, 0.62, -0.16),
		_flat(Color("#c9a227"), 0.95), "ThrowPillow")
	CampusBuilder.box(root, Vector3(0.38, 0.1, 0.38), Vector3(0.82, 0.62, -0.14),
		_flat(Color("#8c2f39"), 0.95), "ThrowPillow")
	# a folded blanket over one arm
	CampusBuilder.box(root, Vector3(0.36, 0.08, 0.62), Vector3(-1.14, 0.82, 0.06),
		_flat(Color("#3f6f8f"), 0.95), "Blanket")
	CampusBuilder.add_collider(root, Vector3(2.5, 0.9, 0.95), Vector3.ZERO, "SofaCol")


func _office_chair(pos: Vector3, yaw: float, color: Color) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	var m := _flat(color, 0.9)
	for x in [-0.22, 0.22]:
		for z in [-0.22, 0.22]:
			CampusBuilder.box(root, Vector3(0.05, 0.44, 0.05), Vector3(x, 0.22, z),
				_shiny(METAL, 0.5, 0.4), "ChairLeg")
	CampusBuilder.box(root, Vector3(0.54, 0.08, 0.54), Vector3(0, 0.47, 0), m, "ChairSeat")
	# a slightly lighter seat cushion and a head rest
	CampusBuilder.box(root, Vector3(0.48, 0.06, 0.48), Vector3(0, 0.53, 0),
		_flat(color.lightened(0.12), 0.95), "ChairCushion")
	CampusBuilder.box(root, Vector3(0.54, 0.52, 0.07), Vector3(0, 0.76, -0.24), m, "ChairBack")
	CampusBuilder.box(root, Vector3(0.4, 0.14, 0.08), Vector3(0, 1.09, -0.24),
		_flat(color.lightened(0.12), 0.95), "ChairHeadRest")


func _shelf(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	CampusBuilder.box(root, Vector3(1.1, 2.2, 0.45), Vector3(0, 1.1, 0),
		_mat("wood"), "Shelf")
	# side panels and a crown so it is not a single slab
	for x in [-0.52, 0.52]:
		CampusBuilder.box(root, Vector3(0.06, 2.2, 0.47), Vector3(x, 1.1, 0.02),
			_flat(WOOD_DARK, 0.75), "ShelfSide")
	CampusBuilder.box(root, Vector3(1.18, 0.1, 0.5), Vector3(0, 2.23, 0.01),
		_flat(WOOD_DARK, 0.75), "ShelfCrown")
	for row in 4:
		CampusBuilder.box(root, Vector3(1.02, 0.04, 0.4), Vector3(0, 0.16 + row * 0.5, 0.02),
			_flat(WOOD_DARK, 0.75), "ShelfBoard")
		var book_colors := [Color("#c0392b"), Color("#2e86c1"), Color("#27ae60"),
			Color("#f1c40f"), Color("#8e44ad")]
		for k in 7:
			if (row * 7 + k) % 5 == 0:
				continue
			CampusBuilder.box(root, Vector3(0.1, 0.34, 0.3),
				Vector3(-0.42 + k * 0.14, 0.35 + row * 0.5, 0.2),
				_flat(book_colors[(row + k) % 5], 0.9), "Book")
	CampusBuilder.add_collider(self, Vector3(1.1, 2.2, 0.45), pos, "ShelfCol")


func _plant(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	CampusBuilder.box(root, Vector3(0.45, 0.4, 0.45), Vector3(0, 0.2, 0),
		_flat(Color("#b85c38"), 0.9), "PlantPot")
	CampusBuilder.box(root, Vector3(0.52, 0.06, 0.52), Vector3(0, 0.42, 0),
		_flat(Color("#8f4527"), 0.9), "PlantPotRim")
	CampusBuilder.box(root, Vector3(0.36, 0.05, 0.36), Vector3(0, 0.43, 0),
		_flat(Color("#4a3a26"), 0.95), "PlantSoil")
	var leaf := _flat(Color("#2f7a38"), 0.95)
	for i in 3:
		var sphere := SphereMesh.new()
		sphere.radius = 0.34 - i * 0.05
		sphere.height = 0.8 - i * 0.12
		var mi := MeshInstance3D.new()
		mi.mesh = sphere
		mi.material_override = leaf
		mi.position = Vector3(cos(i * 2.1) * 0.16, 0.75 + i * 0.16, sin(i * 2.1) * 0.16)
		mi.scale = Vector3(1.0, 1.25, 1.0)
		root.add_child(mi)


# ------------------------------------------------------------------ signs

## A small plate with centred text (desk sign, name plate, ...).
func _plate(parent: Node3D, text: String, pos: Vector3, size: Vector3,
		bg: Color, fg: Color, pixel_size := 0.0035) -> void:
	CampusBuilder.box(parent, size, pos, _flat(bg, 0.55), "Plate")
	var max_px := (size.x * 0.86) / pixel_size
	var fs := _fit_font_size(text, max_px, 34)
	var label := Label3D.new()
	label.text = text
	label.font_size = fs
	label.pixel_size = pixel_size
	label.modulate = fg
	label.outline_size = 4
	label.outline_modulate = bg.darkened(0.5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.width = (size.x * 0.94) / pixel_size
	label.position = pos + Vector3(0, 0, size.z * 0.5 + 0.008)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.double_sided = false
	parent.add_child(label)


## Wall-mounted text sign. `parent` lets the Admin hall door add its own sign.
## The label is never billboarded and always faces along the sign's local +Z.
func _sign(text: String, sub: String, pos: Vector3, yaw: float, size: Vector2,
		bg: Color, fg: Color, parent: Node = null) -> void:
	var target := parent if parent else self
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	target.add_child(root)
	CampusBuilder.box(root, Vector3(size.x, size.y, 0.05), Vector3.ZERO,
		_flat(bg, 0.7), "SignPanel")
	# a slim contrasting border so the sign reads as a plate
	var border := _flat(fg.darkened(0.15), 0.6)
	CampusBuilder.box(root, Vector3(size.x + 0.07, 0.04, 0.07), Vector3(0, size.y * 0.5 + 0.01, 0),
		border, "SignBorder")
	CampusBuilder.box(root, Vector3(size.x + 0.07, 0.04, 0.07), Vector3(0, -size.y * 0.5 - 0.01, 0),
		border, "SignBorder")
	CampusBuilder.box(root, Vector3(0.04, size.y, 0.07), Vector3(-size.x * 0.5 - 0.015, 0, 0),
		border, "SignBorder")
	CampusBuilder.box(root, Vector3(0.04, size.y, 0.07), Vector3(size.x * 0.5 + 0.015, 0, 0),
		border, "SignBorder")

	var pixel_size := 0.005
	var max_px := (size.x * 0.88) / pixel_size
	var fs := _fit_font_size(text, max_px, 42)
	var has_sub := sub != ""
	var dy := size.y * 0.22 if has_sub else 0.0
	_sign_label(root, text, Vector3(0, dy, 0.062), fs, pixel_size, fg, bg, max_px)
	if has_sub:
		var sub_fs := _fit_font_size(sub, max_px, int(fs * 0.58))
		_sign_label(root, sub, Vector3(0, -dy * 1.05, 0.062), sub_fs, pixel_size,
			fg, bg, max_px)


## One centred Label3D. Billboarding is off so the sign keeps facing the wall
## it is mounted on.
func _sign_label(parent: Node3D, text: String, pos: Vector3, fs: int, pixel_size: float,
		fg: Color, bg: Color, width_px: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = fs
	label.pixel_size = pixel_size
	label.modulate = fg
	label.outline_size = maxi(4, int(fs * 0.14))
	label.outline_modulate = bg.darkened(0.45)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.width = width_px
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.double_sided = false
	parent.add_child(label)


## Picks the biggest font size that still fits `text` inside `max_px` pixels,
## so no sign is ever clipped.
func _fit_font_size(text: String, max_px: float, start: int) -> int:
	var font := ThemeDB.fallback_font
	if font == null:
		return start
	var fs := start
	while fs > 14:
		var widest := 0.0
		for line in text.split("\n"):
			widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		if widest <= max_px:
			break
		fs -= 2
	return fs


func _label_on_wall(text: String, pos: Vector3, yaw: float, size: Vector2,
		fg: Color, bg: Color) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	var pixel_size := 0.006
	var max_px := (size.x * 0.9) / pixel_size
	var fs := _fit_font_size(text, max_px, 64)
	var label := Label3D.new()
	label.text = text
	label.font_size = fs
	label.pixel_size = pixel_size
	label.modulate = fg
	label.outline_size = maxi(5, int(fs * 0.12))
	label.outline_modulate = bg
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.width = max_px
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.double_sided = false
	root.add_child(label)
