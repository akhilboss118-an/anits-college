class_name CanteenInterior
extends Node3D
## ANITS Campus Canteen: walk-in food court with stainless steel hot food counter,
## samosa warming showcase, chai urns, illuminated menu board, drink coolers,
## colorful dining tables with attached stools, and ceiling fans.
##
## Built far west of campus in the interior zone at Vector3(-320, 0, 180).

const CENTER := Vector3(-320.0, 0.0, 180.0)
const HALF_W := 8.5
const HALF_D := 7.0
const HEIGHT := 3.8
const DADO_TOP := 1.2

# ------------------------------------------------------------------ palette
const TERRACOTTA := Color("#aa5438")
const WALL_CREAM := Color("#faf4eb")
const DADO_ORANGE := Color("#c66228")
const STAINLESS := Color("#c9d0d6")
const STEEL_DARK := Color("#646b73")
const CHROME := Color("#d0d6dc")
const TABLE_BLUE := Color("#20639b")
const TABLE_YELLOW := Color("#f6d55c")
const SNOODLE_RED := Color("#ed553b")
const CEILING := Color("#ecefe9")
const AMBER_WARM := Color("#ffba49")

# ------------------------------------------------------------------ public API
var entry_pos := CENTER + Vector3(0.0, 0.12, 5.0)
var exit_pos := CENTER + Vector3(0.0, 0.12, 6.2)
var counter_pos := CENTER + Vector3(0.0, 0.0, -2.8)
var hall_door_pos := Vector3.ZERO
var hall_return_pos := Vector3.ZERO

var _fans: Array[Node3D] = []
var _door_node: Node3D = null
var _mats: Dictionary = {}


func build() -> void:
	position = CENTER
	_mats.clear()
	_fans.clear()
	_build_materials()
	_build_shell()
	_build_service_counter()
	_build_drink_coolers()
	_build_dining_tables()
	_build_wash_basin()
	_build_ceiling_fans()
	_build_signs()
	_build_lights()


func _process(delta: float) -> void:
	var rot := delta * 4.5
	for fan in _fans:
		if is_instance_valid(fan):
			fan.rotate_y(rot)


func _mat(key: String) -> StandardMaterial3D:
	return _mats.get(key, null) as StandardMaterial3D


func _build_materials() -> void:
	var m_floor := StandardMaterial3D.new()
	m_floor.albedo_color = TERRACOTTA
	m_floor.roughness = 0.5
	_mats["floor"] = m_floor

	var m_wall := StandardMaterial3D.new()
	m_wall.albedo_color = WALL_CREAM
	m_wall.roughness = 0.85
	_mats["wall"] = m_wall

	var m_dado := StandardMaterial3D.new()
	m_dado.albedo_color = DADO_ORANGE
	m_dado.roughness = 0.65
	_mats["dado"] = m_dado

	var m_steel := StandardMaterial3D.new()
	m_steel.albedo_color = STAINLESS
	m_steel.metallic = 0.45
	m_steel.roughness = 0.4
	_mats["steel"] = m_steel

	var m_chrome := StandardMaterial3D.new()
	m_chrome.albedo_color = CHROME
	m_chrome.metallic = 0.95
	m_chrome.roughness = 0.15
	_mats["chrome"] = m_chrome

	var m_ceiling := StandardMaterial3D.new()
	m_ceiling.albedo_color = CEILING
	m_ceiling.roughness = 0.95
	_mats["ceiling"] = m_ceiling

	var m_amber := StandardMaterial3D.new()
	m_amber.albedo_color = AMBER_WARM
	m_amber.emission_enabled = true
	m_amber.emission = AMBER_WARM
	m_amber.emission_energy_multiplier = 1.2
	_mats["amber"] = m_amber


