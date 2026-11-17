extends CanvasLayer
## ---------------------------------------------------------------------------
## Touch controls - layout at a glance.
##
##   +----------------------------------------------------------+
##   |                                                          |
##   |                                      [ NEXT ]            |  NEXT only
##   |                                        [ G ]             |  during a
##   |   ( ^ )                            ( E )             |  dialogue
##   | ( < o > )                            INTERACT           |
##   |   ( v )                          ( RUN )             |
##   |  MOVE pad                            RUN               |
##   +----------------------------------------------------------+
##
## Bottom-left: a large virtual joystick with directional chevrons.  The
## base and the knob light up while a finger is down, and the ring turns
## gold while the character runs.  Pushing the stick to the outer edge also
## runs.
##
## Bottom-right: a RUN button (toggle run) to the left of an E button
## (interact); both carry a caption pill underneath.  Every action is a white
## glyph on a dark circular badge with a gold accent arc - the RUN badge uses
## a right-hand arc, the action badges use the top arc from the icon sheet.
## E follows the HUD prompt icon and turns bright gold while an interaction is
## available.  G (salute) appears only when the Colonel or a salute step is
## in range, and NEXT only while a dialogue is open.
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
signal bag_pressed
signal run_changed(running: bool)

const HUD_SCRIPT := preload("res://src/ui/hud.gd")

const JOY_RADIUS := 84.0         ## base radius (unscaled)
const JOY_MARGIN := 22.0         ## gap to the screen edge, unscaled
const DEAD_ZONE := 0.14
const RUN_ON := 0.92             ## deflection that starts a run
const RUN_OFF := 0.80            ## hysteresis so the run does not flicker
const TAP_SLOP := 16.0
const BTN_E := 86.0
const BTN_RUN := 86.0
const BTN_G := 68.0
const BTN_NEXT := 86.0
const BTN_GAP := 14.0
const BTN_EDGE := 16.0
const PILL_H := 26.0
const PILL_GAP := 7.0


class JoystickDraw:
	extends Control
	## One flat drawing: an outer shadow, the base, a thin inner ring, four
	## directional chevrons and the knob.  Repainted only when the state or
	## value changes - never every frame.

	var center := Vector2.ZERO
	var value := Vector2.ZERO
	var active := false
	var running := false
	var radius := JOY_RADIUS
	var knob_radius := 38.0

	func _draw() -> void:
		var u := radius / JOY_RADIUS
		var accent := Color(1.0, 0.84, 0.32) if running else Color(0.95, 0.97, 1.0)
		var ring_alpha := 0.88 if active or running else 0.42
		var chev_alpha := 0.82 if active or running else 0.46
		var fill := Color(0.035, 0.06, 0.11, 0.62 if active else 0.44)

		# Soft shadow, navy glass base, bright rim and a faint inner ring.
		draw_circle(center, radius * 1.04, Color(0.01, 0.02, 0.04, 0.28))
		draw_circle(center, radius, fill)
		draw_arc(center, radius, 0.0, TAU, 64,
				Color(accent.r, accent.g, accent.b, ring_alpha), 2.6 * u, true)
		draw_arc(center, radius * 0.62, 0.0, TAU, 48,
				Color(1.0, 1.0, 1.0, 0.10), 1.2 * u, true)
		# A gold arc sweeps the upper-right rim while sprinting, echoing the
		# run button and the reference icon language.
		if running:
			draw_arc(center, radius * 0.99, -PI * 0.52, PI * 0.10, 28,
					Color(1.0, 0.80, 0.32, 0.92), 3.2 * u, true)

		# Four filled directional chevrons.
		var tip_r := radius * 0.80
		var back_r := radius * 0.635
		var half_w := radius * 0.125
		for i in 4:
			var ang := -PI * 0.5 + float(i) * PI * 0.5
			var dir := Vector2(cos(ang), sin(ang))
			var perp := Vector2(-dir.y, dir.x)
			var tip := center + dir * tip_r
			var back := center + dir * back_r
			var p := PackedVector2Array([back + perp * half_w, tip, back - perp * half_w])
			draw_colored_polygon(p, Color(accent.r, accent.g, accent.b, chev_alpha))

		# The knob: cream disc, dark rim, small gold core when running.
		var knob := center + value * maxf(0.0, radius - knob_radius)
		var knob_col := Color(0.94, 0.96, 0.99, 0.96) if active \
				else Color(0.84, 0.87, 0.92, 0.84)
		draw_circle(knob, knob_radius + 3.0 * u, Color(0.01, 0.02, 0.04, 0.36))
		draw_circle(knob, knob_radius, knob_col)
		draw_arc(knob, knob_radius, 0.0, TAU, 48,
				Color(0.10, 0.16, 0.26, 0.48), 1.6 * u, true)
		draw_circle(knob, knob_radius * 0.17,
				Color(1.0, 0.84, 0.32, 0.95) if running else Color(0.26, 0.38, 0.58, 0.55))


