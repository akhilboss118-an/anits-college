class_name ClassroomInterior
extends Node3D
## Room 204 (CSE Lecture Hall): walk-in classroom with student benches,
## lecturer dais, green chalkboard, overhead projector, rotating ceiling fans,
## and department notice board.
##
## Built far west of campus in the interior zone at Vector3(-320, 0, 120).

const CENTER := Vector3(-320.0, 0.0, 120.0)
const HALF_W := 6.5
const HALF_D := 5.5
const HEIGHT := 3.6
const DADO_TOP := 1.1

# ------------------------------------------------------------------ palette
const FLOOR_GRANITE := Color("#5a6065")
const WALL_PALE := Color("#eef3f1")
const DADO_TEAL := Color("#1c4238")
const CHALKBOARD := Color("#172e22")
const DESK_WOOD := Color("#b37d4e")
const DESK_FRAME := Color("#32373d")
const CEILING := Color("#ecefe9")
const CHALKW_WHITE := Color("#f8f9fa")

# ------------------------------------------------------------------ public API
var entry_pos := CENTER + Vector3(4.8, 0.12, 4.0)
var exit_pos := CENTER + Vector3(5.6, 0.12, 4.0)
var lecturer_pos := CENTER + Vector3(0.0, 0.15, -3.8)
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
	_build_dais_and_blackboard()
	_build_student_benches()
	_build_ceiling_fans()
	_build_notices()
	_build_lights()


func _process(delta: float) -> void:
	# Slowly rotate the ceiling fans
	var rot := delta * 4.2
	for fan in _fans:
		if is_instance_valid(fan):
			fan.rotate_y(rot)


func _mat(key: String) -> StandardMaterial3D:
	return _mats.get(key, null) as StandardMaterial3D


func _build_materials() -> void:
	var m_floor := StandardMaterial3D.new()
	m_floor.albedo_color = FLOOR_GRANITE
	m_floor.roughness = 0.6
	_mats["floor"] = m_floor

	var m_wall := StandardMaterial3D.new()
	m_wall.albedo_color = WALL_PALE
	m_wall.roughness = 0.9
	_mats["wall"] = m_wall

	var m_dado := StandardMaterial3D.new()
	m_dado.albedo_color = DADO_TEAL
	m_dado.roughness = 0.75
	_mats["dado"] = m_dado

	var m_board := StandardMaterial3D.new()
	m_board.albedo_color = CHALKBOARD
	m_board.roughness = 0.8
	_mats["board"] = m_board

	var m_wood := StandardMaterial3D.new()
	m_wood.albedo_color = DESK_WOOD
	m_wood.roughness = 0.65
	_mats["wood"] = m_wood

	var m_frame := StandardMaterial3D.new()
	m_frame.albedo_color = DESK_FRAME
	m_frame.metallic = 0.7
	m_frame.roughness = 0.35
	_mats["frame"] = m_frame

	var m_ceiling := StandardMaterial3D.new()
	m_ceiling.albedo_color = CEILING
	m_ceiling.roughness = 0.95
	_mats["ceiling"] = m_ceiling


func _build_shell() -> void:
	# Floor and ceiling
	CampusBuilder.box(self, Vector3(HALF_W * 2.0, 0.2, HALF_D * 2.0),
		Vector3(0, -0.08, 0), _mat("floor"), "Floor")
	CampusBuilder.box(self, Vector3(HALF_W * 2.0, 0.2, HALF_D * 2.0),
		Vector3(0, HEIGHT + 0.1, 0), _mat("ceiling"), "Ceiling")

	CampusBuilder.add_collider(self, Vector3(HALF_W * 2.0, 0.2, HALF_D * 2.0),
		Vector3(0, -0.08, 0), "FloorCol")
	CampusBuilder.add_collider(self, Vector3(HALF_W * 2.0, 0.2, HALF_D * 2.0),
		Vector3(0, HEIGHT + 0.1, 0), "CeilCol")

	# North wall (front - where chalkboard sits)
	_wall(-HALF_W, HALF_W, -HALF_D, -HALF_D + 0.2)
	# South wall (back)
	_wall(-HALF_W, HALF_W, HALF_D - 0.2, HALF_D)
	# West wall
	_wall(-HALF_W, -HALF_W + 0.2, -HALF_D, HALF_D)

	# East wall (with entrance doorway at Z from 3.0 to 4.8)
	_wall(HALF_W - 0.2, HALF_W, -HALF_D, 3.0)
	_wall(HALF_W - 0.2, HALF_W, 4.8, HALF_D)
	# Header over east doorway
	var hdr_size := Vector3(0.2, HEIGHT - 2.4, 1.8)
	var hdr_pos := Vector3(HALF_W - 0.1, (HEIGHT + 2.4) * 0.5, 3.9)
	CampusBuilder.box(self, hdr_size, hdr_pos, _mat("wall"), "EastDoorHeader")
	CampusBuilder.add_collider(self, hdr_size, hdr_pos - Vector3(0, hdr_size.y * 0.5, 0), "EastHdrCol")


