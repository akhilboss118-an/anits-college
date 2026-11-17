extends SceneTree
## Phase 0 headless test runner.
##   godot --headless --path <project> --script res://tests/run_tests.gd
## Asserts that the authored campus data still matches the values verified in
## docs/ (BUILDING_INVENTORY.md, CAMPUS_MAP.md, GAME_ANALYSIS.md).

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_deferred_run()


func _deferred_run() -> void:
	# Let the SceneTree deliver _ready() to nodes the tests add (the UI
	# overlays build their controls there) before exercising them.
	await process_frame
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
	_test_mission_all_days()
	_test_campaign_walk()
	_test_minigame_wins()
	_test_basketball()
	_test_new_systems()
	_test_audio_and_collection()


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
	_check("soda restores 20 energy", is_equal_approx(db.energy_per_drink(0), 20.0))
	_check("energy drink restores 35 energy", is_equal_approx(db.energy_per_drink(1), 35.0))
	_check("boost lasts 30 s", is_equal_approx(db.boost_seconds(), 30.0))

	# The four vending machines together must stock all ten drinks exactly
	# once, otherwise the Canteen Collection cannot be completed.
	var stocked: Dictionary = {}
	for machine in db.campus.get("vending_machines", []):
		for drink_id in (machine.get("stock", []) as Array):
			stocked[str(drink_id)] = true
	_eq("vending stock covers all drinks", stocked.size(), 10)
	var stock_known := true
	for drink_id in stocked.keys():
		if db.drink_by_id(str(drink_id)).is_empty():
			stock_known = false
	_check("vending stock ids exist in economy", stock_known)

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


func _test_campaign_walk() -> void:
	## Walks every day's real step machine to the end: NPC talks, gate ID
	## checks, plan/world position objectives, salutes, checks and minigames.
	## This catches soft-locks such as an interior objective authored in world
	## metres being fed through the plan-pixel converter.
	print("[campaign walk - all 10 days reach the end]")
	var mr := preload("res://src/autoload/mission_runner.gd").new()
	root.add_child(mr)
	var gs: Node = root.get_node_or_null("GameState")
	var ss: Node = root.get_node_or_null("SaveSystem")
	var wallet_before: int = gs.wallet if gs else 0
	var items_before: Dictionary = (gs.items as Dictionary).duplicate() if gs else {}

	for d in range(1, 11):
		mr.start_day(d)
		var guard := 0
		var idcheck_ok := true
		while not mr.finished and guard < 40:
			guard += 1
			var s: Dictionary = mr.current()
			var t := str(s.get("type", ""))
			match t:
				"npc":
					if bool(s.get("check_fee", false)) and gs and gs.wallet < 250:
						gs.wallet = 250
					var before := mr.index
					mr.notify_talked_to(str(s.get("npc", "")))
					if mr.index == before:
						break
				"idcheck":
					# Talking to the guard must NOT satisfy the gate check;
					# only the bag's SHOW ID button advances it.
					var before_id := mr.index
					mr.notify_talked_to("guard")
					if mr.index != before_id:
						idcheck_ok = false
					mr.advance()
				"at":
					var pos: Array = s.get("pos", [0, 0])
					var p: Vector3
					if bool(s.get("world", false)):
						p = Vector3(float(pos[0]), 0.0, float(pos[1]))
					else:
						p = Campus.map_to_world(Vector2(pos[0], pos[1]))
					mr.notify_position(p)
				"salute":
					mr.notify_salute()
				"chk":
					mr.notify_check(str(s.get("check", "")))
				"mini":
					mr.notify_minigame_won()
				_:
					break
		_check("day %d completes all steps" % d, mr.finished,
			"-> stopped at %d/%d (%s)" % [mr.index, mr.steps.size(), str(mr.current().get("text", ""))])
		_check("day %d ID check waits for the card" % d, idcheck_ok)

	# Tests must not leak wallet/items into the player's real profile.
	if gs:
		gs.wallet = wallet_before
		gs.items = items_before
	if ss and ss.has_method("save_items"):
		ss.save_items(items_before)
	mr.free()