func _build_shell() -> void:
	CampusBuilder.box(self, Vector3(HALF_W * 2.0, 0.2, HALF_D * 2.0),
		Vector3(0, -0.08, 0), _mat("floor"), "Floor")
	CampusBuilder.box(self, Vector3(HALF_W * 2.0, 0.2, HALF_D * 2.0),
		Vector3(0, HEIGHT + 0.1, 0), _mat("ceiling"), "Ceiling")

	CampusBuilder.add_collider(self, Vector3(HALF_W * 2.0, 0.2, HALF_D * 2.0),
		Vector3(0, -0.08, 0), "FloorCol")
	CampusBuilder.add_collider(self, Vector3(HALF_W * 2.0, 0.2, HALF_D * 2.0),
		Vector3(0, HEIGHT + 0.1, 0), "CeilCol")

	# North wall (behind the kitchen / serving counters)
	_wall(-HALF_W, HALF_W, -HALF_D, -HALF_D + 0.2)
	# West wall
	_wall(-HALF_W, -HALF_W + 0.2, -HALF_D, HALF_D)
	# East wall
	_wall(HALF_W - 0.2, HALF_W, -HALF_D, HALF_D)

	# South wall (with wide double entrance doorway in center: X from -1.6 to 1.6)
	_wall(-HALF_W, -1.6, HALF_D - 0.2, HALF_D)
	_wall(1.6, HALF_W, HALF_D - 0.2, HALF_D)
	# Header over entrance
	var hdr_size := Vector3(3.2, HEIGHT - 2.5, 0.2)
	var hdr_pos := Vector3(0.0, (HEIGHT + 2.5) * 0.5, HALF_D - 0.1)
	CampusBuilder.box(self, hdr_size, hdr_pos, _mat("wall"), "SouthHdr")
	CampusBuilder.add_collider(self, hdr_size, hdr_pos - Vector3(0, hdr_size.y * 0.5, 0), "SouthHdrCol")


func _wall(x0: float, x1: float, z0: float, z1: float) -> void:
	var size := Vector3(absf(x1 - x0), HEIGHT, absf(z1 - z0))
	var centre := Vector3((x0 + x1) * 0.5, HEIGHT * 0.5, (z0 + z1) * 0.5)

	CampusBuilder.box(self, Vector3(size.x, DADO_TOP, size.z),
		Vector3(centre.x, DADO_TOP * 0.5, centre.z), _mat("dado"), "DadoWall")
	CampusBuilder.box(self, Vector3(size.x + 0.02, 0.04, size.z + 0.02),
		Vector3(centre.x, DADO_TOP, centre.z), _mat("steel"), "DadoRail")
	CampusBuilder.box(self, Vector3(size.x, HEIGHT - DADO_TOP, size.z),
		Vector3(centre.x, (DADO_TOP + HEIGHT) * 0.5, centre.z), _mat("wall"), "UpperWall")

	CampusBuilder.add_collider(self, size, centre - Vector3(0, HEIGHT * 0.5, 0), "WallCol")


