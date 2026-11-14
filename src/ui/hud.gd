extends CanvasLayer
## ---------------------------------------------------------------------------
## In-game HUD - layout at a glance (mobile-game style).
##
##   +---------------------------------------------------------------+
##   | [ (pin) MISSION 1 / 8   Talk to ...          > ]  [ (coin) 200 ][ || ] |
##   |                                                        [ MINIMAP ]  |
##   |                     ( toast )                              |            |
##   |                                                              |
##   |                [ INTERACTION PROMPT ]                        |
##   |                [ SUBTITLE ]                                  |
##   |                [ DIALOGUE BOX ]                              |
##   | [ KEY HINTS - desktop only ]                                 |
##   +---------------------------------------------------------------+
##
## Every size is multiplied by `_ui_scale`, a single factor derived from the
## physical screen (dpi) and the canvas/pixel ratio, so the same layout is
## legible on a 1080p desktop, a 4K desktop and on phones in portrait or in
## landscape.  Screen-edge insets honour the display safe area (notches,
## punch holes, the home bar).  In touch mode the keyboard legend is hidden
## and the bottom of the screen is reserved for the on-screen controls.
##
## Public API used by src/main.gd (unchanged):
##   set_mission(index, total, text) / update_wallet(wallet, bank)
##   update_energy(value) / set_prompt(text) / show_dialogue(speaker, text)
##   hide_dialogue() / show_subtitle(text) / toast(text, seconds)
##   update_player_marker(world_pos) / property `touch_mode_override`
## Signals: pause_requested / resume_requested / menu_requested (pause overlay)
## ---------------------------------------------------------------------------

signal pause_requested
signal resume_requested
signal menu_requested

# ----------------------------------------------------------------- public API
var mission_label: Label
var mission_title: Label
var mission_distance: Label
var dialogue_panel: Control
var dialogue_name: Label
var dialogue_text: Label
var subtitle_label: Label
var wallet_label: Label
var energy_bar: ProgressBar
var energy_label: Label
var prompt_panel: PanelContainer
var prompt_key: TextureRect
var prompt_label: Label
var controls_bar: PanelContainer
var toast_label: Label
var minimap: TextureRect
var minimap_marker: MinimapMarker
var pause_overlay: PanelContainer

var touch_mode_override: int = -1
var _dialogue_art: DialogueArt
var _portrait: TextureRect
var _next_hint: NextHint
var _next_button: Button
var _type_full: String = ""
var _type_shown: float = 0.0
var _type_running: bool = false
const TYPE_CPS := 55.0

# -------------------------------------------------------------------- tuning
const BASE_MINIMAP := 188        ## on-screen size of the minimap, unscaled
const MINIMAP_TEX_LONG := 920     ## baked map texture resolution (crisp labels + mipmap downscale)
const TOUCH_ZONE := 250.0        ## canvas units reserved at the bottom for the pad
const REF_DPI := 96.0            ## dpi of the reference (1080p desktop) screen

# ----------------------------------------------------------------- internals
var _touch: bool = false
var _toast_time: float = 0.0
var _root: Control
var _bottom: VBoxContainer
var _mission_panel: PanelContainer
var _mission_row: HBoxContainer
var _wallet_panel: PanelContainer
var _pause_button: Button
var _pause_row: HBoxContainer
var _objective_base: String = ""
var _paused_title: Label
var _paused_sub: Label
var _north_badge: PanelContainer
var _north_label: Label
var _ui_scale: float = 1.0
var _safe: Vector4 = Vector4.ZERO
var _objective_valid: bool = false
var _objective_plan: Vector2 = Vector2.ZERO
var _objective_world: Vector3 = Vector3.ZERO
var _player: Node = null
var _player_retry: float = 0.0
var _distance_text: String = ""
var _map_extent: Rect2 = Rect2(0, 0, 100, 100)
var _map_tex: Vector2 = Vector2(BASE_MINIMAP, BASE_MINIMAP)
var _key_icons: Array[TextureRect] = []
var _key_labels: Array[Label] = []
var _pips: StepPips = null
var _toast_panel: PanelContainer = null
var _toast_tween: Tween = null
var _toast_hiding: bool = false
var _pause_card: PanelContainer = null
var _pause_buttons: Array[Button] = []
var _entrance_played: bool = false
var _last_wallet: int = -1
var _energy_tween: Tween = null
var _energy_bucket: int = -1
var _line_tween: Tween = null
var _mission_calls: int = 0


class MinimapMarker:
	extends Control
	## Player arrow + objective dot drawn on top of the minimap texture.
	## The arrow is rotated every frame into the player's heading.  A pulsing
	## objective ring, a dotted bearing line and four compass ticks make the
	## little map easier to read at a glance.

	var point := Vector2.ZERO
	var has_player := false
	var heading: float = -PI * 0.5
	var mission_point := Vector2.ZERO
	var has_mission := false
	var _t: float = 0.0

	func _process(delta: float) -> void:
		if not visible:
			return
		_t += delta
		if has_mission or has_player:
			queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		# Compass ticks inside the border; the north tick is longer and gold.
		var tick := Color(0.72, 0.86, 1.0, 0.55)
		draw_line(Vector2(c.x, 4.0), Vector2(c.x, 11.0), Color(1.0, 0.85, 0.4, 0.9), 2.0, true)
		draw_line(Vector2(c.x, size.y - 4.0), Vector2(c.x, size.y - 9.0), tick, 1.6, true)
		draw_line(Vector2(4.0, c.y), Vector2(9.0, c.y), tick, 1.6, true)
		draw_line(Vector2(size.x - 4.0, c.y), Vector2(size.x - 9.0, c.y), tick, 1.6, true)
		if has_mission and has_player:
			# A dotted bearing line from the player to the objective.
			var delta := mission_point - point
			var dist := delta.length()
			if dist > 26.0:
				var dir := delta / dist
				var steps := mini(7, int(dist / 16.0))
				for i in steps:
					var t := (float(i) + 0.6) / float(steps)
					draw_circle(point + delta * t, 1.7, Color(1.0, 0.86, 0.42, 0.40))
		if has_mission:
			var pulse := 0.5 + 0.5 * sin(_t * 2.8)
			draw_arc(mission_point, 6.0 + pulse * 4.2, 0.0, TAU, 24,
					Color(0.48, 1.0, 0.55, 0.45 * (1.0 - pulse)), 1.6, true)
			draw_circle(mission_point, 5.4, Color(0.03, 0.10, 0.05, 0.9))
			draw_circle(mission_point, 3.4, Color(0.45, 1.0, 0.52, 0.98))
		if not has_player:
			return
		var dir := Vector2(cos(heading), sin(heading))
		var side := Vector2(-dir.y, dir.x)
		var a := 8.6
		# white backplate, then the blue navigation arrow
		var tip := point + dir * a * 1.42
		var b1 := point - dir * a * 0.86 + side * a * 0.98
		var b2 := point - dir * a * 0.86 - side * a * 0.98
		draw_colored_polygon(PackedVector2Array([tip, b1, b2]), Color(0.98, 0.99, 1.0, 0.97))
		var tip2 := point + dir * a * 1.02
		var c1 := point - dir * a * 0.52 + side * a * 0.66
		var c2 := point - dir * a * 0.52 - side * a * 0.66
		draw_colored_polygon(PackedVector2Array([tip2, c1, c2]), Color(0.15, 0.38, 0.92, 0.99))


class MapView:
	extends Control
	## Flat top-down campus plan: green ground, asphalt roads, zone slabs and
	## tinted building footprints. Building names are added as Label children
	## by the baker so the map reads like a town plan.

	var campus: Dictionary = {}
	var extent: Array = [0.0, 0.0, 100.0, 100.0]

	func _to_tex(rect: Array, sx: float, sy: float, ox: float, oy: float) -> Rect2:
		var x0 := (float(rect[0]) - ox) * sx
		var y0 := (float(rect[1]) - oy) * sy
		var x1 := (float(rect[2]) - ox) * sx
		var y1 := (float(rect[3]) - oy) * sy
		return Rect2(x0, y0, x1 - x0, y1 - y0)

	func _draw() -> void:
		var sx := size.x / maxf(1.0, float(extent[2]) - float(extent[0]))
		var sy := size.y / maxf(1.0, float(extent[3]) - float(extent[1]))
		draw_rect(Rect2(Vector2.ZERO, size), Color.html("#5fa04b"))
		# roads
		for r in campus.get("roads", []):
			if r.size() >= 4:
				draw_rect(_to_tex(r, sx, sy, float(extent[0]), float(extent[1])), Color.html("#555a63"))
		var zones: Dictionary = campus.get("zones", {})
		var zone_fill := {
			"parade_ground": "#d9c491",
			"basketball": "#b96a45",
			"track": "#2f6b3a",
			"parking": "#6f747b",
		}
		for key in zone_fill:
			var z = zones.get(key, [])
			if z is Array and z.size() >= 4:
				draw_rect(_to_tex(z, sx, sy, float(extent[0]), float(extent[1])), Color.html(str(zone_fill[key])))
		# buildings with a darker outline so they read at small sizes
		for b in campus.get("buildings", []):
			var rect = b.get("rect", [])
			if rect.size() < 4:
				continue
			var r := _to_tex(rect, sx, sy, float(extent[0]), float(extent[1]))
			var col := Color(str(b.get("color", "#cccccc")))
			draw_rect(r, col)
			draw_rect(r, col.darkened(0.55), false, maxf(1.0, size.y / 300.0))
			draw_rect(r.grow(-0.5), Color(1.0, 1.0, 1.0, 0.16), false, 1.0)


