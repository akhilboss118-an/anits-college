extends CanvasLayer
## ---------------------------------------------------------------------------
## In-game HUD - layout at a glance.
##
##   +---------------------------------------------------------------+
##   | [ MISSION BANNER      (needle) 42 m ]            [ WALLET ]   |
##   | [ objective text ... ]                            [ ENERGY ]   |
##   |                                                [ MINIMAP  ]   |
##   |                     ( toast )                              |
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
## ---------------------------------------------------------------------------

# ----------------------------------------------------------------- public API
var mission_label: Label
var mission_title: Label
var dialogue_panel: PanelContainer
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

var touch_mode_override: int = -1

# -------------------------------------------------------------------- tuning
const BASE_MINIMAP := 180        ## on-screen size of the minimap, unscaled
const MINIMAP_TEX_LONG := 384    ## minimap texture resolution (crisp when scaled)
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
var _distance_label: Label
var _needle: CompassNeedle
var _ui_scale: float = 1.0
var _safe: Vector4 = Vector4.ZERO
var _objective_valid: bool = false
var _objective_plan: Vector2 = Vector2.ZERO
var _objective_world: Vector3 = Vector3.ZERO
var _player: Node = null
var _player_retry: float = 0.0
var _distance_text: String = ""
var _needle_bearing: float = 0.0
var _map_extent: Rect2 = Rect2(0, 0, 100, 100)
var _map_tex: Vector2 = Vector2(BASE_MINIMAP, BASE_MINIMAP)
var _key_icons: Array[TextureRect] = []
var _key_labels: Array[Label] = []


class MinimapMarker:
	extends Control
	## Player dot + objective dot drawn on top of the minimap texture.

	var point := Vector2.ZERO
	var has_player := false
	var mission_point := Vector2.ZERO
	var has_mission := false

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.14, 0.24, 0.85), false, 2.0)
		if has_mission:
			draw_circle(mission_point, 5.0, Color(0.03, 0.10, 0.05, 0.85))
			draw_circle(mission_point, 3.2, Color(0.45, 1.0, 0.52, 0.95))
		if not has_player:
			return
		draw_circle(point, 5.0, Color(0.04, 0.08, 0.16, 0.85))
		draw_circle(point, 3.4, Color(1.0, 0.84, 0.3))
		draw_circle(point, 1.4, Color(1.0, 0.96, 0.75))


class CompassNeedle:
	extends Control
	## Tiny arrow that points from the player towards the current objective.
	## Drawn with a reused polygon so a repaint allocates nothing.

	var bearing := 0.0
	var active := false
	var _tri := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])

	func _draw() -> void:
		if not active:
			return
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		var dir := Vector2(sin(bearing), -cos(bearing))
		var side := Vector2(-dir.y, dir.x)
		var tail := c - dir * r * 0.55
		_tri[0] = c + dir * r
		_tri[1] = tail + side * r * 0.44
		_tri[2] = tail - side * r * 0.44
		draw_colored_polygon(_tri, Color(1.0, 0.86, 0.35, 0.95))
		draw_circle(c, r * 0.22, Color(0.06, 0.10, 0.18, 0.8))