func _test_minigame_wins() -> void:
	## Drives the real win path of every minigame used by the campaign.
	print("[minigame win paths]")
	var script := preload("res://src/ui/minigame_overlay.gd")

	var quiz: Node = script.new()
	root.add_child(quiz)
	quiz.start_minigame({"kind": "quiz", "title": "TEST", "need": 2, "qs": [
		["Q1", ["A", "B"], 0], ["Q2", ["A", "B"], 1]]})
	for i in 2:
		quiz._pick_quiz_opt(int(quiz._quiz_qs[i][2]))
	_check("quiz answers score a win", quiz._quiz_ok >= 2 and quiz._result_box.visible)
	quiz.free()

	var typing: Node = script.new()
	root.add_child(typing)
	typing.start_minigame({"kind": "typing", "title": "TEST", "need": 2,
		"words": ["SAMOSA", "CHAI"], "time_per_word": 10.0})
	for wi in 2:
		var word: String = ["SAMOSA", "CHAI"][wi]
		for ci in word.length():
			typing._handle_type_char(word.substr(ci, 1))
	_check("typing eats every samosa", typing._type_eaten >= 2 and typing._result_box.visible)
	typing.free()

	var drill: Node = script.new()
	root.add_child(drill)
	drill.start_minigame({"kind": "drill", "title": "TEST", "time": 30.0})
	for i in 25:
		drill._step_foot(i % 2)
	_check("drill reaches the 100 m mark", drill._drill_dist >= 100.0 and drill._result_box.visible)
	drill.free()

	var dance: Node = script.new()
	root.add_child(dance)
	dance.start_minigame({"kind": "dance", "title": "TEST", "time": 30.0})
	for i in 10:
		dance._hit_dance_move(int(dance._dance_target_move))
	_check("dance fills the crowd hype", dance._dance_hype >= 80.0 and dance._result_box.visible)
	dance.free()

	var mash: Node = script.new()
	root.add_child(mash)
	mash.start_minigame({"kind": "mash", "title": "TEST", "hits": 5, "secs": 8.0})
	for i in 5:
		mash._mash_hit()
	_check("mash challenge reaches its target", mash._mash_count >= 5 and mash._result_box.visible)
	mash.free()

	var cmd: Node = script.new()
	root.add_child(cmd)
	cmd.start_minigame({"kind": "cmd", "title": "TEST", "n": 4, "need": 4,
		"keys": ["ArrowUp", "ArrowLeft", "ArrowRight"]})
	for i in 4:
		cmd._handle_cmd_key(str(cmd._cmd_seq[cmd._cmd_idx]))
	_check("command QTE answers every call", cmd._cmd_ok >= 4 and cmd._result_box.visible)
	cmd.free()


func _test_basketball() -> void:
	## The shootout is a real aimed projectile now: a shot at the rim must drop
	## through, a wild shot must miss, and five aimed shots must win the event.
	print("[basketball shooting]")
	var court_script := preload("res://src/ui/basketball_court.gd")
	var court: Node = court_script.new()
	root.add_child(court)

	var result := [-1]
	court.shot_resolved.connect(func(hit: bool): result[0] = 1 if hit else 0)
	court.aim_at_rim()
	_check("court accepts the first shot", court.throw_ball())
	_drive_court(court, 400)
	_check("aimed shot drops through the hoop", result[0] == 1 and court.shots_hit == 1)

	court.reset_ball()
	result[0] = -1
	court.set_aim(Vector2(90.0, 30.0))
	court.throw_ball()
	_drive_court(court, 400)
	_check("wild shot misses the hoop", result[0] == 0 and court.shots_hit == 1)
	court.free()

	var overlay: Node = preload("res://src/ui/minigame_overlay.gd").new()
	root.add_child(overlay)
	overlay.start_minigame({"kind": "shoot", "title": "TEST", "shots": 5, "need": 3,
		"clock": 7.0, "reset_delay": 0.0})
	for i in 5:
		overlay._shoot_view.aim_at_rim()
		overlay._shoot_throw()
		_drive_court(overlay._shoot_view, 400)
	_check("five aimed shots win the shootout",
		overlay._shoot_hits >= 3 and overlay._result_box.visible)
	overlay.free()