## ------------------------------------------------------------ icons

class PinIcon:
	extends Control
	## Location pin in a dark disc - drawn so it stays crisp at any scale.

	func _draw() -> void:
		var u := minf(size.x, size.y) / 48.0
		var c := Vector2(size.x * 0.5, size.y * 0.5)
		draw_circle(c, 23.0 * u, Color(0.09, 0.16, 0.29, 0.92))
		draw_arc(c, 22.0 * u, 0.0, TAU, 40, Color(0.38, 0.66, 1.0, 0.85), 2.2 * u, true)
		var pc := Vector2(size.x * 0.5, size.y * 0.42)
		var pr := 8.6 * u
		draw_circle(pc, pr, Color(0.96, 0.97, 1.0))
		var tail := PackedVector2Array([
			pc + Vector2(-pr * 0.74, pr * 0.58),
			pc + Vector2(pr * 0.74, pr * 0.58),
			pc + Vector2(0.0, pr * 2.25)])
		draw_colored_polygon(tail, Color(0.96, 0.97, 1.0))
		draw_circle(pc, pr * 0.44, Color(0.09, 0.16, 0.29))

class CoinIcon:
	extends Control
	## Stylised gold coin for the wallet pill.

	func _draw() -> void:
		var u := minf(size.x, size.y) / 44.0
		var c := size * 0.5
		draw_circle(c, 19.0 * u, Color(1.0, 0.83, 0.29))
		draw_arc(c, 13.6 * u, 0.0, TAU, 40, Color(0.72, 0.50, 0.10), 3.6 * u, true)
		draw_circle(c, 10.2 * u, Color(0.98, 0.80, 0.32))
		draw_arc(c, 16.4 * u, PI * 1.05, PI * 1.55, 24, Color(1.0, 0.97, 0.72, 0.9), 2.4 * u, true)

class BoltIcon:
	extends Control
	## Small green lightning bolt for the energy row.

	func _draw() -> void:
		var u := minf(size.x, size.y) / 24.0
		var pts := PackedVector2Array([
			Vector2(13.5, 1.5), Vector2(5.0, 13.0), Vector2(11.0, 13.0),
			Vector2(9.0, 22.5), Vector2(19.0, 10.0), Vector2(13.0, 10.0)])
		var scaled := PackedVector2Array()
		for p in pts:
			scaled.append(p * u)
		draw_colored_polygon(scaled, Color(0.55, 0.95, 0.55, 0.95))

class ChevronIcon:
	extends Control
	## ">" affordance shown on the right edge of the mission pill.

	func _draw() -> void:
		var u := minf(size.x, size.y)
		var p := PackedVector2Array([
			Vector2(0.32 * size.x, 0.22 * size.y),
			Vector2(0.66 * size.x, 0.50 * size.y),
			Vector2(0.32 * size.x, 0.78 * size.y)])
		draw_polyline(p, Color(0.55, 0.76, 1.0, 0.95), maxf(2.0, u * 0.085), true)


class SparkIcon:
	extends Control
	## Small gold four-point sparkle used by the toast pill.

	func _draw() -> void:
		var u := minf(size.x, size.y) / 24.0
		var c := size * 0.5
		var pts := PackedVector2Array()
		for i in 8:
			var ang := -PI * 0.5 + float(i) * TAU / 8.0
			var r := (9.5 if i % 2 == 0 else 3.4) * u
			pts.append(c + Vector2(cos(ang), sin(ang)) * r)
		draw_colored_polygon(pts, Color(1.0, 0.85, 0.34, 0.98))
		draw_circle(c, 2.2 * u, Color(1.0, 0.97, 0.80, 1.0))


class StepPips:
	extends Control
	## The eight mission steps as a row of dots: gold for completed steps,
	## a glowing ring for the current one, dim for the rest.  Gives the player
	## an instant read on how far into the day they are without another label.

	var total: int = 8
	var index: int = 0

	func _draw() -> void:
		var n := maxi(total, 1)
		var d := maxf(4.0, size.y * 0.52)
		var gap := d * 0.9
		var row_w := float(n) * d + float(n - 1) * gap
		var x := (size.x - row_w) * 0.5
		var y := size.y * 0.5
		for i in n:
			var c := Vector2(x + float(i) * (d + gap) + d * 0.5, y)
			if i < index:
				draw_circle(c, d * 0.46, Color(1.0, 0.78, 0.26, 0.95))
			elif i == index:
				draw_circle(c, d * 0.66, Color(1.0, 0.90, 0.52, 0.24))
				draw_circle(c, d * 0.46, Color(1.0, 0.92, 0.62, 1.0))
			else:
				draw_circle(c, d * 0.34, Color(0.82, 0.88, 1.0, 0.24))


class PauseGlyph:
	extends Control
	## Two white bars - the pause affordance.

	func _draw() -> void:
		var u := minf(size.x, size.y) / 44.0
		var w := 5.4 * u
		var h := 19.0 * u
		var y := (size.y - h) * 0.5
		var gap := 6.6 * u
		var x0 := (size.x - (2.0 * w + gap)) * 0.5
		draw_rect(Rect2(x0, y, w, h), Color(0.96, 0.97, 1.0))
		draw_rect(Rect2(x0 + w + gap, y, w, h), Color(0.96, 0.97, 1.0))


class DialogueArt:
	extends Control
	## The dark brush panel behind the dialogue: layered near-black slabs, a
	## pair of gold slashes behind the portrait and a gold rule under the
	## speaker name. Drawn once per layout, never per frame.
	##
	## `slash_x` is where the gold slashes sit, `frame` is the rounded gold
	## plate drawn behind the portrait. All in control units.
	var slash_x := 150.0
	var frame := Rect2(0, 0, 100, 100)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		# Back shadow slab, offset, then the main body with a hand-cut edge.
		var back := PackedVector2Array([
			Vector2(14.0, 12.0), Vector2(w - 30.0, 8.0), Vector2(w - 4.0, 40.0),
			Vector2(w - 12.0, h - 8.0), Vector2(30.0, h - 4.0), Vector2(4.0, h * 0.5)])
		draw_colored_polygon(back, Color(0.0, 0.0, 0.0, 0.45))
		var body := PackedVector2Array([
			Vector2(10.0, 8.0), Vector2(w - 34.0, 4.0), Vector2(w - 2.0, 36.0),
			Vector2(w - 10.0, h - 6.0), Vector2(26.0, h - 2.0), Vector2(2.0, h * 0.44)])
		draw_colored_polygon(body, Color(0.015, 0.028, 0.055, 0.94))
		# Inner rim light along the top edge.
		draw_polyline(PackedVector2Array([
			Vector2(12.0, 9.0), Vector2(w - 34.0, 5.0), Vector2(w - 3.0, 37.0)]),
			Color(1.0, 1.0, 1.0, 0.10), 1.6, true)
		# Gold slashes behind the portrait shoulder area.
		var x := slash_x
		var gold := Color(0.86, 0.66, 0.18)
		var gold_hi := Color(1.0, 0.85, 0.38)
		var s1 := PackedVector2Array([
			Vector2(x, 0.0), Vector2(x + h * 0.42, 0.0),
			Vector2(x + h * 0.05, h), Vector2(x - h * 0.37, h)])
		draw_colored_polygon(s1, gold)
		var s2 := PackedVector2Array([
			Vector2(x + h * 0.46, 0.0), Vector2(x + h * 0.58, 0.0),
			Vector2(x + h * 0.21, h), Vector2(x + h * 0.09, h)])
		draw_colored_polygon(s2, gold_hi)
		# Gold rule under the name.
		var rule_y := h * 0.315
		draw_line(Vector2(x + h * 0.50, rule_y), Vector2(w - 36.0, rule_y),
				Color(0.86, 0.66, 0.18, 0.9), 2.0)
		# The portrait's rounded gold plate.
		if frame.size.x > 4.0:
			_fill_rrect(frame, 24.0, gold)
			_fill_rrect(frame.grow(-7.0), 18.0, Color(0.015, 0.028, 0.055, 0.97))

	func _fill_rrect(rect: Rect2, radius: float, color: Color) -> void:
		var pts := PackedVector2Array()
		var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
		var corners := [
			Vector2(rect.position.x + r, rect.position.y + r),
			Vector2(rect.end.x - r, rect.position.y + r),
			Vector2(rect.end.x - r, rect.end.y - r),
			Vector2(rect.position.x + r, rect.end.y - r)]
		var arcs := [[PI, PI * 1.5], [PI * 1.5, TAU], [0.0, PI * 0.5], [PI * 0.5, PI]]
		for i in 4:
			var a: Array = arcs[i]
			var center: Vector2 = corners[i]
			var steps := 7
			for j in range(steps + 1):
				var t := float(j) / float(steps)
				var ang: float = float(a[0]) + (float(a[1]) - float(a[0])) * t
				pts.append(center + Vector2(cos(ang), sin(ang)) * r)
		draw_colored_polygon(pts, color)