func _wall(x0: float, x1: float, z0: float, z1: float) -> void:
	var size := Vector3(absf(x1 - x0), HEIGHT, absf(z1 - z0))
	var centre := Vector3((x0 + x1) * 0.5, HEIGHT * 0.5, (z0 + z1) * 0.5)

	CampusBuilder.box(self, Vector3(size.x, DADO_TOP, size.z),
		Vector3(centre.x, DADO_TOP * 0.5, centre.z), _mat("dado"), "DadoWall")
	CampusBuilder.box(self, Vector3(size.x + 0.02, 0.04, size.z + 0.02),
		Vector3(centre.x, DADO_TOP, centre.z), _mat("wood"), "DadoRail")
	CampusBuilder.box(self, Vector3(size.x, HEIGHT - DADO_TOP, size.z),
		Vector3(centre.x, (DADO_TOP + HEIGHT) * 0.5, centre.z), _mat("wall"), "UpperWall")

	CampusBuilder.add_collider(self, size, centre - Vector3(0, HEIGHT * 0.5, 0), "WallCol")


func _build_dais_and_blackboard() -> void:
	# Elevated teacher's platform (15 cm high across North wall)
	var dais_size := Vector3(9.0, 0.15, 2.2)
	var dais_pos := Vector3(0.0, 0.075, -HALF_D + 1.2)
	CampusBuilder.box(self, dais_size, dais_pos, _mat("wood"), "TeacherDais")
	CampusBuilder.add_collider(self, dais_size, dais_pos - Vector3(0, 0.075, 0), "DaisCol")

	# Lecturer's Desk on dais
	var desk := Node3D.new()
	desk.name = "LecturerDesk"
	desk.position = Vector3(1.2, 0.15, -HALF_D + 1.1)
	add_child(desk)
	CampusBuilder.box(desk, Vector3(1.6, 0.06, 0.8), Vector3(0, 0.75, 0), _mat("wood"), "DeskTop")
	CampusBuilder.box(desk, Vector3(1.5, 0.72, 0.7), Vector3(0, 0.36, 0), _mat("frame"), "DeskBase")
	CampusBuilder.add_collider(desk, Vector3(1.6, 0.75, 0.8), Vector3(0, 0.0, 0), "DeskCol")

	# Laptop and attendance register
	CampusBuilder.box(desk, Vector3(0.36, 0.02, 0.26), Vector3(-0.35, 0.79, 0.05),
		CampusBuilder.mat(Color("#2a3036"), 0.3), "LaptopBase")
	var l_screen := CampusBuilder.box(desk, Vector3(0.36, 0.24, 0.02), Vector3(-0.35, 0.9, -0.07),
		CampusBuilder.mat(Color("#1a2530"), 0.3), "LaptopScreen")
	l_screen.rotation.x = deg_to_rad(-15.0)

	CampusBuilder.box(desk, Vector3(0.32, 0.03, 0.44), Vector3(0.4, 0.79, 0.05),
		CampusBuilder.mat(Color("#8a3324"), 0.7), "RegisterBook")

	# Wooden podium / lectern
	var lectern := Node3D.new()
	lectern.name = "Lectern"
	lectern.position = Vector3(-1.8, 0.15, -HALF_D + 1.1)
	add_child(lectern)
	CampusBuilder.box(lectern, Vector3(0.65, 1.15, 0.55), Vector3(0, 0.575, 0), _mat("wood"), "LecternBody")
	CampusBuilder.add_collider(lectern, Vector3(0.65, 1.15, 0.55), Vector3(0, 0.0, 0), "LecternCol")
	# Slanted top
	var top := CampusBuilder.box(lectern, Vector3(0.68, 0.04, 0.58), Vector3(0, 1.18, 0), _mat("wood"), "LecternTop")
	top.rotation.x = deg_to_rad(12.0)
	# Gooseneck microphone
	CampusBuilder.box(lectern, Vector3(0.02, 0.22, 0.02), Vector3(-0.15, 1.28, 0.0),
		CampusBuilder.mat(Color("#888888"), 0.4), "MicStem")
	CampusBuilder.box(lectern, Vector3(0.04, 0.06, 0.04), Vector3(-0.15, 1.38, 0.0),
		CampusBuilder.mat(Color("#222222"), 0.3), "MicHead")

	# Huge Green Chalkboard (5.5m wide, 1.5m tall on North wall)
	var board_pos := Vector3(0.0, 1.95, -HALF_D + 0.22)
	CampusBuilder.box(self, Vector3(5.6, 1.5, 0.04), board_pos, _mat("board"), "Chalkboard")
	CampusBuilder.box(self, Vector3(5.66, 1.56, 0.02), board_pos - Vector3(0, 0, 0.01),
		CampusBuilder.mat(Color("#c2c7cc"), 0.4), "BoardFrame")
	CampusBuilder.box(self, Vector3(5.66, 0.06, 0.12), board_pos - Vector3(0, 0.77, -0.04),
		CampusBuilder.mat(Color("#a2a7ac"), 0.4), "ChalkTray")

	# Chalk notes written on board
	_board_label("CSE 204: DATA STRUCTURES & ALGORITHMS", Vector3(-1.4, 2.45, -HALF_D + 0.25), 24, Color("#ffffff"))
	_board_label("Topic: Binary Search Trees & AVL Balancing", Vector3(-1.1, 2.22, -HALF_D + 0.25), 18, Color("#e2f0d9"))
	_board_label("Time: Best O(1) | Worst O(n) | Avg O(log n)", Vector3(-1.0, 1.98, -HALF_D + 0.25), 17, Color("#fff2cc"))
	_board_label("Lab Exam: 2:00 PM today - Prof. Rao", Vector3(-1.3, 1.65, -HALF_D + 0.25), 18, Color("#fce4d6"))

	# Pull-down white projector screen above board
	CampusBuilder.box(self, Vector3(3.4, 0.12, 0.12), Vector3(0.0, 3.35, -HALF_D + 0.26),
		CampusBuilder.mat(Color("#ffffff"), 0.4), "ScreenCase")
	CampusBuilder.box(self, Vector3(3.2, 0.5, 0.02), Vector3(0.0, 3.08, -HALF_D + 0.28),
		CampusBuilder.mat(Color("#f0f4f8"), 0.2), "ScreenPulldown")

	# Ceiling digital projector
	var proj := Node3D.new()
	proj.position = Vector3(0.0, HEIGHT - 0.45, -1.0)
	add_child(proj)
	CampusBuilder.box(proj, Vector3(0.06, 0.45, 0.06), Vector3(0, 0.22, 0), _mat("frame"), "Mount")
	CampusBuilder.box(proj, Vector3(0.44, 0.18, 0.38), Vector3(0, 0, 0),
		CampusBuilder.mat(Color("#ffffff"), 0.3), "ProjectorBody")
	# Lens
	CampusBuilder.box(proj, Vector3(0.08, 0.08, 0.06), Vector3(0, -0.02, -0.2),
		CampusBuilder.mat(Color("#1a4d7a"), 0.2, 0.8), "Lens")