func _ready() -> void:
	layer = 10
	_touch = Settings.is_touch_mode() if Settings else false
	if touch_mode_override >= 0:
		_touch = touch_mode_override == 1
	_build()
	get_viewport().size_changed.connect(_relayout)
	_root.resized.connect(_relayout)
	_relayout()


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

	# --- mission panel (top left) ---
	_mission_panel = PanelContainer.new()
	_mission_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mission_panel.grow_horizontal = Control.GROW_DIRECTION_END
	_mission_panel.grow_vertical = Control.GROW_DIRECTION_END
	_root.add_child(_mission_panel)
	var v := VBoxContainer.new()
	_mission_panel.add_child(v)
	_mission_row = HBoxContainer.new()
	_mission_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mission_row.add_theme_constant_override("separation", 8)
	v.add_child(_mission_row)
	mission_title = Label.new()
	mission_title.text = "DAY 1 · MISSION 1 / 8"
	mission_title.add_theme_color_override("font_color", Color(0xff, 0xd5, 0x4a))
	mission_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mission_row.add_child(mission_title)
	_needle = CompassNeedle.new()
	_needle.custom_minimum_size = Vector2(22, 22)
	_needle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mission_row.add_child(_needle)
	_distance_label = Label.new()
	_distance_label.text = ""
	_distance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_distance_label.add_theme_color_override("font_color", Color(0.86, 0.95, 1.0, 0.94))
	_distance_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_distance_label.add_theme_constant_override("outline_size", 4)
	_mission_row.add_child(_distance_label)
	mission_label = Label.new()
	mission_label.text = ""
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_label.add_theme_color_override("font_color", Color(0.93, 0.96, 1.0, 0.96))
	mission_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	mission_label.add_theme_constant_override("outline_size", 3)
	v.add_child(mission_label)

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
	wallet_label = Label.new()
	wallet_label.text = "Rs.200"
	wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wallet_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	wallet_label.add_theme_constant_override("outline_size", 4)
	right.add_child(wallet_label)
	var energy_row := HBoxContainer.new()
	energy_row.alignment = BoxContainer.ALIGNMENT_END
	energy_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_row.add_theme_constant_override("separation", 6)
	right.add_child(energy_row)
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

	# --- toast (top centre, below the banner band) ---
	toast_label = Label.new()
	toast_label.anchor_left = 0.5
	toast_label.anchor_right = 0.5
	toast_label.offset_left = -320
	toast_label.offset_right = 320
	toast_label.offset_top = 104
	toast_label.offset_bottom = 144
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7))
	toast_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	toast_label.add_theme_constant_override("outline_size", 4)
	toast_label.modulate.a = 0.0
	_root.add_child(toast_label)

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
	dialogue_panel = PanelContainer.new()
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_panel.visible = false
	dialogue_row.add_child(dialogue_panel)
	var dv := VBoxContainer.new()
	dialogue_panel.add_child(dv)
	dialogue_name = Label.new()
	dialogue_name.text = ""
	dialogue_name.add_theme_color_override("font_color", Color(0xff, 0xd5, 0x4a))
	dv.add_child(dialogue_name)
	dialogue_text = Label.new()
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	dialogue_text.add_theme_constant_override("outline_size", 3)
	dv.add_child(dialogue_text)

	# --- minimap ---
	minimap = TextureRect.new()
	minimap.stretch_mode = TextureRect.STRETCH_SCALE
	minimap.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	minimap.texture = _build_minimap()
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(minimap)
	if _touch:
		minimap.anchor_left = 1.0
		minimap.anchor_right = 1.0
		minimap.anchor_top = 0.0
		minimap.anchor_bottom = 0.0
	else:
		minimap.anchor_left = 1.0
		minimap.anchor_right = 1.0
		minimap.anchor_top = 1.0
		minimap.anchor_bottom = 1.0
	minimap_marker = MinimapMarker.new()
	minimap_marker.set_anchors_preset(Control.PRESET_FULL_RECT)
	minimap_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap.add_child(minimap_marker)

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
	_font_size(mission_label, 16)
	_font_size(_distance_label, 15)
	_font_size(wallet_label, 20)
	_font_size(energy_label, 17)
	_font_size(toast_label, 18)
	_font_size(prompt_label, 20)
	_font_size(subtitle_label, 18)
	_font_size(dialogue_name, 18)
	_font_size(dialogue_text, 18)
	_needle.custom_minimum_size = Vector2(22.0 * s, 22.0 * s)
	_mission_row.add_theme_constant_override("separation", int(round(8.0 * s)))

	# --- mission banner (top left) ---
	var wallet_w := minf(340.0 * s, view.x * 0.40)
	var banner_w := minf((330.0 if _touch else 460.0) * s,
			maxf(140.0 * s, view.x - _safe.x - _safe.z - wallet_w - 16.0 * s))
	var banner_x := _safe.x + 14.0 * s
	var banner_y := _safe.y + 12.0 * s
	_mission_panel.offset_left = banner_x
	_mission_panel.offset_right = banner_x + banner_w
	_mission_panel.offset_top = banner_y
	_mission_panel.offset_bottom = banner_y
	_mission_panel.custom_minimum_size = Vector2(banner_w, 0)
	_mission_panel.add_theme_stylebox_override("panel",
			_panel_style(Color(0.05, 0.09, 0.18, 0.82), Color(0.23, 0.63, 1.0, 0.8), s))
	mission_label.custom_minimum_size = Vector2(maxf(60.0 * s, banner_w - 28.0 * s), 0)

	# --- wallet + energy (top right) ---
	_wallet_panel.offset_left = -wallet_w - (_safe.z + 14.0 * s)
	_wallet_panel.offset_right = -(_safe.z + 14.0 * s)
	_wallet_panel.offset_top = _safe.y + 12.0 * s
	_wallet_panel.offset_bottom = _safe.y + 12.0 * s
	_wallet_panel.add_theme_stylebox_override("panel",
			_panel_style(Color(0.05, 0.09, 0.18, 0.72), Color(1.0, 0.84, 0.3, 0.45), s))
	energy_bar.custom_minimum_size = Vector2(120.0 * s, maxf(10.0, 14.0 * s))

	# --- toast (top centre, under the banner band) ---
	var toast_half := minf(320.0 * s, view.x * 0.45)
	toast_label.offset_left = -toast_half
	toast_label.offset_right = toast_half
	var band := maxf(_mission_panel.get_combined_minimum_size().y,
			_wallet_panel.get_combined_minimum_size().y)
	var toast_top := _safe.y + 12.0 * s + band + 10.0 * s
	toast_label.offset_top = toast_top
	toast_label.offset_bottom = toast_top + 46.0 * s

	# --- bottom stack: prompt, subtitle, dialogue ---
	var bottom_inset := 20.0 * s + (TOUCH_ZONE * s if _touch else 0.0)
	_bottom.offset_top = -bottom_inset - 460.0 * s
	_bottom.offset_bottom = -bottom_inset
	var dialogue_w := minf((470.0 if _touch else 560.0) * s,
			maxf(160.0 * s, view.x - 2.0 * (_safe.x + _safe.z) - 24.0 * s))
	dialogue_panel.custom_minimum_size = Vector2(dialogue_w, 90.0 * s)
	dialogue_panel.add_theme_stylebox_override("panel",
			_panel_style(Color(0.04, 0.09, 0.18, 0.92), Color(0.23, 0.63, 1.0, 0.85), s))
	dialogue_text.custom_minimum_size = Vector2(maxf(120.0 * s, dialogue_w - 28.0 * s), 44.0 * s)
	prompt_panel.add_theme_stylebox_override("panel",
			_panel_style(Color(0.03, 0.07, 0.15, 0.92), Color(0.23, 0.63, 1.0, 0.9), s))

	# --- minimap ---
	var map_long := clampf(BASE_MINIMAP * s, 96.0, view.x * 0.26)
	var map_w := map_long * (_map_tex.x / maxf(1.0, _map_tex.y))
	var map_h := map_long
	if _touch:
		minimap.offset_left = -(map_w + 14.0 * s + _safe.z)
		minimap.offset_right = -(14.0 * s + _safe.z)
		minimap.offset_top = _safe.y + 12.0 * s + band + 10.0 * s
		minimap.offset_bottom = minimap.offset_top + map_h
	else:
		minimap.offset_left = -(map_w + 16.0 * s + _safe.z)
		minimap.offset_right = -(16.0 * s + _safe.z)
		minimap.offset_top = -(map_h + 16.0 * s + _safe.w)
		minimap.offset_bottom = -(16.0 * s + _safe.w)

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

	_update_mission_marker()