class NextHint:
	extends Control
	## Small gold downward triangle shown when a line is ready to advance.
	var flash := 1.0

	func _draw() -> void:
		var u := minf(size.x, size.y) / 22.0
		var c := size * 0.5
		var pts := PackedVector2Array([
			Vector2(c.x - 7.5 * u, c.y - 4.0 * u),
			Vector2(c.x + 7.5 * u, c.y - 4.0 * u),
			Vector2(c.x, c.y + 7.0 * u)])
		draw_colored_polygon(pts, Color(1.0, 0.83, 0.30, clampf(flash, 0.15, 1.0)))


func _ready() -> void:
	layer = 10
	_touch = Settings.is_touch_mode() if Settings else false
	if touch_mode_override >= 0:
		_touch = touch_mode_override == 1
	_build()
	get_viewport().size_changed.connect(_relayout)
	_root.resized.connect(_relayout)
	_relayout()
	_play_entrance()


# ------------------------------------------------------- shared device maths

static func compute_ui_scale(view_size: Vector2, window_size: Vector2) -> float:
	## One factor that turns the 1080p reference sizes into the right size for
	## the current screen.
	##
	##   * `view_size` is the canvas size, `window_size` the physical pixels.
	##     The ratio tells how many canvas units one physical pixel covers: a
	##     phone in portrait squeezes a 1920-wide canvas into 1080 pixels, so
	##     the UI has to grow to stay readable.
	##   * Phones report 300-450 dpi, desktops ~96, so a label that is 18 px
	##     on a laptop should be physically bigger on a phone.
	var scale := 1.0
	if view_size.x > 0.0 and window_size.x > 0:
		scale = view_size.x / float(window_size.x)
	var dpi := DisplayServer.screen_get_dpi()
	if dpi > 0:
		scale *= clampf(float(dpi) / REF_DPI, 1.0, 2.2)
	return clampf(scale, 0.75, 2.2)


static func safe_area_insets(view_size: Vector2, window_size: Vector2) -> Vector4:
	## Screen-edge insets (notches, punch holes, the home bar) in canvas
	## units: x = left, y = top, z = right, w = bottom.
	var insets := Vector4.ZERO
	if window_size.x <= 0 or window_size.y <= 0 or view_size.x <= 0.0:
		return insets
	var units_per_px := view_size.x / float(window_size.x)
	var left := 0.0
	var top := 0.0
	var right := 0.0
	var bottom := 0.0
	var safe := DisplayServer.get_display_safe_area()
	# Only trust the screen rect when the window actually fits inside it.
	if safe.size.x > 0 and safe.size.y > 0 \
			and safe.size.x <= window_size.x and safe.size.y <= window_size.y:
		left = maxf(left, float(safe.position.x))
		top = maxf(top, float(safe.position.y))
		right = maxf(right, float(window_size.x - safe.end.x))
		bottom = maxf(bottom, float(window_size.y - safe.end.y))
	return Vector4(left / units_per_px, top / units_per_px,
			right / units_per_px, bottom / units_per_px)


# ---------------------------------------------------------------------- build