func _board_label(text: String, pos: Vector3, size: int, col: Color) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = size
	lbl.modulate = col
	lbl.outline_size = 2
	lbl.outline_modulate = Color(0, 0, 0, 0.4)
	lbl.position = pos
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(lbl)


func _build_student_benches() -> void:
	# 4 Rows of student desks, 2 columns (left and right with central aisle)
	# Left column: X = -2.8, Right column: X = 2.8
	var row_z := [-1.2, 0.4, 2.0, 3.6]
	var col_x := [-2.8, 2.8]

	for rx in col_x:
		for rz in row_z:
			var desk := Node3D.new()
			desk.name = "StudentBench_%.1f_%.1f" % [rx, rz]
			desk.position = Vector3(rx, 0.0, rz)
			add_child(desk)

			# Desk Top: W 2.4m, D 0.48m, H 0.72m
			CampusBuilder.box(desk, Vector3(2.4, 0.04, 0.48), Vector3(0, 0.72, 0), _mat("wood"), "DeskTop")
			CampusBuilder.add_collider(desk, Vector3(2.4, 0.72, 0.48), Vector3(0, 0.0, 0), "DeskCol")

			# Metal tubular frame for desk
			for lx in [-1.05, 1.05]:
				CampusBuilder.box(desk, Vector3(0.04, 0.72, 0.42), Vector3(lx, 0.36, 0), _mat("frame"), "Leg")

			# Attached bench seat behind desk: Z + 0.48m, H 0.44m
			CampusBuilder.box(desk, Vector3(2.4, 0.04, 0.32), Vector3(0, 0.44, 0.52), _mat("wood"), "BenchSeat")
			CampusBuilder.box(desk, Vector3(2.4, 0.26, 0.03), Vector3(0, 0.68, 0.67), _mat("wood"), "BenchBack")

			for lx in [-1.05, 1.05]:
				CampusBuilder.box(desk, Vector3(0.04, 0.44, 0.04), Vector3(lx, 0.22, 0.52), _mat("frame"), "BenchLeg")

			# Random student props on some desks
			if int(rx + rz) % 2 == 0:
				CampusBuilder.box(desk, Vector3(0.24, 0.02, 0.32), Vector3(-0.4, 0.75, 0),
					CampusBuilder.mat(Color("#34495e"), 0.7), "Notebook")
				CampusBuilder.box(desk, Vector3(0.02, 0.01, 0.16), Vector3(-0.15, 0.75, 0),
					CampusBuilder.mat(Color("#3498db"), 0.4), "Pen")

			# Student desk interactable seating node
			var seat := Node3D.new()
			seat.name = "ClassroomDeskSeat"
			seat.position = Vector3(rx, 0.44, rz + 0.52)
			seat.add_to_group("interactables")
			seat.add_to_group("classroom_seat")
			add_child(seat)


