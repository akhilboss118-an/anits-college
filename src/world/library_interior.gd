class_name LibraryInterior
extends Node3D
## ANITS Central Library: a walk-in interior with bookshelves, study desks,
## reading lamps, digital OPAC kiosks, and a librarian issue counter.
##
## Built far west of campus in the interior zone at Vector3(-320, 0, 60).
## Low-poly geometry with shared materials and 5 warm OmniLights keeps performance
## rock-solid on mobile and web.

const CENTER := Vector3(-320.0, 0.0, 60.0)
const HALF_W := 8.0
const HALF_D := 6.5
const HEIGHT := 3.6
const DADO_TOP := 1.1

# ------------------------------------------------------------------ palette
const PARQUET := Color("#735137")
const OAK := Color("#593c24")
const OAK_DARK := Color("#3c2615")
const WALL_CREAM := Color("#f3ede2")
const DADO_GREEN := Color("#204634")
const GOLD_TRIM := Color("#c8a14d")
const CEILING := Color("#ecefe9")
const LAMP_GREEN := Color("#1f5b3a")
const WARM_LIGHT := Color("#fff1d0")
const METAL_CHROME := Color("#8a939a")
const BOOK_COLORS := [
	Color("#8b2635"), Color("#1f4e5b"), Color("#2b5937"),
	Color("#a26d24"), Color("#463b63"), Color("#3d4550"),
	Color("#9e472a"), Color("#235b64"), Color("#69314c"),
]

# ------------------------------------------------------------------ public API
var entry_pos := CENTER + Vector3(0.0, 0.12, 4.6)
var exit_pos := CENTER + Vector3(0.0, 0.12, 5.8)
var librarian_seat := CENTER + Vector3(4.2, 0.0, 2.5)
var desk_pos := CENTER + Vector3(4.2, 0.0, 3.6)
var hall_door_pos := Vector3.ZERO
var hall_return_pos := Vector3.ZERO

var _door_node: Node3D = null
var _mats: Dictionary = {}


func build() -> void:
	position = CENTER
	_mats.clear()
	_build_materials()
	_build_shell()
	_build_issue_desk()
	_build_bookshelves()
	_build_reading_tables()
	_build_digital_kiosks()
	_build_signs()
	_build_lights()


func _mat(key: String) -> StandardMaterial3D:
	return _mats.get(key, null) as StandardMaterial3D


func _build_materials() -> void:
	var m_floor := StandardMaterial3D.new()
	m_floor.albedo_color = PARQUET
	m_floor.roughness = 0.55
	_mats["floor"] = m_floor

	var m_wall := StandardMaterial3D.new()
	m_wall.albedo_color = WALL_CREAM
	m_wall.roughness = 0.88
	_mats["wall"] = m_wall

	var m_dado := StandardMaterial3D.new()
	m_dado.albedo_color = DADO_GREEN
	m_dado.roughness = 0.72
	_mats["dado"] = m_dado

	var m_gold := StandardMaterial3D.new()
	m_gold.albedo_color = GOLD_TRIM
	m_gold.metallic = 0.65
	m_gold.roughness = 0.35
	_mats["gold"] = m_gold

	var m_oak := StandardMaterial3D.new()
	m_oak.albedo_color = OAK
	m_oak.roughness = 0.65
	_mats["oak"] = m_oak

	var m_oak_dark := StandardMaterial3D.new()
	m_oak_dark.albedo_color = OAK_DARK
	m_oak_dark.roughness = 0.7
	_mats["oak_dark"] = m_oak_dark

	var m_ceiling := StandardMaterial3D.new()
	m_ceiling.albedo_color = CEILING
	m_ceiling.roughness = 0.95
	_mats["ceiling"] = m_ceiling

	var m_chrome := StandardMaterial3D.new()
	m_chrome.albedo_color = METAL_CHROME
	m_chrome.metallic = 0.8
	m_chrome.roughness = 0.3
	_mats["chrome"] = m_chrome

	var m_lamp := StandardMaterial3D.new()
	m_lamp.albedo_color = LAMP_GREEN
	m_lamp.roughness = 0.3
	_mats["banker_lamp"] = m_lamp

	var m_emissive := StandardMaterial3D.new()
	m_emissive.albedo_color = WARM_LIGHT
	m_emissive.emission_enabled = true
	m_emissive.emission = WARM_LIGHT
	m_emissive.emission_energy_multiplier = 1.4
	_mats["emissive"] = m_emissive


