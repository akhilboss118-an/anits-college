extends CanvasLayer
## Front end: year select -> character select -> name -> welcome -> main menu
## -> level select -> play, exactly the flow of js/menu.js.
##
## Mirrors the look of the original web build: the same campus photo
## (assets/ui/bg_clean.jpg) behind every screen, the ANITS crest, the gold/blue
## palette, big pill buttons, live previews of the two original character
## models, the ten-card 5x2 level grid and the "Powered by Little Hearts"
## footer.
##
## The screen is drawn on a centred 1600x1080 design canvas, so the layout is
## identical at 1280x720, 1920x1080 and on a phone in landscape.
##
## Public surface (used by src/main.gd):
##   signal start_requested(profile: Dictionary)  -> {"name", "char", "year"}
##   show_year() / show_character()                -> screen switches
##   year / character / player_name                -> current selection
##   visible                                      -> inherited CanvasLayer flag

signal start_requested(profile: Dictionary)
signal loading_go

var year: int = 2024
var character: String = "boy"
var player_name: String = "Player"

# ---------------------------------------------------------------- constants

const DESIGN_W := 1600.0
const DESIGN_H := 1080.0

const GOLD := Color(1.0, 0.84, 0.30)
const SKY_TEXT := Color(0.86, 0.94, 1.0)
const BLUE := Color(0.30, 0.65, 1.0)
const MUTED := Color(0.63, 0.77, 0.93, 0.85)

const PREVIEW_W := 340
const PREVIEW_H := 430
const CARD_W := 380.0
const CARD_H := 690.0

## The web build's own menu photo (copied out of ANITS-WEB GAME/assets/ui).
const BG_PHOTO := "res://assets/ui/bg_clean.jpg"
const LEVEL_THUMB := "res://assets/ui/levels/lv_%02d.jpg"

## Startup experience, reconstructed from js/cinematic.js and js/menu.js.
const LOGO := "res://assets/ui/anits_logo.png"
const STUDIO_LOGO := "res://assets/ui/little_hearts_logo.png"
const INTRO_CFG := "user://intro.cfg"

## js/menu.js:4 - the quotes shown under the loading bar.
const LOADING_QUOTES := [
	"Some places teach you lessons, ANITS teaches you life.",
	"Every campus has a story. Yours starts here.",
	"Friends make the canteen chai taste better.",
	"First bench or last bench, the best memories are made together.",
	"Attendance is temporary, memories are permanent.",
	"A salute to discipline, a smile to friendship.",
	"Study hard, play harder, stay curious.",
	"The best classroom is the one with your friends in it.",
	"Dream big. The campus is big enough for it.",
	"One chai, one samosa, and a thousand stories.",
	"Today a fresher, tomorrow a legend of ANITS.",
	"Pragnanam Brahma: knowledge is supreme.",
]

## The ten levels of js/levels.js (window.__LVINFO), in order.
const LEVELS := [
	"Explore the College", "Pay the Fees", "Find Your Classroom",
	"Library Card", "Basketball Event", "NCC Parade", "Lab Manual Run",
	"Canteen Challenge", "Fest Stage", "First Classroom",
]

const UNIFORMS := {
	2023: ["Rose Uniform", "LIGHT PINK SHIRT - BLACK PANTS", Color(0.941, 0.651, 0.769), Color(0.086, 0.086, 0.106)],
	2024: ["Classic Uniform", "CREAM SHIRT - BROWN PANTS", Color(0.910, 0.875, 0.769), Color(0.231, 0.165, 0.122)],
	2025: ["New Uniform", "SKY BLUE SHIRT - NAVY PANTS", Color(0.529, 0.808, 0.922), Color(0.063, 0.102, 0.290)],
}

const YEAR_KEYS := [2023, 2024, 2025]

# ---------------------------------------------------------------- state

var _root: Control
var _frame: Control
var _canvas: Control
var _screen_year: Control
var _screen_char: Control
var _screen_name: Control
var _screen_welcome: Control
var _screen_main: Control
var _screen_levels: Control
var _screen_settings: Control
var _screen_intro: Control
var _screen_loading: Control
var _intro_logo: TextureRect
var _intro_mark: TextureRect
var _intro_studio: Label
var _intro_dev: Label
var _intro_skip: Button
var _intro_top: ColorRect
var _intro_bottom: ColorRect
var _intro_tweens: Array[Tween] = []
var _intro_started_ms: int = 0
var _intro_done: bool = false
var _loading_bar: ProgressBar
var _loading_status: Label
var _loading_quote: Label
var _loading_tween: Tween
var _starting: bool = false
var _year_value: Label
var _year_name: Label
var _year_desc: Label
var _year_slider: HSlider
var _year_chips: Array[Button] = []
var _swatch_top: Panel
var _swatch_bottom: Panel
var _name_input: LineEdit
var _name_go: Button
var _main_label: Label
var _welcome_top: Label
var _welcome_name: Label
var _welcome_bottom: Label
var _cards: Dictionary = {}
var _preview_boy: SubViewport
var _preview_girl: SubViewport
var _preview_pivots: Array[Node3D] = []
var _preview_visuals: Dictionary = {}
var _settings_panel: Control
var _vol_slider: HSlider
var _vol_label: Label
var _look_slider: HSlider
var _look_label: Label
var _welcome_tween: Tween
var _choose_tween: Tween
var _current: String = "year"
var _clock: float = 0.0
var _touch: bool = false
var _ui: float = 1.0
var _year_badge: Button
var _year_continue: Button
var _main_play: Button
var _main_crest: Control
var _sun_glow: TextureRect
var _level_cards: Array[Button] = []
var _level_toast: Label
var _level_toast_tween: Tween
var _screen_tween: Tween
var _year_tween: Tween
var _level_progress: Label
var _level_progress_bar: ProgressBar
var _loading_bg: TextureRect
var _loading_logo: TextureRect
var _loading_spinner: Control
var _loading_pct: Label
var _loading_shine: ColorRect
var _loading_loops: Array[Tween] = []
var _quote_tween: Tween


# ---------------------------------------------------------------- small art

class Heart:
	extends Control
	## A drawn heart, so the footer never depends on a font glyph.

	func _draw() -> void:
		var pts := PackedVector2Array()
		var w := size.x
		var h := size.y
		for i in 26:
			var t := TAU * float(i) / 26.0
			var hx := 16.0 * pow(sin(t), 3.0)
			var hy := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
			pts.append(Vector2(w * 0.5 + hx * (w / 36.0), h * 0.5 - hy * (h / 36.0)))
		draw_colored_polygon(pts, Color(1.0, 0.30, 0.43))


class Crest:
	extends Control
	## The ANITS crest: a navy shield with a gold rim, a star and the wordmark.

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var gold := Color(1.0, 0.84, 0.30)
		var shield := PackedVector2Array([
			Vector2(w * 0.06, h * 0.04), Vector2(w * 0.94, h * 0.04),
			Vector2(w * 0.94, h * 0.54), Vector2(w * 0.76, h * 0.82),
			Vector2(w * 0.50, h * 0.98), Vector2(w * 0.24, h * 0.82),
			Vector2(w * 0.06, h * 0.54)])
		draw_colored_polygon(shield, Color(0.035, 0.09, 0.20, 0.96))
		draw_polyline(_closed(shield), gold, 3.0, true)
		var inner := PackedVector2Array()
		for p in shield:
			inner.append(Vector2(w * 0.5 + (p.x - w * 0.5) * 0.86, h * 0.03 + (p.y - h * 0.04) * 0.88))
		draw_polyline(_closed(inner), Color(gold.r, gold.g, gold.b, 0.40), 1.5, true)
		# a five point star above the wordmark
		var centre := Vector2(w * 0.5, h * 0.27)
		var star := PackedVector2Array()
		for i in 10:
			var a := -PI * 0.5 + TAU * float(i) / 10.0
			var r := w * 0.155 if i % 2 == 0 else w * 0.062
			star.append(centre + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(star, gold)
		var font := ThemeDB.fallback_font
		if font:
			draw_string(font, Vector2(0.0, h * 0.63), "ANITS", HORIZONTAL_ALIGNMENT_CENTER,
					w, int(h * 0.175), Color(1.0, 0.90, 0.52))
			draw_string(font, Vector2(0.0, h * 0.74), "COLLEGE", HORIZONTAL_ALIGNMENT_CENTER,
					w, int(h * 0.058), Color(0.64, 0.80, 0.96, 0.85))
		var rule := Rect2(Vector2(w * 0.29, h * 0.665), Vector2(w * 0.42, 2.0))
		draw_rect(rule, Color(gold.r, gold.g, gold.b, 0.55))

	func _closed(points: PackedVector2Array) -> PackedVector2Array:
		var out := PackedVector2Array(points)
		if out.size() > 0:
			out.append(out[0])
		return out


class Icon:
	extends Control
	## Small hand drawn glyphs. The default Godot font has no dingbats, so the
	## buttons use vectors instead of symbol characters.

	var kind: String = "play"

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		var ink := Color(0.94, 0.98, 1.0)
		if kind == "play":
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-r * 0.45, -r * 0.78),
				c + Vector2(r * 0.80, 0.0),
				c + Vector2(-r * 0.45, r * 0.78)]), ink)
		elif kind == "gear":
			for i in 8:
				var a := TAU * float(i) / 8.0
				var dir := Vector2(cos(a), sin(a))
				var mid := c + dir * r * 0.66
				var side := Vector2(-dir.y, dir.x) * r * 0.26
				draw_colored_polygon(PackedVector2Array([
					mid + side, mid + dir * r * 0.34 - side,
					mid + dir * r * 0.34 + side]), ink)
			draw_arc(c, r * 0.52, 0.0, TAU, 28, ink, r * 0.30, true)
			draw_circle(c, r * 0.20, Color(0.04, 0.12, 0.26, 1.0))


class Lock:
	extends Control
	## The padlock on a locked level card, drawn as vectors so it never depends
	## on a font glyph (the web build uses an inline SVG icon).

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var gold := Color(1.0, 0.85, 0.36, 0.95)
		# shackle
		draw_arc(Vector2(w * 0.5, h * 0.38), w * 0.26, PI, TAU, 24, gold, w * 0.10, true)
		draw_line(Vector2(w * 0.24, h * 0.38), Vector2(w * 0.24, h * 0.50), gold, w * 0.10)
		draw_line(Vector2(w * 0.76, h * 0.38), Vector2(w * 0.76, h * 0.50), gold, w * 0.10)
		# body
		var body := Rect2(Vector2(w * 0.12, h * 0.48), Vector2(w * 0.76, h * 0.44))
		draw_rect(body, Color(0.07, 0.16, 0.30, 0.96))
		draw_rect(body, gold, false, 3.0)
		draw_circle(Vector2(w * 0.5, h * 0.66), w * 0.09, gold)
		draw_line(Vector2(w * 0.5, h * 0.70), Vector2(w * 0.5, h * 0.82), gold, 4.0)


class Spinner:
	extends Control
	## A ring with a bright comet arc; the loading screen rotates it.

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 6.0
		draw_arc(c, r, 0.0, TAU, 48, Color(0.55, 0.80, 1.0, 0.18), 5.0, true)
		draw_arc(c, r, -PI * 0.5, -PI * 0.5 + PI * 0.62, 24, Color(1.0, 0.86, 0.38, 0.98), 6.0, true)
		draw_arc(c, r, -PI * 0.5 + PI * 0.62, -PI * 0.5 + PI * 1.0, 16, Color(0.45, 0.75, 1.0, 0.55), 5.0, true)