func _build_ceiling_fans() -> void:
	# 4 Ceiling fans spaced evenly across the ceiling
	var fan_pos := [
		Vector3(-2.8, HEIGHT, -1.5),
		Vector3(2.8, HEIGHT, -1.5),
		Vector3(-2.8, HEIGHT, 2.0),
		Vector3(2.8, HEIGHT, 2.0),
	]
	for p in fan_pos:
		var root := Node3D.new()
		root.position = p
		add_child(root)

		# Down-rod and canopy
		CampusBuilder.box(root, Vector3(0.04, 0.45, 0.04), Vector3(0, -0.22, 0), _mat("frame"), "Downrod")
		CampusBuilder.box(root, Vector3(0.18, 0.08, 0.18), Vector3(0, -0.04, 0), _mat("frame"), "Canopy")

		# Rotating blade hub
		var hub := Node3D.new()
		hub.name = "FanHub"
		hub.position = Vector3(0, -0.45, 0)
		root.add_child(hub)
		CampusBuilder.box(hub, Vector3(0.22, 0.08, 0.22), Vector3.ZERO, _mat("frame"), "Motor")

		# 3 aerodynamic blades
		for i in 3:
			var blade := Node3D.new()
			blade.rotation.y = i * (PI * 2.0 / 3.0)
			hub.add_child(blade)
			CampusBuilder.box(blade, Vector3(0.14, 0.01, 0.72), Vector3(0, 0, 0.42),
				CampusBuilder.mat(Color("#4a525a"), 0.4), "Blade")

		_fans.append(hub)