func _build_shell() -> void:
	# Floor and ceiling
	CampusBuilder.box(self, Vector3(HALF_W * 2.0, 0.2, HALF_D * 2.0),
		Vector3(0, -0.08, 0), _mat("floor"), "Floor")
	CampusBuilder.box(self, Vector3(HALF_W * 2.0, 0.2, HALF_D * 2.0),
		Vector3(0, HEIGHT + 0.1, 0), _mat("ceiling"), "Ceiling")

	# Colliders for floor and ceiling
	CampusBuilder.add_collider(self, Vector3(HALF_W * 2.0, 0.2, HALF_D * 2.0),
		Vector3(0, -0.08, 0), "FloorCol")
	CampusBuilder.add_collider(self, Vector3(HALF_W * 2.0, 0.2, HALF_D * 2.0),
		Vector3(0, HEIGHT + 0.1, 0), "CeilCol")

	# North wall (back)
	_wall(-HALF_W, HALF_W, -HALF_D, -HALF_D + 0.2)
	# West wall
	_wall(-HALF_W, -HALF_W + 0.2, -HALF_D, HALF_D)
	# East wall
	_wall(HALF_W - 0.2, HALF_W, -HALF_D, HALF_D)

	# South wall (with entrance doorway in center: X from -1.4 to 1.4)
	_wall(-HALF_W, -1.4, HALF_D - 0.2, HALF_D)
	_wall(1.4, HALF_W, HALF_D - 0.2, HALF_D)
	# Transom over doorway
	_wall_segment(Vector3(0, (HEIGHT + 2.4) * 0.5, HALF_D - 0.1),
		Vector3(2.8, HEIGHT - 2.4, 0.2))

	# Double entrance doors (swung inward / open frame)
	_build_doorway()


func _wall(x0: float, x1: float, z0: float, z1: float) -> void:
	var size := Vector3(absf(x1 - x0), HEIGHT, absf(z1 - z0))
	var centre := Vector3((x0 + x1) * 0.5, HEIGHT * 0.5, (z0 + z1) * 0.5)

	# Lower dado wainscot
	CampusBuilder.box(self, Vector3(size.x, DADO_TOP, size.z),
		Vector3(centre.x, DADO_TOP * 0.5, centre.z), _mat("dado"), "DadoWall")
	# Gold rail trim
	CampusBuilder.box(self, Vector3(size.x + 0.02, 0.05, size.z + 0.02),
		Vector3(centre.x, DADO_TOP, centre.z), _mat("gold"), "DadoRail")
	# Skirting board
	CampusBuilder.box(self, Vector3(size.x + 0.02, 0.12, size.z + 0.02),
		Vector3(centre.x, 0.06, centre.z), _mat("oak_dark"), "Skirting")
	# Upper cream plaster
	CampusBuilder.box(self, Vector3(size.x, HEIGHT - DADO_TOP, size.z),
		Vector3(centre.x, (DADO_TOP + HEIGHT) * 0.5, centre.z), _mat("wall"), "UpperWall")

	CampusBuilder.add_collider(self, size, centre - Vector3(0, HEIGHT * 0.5, 0), "WallCol")


func _wall_segment(centre: Vector3, size: Vector3) -> void:
	CampusBuilder.box(self, size, centre, _mat("wall"), "WallSegment")
	CampusBuilder.add_collider(self, size, centre - Vector3(0, size.y * 0.5, 0), "WallSegCol")


func _build_doorway() -> void:
	# Wooden door frame
	var frame_mat := _mat("oak_dark")
	CampusBuilder.box(self, Vector3(0.12, 2.45, 0.26), Vector3(-1.38, 1.22, HALF_D - 0.1), frame_mat, "DoorPostL")
	CampusBuilder.box(self, Vector3(0.12, 2.45, 0.26), Vector3(1.38, 1.22, HALF_D - 0.1), frame_mat, "DoorPostR")
	CampusBuilder.box(self, Vector3(2.88, 0.12, 0.26), Vector3(0.0, 2.45, HALF_D - 0.1), frame_mat, "DoorHeader")

	# Frosted glass doors angled open
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.85, 0.92, 0.98, 0.55)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.2

	var door_l := CampusBuilder.box(self, Vector3(1.15, 2.3, 0.06), Vector3(-0.85, 1.15, HALF_D - 0.4), glass_mat, "DoorL")
	door_l.rotation.y = deg_to_rad(-25.0)
	var door_r := CampusBuilder.box(self, Vector3(1.15, 2.3, 0.06), Vector3(0.85, 1.15, HALF_D - 0.4), glass_mat, "DoorR")
	door_r.rotation.y = deg_to_rad(25.0)

	# Brass handles
	CampusBuilder.box(door_l, Vector3(0.04, 0.35, 0.08), Vector3(0.48, 0.0, 0.0), _mat("gold"), "HandleL")
	CampusBuilder.box(door_r, Vector3(0.04, 0.35, 0.08), Vector3(-0.48, 0.0, 0.0), _mat("gold"), "HandleR")