class Skyline:
	extends Control
	## The campus silhouette that sits along the bottom of the sky. Drawn once.

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var base := h
		var far := Color(0.055, 0.115, 0.205, 0.80)
		var near := Color(0.014, 0.043, 0.098, 0.96)
		# a soft ridge behind the buildings
		var ridge := PackedVector2Array()
		var steps := 30
		for i in steps + 1:
			var t := float(i) / float(steps)
			var y := base - h * (0.46 + 0.09 * sin(t * 8.3) + 0.05 * sin(t * 3.1 + 1.7))
			ridge.append(Vector2(t * w, y))
		ridge.append(Vector2(w, base))
		ridge.append(Vector2(0.0, base))
		draw_colored_polygon(ridge, far)
		# blocks
		var count := int(maxf(8.0, w / 150.0))
		for i in count:
			var seed_v := i * 7 + 3
			var bw := w / float(count) * (0.55 + _rand(seed_v) * 0.7)
			var bh := h * (0.16 + _rand(seed_v + 1) * 0.30)
			var x := w * (float(i) / float(count)) + w / float(count) * 0.18
			draw_rect(Rect2(x, base - bh, bw, bh), near)
			# a few lit windows
			var cols := int(bw / 26.0)
			for c in cols:
				if _rand(seed_v * 31 + c) < 0.34:
					var wx := x + 10.0 + float(c) * 26.0
					if wx + 8.0 < x + bw:
						draw_rect(Rect2(wx, base - bh + 14.0 + _rand(seed_v + c) * (bh - 34.0), 7.0, 9.0),
								Color(1.0, 0.80, 0.42, 0.55))
		# the temple, dead centre
		var tx := w * 0.5
		var th := h * 0.50
		for i in 4:
			var f := 1.0 - float(i) * 0.20
			var y0 := base - th + float(i) * th * 0.17
			var y1 := base - th + float(i + 1) * th * 0.17
			var half0 := w * 0.052 * f
			var half1 := w * 0.052 * (f - 0.20)
			draw_colored_polygon(PackedVector2Array([
				Vector2(tx - half0, y0), Vector2(tx + half0, y0),
				Vector2(tx + half1, y1), Vector2(tx - half1, y1)]), near)
		draw_rect(Rect2(tx - 3.0, base - th - 26.0, 6.0, 26.0), near)
		# flag on the pole
		draw_colored_polygon(PackedVector2Array([
			Vector2(tx + 3.0, base - th - 24.0), Vector2(tx + 34.0, base - th - 18.0),
			Vector2(tx + 3.0, base - th - 12.0)]), Color(0.95, 0.45, 0.35, 0.75))
		# trees
		var trees := int(maxf(6.0, w / 260.0))
		for i in trees:
			var seed_v := i * 13 + 5
			var tx2 := w * (float(i) + 0.5) / float(trees) + _rand(seed_v) * 40.0
			var th2 := h * (0.16 + _rand(seed_v + 2) * 0.12)
			draw_rect(Rect2(tx2 - 2.0, base - th2 * 0.34, 4.0, th2 * 0.34), near)
			draw_circle(Vector2(tx2, base - th2 * 0.52), th2 * 0.30, near)

	func _rand(seed_v: int) -> float:
		var x := sin(float(seed_v) * 12.9898 + 4.1414) * 43758.5453
		return x - floor(x)


# ---------------------------------------------------------------- lifecycle

func _ready() -> void:
	layer = 20
	_touch = Settings.is_touch_mode() if Settings else false
	_ui = 1.22 if _touch else 1.0
	_build()
	# Verification and screenshot runs go straight to the menu; a normal launch
	# plays the Little Hearts production card first.
	var args := OS.get_cmdline_user_args()
	var skip_intro := args.has("--skip-intro") or args.has("--check") \
		or args.has("--beauty") or args.has("--menu-shot") or args.has("--flow-shot")
	if skip_intro:
		show_year()
	else:
		show_intro()


func _process(delta: float) -> void:
	# Only the character preview animates, and only while it is on screen.
	if _preview_pivots.is_empty() or _screen_char == null or not _screen_char.visible:
		return
	_clock += delta
	var yaw := sin(_clock * 0.72) * 0.5 + 0.25
	for pivot in _preview_pivots:
		if is_instance_valid(pivot):
			pivot.rotation.y = yaw


# ---------------------------------------------------------------- build

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_background()

	# Design canvas: 1600x1080, centred on any phone/tablet/laptop aspect.
	_frame = Control.new()
	_frame.anchor_left = 0.5
	_frame.anchor_right = 0.5
	_frame.anchor_top = 0.0
	_frame.anchor_bottom = 1.0
	_frame.offset_left = -DESIGN_W * 0.5
	_frame.offset_right = DESIGN_W * 0.5
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_frame)

	_canvas = Control.new()
	_canvas.anchor_left = 0.0
	_canvas.anchor_right = 1.0
	_canvas.anchor_top = 0.5
	_canvas.anchor_bottom = 0.5
	_canvas.offset_left = 0.0
	_canvas.offset_right = 0.0
	_canvas.offset_top = -DESIGN_H * 0.5
	_canvas.offset_bottom = DESIGN_H * 0.5
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_canvas)

	_build_year_screen()
	_build_character_screen()
	_build_name_screen()
	_build_welcome_screen()
	_build_main_screen()
	_build_levels_screen()
	_build_settings_screen()
	_build_footer()
	_build_intro_screen()
	_build_loading_screen()
	_build_ambient()


func _build_ambient() -> void:
	## Two slow, looping motions keep the screen alive without any per-frame
	## script work: the sun breathes and the crest floats.
	if _sun_glow:
		var tw := create_tween().set_loops()
		var up := tw.tween_property(_sun_glow, "modulate:a", 1.15, 2.6)
		up.set_trans(Tween.TRANS_SINE)
		up.set_ease(Tween.EASE_IN_OUT)
		var down := tw.tween_property(_sun_glow, "modulate:a", 0.70, 2.6)
		down.set_trans(Tween.TRANS_SINE)
		down.set_ease(Tween.EASE_IN_OUT)
	_add_orbs()
	if _main_crest:
		_main_crest.set_meta("no_stagger", true)
		var cw := create_tween().set_loops()
		var lift := cw.tween_method(_crest_lift, 0.0, 1.0, 3.4)
		lift.set_trans(Tween.TRANS_SINE)
		lift.set_ease(Tween.EASE_IN_OUT)


func _add_orbs() -> void:
	## Five soft light orbs drift behind the UI: cheap textured quads, no particles.
	var specs := [
		[0.10, 0.22, 420.0, Color(0.30, 0.62, 1.0, 0.16), 7.0, 46.0],
		[0.88, 0.72, 500.0, Color(1.0, 0.72, 0.38, 0.12), 9.0, 58.0],
		[0.50, 0.92, 380.0, Color(0.36, 0.70, 1.0, 0.12), 8.0, 40.0],
		[0.30, 0.64, 300.0, Color(0.72, 0.60, 1.0, 0.08), 10.0, 34.0],
		[0.78, 0.14, 340.0, Color(1.0, 0.84, 0.46, 0.10), 6.5, 36.0],
	]
	for spec in specs:
		var s: Array = spec
		var r: float = float(s[2]) * 0.5
		var orb := _radial_glow(float(s[2]), s[3] as Color)
		orb.anchor_left = float(s[0])
		orb.anchor_right = float(s[0])
		orb.anchor_top = float(s[1])
		orb.anchor_bottom = float(s[1])
		orb.offset_left = -r
		orb.offset_right = r
		orb.offset_top = -r
		orb.offset_bottom = r
		_root.add_child(orb)
		_root.move_child(orb, _frame.get_index())
		var tw := create_tween().set_loops()
		tw.tween_method(_drift_orb.bind(orb, r, float(s[5])), 0.0, 1.0, float(s[4]))


func _drift_orb(t: float, orb: Control, r: float, amp: float) -> void:
	var dy := sin(t * TAU) * amp
	orb.offset_top = -r + dy
	orb.offset_bottom = r + dy


func _crest_lift(t: float) -> void:
	if _main_crest:
		_main_crest.position.y = 132.0 + sin(t * PI) * 8.0