func _build_service_counter() -> void:
	var root := Node3D.new()
	root.name = "ServiceCounter"
	root.position = Vector3(0.0, 0.0, -HALF_D + 2.8)
	add_child(root)

	# Long stainless steel serving counter (11.0m long, 1.1m high, 0.9m deep)
	CampusBuilder.box(root, Vector3(11.0, 1.05, 0.9), Vector3(0, 0.525, 0), _mat("steel"), "CounterBase")
	CampusBuilder.box(root, Vector3(11.2, 0.06, 1.0), Vector3(0, 1.08, 0), _mat("chrome"), "CounterTop")
	CampusBuilder.add_collider(root, Vector3(11.0, 1.1, 0.9), Vector3(0, 0.0, 0), "CounterCol")

	# Glass sneeze guard across counter top (0.45m high)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.88, 0.94, 1.0, 0.4)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	CampusBuilder.box(root, Vector3(8.5, 0.45, 0.04), Vector3(-1.0, 1.33, 0.4), glass, "SneezeGuard")
	CampusBuilder.box(root, Vector3(8.6, 0.04, 0.06), Vector3(-1.0, 1.56, 0.4), _mat("chrome"), "GuardRail")
	# Chrome posts carry the guard and rail up off the counter top.
	for px in [-5.0, -1.8, 0.9, 2.9]:
		CampusBuilder.box(root, Vector3(0.035, 0.44, 0.035), Vector3(px, 1.32, 0.4),
			_mat("chrome"), "GuardPost")

	# 1. Hot Samosa & Snack Warming Showcase (left side of counter)
	var warmer := Node3D.new()
	warmer.position = Vector3(-3.4, 1.1, 0.0)
	root.add_child(warmer)
	CampusBuilder.box(warmer, Vector3(1.6, 0.65, 0.7), Vector3(0, 0.325, 0), glass, "WarmerGlass")
	CampusBuilder.box(warmer, Vector3(1.62, 0.04, 0.72), Vector3(0, 0.66, 0), _mat("steel"), "WarmerTop")
	CampusBuilder.box(warmer, Vector3(1.4, 0.04, 0.6), Vector3(0, 0.63, 0), _mat("amber"), "HeatLamp")
	# Golden samosa snacks inside showcase
	for sx in [-0.5, -0.15, 0.2, 0.5]:
		CampusBuilder.box(warmer, Vector3(0.18, 0.12, 0.18), Vector3(sx, 0.08, 0.0),
			CampusBuilder.mat(Color("#d4882e"), 0.6), "SamosaGroup")

	# 2. Large Stainless Steel Chai Urn & Dispenser (center of counter)
	var urn := Node3D.new()
	urn.position = Vector3(-0.6, 1.1, 0.0)
	root.add_child(urn)
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.22
	cylinder.bottom_radius = 0.22
	cylinder.height = 0.65
	var umi := MeshInstance3D.new()
	umi.mesh = cylinder
	umi.material_override = _mat("chrome")
	umi.position = Vector3(0, 0.35, 0)
	urn.add_child(umi)
	# Chrome tap
	CampusBuilder.box(urn, Vector3(0.06, 0.12, 0.16), Vector3(0, 0.2, 0.26), _mat("chrome"), "Tap")
	# Stacks of paper cups beside chai urn
	for cx in [0.35, 0.5]:
		CampusBuilder.box(urn, Vector3(0.12, 0.38, 0.12), Vector3(cx, 0.19, 0.1),
			CampusBuilder.mat(Color("#f7eedb"), 0.7), "CupStack")

	# 3. Cash Register / Token Billing Point (right side of counter)
	var pos_reg := Node3D.new()
	pos_reg.position = Vector3(4.2, 1.1, 0.0)
	root.add_child(pos_reg)
	CampusBuilder.box(pos_reg, Vector3(0.48, 0.22, 0.44), Vector3(0, 0.11, 0),
		CampusBuilder.mat(Color("#2c343b"), 0.4), "Register")
	CampusBuilder.box(pos_reg, Vector3(0.3, 0.18, 0.05), Vector3(0, 0.3, -0.15),
		CampusBuilder.mat(Color("#1a4568"), 0.3, 0.6), "RegisterScreen")
	# Token collection box
	CampusBuilder.box(pos_reg, Vector3(0.24, 0.14, 0.24), Vector3(-0.45, 0.07, 0.1),
		CampusBuilder.mat(Color("#d85c35"), 0.5), "TokenBox")

	# Large Illuminated Menu Board hung overhead above counter
	_build_menu_board(root)


func _build_menu_board(parent: Node) -> void:
	var board := Node3D.new()
	board.position = Vector3(0.0, 2.65, 0.4)
	parent.add_child(board)

	var b_mat := CampusBuilder.mat(Color("#1c2733"), 0.5)
	CampusBuilder.box(board, Vector3(7.2, 1.1, 0.08), Vector3.ZERO, b_mat, "MenuPlate")
	CampusBuilder.box(board, Vector3(7.3, 1.2, 0.04), Vector3(0, 0, -0.02), _mat("steel"), "MenuFrame")

	var title := Label3D.new()
	title.text = "ANITS CAMPUS CANTEEN · FRESH FOOD DAILY"
	title.font_size = 28
	title.modulate = Color("#ffd54a")
	title.outline_modulate = Color.BLACK
	title.outline_size = 6
	title.position = Vector3(0, 0.34, 0.05)
	board.add_child(title)

	var col1 := Label3D.new()
	col1.text = "SNACKS & SIDES\n• Masala Chai . . . . Rs 10\n• Samosa (2 pcs) . . Rs 15\n• Veg Puff . . . . . . Rs 20\n• Mirchi Bajji . . . . Rs 15"
	col1.font_size = 17
	col1.modulate = Color.WHITE
	col1.outline_modulate = Color.BLACK
	col1.outline_size = 4
	col1.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col1.position = Vector3(-2.8, -0.08, 0.05)
	board.add_child(col1)

	var col2 := Label3D.new()
	col2.text = "MEALS & BOWLS\n• Veg Fried Rice . . Rs 50\n• Egg Noodles . . . Rs 55\n• South Indian Thali Rs 60\n• Buldak Noodles . . Rs 50"
	col2.font_size = 17
	col2.modulate = Color.WHITE
	col2.outline_modulate = Color.BLACK
	col2.outline_size = 4
	col2.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col2.position = Vector3(-0.3, -0.08, 0.05)
	board.add_child(col2)

	var col3 := Label3D.new()
	col3.text = "BEVERAGES\n• Filter Coffee . . . Rs 15\n• Badam Milk . . . . Rs 20\n• Red Bull Energy . Rs 45\n• Cold Soda Drinks . Rs 20"
	col3.font_size = 17
	col3.modulate = Color.WHITE
	col3.outline_modulate = Color.BLACK
	col3.outline_size = 4
	col3.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col3.position = Vector3(2.1, -0.08, 0.05)
	board.add_child(col3)


