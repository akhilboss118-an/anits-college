class_name InventoryPanel
extends CanvasLayer
## In-game student bag overlay (Key B / on-screen Bag button).
## Displays collected documents:
##   - Student ID Card (generated roll number + department)
##   - Fee Receipt (stamped PAID)
##   - Central Library Card
##   - Signed Lab Manual
##
## Allows "SHOW ID" when requested by Security Guard Bajirao at the main gate.

signal id_shown

var is_open: bool = false
var ask_mode: bool = false
var local_items: Dictionary = {"id": true}

var _panel: PanelContainer
var _card_grid: HBoxContainer
var _title_lbl: Label
var _sub_lbl: Label
var _close_btn: Button
var _drinks_title: Label
var _drinks_grid: GridContainer


func has_item(item_id: String) -> bool:
	var gs: Node = get_node_or_null("/root/GameState") if is_inside_tree() else null
	if gs and gs.has_method("has_item"):
		return bool(gs.has_item(item_id))
	return bool(local_items.get(item_id, false))


func add_item(item_id: String) -> void:
	local_items[item_id] = true
	var gs: Node = get_node_or_null("/root/GameState") if is_inside_tree() else null
	if gs and gs.has_method("give_item"):
		gs.give_item(item_id)


func _init() -> void:
	layer = 24
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
	dim.color = Color(0.01, 0.04, 0.10, 0.8)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(880, 540)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.10, 0.22, 0.98)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color("#3aa0ff")
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_left = 18
	sb.corner_radius_bottom_right = 18
	sb.shadow_color = Color(0.12, 0.45, 0.95, 0.35)
	sb.shadow_size = 36
	_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	_title_lbl = Label.new()
	_title_lbl.text = "STUDENT BAG & INVENTORY"
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 22)
	_title_lbl.add_theme_color_override("font_color", Color("#7cc4ff"))
	vbox.add_child(_title_lbl)

	_sub_lbl = Label.new()
	_sub_lbl.text = "Your ANITS documents. Security checks your ID card at the gate every day."
	_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_lbl.add_theme_font_size_override("font_size", 14)
	_sub_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	vbox.add_child(_sub_lbl)

	_card_grid = HBoxContainer.new()
	_card_grid.alignment = BoxContainer.ALIGNMENT_CENTER
	_card_grid.add_theme_constant_override("separation", 18)
	_card_grid.custom_minimum_size = Vector2(760, 210)
	vbox.add_child(_card_grid)

	# Canteen collection: all 10 drinks from the original DR table, with the
	# Campus Foodie badge shown once every one has been tried.
	_drinks_title = Label.new()
	_drinks_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_drinks_title.add_theme_font_size_override("font_size", 15)
	_drinks_title.add_theme_color_override("font_color", Color("#ffd54a"))
	vbox.add_child(_drinks_title)

	_drinks_grid = GridContainer.new()
	_drinks_grid.columns = 5
	_drinks_grid.add_theme_constant_override("h_separation", 8)
	_drinks_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(_drinks_grid)

	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(foot)

	_close_btn = Button.new()
	_close_btn.text = "CLOSE (B)"
	_close_btn.custom_minimum_size = Vector2(130, 38)
	_close_btn.pressed.connect(close)
	foot.add_child(_close_btn)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			toggle()
		elif event.keycode == KEY_ESCAPE and is_open:
			close()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open(for_check: bool = false) -> void:
	ask_mode = for_check
	is_open = true
	visible = true
	_play_ui_sfx("ui_click", -14.0)
	_render_cards()


func close() -> void:
	is_open = false
	visible = false
	_play_ui_sfx("ui_back", -16.0)


## Null-safe: the headless test runner compiles this script before the autoload
## globals exist, so never reference the `Audio` singleton directly.
func _play_ui_sfx(id: String, volume_db: float = -14.0) -> void:
	var a: Node = get_node_or_null("/root/Audio")
	if a:
		a.play_ui(id, volume_db)