func _build_issue_desk() -> void:
	var root := Node3D.new()
	root.name = "IssueDesk"
	root.position = Vector3(4.2, 0.0, 3.6)
	add_child(root)

	var desk_mat := _mat("oak")
	var dark_mat := _mat("oak_dark")

	# Front counter (length 3.4m, height 1.1m)
	CampusBuilder.box(root, Vector3(3.4, 1.05, 0.7), Vector3(0, 0.52, 0), desk_mat, "CounterFront")
	CampusBuilder.box(root, Vector3(3.5, 0.08, 0.8), Vector3(0, 1.09, 0), dark_mat, "CounterTop")
	CampusBuilder.add_collider(root, Vector3(3.4, 1.1, 0.7), Vector3(0, 0.0, 0), "CounterCol")

	# Side return counter (L-shape)
	CampusBuilder.box(root, Vector3(0.65, 1.05, 1.8), Vector3(1.35, 0.52, -1.25), desk_mat, "CounterReturn")
	CampusBuilder.box(root, Vector3(0.75, 0.08, 1.9), Vector3(1.35, 1.09, -1.25), dark_mat, "ReturnTop")
	CampusBuilder.add_collider(root, Vector3(0.65, 1.1, 1.8), Vector3(1.35, 0.0, -1.25), "ReturnCol")

	# Librarian computer monitor
	CampusBuilder.box(root, Vector3(0.52, 0.34, 0.06), Vector3(-0.6, 1.34, 0.05),
		CampusBuilder.mat(Color("#222629"), 0.4), "Monitor")
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color("#183d5a")
	screen_mat.emission_enabled = true
	screen_mat.emission = Color("#2a689a")
	screen_mat.emission_energy_multiplier = 0.6
	CampusBuilder.box(root, Vector3(0.48, 0.3, 0.02), Vector3(-0.6, 1.34, 0.08), screen_mat, "Screen")
	# Monitor stand
	CampusBuilder.box(root, Vector3(0.08, 0.18, 0.08), Vector3(-0.6, 1.18, 0.05), _mat("chrome"), "Stand")
	CampusBuilder.box(root, Vector3(0.24, 0.02, 0.2), Vector3(-0.6, 1.1, 0.05), _mat("chrome"), "Base")

	# Keyboard + mouse pad
	CampusBuilder.box(root, Vector3(0.38, 0.02, 0.14), Vector3(-0.6, 1.11, 0.26),
		CampusBuilder.mat(Color("#2b2f33"), 0.5), "Keyboard")

	# Stamp pad and book register
	CampusBuilder.box(root, Vector3(0.36, 0.04, 0.46), Vector3(0.4, 1.12, 0.1),
		CampusBuilder.mat(Color("#4a2a1a"), 0.6), "RegisterBook")
	CampusBuilder.box(root, Vector3(0.12, 0.02, 0.08), Vector3(0.72, 1.11, 0.1),
		CampusBuilder.mat(Color("#1a1a1a"), 0.4), "StampPad")

	# Librarian office chair
	var chair := Node3D.new()
	chair.name = "LibrarianChair"
	chair.position = Vector3(0.0, 0.0, -0.9)
	root.add_child(chair)
	var leather := CampusBuilder.mat(Color("#2c2c30"), 0.45)
	CampusBuilder.box(chair, Vector3(0.48, 0.08, 0.48), Vector3(0, 0.48, 0), leather, "Seat")
	CampusBuilder.box(chair, Vector3(0.46, 0.52, 0.08), Vector3(0, 0.78, -0.2), leather, "Back")
	CampusBuilder.box(chair, Vector3(0.06, 0.45, 0.06), Vector3(0, 0.23, 0), _mat("chrome"), "Stem")

	# Sign on front of desk: "RETURN BOOKS HERE"
	_sign("RETURN & ISSUE DESK", "Keep your ID card ready",
		Vector3(0.0, 0.75, 0.38), 0.0, Vector2(1.8, 0.38), Color("#1d3b2b"), Color("#ffd54a"), root)