func _build_drink_coolers() -> void:
	# 2 Large glass-front drink refrigerators against the West wall
	for cz in [-2.4, -0.6]:
		var cooler := Node3D.new()
		cooler.position = Vector3(-HALF_W + 0.6, 0.0, cz)
		add_child(cooler)

		# Cooler body
		var body_mat := CampusBuilder.mat(Color("#14181c"), 0.4)
		CampusBuilder.box(cooler, Vector3(0.9, 2.2, 0.9), Vector3(0, 1.1, 0), body_mat, "CoolerBody")
		CampusBuilder.add_collider(cooler, Vector3(0.9, 2.2, 0.9), Vector3(0, 0.0, 0), "CoolerCol")

		# Illuminated header sign: "COLD DRINKS"
		CampusBuilder.box(cooler, Vector3(0.85, 0.25, 0.05), Vector3(0, 2.05, 0.46),
			_mat("amber"), "CoolerHeader")

		# Glass front
		var glass := StandardMaterial3D.new()
		glass.albedo_color = Color(0.8, 0.92, 1.0, 0.4)
		glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		CampusBuilder.box(cooler, Vector3(0.8, 1.6, 0.04), Vector3(0, 1.05, 0.46), glass, "CoolerGlass")

		# Multi-colored drink cans inside cooler shelves
		for sy in [0.5, 0.9, 1.3, 1.7]:
			for cx in [-0.28, -0.1, 0.1, 0.28]:
				var can_col: Color = [Color("#c0392b"), Color("#27ae60"), Color("#2980b9"), Color("#f39c12")][randi() % 4]
				CampusBuilder.box(cooler, Vector3(0.1, 0.2, 0.1), Vector3(cx, sy, 0.25),
					CampusBuilder.mat(can_col, 0.3), "Can")


func _build_dining_tables() -> void:
	# 6 Canteen dining tables (2 columns of 3 tables)
	var col_x := [-3.5, 3.5]
	var row_z := [0.8, 2.8, 4.8]

	var table_idx := 0
	for cx in col_x:
		for rz in row_z:
			var tbl := Node3D.new()
			tbl.name = "CanteenTable_%d" % table_idx
			tbl.position = Vector3(cx, 0.0, rz)
			add_child(tbl)

			var top_col: Color = TABLE_BLUE if table_idx % 2 == 0 else TABLE_YELLOW
			table_idx += 1
			var top_mat := CampusBuilder.mat(top_col, 0.35)

			# Table top: W 2.4m, D 1.1m, H 0.75m
			CampusBuilder.box(tbl, Vector3(2.4, 0.06, 1.1), Vector3(0, 0.75, 0), top_mat, "TableTop")
			CampusBuilder.add_collider(tbl, Vector3(2.4, 0.75, 1.1), Vector3(0, 0.0, 0), "TableCol")

			# Metal support structure
			CampusBuilder.box(tbl, Vector3(2.0, 0.06, 0.06), Vector3(0, 0.38, 0), _mat("steel"), "FrameBeam")
			for lx in [-0.9, 0.9]:
				CampusBuilder.box(tbl, Vector3(0.08, 0.75, 0.08), Vector3(lx, 0.375, 0), _mat("steel"), "Leg")

			# 4 Attached circular stools (2 on North side, 2 on South side)
			for sx in [-0.65, 0.65]:
				for sz in [-0.78, 0.78]:
					var stool_cyl := CylinderMesh.new()
					stool_cyl.top_radius = 0.2
					stool_cyl.bottom_radius = 0.2
					stool_cyl.height = 0.05
					var smi := MeshInstance3D.new()
					smi.mesh = stool_cyl
					smi.material_override = top_mat
					smi.position = Vector3(sx, 0.46, sz)
					tbl.add_child(smi)
					CampusBuilder.box(tbl, Vector3(0.05, 0.46, 0.05), Vector3(sx, 0.23, sz), _mat("steel"), "StoolStem")

			# Table accessories (napkin holder + water bottle)
			CampusBuilder.box(tbl, Vector3(0.12, 0.12, 0.08), Vector3(-0.3, 0.84, 0),
				CampusBuilder.mat(Color("#ffffff"), 0.5), "Napkins")
			CampusBuilder.box(tbl, Vector3(0.09, 0.24, 0.09), Vector3(0.3, 0.9, 0),
				CampusBuilder.mat(Color("#2980b9"), 0.3), "WaterBottle")