func _build() -> void:
	_root = Control.new()
	_root.name = "HudRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# --- mission panel (top left, rounded navy pill) ---
	_mission_panel = PanelContainer.new()
	_mission_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mission_panel.grow_horizontal = Control.GROW_DIRECTION_END
	_mission_panel.grow_vertical = Control.GROW_DIRECTION_END
	_root.add_child(_mission_panel)
	_mission_row = HBoxContainer.new()
	_mission_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mission_row.add_theme_constant_override("separation", 12)
	_mission_panel.add_child(_mission_row)
	var pin := PinIcon.new()
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin.custom_minimum_size = Vector2(46, 46)
	pin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_mission_row.add_child(pin)
	var text_col := VBoxContainer.new()
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_col.add_theme_constant_override("separation", 0)
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_mission_row.add_child(text_col)
	var title_row := HBoxContainer.new()
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_theme_constant_override("separation", 8)
	text_col.add_child(title_row)
	mission_title = Label.new()
	mission_title.text = "MISSION 1 / 8"
	mission_title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.98))
	mission_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
	mission_title.add_theme_constant_override("outline_size", 3)
	mission_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(mission_title)
	# Distance sits on the title row, right-aligned in gold.
	mission_distance = Label.new()
	mission_distance.text = ""
	mission_distance.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mission_distance.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mission_distance.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
	mission_distance.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	mission_distance.add_theme_constant_override("outline_size", 3)
	mission_distance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(mission_distance)
	mission_label = Label.new()
	mission_label.text = ""
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_label.add_theme_color_override("font_color", Color(0.76, 0.83, 0.95, 0.96))
	text_col.add_child(mission_label)
	_pips = StepPips.new()
	_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pips.custom_minimum_size = Vector2(0, 10)
	text_col.add_child(_pips)
	var chevron := ChevronIcon.new()
	chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chevron.custom_minimum_size = Vector2(30, 46)
	chevron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_mission_row.add_child(chevron)

	# --- wallet + energy (top right) ---
	_wallet_panel = PanelContainer.new()
	_wallet_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wallet_panel.anchor_left = 1.0
	_wallet_panel.anchor_right = 1.0
	_wallet_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_wallet_panel.grow_vertical = Control.GROW_DIRECTION_END
	_root.add_child(_wallet_panel)
	var right := VBoxContainer.new()
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_theme_constant_override("separation", 4)
	_wallet_panel.add_child(right)
	var coin_row := HBoxContainer.new()
	coin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	coin_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_row.add_theme_constant_override("separation", 8)
	right.add_child(coin_row)
	var coin := CoinIcon.new()
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin.custom_minimum_size = Vector2(30, 30)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coin_row.add_child(coin)
	wallet_label = Label.new()
	wallet_label.text = "200"
	wallet_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wallet_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.98))
	wallet_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
	wallet_label.add_theme_constant_override("outline_size", 3)
	coin_row.add_child(wallet_label)
	var energy_row := HBoxContainer.new()
	energy_row.alignment = BoxContainer.ALIGNMENT_END
	energy_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_row.add_theme_constant_override("separation", 6)
	right.add_child(energy_row)
	var bolt := BoltIcon.new()
	bolt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bolt.custom_minimum_size = Vector2(18, 18)
	bolt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	energy_row.add_child(bolt)
	energy_label = Label.new()
	energy_label.text = "40"
	energy_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	energy_label.add_theme_constant_override("outline_size", 4)
	energy_row.add_child(energy_label)
	energy_bar = ProgressBar.new()
	energy_bar.custom_minimum_size = Vector2(120, 14)
	energy_bar.max_value = 100
	energy_bar.value = 40
	energy_bar.show_percentage = false
	energy_bar.add_theme_stylebox_override("background", _bar_style(Color(0.05, 0.09, 0.17, 0.85)))
	energy_bar.add_theme_stylebox_override("fill", _bar_style(Color(0.34, 0.84, 0.44, 0.95)))
	energy_row.add_child(energy_bar)

	# --- pause button (top right corner) ---
	_pause_button = Button.new()
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_pause_button.grow_vertical = Control.GROW_DIRECTION_END
	_pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_pause_button.size = Vector2(46, 46)
	_pause_button.pivot_offset = Vector2(23, 23)
	_pause_button.pressed.connect(_on_pause_pressed)
	_root.add_child(_pause_button)
	_add_button_juice(_pause_button)
	var pause_glyph := PauseGlyph.new()
	pause_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_button.add_child(pause_glyph)

	# --- toast (top centre, below the banner band) ---
	_toast_panel = PanelContainer.new()
	_toast_panel.anchor_left = 0.5
	_toast_panel.anchor_right = 0.5
	_toast_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.visible = false
	_root.add_child(_toast_panel)
	var toast_row := HBoxContainer.new()
	toast_row.alignment = BoxContainer.ALIGNMENT_CENTER
	toast_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_row.add_theme_constant_override("separation", 8)
	_toast_panel.add_child(toast_row)
	var spark := SparkIcon.new()
	spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spark.custom_minimum_size = Vector2(20, 20)
	spark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	toast_row.add_child(spark)
	toast_label = Label.new()
	toast_label.text = ""
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_color", Color(0.94, 1.0, 0.95))
	toast_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	toast_label.add_theme_constant_override("outline_size", 3)
	toast_row.add_child(toast_label)

	# --- bottom stack: prompt, subtitle, dialogue ---
	_bottom = VBoxContainer.new()
	_bottom.anchor_left = 0.0
	_bottom.anchor_right = 1.0
	_bottom.anchor_top = 1.0
	_bottom.anchor_bottom = 1.0
	_bottom.offset_top = -320.0
	_bottom.offset_bottom = -20.0
	_bottom.alignment = BoxContainer.ALIGNMENT_END
	_bottom.add_theme_constant_override("separation", 8)
	_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_bottom)

	var prompt_row := HBoxContainer.new()
	prompt_row.alignment = BoxContainer.ALIGNMENT_CENTER
	prompt_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom.add_child(prompt_row)
	prompt_panel = PanelContainer.new()
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_panel.visible = false
	prompt_row.add_child(prompt_panel)
	var prompt_row_inner := HBoxContainer.new()
	prompt_row_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_row_inner.add_theme_constant_override("separation", 8)
	prompt_panel.add_child(prompt_row_inner)
	prompt_key = _key_texture("e")
	prompt_key.visible = not _touch
	prompt_row_inner.add_child(prompt_key)
	prompt_label = Label.new()
	prompt_label.text = ""
	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_label.add_theme_color_override("font_color", Color(1, 0.84, 0.3))
	prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	prompt_label.add_theme_constant_override("outline_size", 4)
	prompt_row_inner.add_child(prompt_label)

	subtitle_label = Label.new()
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_color_override("font_color", Color(1, 1, 1))
	subtitle_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	subtitle_label.add_theme_constant_override("outline_size", 6)
	_bottom.add_child(subtitle_label)

	var dialogue_row := HBoxContainer.new()
	dialogue_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dialogue_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom.add_child(dialogue_row)
	dialogue_panel = Control.new()
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_panel.visible = false
	dialogue_row.add_child(dialogue_panel)

	# The brush-stroke background, drawn once per layout.
	_dialogue_art = DialogueArt.new()
	_dialogue_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dialogue_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_panel.add_child(_dialogue_art)

	# The portrait, sticking out above the panel's top edge like the web build.
	_portrait = TextureRect.new()
	_portrait.name = "Portrait"
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portrait_mat := ShaderMaterial.new()
	var portrait_shader := Shader.new()
	portrait_shader.code = """
shader_type canvas_item;
uniform float radius = 0.17;
void fragment() {
	vec2 p = UV - 0.5;
	vec2 half_box = vec2(0.5);
	vec2 q = abs(p) - (half_box - vec2(radius));
	float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
	if (d > 0.0) {
		discard;
	}
	vec4 tex = texture(TEXTURE, UV);
	COLOR = tex;
}
"""
	portrait_mat.shader = portrait_shader
	_portrait.material = portrait_mat
	_portrait.pivot_offset = Vector2(0.5, 0.5) * 132.0
	dialogue_panel.add_child(_portrait)

	dialogue_name = Label.new()
	dialogue_name.text = ""
	dialogue_name.name = "DialogueName"
	dialogue_name.add_theme_color_override("font_color", Color(1.0, 0.83, 0.31))
	dialogue_name.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.55))
	dialogue_name.add_theme_constant_override("outline_size", 3)
	dialogue_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_panel.add_child(dialogue_name)

	dialogue_text = Label.new()
	dialogue_text.text = ""
	dialogue_text.name = "DialogueText"
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	dialogue_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	dialogue_text.add_theme_constant_override("outline_size", 2)
	dialogue_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_panel.add_child(dialogue_text)

	_next_hint = NextHint.new()
	_next_hint.name = "NextHint"
	_next_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_next_hint.visible = false
	dialogue_panel.add_child(_next_hint)

	_next_button = Button.new()
	_next_button.name = "NextButton"
	_next_button.text = "NEXT"
	_next_button.focus_mode = Control.FOCUS_NONE
	_next_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_next_button.add_theme_color_override("font_color", Color(1.0, 0.85, 0.38))
	_next_button.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.55))
	_next_button.add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 0.65))
	_next_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_next_button.pressed.connect(_on_next_dialogue)
	dialogue_panel.add_child(_next_button)
	_add_button_juice(_next_button)

	# --- minimap (rounded, with an N badge) ---
	minimap = TextureRect.new()
	minimap.stretch_mode = TextureRect.STRETCH_SCALE
	minimap.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	minimap.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	minimap.grow_vertical = Control.GROW_DIRECTION_END
	minimap.visible = false
	_root.add_child(minimap)
	var map_mat := ShaderMaterial.new()
	var map_shader := Shader.new()
	map_shader.code = """
shader_type canvas_item;
uniform float aspect = 0.83;
uniform float radius = 0.085;
uniform float border_w = 0.022;
uniform vec4 border_color = vec4(0.42, 0.66, 1.0, 0.95);
void fragment() {
	vec2 p = UV - 0.5;
	p.x *= aspect;
	float r = radius;
	vec2 half_box = vec2(aspect * 0.5, 0.5);
	vec2 q = abs(p) - (half_box - vec2(r));
	float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
	if (d > 0.0) {
		discard;
	}
	vec4 tex = texture(TEXTURE, UV);
	float aa = 0.008;
	float alpha = 1.0 - smoothstep(-aa, aa, d);
	float ring = smoothstep(-border_w - aa, -border_w, d) * alpha;
	vec3 col = mix(tex.rgb, border_color.rgb, clamp(ring, 0.0, 1.0));
	COLOR = vec4(col, tex.a * alpha);
}
"""
	map_mat.shader = map_shader
	if _map_tex.x > 0.0 and _map_tex.y > 0.0:
		map_mat.set_shader_parameter("aspect", _map_tex.x / _map_tex.y)
		map_mat.set_shader_parameter("radius", 0.085)
		map_mat.set_shader_parameter("border_w", 0.030)
	minimap.material = map_mat
	minimap_marker = MinimapMarker.new()
	minimap_marker.set_anchors_preset(Control.PRESET_FULL_RECT)
	minimap_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap.add_child(minimap_marker)
	var n_badge := PanelContainer.new()
	n_badge.name = "NorthBadge"
	n_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n_style := StyleBoxFlat.new()
	n_style.bg_color = Color(0.07, 0.13, 0.24, 0.96)
	n_style.border_color = Color(0.42, 0.66, 1.0, 0.95)
	n_style.set_border_width_all(2)
	n_style.set_corner_radius_all(14)
	n_badge.add_theme_stylebox_override("panel", n_style)
	var n_label := Label.new()
	n_label.text = "N"
	n_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	n_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.42))
	n_badge.add_child(n_label)
	n_badge.custom_minimum_size = Vector2(28, 28)
	n_badge.size = Vector2(28, 28)
	minimap.add_child(n_badge)
	n_badge.anchor_left = 0.5
	n_badge.anchor_right = 0.5
	n_badge.anchor_top = 0.0
	n_badge.anchor_bottom = 0.0
	n_badge.offset_left = -14.0
	n_badge.offset_right = 14.0
	n_badge.offset_top = -12.0
	n_badge.offset_bottom = 16.0
	_north_badge = n_badge
	_north_label = n_label
	_bake_minimap.call_deferred()

	# --- keyboard legend (desktop only) ---
	controls_bar = PanelContainer.new()
	controls_bar.anchor_top = 1.0
	controls_bar.anchor_bottom = 1.0
	controls_bar.offset_left = 16.0
	controls_bar.offset_right = 760.0
	controls_bar.offset_top = -54.0
	controls_bar.offset_bottom = -14.0
	controls_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls_bar.visible = not _touch
	_root.add_child(controls_bar)
	if not _touch:
		var controls_row := HBoxContainer.new()
		controls_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		controls_row.add_theme_constant_override("separation", 18)
		controls_bar.add_child(controls_row)
		_add_control(controls_row, ["w", "a", "s", "d"], "Move")
		_add_control(controls_row, ["shift"], "Run")
		_add_control(controls_row, ["e"], "Talk / use")
		_add_control(controls_row, ["g"], "Salute")
		_add_control(controls_row, ["q"], "Turn camera")
		_add_control(controls_row, ["esc"], "Pause")


	# --- pause overlay (hidden until Esc / pause button) ---
	pause_overlay = PanelContainer.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.visible = false
	_root.add_child(pause_overlay)
	var pause_dim := StyleBoxFlat.new()
	pause_dim.bg_color = Color(0.02, 0.05, 0.11, 0.66)
	pause_overlay.add_theme_stylebox_override("panel", pause_dim)
	var pause_center := CenterContainer.new()
	pause_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_overlay.add_child(pause_center)
	var pause_card := PanelContainer.new()
	pause_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.03, 0.06, 0.11, 0.94)
	card_style.border_color = Color(0.86, 0.66, 0.18, 0.75)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(24)
	card_style.content_margin_left = 48.0
	card_style.content_margin_right = 48.0
	card_style.content_margin_top = 30.0
	card_style.content_margin_bottom = 32.0
	card_style.shadow_color = Color(0, 0, 0, 0.55)
	card_style.shadow_size = 18
	card_style.shadow_offset = Vector2(0, 8)
	pause_card.add_theme_stylebox_override("panel", card_style)
	pause_center.add_child(pause_card)
	_pause_card = pause_card
	var pause_box := VBoxContainer.new()
	pause_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_box.add_theme_constant_override("separation", 10)
	pause_card.add_child(pause_box)
	var paused_title := Label.new()
	paused_title.name = "PausedTitle"
	paused_title.text = "PAUSED"
	paused_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paused_title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
	paused_title.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.16, 0.9))
	paused_title.add_theme_constant_override("outline_size", 6)
	pause_box.add_child(paused_title)
	_paused_title = paused_title
	var paused_sub := Label.new()
	paused_sub.text = "ANITS College Simulation"
	paused_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paused_sub.add_theme_color_override("font_color", Color(0.66, 0.74, 0.88, 0.9))
	pause_box.add_child(paused_sub)
	_paused_sub = paused_sub
	var rule := ColorRect.new()
	rule.color = Color(0.86, 0.66, 0.18, 0.8)
	rule.custom_minimum_size = Vector2(190, 2)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_box.add_child(rule)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
	pause_box.add_child(spacer)
	var resume_button := _make_pause_button("RESUME")
	resume_button.pressed.connect(_on_resume_pressed)
	pause_box.add_child(resume_button)
	_pause_buttons.append(resume_button)
	var menu_button := _make_pause_button("MAIN MENU")
	menu_button.pressed.connect(_on_menu_pressed)
	pause_box.add_child(menu_button)
	_pause_buttons.append(menu_button)