func _build_bookshelves() -> void:
	# 6 Double-sided tall book stacks
	# Arranged in 2 aisles (X = -4.8 and X = -1.6)
	var aisle_x := [-4.8, -1.6]
	var row_z := [-3.8, -1.2, 1.4]

	var book_idx := 0
	for ax in aisle_x:
		for rz in row_z:
			var stack := Node3D.new()
			stack.name = "Bookstack_%.1f_%.1f" % [ax, rz]
			stack.position = Vector3(ax, 0.0, rz)
			add_child(stack)

			# Main bookcase frame: W 2.6m, H 2.7m, D 0.85m
			var frame_mat := _mat("oak")
			CampusBuilder.box(stack, Vector3(2.6, 2.7, 0.85), Vector3(0, 1.35, 0), frame_mat, "CaseFrame")
			CampusBuilder.add_collider(stack, Vector3(2.6, 2.7, 0.85), Vector3(0, 0.0, 0), "CaseCol")

			# 4 shelves on North face, 4 on South face
			for shelf_y in [0.45, 1.05, 1.65, 2.25]:
				# Shelving boards
				CampusBuilder.box(stack, Vector3(2.48, 0.04, 0.82), Vector3(0, shelf_y, 0), _mat("oak_dark"), "Shelf")

				# Rows of books on front and back
				for side in [-0.28, 0.28]:
					# Create clusters of books with contrasting colors
					var x_start := -1.15
					while x_start < 1.15:
						var book_w := randf_range(0.25, 0.45)
						var book_h := randf_range(0.32, 0.46)
						var col: Color = BOOK_COLORS[book_idx % BOOK_COLORS.size()]
						book_idx += 1
						var b_mat := CampusBuilder.mat(col, 0.6)
						CampusBuilder.box(stack, Vector3(book_w - 0.03, book_h, 0.22),
							Vector3(x_start + book_w * 0.5, shelf_y + book_h * 0.5 + 0.02, side),
							b_mat, "Books")
						x_start += book_w

			# Category label on end panel
			var cat_name := "CSE & IT" if ax < -3.0 else "MATH & BASIC SCI"
			if rz > 0.0:
				cat_name = "REFERENCE" if ax < -3.0 else "JOURNALS"
			_sign(cat_name, "ANITS LIBRARY", Vector3(1.32, 2.1, 0.0), PI * 0.5,
				Vector2(0.7, 0.26), Color("#1b2e23"), Color("#f4e8b8"), stack)


func _build_reading_tables() -> void:
	# 2 Large study tables on the East side (X = 3.6, Z = -3.5 and Z = -0.5)
	for tz in [-3.5, -0.6]:
		var table := Node3D.new()
		table.name = "StudyTable_%.1f" % tz
		table.position = Vector3(3.6, 0.0, tz)
		add_child(table)

		# Table top: W 3.2m, D 1.4m, H 0.75m
		var t_mat := _mat("oak")
		CampusBuilder.box(table, Vector3(3.2, 0.06, 1.4), Vector3(0, 0.75, 0), t_mat, "TableTop")
		CampusBuilder.add_collider(table, Vector3(3.2, 0.75, 1.4), Vector3(0, 0.0, 0), "TableCol")

		# 4 sturdy wooden legs
		for lx in [-1.45, 1.45]:
			for lz in [-0.58, 0.58]:
				CampusBuilder.box(table, Vector3(0.08, 0.75, 0.08), Vector3(lx, 0.375, lz), _mat("oak_dark"), "Leg")

		# Center partition / divider
		CampusBuilder.box(table, Vector3(3.0, 0.24, 0.04), Vector3(0, 0.9, 0), _mat("oak_dark"), "Divider")

		# 2 Green brass banker's reading lamps on table
		for bx in [-0.85, 0.85]:
			var lamp := Node3D.new()
			lamp.position = Vector3(bx, 0.78, 0)
			table.add_child(lamp)
			CampusBuilder.box(lamp, Vector3(0.12, 0.02, 0.12), Vector3(0, 0.01, 0), _mat("gold"), "LampBase")
			CampusBuilder.box(lamp, Vector3(0.02, 0.28, 0.02), Vector3(0, 0.14, 0), _mat("gold"), "LampStem")
			CampusBuilder.box(lamp, Vector3(0.22, 0.08, 0.1), Vector3(0, 0.26, 0), _mat("banker_lamp"), "Shade")
			CampusBuilder.box(lamp, Vector3(0.18, 0.04, 0.06), Vector3(0, 0.23, 0), _mat("emissive"), "Bulb")

		# Open study books on the table
		CampusBuilder.box(table, Vector3(0.38, 0.03, 0.28), Vector3(-0.9, 0.79, 0.4),
			CampusBuilder.mat(Color("#f0eada"), 0.7), "OpenBook1")
		CampusBuilder.box(table, Vector3(0.36, 0.03, 0.26), Vector3(0.9, 0.79, -0.4),
			CampusBuilder.mat(Color("#ebe4d5"), 0.7), "OpenBook2")

		# 4 Wooden study chairs per table
		for cx in [-0.9, 0.9]:
			for cz in [-0.95, 0.95]:
				var chair := Node3D.new()
				chair.position = Vector3(cx, 0.0, cz)
				chair.rotation.y = 0.0 if cz > 0 else PI
				table.add_child(chair)
				CampusBuilder.box(chair, Vector3(0.44, 0.05, 0.44), Vector3(0, 0.45, 0), _mat("oak"), "Seat")
				CampusBuilder.box(chair, Vector3(0.44, 0.44, 0.04), Vector3(0, 0.72, 0.2), _mat("oak"), "Back")
				for lx in [-0.18, 0.18]:
					for lz in [-0.18, 0.18]:
						CampusBuilder.box(chair, Vector3(0.04, 0.45, 0.04), Vector3(lx, 0.225, lz), _mat("oak_dark"), "Leg")