class ButtonBadge:
	extends Control
	## Dark circular badge with a gold arc, shared by every touch action.
	## The RUN button uses a right-hand arc (as in the reference shot); the
	## action icons use the top arc from the icon reference sheet.
	const ICONS := preload("res://src/ui/ui_icons.gd")
	var arc_alpha: float = 0.92
	var arc_from: float = PI * 1.06
	var arc_to: float = TAU * 0.99

	func _draw() -> void:
		ICONS.badge(self, size * 0.5, minf(size.x, size.y) * 0.5 - 1.0,
				arc_alpha, arc_from, arc_to)

	func set_alpha(value: float) -> void:
		if is_equal_approx(arc_alpha, value):
			return
		arc_alpha = value
		queue_redraw()


class ButtonGlyph:
	extends Control
	## White glyph from the shared UI icon set; the action icon follows the
	## current interaction (door, talk, cart, book, water, ...).
	const ICONS := preload("res://src/ui/ui_icons.gd")
	var kind: String = "hand"
	var colour: Color = Color(0.965, 0.975, 1.0)

	func _draw() -> void:
		var pad := minf(size.x, size.y) * 0.25
		ICONS.draw_glyph(self, kind, Rect2(Vector2.ZERO, size).grow(-pad), colour, -1.0)

	func set_kind(value: String) -> void:
		if value == kind:
			return
		kind = value
		queue_redraw()


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
var _e_icon: ButtonGlyph
var _g_icon: ButtonGlyph
var _bag_icon: ButtonGlyph
var _run_icon: ButtonGlyph
var _button_e: Button
var _button_g: Button
var _button_bag: Button
var _button_next: Button
var _button_run: Button
var _pill_run: PanelContainer
var _pill_e: PanelContainer
var _pill_run_label: Label
var _pill_e_label: Label
var _ui_scale: float = 1.0
var _safe: Vector4 = Vector4.ZERO
var _style_scale: float = -1.0
var _joy_run: bool = false
var _run_latched: bool = false
var _run_effective: bool = false
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

	_button_run = _make_button("", BTN_RUN, "run", "right")
	_button_run.pressed.connect(_on_run_toggled)
	_run_icon = _button_run.get_meta("glyph") as ButtonGlyph

	_button_e = _make_button("", BTN_E, "hand")
	_button_e.pressed.connect(_on_interact)
	_e_icon = _button_e.get_meta("glyph") as ButtonGlyph
	_button_g = _make_button("", BTN_G, "salute")
	_button_g.pressed.connect(_on_salute)
	_button_g.visible = false
	_g_icon = _button_g.get_meta("glyph") as ButtonGlyph
	_button_bag = _make_button("", BTN_G, "bag")
	_button_bag.pressed.connect(_on_bag)
	_button_bag.visible = true
	_bag_icon = _button_bag.get_meta("glyph") as ButtonGlyph
	_button_next = _make_button("NEXT", BTN_NEXT)
	_button_next.pressed.connect(_on_next)
	_button_next.visible = false

	_pill_run = _make_pill()
	_pill_run_label = _pill_run.get_child(0) as Label
	_pill_run_label.text = "RUN"
	_pill_e = _make_pill()
	_pill_e_label = _pill_e.get_child(0) as Label
	_pill_e_label.text = "INTERACT"

	_root.resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	_layout()


# ------------------------------------------------------------------ controls

func _make_button(text: String, diameter: float, glyph: String = "",
		arc_side: String = "top") -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.grow_horizontal = Control.GROW_DIRECTION_END
	button.grow_vertical = Control.GROW_DIRECTION_END
	button.size = Vector2(diameter, diameter)
	button.pivot_offset = Vector2(diameter, diameter) * 0.5
	button.add_theme_font_size_override("font_size", int(diameter * 0.34))
	button.add_theme_color_override("font_color", Color(1, 1, 1, 0.97))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.45, 1))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if glyph != "":
		# Icon button: a dark circular badge + white glyph draws the frame,
		# so the Button itself stays transparent.
		var badge := ButtonBadge.new()
		if arc_side == "right":
			badge.arc_from = -PI * 0.50
			badge.arc_to = PI * 0.55
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.set_anchors_preset(Control.PRESET_FULL_RECT)
		button.add_child(badge)
		button.set_meta("badge", badge)
		var icon := ButtonGlyph.new()
		icon.kind = glyph
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		button.add_child(icon)
		button.set_meta("glyph", icon)
		for state in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_root.add_child(button)
	_buttons.append(button)
	return button