func _build_wash_basin() -> void:
	# Hand washing area in East corner
	var wash := Node3D.new()
	wash.position = Vector3(HALF_W - 0.5, 0.0, 3.8)
	add_child(wash)

	# Ceramic / steel vanity (2.2m long)
	CampusBuilder.box(wash, Vector3(0.7, 0.82, 2.2), Vector3(0, 0.41, 0), _mat("steel"), "Vanity")
	CampusBuilder.add_collider(wash, Vector3(0.7, 0.82, 2.2), Vector3(0, 0.0, 0), "VanityCol")

	# 2 Sinks
	for sz in [-0.6, 0.6]:
		CampusBuilder.box(wash, Vector3(0.48, 0.04, 0.48), Vector3(-0.02, 0.83, sz),
			CampusBuilder.mat(Color("#f0f4f8"), 0.2), "Sink")
		# Chrome faucet
		CampusBuilder.box(wash, Vector3(0.04, 0.2, 0.12), Vector3(0.18, 0.95, sz), _mat("chrome"), "Faucet")

	# Mirrors on wall above sinks
	CampusBuilder.box(wash, Vector3(0.04, 0.9, 2.0), Vector3(0.35, 1.6, 0),
		CampusBuilder.mat(Color("#d8ecf8"), 0.05, 0.0), "Mirror")

	_sign("HAND WASH AREA", "Please keep counters clean",
		Vector3(HALF_W - 0.22, 2.3, 3.8), -PI * 0.5, Vector2(1.8, 0.38), Color("#1b354b"), Color.WHITE)


func _build_ceiling_fans() -> void:
	var fan_pos := [
		Vector3(-3.5, HEIGHT, 0.5),
		Vector3(3.5, HEIGHT, 0.5),
		Vector3(-3.5, HEIGHT, 3.8),
		Vector3(3.5, HEIGHT, 3.8),
	]
	for p in fan_pos:
		var root := Node3D.new()
		root.position = p
		add_child(root)

		CampusBuilder.box(root, Vector3(0.04, 0.45, 0.04), Vector3(0, -0.22, 0), _mat("steel"), "Downrod")
		CampusBuilder.box(root, Vector3(0.18, 0.08, 0.18), Vector3(0, -0.04, 0), _mat("steel"), "Canopy")

		var hub := Node3D.new()
		hub.name = "FanHub"
		hub.position = Vector3(0, -0.45, 0)
		root.add_child(hub)
		CampusBuilder.box(hub, Vector3(0.22, 0.08, 0.22), Vector3.ZERO, _mat("steel"), "Motor")

		for i in 3:
			var blade := Node3D.new()
			blade.rotation.y = i * (PI * 2.0 / 3.0)
			hub.add_child(blade)
			CampusBuilder.box(blade, Vector3(0.14, 0.01, 0.72), Vector3(0, 0, 0.42),
				CampusBuilder.mat(Color("#2c3e50"), 0.4), "Blade")

		_fans.append(hub)


func _build_signs() -> void:
	_sign("ANITS COLLEGE CANTEEN", "SNACKS · DRINKS · MEALS",
		Vector3(0.0, 2.95, HALF_D - 0.22), PI, Vector2(3.4, 0.58), Color("#c65a28"), Color("#ffd54a"))

	# Waste disposal sign
	_sign("KEEP CAMPUS CLEAN", "Dispose waste in green bins",
		Vector3(-HALF_W + 0.22, 2.2, 3.5), PI * 0.5, Vector2(1.8, 0.42), Color("#27ae60"), Color.WHITE)