func _build_digital_kiosks() -> void:
	# 2 Standing digital catalogue terminals on the west wall
	for kz in [-4.2, -1.8]:
		var kiosk := Node3D.new()
		kiosk.position = Vector3(-HALF_W + 0.5, 0.0, kz)
		add_child(kiosk)

		var podium_mat := CampusBuilder.mat(Color("#1d242b"), 0.4)
		CampusBuilder.box(kiosk, Vector3(0.5, 1.15, 0.5), Vector3(0, 0.575, 0), podium_mat, "KioskPedestal")
		CampusBuilder.add_collider(kiosk, Vector3(0.5, 1.15, 0.5), Vector3(0, 0.0, 0), "KioskCol")

		# Angled touchscreen monitor
		var mon := CampusBuilder.box(kiosk, Vector3(0.48, 0.32, 0.06), Vector3(0.05, 1.25, 0),
			CampusBuilder.mat(Color("#0d131a"), 0.3), "Monitor")
		mon.rotation.x = deg_to_rad(-20.0)
		var scr := CampusBuilder.box(mon, Vector3(0.44, 0.28, 0.02), Vector3(0, 0, 0.04),
			_mat("emissive"), "Screen")
		scr.material_override = CampusBuilder.mat(Color("#2471a3"), 0.4, 0.8)


func _build_signs() -> void:
	# Main entrance greeting over inside doorway
	_sign("CENTRAL LIBRARY · ANITS", "SILENCE PLEASE · NO FOOD OR PHONE CALLS",
		Vector3(0.0, 2.95, HALF_D - 0.22), PI, Vector2(3.2, 0.58), Color("#1b382b"), Color("#ffd54a"))

	# Library Rules notice board on east wall
	_sign("DIGITAL LIBRARY RULES", "1. Valid Student ID required at all times\n2. Issue limit: 3 books per card\n3. Renewal period: 14 days\n4. Strict silence in study bay",
		Vector3(HALF_W - 0.22, 2.1, 0.8), -PI * 0.5, Vector2(2.2, 1.1), Color("#243342"), Color.WHITE)

	# Wall clock on North wall
	var clock := CylinderMesh.new()
	clock.top_radius = 0.32
	clock.bottom_radius = 0.32
	clock.height = 0.05
	var cmi := MeshInstance3D.new()
	cmi.mesh = clock
	cmi.material_override = CampusBuilder.mat(Color("#ffffff"), 0.2)
	cmi.rotation.x = PI * 0.5
	cmi.position = Vector3(0.0, 2.9, -HALF_D + 0.23)
	add_child(cmi)