func _make_pill() -> PanelContainer:
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.030, 0.045, 0.070, 0.90)
	sb.border_color = Color(1.0, 0.80, 0.32, 0.28)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(999)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 3.0
	sb.content_margin_bottom = 3.0
	pill.add_theme_stylebox_override("panel", sb)
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.98, 0.98, 0.98, 0.95))
	label.add_theme_constant_override("outline_size", 0)
	pill.add_child(label)
	_root.add_child(pill)
	return pill


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
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style


func _apply_button_style(button: Button, state: int) -> void:
	## state: 0 = idle, 1 = available (the action can be used), 2 = latched.
	var badge: ButtonBadge = null
	if button.has_meta("badge"):
		badge = button.get_meta("badge") as ButtonBadge
	if badge != null:
		# Only the gold arc changes; the dark badge and white glyph stay put.
		match state:
			0: badge.set_alpha(0.78)
			1: badge.set_alpha(0.98)
			2: badge.set_alpha(1.0)
		return
	var diameter: float = button.size.x
	var radius := diameter * 0.5
	match state:
		1:
			button.add_theme_stylebox_override("normal",
					_button_style(Color(0.10, 0.16, 0.28, 0.80), Color(1.0, 0.86, 0.34, 0.98), 3.0, radius))
			button.add_theme_stylebox_override("hover",
					_button_style(Color(0.15, 0.24, 0.40, 0.90), Color(1.0, 0.92, 0.45, 1.0), 3.0, radius))
			button.add_theme_stylebox_override("pressed",
					_button_style(Color(0.22, 0.34, 0.52, 0.95), Color(1.0, 0.94, 0.48, 1.0), 3.0, radius))
		2:
			button.add_theme_stylebox_override("normal",
					_button_style(Color(0.30, 0.23, 0.08, 0.88), Color(1.0, 0.88, 0.36, 1.0), 3.0, radius))
			button.add_theme_stylebox_override("hover",
					_button_style(Color(0.40, 0.31, 0.10, 0.94), Color(1.0, 0.93, 0.45, 1.0), 3.0, radius))
			button.add_theme_stylebox_override("pressed",
					_button_style(Color(0.48, 0.37, 0.12, 0.96), Color(1.0, 0.90, 0.40, 1.0), 3.0, radius))
		_:
			button.add_theme_stylebox_override("normal",
					_button_style(Color(0.05, 0.09, 0.16, 0.70), Color(0.85, 0.90, 1.0, 0.38), 2.0, radius))
			button.add_theme_stylebox_override("hover",
					_button_style(Color(0.09, 0.15, 0.26, 0.82), Color(0.90, 0.94, 1.0, 0.60), 2.0, radius))
			button.add_theme_stylebox_override("pressed",
					_button_style(Color(0.14, 0.22, 0.36, 0.90), Color(1.0, 0.88, 0.40, 0.95), 2.5, radius))


func _apply_run_style() -> void:
	_apply_button_style(_button_run, 2 if _run_latched else 0)


func _emit_run_effective() -> void:
	var effective := _run_latched or _joy_run
	if effective == _run_effective:
		return
	_run_effective = effective
	_draw_layer.running = effective
	_draw_layer.queue_redraw()
	run_changed.emit(effective)


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
	_draw_layer.knob_radius = radius * 0.32
	_draw_layer.queue_redraw()

	# --- right hand cluster: caption pills always sit at the bottom edge ---
	var d_e := BTN_E * s
	var d_r := BTN_RUN * s
	var d_g := BTN_G * s
	var d_b := BTN_G * s
	var d_n := BTN_NEXT * s
	var gap := BTN_GAP * s
	var edge := BTN_EDGE * s
	var pill_h := PILL_H * s
	var pill_gap := PILL_GAP * s
	var right_edge := view.x - _safe.z - edge
	var bottom_edge := view.y - _safe.w - edge
	var pill_y := bottom_edge - pill_h
	var button_y := pill_y - pill_gap - maxf(d_e, d_r)

	_place(_button_e, Vector2(right_edge - d_e, button_y + (maxf(d_e, d_r) - d_e)), d_e)
	_place(_button_run, Vector2(right_edge - d_e - gap - d_r, button_y + (maxf(d_e, d_r) - d_r)), d_r)
	_place(_button_g, Vector2(right_edge - d_g, button_y - gap - d_g), d_g)
	_place(_button_bag, Vector2(right_edge - d_g - gap - d_b, button_y - gap - d_b), d_b)
	# NEXT replaces E in the same slot while a dialogue is open.
	_place(_button_next, Vector2(right_edge - d_n, button_y + (maxf(d_e, d_n) - d_n)), d_n)

	_place_pill(_pill_run, Vector2(_button_run.position.x + d_r * 0.5, pill_y), pill_h, s)
	_place_pill(_pill_e, Vector2(_button_e.position.x + d_e * 0.5, pill_y), pill_h, s)

	if not is_equal_approx(s, _style_scale):
		_style_scale = s
		for button in _buttons:
			button.add_theme_font_size_override("font_size", int(button.size.x * 0.34))
		_apply_button_style(_button_e, 1 if _action_available else 0)
		_apply_button_style(_button_g, 1 if _salute_available else 0)
		_apply_button_style(_button_bag, 0)
		_apply_button_style(_button_next, 0)
		_apply_run_style()
		_pill_run_label.add_theme_font_size_override("font_size", int(round(11.0 * s)))
		_pill_e_label.add_theme_font_size_override("font_size", int(round(11.0 * s)))
		_pill_run_label.add_theme_constant_override("outline_size", 2)
		_pill_e_label.add_theme_constant_override("outline_size", 2)
		_pill_run_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
		_pill_e_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))