func _build_background() -> void:
	## The original web build's menu photo: the real ANITS campus, cropped to
	## cover the screen exactly like the CSS `center/cover` rule.
	var bg := TextureRect.new()
	if ResourceLoader.exists(BG_PHOTO):
		bg.texture = load(BG_PHOTO) as Texture2D
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)
	bg.resized.connect(func() -> void: bg.pivot_offset = bg.size * 0.5)
	var kb := create_tween().set_loops()
	kb.tween_property(bg, "scale", Vector2(1.06, 1.06), 20.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	kb.tween_property(bg, "scale", Vector2.ONE, 20.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# blue dusk wash over the photo: bright in the middle band where the
	# campus shows, deep navy at the top and bottom behind the UI
	var wash := Gradient.new()
	wash.set_color(0, Color(0.012, 0.043, 0.110, 0.86))
	wash.set_color(1, Color(0.004, 0.014, 0.035, 0.94))
	wash.add_point(0.30, Color(0.020, 0.090, 0.200, 0.55))
	wash.add_point(0.52, Color(0.030, 0.130, 0.280, 0.34))
	wash.add_point(0.74, Color(0.020, 0.080, 0.180, 0.52))
	var wash_tex := GradientTexture2D.new()
	wash_tex.gradient = wash
	wash_tex.fill_from = Vector2(0.0, 0.0)
	wash_tex.fill_to = Vector2(0.0, 1.0)
	wash_tex.width = 16
	wash_tex.height = 512
	var shade := TextureRect.new()
	shade.texture = wash_tex
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(shade)

	# one soft warm glow keeps the photo from reading as a flat backdrop
	var sun := _radial_glow(820.0, Color(1.0, 0.70, 0.36, 0.20))
	sun.anchor_left = 0.72
	sun.anchor_right = 0.72
	sun.anchor_top = 0.30
	sun.anchor_bottom = 0.30
	sun.offset_left = -410.0
	sun.offset_right = 410.0
	sun.offset_top = -410.0
	sun.offset_bottom = 410.0
	_root.add_child(sun)
	_sun_glow = sun

	# vignette
	var vignette := TextureRect.new()
	var vg := Gradient.new()
	vg.set_color(0, Color(0.0, 0.0, 0.0, 0.0))
	vg.set_color(1, Color(0.01, 0.03, 0.07, 0.80))
	vg.add_point(0.52, Color(0.0, 0.0, 0.0, 0.0))
	var vt := GradientTexture2D.new()
	vt.gradient = vg
	vt.fill = GradientTexture2D.FILL_RADIAL
	vt.fill_from = Vector2(0.5, 0.5)
	vt.fill_to = Vector2(1.16, 0.5)
	vt.width = 256
	vt.height = 256
	vignette.texture = vt
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(vignette)


func _build_year_screen() -> void:
	_screen_year = _screen()
	_glass(_screen_year, Rect2(330, 172, 940, 648))
	var title := _headline("WHICH YEAR DID YOU JOIN?", 56)
	title.position = Vector2(0, 54)
	_screen_year.add_child(title)
	var sub := _caption("Slide to your joining year. It decides your uniform.")
	sub.position = Vector2(0, 128)
	_screen_year.add_child(sub)

	_year_value = Label.new()
	_year_value.text = "2024"
	_year_value.add_theme_font_size_override("font_size", 150)
	_year_value.add_theme_color_override("font_color", Color(1, 1, 1))
	_year_value.add_theme_color_override("font_outline_color", Color(1.0, 0.84, 0.30, 0.35))
	_year_value.add_theme_constant_override("outline_size", 10)
	_year_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_year_value.position = Vector2(0, 176)
	_year_value.size = Vector2(DESIGN_W, 180)
	_screen_year.add_child(_year_value)

	# slider
	_year_slider = HSlider.new()
	_year_slider.min_value = 2023
	_year_slider.max_value = 2025
	_year_slider.step = 1
	_year_slider.value = 2024
	_year_slider.custom_minimum_size = Vector2(620, 48)
	_year_slider.position = Vector2(490, 392)
	_style_slider(_year_slider)
	_year_slider.value_changed.connect(_on_year_changed)
	_screen_year.add_child(_year_slider)

	# big touch targets for the three joining years
	for i in YEAR_KEYS.size():
		var chip := _button(str(YEAR_KEYS[i]), 22)
		chip.custom_minimum_size = Vector2(190, 62)
		chip.size = Vector2(190, 62)
		chip.position = Vector2(395.0 + float(i) * 315.0, 458)
		chip.pressed.connect(_on_year_chip.bind(YEAR_KEYS[i]))
		_screen_year.add_child(chip)
		_year_chips.append(chip)

	# uniform swatches + name
	_swatch_top = _swatch(Color(0.91, 0.87, 0.77))
	_swatch_top.position = Vector2(742, 552)
	_screen_year.add_child(_swatch_top)
	_swatch_bottom = _swatch(Color(0.23, 0.16, 0.12))
	_swatch_bottom.position = Vector2(808, 552)
	_screen_year.add_child(_swatch_bottom)

	_year_name = Label.new()
	_year_name.text = "Classic Uniform"
	_year_name.add_theme_font_size_override("font_size", 30)
	_year_name.add_theme_color_override("font_color", Color(1, 1, 1))
	_year_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_year_name.position = Vector2(0, 632)
	_year_name.size = Vector2(DESIGN_W, 38)
	_screen_year.add_child(_year_name)

	_year_desc = Label.new()
	_year_desc.text = "CREAM SHIRT - BROWN PANTS"
	_year_desc.add_theme_font_size_override("font_size", 16)
	_year_desc.add_theme_color_override("font_color", MUTED)
	_year_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_year_desc.position = Vector2(0, 676)
	_year_desc.size = Vector2(DESIGN_W, 28)
	_screen_year.add_child(_year_desc)

	var cont := _button("CONTINUE", 26)
	cont.custom_minimum_size = Vector2(300, 84)
	cont.size = Vector2(300, 84)
	cont.position = Vector2(650, 726)
	cont.pressed.connect(show_character)
	_screen_year.add_child(cont)
	_year_continue = cont

	var hint := _caption("ENTER to continue  ·  choose your joining year")
	hint.position = Vector2(0, 836)
	_screen_year.add_child(hint)

	# keyboard: slider <-> year chips <-> continue
	_focus_row(_year_chips)
	for chip in _year_chips:
		chip.focus_neighbor_top = chip.get_path_to(_year_slider)
		chip.focus_neighbor_bottom = chip.get_path_to(cont)
	_year_slider.focus_neighbor_bottom = _year_slider.get_path_to(_year_chips[1])
	_year_slider.focus_neighbor_top = _year_slider.get_path_to(cont)
	cont.focus_neighbor_top = cont.get_path_to(_year_chips[1])


func _build_character_screen() -> void:
	_screen_char = _screen()
	var back := _button("<  YEAR", 18)
	back.custom_minimum_size = Vector2(230, 62)
	back.size = Vector2(230, 62)
	back.position = Vector2(44, 34)
	back.pressed.connect(show_year)
	_screen_char.add_child(back)
	_year_badge = back

	var title := _headline("CHOOSE YOUR CHARACTER", 56)
	title.position = Vector2(0, 54)
	_screen_char.add_child(title)
	var sub := _caption("Who will walk into ANITS today?")
	sub.position = Vector2(0, 128)
	_screen_char.add_child(sub)

	_make_card("boy", "Mike", "BOY", Color.html("#7fb0ff"), Vector2(400, 190))
	_make_card("girl", "Amy", "GIRL", Color.html("#f0a6d2"), Vector2(820, 190))

	var hint := _caption("Tap a card to start  ·  LEFT / RIGHT to look around")
	hint.position = Vector2(0, 920)
	_screen_char.add_child(hint)

	# keyboard: left / right between the two cards, up to the back button
	var boy_entry: Dictionary = _cards.get("boy", {})
	var girl_entry: Dictionary = _cards.get("girl", {})
	var boy := boy_entry.get("button") as Button
	var girl := girl_entry.get("button") as Button
	if boy and girl:
		boy.focus_neighbor_right = boy.get_path_to(girl)
		girl.focus_neighbor_left = girl.get_path_to(boy)
		boy.focus_neighbor_top = boy.get_path_to(back)
		girl.focus_neighbor_top = girl.get_path_to(back)
		back.focus_neighbor_bottom = back.get_path_to(boy)


func _build_name_screen() -> void:
	_screen_name = _screen()
	_glass(_screen_name, Rect2(290, 292, 1020, 428))
	var back := _button("<  BACK", 18)
	back.custom_minimum_size = Vector2(190, 62)
	back.size = Vector2(190, 62)
	back.position = Vector2(44, 34)
	back.pressed.connect(show_character)
	_screen_name.add_child(back)

	var title := _headline("WHAT SHOULD WE CALL YOU?", 52)
	title.position = Vector2(0, 330)
	_screen_name.add_child(title)
	var sub := _caption("Type your name to begin your story")
	sub.position = Vector2(0, 400)
	_screen_name.add_child(sub)

	_name_input = LineEdit.new()
	_name_input.max_length = 14
	_name_input.placeholder_text = "Your name"
	_name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_input.add_theme_font_size_override("font_size", 30)
	_name_input.add_theme_color_override("font_color", Color(1, 1, 1))
	_name_input.add_theme_color_override("font_placeholder_color", Color(0.55, 0.70, 0.90, 0.7))
	_name_input.add_theme_stylebox_override("normal", _sb(Color(0.02, 0.07, 0.16, 0.85),
			Color(0.42, 0.75, 1.0, 0.9), 2, 14))
	_name_input.add_theme_stylebox_override("focus", _sb(Color(0.03, 0.10, 0.24, 0.95),
			Color(0.65, 0.88, 1.0, 1.0), 2, 14))
	_name_input.custom_minimum_size = Vector2(520, 78)
	_name_input.position = Vector2(540, 452)
	_name_input.text_submitted.connect(func(_t: String) -> void: _submit_name())
	_name_input.text_changed.connect(_on_name_changed)
	_screen_name.add_child(_name_input)

	_name_go = _button("CONTINUE", 26)
	_name_go.custom_minimum_size = Vector2(300, 84)
	_name_go.size = Vector2(300, 84)
	_name_go.position = Vector2(650, 566)
	_name_go.disabled = true
	_name_go.pressed.connect(_submit_name)
	_screen_name.add_child(_name_go)

	_focus_chain([_name_input, _name_go])


func _build_welcome_screen() -> void:
	_screen_welcome = _screen()
	var heart := Heart.new()
	heart.size = Vector2(74, 74)
	heart.position = Vector2(763, 300)
	heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_welcome.add_child(heart)

	_welcome_top = Label.new()
	_welcome_top.text = "WELCOME"
	_welcome_top.add_theme_font_size_override("font_size", 30)
	_welcome_top.add_theme_color_override("font_color", Color.html("#7cc4ff"))
	_welcome_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_welcome_top.position = Vector2(0, 392)
	_welcome_top.size = Vector2(DESIGN_W, 42)
	_screen_welcome.add_child(_welcome_top)

	_welcome_name = Label.new()
	_welcome_name.text = ""
	_welcome_name.add_theme_font_size_override("font_size", 104)
	_welcome_name.add_theme_color_override("font_color", Color(1, 1, 1))
	_welcome_name.add_theme_color_override("font_outline_color", Color(0.35, 0.68, 1.0, 0.55))
	_welcome_name.add_theme_constant_override("outline_size", 10)
	_welcome_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_welcome_name.position = Vector2(0, 440)
	_welcome_name.size = Vector2(DESIGN_W, 130)
	_screen_welcome.add_child(_welcome_name)

	_welcome_bottom = Label.new()
	_welcome_bottom.text = "TO ANITS COLLEGE"
	_welcome_bottom.add_theme_font_size_override("font_size", 40)
	_welcome_bottom.add_theme_color_override("font_color", GOLD)
	_welcome_bottom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_welcome_bottom.position = Vector2(0, 590)
	_welcome_bottom.size = Vector2(DESIGN_W, 56)
	_welcome_bottom.modulate.a = 0.0
	_screen_welcome.add_child(_welcome_bottom)


func _build_main_screen() -> void:
	_screen_main = _screen()
	_glass(_screen_main, Rect2(52, 96, 700, 790))

	var crest := Crest.new()
	crest.size = Vector2(190, 210)
	crest.position = Vector2(96, 132)
	crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_main.add_child(crest)
	_main_crest = crest

	# a big, faint crest watermark on the right balances the lock-up
	var mark := Crest.new()
	mark.size = Vector2(300, 330)
	mark.position = Vector2(1150, 330)
	mark.modulate = Color(1, 1, 1, 0.13)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_main.add_child(mark)

	var logo := Label.new()
	logo.text = "ANITS"
	logo.add_theme_font_size_override("font_size", 118)
	logo.add_theme_color_override("font_color", Color(1, 1, 1))
	logo.add_theme_color_override("font_outline_color", Color(0.10, 0.45, 0.95, 0.55))
	logo.add_theme_constant_override("outline_size", 6)
	logo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	logo.add_theme_constant_override("shadow_offset_x", 4)
	logo.add_theme_constant_override("shadow_offset_y", 6)
	logo.position = Vector2(90, 356)
	logo.size = Vector2(700, 140)
	_screen_main.add_child(logo)

	var rule := ColorRect.new()
	rule.color = Color(0.16, 0.64, 1.0, 0.9)
	rule.size = Vector2(330, 3)
	rule.position = Vector2(96, 500)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_main.add_child(rule)

	var sub := Label.new()
	sub.text = _spaced("COLLEGE SIMULATION")
	sub.add_theme_font_size_override("font_size", 30)
	sub.add_theme_color_override("font_color", GOLD)
	sub.position = Vector2(96, 516)
	sub.size = Vector2(760, 44)
	_screen_main.add_child(sub)

	var play := _button("START GAME", 26)
	play.custom_minimum_size = Vector2(430, 92)
	play.size = Vector2(430, 92)
	play.position = Vector2(96, 604)
	_style_button(play, true)
	_icon_button(play, "play", Vector2(30, 33))
	play.pressed.connect(show_levels)
	_screen_main.add_child(play)
	_main_play = play

	var settings := _button("SETTINGS", 22)
	settings.custom_minimum_size = Vector2(430, 80)
	settings.size = Vector2(430, 80)
	settings.position = Vector2(96, 714)
	_icon_button(settings, "gear", Vector2(30, 27))
	settings.pressed.connect(show_settings)
	_screen_main.add_child(settings)

	_main_label = Label.new()
	_main_label.text = ""
	_main_label.add_theme_font_size_override("font_size", 16)
	_main_label.add_theme_color_override("font_color", MUTED)
	_main_label.position = Vector2(96, 818)
	_main_label.size = Vector2(760, 28)
	_screen_main.add_child(_main_label)

	var features := Label.new()
	features.text = _spaced("LOW-POLY CAMPUS  ·  DAY 1 STORY  ·  60 FPS ON MOBILE  ·  KEYBOARD + TOUCH")
	features.add_theme_font_size_override("font_size", 14)
	features.add_theme_color_override("font_color", Color(0.58, 0.74, 0.92, 0.6))
	features.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	features.position = Vector2(0, 930)
	features.size = Vector2(DESIGN_W, 26)
	_screen_main.add_child(features)

	_focus_chain([play, settings])


func _build_levels_screen() -> void:
	## The web build's 5x2 level grid (js/menu.js `levels()`): every card is a
	## real campus screenshot, a DAY number and the level name. Locked cards
	## shake and toast, exactly like the original.
	_screen_levels = _screen()

	var back := _button("<  BACK", 18)
	back.custom_minimum_size = Vector2(190, 62)
	back.size = Vector2(190, 62)
	back.position = Vector2(44, 34)
	back.pressed.connect(show_main)
	_screen_levels.add_child(back)

	var logo := Label.new()
	logo.text = "ANITS"
	logo.add_theme_font_size_override("font_size", 54)
	logo.add_theme_color_override("font_color", Color(1, 1, 1))
	logo.add_theme_color_override("font_outline_color", Color(0.10, 0.45, 0.95, 0.55))
	logo.add_theme_constant_override("outline_size", 4)
	logo.position = Vector2(72, 96)
	logo.size = Vector2(420, 66)
	_screen_levels.add_child(logo)

	var sub := Label.new()
	sub.text = _spaced("COLLEGE SIMULATION")
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", GOLD)
	sub.position = Vector2(72, 160)
	sub.size = Vector2(420, 26)
	_screen_levels.add_child(sub)

	var quote := Label.new()
	quote.text = "\u201c Every campus has a story.\nYours starts here. \u201d"
	quote.add_theme_font_size_override("font_size", 21)
	quote.add_theme_color_override("font_color", Color(0.80, 0.90, 1.0, 0.9))
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quote.position = Vector2(1020, 96)
	quote.size = Vector2(508, 74)
	_screen_levels.add_child(quote)

	# LEVELS badge
	var badge := PanelContainer.new()
	var bs := _sb(Color(0.020, 0.094, 0.235, 0.88), Color(0.31, 0.69, 1.0, 1.0), 2, 14)
	bs.content_margin_left = 56
	bs.content_margin_right = 56
	bs.content_margin_top = 8
	bs.content_margin_bottom = 8
	badge.add_theme_stylebox_override("panel", bs)
	badge.position = Vector2(636, 204)
	badge.custom_minimum_size = Vector2(328, 62)
	badge.size = Vector2(328, 62)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_text := Label.new()
	badge_text.text = _spaced("LEVELS")
	badge_text.add_theme_font_size_override("font_size", 26)
	badge_text.add_theme_color_override("font_color", Color(0.82, 0.93, 1.0))
	badge_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(badge_text)
	_screen_levels.add_child(badge)

	_level_progress = Label.new()
	_level_progress.add_theme_font_size_override("font_size", 16)
	_level_progress.add_theme_color_override("font_color", Color(0.80, 0.90, 1.0, 0.92))
	_level_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_level_progress.position = Vector2(1000, 210)
	_level_progress.size = Vector2(528, 26)
	_level_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_levels.add_child(_level_progress)
	_level_progress_bar = ProgressBar.new()
	_level_progress_bar.min_value = 0
	_level_progress_bar.max_value = LEVELS.size()
	_level_progress_bar.show_percentage = false
	_level_progress_bar.position = Vector2(1228, 242)
	_level_progress_bar.size = Vector2(300, 10)
	_level_progress_bar.custom_minimum_size = Vector2(300, 10)
	_level_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.42, 0.72, 1.0, 0.22)
	pb_bg.set_corner_radius_all(5)
	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = GOLD
	pb_fill.set_corner_radius_all(5)
	pb_fill.shadow_size = 6
	pb_fill.shadow_color = Color(1.0, 0.84, 0.30, 0.35)
	_level_progress_bar.add_theme_stylebox_override("background", pb_bg)
	_level_progress_bar.add_theme_stylebox_override("fill", pb_fill)
	_screen_levels.add_child(_level_progress_bar)
	_update_level_progress()

	const COLS := 5
	const CW := 276.0
	const CH := 308.0
	const GAP := 18.0
	const X0 := 72.0
	const Y0 := 292.0
	for i in LEVELS.size():
		var n := i + 1
		var col := i % COLS
		var row := i / COLS
		var pos := Vector2(X0 + float(col) * (CW + GAP), Y0 + float(row) * (CH + GAP))
		_make_level_card(n, str(LEVELS[i]), pos, Vector2(CW, CH))

	_level_toast = Label.new()
	_level_toast.text = ""
	_level_toast.add_theme_font_size_override("font_size", 20)
	_level_toast.add_theme_color_override("font_color", Color(1, 0.92, 0.62))
	_level_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_toast.position = Vector2(0, 942)
	_level_toast.size = Vector2(DESIGN_W, 30)
	_level_toast.modulate.a = 0.0
	_level_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_toast.set_meta("no_stagger", true)
	_screen_levels.add_child(_level_toast)


func _make_level_card(n: int, level_name: String, pos: Vector2, card_size: Vector2) -> void:
	var unlocked: int = 1
	if GameState:
		unlocked = clampi(GameState.unlocked_day, 1, LEVELS.size())
	var open := n <= unlocked
	var done := n < unlocked

	var card := Button.new()
	card.text = ""
	card.position = pos
	card.size = card_size
	card.custom_minimum_size = card_size
	card.focus_mode = Control.FOCUS_ALL
	card.pressed.connect(_on_level_pressed.bind(n, open, card))
	_screen_levels.add_child(card)
	_level_cards.append(card)

	var current := open and not done
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.030, 0.090, 0.200, 0.86) if open else Color(0.020, 0.055, 0.120, 0.90)
	normal.border_color = Color(0.42, 0.75, 1.0, 0.60) if open else Color(0.34, 0.46, 0.62, 0.45)
	if done:
		normal.bg_color = Color(0.030, 0.120, 0.150, 0.88)
		normal.border_color = Color(0.40, 0.90, 0.62, 0.75)
	elif current:
		normal.bg_color = Color(0.050, 0.130, 0.270, 0.92)
		normal.border_color = Color(1.0, 0.84, 0.30, 0.95)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(18)
	normal.shadow_size = 10
	normal.shadow_color = Color(0, 0, 0, 0.38)
	normal.shadow_offset = Vector2(0, 5)
	card.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = GOLD if open else Color(0.60, 0.70, 0.84, 0.7)
	hover.bg_color = Color(0.07, 0.17, 0.35, 0.95) if open else Color(0.03, 0.08, 0.16, 0.94)
	hover.shadow_size = 18 if open else 10
	hover.shadow_color = Color(1.0, 0.84, 0.30, 0.30) if open else Color(0, 0, 0, 0.38)
	card.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.border_color = GOLD
	pressed.bg_color = Color(0.10, 0.21, 0.42, 0.98)
	card.add_theme_stylebox_override("pressed", pressed)
	var focus := StyleBoxFlat.new()
	focus.border_color = Color(1, 0.95, 0.62, 0.95)
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(18)
	focus.draw_center = false
	card.add_theme_stylebox_override("focus", focus)
	_juice(card, 1.035)
	if current:
		var halo := Panel.new()
		var halo_sb := StyleBoxFlat.new()
		halo_sb.draw_center = false
		halo_sb.border_color = Color(1.0, 0.90, 0.50, 1.0)
		halo_sb.set_border_width_all(3)
		halo_sb.set_corner_radius_all(18)
		halo_sb.shadow_size = 14
		halo_sb.shadow_color = Color(1.0, 0.84, 0.30, 0.35)
		halo.add_theme_stylebox_override("panel", halo_sb)
		halo.size = card_size
		halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(halo)
		var pulse := halo.create_tween().set_loops()
		pulse.tween_property(halo, "modulate:a", 0.15, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse.tween_property(halo, "modulate:a", 1.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# thumbnail, clipped to the card's rounded-ish top area
	var frame := Control.new()
	frame.position = Vector2(10, 10)
	frame.size = Vector2(card_size.x - 20.0, 190.0)
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(frame)
	var thumb_path := LEVEL_THUMB % n
	if ResourceLoader.exists(thumb_path):
		var thumb := TextureRect.new()
		thumb.texture = load(thumb_path) as Texture2D
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb.size = frame.size
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		thumb.pivot_offset = thumb.size * 0.5
		frame.add_child(thumb)
		if open:
			card.mouse_entered.connect(_zoom_thumb.bind(thumb, 1.09))
			card.mouse_exited.connect(_zoom_thumb.bind(thumb, 1.0))
			card.focus_entered.connect(_zoom_thumb.bind(thumb, 1.09))
			card.focus_exited.connect(_zoom_thumb.bind(thumb, 1.0))
	if not open:
		var dim := ColorRect.new()
		dim.color = Color(0.01, 0.03, 0.08, 0.66)
		dim.size = frame.size
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(dim)
		var lock := Lock.new()
		lock.size = Vector2(52, 64)
		lock.position = Vector2((frame.size.x - 52.0) * 0.5, (frame.size.y - 64.0) * 0.5)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(lock)
	elif done:
		var done_badge := PanelContainer.new()
		var db := _sb(Color(0.10, 0.62, 0.32, 0.92), Color(0.55, 1.0, 0.72, 0.9), 0, 10)
		db.content_margin_left = 10
		db.content_margin_right = 10
		db.content_margin_top = 3
		db.content_margin_bottom = 3
		done_badge.add_theme_stylebox_override("panel", db)
		done_badge.position = Vector2(frame.size.x - 76.0, 10)
		done_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dl := Label.new()
		dl.text = "DONE"
		dl.add_theme_font_size_override("font_size", 12)
		dl.add_theme_color_override("font_color", Color(0.92, 1.0, 0.94))
		done_badge.add_child(dl)
		frame.add_child(done_badge)
	elif n == unlocked:
		var new_badge := PanelContainer.new()
		var nb := _sb(GOLD, GOLD, 0, 10)
		nb.content_margin_left = 10
		nb.content_margin_right = 10
		nb.content_margin_top = 3
		nb.content_margin_bottom = 3
		new_badge.add_theme_stylebox_override("panel", nb)
		new_badge.position = Vector2(frame.size.x - 70.0, 10)
		new_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var nl := Label.new()
		nl.text = "NEW"
		nl.add_theme_font_size_override("font_size", 12)
		nl.add_theme_color_override("font_color", Color(0.10, 0.08, 0.03))
		new_badge.add_child(nl)
		frame.add_child(new_badge)

	var day_label := Label.new()
	day_label.text = _spaced("DAY %d" % n)
	day_label.add_theme_font_size_override("font_size", 13)
	day_label.add_theme_color_override("font_color", GOLD if open else Color(0.52, 0.62, 0.76, 0.8))
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_label.position = Vector2(0, 208)
	day_label.size = Vector2(card_size.x, 22)
	day_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(day_label)

	var name_label := Label.new()
	name_label.text = level_name
	name_label.add_theme_font_size_override("font_size", 23)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1) if open else Color(0.66, 0.75, 0.88, 0.85))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.position = Vector2(12, 236)
	name_label.size = Vector2(card_size.x - 24.0, 62)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_label)


