extends SceneTree
## Phase 0 headless test runner.
##   godot --headless --path <project> --script res://tests/run_tests.gd
## Asserts that the authored campus data still matches the values verified in
## docs/ (BUILDING_INVENTORY.md, CAMPUS_MAP.md, GAME_ANALYSIS.md).

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	print("=== ANITS Phase 0 test suite ===")
	_run_all()
	print("--- %d checks, %d failures ---" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _run_all() -> void:
	_test_coordinate_system()
	_test_campus_data()
	_test_npc_census()
	_test_economy_data()
	_test_lcg_determinism()


# ---------------------------------------------------------------- helpers

func _check(label: String, condition: bool, detail: String = "") -> void:
	_checks += 1
	if condition:
		print("  PASS  %s" % label)
	else:
		_failures += 1
		print("  FAIL  %s %s" % [label, detail])


func _eq(label: String, actual: Variant, expected: Variant) -> void:
	_check(label, actual == expected, "-> got %s, expected %s" % [actual, expected])


## JSON numbers come back as floats - compare numeric arrays element by element.
func _arr_eq(label: String, actual: Variant, expected: Array) -> void:
	var ok := typeof(actual) == TYPE_ARRAY and (actual as Array).size() == expected.size()
	if ok:
		for i in expected.size():
			if not is_equal_approx(float((actual as Array)[i]), float(expected[i])):
				ok = false
				break
	_check(label, ok, "-> got %s, expected %s" % [actual, expected])


# ---------------------------------------------------------------- tests

func _test_coordinate_system() -> void:
	print("[coordinate system]")
	var p := Vector2(122, 448)
	var w := Campus.map_to_world(p)
	_check("spawn world X", is_equal_approx(w.x, -65.1), "-> %f" % w.x)
	_check("spawn world Z", is_equal_approx(w.z, 138.6), "-> %f" % w.z)
	var back := Campus.world_to_map(w)
	_check("round trip", back.is_equal_approx(p), "-> %s" % back)
	_eq("campus width m", snappedf(Campus.campus_size_m().x, 0.1), 217.0)
	_eq("campus depth m", snappedf(Campus.campus_size_m().y, 0.1), 261.8)
	_eq("map scale", Campus.MAP_SCALE, 0.7)


func _test_campus_data() -> void:
	print("[campus data]")
	var db := preload("res://src/autoload/campus_db.gd").new()
	_check("campus_data.json loads", db.load_all())
	_eq("buildings", db.building_list.size(), 17)
	_eq("roads", (db.campus.get("roads", []) as Array).size(), 12)
	# the campus is ringed by a perimeter service road outside the boundary wall
	var roads: Array = db.campus.get("roads", [])
	_check("perimeter road north", roads.any(func(r): return r[1] < 58 and r[3] <= 58))
	_check("perimeter road west", roads.any(func(r): return r[0] < 58 and r[2] <= 58))
	_check("perimeter road east", roads.any(func(r): return r[0] >= 368))
	_check("perimeter road south", roads.any(func(r): return r[3] >= 432))
	_eq("zones", (db.campus.get("zones", {}) as Dictionary).size(), 5)
	_eq("walls", (db.campus.get("walls", []) as Array).size(), 6)
	_eq("gates", (db.campus.get("gates", []) as Array).size(), 2)
	_eq("lamps", (db.campus.get("props", {}) as Dictionary).get("lamps"), 14)
	_eq("benches", (db.campus.get("props", {}) as Dictionary).get("benches"), 7)
	_eq("vending machines", (db.campus.get("props", {}) as Dictionary).get("vending_machines"), 4)
	_eq("cars", (db.campus.get("props", {}) as Dictionary).get("cars"), 91)
	_eq("trees", (db.campus.get("props", {}) as Dictionary).get("trees"), 150)
	_eq("bushes", (db.campus.get("props", {}) as Dictionary).get("bushes"), 130)
	_eq("grass instances", (db.campus.get("props", {}) as Dictionary).get("grass_instances"), 4200)

	var cse := db.building_by_name("CSE Block")
	_arr_eq("CSE rect", cse.get("rect", []), [100, 248, 155, 279])
	_eq("CSE height", cse.get("height"), 11.5)
	_eq("CSE tint", cse.get("tint"), "#cfe3ff")
	# The four panel blocks form a clean 2x2 grid: equal 31 px depth, shared
	# x edges per column, and 2 px clear of every road.
	var ece := db.building_by_name("ECE Block")
	_arr_eq("ECE rect", ece.get("rect", []), [173, 248, 232, 279])
	var eee := db.building_by_name("EEE Block")
	_arr_eq("EEE rect", eee.get("rect", []), [173, 206, 232, 237])
	var chem := db.building_by_name("Chemical Block")
	_arr_eq("Chemical rect", chem.get("rect", []), [100, 206, 155, 237])
	_check("ECE/EEE share column", ece.get("rect")[0] == eee.get("rect")[0]
		and ece.get("rect")[2] == eee.get("rect")[2])
	_check("panel grid rows equal", ece.get("rect")[3] - ece.get("rect")[1]
		== chem.get("rect")[3] - chem.get("rect")[1])
	var admin := db.building_by_name("ADMIN BLOCK")
	_eq("ADMIN rendered height", admin.get("rendered_height"), 16.954)

	var player := db.player_tuning()
	_eq("walk speed", player.get("walk_speed"), 2.4)
	_eq("run speed", player.get("run_speed"), 5.6)
	_eq("boost multiplier", player.get("boost_multiplier"), 1.3)
	_eq("camera distance", player.get("camera_distance"), 5.4)
	_eq("interact radius", player.get("interact_radius"), 3.8)

	var spawn: Array = (db.campus.get("spawn", {}) as Dictionary).get("pos", [])
	var spawn_world := Campus.map_to_world(Vector2(spawn[0], spawn[1]))
	# the spawn sits on the approach road, just outside the main gate
	_check("spawn matches player data", is_equal_approx(spawn_world.x, -65.1) and is_equal_approx(spawn_world.z, 148.4))
	db.free()


func _test_npc_census() -> void:
	print("[npc census]")
	var db := preload("res://src/autoload/campus_db.gd").new()
	db.load_all()
	_eq("total npcs", db.npc_list.size(), 64)

	var groups := {}
	for npc in db.npc_list:
		var group: String = npc.get("group", "main")
		groups[group] = int(groups.get(group, 0)) + 1
	_eq("main", groups.get("main", 0), 6)
	_eq("cadets", groups.get("cadet", 0), 18)
	_eq("route students", groups.get("route_student", 0), 9)
	_eq("basketball players", groups.get("basketball", 0), 3)
	_eq("named walkers", groups.get("named_walker", 0), 10)
	_eq("standing groups", groups.get("standing", 0), 8)
	_eq("remy", groups.get("remy", 0), 1)
	_eq("girls", groups.get("girl", 0), 9)

	var guard := db.main_npc("guard")
	_arr_eq("guard position", guard.get("pos", []), [134, 438])
	var colonel := db.main_npc("colonel")
	_arr_eq("colonel position", colonel.get("pos", []), [214, 396])
	_check("colonel dialogue present", (colonel.get("lines", {}) as Dictionary).get("steps", {}).has("6"))
	db.free()


func _test_economy_data() -> void:
	print("[economy]")
	var db := preload("res://src/autoload/campus_db.gd").new()
	db.load_all()
	_eq("drinks", db.drinks.size(), 10)
	_eq("noodles", db.noodles.size(), 4)
	_eq("items", db.items.size(), 3)
	_eq("red bull price", db.drink_by_id("redbull").get("price"), 60)
	_eq("happy faces price", db.drink_by_id("happy").get("price"), 20)
	_eq("buldak price", db.noodle_by_id("buldak").get("price"), 150)
	_eq("buldak energy", db.noodle_by_id("buldak").get("energy"), 50)
	_check("buldak is spicy", db.noodle_by_id("buldak").get("hot", false))

	var tuning := db.economy_tuning()
	_eq("start wallet", tuning.get("start_wallet"), 200)
	_eq("start bank", tuning.get("start_bank"), 2000)
	_eq("fee", tuning.get("fee"), 250)
	_eq("start energy", tuning.get("start_energy"), 40)
	_eq("max energy", tuning.get("max_energy"), 100)
	db.free()


func _test_lcg_determinism() -> void:
	print("[seeded generator]")
	var a := LCG.new(5)
	var b := LCG.new(5)
	var same := true
	for i in 50:
		if not is_equal_approx(a.randf(), b.randf()):
			same = false
			break
	_check("same seed gives same stream", same)

	var c := LCG.new(5)
	var first := c.randf()
	var d := LCG.new(5)
	_check("first value reproducible", is_equal_approx(first, d.randf()))
	_check("values in [0,1)", first >= 0.0 and first < 1.0)
