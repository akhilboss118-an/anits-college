extends Node
## The mission state machine for all 10 Days of ANITS College Simulation.
## Faithfully ports the original's step schema from js/levels.js & js/game.js.
##
## Step fields:
##   - text: prompt text displayed in the HUD
##   - type: "npc" | "at" | "salute" | "mini" | "chk" | "idcheck" | "interior"
##   - npc: target npc id
##   - pos: [plan_x, plan_z], radius: metres
##   - mini: minigame configuration
##   - lines: custom dialogue override for NPCs
##   - say: toast notification spoken by player/narrator

signal step_changed(index: int, total: int, text: String)
signal completed(day: int)
signal minigame_triggered(config: Dictionary)

const DAY1 := [
	{"text": "Talk to Security Guard Bajirao beside the main gate (press E near him).",
	 "type": "npc", "npc": "guard", "line": "0", "say": "You: First day at ANITS... let us go in!"},
	{"text": "Walk through the ANITS main gate. (Hold Shift to run)",
	 "type": "at", "pos": [122, 396], "radius": 12},
	{"text": "Go to the Admin Block and talk to Laksmi (Admin).",
	 "type": "npc", "npc": "clerk", "line": "2"},
	{"text": "Meet Prof. Rao at the CSE Block.",
	 "type": "npc", "npc": "prof", "line": "3"},
	{"text": "Collect your lab manual from Suresh at the IT Block.",
	 "type": "npc", "npc": "suresh", "line": "4"},
	{"text": "Meet your friend Arjun at the Canteen.",
	 "type": "npc", "npc": "arjun", "line": "5"},
	{"text": "Go to the Open Auditorium grounds and salute the NCC cadets (press G near Colonel Singh).",
	 "type": "salute"},
	{"text": "Talk to Colonel Singh.",
	 "type": "npc", "npc": "colonel", "line": "7"},
]

var day: int = 1
var steps: Array = []
var index: int = -1
var finished: bool = false
var active: bool = false
var player_position: Vector3 = Vector3.ZERO


func start_day(new_day: int) -> void:
	day = clampi(new_day, 1, 10)
	finished = false
	active = true
	if day == 1:
		steps = DAY1.duplicate(true)
	else:
		steps = _build_day_steps(day)
	index = -1
	var vb: Node = get_node_or_null("/root/VoiceBank") if is_inside_tree() else null
	if vb and vb.has_method("stop_all"):
		vb.stop_all()
	advance()