func _sign(title: String, subtitle: String, pos: Vector3, yaw: float,
		size: Vector2, bg_col: Color, text_col: Color, parent: Node = null) -> void:
	var root := parent if parent != null else self
	var sign_node := Node3D.new()
	sign_node.position = pos
	sign_node.rotation.y = yaw
	root.add_child(sign_node)

	CampusBuilder.box(sign_node, Vector3(size.x, size.y, 0.04), Vector3.ZERO,
		CampusBuilder.mat(bg_col, 0.5), "SignPlate")

	var lbl := Label3D.new()
	lbl.text = title
	lbl.font_size = 26
	lbl.pixel_size = CampusBuilder.fit_label_pixel_size(title, 26, size.x - 0.08)
	lbl.modulate = text_col
	lbl.outline_modulate = Color.BLACK
	lbl.outline_size = 6
	lbl.position = Vector3(0, 0.08 if subtitle != "" else 0.0, 0.025)
	sign_node.add_child(lbl)

	if subtitle != "":
		var sub := Label3D.new()
		sub.text = subtitle
		sub.font_size = 14
		sub.pixel_size = CampusBuilder.fit_label_pixel_size(subtitle, 14, size.x - 0.08)
		sub.modulate = Color(text_col.r, text_col.g, text_col.b, 0.88)
		sub.outline_modulate = Color.BLACK
		sub.outline_size = 4
		sub.position = Vector3(0, -0.12, 0.025)
		sign_node.add_child(sub)


func _build_lights() -> void:
	# 5 Warm OmniLights for a cozy, appetizing canteen ambience
	var light_specs := [
		[Vector3(0.0, 3.2, -2.5), Color("#ffe5b4"), 1.5, 9.5],
		[Vector3(-3.5, 3.1, 1.2), Color("#ffdba0"), 1.35, 8.5],
		[Vector3(3.5, 3.1, 1.2), Color("#ffdba0"), 1.35, 8.5],
		[Vector3(-3.5, 3.1, 4.2), Color("#ffdba0"), 1.3, 8.5],
		[Vector3(3.5, 3.1, 4.2), Color("#ffdba0"), 1.3, 8.5],
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

func build_campus_door(pos: Vector3, yaw: float) -> void:
	hall_door_pos = pos
	hall_return_pos = pos + Vector3(sin(yaw), 0.12, cos(yaw)) * 1.8

	var root := Node3D.new()
	root.name = "CampusCanteenDoor"
	root.position = hall_door_pos - position
	root.rotation.y = yaw
	add_child(root)

	var frame_mat := CampusBuilder.mat(Color("#2c343b"), 0.6)
	var door_wood := CampusBuilder.mat(Color("#a2542e"), 0.5)

	CampusBuilder.box(root, Vector3(2.6, 2.8, 0.3), Vector3(0, 1.4, 0), frame_mat, "Portal")
	CampusBuilder.box(root, Vector3(1.08, 2.3, 0.08), Vector3(-0.58, 1.15, 0.06), door_wood, "DoorL")
	CampusBuilder.box(root, Vector3(1.08, 2.3, 0.08), Vector3(0.58, 1.15, 0.06), door_wood, "DoorR")

	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.85, 0.92, 1.0, 0.45)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	CampusBuilder.box(root, Vector3(0.72, 1.1, 0.09), Vector3(-0.58, 1.4, 0.06), glass, "GlassL")
	CampusBuilder.box(root, Vector3(0.72, 1.1, 0.09), Vector3(0.58, 1.4, 0.06), glass, "GlassR")

	# Sign: "ANITS CANTEEN · SNACKS & DRINKS"
	_sign("ANITS CANTEEN", "SNACKS & BEVERAGES", Vector3(0, 2.95, 0.18), 0.0,
		Vector2(2.6, 0.48), Color("#c65a28"), Color("#ffd54a"), root)

	_door_node = Node3D.new()
	_door_node.name = "CanteenDoorInteract"
	_door_node.position = Vector3(0, 1.0, 0.8)
	_door_node.add_to_group("interactables")
	_door_node.add_to_group("canteen_door")
	root.add_child(_door_node)
