extends CanvasLayer
## ---------------------------------------------------------------------------
## Touch controls - layout at a glance.
##
##   +----------------------------------------------------------+
##   |                                            [ NEXT ]     |  NEXT only
##   |                                     [ G ]   [ RUN ]     |  while a
##   |  ( o )                                      [ E ]       |  dialogue
##   |  MOVE                                          ^        |  is open
##   |     virtual stick      drag anywhere = orbit the camera  |
##   +----------------------------------------------------------+
##
## Bottom-left: a virtual joystick.  The base and the knob are always drawn;
## they are dim while idle and light up while a finger is down.  The "MOVE"
## hint fades out the first time the stick is used.
##
## Bottom-right: E (interact), G (salute) and a RUN toggle that latches (tap
## to run, tap again to walk).  E and G light up while the action is possible.
## NEXT appears while a dialogue is open and advances it.
##
## Anywhere else: drag to orbit the camera, tap to advance a dialogue.
##
## Sizes follow the device (the shared `_ui_scale` helper lives in hud.gd)
## and the whole pad stays inside the display safe area, so notches, punch
## holes and the home bar never cover a control.  Nothing is repainted every
## frame: the joystick only redraws when it actually changes.
##
## Public API used by src/main.gd (unchanged):
##   move_changed(Vector2) / look_dragged(Vector2) / run_changed(bool)
##   tapped / interact_pressed / salute_pressed
## ---------------------------------------------------------------------------

signal move_changed(value: Vector2)
signal look_dragged(relative: Vector2)
signal tapped
signal interact_pressed
signal salute_pressed
signal run_changed(running: bool)

const HUD_SCRIPT := preload("res://src/ui/hud.gd")

const JOY_RADIUS := 104.0        ## base radius, unscaled
const JOY_MARGIN := 30.0         ## gap to the screen edge, unscaled
const DEAD_ZONE := 0.14
const TAP_SLOP := 16.0
const BTN_E := 100.0
const BTN_G := 84.0
const BTN_RUN := 92.0
const BTN_NEXT := 92.0
const BTN_GAP := 16.0
const BTN_EDGE := 14.0


class JoystickDraw:
	extends Control
	## The joystick is one flat drawing: an outer glow, the base, two rings and
	## the knob.  It is repainted only when the value, the state or the layout
	## changes - never every frame.

	var center := Vector2.ZERO
	var value := Vector2.ZERO
	var active := false
	var radius := 104.0
	var knob_radius := 36.0

	func _draw() -> void:
		var ring := Color(0.86, 0.93, 1.0, 0.62 if active else 0.34)
		var fill := Color(0.05, 0.10, 0.20, 0.46 if active else 0.26)
		draw_circle(center, radius * 1.07, Color(0.02, 0.05, 0.11, 0.20))
		draw_circle(center, radius, fill)
		draw_arc(center, radius, 0.0, TAU, 44, ring, 3.0, true)
		draw_arc(center, radius * 0.58, 0.0, TAU, 30,
				Color(ring.r, ring.g, ring.b, ring.a * 0.45), 1.5, true)
		var knob := center + value * maxf(0.0, radius - knob_radius)
		var knob_colour := Color(0.94, 0.97, 1.0, 0.94) if active \
				else Color(0.84, 0.91, 1.0, 0.55)
		draw_circle(knob, knob_radius + 4.0, Color(0.02, 0.05, 0.11, 0.40))
		draw_circle(knob, knob_radius, knob_colour)
		if not active:
			# Idle: a small dot marks the rest position of the knob.
			draw_circle(center, 4.0, Color(0.94, 0.97, 1.0, 0.40))


var _root: Control
var _draw_layer: JoystickDraw
var _joy_center := Vector2.ZERO
var _joy_radius := JOY_RADIUS
var _joy_index: int = -1
var _joy_value := Vector2.ZERO
var _look_index: int = -1
var _look_last := Vector2.ZERO
var _look_travel := 0.0
var _buttons: Array[Button] = []
var _button_run: Button
var _button_e: Button
var _button_g: Button
var _button_next: Button
var _hint: Label
var _ui_scale: float = 1.0
var _safe: Vector4 = Vector4.ZERO
var _style_scale: float = -1.0
var _run_latched: bool = false
var _suppress_run: bool = false
var _dialogue_open: bool = false
var _action_available: bool = false
var _salute_available: bool = false
var _dialogue_override: int = -1
var _action_override: int = -1
var _salute_override: int = -1
var _player: Node = null
var _player_has_props: bool = false
var _player_retry: float = 0.0
var _colonel: Node3D = null
var _step_index: int = -2
var _step_type: String = ""