func _render_cards() -> void:
	for child in _card_grid.get_children():
		child.queue_free()

	if ask_mode:
		_sub_lbl.text = "Security Bajirao: \"Show me your ID card, please.\" Click SHOW on your card."
		_sub_lbl.add_theme_color_override("font_color", Color("#ffd54a"))
	else:
		_sub_lbl.text = "Your ANITS documents, and the 10-drink Canteen Collection."
		_sub_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))

	var gs: Node = get_node_or_null("/root/GameState") if is_inside_tree() else null
	var p_name: String = "Student"
	if gs:
		p_name = str(gs.profile.get("name", "Student"))
	var roll := "24A91A05%02d" % (hash(p_name) % 90 + 10)

	# 1. Student ID Card
	var has_id: bool = has_item("id") or (gs != null and (bool(gs.has_item("id")) or int(gs.current_day) > 1))
	_add_card_slot("Student ID Card", has_id, func(card_panel):
		_build_id_card(card_panel, p_name, roll)
	)

	# 2. Fee Receipt
	var has_fee: bool = has_item("fee") or (gs != null and bool(gs.has_item("fee")))
	_add_card_slot("Fee Receipt", has_fee, func(card_panel):
		_build_fee_card(card_panel, p_name, roll)
	)

	# 3. Library Card
	var has_lib: bool = has_item("lib") or (gs != null and bool(gs.has_item("lib")))
	_add_card_slot("Library Card", has_lib, func(card_panel):
		_build_lib_card(card_panel, p_name, roll)
	)

	_render_drinks(gs)


func _render_drinks(gs: Node) -> void:
	if _drinks_grid == null:
		return
	for child in _drinks_grid.get_children():
		child.queue_free()

	var tried: Dictionary = {}
	var count := 0
	if gs:
		tried = gs.drinks_tried
		count = gs.drinks_tried_count()
	var db: Node = get_node_or_null("/root/CampusDB") if is_inside_tree() else null
	var drinks: Array = db.drinks if db else []
	var total := drinks.size() if drinks.size() > 0 else 10
	var badge := ""
	if gs and gs.has_item("foodie"):
		badge = "   •   CAMPUS FOODIE BADGE UNLOCKED"
	_drinks_title.text = "CANTEEN COLLECTION — %d / %d%s" % [count, total, badge]
	_drinks_title.add_theme_color_override("font_color",
		Color("#6dff9f") if count >= total else Color("#ffd54a"))

	for drink in drinks:
		var drink_id := str(drink.get("id", ""))
		var got := tried.has(drink_id)
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(158, 40)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.22, 0.15, 0.95) if got else Color(0.05, 0.09, 0.16, 0.8)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color("#2fd36b") if got else Color(0.35, 0.48, 0.62, 0.35)
		sb.corner_radius_top_left = 8
		sb.corner_radius_top_right = 8
		sb.corner_radius_bottom_left = 8
		sb.corner_radius_bottom_right = 8
		chip.add_theme_stylebox_override("panel", sb)
		_drinks_grid.add_child(chip)

		var lbl := Label.new()
		lbl.text = ("✓ " if got else "· ") + str(drink.get("name", drink_id))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.clip_text = true
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color",
			Color("#d9ffe6") if got else Color(1, 1, 1, 0.45))
		chip.add_child(lbl)