func _drive_court(court: Node, frames: int) -> void:
	for i in frames:
		court._process(1.0 / 60.0)
		if not court.flying and not court._awaiting_result:
			return


func _test_mission_all_days() -> void:
	print("[mission runner - 10 days]")
	var mr := preload("res://src/autoload/mission_runner.gd").new()
	for d in range(1, 11):
		mr.start_day(d)
		_eq("day %d active" % d, mr.day, d)
		_check("day %d has steps" % d, mr.steps.size() >= 4, "-> %d steps" % mr.steps.size())
		var has_valid_fields := true
		for s in mr.steps:
			if not (s is Dictionary and s.has("text") and s.has("type")):
				has_valid_fields = false
				break
		_check("day %d steps valid format" % d, has_valid_fields)

	# Verify specific mechanics
	mr.start_day(2)
	_check("day 2 has bank withdrawal check", mr.steps.any(func(s): return s.get("type") == "chk" and s.get("check") == "bank"))

	mr.start_day(4)
	var d4_quiz := mr.steps.filter(func(s): return s.get("type") == "mini" and s.get("mini", {}).get("kind") == "quiz")
	_check("day 4 has library quiz", d4_quiz.size() == 1 and d4_quiz[0].mini.qs.size() == 3)

	mr.start_day(5)
	var d5_shoot := mr.steps.filter(func(s): return s.get("type") == "mini" and s.get("mini", {}).get("kind") == "shoot")
	_check("day 5 has basketball shootout", d5_shoot.size() == 1 and d5_shoot[0].mini.shots == 5)

	mr.start_day(6)
	var d6_drill := mr.steps.filter(func(s): return s.get("type") == "mini" and s.get("mini", {}).get("kind") == "drill")
	_check("day 6 has ncc drill running cadence", d6_drill.size() == 1 and d6_drill[0].mini.time >= 20.0)

	mr.start_day(8)
	var d8_typing := mr.steps.filter(func(s): return s.get("type") == "mini" and s.get("mini", {}).get("kind") == "typing")
	_check("day 8 has samosa typing eating", d8_typing.size() == 1 and d8_typing[0].mini.words.size() >= 5)

	mr.start_day(9)
	var d9_dance := mr.steps.filter(func(s): return s.get("type") == "mini" and s.get("mini", {}).get("kind") == "dance")
	_check("day 9 has fest dance battle with hype", d9_dance.size() == 1 and d9_dance[0].mini.target_hype >= 75.0)

	mr.start_day(10)
	var d10_quiz := mr.steps.filter(func(s): return s.get("type") == "mini" and s.get("mini", {}).get("kind") == "quiz")
	_check("day 10 has first class quiz", d10_quiz.size() == 1 and d10_quiz[0].mini.qs.size() == 4)

	mr.free()


func _test_new_systems() -> void:
	print("[new systems & interiors]")
	# Interiors
	var lib = preload("res://src/world/library_interior.gd").new()
	_check("library interior instances", lib != null)
	lib.free()

	var cls = preload("res://src/world/classroom_interior.gd").new()
	_check("classroom interior instances", cls != null)
	cls.free()

	var can = preload("res://src/world/canteen_interior.gd").new()
	_check("canteen interior instances", can != null)
	can.free()

	# UI Systems
	var minigame = preload("res://src/ui/minigame_overlay.gd").new()
	_check("minigame overlay instances", minigame != null)
	minigame.free()

	var inv = preload("res://src/ui/inventory_panel.gd").new()
	_check("inventory panel instances", inv != null)
	_check("inventory has default id", inv.has_item("id"))
	inv.add_item("receipt")
	_check("inventory add receipt works", inv.has_item("receipt"))
	inv.free()

	var dlg = preload("res://src/ui/level_complete_dialog.gd").new()
	_check("level complete dialog instances", dlg != null)
	_eq("lore lines count", dlg.COMPLETION_LINES.size(), 10)
	dlg.free()

	# Developer mode: persistent switch plus the unlock-all cap.
	var settings: Node = root.get_node_or_null("Settings")
	var prev_dev: bool = bool(settings.dev_mode) if settings else false
	if settings:
		settings.set_dev_mode(true)
		_check("developer mode turns on", settings.is_dev_mode())
		settings.set_dev_mode(false)
		_check("developer mode turns off", not settings.is_dev_mode())
		settings.set_dev_mode(prev_dev)
		var prev_gfx: String = str(settings.graphics_mode)
		settings.set_graphics_mode("fast")
		_eq("graphics profile saves fast", settings.graphics_mode, "fast")
		settings.set_graphics_mode("bogus")
		_eq("graphics profile rejects unknown", settings.graphics_mode, "auto")
		settings.set_graphics_mode(prev_gfx)
	var gs: Node = root.get_node_or_null("GameState")
	if gs:
		var prev_unlocked: int = gs.unlocked_day
		gs.unlocked_day = 1
		gs.unlock(9)
		_eq("day 9 completion unlocks day 10", gs.unlocked_day, 10)
		gs.unlock(10)
		_eq("unlocked day caps at 10", gs.unlocked_day, 10)
		gs.unlocked_day = prev_unlocked