func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.name = "TouchRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_draw_layer = JoystickDraw.new()
	_draw_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_draw_layer)

	_button_e = _make_button("E", BTN_E)
	_button_e.pressed.connect(_on_interact)
	_button_g = _make_button("G", BTN_G)
	_button_g.pressed.connect(_on_salute)
	_button_run = _make_button("RUN", BTN_RUN)
	_button_run.toggle_mode = true
	_button_run.toggled.connect(_on_run_toggled)
	_button_next = _make_button("NEXT", BTN_NEXT)
	_button_next.pressed.connect(_on_next)
	_button_next.visible = false

	_hint = Label.new()
	_hint.text = "MOVE"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_hint.add_theme_constant_override("outline_size", 4)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hint)

	_root.resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	_layout()


# ------------------------------------------------------------------ controls

func _make_button(text: String, diameter: float) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.grow_horizontal = Control.GROW_DIRECTION_END
	button.grow_vertical = Control.GROW_DIRECTION_END
	button.size = Vector2(diameter, diameter)
	button.pivot_offset = Vector2(diameter, diameter) * 0.5
	button.add_theme_font_size_override("font_size", int(diameter * 0.30))
	button.add_theme_color_override("font_color", Color(1, 1, 1, 0.96))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.45, 1))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_root.add_child(button)
	_buttons.append(button)
	return button


