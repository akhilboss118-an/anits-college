extends Node
## The mission state machine. Ported 1:1 from the original's step schema
## (js/levels.js + the hard-coded Day 1 array in js/game.js).
##
## Step fields: t (text), at (plan position + radius), npc, salute, lines, ok,
## done, chk, mini, say. Day 1 is the tutorial; Days 2-10 add the gate ID check.

signal step_changed(index: int, total: int, text: String)
signal completed(day: int)

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
## The last known player position - the NCC chorus is triggered around it.
var player_position: Vector3 = Vector3.ZERO


func start_day(new_day: int) -> void:
	day = new_day
	finished = false
	active = true
	if new_day == 1:
		steps = DAY1.duplicate(true)
	else:
		steps = _build_later_day(new_day)
	index = -1
	# A new day rebuilds the campus - every sound of the old day is dropped.
	if VoiceBank:
		VoiceBank.stop_all()
	advance()


func _build_later_day(d: int) -> Array:
	## Days 2-10 always start with the ID check and the walk through the gate.
	var id_steps := [
		{"text": "Show your ID card to Security Guard Bajirao at the main gate (press E near him, then press SHOW in your bag).",
		 "type": "npc", "npc": "guard", "line": "id"},
		{"text": "Walk through the main gate and into the college.",
		 "type": "at", "pos": [122, 396], "radius": 12},
	]
	var body: Array = []
	match d:
		2:
			body = [
				{"text": "Go to Laksmi (Admin) in the Admin Block and ask for your fee slip.", "type": "npc", "npc": "clerk", "line": "day2"},
				{"text": "Withdraw at least Rs.250 from the bank ATM (press E near the bank).", "type": "chk", "check": "bank"},
				{"text": "Pay the fees to Laksmi (Admin) at the Admin Block.", "type": "npc", "npc": "clerk", "line": "day2"},
				{"text": "Show the fee receipt to Prof. Rao at the CSE Block.", "type": "npc", "npc": "prof", "line": "day2"},
			]
		_:
			body = [{"text": "Day %d content is not ported yet." % d, "type": "npc", "npc": "prof", "line": "day3"}]
	return id_steps + body


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
		EventBus.notification.emit(str(s["say"]), 3.0)


func notify_talked_to(npc_id: String) -> bool:
	## Returns true when the conversation advanced the mission.
	var s := current()
	if s.is_empty():
		return false
	if str(s.get("type", "")) != "npc" or str(s.get("npc", "")) != npc_id:
		return false
	advance()
	return true


func notify_position(player_pos: Vector3) -> bool:
	# The player position is cached for every step, not only for the "walk
	# here" ones - the NCC chorus needs it when the salute comes.
	player_position = player_pos
	var s := current()
	if s.is_empty() or str(s.get("type", "")) != "at":
		return false
	var pos: Array = s.get("pos", [0, 0])
	var w := Campus.map_to_world(Vector2(pos[0], pos[1]))
	var radius := float(s.get("radius", 8))   # metres
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


## The NCC company answers the salute with a "Jai Hind!" chorus
## (js/voice.js chorus(), docs/CHARACTER_AND_NPC_ANALYSIS.md §6.3).
## Every cadet within 16 m shouts the line in its own voice; the chorus never
## cuts the dialogue and is ducked while a line is open.
func _salute_chorus() -> void:
	if not VoiceBank:
		return
	VoiceBank.play_chorus(player_position)