func _on_level_pressed(n: int, open: bool, card: Button) -> void:
	if not open:
		var unlocked: int = 1
		if GameState:
			unlocked = clampi(GameState.unlocked_day, 1, LEVELS.size())
		if _level_toast:
			_level_toast.text = "Complete Day %d to unlock this level" % maxi(1, n - 1)
			_level_toast.modulate.a = 1.0
			if _level_toast_tween and _level_toast_tween.is_valid():
				_level_toast_tween.kill()
			_level_toast_tween = create_tween()
			_level_toast_tween.tween_interval(1.4)
			_level_toast_tween.tween_property(_level_toast, "modulate:a", 0.0, 0.5)
		# shake, like the web card
		var tw := create_tween()
		var x := card.position.x
		for dx in [10.0, -9.0, 7.0, -6.0, 4.0, 0.0]:
			tw.tween_property(card, "position:x", x + dx, 0.045)
		return
	_start(n)


func show_levels() -> void:
	_current = "levels"
	# progression may have changed since the menu was built
	var unlocked: int = 1
	if GameState:
		unlocked = clampi(GameState.unlocked_day, 1, LEVELS.size())
	_update_level_progress()
	for i in _level_cards.size():
		var card := _level_cards[i]
		var n := i + 1
		_refresh_level_card(card, n, n <= unlocked, n < unlocked)
	_show_only(_screen_levels)
	_fade_in(_screen_levels)
	if not _level_cards.is_empty():
		_level_cards[0].grab_focus()