func _build_notices() -> void:
	# Timetable on East wall
	_sign("CSE 1ST YEAR (SECTION B)", "PERIOD 1: Data Structures\nPERIOD 2: Engineering Physics\nPERIOD 3: Math-II\nLUNCH: 12:30 - 1:15 PM\nPERIOD 4-6: Programming Lab",
		Vector3(HALF_W - 0.22, 2.1, 0.5), -PI * 0.5, Vector2(2.4, 1.2), Color("#243342"), Color.WHITE)

	# Room number plate over East doorway
	_sign("ROOM 204", "CSE DEPARTMENT", Vector3(HALF_W - 0.22, 2.85, 3.9), -PI * 0.5,
		Vector2(1.6, 0.42), Color("#1c4238"), Color("#ffd54a"))

	# Wall clock above chalkboard
	var clock := CylinderMesh.new()
	clock.top_radius = 0.3
	clock.bottom_radius = 0.3
	clock.height = 0.05
	var cmi := MeshInstance3D.new()
	cmi.mesh = clock
	cmi.material_override = CampusBuilder.mat(Color("#ffffff"), 0.2)
	cmi.rotation.x = PI * 0.5
	cmi.position = Vector3(0.0, 3.1, -HALF_D + 0.23)
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
	# 4 ceiling fluorescent troffers
	var tube_mat := StandardMaterial3D.new()
	tube_mat.albedo_color = Color("#ffffff")
	tube_mat.emission_enabled = true
	tube_mat.emission = Color("#eef6ff")
	tube_mat.emission_energy_multiplier = 1.3

	for lx in [-2.8, 2.8]:
		for lz in [-2.0, 1.8]:
			var pos := Vector3(lx, HEIGHT - 0.02, lz)
			CampusBuilder.box(self, Vector3(1.8, 0.06, 0.45), pos,
				CampusBuilder.mat(Color("#2c343b"), 0.5), "TubeHousing")
			CampusBuilder.box(self, Vector3(1.6, 0.02, 0.35), pos - Vector3(0, 0.03, 0),
				tube_mat, "TubeDiffuser")

	# 4 OmniLights for bright classroom illumination
	var light_specs := [
		[Vector3(-2.8, 3.1, -2.0), Color("#f2f8ff"), 1.35, 8.5],
		[Vector3(2.8, 3.1, -2.0), Color("#f2f8ff"), 1.35, 8.5],
		[Vector3(-2.8, 3.1, 1.8), Color("#f2f8ff"), 1.3, 8.5],
		[Vector3(2.8, 3.1, 1.8), Color("#f2f8ff"), 1.3, 8.5],
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
	root.name = "Classroom204Door"
	root.position = hall_door_pos - position
	root.rotation.y = yaw
	add_child(root)

	var frame_mat := CampusBuilder.mat(Color("#2c343b"), 0.6)
	var door_wood := CampusBuilder.mat(DESK_WOOD, 0.5)

	CampusBuilder.box(root, Vector3(1.8, 2.7, 0.25), Vector3(0, 1.35, 0), frame_mat, "Portal")
	CampusBuilder.box(root, Vector3(1.35, 2.25, 0.08), Vector3(0, 1.15, 0.05), door_wood, "DoorLeaf")

	# Glass vision panel
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.85, 0.92, 1.0, 0.45)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	CampusBuilder.box(root, Vector3(0.42, 0.75, 0.09), Vector3(0, 1.45, 0.05), glass, "VisionGlass")

	# Sign: "ROOM 204 · CSE LECTURE HALL"
	_sign("ROOM 204", "CSE DEPARTMENT", Vector3(0, 2.82, 0.15), 0.0,
		Vector2(1.8, 0.42), Color("#1c4238"), Color("#ffd54a"), root)

	# Overhead architectural canopy
	CampusBuilder.box(root, Vector3(2.2, 0.12, 1.1), Vector3(0, 3.12, 0.55), frame_mat, "Canopy")

	# Warm entrance lantern light
	var lantern := OmniLight3D.new()
	lantern.name = "DoorLantern"
	lantern.position = Vector3(0, 2.92, 0.55)
	lantern.light_color = Color(1.0, 0.94, 0.75)
	lantern.light_energy = 2.4
	lantern.omni_range = 6.5
	lantern.shadow_enabled = false
	root.add_child(lantern)

	# High-visibility billboard beacon sign above door
	var badge := Label3D.new()
	badge.name = "DoorBillboard"
	badge.text = "★ ROOM 204 ★\nCSE LECTURE HALL"
	badge.font_size = 28
	badge.modulate = Color(1.0, 0.88, 0.28)
	badge.outline_modulate = Color(0.04, 0.08, 0.16)
	badge.outline_size = 6
	badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	badge.no_depth_test = true
	badge.position = Vector3(0, 3.82, 0.2)
	root.add_child(badge)

	# Ground entrance mat with guide text
	var mat_node := Node3D.new()
	mat_node.position = Vector3(0, 0.03, 0.9)
	CampusBuilder.box(mat_node, Vector3(2.0, 0.02, 1.4), Vector3.ZERO, CampusBuilder.mat(Color("#1c4238"), 0.8), "MatBase")
	var mat_label := Label3D.new()
	mat_label.text = "► ENTER ROOM 204 ◄"
	mat_label.font_size = 22
	mat_label.rotation_degrees = Vector3(-90, 0, 0)
	mat_label.modulate = Color(1.0, 0.85, 0.3)
	mat_label.outline_size = 5
	mat_label.outline_modulate = Color(0, 0, 0)
	mat_label.position = Vector3(0, 0.02, 0)
	mat_node.add_child(mat_label)
	root.add_child(mat_node)

	# Interact trigger node directly in front of door
	_door_node = Node3D.new()
	_door_node.name = "ClassroomDoorInteract"
	_door_node.position = Vector3(0, 1.0, 0.8)
	_door_node.add_to_group("interactables")
	_door_node.add_to_group("classroom_door")
	root.add_child(_door_node)