func _sign(title: String, subtitle: String, pos: Vector3, yaw: float,
		size: Vector2, bg_col: Color, text_col: Color, parent: Node = null) -> void:
	var root := parent if parent != null else self
	var sign_node := Node3D.new()
	sign_node.position = pos
	sign_node.rotation.y = yaw
	root.add_child(sign_node)

	CampusBuilder.box(sign_node, Vector3(size.x, size.y, 0.04), Vector3.ZERO,
		CampusBuilder.mat(bg_col, 0.5), "SignPlate")
	CampusBuilder.box(sign_node, Vector3(size.x + 0.04, size.y + 0.04, 0.02), Vector3(0, 0, -0.01),
		_mat("gold"), "SignFrame")

	var lbl := Label3D.new()
	lbl.text = title
	lbl.font_size = 28
	lbl.modulate = text_col
	lbl.outline_modulate = Color.BLACK
	lbl.outline_size = 6
	lbl.position = Vector3(0, 0.08 if subtitle != "" else 0.0, 0.025)
	sign_node.add_child(lbl)

	if subtitle != "":
		var sub := Label3D.new()
		sub.text = subtitle
		sub.font_size = 14
		sub.modulate = Color(text_col.r, text_col.g, text_col.b, 0.85)
		sub.outline_modulate = Color.BLACK
		sub.outline_size = 4
		sub.position = Vector3(0, -0.12, 0.025)
		sign_node.add_child(sub)


func _build_lights() -> void:
	# 5 ceiling lamps: metal housing + frosted glass emissive diffusers
	for lx in [-4.0, 0.0, 4.0]:
		for lz in [-3.0, 2.5]:
			if lx == 0.0 and lz > 0.0:
				continue
			var pos := Vector3(lx, HEIGHT - 0.02, lz)
			CampusBuilder.box(self, Vector3(2.2, 0.08, 0.5), pos,
				CampusBuilder.mat(Color("#2c343b"), 0.5), "LampHousing")
			CampusBuilder.box(self, Vector3(2.0, 0.03, 0.38), pos - Vector3(0, 0.04, 0),
				_mat("emissive"), "LampPanel")

	# 4 warm OmniLights
	var light_specs := [
		[Vector3(-4.0, 3.1, -2.5), WARM_LIGHT, 1.4, 9.0],
		[Vector3(-4.0, 3.1, 2.0), WARM_LIGHT, 1.3, 8.5],
		[Vector3(3.6, 3.1, -2.5), WARM_LIGHT, 1.4, 9.0],
		[Vector3(3.6, 3.1, 2.5), WARM_LIGHT, 1.3, 8.5],
	]
	for spec in light_specs:
		var light := OmniLight3D.new()
		light.position = spec[0]
		light.light_color = spec[1]
		light.light_energy = spec[2]
		light.omni_range = spec[3]
		light.shadow_enabled = false
		add_child(light)


# ------------------------------------------------------------------ campus door

## Builds the exterior doorframe on the campus and the interactable node
func build_campus_door(pos: Vector3, yaw: float) -> void:
	hall_door_pos = pos
	hall_return_pos = pos + Vector3(sin(yaw), 0.12, cos(yaw)) * 1.8

	var root := Node3D.new()
	root.name = "CentralLibraryDoor"
	root.position = hall_door_pos - position
	root.rotation.y = yaw
	add_child(root)

	var frame_mat := CampusBuilder.mat(Color("#2c4034"), 0.6)
	var door_wood := CampusBuilder.mat(OAK, 0.5)

	# Portal frame
	CampusBuilder.box(root, Vector3(2.4, 2.8, 0.3), Vector3(0, 1.4, 0), frame_mat, "Portal")
	# Double door leaves
	CampusBuilder.box(root, Vector3(0.98, 2.3, 0.08), Vector3(-0.52, 1.15, 0.06), door_wood, "DoorL")
	CampusBuilder.box(root, Vector3(0.98, 2.3, 0.08), Vector3(0.52, 1.15, 0.06), door_wood, "DoorR")
	# Glass panels
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.8, 0.9, 1.0, 0.5)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	CampusBuilder.box(root, Vector3(0.65, 1.1, 0.09), Vector3(-0.52, 1.4, 0.06), glass, "GlassL")
	CampusBuilder.box(root, Vector3(0.65, 1.1, 0.09), Vector3(0.52, 1.4, 0.06), glass, "GlassR")

	# Sign: "CENTRAL LIBRARY"
	_sign("CENTRAL LIBRARY", "Open 8:30 AM - 6:00 PM", Vector3(0, 2.95, 0.18), 0.0,
		Vector2(2.6, 0.48), Color("#1b3b28"), Color("#ffd54a"), root)

	_door_node = Node3D.new()
	_door_node.name = "LibraryDoorInteract"
	_door_node.position = Vector3(0, 1.0, 0.8)
	_door_node.add_to_group("interactables")
	_door_node.add_to_group("library_door")
	root.add_child(_door_node)