func _update_level_progress() -> void:
	if _level_progress == null:
		return
	var unlocked: int = 1
	if GameState:
		unlocked = clampi(GameState.unlocked_day, 1, LEVELS.size())
	var finished := unlocked - 1
	_level_progress.text = "%d / %d DAYS COMPLETED" % [finished, LEVELS.size()]
	var tw := create_tween()
	tw.tween_property(_level_progress_bar, "value", float(finished), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _zoom_thumb(thumb: Control, factor: float) -> void:
	if not is_instance_valid(thumb):
		return
	var tw := thumb.create_tween()
	tw.tween_property(thumb, "scale", Vector2(factor, factor), 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _refresh_level_card(card: Button, n: int, open: bool, done: bool) -> void:
	## Just the lock veil: the badge state is rebuilt by show_levels() on
	## re-entry, so a finished day loses its lock immediately.
	var frame := card.get_child(0) as Control
	if frame == null or frame.get_child_count() == 0:
		return
	var veil := frame.get_node_or_null("LockVeil")
	if open and veil:
		veil.queue_free()
	elif not open and veil == null:
		var dim := ColorRect.new()
		dim.name = "LockVeil"
		dim.color = Color(0.01, 0.03, 0.08, 0.66)
		dim.size = frame.size
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(dim)
		var lock := Lock.new()
		lock.size = Vector2(52, 64)
		lock.position = Vector2((frame.size.x - 52.0) * 0.5, (frame.size.y - 64.0) * 0.5)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(lock)


func _build_settings_screen() -> void:
	_screen_settings = _screen()
	_settings_panel = _screen_settings

	var dim := ColorRect.new()
	dim.color = Color(0.008, 0.03, 0.08, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_screen_settings.add_child(dim)

	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _sb(Color.html("#0a1f42"), Color(0.31, 0.72, 1.0, 0.9), 2, 18))
	box.custom_minimum_size = Vector2(560, 490)
	box.position = Vector2(520, 300)
	box.size = Vector2(560, 490)
	_screen_settings.add_child(box)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	box.add_child(col)

	var heading := Label.new()
	heading.text = "SETTINGS"
	heading.add_theme_font_size_override("font_size", 32)
	heading.add_theme_color_override("font_color", GOLD)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(heading)

	var vol_caption := Label.new()
	vol_caption.text = _spaced("VOICE VOLUME")
	vol_caption.add_theme_font_size_override("font_size", 15)
	vol_caption.add_theme_color_override("font_color", MUTED)
	col.add_child(vol_caption)

	_vol_slider = HSlider.new()
	_vol_slider.min_value = 0
	_vol_slider.max_value = 100
	_vol_slider.step = 1
	_vol_slider.value = 100
	if Settings:
		_vol_slider.value = int(round(Settings.voice_volume * 100.0))
	_vol_slider.custom_minimum_size = Vector2(0, 40)
	_style_slider(_vol_slider)
	_vol_slider.value_changed.connect(_on_volume_changed)
	_vol_slider.drag_ended.connect(func(_c: bool) -> void: _apply_volume())
	col.add_child(_vol_slider)

	_vol_label = Label.new()
	_vol_label.text = "%d%%" % int(round(_vol_slider.value))
	_vol_label.add_theme_font_size_override("font_size", 16)
	_vol_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_vol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_vol_label)

	# Look sensitivity: works for mouse, trackpad and touch drag alike.
	# 30-250 % maps to Settings.look_sensitivity 0.3-2.5.
	var look_caption := Label.new()
	look_caption.text = _spaced("LOOK SENSITIVITY")
	look_caption.add_theme_font_size_override("font_size", 15)
	look_caption.add_theme_color_override("font_color", MUTED)
	col.add_child(look_caption)

	_look_slider = HSlider.new()
	_look_slider.min_value = 30
	_look_slider.max_value = 250
	_look_slider.step = 5
	_look_slider.value = 100
	if Settings:
		_look_slider.value = int(round(Settings.look_sensitivity * 100.0))
	_look_slider.custom_minimum_size = Vector2(0, 40)
	_style_slider(_look_slider)
	_look_slider.value_changed.connect(_on_look_changed)
	_look_slider.drag_ended.connect(func(_c: bool) -> void: _apply_look())
	col.add_child(_look_slider)

	_look_label = Label.new()
	_look_label.text = "%d%%" % int(round(_look_slider.value))
	_look_label.add_theme_font_size_override("font_size", 16)
	_look_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_look_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_look_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)

	var change := _button("CHANGE PLAYER", 18)
	change.custom_minimum_size = Vector2(230, 68)
	change.size = Vector2(230, 68)
	change.pressed.connect(_change_player)
	row.add_child(change)

	var done := _button("DONE", 18)
	done.custom_minimum_size = Vector2(180, 68)
	done.size = Vector2(180, 68)
	done.pressed.connect(hide_settings)
	row.add_child(done)

	_focus_chain([change, done])


func _build_intro_screen() -> void:
	## The web build's cinematic card (js/cinematic.js): black screen, letterbox
	## bars, the ANITS crest, the Little Hearts mark, the studio line and the
	## developer credit.  No music, matching the "models and voices only" brief.
	_screen_intro = Control.new()
	_screen_intro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen_intro.mouse_filter = Control.MOUSE_FILTER_STOP
	_screen_intro.visible = false
	_screen_intro.gui_input.connect(_on_intro_gui_input)
	_root.add_child(_screen_intro)

	var black := ColorRect.new()
	black.color = Color(0.0196, 0.0196, 0.0235)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_intro.add_child(black)

	var glow := _radial_glow(1200.0, Color(0.16, 0.47, 1.0, 0.11))
	glow.anchor_left = 0.5
	glow.anchor_right = 0.5
	glow.anchor_top = 0.5
	glow.anchor_bottom = 0.5
	glow.offset_left = -600.0
	glow.offset_right = 600.0
	glow.offset_top = -600.0
	glow.offset_bottom = 600.0
	_screen_intro.add_child(glow)

	_intro_top = ColorRect.new()
	_intro_top.color = Color.BLACK
	_intro_top.anchor_right = 1.0
	_intro_top.offset_bottom = 0.0
	_intro_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_intro.add_child(_intro_top)

	_intro_bottom = ColorRect.new()
	_intro_bottom.color = Color.BLACK
	_intro_bottom.anchor_top = 1.0
	_intro_bottom.anchor_right = 1.0
	_intro_bottom.anchor_bottom = 1.0
	_intro_bottom.offset_top = 0.0
	_intro_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_intro.add_child(_intro_bottom)

	_intro_logo = TextureRect.new()
	_intro_logo.texture = load(LOGO) as Texture2D
	_intro_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_intro_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_intro_logo.anchor_left = 0.5
	_intro_logo.anchor_right = 0.5
	_intro_logo.anchor_top = 0.5
	_intro_logo.anchor_bottom = 0.5
	_intro_logo.offset_left = -220.0
	_intro_logo.offset_right = 220.0
	_intro_logo.offset_top = -220.0
	_intro_logo.offset_bottom = 220.0
	_intro_logo.modulate.a = 0.0
	_intro_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_intro.add_child(_intro_logo)

	_intro_mark = TextureRect.new()
	_intro_mark.texture = load(STUDIO_LOGO) as Texture2D
	_intro_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_intro_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_intro_mark.anchor_left = 0.5
	_intro_mark.anchor_right = 0.5
	_intro_mark.anchor_top = 0.5
	_intro_mark.anchor_bottom = 0.5
	_intro_mark.offset_left = -120.0
	_intro_mark.offset_right = 120.0
	_intro_mark.offset_top = -230.0
	_intro_mark.offset_bottom = -15.0
	_intro_mark.modulate.a = 0.0
	_intro_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_intro.add_child(_intro_mark)

	_intro_studio = Label.new()
	_intro_studio.text = "A LITTLE HEART PRODUCTION"
	_intro_studio.add_theme_font_size_override("font_size", 30)
	_intro_studio.add_theme_color_override("font_color", Color(0.957, 0.925, 0.910))
	_intro_studio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro_studio.anchor_left = 0.0
	_intro_studio.anchor_right = 1.0
	_intro_studio.anchor_top = 0.5
	_intro_studio.anchor_bottom = 0.5
	_intro_studio.offset_top = 10.0
	_intro_studio.offset_bottom = 56.0
	_intro_studio.modulate.a = 0.0
	_intro_studio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_intro.add_child(_intro_studio)

	_intro_dev = Label.new()
	_intro_dev.text = "Developed by akhilboss"
	_intro_dev.add_theme_font_size_override("font_size", 19)
	_intro_dev.add_theme_color_override("font_color", Color(0.957, 0.925, 0.910, 0.66))
	_intro_dev.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro_dev.anchor_left = 0.0
	_intro_dev.anchor_right = 1.0
	_intro_dev.anchor_top = 0.5
	_intro_dev.anchor_bottom = 0.5
	_intro_dev.offset_top = 66.0
	_intro_dev.offset_bottom = 100.0
	_intro_dev.modulate.a = 0.0
	_intro_dev.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_intro.add_child(_intro_dev)

	_intro_skip = _button("SKIP", 16)
	_intro_skip.custom_minimum_size = Vector2(132, 50)
	_intro_skip.size = Vector2(132, 50)
	_intro_skip.anchor_left = 1.0
	_intro_skip.anchor_right = 1.0
	_intro_skip.anchor_top = 1.0
	_intro_skip.anchor_bottom = 1.0
	_intro_skip.offset_left = -160.0
	_intro_skip.offset_right = -28.0
	_intro_skip.offset_top = -78.0
	_intro_skip.offset_bottom = -28.0
	_intro_skip.visible = false
	_intro_skip.pressed.connect(_skip_intro)
	_screen_intro.add_child(_intro_skip)