func _build_day_steps(d: int) -> Array:
	var id_gate := [
		{"text": "Show your ID card to Security Guard Bajirao at the main gate (press E near him).",
		 "type": "idcheck", "npc": "guard",
		 "lines": {"guard": ["Stop! Students need to show their ID card at the gate.", "Press B to open your bag and show your ID card."]}},
		{"text": "Walk through the main gate and into the college.",
		 "type": "at", "pos": [122, 396], "radius": 12},
	]

	var body: Array = []
	match d:
		2: # Pay the Fees
			body = [
				{"text": "Go to Laksmi (Admin) in the Admin Block and ask for your fee slip.",
				 "type": "npc", "npc": "clerk",
				 "lines": {"clerk": ["Fees? Yes, here is your fee slip. The total is Rs. 250.", "Withdraw cash from the bank ATM first, then come back to pay me."]}},
				{"text": "Withdraw at least Rs. 250 from the bank ATM (press E near the bank).",
				 "type": "chk", "check": "bank"},
				{"text": "Pay the fees to Laksmi (Admin) at the Admin Block.",
				 "type": "npc", "npc": "clerk", "check_fee": true,
				 "lines": {"clerk": ["Thank you! Rs. 250 received. Here is your receipt.", "Now show this stamped receipt to Prof. Rao."]}},
				{"text": "Show the fee receipt to Prof. Rao at the CSE Block.",
				 "type": "npc", "npc": "prof",
				 "lines": {"prof": ["Ah, the fee receipt. Very good, you are officially an ANITS student!"]}}
			]

		3: # Find Your Classroom
			body = [
				{"text": "Ask Prof. Rao where your classroom is.",
				 "type": "npc", "npc": "prof",
				 "lines": {"prof": ["Your classroom? Head to Room 204 in the CSE Block!", "Look for the gold sign along the east corridor. Hurry, first bell rings soon!"]}},
				{"text": "Go to Room 204 at the CSE Block corridor.",
				 "type": "at", "pos": [155, 263.5], "radius": 7, "say": "You: Room 204! Let's head inside."},
				{"text": "Enter Room 204 and find your desk.",
				 "type": "at", "pos": [-320, 120], "world": true, "radius": 14,
				 "say": "You: Wow, proper lecture hall! Arjun is waving over there."},
				{"text": "Talk to your classmate Arjun in Room 204.",
				 "type": "npc", "npc": "arjun",
				 "lines": {"arjun": ["Hey! Over here! I saved you a desk seat in the front row!", "Sit down and let's get ready for our classes!"]}}
			]

		4: # Library Card
			body = [
				{"text": "Collect the library card form from Laksmi (Admin).",
				 "type": "npc", "npc": "clerk",
				 "lines": {"clerk": ["A library card? Fill this form, then go to the Central Library.", "Answer a small quiz there and the librarian will issue your card."]}},
				{"text": "Walk to the Central Library on the west wing.",
				 "type": "at", "pos": [99, 175], "radius": 8},
				{"text": "Library quiz: answer 2 of 3 questions correctly.",
				 "type": "mini",
				 "mini": {
					"kind": "quiz",
					"title": "LIBRARY QUIZ",
					"need": 2,
					"qs": [
						["What does CSE stand for?", ["Computer Science & Engineering", "Civil Study Edition", "Central Sports Event", "Class Seat Exam"], 0],
						["What should you maintain inside a library?", ["Loud music", "Silence", "A cricket bat", "Samosa party"], 1],
						["Which college simulation is this game about?", ["ANITS", "NASA Space Academy", "MIT Mars", "ABCD Academy"], 0]
					]
				 }},
				{"text": "Collect your library card from Suresh at the IT Block.",
				 "type": "npc", "npc": "suresh", "give_item": "lib",
				 "lines": {"suresh": ["Your library card is ready! Please keep silence inside the library."]}}
			]

		5: # Basketball Event
			body = [
				{"text": "Go to the Basketball Court for the freshers' match.",
				 "type": "at", "pos": [290, 275], "radius": 9, "say": "Basketball players: Shoot your shots, fresher!"},
				{"text": "Basketball shootout: score 3 of 5 shots! Aim with the mouse and press THROW to shoot.",
				 "type": "mini",
				 "mini": {"kind": "shoot", "title": "BASKETBALL SHOOTOUT", "shots": 5, "need": 3, "clock": 7.0}},
				{"text": "Celebrate with your friend Arjun at the Canteen.",
				 "type": "npc", "npc": "arjun",
				 "lines": {"arjun": ["Super shots! You are a proper basketball player!"]}}
			]

		6: # NCC Parade
			body = [
				{"text": "Report to Colonel Singh at the Open Auditorium grounds.",
				 "type": "npc", "npc": "colonel",
				 "lines": {"colonel": ["Cadet, today is the parade drill sprint! Alternate Left and Right foot in cadence!"]}},
				{"text": "Parade drill: Sprint 100m in cadence with the NCC company! (Keys A/D or Left/Right foot buttons)",
				 "type": "mini",
				 "mini": {
					"kind": "drill",
					"title": "NCC PARADE CADENCE SPRINT",
					"time": 25.0
				 }},
				{"text": "Salute the NCC company (press G near Colonel Singh).",
				 "type": "salute"},
				{"text": "Report back to Colonel Singh.",
				 "type": "npc", "npc": "colonel",
				 "lines": {"colonel": ["Excellent parade sprint! You marched like a true cadet. Jai Hind!"]}}
			]

		7: # Lab Manual Run
			body = [
				{"text": "Get the lab manual form from Suresh at the IT Block.",
				 "type": "npc", "npc": "suresh",
				 "lines": {"suresh": ["Lab manual run! Get Prof. Rao's signature first."]}},
				{"text": "Get Prof. Rao's signature at the CSE Block.",
				 "type": "npc", "npc": "prof",
				 "lines": {"prof": ["Signature done. Now take the stamp from Laksmi (Admin)."]}},
				{"text": "Get the stamp from Laksmi (Admin) at the Admin Block.",
				 "type": "npc", "npc": "clerk",
				 "lines": {"clerk": ["Stamp done! Take it back to Suresh quickly."]}},
				{"text": "Return the stamped form to Suresh at the IT Block.",
				 "type": "npc", "npc": "suresh", "give_item": "manual",
				 "lines": {"suresh": ["Perfect! All signatures are complete. Lab entry unlocked!"]}}
			]

		8: # Canteen Challenge
			body = [
				{"text": "Head to the Canteen for the eating challenge.",
				 "type": "at", "pos": [268, 145], "radius": 8},
				{"text": "Buy and drink 2 cold drinks from a vending machine (press E).",
				 "type": "chk", "check": "drinks"},
				{"text": "Samosa speed-eating: Type the canteen food words fast to eat all samosas!",
				 "type": "mini",
				 "mini": {
					"kind": "typing",
					"title": "SAMOSA SPEED-EATING CHALLENGE",
					"words": ["SAMOSA", "CHAI", "CRISPY", "MIRCHI", "CHUTNEY", "ANITS"],
					"need": 5,
					"time_per_word": 6.5
				 }},
				{"text": "Collect your prize from Arjun at the Canteen.",
				 "type": "npc", "npc": "arjun",
				 "lines": {"arjun": ["You won! Chai and samosas are on me today!"]}}
			]

		9: # Fest Stage
			body = [
				{"text": "Go to the fest stage near the IT Block road.",
				 "type": "at", "pos": [238, 244], "radius": 8, "say": "Lights, camera, fest!"},
				{"text": "Dance battle: Hit the dance buttons and hype the crowd to 80%! (Keys W/A/S/D or Dance Buttons)",
				 "type": "mini",
				 "mini": {
					"kind": "dance",
					"title": "FEST DANCE BATTLE",
					"time": 25.0,
					"target_hype": 80.0
				 }},
				{"text": "Meet your friend Arjun backstage at the Canteen.",
				 "type": "npc", "npc": "arjun",
				 "lines": {"arjun": ["Your dance was super! The entire crowd cheered for you!"]}}
			]

		10: # First Classroom
			body = [
				{"text": "Go to Prof. Rao at the CSE Block / Room 204 for your first class.",
				 "type": "npc", "npc": "prof",
				 "lines": {"prof": ["Welcome to your first class! Let us begin with our first lecture quiz."]}},
				{"text": "First class quiz: answer 3 of 4 questions correctly.",
				 "type": "mini",
				 "mini": {
					"kind": "quiz",
					"title": "FIRST CLASS QUIZ",
					"need": 3,
					"qs": [
						["Which language is 'print(\"hello\")' commonly written in?", ["Python", "Telugu", "Morse", "Latin"], 0],
						["What is 2 + 2 * 3 equal to?", ["12", "8", "10", "6"], 1],
						["What does a loop construct do in programming?", ["Repeats instructions", "Deletes the computer", "Sings audio", "Locks the room"], 0],
						["Where do freshers love to hang out between classes?", ["Canteen", "Moon", "Parking roof", "Server rack"], 0]
					]
				 }},
				{"text": "Talk to Prof. Rao to complete your first class.",
				 "type": "npc", "npc": "prof",
				 "lines": {"prof": ["Excellent work! Class dismissed. Welcome to ANITS, your best four years begin now!"]}}
			]

	return id_gate + body