func _place(button: Button, pos: Vector2, diameter: float) -> void:
	button.size = Vector2(diameter, diameter)
	button.pivot_offset = Vector2(diameter, diameter) * 0.5
	button.position = pos


func _place_pill(pill: PanelContainer, centre: Vector2, height: float, s: float) -> void:
	pill.reset_size()
	pill.size = Vector2(0, height)
	var min_w := pill.get_combined_minimum_size().x
	pill.size = Vector2(min_w, height)
	pill.position = Vector2(centre.x - min_w * 0.5, centre.y)


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
	# Pushing the stick to the outer ring runs; easing back releases it.
	var auto_run := value.length() >= (RUN_OFF if _joy_run else RUN_ON)
	if auto_run != _joy_run:
		_joy_run = auto_run
		_emit_run_effective()
	_draw_layer.value = value
	if not _draw_layer.active:
		_draw_layer.active = true
	_draw_layer.queue_redraw()


func _release_joystick() -> void:
	if _joy_value != Vector2.ZERO:
		_joy_value = Vector2.ZERO
		move_changed.emit(Vector2.ZERO)
	if _joy_run:
		_joy_run = false
		_emit_run_effective()
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


func _on_bag() -> void:
	bag_pressed.emit()


func _on_next() -> void:
	## The explicit "next" button advances the dialogue.  It reuses `tapped`
	## so the game side does not need to know about it.
	tapped.emit()


func _on_run_toggled() -> void:
	_run_latched = not _run_latched
	_apply_run_style()
	_emit_run_effective()


## Optional: drive the NEXT button from the game instead of the `Dialogue`
## autoload.  Called by nothing today, kept so the HUD/game can take over.
func set_dialogue_open(open: bool) -> void:
	_dialogue_override = 1 if open else 0
	_update_dialogue_state()


## Optional: light up (or dim) the E button by hand.
func set_action_available(available: bool) -> void:
	_action_override = 1 if available else 0
	_update_action_state()


## The E button copies the HUD prompt glyph, so the touch prompt and the
## desktop prompt always show the same action icon (door, talk, cart, ...).
func set_action_icon(kind: String) -> void:
	if _e_icon == null:
		return
	_e_icon.set_kind(kind if kind != "" else "hand")


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


func _update_dialogue_state() -> void:
	var open := false
	if _dialogue_override >= 0:
		open = _dialogue_override == 1
	elif Dialogue:
		open = Dialogue.active
	if open == _dialogue_open:
		return
	_dialogue_open = open
	_refresh_button_visibility()
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
	_pill_e_label.add_theme_color_override("font_color",
			Color(1.0, 0.84, 0.32) if available else Color(0.98, 0.98, 0.98, 0.95))
	_refresh_button_visibility()


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
	_refresh_button_visibility()


## E and RUN stay on screen (dimmed or gold); G is context-only; NEXT only
## replaces E while a dialogue is open.
func _refresh_button_visibility() -> void:
	_button_e.visible = not _dialogue_open
	_button_run.visible = not _dialogue_open
	_button_g.visible = _salute_available and not _dialogue_open
	if _button_bag:
		_button_bag.visible = not _dialogue_open
	_button_next.visible = _dialogue_open
	_pill_e.visible = _button_e.visible
	_pill_run.visible = _button_run.visible


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