func _add_card_slot(title: String, has_it: bool, build_card_func: Callable) -> void:
	var slot := VBoxContainer.new()
	slot.custom_minimum_size = Vector2(230, 200)
	slot.alignment = BoxContainer.ALIGNMENT_CENTER
	slot.add_theme_constant_override("separation", 8)
	_card_grid.add_child(slot)

	var card_container := PanelContainer.new()
	card_container.custom_minimum_size = Vector2(220, 136)
	slot.add_child(card_container)

	if has_it:
		build_card_func.call(card_container)
	else:
		var empty_sb := StyleBoxFlat.new()
		empty_sb.bg_color = Color(0.06, 0.12, 0.22, 0.4)
		empty_sb.border_width_left = 1
		empty_sb.border_width_top = 1
		empty_sb.border_width_right = 1
		empty_sb.border_width_bottom = 1
		empty_sb.border_color = Color(0.4, 0.6, 0.8, 0.3)
		empty_sb.corner_radius_top_left = 12
		empty_sb.corner_radius_top_right = 12
		empty_sb.corner_radius_bottom_left = 12
		empty_sb.corner_radius_bottom_right = 12
		card_container.add_theme_stylebox_override("panel", empty_sb)

		var empty_lbl := Label.new()
		empty_lbl.text = "NOT COLLECTED YET"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
		card_container.add_child(empty_lbl)

	var name_lbl := Label.new()
	name_lbl.text = title
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 14)
	slot.add_child(name_lbl)

	if has_it and ask_mode and title == "Student ID Card":
		var show_btn := Button.new()
		show_btn.text = "SHOW ID"
		show_btn.custom_minimum_size = Vector2(110, 32)
		show_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = Color("#2fd36b")
		bsb.corner_radius_top_left = 16
		bsb.corner_radius_top_right = 16
		bsb.corner_radius_bottom_left = 16
		bsb.corner_radius_bottom_right = 16
		show_btn.add_theme_stylebox_override("normal", bsb)
		show_btn.add_theme_color_override("font_color", Color("#06210f"))
		show_btn.pressed.connect(func():
			id_shown.emit()
			close()
		)
		slot.add_child(show_btn)


func _build_id_card(parent: Control, p_name: String, roll: String) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#0d3b8e")
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	parent.add_theme_stylebox_override("panel", sb)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	parent.add_child(margin)

	var c_box := VBoxContainer.new()
	margin.add_child(c_box)

	var h := Label.new()
	h.text = "ANITS · STUDENT ID"
	h.add_theme_font_size_override("font_size", 11)
	h.add_theme_color_override("font_color", Color("#ffd54a"))
	c_box.add_child(h)

	var details := Label.new()
	details.text = "%s\nB.Tech CSE · Year 1\nRoll %s" % [p_name, roll]
	details.add_theme_font_size_override("font_size", 13)
	c_box.add_child(details)


func _build_fee_card(parent: Control, p_name: String, roll: String) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#fdfaf0")
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	parent.add_theme_stylebox_override("panel", sb)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	parent.add_child(margin)

	var c_box := VBoxContainer.new()
	margin.add_child(c_box)

	var h := Label.new()
	h.text = "ANITS · FEE RECEIPT"
	h.add_theme_font_size_override("font_size", 11)
	h.add_theme_color_override("font_color", Color("#222222"))
	c_box.add_child(h)

	var details := Label.new()
	details.text = "%s (Roll %s)\nSem 1 Fee: ₹250\nStatus: PAID [STAMPED]" % [p_name, roll]
	details.add_theme_font_size_override("font_size", 12)
	details.add_theme_color_override("font_color", Color("#333333"))
	c_box.add_child(details)

	var stamp := Label.new()
	stamp.text = "PAID"
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stamp.add_theme_font_size_override("font_size", 18)
	stamp.add_theme_color_override("font_color", Color("#d3202f"))
	c_box.add_child(stamp)


func _build_lib_card(parent: Control, p_name: String, roll: String) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#0d6b3c")
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	parent.add_theme_stylebox_override("panel", sb)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	parent.add_child(margin)

	var c_box := VBoxContainer.new()
	margin.add_child(c_box)

	var h := Label.new()
	h.text = "CENTRAL LIBRARY · ANITS"
	h.add_theme_font_size_override("font_size", 11)
	h.add_theme_color_override("font_color", Color("#6dff9f"))
	c_box.add_child(h)

	var details := Label.new()
	details.text = "%s\nMember LB-%s\nValid: 4 Years" % [p_name, roll.substr(roll.length() - 4)]
	details.add_theme_font_size_override("font_size", 13)
	c_box.add_child(details)