func _build_loading_screen() -> void:
	## js/menu.js `#s-load`: campus photo, crest, a quote, the blue progress bar
	## and "LOADING...  DAY n · LEVEL".
	_screen_loading = Control.new()
	_screen_loading.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen_loading.mouse_filter = Control.MOUSE_FILTER_STOP
	_screen_loading.visible = false
	_screen_loading.gui_input.connect(_on_loading_gui_input)
	_root.add_child(_screen_loading)

	var bg := TextureRect.new()
	if ResourceLoader.exists(BG_PHOTO):
		bg.texture = load(BG_PHOTO) as Texture2D
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_loading.add_child(bg)
	bg.resized.connect(func() -> void: bg.pivot_offset = bg.size * 0.5)
	_loading_bg = bg

	var shade := ColorRect.new()
	shade.color = Color(0.008, 0.047, 0.133, 0.62)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_loading.add_child(shade)

	var logo := TextureRect.new()
	logo.texture = load(LOGO) as Texture2D
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.anchor_left = 0.5
	logo.anchor_right = 0.5
	logo.anchor_top = 0.0
	logo.anchor_bottom = 0.0
	logo.offset_left = -110.0
	logo.offset_right = 110.0
	logo.offset_top = 28.0
	logo.offset_bottom = 248.0
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_loading.add_child(logo)
	logo.resized.connect(func() -> void: logo.pivot_offset = logo.size * 0.5)
	_loading_logo = logo

	var spinner := Spinner.new()
	spinner.anchor_left = 0.5
	spinner.anchor_right = 0.5
	spinner.anchor_top = 0.5
	spinner.anchor_bottom = 0.5
	spinner.offset_left = -44.0
	spinner.offset_right = 44.0
	spinner.offset_top = -44.0
	spinner.offset_bottom = 44.0
	spinner.pivot_offset = Vector2(44.0, 44.0)
	spinner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_loading.add_child(spinner)
	_loading_spinner = spinner

	var caption := Label.new()
	caption.text = "COLLEGE SIMULATION"
	caption.add_theme_font_size_override("font_size", 20)
	caption.add_theme_color_override("font_color", Color(0.80, 0.90, 1.0, 0.82))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.anchor_left = 0.0
	caption.anchor_right = 1.0
	caption.anchor_top = 0.0
	caption.anchor_bottom = 0.0
	caption.offset_top = 252.0
	caption.offset_bottom = 284.0
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_loading.add_child(caption)

	_loading_quote = Label.new()
	_loading_quote.text = ""
	_loading_quote.add_theme_font_size_override("font_size", 26)
	_loading_quote.add_theme_color_override("font_color", Color(0.93, 0.97, 1.0))
	_loading_quote.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_loading_quote.add_theme_constant_override("outline_size", 5)
	_loading_quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_loading_quote.anchor_left = 0.5
	_loading_quote.anchor_right = 0.5
	_loading_quote.anchor_top = 1.0
	_loading_quote.anchor_bottom = 1.0
	_loading_quote.offset_left = -360.0
	_loading_quote.offset_right = 360.0
	_loading_quote.offset_top = -250.0
	_loading_quote.offset_bottom = -150.0
	_loading_quote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_loading.add_child(_loading_quote)

	_loading_bar = ProgressBar.new()
	_loading_bar.min_value = 0
	_loading_bar.max_value = 100
	_loading_bar.value = 0
	_loading_bar.show_percentage = false
	_loading_bar.anchor_left = 0.5
	_loading_bar.anchor_right = 0.5
	_loading_bar.anchor_top = 1.0
	_loading_bar.anchor_bottom = 1.0
	_loading_bar.offset_left = -360.0
	_loading_bar.offset_right = 360.0
	_loading_bar.offset_top = -126.0
	_loading_bar.offset_bottom = -106.0
	_loading_bar.add_theme_stylebox_override("background",
			_sb(Color(0.012, 0.055, 0.149, 0.72), Color(0.31, 0.69, 1.0, 0.95), 2, 9))
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.26, 0.68, 1.0)
	fill.set_corner_radius_all(8)
	fill.shadow_size = 10
	fill.shadow_color = Color(0.30, 0.70, 1.0, 0.55)
	_loading_bar.add_theme_stylebox_override("fill", fill)
	_loading_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_bar.clip_contents = true
	_screen_loading.add_child(_loading_bar)
	_loading_shine = ColorRect.new()
	_loading_shine.color = Color(1, 1, 1, 0.30)
	_loading_shine.size = Vector2(90, 20)
	_loading_shine.position = Vector2(-90, 0)
	_loading_shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_bar.add_child(_loading_shine)

	_loading_pct = Label.new()
	_loading_pct.text = "0%"
	_loading_pct.add_theme_font_size_override("font_size", 18)
	_loading_pct.add_theme_color_override("font_color", GOLD)
	_loading_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_loading_pct.anchor_left = 0.5
	_loading_pct.anchor_right = 0.5
	_loading_pct.anchor_top = 1.0
	_loading_pct.anchor_bottom = 1.0
	_loading_pct.offset_left = 200.0
	_loading_pct.offset_right = 360.0
	_loading_pct.offset_top = -160.0
	_loading_pct.offset_bottom = -130.0
	_loading_pct.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_loading.add_child(_loading_pct)
	_loading_bar.value_changed.connect(func(v: float) -> void: _loading_pct.text = "%d%%" % int(v))

	_loading_status = Label.new()
	_loading_status.text = "LOADING..."
	_loading_status.add_theme_font_size_override("font_size", 15)
	_loading_status.add_theme_color_override("font_color", Color(0.82, 0.92, 1.0, 0.85))
	_loading_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_status.anchor_left = 0.0
	_loading_status.anchor_right = 1.0
	_loading_status.anchor_top = 1.0
	_loading_status.anchor_bottom = 1.0
	_loading_status.offset_top = -94.0
	_loading_status.offset_bottom = -56.0
	_loading_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_loading.add_child(_loading_status)


func _build_footer() -> void:
	## The web build's footer: a soft dark band with the studio and the author.
	var band := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.008, 0.031, 0.078, 0.0))
	grad.set_color(1, Color(0.008, 0.031, 0.078, 0.88))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0.0, 0.0)
	tex.fill_to = Vector2(0.0, 1.0)
	tex.width = 8
	tex.height = 128
	band.texture = tex
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.position = Vector2(-800, 960)
	band.size = Vector2(3200, 120)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(band)

	var row := HBoxContainer.new()
	row.anchor_left = 0.0
	row.anchor_right = 1.0
	row.anchor_top = 1.0
	row.anchor_bottom = 1.0
	row.offset_left = 0.0
	row.offset_right = 0.0
	row.offset_top = -96.0
	row.offset_bottom = -44.0
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(row)

	var heart := Heart.new()
	heart.size = Vector2(20, 20)
	heart.custom_minimum_size = Vector2(20, 20)
	heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(heart)
	row.add_child(_footer_text("Powered by", "Little Hearts"))
	row.add_child(_footer_rule())
	row.add_child(_footer_text("Developed by", "AKHILBOSS"))
	row.add_child(_footer_rule())
	row.add_child(_footer_text("Godot 4 remake of", "ANITS College Simulation"))


# ---------------------------------------------------------------- widgets

func _screen() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.visible = false
	_canvas.add_child(c)
	return c


func _headline(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", int(font_size * _ui))
	l.add_theme_color_override("font_color", SKY_TEXT)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(DESIGN_W, 70)
	l.position = Vector2(0, 54)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _caption(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", int(20 * _ui))
	l.add_theme_color_override("font_color", Color(0.75, 0.86, 1.0, 0.8))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(DESIGN_W, 30)
	l.position = Vector2(0, 128)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, font_size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(240, 62)
	b.add_theme_font_size_override("font_size", int(font_size * _ui))
	b.focus_mode = Control.FOCUS_ALL
	_style_button(b, false)
	_juice(b, 1.04)
	return b


func _glass(parent: Control, rect: Rect2) -> Panel:
	## A translucent rounded panel with a soft shadow: the shared glass look.
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.15, 0.32, 0.46)
	sb.border_color = Color(0.75, 0.90, 1.0, 0.22)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(30)
	sb.shadow_size = 28
	sb.shadow_color = Color(0, 0, 0, 0.38)
	sb.shadow_offset = Vector2(0, 12)
	p.add_theme_stylebox_override("panel", sb)
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


func _juice(b: Button, lift: float) -> void:
	## Hover / focus lift and a press squash on any button.
	b.mouse_entered.connect(_pop.bind(b, lift, 0.16))
	b.mouse_exited.connect(_pop.bind(b, 1.0, 0.20))
	b.focus_entered.connect(_pop.bind(b, lift, 0.16))
	b.focus_exited.connect(_pop.bind(b, 1.0, 0.20))
	b.button_down.connect(_pop.bind(b, 0.96, 0.08))
	b.button_up.connect(func() -> void: _pop(b, lift if b.is_hovered() else 1.0, 0.14))


func _pop(b: Button, target: float, dur: float) -> void:
	if not is_instance_valid(b) or (b.disabled and target != 1.0):
		return
	b.pivot_offset = b.size * 0.5
	if b.has_meta("pop_tween"):
		var old: Tween = b.get_meta("pop_tween")
		if old and old.is_valid():
			old.kill()
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(target, target), dur).set_trans(
			Tween.TRANS_BACK if target > 1.0 else Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	b.set_meta("pop_tween", tw)


func _swatch(colour: Color) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = colour
	sb.border_color = Color(1, 1, 1, 0.75)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(28)
	p.add_theme_stylebox_override("panel", sb)
	p.size = Vector2(56, 56)
	p.custom_minimum_size = Vector2(56, 56)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _footer_text(lead: String, bold: String) -> Label:
	var l := Label.new()
	l.text = "%s %s" % [lead, bold]
	l.add_theme_font_size_override("font_size", int(15 * _ui))
	l.add_theme_color_override("font_color", Color(0.72, 0.84, 0.98, 0.9))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _footer_rule() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.55, 0.78, 1.0, 0.45)
	r.custom_minimum_size = Vector2(2, 22)
	r.size = Vector2(2, 22)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _sb(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	if bg.a > 0.05:
		sb.shadow_size = 8
		sb.shadow_color = Color(0, 0, 0, 0.30)
		sb.shadow_offset = Vector2(0, 4)
	return sb


func _style_button(b: Button, primary: bool) -> void:
	var base := Color(0.07, 0.18, 0.38, 0.66)
	var hover := Color(0.13, 0.33, 0.66, 0.90)
	var border := Color(0.66, 0.86, 1.0, 0.50)
	if primary:
		base = Color(0.13, 0.47, 0.92, 0.96)
		hover = Color(0.22, 0.62, 1.0, 1.0)
		border = Color(0.80, 0.92, 1.0, 0.95)
	b.add_theme_stylebox_override("normal", _sb(base, border, 2, 14))
	b.add_theme_stylebox_override("hover", _sb(hover, Color(0.85, 0.95, 1.0, 1.0), 2, 14))
	b.add_theme_stylebox_override("pressed", _sb(base.darkened(0.18), GOLD, 2, 14))
	var focus := _sb(Color(0, 0, 0, 0), GOLD, 3, 14)
	focus.draw_center = false
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_stylebox_override("disabled",
			_sb(Color(0.05, 0.09, 0.17, 0.55), Color(0.40, 0.50, 0.66, 0.45), 2, 14))
	b.add_theme_color_override("font_color", Color(0.93, 0.97, 1.0))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_pressed_color", Color(1, 0.92, 0.6))
	b.add_theme_color_override("font_focus_color", Color(1, 1, 1))
	b.add_theme_color_override("font_disabled_color", Color(0.60, 0.68, 0.80, 0.45))


func _style_slider(s: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.42, 0.72, 1.0, 0.28)
	track.set_corner_radius_all(8)
	track.content_margin_top = 16
	track.content_margin_bottom = 16
	s.add_theme_stylebox_override("slider", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = GOLD
	fill.set_corner_radius_all(8)
	fill.content_margin_top = 16
	fill.content_margin_bottom = 16
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	s.add_theme_icon_override("grabber", _disc_texture(48, Color(1.0, 0.86, 0.36)))
	s.add_theme_icon_override("grabber_disabled", _disc_texture(48, Color(0.6, 0.6, 0.6, 0.5)))


func _disc_texture(diameter: int, colour: Color) -> Texture2D:
	## A soft glowing disc, used for the slider grabber.
	var g := Gradient.new()
	g.set_color(0, colour)
	g.set_color(1, Color(colour.r, colour.g, colour.b, 0.0))
	g.add_point(0.55, colour)
	g.add_point(0.72, Color(1, 1, 1, 0.95))
	g.add_point(0.86, Color(1, 1, 1, 0.18))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = diameter
	tex.height = diameter
	return tex


func _radial_glow(diameter: float, colour: Color) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, colour)
	g.set_color(1, Color(colour.r, colour.g, colour.b, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	var rect := TextureRect.new()
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.custom_minimum_size = Vector2(diameter, diameter)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _spaced(text: String) -> String:
	var out := ""
	for i in text.length():
		if i > 0:
			out += " "
		out += text[i]
	return out


func _focus_chain(nodes: Array) -> void:
	## Wires the arrow keys between a vertical list of controls.
	for i in nodes.size():
		var a := nodes[i] as Control
		if a == null:
			continue
		if i > 0:
			var up := nodes[i - 1] as Control
			if up:
				a.focus_neighbor_top = a.get_path_to(up)
				up.focus_neighbor_bottom = up.get_path_to(a)
		if i < nodes.size() - 1:
			var down := nodes[i + 1] as Control
			if down:
				a.focus_neighbor_bottom = a.get_path_to(down)
				down.focus_neighbor_top = down.get_path_to(a)


func _focus_row(nodes: Array) -> void:
	## Wires the arrow keys between a horizontal list of controls.
	for i in nodes.size():
		var a := nodes[i] as Control
		if a == null:
			continue
		if i > 0:
			var left := nodes[i - 1] as Control
			if left:
				a.focus_neighbor_left = a.get_path_to(left)
				left.focus_neighbor_right = left.get_path_to(a)
		if i < nodes.size() - 1:
			var right := nodes[i + 1] as Control
			if right:
				a.focus_neighbor_right = a.get_path_to(right)
				right.focus_neighbor_left = right.get_path_to(a)


func _icon_button(b: Button, kind: String, icon_pos: Vector2) -> void:
	## Turns a button into the web build's icon + rule + label row.
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	for key in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := b.get_theme_stylebox(key) as StyleBoxFlat
		if sb:
			sb.content_margin_left = 104
	var icon := Icon.new()
	icon.kind = kind
	icon.size = Vector2(28, 28)
	icon.position = icon_pos
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)
	var rule := ColorRect.new()
	rule.color = Color(0.62, 0.84, 1.0, 0.45)
	rule.size = Vector2(2, 32)
	rule.position = Vector2(icon_pos.x + 44.0, icon_pos.y - 2.0)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(rule)


# ---------------------------------------------------------------- character cards

func _make_card(model_id: String, title: String, tag: String, colour: Color, pos: Vector2) -> void:
	var card := Button.new()
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
	card.size = Vector2(CARD_W, CARD_H)
	card.position = pos
	card.focus_mode = Control.FOCUS_ALL
	card.text = ""
	_style_card(card, false)
	_juice(card, 1.025)
	card.pressed.connect(func() -> void: _choose(model_id))
	_screen_char.add_child(card)

	# live preview of the original model
	var vp := _build_preview(model_id, 1.65 if model_id == "girl" else 1.75)
	var preview := TextureRect.new()
	preview.texture = vp.get_texture()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.position = Vector2(22, 44)
	preview.size = Vector2(CARD_W - 44.0, 470)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(preview)

	var name_label := Label.new()
	name_label.text = title
	name_label.add_theme_font_size_override("font_size", 34)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(0, CARD_H - 108.0)
	name_label.size = Vector2(CARD_W, 46)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_label)

	var tag_label := Label.new()
	tag_label.text = _spaced(tag)
	tag_label.add_theme_font_size_override("font_size", 15)
	tag_label.add_theme_color_override("font_color", colour)
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_label.position = Vector2(0, CARD_H - 62.0)
	tag_label.size = Vector2(CARD_W, 28)
	tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(tag_label)

	var badge := PanelContainer.new()
	var badge_style := _sb(GOLD, GOLD, 0, 12)
	badge_style.content_margin_left = 14
	badge_style.content_margin_right = 14
	badge_style.content_margin_top = 5
	badge_style.content_margin_bottom = 5
	badge.add_theme_stylebox_override("panel", badge_style)
	badge.custom_minimum_size = Vector2(112, 30)
	badge.position = Vector2(CARD_W - 128.0, 16)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_text := Label.new()
	badge_text.text = "SELECTED"
	badge_text.add_theme_font_size_override("font_size", 13)
	badge_text.add_theme_color_override("font_color", Color(0.08, 0.08, 0.10))
	badge.add_child(badge_text)
	card.add_child(badge)

	_cards[model_id] = {"button": card, "badge": badge, "colour": colour}


func _style_card(card: Button, selected: bool) -> void:
	var border := Color(0.42, 0.74, 1.0, 0.55)
	var bg := Color(0.035, 0.11, 0.25, 0.72)
	if selected:
		border = GOLD
		bg = Color(0.09, 0.16, 0.32, 0.88)
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = border
	normal.set_border_width_all(2 if not selected else 3)
	normal.set_corner_radius_all(24)
	normal.shadow_size = 22 if selected else 12
	normal.shadow_color = Color(1.0, 0.84, 0.30, 0.30) if selected else Color(0, 0, 0, 0.4)
	normal.shadow_offset = Vector2(0, 0) if selected else Vector2(0, 6)
	normal.content_margin_left = 0
	normal.content_margin_right = 0
	normal.content_margin_top = 0
	normal.content_margin_bottom = 0
	card.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = GOLD if not selected else Color(1, 1, 1, 0.9)
	hover.bg_color = Color(0.07, 0.15, 0.33, 0.86)
	card.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.12, 0.22, 0.44, 0.95)
	pressed.border_color = GOLD
	card.add_theme_stylebox_override("pressed", pressed)
	var focus := StyleBoxFlat.new()
	focus.border_color = Color(1, 0.95, 0.6, 0.95)
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(24)
	focus.draw_center = false
	card.add_theme_stylebox_override("focus", focus)