# ------------------------------------------------------------------- layout

func _relayout() -> void:
	if _root == null:
		return
	var view := _root.size
	if view.x <= 0.0 or view.y <= 0.0:
		return
	var win := DisplayServer.window_get_size()
	_ui_scale = compute_ui_scale(view, win)
	_safe = safe_area_insets(view, win)
	var s := _ui_scale

	# --- fonts: one place so every label scales together ---
	_font_size(mission_title, 17)
	_font_size(mission_label, 15)
	_font_size(mission_distance, 16)
	_font_size(wallet_label, 19)
	_font_size(energy_label, 16)
	_font_size(toast_label, 18)
	_font_size(prompt_label, 20)
	_font_size(subtitle_label, 18)
	_font_size(dialogue_name, 20)
	_font_size(dialogue_text, 17)
	_font_size(_paused_title, 44)
	_font_size(_paused_sub, 13)
	_font_size(_north_label, 13)
	_mission_row.add_theme_constant_override("separation", int(round(12.0 * s)))
	if _pips:
		_pips.custom_minimum_size = Vector2(0, maxf(8.0, 10.0 * s))
		_pips.queue_redraw()

	# --- mission banner (top left pill) ---
	var wallet_w := minf(240.0 * s, view.x * 0.32)
	var pause_d := 46.0 * s
	var banner_w := minf((340.0 if _touch else 470.0) * s,
			maxf(160.0 * s, view.x - _safe.x - _safe.z - wallet_w - pause_d - 34.0 * s))
	var banner_x := _safe.x + 14.0 * s
	var banner_y := _safe.y + 12.0 * s
	_mission_panel.offset_left = banner_x
	_mission_panel.offset_right = banner_x + banner_w
	_mission_panel.offset_top = banner_y
	_mission_panel.offset_bottom = banner_y
	_mission_panel.custom_minimum_size = Vector2(banner_w, 0)
	_mission_panel.pivot_offset = Vector2.ZERO
	_mission_panel.add_theme_stylebox_override("panel",
			_panel_style(Color(0.055, 0.095, 0.185, 0.92), Color(0.30, 0.56, 0.95, 0.85), s, 340))
	mission_label.custom_minimum_size = Vector2(maxf(60.0 * s, banner_w - 100.0 * s), 0)

	# --- wallet + energy (top right, left of the pause button) ---
	_wallet_panel.offset_left = -wallet_w - (_safe.z + 14.0 * s + pause_d + 10.0 * s)
	_wallet_panel.offset_right = -(_safe.z + 14.0 * s + pause_d + 10.0 * s)
	_wallet_panel.offset_top = _safe.y + 12.0 * s
	_wallet_panel.offset_bottom = _safe.y + 12.0 * s
	_wallet_panel.add_theme_stylebox_override("panel",
			_panel_style(Color(0.055, 0.095, 0.185, 0.92), Color(1.0, 0.84, 0.3, 0.45), s, 340))
	energy_bar.custom_minimum_size = Vector2(120.0 * s, maxf(10.0, 14.0 * s))

	# --- pause button (top right corner) ---
	_pause_button.offset_left = -pause_d - (_safe.z + 14.0 * s)
	_pause_button.offset_right = -(_safe.z + 14.0 * s)
	_pause_button.offset_top = _safe.y + 12.0 * s
	_pause_button.offset_bottom = _safe.y + 12.0 * s + pause_d
	_pause_button.size = Vector2(pause_d, pause_d)
	_pause_button.pivot_offset = Vector2(pause_d, pause_d) * 0.5
	_pause_button.add_theme_stylebox_override("normal",
			_pause_style(Color(0.055, 0.095, 0.185, 0.88), Color(0.30, 0.56, 0.95, 0.85), s))
	_pause_button.add_theme_stylebox_override("hover",
			_pause_style(Color(0.10, 0.17, 0.30, 0.95), Color(0.45, 0.72, 1.0, 0.95), s))
	_pause_button.add_theme_stylebox_override("pressed",
			_pause_style(Color(0.16, 0.27, 0.45, 1.0), Color(1.0, 0.86, 0.34, 0.95), s))
	_pause_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	# --- toast (top centre, under the banner band) ---
	var toast_half := minf(320.0 * s, view.x * 0.45)
	_toast_panel.offset_left = -toast_half
	_toast_panel.offset_right = toast_half
	var band := maxf(_mission_panel.get_combined_minimum_size().y,
			_wallet_panel.get_combined_minimum_size().y)
	var toast_top := _safe.y + 12.0 * s + band + 10.0 * s
	_toast_panel.offset_top = toast_top
	_toast_panel.offset_bottom = toast_top + 44.0 * s
	_toast_panel.add_theme_stylebox_override("panel",
			_panel_style(Color(0.035, 0.075, 0.15, 0.92), Color(1.0, 0.84, 0.32, 0.55), s, 999))
	_toast_panel.pivot_offset = Vector2(toast_half, 22.0 * s)

	# --- bottom stack: prompt, subtitle, dialogue ---
	var bottom_inset := 20.0 * s + (TOUCH_ZONE * s if _touch else 0.0)
	_bottom.offset_top = -bottom_inset - 460.0 * s
	_bottom.offset_bottom = -bottom_inset
	var dialogue_w := clampf(view.x * (0.88 if _touch else 0.80), 330.0 * s, 1150.0 * s)
	var dialogue_h := 168.0 * s
	dialogue_panel.custom_minimum_size = Vector2(dialogue_w, dialogue_h)
	# - portrait: sticks out above the panel's top edge
	var port := 132.0 * s
	_portrait.size = Vector2(port, port)
	_portrait.position = Vector2(16.0 * s, -port * 0.26)
	_portrait.pivot_offset = Vector2(port, port) * 0.5
	_dialogue_art.frame = Rect2(
			_portrait.position - Vector2(9.0 * s, 9.0 * s),
			Vector2(port + 18.0 * s, port + 18.0 * s))
	# - text column
	var text_x := port + 40.0 * s
	dialogue_name.position = Vector2(text_x, 10.0 * s)
	dialogue_name.size = Vector2(maxf(120.0 * s, dialogue_w - text_x - 96.0 * s), 34.0 * s)
	dialogue_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_text.position = Vector2(text_x, 50.0 * s)
	dialogue_text.size = Vector2(maxf(120.0 * s, dialogue_w - text_x - 24.0 * s), dialogue_h - 58.0 * s)
	# - the "ready to advance" triangle
	_next_hint.size = Vector2(22.0 * s, 22.0 * s)
	_next_hint.position = Vector2(dialogue_w - 42.0 * s, dialogue_h - 30.0 * s)
	# - NEXT button, sticking out past the panel's right edge
	var nb := 66.0 * s
	_next_button.size = Vector2(nb, nb)
	_next_button.pivot_offset = Vector2(nb, nb) * 0.5
	_next_button.position = Vector2(dialogue_w - nb * 0.42, dialogue_h * 0.5 - nb * 0.5)
	_next_button.add_theme_font_size_override("font_size", int(round(13.0 * s)))
	_next_button.add_theme_stylebox_override("normal",
			_pause_style(Color(0.10, 0.085, 0.04, 0.94), Color(1.0, 0.84, 0.34, 0.95), s))
	_next_button.add_theme_stylebox_override("hover",
			_pause_style(Color(0.16, 0.13, 0.06, 0.98), Color(1.0, 0.90, 0.45, 1.0), s))
	_next_button.add_theme_stylebox_override("pressed",
			_pause_style(Color(0.30, 0.24, 0.08, 1.0), Color(1.0, 0.94, 0.55, 1.0), s))
	_next_button.visible = not _touch
	# - the brush strokes
	_dialogue_art.slash_x = port + 24.0 * s
	_dialogue_art.queue_redraw()
	prompt_panel.add_theme_stylebox_override("panel",
			_panel_style(Color(0.03, 0.07, 0.15, 0.92), Color(0.23, 0.63, 1.0, 0.9), s))

	# --- minimap (always top right, below the pills) ---
	var map_long := clampf(BASE_MINIMAP * s, 96.0, view.x * 0.26)
	var map_w := map_long * (_map_tex.x / maxf(1.0, _map_tex.y))
	var map_h := map_long
	minimap.offset_left = -(map_w + 14.0 * s + _safe.z)
	minimap.offset_right = -(14.0 * s + _safe.z)
	minimap.offset_top = _safe.y + 12.0 * s + band + 10.0 * s
	minimap.offset_bottom = minimap.offset_top + map_h
	if _north_badge:
		var badge_d := 28.0 * s
		_north_badge.offset_left = -badge_d * 0.5
		_north_badge.offset_right = badge_d * 0.5
		_north_badge.offset_top = -12.0 * s
		_north_badge.offset_bottom = _north_badge.offset_top + badge_d
		_north_badge.custom_minimum_size = Vector2(badge_d, badge_d)
		_north_badge.size = Vector2(badge_d, badge_d)

	# --- keyboard legend (desktop only) ---
	controls_bar.offset_left = 16.0 * s + _safe.x
	controls_bar.offset_right = minf(760.0 * s, view.x * 0.55)
	controls_bar.offset_top = -(54.0 * s + _safe.w)
	controls_bar.offset_bottom = -(14.0 * s + _safe.w)
	controls_bar.add_theme_stylebox_override("panel",
			_panel_style(Color(0.04, 0.09, 0.18, 0.68), Color(1, 1, 1, 0.12), s))
	for icon in _key_icons:
		icon.custom_minimum_size = Vector2(27.0 * s, 27.0 * s)
	for key_label in _key_labels:
		key_label.add_theme_font_size_override("font_size", int(round(15.0 * s)))

	if _pause_card:
		_pause_card.pivot_offset = _pause_card.size * 0.5
	for button in _pause_buttons:
		button.pivot_offset = button.size * 0.5
	minimap.pivot_offset = minimap.size * 0.5

	_update_mission_marker()


