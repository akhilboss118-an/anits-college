class_name LevelCompleteDialog
extends CanvasLayer
## Victory overlay shown upon completing any of the 10 Days.
## Displays the celebratory story line, unlocks the next day, and offers
## direct continuation to the next day or return to the main menu.

signal next_day_requested(next_day: int)
signal menu_requested

const COMPLETION_LINES := [
	"You toured every corner of ANITS, met the staff, found a friend and saluted the NCC company. Jai Hind!",
	"Fees paid, receipt stamped. You are officially an ANITS student!",
	"After a wrong lab and a lost corridor, you found your classroom!",
	"Quiz passed. Your library card is in your pocket!",
	"Nothing but net! The court has a new star.",
	"You marched with the NCC company. Colonel Singh is proud!",
	"All signatures collected. The lab is open for you!",
	"Chai, samosa and a win. What a canteen day!",
	"The crowd is still cheering your name! You rocked the fest!",
	"Your first class at ANITS is done. The story has just begun! Welcome to ANITS!"
]

const DAY_NAMES := [
	"Explore the College",
	"Pay the Fees",
	"Find Your Classroom",
	"Library Card",
	"Basketball Event",
	"NCC Parade",
	"Lab Manual Run",
	"Canteen Challenge",
	"Fest Stage",
	"First Classroom"
]

var _day: int = 1
var _panel: PanelContainer
var _title_lbl: Label
var _name_lbl: Label
var _desc_lbl: Label
var _next_btn: Button


func _init() -> void:
	layer = 26
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	visible = false
	_build_ui()


func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.03, 0.08, 0.86)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(580, 320)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.12, 0.28, 0.98)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color("#ffd54a")
	sb.corner_radius_top_left = 20
	sb.corner_radius_top_right = 20
	sb.corner_radius_bottom_left = 20
	sb.corner_radius_bottom_right = 20
	sb.shadow_color = Color(1.0, 0.83, 0.29, 0.4)
	sb.shadow_size = 40
	_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 28)
	_title_lbl.add_theme_color_override("font_color", Color("#ffd54a"))
	vbox.add_child(_title_lbl)

	_name_lbl = Label.new()
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_lbl.add_theme_font_size_override("font_size", 18)
	_name_lbl.add_theme_color_override("font_color", Color("#7cc4ff"))
	vbox.add_child(_name_lbl)

	_desc_lbl = Label.new()
	_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_lbl.add_theme_font_size_override("font_size", 15)
	_desc_lbl.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_desc_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var menu_btn := Button.new()
	menu_btn.text = "MAIN MENU"
	menu_btn.custom_minimum_size = Vector2(160, 44)
	menu_btn.pressed.connect(func():
		visible = false
		menu_requested.emit()
	)
	btn_row.add_child(menu_btn)

	_next_btn = Button.new()
	_next_btn.text = "CONTINUE"
	_next_btn.custom_minimum_size = Vector2(180, 44)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color("#2fd36b")
	bsb.corner_radius_top_left = 22
	bsb.corner_radius_top_right = 22
	bsb.corner_radius_bottom_left = 22
	bsb.corner_radius_bottom_right = 22
	_next_btn.add_theme_stylebox_override("normal", bsb)
	_next_btn.add_theme_color_override("font_color", Color("#06210f"))
	_next_btn.pressed.connect(_on_next_pressed)
	btn_row.add_child(_next_btn)


func show_day_completed(day: int) -> void:
	_day = day
	visible = true

	# Unlock next day
	var gs: Node = get_node_or_null("/root/GameState") if is_inside_tree() else null
	if gs:
		gs.unlock(day)
		if day == 1:
			gs.give_item("id")
		var ss: Node = get_node_or_null("/root/SaveSystem") if is_inside_tree() else null
		if ss:
			ss.save_profile(gs.profile, gs.unlocked_day)

	var d_idx := clampi(day - 1, 0, DAY_NAMES.size() - 1)
	_title_lbl.text = "★ DAY %d COMPLETE! ★" % day
	_name_lbl.text = DAY_NAMES[d_idx].to_upper()
	_desc_lbl.text = COMPLETION_LINES[d_idx]

	if day >= 10:
		_next_btn.text = "GRADUATE!"
	else:
		_next_btn.text = "CONTINUE TO DAY %d →" % (day + 1)


func _on_next_pressed() -> void:
	visible = false
	if _day < 10:
		next_day_requested.emit(_day + 1)
	else:
		menu_requested.emit()