func _update_cards() -> void:
	for id in _cards:
		var entry: Dictionary = _cards[id]
		var card := entry["button"] as Button
		var badge := entry["badge"] as PanelContainer
		var selected := str(id) == character
		_style_card(card, selected)
		badge.visible = selected


func _build_preview(model_id: String, model_height: float) -> SubViewport:
	## A tiny 3D viewport showing the original character model, like the web
	## build's live canvas preview. It only renders while the screen is open.
	var vp := SubViewport.new()
	vp.size = Vector2i(PREVIEW_W, PREVIEW_H)
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(vp)

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.86, 0.92, 1.0)
	environment.ambient_light_energy = 1.25
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = environment
	vp.add_child(env)

	var key := DirectionalLight3D.new()
	key.light_energy = 1.7
	key.light_color = Color(1.0, 0.96, 0.90)
	key.rotation_degrees = Vector3(-32.0, 38.0, 0.0)
	key.shadow_enabled = false
	vp.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.8
	fill.light_color = Color(0.55, 0.72, 1.0)
	fill.rotation_degrees = Vector3(-12.0, -140.0, 0.0)
	fill.shadow_enabled = false
	vp.add_child(fill)

	var pivot := Node3D.new()
	vp.add_child(pivot)
	_preview_pivots.append(pivot)

	var visual := CharacterVisual.create(model_id, model_height)
	if visual:
		pivot.add_child(visual)
		visual.apply_uniform(year)
		_preview_visuals[model_id] = visual
		_play_preview(visual)

	var cam := Camera3D.new()
	cam.fov = 30.0
	cam.position = Vector3(0.0, 1.02, 4.4)
	vp.add_child(cam)
	cam.look_at(Vector3(0.0, 0.92, 0.0), Vector3.UP)

	if model_id == "girl":
		_preview_girl = vp
	else:
		_preview_boy = vp
	return vp


func _play_preview(visual: CharacterVisual) -> void:
	if visual == null or visual.anim == null:
		return
	# A slow talk loop reads as a living character without moving off its
	# card.  The walk cycle is only used as a posed fallback because its root
	# motion would carry the model sideways out of the preview.
	for clip_name in ["talk", "idle", "walk"]:
		if visual.anim.has_animation(clip_name):
			visual.anim.play(clip_name)
			visual.anim.speed_scale = 0.35
			if clip_name == "walk":
				visual.anim.seek(0.0, true)
				visual.anim.pause()
			return


# ---------------------------------------------------------------- screens

func _show_only(screen: Control) -> void:
	for s in [_screen_year, _screen_char, _screen_name, _screen_welcome,
			_screen_main, _screen_levels, _screen_settings]:
		(s as Control).visible = s == screen
	if _screen_intro and screen != _screen_intro:
		_screen_intro.visible = false
	if _screen_loading and screen != _screen_loading:
		_screen_loading.visible = false
	_update_preview_mode(screen == _screen_char)


func _update_preview_mode(on: bool) -> void:
	var mode := SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
	if _preview_boy:
		_preview_boy.render_target_update_mode = mode
	if _preview_girl:
		_preview_girl.render_target_update_mode = mode