func _font_size(label: Label, base: float) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", int(round(base * _ui_scale)))


func _panel_style(bg: Color, border: Color, s: float = 1.0, corner: float = -1.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(maxi(1, int(round(2.0 * s))))
	if corner > 0.0:
		sb.set_corner_radius_all(int(corner))
	else:
		sb.set_corner_radius_all(maxi(4, int(round(8.0 * s))))
	sb.content_margin_left = 12.0 * s
	sb.content_margin_right = 12.0 * s
	sb.content_margin_top = 8.0 * s
	sb.content_margin_bottom = 8.0 * s
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = int(round(4.0 * s))
	sb.shadow_offset = Vector2(0, 2.0 * s)
	return sb


func _bar_style(colour: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = colour
	sb.set_corner_radius_all(6)
	# A soft matching halo makes the fill read as a lit energy cell.
	sb.shadow_color = Color(colour.r, colour.g, colour.b, 0.35)
	sb.shadow_size = 3
	return sb

func _pause_style(bg: Color, border: Color, s: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(maxi(1, int(round(2.0 * s))))
	sb.set_corner_radius_all(999)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = int(round(4.0 * s))
	sb.shadow_offset = Vector2(0, 2.0 * s)
	return sb

func _make_pause_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(260, 56)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.45))
	button.add_theme_stylebox_override("normal", _pause_menu_style(Color(0.08, 0.15, 0.28, 0.95), Color(0.30, 0.56, 0.95, 0.85)))
	button.add_theme_stylebox_override("hover", _pause_menu_style(Color(0.13, 0.23, 0.40, 1.0), Color(0.45, 0.72, 1.0, 1.0)))
	button.add_theme_stylebox_override("pressed", _pause_menu_style(Color(0.20, 0.35, 0.58, 1.0), Color(1.0, 0.86, 0.34, 1.0)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_add_button_juice(button)
	return button

func _pause_menu_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 20.0
	sb.content_margin_right = 20.0
	sb.content_margin_top = 12.0
	sb.content_margin_bottom = 12.0
	return sb

func _add_button_juice(button: Button) -> void:
	## Hover lift and press squash, shared by the pause pill, the pause card
	## buttons and the dialogue NEXT button.  Scale only, so the layout never
	## shifts and touch taps still land on the same rect.
	button.mouse_entered.connect(_button_scale.bind(button, 1.045, 0.10))
	button.mouse_exited.connect(_button_scale.bind(button, 1.0, 0.14))
	button.button_down.connect(_button_scale.bind(button, 0.94, 0.07))
	button.button_up.connect(_button_scale.bind(button, 1.0, 0.12))


func _button_scale(button: Button, target: float, seconds: float) -> void:
	if button == null or not is_instance_valid(button):
		return
	if button.pivot_offset == Vector2.ZERO:
		button.pivot_offset = button.size * 0.5
	var tw := button.create_tween()
	tw.tween_property(button, "scale", Vector2(target, target), seconds)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _play_entrance() -> void:
	## HUD slides/pops in once the campus is ready.  Everything is scale and
	## alpha only, so it never fights `_relayout()` on a resize.
	if _entrance_played or not is_inside_tree():
		return
	_entrance_played = true
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_mission_panel.pivot_offset = Vector2.ZERO
	_wallet_panel.pivot_offset = Vector2(_wallet_panel.size.x, 0.0)
	minimap.pivot_offset = minimap.size * 0.5
	_pause_button.pivot_offset = _pause_button.size * 0.5
	_mission_panel.modulate.a = 0.0
	_mission_panel.scale = Vector2(0.95, 0.95)
	_wallet_panel.modulate.a = 0.0
	_wallet_panel.scale = Vector2(0.95, 0.95)
	minimap.modulate.a = 0.0
	minimap.scale = Vector2(0.90, 0.90)
	_pause_button.modulate.a = 0.0
	_pause_button.scale = Vector2(0.60, 0.60)
	if controls_bar:
		controls_bar.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_mission_panel, "modulate:a", 1.0, 0.42).set_delay(0.04)
	tw.tween_property(_mission_panel, "scale", Vector2.ONE, 0.50)\
		.set_delay(0.04).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_wallet_panel, "modulate:a", 1.0, 0.42).set_delay(0.12)
	tw.tween_property(_wallet_panel, "scale", Vector2.ONE, 0.50)\
		.set_delay(0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_pause_button, "modulate:a", 1.0, 0.30).set_delay(0.20)
	tw.tween_property(_pause_button, "scale", Vector2.ONE, 0.42)\
		.set_delay(0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(minimap, "modulate:a", 1.0, 0.45).set_delay(0.24)
	tw.tween_property(minimap, "scale", Vector2.ONE, 0.52)\
		.set_delay(0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if controls_bar:
		tw.tween_property(controls_bar, "modulate:a", 1.0, 0.40).set_delay(0.34)


func _on_pause_pressed() -> void:
	pause_requested.emit()

func _on_resume_pressed() -> void:
	resume_requested.emit()

func _on_menu_pressed() -> void:
	menu_requested.emit()

func set_paused_visible(on: bool) -> void:
	if pause_overlay == null:
		return
	if not on:
		pause_overlay.visible = false
		return
	pause_overlay.visible = true
	pause_overlay.modulate.a = 0.0
	if _pause_card:
		_pause_card.pivot_offset = _pause_card.size * 0.5
		_pause_card.scale = Vector2(0.92, 0.92)
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(pause_overlay, "modulate:a", 1.0, 0.16)
	if _pause_card:
		tw.tween_property(_pause_card, "scale", Vector2.ONE, 0.28)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _key_texture(key_name: String) -> TextureRect:
	var tex := TextureRect.new()
	var path := "res://addons/controller_icons/assets/key/%s.png" % key_name
	if ResourceLoader.exists(path):
		tex.texture = load(path) as Texture2D
	tex.custom_minimum_size = Vector2(27, 27)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_key_icons.append(tex)
	return tex


func _add_control(row: HBoxContainer, keys: Array, action: String) -> void:
	var group := HBoxContainer.new()
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_theme_constant_override("separation", 3)
	for key_name in keys:
		group.add_child(_key_texture(str(key_name)))
	row.add_child(group)
	var label := Label.new()
	label.text = action
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.87, 0.92, 1.0, 0.94))
	_key_labels.append(label)
	row.add_child(label)


# ------------------------------------------------------------------ minimap

func _bake_minimap() -> void:
	## Bakes the top-down campus plan (roads, zones, tinted buildings with
	## name labels) into a SubViewport once, then hands the image to the
	## minimap. Async because it has to let the viewport paint a frame.
	var campus: Dictionary = CampusDB.campus if CampusDB else {}
	var extent: Array = [0, 0, 100, 100]
	if not campus.is_empty():
		extent = campus.get("extent_plan_px", extent)
	var x0 := float(extent[0])
	var y0 := float(extent[1])
	var w := maxf(1.0, float(extent[2]) - x0)
	var h := maxf(1.0, float(extent[3]) - y0)
	_map_extent = Rect2(x0, y0, w, h)
	var tex_scale := float(MINIMAP_TEX_LONG) / maxf(w, h)
	var tex_w := maxi(16, int(round(w * tex_scale)))
	var tex_h := maxi(16, int(round(h * tex_scale)))
	_map_tex = Vector2(tex_w, tex_h)
	if campus.is_empty():
		minimap.visible = true
		return
	await get_tree().process_frame
	await get_tree().process_frame

	var vp := SubViewport.new()
	vp.size = Vector2i(tex_w, tex_h)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var view := MapView.new()
	view.campus = campus
	view.extent = extent
	view.size = Vector2(tex_w, tex_h)
	view.position = Vector2.ZERO
	# name labels, sized to fit each footprint (skipped when they would not fit)
	for b in campus.get("buildings", []):
		var rect = b.get("rect", [])
		if rect.size() < 4:
			continue
		var name := _short_building_name(str(b.get("name", "")))
		if name == "":
			continue
		var rw := (float(rect[2]) - float(rect[0])) * tex_scale
		var rh := (float(rect[3]) - float(rect[1])) * tex_scale
		var font := int(minf(rh * 0.42, rw / (float(name.length()) * 0.60)))
		if font < 15:
			continue
		_add_map_label(view, name, rect, extent, tex_scale, font)
	vp.add_child(view)
	await get_tree().process_frame
	await get_tree().process_frame
	var img := vp.get_texture().get_image()
	if img:
		img.generate_mipmaps()
		var tex := ImageTexture.create_from_image(img)
		if minimap.material is ShaderMaterial:
			var aspect := tex.get_width() / float(maxf(1, tex.get_height()))
			(minimap.material as ShaderMaterial).set_shader_parameter("aspect", aspect)
		minimap.texture = tex
		minimap.visible = true
	vp.queue_free()
	_relayout()


func _short_building_name(raw: String) -> String:
	var n := raw.strip_edges()
	n = n.replace(" Block", "").replace("Stair ", "").replace("Gate ", "")
	n = n.replace(" Temple", "").strip_edges()
	n = n.substr(0, 11).strip_edges()
	return n.to_upper()


func _add_map_label(view: MapView, text: String, rect: Array, extent: Array,
		tex_scale: float, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.055, 0.075, 0.12, 0.94))
	label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.40))
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var x := (float(rect[0]) - float(extent[0])) * tex_scale
	var y := (float(rect[1]) - float(extent[1])) * tex_scale
	var w := (float(rect[2]) - float(rect[0])) * tex_scale
	var h := (float(rect[3]) - float(rect[1])) * tex_scale
	label.position = Vector2(x, y)
	label.size = Vector2(w, h)
	view.add_child(label)