func current() -> Dictionary:
	if index < 0 or index >= steps.size():
		return {}
	return steps[index]


func advance() -> void:
	index += 1
	if index >= steps.size():
		finished = true
		active = false
		completed.emit(day)
		return
	var s := current()
	step_changed.emit(index, steps.size(), str(s.get("text", "")))
	if s.has("say"):
		var eb: Node = get_node_or_null("/root/EventBus") if is_inside_tree() else null
		if eb:
			eb.emit_signal("notification", str(s["say"]), 3.0)

	# Trigger minigame if current step is mini
	if str(s.get("type", "")) == "mini" and s.has("mini"):
		minigame_triggered.emit(s["mini"])


func notify_talked_to(npc_id: String) -> bool:
	var s := current()
	if s.is_empty():
		return false

	var step_type := str(s.get("type", ""))
	# The ID check advances only when the bag's SHOW ID button is pressed
	# (`_on_id_shown`), not merely by talking to the guard.
	if step_type == "idcheck":
		return false

	if step_type != "npc" or str(s.get("npc", "")) != npc_id:
		return false

	# Fee check on Day 2
	var gs: Node = get_node_or_null("/root/GameState") if is_inside_tree() else null
	if s.get("check_fee", false):
		if gs and not gs.can_afford(250):
			var eb: Node = get_node_or_null("/root/EventBus") if is_inside_tree() else null
			if eb:
				eb.emit_signal("notification", "Laksmi: You need Rs. 250! Withdraw from the bank ATM first.", 3.0)
			return false
		if gs:
			gs.spend(250)
			gs.give_item("fee")

	if s.has("give_item") and gs:
		gs.give_item(str(s["give_item"]))

	advance()
	return true


func notify_position(player_pos: Vector3) -> bool:
	player_position = player_pos
	var s := current()
	if s.is_empty() or str(s.get("type", "")) != "at":
		return false
	var pos: Array = s.get("pos", [0, 0])
	# Most objectives are authored in plan pixels; interior objectives use
	# world metres because the walk-in rooms live far outside the campus plan.
	var w: Vector3
	if bool(s.get("world", false)):
		w = Vector3(float(pos[0]), 0.0, float(pos[1]))
	else:
		w = Campus.map_to_world(Vector2(pos[0], pos[1]))
	var radius := float(s.get("radius", 8))
	if player_pos.distance_to(Vector3(w.x, player_pos.y, w.z)) <= radius:
		advance()
		return true
	return false


func notify_salute() -> bool:
	var s := current()
	if s.is_empty() or str(s.get("type", "")) != "salute":
		return false
	advance()
	_salute_chorus()
	return true


func notify_check(check_id: String) -> bool:
	var s := current()
	if s.is_empty() or str(s.get("type", "")) != "chk":
		return false
	if str(s.get("check", "")) == check_id:
		advance()
		return true
	return false


func notify_minigame_won() -> bool:
	var s := current()
	if s.is_empty() or str(s.get("type", "")) != "mini":
		return false
	advance()
	return true


func _salute_chorus() -> void:
	var vb: Node = get_node_or_null("/root/VoiceBank") if is_inside_tree() else null
	if vb and vb.has_method("play_chorus"):
		vb.play_chorus(player_position)