func _fade_in(node: CanvasItem) -> void:
	## Screen entrance: the screen fades in and its direct children rise into
	## place one after another (staggered).
	if _screen_tween and _screen_tween.is_valid():
		_screen_tween.kill()
	node.modulate.a = 0.0
	_screen_tween = create_tween().set_parallel(true)
	_screen_tween.tween_property(node, "modulate:a", 1.0, 0.28)
	if not (node is Control) or node == _screen_welcome or node == _screen_settings:
		return
	var idx := 0
	for child in node.get_children():
		var c := child as Control
		if c == null or c.has_meta("no_stagger"):
			continue
		if not c.has_meta("rest_pos"):
			c.set_meta("rest_pos", c.position)
			c.set_meta("rest_a", c.modulate.a)
		var rest: Vector2 = c.get_meta("rest_pos")
		var rest_a: float = c.get_meta("rest_a")
		var delay := minf(float(idx) * 0.04, 0.55)
		c.position = rest + Vector2(0.0, 28.0)
		c.modulate.a = 0.0
		_screen_tween.tween_property(c, "position", rest, 0.52).set_delay(delay).set_trans(
				Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_screen_tween.tween_property(c, "modulate:a", rest_a, 0.40).set_delay(delay)
		idx += 1


func show_intro() -> void:
	## First launch plays the full 11 s card; later launches replay the short
	## 4 s version, exactly like `replay: 'short'` in js/cinematic.js.
	_current = "intro"
	_intro_done = false
	_intro_started_ms = Time.get_ticks_msec()
	for tw in _intro_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_intro_tweens.clear()
	_show_only(_screen_intro)
	_screen_intro.visible = true
	_screen_intro.modulate.a = 1.0
	_intro_logo.modulate.a = 0.0
	_intro_mark.modulate.a = 0.0
	_intro_studio.modulate.a = 0.0
	_intro_dev.modulate.a = 0.0
	_intro_skip.visible = false
	_intro_top.offset_bottom = 0.0
	_intro_bottom.offset_top = 0.0

	if OS.get_cmdline_user_args().has("--intro-reset"):
		_intro_seen_reset()
	var short := _intro_seen()
	var logo_at := 0.15 if short else 1.0
	var mark_at := 1.5 if short else 4.1
	var studio_at := 1.8 if short else 5.4
	var dev_at := 2.3 if short else 7.0
	var out_at := 3.4 if short else 9.8
	var out_dur := 0.7 if short else 1.2

	# Letterbox bars slide in from the top and bottom.
	var bars := create_tween()
	bars.tween_property(_intro_top, "offset_bottom", 120.0, 0.5 if short else 1.4)
	bars.parallel().tween_property(_intro_bottom, "offset_top", -120.0, 0.5 if short else 1.4)
	_intro_tweens.append(bars)

	_intro_track(_intro_logo, logo_at, 0.5 if short else 0.9,
			0.8 if short else 2.4, 0.35 if short else 0.6)
	_intro_track(_intro_mark, mark_at, 0.45 if short else 0.8,
			0.35 if short else 1.2, 0.3 if short else 0.5)
	_intro_track(_intro_studio, studio_at, 0.4 if short else 0.7,
			maxf(0.1, out_at - studio_at - 0.4), 0.3)
	_intro_track(_intro_dev, dev_at, 0.4 if short else 0.7,
			maxf(0.1, out_at - dev_at - 0.4), 0.3)

	var skip_tw := create_tween()
	skip_tw.tween_interval(0.6 if short else 1.0)
	skip_tw.tween_callback(func() -> void: _intro_skip.visible = true)
	_intro_tweens.append(skip_tw)

	var end_tw := create_tween()
	end_tw.tween_interval(out_at)
	end_tw.tween_property(_screen_intro, "modulate:a", 0.0, out_dur)
	end_tw.tween_callback(_intro_complete)
	_intro_tweens.append(end_tw)


func _intro_track(node: CanvasItem, at: float, fade_in: float,
		hold: float, fade_out: float) -> void:
	var tw := create_tween()
	tw.tween_interval(at)
	tw.tween_property(node, "modulate:a", 1.0, fade_in)
	tw.tween_interval(hold)
	tw.tween_property(node, "modulate:a", 0.0, fade_out)
	_intro_tweens.append(tw)


func _on_loading_gui_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		pressed = (event as InputEventMouseButton).pressed
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if pressed and _loading_bar.value >= 100.0:
		loading_go.emit()


func _on_intro_gui_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		pressed = (event as InputEventMouseButton).pressed
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if not pressed:
		return
	# js/cinematic.js: a tap skips only after 700 ms of playback.
	if Time.get_ticks_msec() - _intro_started_ms > 700:
		_skip_intro()


func _skip_intro() -> void:
	if _intro_done:
		return
	_intro_done = true
	for tw in _intro_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_intro_tweens.clear()
	var tw := create_tween()
	tw.tween_property(_screen_intro, "modulate:a", 0.0, 0.25)
	tw.tween_callback(_intro_to_menu)


func _intro_complete() -> void:
	if _intro_done:
		return
	_intro_done = true
	_intro_to_menu()


func _intro_to_menu() -> void:
	_intro_seen_save()
	_screen_intro.visible = false
	show_year()


func _intro_seen() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(INTRO_CFG) != OK:
		return false
	return bool(cfg.get_value("intro", "seen", false))


func _intro_seen_save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(INTRO_CFG)
	cfg.set_value("intro", "seen", true)
	cfg.save(INTRO_CFG)


func _intro_seen_reset() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("intro", "seen", false)
	cfg.save(INTRO_CFG)


func show_year() -> void:
	_current = "year"
	_on_year_changed(year)
	if _year_badge:
		_year_badge.text = "<  YEAR %d" % year
	_show_only(_screen_year)
	_fade_in(_screen_year)
	if _year_continue:
		_year_continue.grab_focus()


func show_character() -> void:
	_current = "char"
	_update_cards()
	_show_only(_screen_char)
	_fade_in(_screen_char)
	var card: Dictionary = _cards.get(character, {})
	var button := card.get("button") as Button
	if button:
		button.grab_focus()


func show_name() -> void:
	_current = "name"
	_show_only(_screen_name)
	_fade_in(_screen_name)
	if _name_input.text.strip_edges().is_empty():
		_name_input.text = player_name if player_name != "Player" else ""
	_on_name_changed(_name_input.text)
	_name_input.grab_focus()


func show_welcome() -> void:
	_current = "welcome"
	_welcome_top.text = "WELCOME"
	_welcome_name.text = ""
	_welcome_bottom.text = "TO ANITS COLLEGE"
	_welcome_bottom.modulate.a = 0.0
	_show_only(_screen_welcome)
	_fade_in(_screen_welcome)
	if _welcome_tween and _welcome_tween.is_valid():
		_welcome_tween.kill()
	_welcome_tween = create_tween()
	_welcome_tween.tween_property(_welcome_top, "modulate:a", 1.0, 0.30)
	var steps := maxi(1, player_name.length())
	_welcome_tween.tween_method(_type_welcome_name, 0.0, float(steps), 0.05 * float(steps))
	_welcome_tween.tween_callback(func() -> void: _welcome_bottom.modulate.a = 1.0)
	_welcome_tween.tween_property(_welcome_bottom, "modulate:a", 1.0, 0.45)
	_welcome_tween.tween_interval(1.1)
	_welcome_tween.tween_callback(show_main)


func show_main() -> void:
	_current = "main"
	if _welcome_tween and _welcome_tween.is_valid():
		_welcome_tween.kill()
	_refresh_profile()
	_show_only(_screen_main)
	_fade_in(_screen_main)
	if _main_play:
		_main_play.grab_focus()


func show_settings() -> void:
	_current = "settings"
	_show_only(_screen_settings)
	_fade_in(_screen_settings)


func hide_settings() -> void:
	_apply_volume()
	_apply_look()
	show_main()


func _change_player() -> void:
	show_year()


func _refresh_profile() -> void:
	if _main_label:
		_main_label.text = "PLAYING AS %s  ·  %s  ·  YEAR %d" % [
			player_name, "AMY" if character == "girl" else "MIKE", year]


func _type_welcome_name(value: float) -> void:
	if _welcome_name:
		_welcome_name.text = player_name.substr(0, int(value))


# ---------------------------------------------------------------- actions

func _on_year_chip(value: int) -> void:
	_year_slider.value = value
	_on_year_changed(value)


func _on_year_changed(value: float) -> void:
	year = int(value)
	var info: Array = UNIFORMS.get(year, UNIFORMS[2024])
	_year_value.text = str(year)
	_year_value.pivot_offset = _year_value.size * 0.5
	_year_value.scale = Vector2(1.14, 1.14)
	if _year_tween and _year_tween.is_valid():
		_year_tween.kill()
	_year_tween = create_tween()
	_year_tween.tween_property(_year_value, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_year_name.text = str(info[0])
	_year_desc.text = str(info[1])
	_swatch_top.add_theme_stylebox_override("panel", _swatch_style(info[2]))
	_swatch_bottom.add_theme_stylebox_override("panel", _swatch_style(info[3]))
	for chip in _year_chips:
		_style_chip(chip, int(chip.text) == year)
	if _year_badge:
		_year_badge.text = "<  YEAR %d" % year
	for model_id in _preview_visuals:
		var visual := _preview_visuals[model_id] as CharacterVisual
		if is_instance_valid(visual):
			visual.apply_uniform(year)


func _swatch_style(colour: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = colour
	sb.border_color = Color(1, 1, 1, 0.75)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(28)
	return sb


func _style_chip(chip: Button, selected: bool) -> void:
	var bg := Color(0.045, 0.125, 0.28, 0.80)
	var border := Color(0.42, 0.74, 1.0, 0.7)
	var font := Color(0.80, 0.90, 1.0, 0.85)
	if selected:
		bg = GOLD
		border = Color(1, 1, 1, 0.9)
		font = Color(0.10, 0.09, 0.05)
	chip.add_theme_stylebox_override("normal", _sb(bg, border, 2, 12))
	chip.add_theme_stylebox_override("hover", _sb(bg.lightened(0.12), GOLD, 2, 12))
	chip.add_theme_stylebox_override("pressed", _sb(bg.darkened(0.15), GOLD, 2, 12))
	var focus := _sb(Color(0, 0, 0, 0), GOLD, 3, 12)
	focus.draw_center = false
	chip.add_theme_stylebox_override("focus", focus)
	chip.add_theme_color_override("font_color", font)
	chip.add_theme_color_override("font_hover_color", font)
	chip.add_theme_color_override("font_pressed_color", font)
	chip.add_theme_color_override("font_focus_color", font)


func _on_name_changed(text: String) -> void:
	if _name_go:
		_name_go.disabled = text.strip_edges().is_empty()


func _choose(which: String) -> void:
	character = which
	_update_cards()
	if _choose_tween and _choose_tween.is_valid():
		_choose_tween.kill()
	_choose_tween = create_tween()
	_choose_tween.tween_interval(0.38)
	_choose_tween.tween_callback(show_name)


func _submit_name() -> void:
	if _current != "name":
		return
	player_name = _name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	_name_input.text = player_name
	show_welcome()


func _on_volume_changed(value: float) -> void:
	if _vol_label:
		_vol_label.text = "%d%%" % int(round(value))


func _apply_volume() -> void:
	if _vol_slider == null:
		return
	if Settings:
		Settings.set_voice_volume(clampf(_vol_slider.value / 100.0, 0.0, 1.0))


func _on_look_changed(value: float) -> void:
	if _look_label:
		_look_label.text = "%d%%" % int(round(value))
	# Live update so the camera responds while the slider is being dragged.
	if Settings:
		Settings.look_sensitivity = clampf(value / 100.0, 0.3, 2.5)


func _apply_look() -> void:
	if _look_slider == null:
		return
	if Settings:
		Settings.set_look_sensitivity(_look_slider.value / 100.0)


func _start(day: int = 1) -> void:
	if _starting:
		return
	_starting = true
	get_viewport().gui_release_focus()
	_show_loading(day)
	# Fill to 90 % while the menu hands over, then jump to 100 % when the
	# campus is ready (main.gd calls dismiss_loading()).
	var tw := create_tween()
	tw.tween_property(_loading_bar, "value", 90.0, 1.4)
	await tw.finished
	_loading_bar.value = 100.0
	# Same gate as js/menu.js: the bar fills to 100 %, then waits for a tap.
	_loading_status.text = "TAP ANYWHERE TO START" if _touch else "CLICK ANYWHERE TO START"
	if _quote_tween and _quote_tween.is_valid():
		_quote_tween.kill()
	var ready_pulse := create_tween().set_loops()
	ready_pulse.tween_property(_loading_status, "modulate:a", 0.35, 0.7).set_trans(Tween.TRANS_SINE)
	ready_pulse.tween_property(_loading_status, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
	_loading_loops.append(ready_pulse)
	await loading_go
	start_requested.emit({"name": player_name, "char": character, "year": year,
		"day": clampi(day, 1, 10)})


func _loading_stop_loops() -> void:
	for tw in _loading_loops:
		if tw and tw.is_valid():
			tw.kill()
	_loading_loops.clear()
	if _quote_tween and _quote_tween.is_valid():
		_quote_tween.kill()


func _loading_start_loops() -> void:
	_loading_stop_loops()
	_loading_bg.scale = Vector2.ONE
	_loading_logo.scale = Vector2.ONE
	_loading_status.modulate.a = 1.0
	var kb := create_tween()
	kb.tween_property(_loading_bg, "scale", Vector2(1.10, 1.10), 14.0).set_trans(Tween.TRANS_SINE)
	_loading_loops.append(kb)
	var breathe := create_tween().set_loops()
	breathe.tween_property(_loading_logo, "scale", Vector2(1.06, 1.06), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathe.tween_property(_loading_logo, "scale", Vector2.ONE, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_loading_loops.append(breathe)
	_loading_spinner.rotation = 0.0
	var spin := create_tween().set_loops()
	spin.tween_property(_loading_spinner, "rotation", TAU, 1.15).from(0.0)
	_loading_loops.append(spin)
	var sweep := create_tween().set_loops()
	sweep.tween_property(_loading_shine, "position:x", 740.0, 1.3).from(-90.0).set_trans(Tween.TRANS_SINE)
	sweep.tween_interval(0.4)
	_loading_loops.append(sweep)
	_quote_tween = create_tween().set_loops()
	_quote_tween.tween_interval(3.6)
	_quote_tween.tween_property(_loading_quote, "modulate:a", 0.0, 0.35)
	_quote_tween.tween_callback(func() -> void:
		_loading_quote.text = "\u201c%s\u201d" % LOADING_QUOTES[randi() % LOADING_QUOTES.size()])
	_quote_tween.tween_property(_loading_quote, "modulate:a", 1.0, 0.35)


func _show_loading(day: int) -> void:
	_current = "loading"
	_show_only(_screen_loading)
	_screen_loading.visible = true
	_screen_loading.modulate.a = 1.0
	_loading_quote.modulate.a = 1.0
	_loading_start_loops()
	_loading_bar.value = 0.0
	var title := "DAY %d" % clampi(day, 1, LEVELS.size())
	if day >= 1 and day <= LEVELS.size():
		title = "DAY %d · %s" % [day, str(LEVELS[day - 1]).to_upper()]
	_loading_status.text = "LOADING...  " + title
	var index := randi() % LOADING_QUOTES.size()
	_loading_quote.text = "“%s”" % LOADING_QUOTES[index]


## Called by src/main.gd once the campus is built and the first frame is ready.
func dismiss_loading() -> void:
	if not _starting:
		if _screen_loading:
			_screen_loading.visible = false
		return
	if _loading_tween and _loading_tween.is_valid():
		_loading_tween.kill()
	_loading_tween = create_tween()
	_loading_tween.tween_property(_screen_loading, "modulate:a", 0.0, 0.35)
	_loading_tween.tween_callback(func() -> void:
		_loading_stop_loops()
		_screen_loading.visible = false
		_root.visible = false
		_starting = false)


# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
	if _root == null or not _root.visible:
		return
	if _current == "intro" and event.is_action_pressed("ui_cancel"):
		_skip_intro()
		get_viewport().set_input_as_handled()
		return
	if _current == "loading":
		if event.is_action_pressed("ui_accept") and _loading_bar.value >= 100.0:
			loading_go.emit()
		return
	if event.is_action_pressed("ui_cancel"):
		_back()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _root == null or not _root.visible:
		return
	if not event.is_action_pressed("ui_accept"):
		return
	match _current:
		"year":
			show_character()
		"char":
			_choose(character)
		"name":
			_submit_name()
		"welcome":
			show_main()
		"main":
			show_levels()
		"levels":
			var first: Button = _level_cards[0] if not _level_cards.is_empty() else null
			if first:
				first.emit_signal("pressed")


func _back() -> void:
	match _current:
		"settings":
			hide_settings()
		"char":
			show_year()
		"name":
			show_character()
		"welcome":
			show_main()
		"levels":
			show_main()