func update_player_marker(world_pos: Vector3) -> void:
	## Called every frame by main.gd.  Only the numbers that actually change
	## are touched, so there is no per-frame allocation and no needless
	## repaint of the marker.
	if minimap_marker == null:
		return
	var ext := _map_extent
	if ext.size.x <= 0.0 or ext.size.y <= 0.0:
		return
	var plan := Campus.world_to_map(world_pos)
	var point := Vector2((plan.x - ext.position.x) / ext.size.x,
			(plan.y - ext.position.y) / ext.size.y) * minimap_marker.size
	# Spawn sits on the approach road just outside the campus extent, so
	# clamp the marker onto the edge instead of drawing past the map.
	var edge := 5.0
	var mm_size := minimap_marker.size
	if mm_size.x > 2.0:
		point = point.clamp(Vector2(edge, edge), mm_size - Vector2(edge, edge))
	if not minimap_marker.has_player or point.distance_to(minimap_marker.point) >= 0.4:
		minimap_marker.point = point
		minimap_marker.has_player = true
		minimap_marker.queue_redraw()
	# Rotate the arrow into the player's heading (plan-space). The controller's
	# forward is (sin yaw, 0, cos yaw) - the same formula player.gd uses.
	var p := _player_node()
	if p != null:
		var yaw := float(p.get("yaw"))
		var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
		var to_plan: Vector3 = world_pos + fwd * 2.0
		var a := Campus.world_to_map(world_pos)
		var b := Campus.world_to_map(to_plan)
		if b.distance_to(a) > 0.01:
			var heading := atan2(b.y - a.y, b.x - a.x)
			if absf(heading - minimap_marker.heading) > 0.035:
				minimap_marker.heading = heading
				minimap_marker.queue_redraw()
	_update_objective_readout(world_pos)


func _update_objective_readout(world_pos: Vector3) -> void:
	var distance_text := ""
	if _objective_valid:
		var to := _objective_world - world_pos
		distance_text = "%d m" % int(round(Vector2(to.x, to.z).length()))
	if distance_text == _distance_text:
		return
	_distance_text = distance_text
	mission_label.text = _objective_base
	mission_distance.text = distance_text


func _update_mission_marker() -> void:
	if minimap_marker == null:
		return
	if _objective_valid:
		var ext := _map_extent
		minimap_marker.mission_point = Vector2(
				(_objective_plan.x - ext.position.x) / maxf(1.0, ext.size.x),
				(_objective_plan.y - ext.position.y) / maxf(1.0, ext.size.y)) * minimap_marker.size
		var edge := 5.0
		if minimap_marker.size.x > 2.0:
			minimap_marker.mission_point = minimap_marker.mission_point.clamp(
					Vector2(edge, edge), minimap_marker.size - Vector2(edge, edge))
		minimap_marker.has_mission = true
	else:
		minimap_marker.has_mission = false
	minimap_marker.queue_redraw()


func _player_node() -> Node:
	if _player != null and is_instance_valid(_player):
		return _player
	if not is_inside_tree() or _player_retry > 0.0:
		return null
	# At most twice a second, so a missing player never costs a per-frame
	# allocation.
	_player_retry = 0.5
	_player = get_tree().get_first_node_in_group("player")
	return _player