func _font_size(label: Label, base: float) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", int(round(base * _ui_scale)))


func _panel_style(bg: Color, border: Color, s: float = 1.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(maxi(1, int(round(2.0 * s))))
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
	return sb


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

func _build_minimap() -> ImageTexture:
	## The texture keeps the aspect of the campus plan so the dots land exactly
	## on the buildings; it is rendered at a high resolution and minified with
	## mipmaps, so it stays crisp on a 4K screen and on a phone.
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
	var img := Image.create(tex_w, tex_h, false, Image.FORMAT_RGBA8)
	img.fill(Color.html("#5fa04b"))
	if not campus.is_empty():
		var scale := minf(float(tex_w) / w, float(tex_h) / h)
		_fill_rect(img, campus.get("roads", []), Color.html("#555a63"), extent, scale)
		_fill_rect(img, [campus.get("zones", {}).get("parade_ground", [])], Color.html("#d9c491"), extent, scale)
		_fill_rect(img, [campus.get("zones", {}).get("basketball", [])], Color.html("#b96a45"), extent, scale)
		_fill_rect(img, [campus.get("zones", {}).get("track", [])], Color.html("#2f6b3a"), extent, scale)
		_fill_rect(img, [campus.get("zones", {}).get("parking", [])], Color.html("#6f747b"), extent, scale)
		for b in campus.get("buildings", []):
			_fill_rect(img, [b.get("rect", [])], Color(str(b.get("color", "#cccccc"))), extent, scale)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _fill_rect(img: Image, rects: Array, colour: Color, extent: Array, scale: float) -> void:
	for r in rects:
		if r.size() < 4:
			continue
		var x0 := clampi(int((r[0] - extent[0]) * scale), 0, img.get_width())
		var y0 := clampi(int((r[1] - extent[1]) * scale), 0, img.get_height())
		var x1 := clampi(int((r[2] - extent[0]) * scale), 0, img.get_width())
		var y1 := clampi(int((r[3] - extent[1]) * scale), 0, img.get_height())
		if x1 <= x0 or y1 <= y0:
			continue
		img.fill_rect(Rect2i(x0, y0, x1 - x0, y1 - y0), colour)


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
	if not minimap_marker.has_player or point.distance_to(minimap_marker.point) >= 0.4:
		minimap_marker.point = point
		minimap_marker.has_player = true
		minimap_marker.queue_redraw()
	_update_objective_readout(world_pos)


func _update_objective_readout(world_pos: Vector3) -> void:
	if not _objective_valid:
		if _distance_text != "":
			_distance_text = ""
			_distance_label.text = ""
		if _needle.active:
			_needle.active = false
			_needle.queue_redraw()
		return
	var to := _objective_world - world_pos
	var metres := int(round(Vector2(to.x, to.z).length()))
	var text := "%d m" % metres
	if text != _distance_text:
		_distance_text = text
		_distance_label.text = text
	if not _needle.active:
		_needle.active = true
		_needle.queue_redraw()
	var yaw := 0.0
	var p := _player_node()
	if p != null:
		yaw = float(p.get("yaw"))
	var bearing := wrapf(atan2(to.x, to.z) - yaw, -PI, PI)
	if absf(bearing - _needle_bearing) > 0.03:
		_needle_bearing = bearing
		_needle.bearing = bearing
		_needle.queue_redraw()


func _update_mission_marker() -> void:
	if minimap_marker == null:
		return
	if _objective_valid:
		var ext := _map_extent
		minimap_marker.mission_point = Vector2(
				(_objective_plan.x - ext.position.x) / maxf(1.0, ext.size.x),
				(_objective_plan.y - ext.position.y) / maxf(1.0, ext.size.y)) * minimap_marker.size
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
	mission_title.text = "DAY %d · MISSION %d / %d" % [Mission.day if Mission else 1, index + 1, total]
	mission_label.text = text
	_refresh_objective()


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


func show_dialogue(speaker: String, text: String) -> void:
	dialogue_panel.visible = true
	dialogue_name.text = speaker + ":"
	dialogue_text.text = text


func hide_dialogue() -> void:
	dialogue_panel.visible = false


func show_subtitle(text: String) -> void:
	subtitle_label.text = text


func update_wallet(wallet: int, bank: int) -> void:
	wallet_label.text = "Rs.%d  |  bank Rs.%d" % [wallet, bank]


func update_energy(value: float) -> void:
	energy_bar.value = value
	energy_label.text = str(int(round(value)))


func toast(text: String, seconds: float = 2.5) -> void:
	toast_label.text = text
	toast_label.modulate.a = 1.0
	_toast_time = seconds


func _process(delta: float) -> void:
	if _player_retry > 0.0:
		_player_retry -= delta
	if _toast_time > 0.0:
		_toast_time -= delta
		if _toast_time <= 0.0:
			toast_label.modulate.a = 0.0