func _button_style(bg: Color, border: Color, width: float, radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(int(width))
	style.set_corner_radius_all(int(radius))
	# The label is centred inside a circle, so no extra padding is needed and
	# the button keeps its designed diameter.
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style


func _apply_button_style(button: Button, state: int) -> void:
	## state: 0 = idle, 1 = available (the action can be used), 2 = latched
	## (RUN is on).  The "pressed" box carries the latched look for the
	## toggle button, which Godot renders while the button is turned on.
	var diameter: float = button.size.x
	var radius := diameter * 0.5
	match state:
		1:
			button.add_theme_stylebox_override("normal",
					_button_style(Color(0.11, 0.19, 0.34, 0.66), Color(1.0, 0.86, 0.34, 0.98), 3.0, radius))
			button.add_theme_stylebox_override("hover",
					_button_style(Color(0.16, 0.26, 0.44, 0.78), Color(1.0, 0.92, 0.45, 1.0), 3.0, radius))
			button.add_theme_stylebox_override("pressed",
					_button_style(Color(0.22, 0.36, 0.56, 0.90), Color(1.0, 0.94, 0.48, 1.0), 3.0, radius))
		2:
			button.add_theme_stylebox_override("normal",
					_button_style(Color(0.52, 0.36, 0.05, 0.80), Color(1.0, 0.88, 0.36, 1.0), 3.0, radius))
			button.add_theme_stylebox_override("hover",
					_button_style(Color(0.62, 0.44, 0.06, 0.88), Color(1.0, 0.93, 0.45, 1.0), 3.0, radius))
			button.add_theme_stylebox_override("pressed",
					_button_style(Color(0.58, 0.40, 0.06, 0.86), Color(1.0, 0.90, 0.40, 1.0), 3.0, radius))
		_:
			button.add_theme_stylebox_override("normal",
					_button_style(Color(0.04, 0.09, 0.19, 0.52), Color(0.93, 0.80, 0.32, 0.62), 2.0, radius))
			button.add_theme_stylebox_override("hover",
					_button_style(Color(0.09, 0.16, 0.30, 0.68), Color(1.0, 0.87, 0.38, 0.92), 3.0, radius))
			button.add_theme_stylebox_override("pressed",
					_button_style(Color(0.20, 0.34, 0.54, 0.88), Color(1.0, 0.92, 0.45, 1.0), 3.0, radius))


func _layout() -> void:
	if _root == null:
		return
	var view := _root.size
	if view.x <= 0.0 or view.y <= 0.0:
		return
	var win := DisplayServer.window_get_size()
	_ui_scale = HUD_SCRIPT.compute_ui_scale(view, win)
	_safe = HUD_SCRIPT.safe_area_insets(view, win)
	var s := _ui_scale

	# --- joystick (bottom left, inside the safe area) ---
	var radius := JOY_RADIUS * s
	_joy_radius = radius
	var margin := JOY_MARGIN * s
	_joy_center = Vector2(_safe.x + margin + radius,
			view.y - _safe.w - margin - radius)
	_draw_layer.center = _joy_center
	_draw_layer.radius = radius
	_draw_layer.knob_radius = radius * 0.34
	_draw_layer.queue_redraw()
	_hint.position = Vector2(_joy_center.x - 70.0 * s, _joy_center.y + radius + 6.0 * s)
	_hint.size = Vector2(140.0 * s, 24.0 * s)
	_hint.add_theme_font_size_override("font_size", int(round(14.0 * s)))

	# --- right hand cluster (E, G, RUN, NEXT) ---
	var d_e := BTN_E * s
	var d_g := BTN_G * s
	var d_r := BTN_RUN * s
	var d_n := BTN_NEXT * s
	var gap := BTN_GAP * s
	var edge := BTN_EDGE * s
	var right_edge := view.x - _safe.z - edge
	var bottom_edge := view.y - _safe.w - edge
	_place(_button_e, Vector2(right_edge - d_e, bottom_edge - d_e), d_e)
	_place(_button_g, Vector2(right_edge - d_g, bottom_edge - d_e - gap - d_g), d_g)
	_place(_button_run, Vector2(right_edge - d_e - gap - d_r, bottom_edge - d_r), d_r)
	_place(_button_next, Vector2(right_edge - d_e - gap - d_n, bottom_edge - d_r - gap - d_n), d_n)

	if not is_equal_approx(s, _style_scale):
		_style_scale = s
		for button in _buttons:
			button.add_theme_font_size_override("font_size", int(button.size.x * 0.30))
		_apply_button_style(_button_e, 1 if _action_available else 0)
		_apply_button_style(_button_g, 1 if _salute_available else 0)
		_apply_button_style(_button_run, 2 if _run_latched else 0)
		_apply_button_style(_button_next, 0)


func _place(button: Button, pos: Vector2, diameter: float) -> void:
	button.size = Vector2(diameter, diameter)
	button.pivot_offset = Vector2(diameter, diameter) * 0.5
	button.position = pos


# -------------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_on_touch_down(touch.index, touch.position)
		else:
			_on_touch_up(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _joy_index:
			_update_joystick(drag.position)
		elif drag.index == _look_index:
			var relative: Vector2 = drag.position - _look_last
			_look_last = drag.position
			_look_travel += relative.length()
			look_dragged.emit(relative)


func _on_touch_down(index: int, point: Vector2) -> void:
	if _inside_button(point):
		return
	if _joy_index < 0 and point.distance_to(_joy_center) < _joy_radius * 1.45:
		_joy_index = index
		_update_joystick(point)
		return
	if _look_index < 0:
		_look_index = index
		_look_last = point
		_look_travel = 0.0


func _on_touch_up(index: int) -> void:
	if index == _joy_index:
		_joy_index = -1
		_release_joystick()
	elif index == _look_index:
		_look_index = -1
		if _look_travel < TAP_SLOP:
			tapped.emit()


func _update_joystick(point: Vector2) -> void:
	var offset := point - _joy_center
	if offset.length() > _joy_radius:
		offset = offset.normalized() * _joy_radius
	var value := offset / _joy_radius
	if value.length() < DEAD_ZONE:
		value = Vector2.ZERO
	else:
		value = value.normalized() * ((value.length() - DEAD_ZONE) / (1.0 - DEAD_ZONE))
	_joy_value = value
	move_changed.emit(value)
	_draw_layer.value = value
	if not _draw_layer.active:
		_draw_layer.active = true
		if _hint.modulate.a > 0.0:
			_hint.modulate.a = 0.0
	_draw_layer.queue_redraw()


func _release_joystick() -> void:
	if _joy_value != Vector2.ZERO:
		_joy_value = Vector2.ZERO
		move_changed.emit(Vector2.ZERO)
	_draw_layer.value = Vector2.ZERO
	if _draw_layer.active:
		_draw_layer.active = false
		_draw_layer.queue_redraw()


func _inside_button(point: Vector2) -> bool:
	for button in _buttons:
		if not button.visible:
			continue
		if button.get_global_rect().has_point(point):
			return true
	return false


# ------------------------------------------------------------------ actions

func _on_interact() -> void:
	interact_pressed.emit()


func _on_salute() -> void:
	salute_pressed.emit()


func _on_next() -> void:
	## The explicit "next" button advances the dialogue.  It reuses `tapped`
	## so the game side does not need to know about it.
	tapped.emit()


func _on_run_toggled(on: bool) -> void:
	if _suppress_run:
		return
	_run_latched = on
	_apply_button_style(_button_run, 2 if on else 0)
	run_changed.emit(on)


## Optional: drive the NEXT button from the game instead of the `Dialogue`
## autoload.  Called by nothing today, kept so the HUD/game can take over.
func set_dialogue_open(open: bool) -> void:
	_dialogue_override = 1 if open else 0
	_update_dialogue_state()


## Optional: light up (or dim) the E button by hand.
func set_action_available(available: bool) -> void:
	_action_override = 1 if available else 0
	_update_action_state()


## Optional: light up (or dim) the G button by hand.
func set_salute_available(available: bool) -> void:
	_salute_override = 1 if available else 0
	_update_salute_state()


# ------------------------------------------------------------------- state

func _process(delta: float) -> void:
	if _player_retry > 0.0:
		_player_retry -= delta
	_update_dialogue_state()
	_update_action_state()
	_update_salute_state()
	_update_step()
	_sync_run_state()


func _update_dialogue_state() -> void:
	var open := false
	if _dialogue_override >= 0:
		open = _dialogue_override == 1
	elif Dialogue:
		open = Dialogue.active
	if open == _dialogue_open:
		return
	_dialogue_open = open
	_button_next.visible = open
	if open:
		_release_joystick()


func _update_action_state() -> void:
	var available := false
	if _action_override >= 0:
		available = _action_override == 1
	else:
		var p := _player_node()
		if p != null and _player_has_props:
			available = p.get("dialogue_nearby") != null or p.get("interact_target") != null
	if available == _action_available:
		return
	_action_available = available
	_apply_button_style(_button_e, 1 if available else 0)


func _update_salute_state() -> void:
	var available := false
	if _salute_override >= 0:
		available = _salute_override == 1
	else:
		available = _step_type == "salute" or _near_colonel()
	if available == _salute_available:
		return
	_salute_available = available
	_apply_button_style(_button_g, 1 if available else 0)


func _near_colonel() -> bool:
	if _colonel == null or not is_instance_valid(_colonel):
		return false
	var p := _player_node()
	if p == null:
		return false
	var pos: Variant = p.get("global_position")
	if typeof(pos) != TYPE_VECTOR3:
		return false
	return (pos as Vector3).distance_to(_colonel.global_position) < 20.0


func _update_step() -> void:
	## Cheap poll of the mission table: only touched when the step changes.
	if not Mission:
		return
	var index := Mission.index
	if index == _step_index:
		return
	_step_index = index
	_step_type = ""
	if index >= 0 and index < Mission.steps.size():
		var step: Variant = Mission.steps[index]
		if typeof(step) == TYPE_DICTIONARY:
			_step_type = str((step as Dictionary).get("type", ""))
	_colonel = _find_npc("colonel")


func _find_npc(npc_id: String) -> Node3D:
	if not is_inside_tree():
		return null
	for n in get_tree().get_nodes_in_group("npcs"):
		var node := n as Node3D
		if node != null and str(node.get("npc_id")) == npc_id:
			return node
	return null


func _sync_run_state() -> void:
	## The game clears `touch_run` when a dialogue starts or ends, so the
	## latched button follows the player instead of lying about the state.
	var p := _player_node()
	if p == null:
		return
	var value: Variant = p.get("touch_run")
	if typeof(value) != TYPE_BOOL:
		return
	var on: bool = value
	if on == _run_latched:
		return
	_run_latched = on
	_suppress_run = true
	_button_run.button_pressed = on
	_suppress_run = false
	_apply_button_style(_button_run, 2 if on else 0)


func _player_node() -> Node:
	if _player != null and is_instance_valid(_player):
		return _player
	if not is_inside_tree() or _player_retry > 0.0:
		return null
	# Looked up at most twice a second so a missing player never turns into a
	# per-frame allocation.
	_player_retry = 0.5
	_player = get_tree().get_first_node_in_group("player")
	_player_has_props = _player != null and "dialogue_nearby" in _player
	return _player