func _test_audio_and_collection() -> void:
	print("[audio & canteen collection]")
	var audio: Node = root.get_node_or_null("Audio")
	_check("Audio autoload exists", audio != null)
	if audio:
		_check("Audio loads every SFX + ambience stream", audio.stream_count() >= 23,
			"-> %d" % audio.stream_count())
		for id in ["ui_click", "ui_back", "success", "error", "item", "step_1",
				"ball_bounce", "rim", "throw", "whistle", "coin", "cheer",
				"unlock", "fizz", "tired", "ambient_campus", "ambient_interior"]:
			_check("audio stream: %s" % id, audio.has_stream(id))

	var gs: Node = root.get_node_or_null("GameState")
	_check("GameState autoload exists", gs != null)
	var eb: Node = root.get_node_or_null("EventBus")
	var db: Node = root.get_node_or_null("CampusDB")
	if gs:
		var prev_energy: float = gs.energy
		var prev_drinks: Dictionary = (gs.drinks_tried as Dictionary).duplicate()
		var prev_items: Dictionary = (gs.items as Dictionary).duplicate()
		var depleted := [0]
		var on_depleted := func() -> void: depleted[0] += 1
		eb.energy_depleted.connect(on_depleted)

		gs.energy = 5.0
		gs.drain_energy(3.0)
		_check("sprint drain subtracts energy", is_equal_approx(gs.energy, 2.0),
			"-> %f" % gs.energy)
		gs.drain_energy(10.0)
		_check("energy clamps at zero", is_equal_approx(gs.energy, 0.0),
			"-> %f" % gs.energy)
		gs.drain_energy(5.0)
		_check("empty bar never goes negative", is_equal_approx(gs.energy, 0.0))
		_eq("depletion signal fires once", depleted[0], 1)
		gs.add_energy(20.0)
		_check("drink refills the bar", is_equal_approx(gs.energy, 20.0))
		eb.energy_depleted.disconnect(on_depleted)

		var unlocked := [0]
		var on_foodie := func() -> void: unlocked[0] += 1
		eb.foodie_unlocked.connect(on_foodie)
		gs.drinks_tried.clear()
		for drink in db.drinks:
			gs.try_drink(str(drink.get("id", "")))
		_eq("all ten drinks tracked", gs.drinks_tried_count(), 10)
		_check("ten drinks unlock the foodie badge", gs.has_item("foodie"))
		_eq("foodie signal fires once", unlocked[0], 1)
		eb.foodie_unlocked.disconnect(on_foodie)

		# Tests must not leak the collection into the player's profile.
		gs.energy = prev_energy
		gs.drinks_tried = prev_drinks
		gs.items = prev_items
		var ss: Node = root.get_node_or_null("SaveSystem")
		if ss and ss.has_method("save_items"):
			ss.save_items(prev_items)

	_check("player controller script present",
		ResourceLoader.exists("res://src/actors/player.gd"))