# ------------------------------------------------------------------ updates

func set_mission(index: int, total: int, text: String) -> void:
	var changed := _pips != null and (_pips.index != index or _pips.total != total)
	mission_title.text = "MISSION %d / %d" % [index + 1, total]
	_objective_base = text
	_distance_text = ""
	mission_label.text = text
	if _pips:
		_pips.total = total
		_pips.index = index
		_pips.queue_redraw()
	_refresh_objective()
	# Skip the very first assignment: the HUD entrance animation owns it.
	if changed and _entrance_played and _mission_calls > 0:
		_pulse_mission()
	_mission_calls += 1


func _pulse_mission() -> void:
	if _mission_panel == null:
		return
	_mission_panel.pivot_offset = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(_mission_panel, "scale", Vector2(1.025, 1.025), 0.10)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_mission_panel, "scale", Vector2.ONE, 0.26)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	mission_label.modulate = Color(1.0, 0.90, 0.62)
	var tw2 := create_tween()
	tw2.tween_property(mission_label, "modulate", Color.WHITE, 0.55)


func _refresh_objective() -> void:
	## Works out where the current objective is so the banner can show a
	## bearing and a distance.  Uses only the mission table and the scene
	## tree, no new game-side API.
	_objective_valid = false
	_objective_plan = Vector2.ZERO
	_objective_world = Vector3.ZERO
	if not Mission:
		return
	var step := Mission.current()
	if step.is_empty():
		_update_mission_marker()
		return
	var kind := str(step.get("type", ""))
	if step.has("pos"):
		var pos: Array = step["pos"]
		if pos.size() >= 2:
			_objective_plan = Vector2(float(pos[0]), float(pos[1]))
			_objective_world = Campus.map_to_world(_objective_plan)
			_objective_valid = true
		_update_mission_marker()
		return
	var npc_id := str(step.get("npc", ""))
	if kind == "salute":
		npc_id = "colonel"
	if npc_id == "":
		_update_mission_marker()
		return
	var node := _find_npc(npc_id)
	if node != null:
		_objective_world = node.global_position
		_objective_plan = Campus.world_to_map(_objective_world)
		_objective_valid = true
	_update_mission_marker()


func _find_npc(npc_id: String) -> Node3D:
	if not is_inside_tree():
		return null
	for n in get_tree().get_nodes_in_group("npcs"):
		var node := n as Node3D
		if node != null and str(node.get("npc_id")) == npc_id:
			return node
	return null


func set_prompt(text: String) -> void:
	if prompt_panel == null:
		return
	var shown := text.strip_edges() != ""
	prompt_panel.visible = shown
	if shown:
		prompt_label.text = text


## The speaker key (guard / prof / suresh / ...) picks the portrait. The web
## build showed a painted portrait for every speaking NPC; the portraits are
## rendered from the game's own character models.
const PORTRAIT_DIR := "res://assets/ui/portraits"
const PORTRAIT_FALLBACK := "res://assets/ui/portraits/student.jpg"
var _portrait_cache: Dictionary = {}

func _portrait_texture(key: String) -> Texture2D:
	if _portrait_cache.has(key):
		return _portrait_cache[key] as Texture2D
	var path := "%s/%s.jpg" % [PORTRAIT_DIR, key]
	if key == "" or not ResourceLoader.exists(path):
		path = PORTRAIT_FALLBACK
	var tex := load(path) as Texture2D
	_portrait_cache[key] = tex
	return tex

func show_dialogue(speaker: String, text: String, key: String = "") -> void:
	var was_visible := dialogue_panel.visible
	dialogue_panel.visible = true
	if controls_bar:
		controls_bar.visible = false
	subtitle_label.visible = false
	dialogue_name.text = speaker
	dialogue_text.text = ""
	_type_full = text
	_type_shown = 0.0
	_type_running = true
	_next_hint.visible = false
	_portrait.texture = _portrait_texture(key)
	# Fade each new line in, so the text change reads as a beat rather than a
	# hard cut.
	if _line_tween and _line_tween.is_valid():
		_line_tween.kill()
	dialogue_text.modulate.a = 0.30
	_line_tween = create_tween()
	_line_tween.tween_property(dialogue_text, "modulate:a", 1.0, 0.18)
	# Pop the portrait and fade the panel in.
	if not was_visible:
		dialogue_panel.modulate.a = 0.0
		dialogue_panel.pivot_offset = dialogue_panel.size * 0.5
		dialogue_panel.scale = Vector2(0.97, 0.97)
		_portrait.scale = Vector2(0.72, 0.72)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(dialogue_panel, "modulate:a", 1.0, 0.16)
		tw.tween_property(dialogue_panel, "scale", Vector2.ONE, 0.24)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_portrait, "scale", Vector2.ONE, 0.24)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if not _touch:
			# desktop keeps its NEXT button (touch uses the pad's own)
			_next_button.visible = true
		elif _next_button:
			_next_button.visible = false


func hide_dialogue() -> void:
	dialogue_panel.visible = false
	subtitle_label.visible = true
	if controls_bar:
		controls_bar.visible = not _touch


## Called by E / click / NEXT: finishes the typewriter if a line is still
## being revealed. Returns true when the caller should NOT advance the line.
func skip_line() -> bool:
	if not _type_running:
		return false
	_type_shown = float(_type_full.length())
	_type_running = false
	dialogue_text.text = _type_full
	_next_hint.visible = true
	return true


func _on_next_dialogue() -> void:
	if skip_line():
		return
	if Dialogue:
		Dialogue.skip()


func show_subtitle(text: String) -> void:
	subtitle_label.text = text


func update_wallet(wallet: int, bank: int) -> void:
	var first := _last_wallet < 0
	var changed := wallet != _last_wallet
	_last_wallet = wallet
	wallet_label.text = str(wallet)
	if first or not changed or not is_inside_tree():
		return
	# A quick gold pop whenever the balance moves.
	wallet_label.pivot_offset = wallet_label.size * 0.5
	var tw := create_tween()
	tw.tween_property(wallet_label, "scale", Vector2(1.18, 1.18), 0.08)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(wallet_label, "scale", Vector2.ONE, 0.22)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func update_energy(value: float) -> void:
	var target := clampf(value, 0.0, 100.0)
	energy_label.text = str(int(round(target)))
	var bucket := 0 if target < 25.0 else (1 if target < 55.0 else 2)
	if _energy_bucket < 0:
		energy_bar.value = target
	if bucket != _energy_bucket:
		var colours := [Color(0.95, 0.35, 0.28, 0.96),
			Color(1.0, 0.72, 0.22, 0.96), Color(0.34, 0.84, 0.44, 0.96)]
		energy_bar.add_theme_stylebox_override("fill", _bar_style(colours[bucket]))
	_energy_bucket = bucket
	if _energy_tween and _energy_tween.is_valid():
		_energy_tween.kill()
	_energy_tween = create_tween()
	_energy_tween.tween_property(energy_bar, "value", target, 0.28)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func toast(text: String, seconds: float = 2.5) -> void:
	toast_label.text = text
	if _toast_panel == null:
		return
	if text.strip_edges() == "":
		_toast_panel.visible = false
		return
	_toast_time = seconds
	_toast_hiding = false
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_panel.visible = true
	_toast_panel.modulate.a = 1.0
	_toast_panel.pivot_offset = _toast_panel.size * 0.5
	_toast_panel.scale = Vector2(0.96, 0.96)
	var tw := create_tween()
	tw.tween_property(_toast_panel, "scale", Vector2.ONE, 0.24)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_toast_tween = tw


func _hide_toast() -> void:
	if _toast_panel == null or not _toast_panel.visible or _toast_hiding:
		return
	_toast_hiding = true
	var tw := create_tween()
	tw.tween_property(_toast_panel, "modulate:a", 0.0, 0.32)
	tw.tween_callback(_finish_hide_toast)
	_toast_tween = tw


func _finish_hide_toast() -> void:
	if _toast_panel:
		_toast_panel.visible = false
	_toast_hiding = false


func _process(delta: float) -> void:
	if _player_retry > 0.0:
		_player_retry -= delta
	if _toast_time > 0.0:
		_toast_time -= delta
		if _toast_time <= 0.0:
			_hide_toast()
	if _type_running:
		_type_shown = minf(_type_shown + delta * TYPE_CPS, float(_type_full.length()))
		var count := int(floor(_type_shown))
		dialogue_text.text = _type_full.substr(0, count)
		if count >= _type_full.length():
			_type_running = false
			_next_hint.visible = true
	if _next_hint.visible:
		_next_hint.flash = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.005)
		_next_hint.queue_redraw()
