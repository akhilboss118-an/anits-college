class_name MinigameOverlay
extends CanvasLayer
## Interactive Minigame Overlay for ANITS College Simulation.
## Powers:
##   - Basketball Shootout (mouse/touch aimed shot with a real gravity arc)
##   - Parade Drill & Fest Dance (QTE arrow commands with countdown timer)
##   - Samosa Speed-Eating Challenge (rapid button mash with progress bar)
##   - Library & First Class Quizzes (4-option multiple choice cards)

signal minigame_completed(won: bool)

const COURT_SCRIPT := preload("res://src/ui/basketball_court.gd")

var is_active: bool = false
var _config: Dictionary = {}
var _callback: Callable = Callable()

var _panel: PanelContainer
var _title_lbl: Label
var _sub_lbl: Label
var _content_box: VBoxContainer
var _hint_lbl: Label
var _result_box: VBoxContainer
var _result_lbl: Label
var _retry_btn: Button

# Sub-game state
var _kind: String = ""
var _timer: float = 0.0
var _time_limit: float = 0.0
var _anim_time: float = 0.0

# shoot (mouse/touch aimed basketball)
var _shoot_count: int = 0
var _shoot_hits: int = 0
var _shoot_shots_total: int = 5
var _shoot_need: int = 3
var _shoot_clock: float = 7.0
var _shoot_clock_max: float = 7.0
var _shoot_reset_delay: float = 0.8
var _shoot_dots: Array[ColorRect] = []
var _shoot_busy: bool = false
var _shoot_view: BasketballCourt
var _shoot_throw_btn: Button
var _shoot_score_lbl: Label
var _shoot_clock_lbl: Label
var _shoot_reset_token: int = 0
var _shoot_last_tick: int = -1

# cmd (QTE)
var _cmd_seq: Array = []
var _cmd_idx: int = 0
var _cmd_ok: int = 0
var _cmd_need: int = 6
var _cmd_time_per: float = 1.7
var _cmd_time_left: float = 1.7
var _cmd_symbol_lbl: Label
var _cmd_name_lbl: Label
var _cmd_bar: ProgressBar
var _cmd_dots: Array[ColorRect] = []

# mash
var _mash_count: int = 0
var _mash_needed: int = 25
var _mash_secs: float = 8.0
var _mash_started: bool = false
var _mash_lbl: Label
var _mash_bar: ProgressBar

# quiz
var _quiz_qs: Array = []
var _quiz_idx: int = 0
var _quiz_ok: int = 0
var _quiz_need: int = 2
var _quiz_opt_btns: Array[Button] = []
var _quiz_q_lbl: Label

# typing (Samosa Speed-Eating)
var _type_words: Array = []
var _type_idx: int = 0
var _type_eaten: int = 0
var _type_need: int = 5
var _type_current_word: String = ""
var _type_input: String = ""
var _type_time_per: float = 6.5
var _type_time_left: float = 6.5
var _type_word_lbl: RichTextLabel
var _type_platter_lbl: Label
var _type_bar: ProgressBar
var _type_keys_box: HBoxContainer

# drill (NCC Parade Running Challenge)
var _drill_dist: float = 0.0
var _drill_target: float = 100.0
var _drill_cadence_step: int = 0
var _drill_time_left: float = 25.0
var _drill_cadence_score: float = 0.0
var _drill_salute_cue: bool = false
var _drill_cadence_lbl: Label
var _drill_dist_bar: ProgressBar

# dance (Fest Dance Battle)
var _dance_hype: float = 25.0
var _dance_target_hype: float = 80.0
var _dance_time_left: float = 22.0
var _dance_target_move: int = 0
var _dance_timer: float = 0.0
var _dance_hype_bar: ProgressBar
var _dance_prompt_lbl: Label
var _dance_status_lbl: Label


func _init() -> void:
	layer = 25
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

	# Dark frosted glass backdrop
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.04, 0.10, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(560, 360)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.12, 0.26, 0.96)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color("#3aa0ff")
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_left = 18
	sb.corner_radius_bottom_right = 18
	sb.shadow_color = Color(0.15, 0.55, 1.0, 0.35)
	sb.shadow_size = 32
	_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 20)
	_title_lbl.add_theme_color_override("font_color", Color("#7cc4ff"))
	vbox.add_child(_title_lbl)

	_sub_lbl = Label.new()
	_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sub_lbl.add_theme_font_size_override("font_size", 15)
	_sub_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	vbox.add_child(_sub_lbl)

	_content_box = VBoxContainer.new()
	_content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_box.custom_minimum_size = Vector2(480, 140)
	_content_box.add_theme_constant_override("separation", 12)
	vbox.add_child(_content_box)

	_hint_lbl = Label.new()
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_size_override("font_size", 13)
	_hint_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	vbox.add_child(_hint_lbl)

	# Result box (shown at end)
	_result_box = VBoxContainer.new()
	_result_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_result_box.visible = false
	_result_box.add_theme_constant_override("separation", 14)
	vbox.add_child(_result_box)

	_result_lbl = Label.new()
	_result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_lbl.add_theme_font_size_override("font_size", 24)
	_result_box.add_child(_result_lbl)

	_retry_btn = Button.new()
	_retry_btn.text = "TRY AGAIN"
	_retry_btn.custom_minimum_size = Vector2(160, 44)
	_retry_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = Color("#ffd54a")
	btn_sb.corner_radius_top_left = 22
	btn_sb.corner_radius_top_right = 22
	btn_sb.corner_radius_bottom_left = 22
	btn_sb.corner_radius_bottom_right = 22
	_retry_btn.add_theme_stylebox_override("normal", btn_sb)
	_retry_btn.add_theme_color_override("font_color", Color("#111111"))
	_retry_btn.add_theme_font_size_override("font_size", 16)
	_retry_btn.pressed.connect(_on_retry)
	_result_box.add_child(_retry_btn)


func start_minigame(cfg: Dictionary, on_finish: Callable = Callable()) -> void:
	_config = cfg
	_callback = on_finish
	_kind = str(cfg.get("kind", ""))
	_title_lbl.text = str(cfg.get("title", "CHALLENGE")).to_upper()
	is_active = true
	visible = true
	_result_box.visible = false
	_content_box.visible = true
	_clear_content()
	var big := _kind == "shoot"
	_panel.custom_minimum_size = Vector2(700, 610) if big else Vector2(560, 360)
	_content_box.custom_minimum_size = Vector2(640, 430) if big else Vector2(480, 140)

	match _kind:
		"shoot":
			_start_shoot()
		"cmd":
			_start_cmd()
		"mash":
			_start_mash()
		"typing":
			_start_typing()
		"drill":
			_start_drill()
		"dance":
			_start_dance()
		"quiz":
			_start_quiz()


func _clear_content() -> void:
	for child in _content_box.get_children():
		child.queue_free()


func _process(delta: float) -> void:
	if not is_active:
		return
	_anim_time += delta

	match _kind:
		"shoot":
			if _shoot_view != null and not _shoot_busy and not _result_box.visible:
				if _shoot_clock > 0.0:
					_shoot_clock -= delta
					if _shoot_clock <= 3.0:
						var sec := int(ceil(_shoot_clock))
						if sec != _shoot_last_tick:
							_shoot_last_tick = sec
							_play_ui_sfx("tick", -15.0)
					if _shoot_clock <= 0.0:
						_shoot_clock = 0.0
						_register_shot(false)
					elif _shoot_clock_lbl != null:
						_shoot_clock_lbl.text = "SHOT CLOCK  %.1fs" % _shoot_clock
		"cmd":
			if _cmd_time_left > 0.0 and _cmd_idx < _cmd_seq.size():
				_cmd_time_left -= delta
				if _cmd_bar:
					_cmd_bar.value = maxf(0.0, _cmd_time_left / _cmd_time_per * 100.0)
				if _cmd_time_left <= 0.0:
					_on_cmd_timeout()
		"mash":
			if _mash_started and _mash_secs > 0.0:
				_mash_secs -= delta
				if _mash_secs <= 0.0:
					_mash_secs = 0.0
					_finish_mash()
				_hint_lbl.text = "%.1fs remaining | TAP SPACE FAST!" % _mash_secs
		"typing":
			if _type_time_left > 0.0:
				_type_time_left -= delta
				if _type_bar:
					_type_bar.value = maxf(0.0, _type_time_left / _type_time_per * 100.0)
				if _type_time_left <= 0.0:
					_on_typing_timeout()
		"drill":
			if _drill_time_left > 0.0:
				_drill_time_left -= delta
				_hint_lbl.text = "Drill Time: %.1fs left | Run to the 100m mark!" % _drill_time_left
				if _drill_time_left <= 0.0:
					_end_game(_drill_dist >= _drill_target)
		"dance":
			if _dance_time_left > 0.0:
				_dance_time_left -= delta
				_dance_timer += delta
				if _dance_timer >= 2.0:
					_dance_timer = 0.0
					_next_dance_move()
				_dance_hype = maxf(0.0, _dance_hype - delta * 2.2)
				if _dance_hype_bar:
					_dance_hype_bar.value = _dance_hype
				_hint_lbl.text = "Dance Battle: %.1fs left | Target: 80%% Hype!" % _dance_time_left
				if _dance_hype >= _dance_target_hype:
					_end_game(true)
				elif _dance_time_left <= 0.0:
					_end_game(_dance_hype >= _dance_target_hype)


func _unhandled_input(event: InputEvent) -> void:
	if not is_active or _result_box.visible:
		if _result_box.visible and event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
				_on_retry()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match _kind:
			"shoot":
				if _shoot_view == null:
					return
				match event.keycode:
					KEY_LEFT, KEY_A:
						_shoot_view.set_aim(_shoot_view.aim + Vector2(-10.0, 0.0))
					KEY_RIGHT, KEY_D:
						_shoot_view.set_aim(_shoot_view.aim + Vector2(10.0, 0.0))
					KEY_UP, KEY_W:
						_shoot_view.set_aim(_shoot_view.aim + Vector2(0.0, -10.0))
					KEY_DOWN, KEY_S:
						_shoot_view.set_aim(_shoot_view.aim + Vector2(0.0, 10.0))
					KEY_SPACE, KEY_ENTER:
						_shoot_throw()
			"cmd":
				var k := ""
				match event.keycode:
					KEY_UP, KEY_W: k = "ArrowUp"
					KEY_DOWN, KEY_S: k = "ArrowDown"
					KEY_LEFT, KEY_A: k = "ArrowLeft"
					KEY_RIGHT, KEY_D: k = "ArrowRight"
				if k != "":
					_handle_cmd_key(k)
			"mash":
				if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
					_mash_hit()
			"typing":
				if event.unicode > 0:
					var char_typed := String.chr(event.unicode).to_upper()
					if char_typed >= "A" and char_typed <= "Z":
						_handle_type_char(char_typed)
			"drill":
				match event.keycode:
					KEY_A, KEY_LEFT: _step_foot(0)
					KEY_D, KEY_RIGHT: _step_foot(1)
					KEY_G:
						if _drill_salute_cue:
							_drill_salute()
			"dance":
				match event.keycode:
					KEY_A, KEY_LEFT: _hit_dance_move(0)
					KEY_W, KEY_UP: _hit_dance_move(1)
					KEY_S, KEY_DOWN: _hit_dance_move(2)
					KEY_D, KEY_RIGHT: _hit_dance_move(3)
			"quiz":
				match event.keycode:
					KEY_1: _pick_quiz_opt(0)
					KEY_2: _pick_quiz_opt(1)
					KEY_3: _pick_quiz_opt(2)
					KEY_4: _pick_quiz_opt(3)


# ------------------------------------------------------------------ SHOOT (Basketball)

func _start_shoot() -> void:
	_shoot_count = 0
	_shoot_hits = 0
	_shoot_shots_total = int(_config.get("shots", 5))
	_shoot_need = int(_config.get("need", 3))
	_shoot_clock_max = maxf(3.0, float(_config.get("clock", 7.0)))
	_shoot_clock = _shoot_clock_max
	_shoot_reset_delay = maxf(0.0, float(_config.get("reset_delay", 0.8)))
	_shoot_busy = false
	_shoot_reset_token += 1
	_shoot_last_tick = -1
	_anim_time = 0.0
	_shoot_dots.clear()

	_sub_lbl.text = "Aim with the mouse (or drag on touch) and press THROW.\nScore %d of %d shots before the shot clock runs out!" % [_shoot_need, _shoot_shots_total]
	_hint_lbl.text = "Mouse / drag = aim  •  Click court or THROW = shoot  •  Arrows + SPACE = keyboard"

	_shoot_view = COURT_SCRIPT.new()
	_shoot_view.name = "BasketballCourt"
	_shoot_view.shot_resolved.connect(_on_shot_resolved)
	_shoot_view.throw_requested.connect(_shoot_throw)
	_content_box.add_child(_shoot_view)
	# Start slightly off the sweet spot so the first shot still needs an aim.
	_shoot_view.set_aim(_shoot_view.RIM_CENTER - Vector2(58.0, 20.0))

	var hud_row := HBoxContainer.new()
	hud_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hud_row.add_theme_constant_override("separation", 24)
	_content_box.add_child(hud_row)

	_shoot_score_lbl = Label.new()
	_shoot_score_lbl.add_theme_font_size_override("font_size", 17)
	_shoot_score_lbl.add_theme_color_override("font_color", Color("#ffd54a"))
	_shoot_score_lbl.text = "HITS  0 / %d  •  NEED %d" % [_shoot_shots_total, _shoot_need]
	hud_row.add_child(_shoot_score_lbl)

	_shoot_clock_lbl = Label.new()
	_shoot_clock_lbl.add_theme_font_size_override("font_size", 17)
	_shoot_clock_lbl.add_theme_color_override("font_color", Color("#7cc4ff"))
	_shoot_clock_lbl.text = "SHOT CLOCK  %.1fs" % _shoot_clock
	hud_row.add_child(_shoot_clock_lbl)

	# Dot indicators row
	var dot_row := HBoxContainer.new()
	dot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dot_row.add_theme_constant_override("separation", 10)
	_content_box.add_child(dot_row)

	for i in _shoot_shots_total:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(18, 18)
		dot.color = Color("#16305c")
		dot_row.add_child(dot)
		_shoot_dots.append(dot)

	# The big throw button: mouse, touch and keyboard all release here.
	_shoot_throw_btn = Button.new()
	_shoot_throw_btn.text = "THROW  (click / SPACE)"
	_shoot_throw_btn.custom_minimum_size = Vector2(280, 54)
	_shoot_throw_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var throw_sb := StyleBoxFlat.new()
	throw_sb.bg_color = Color("#e8792f")
	throw_sb.corner_radius_top_left = 27
	throw_sb.corner_radius_top_right = 27
	throw_sb.corner_radius_bottom_left = 27
	throw_sb.corner_radius_bottom_right = 27
	throw_sb.border_width_left = 2
	throw_sb.border_width_top = 2
	throw_sb.border_width_right = 2
	throw_sb.border_width_bottom = 2
	throw_sb.border_color = Color("#ffd54a")
	_shoot_throw_btn.add_theme_stylebox_override("normal", throw_sb)
	var hover_sb := throw_sb.duplicate() as StyleBoxFlat
	hover_sb.bg_color = Color("#ff9a45")
	_shoot_throw_btn.add_theme_stylebox_override("hover", hover_sb)
	_shoot_throw_btn.add_theme_stylebox_override("pressed", hover_sb)
	_shoot_throw_btn.add_theme_color_override("font_color", Color("#1a1208"))
	_shoot_throw_btn.add_theme_font_size_override("font_size", 20)
	_shoot_throw_btn.pressed.connect(_shoot_throw)
	_content_box.add_child(_shoot_throw_btn)


func _shoot_throw() -> void:
	if not is_active or _shoot_busy or _result_box.visible or _shoot_view == null:
		return
	if not _shoot_view.throw_ball():
		return
	_shoot_busy = true
	_shoot_clock = _shoot_clock_max
	_shoot_throw_btn.disabled = true
	_hint_lbl.text = "Ball in the air..."


func _on_shot_resolved(hit: bool) -> void:
	if not is_active:
		return
	_register_shot(hit)


func _register_shot(hit: bool) -> void:
	_shoot_busy = true
	_shoot_count += 1
	if hit:
		_shoot_hits += 1
	var idx := _shoot_count - 1
	if idx >= 0 and idx < _shoot_dots.size():
		_shoot_dots[idx].color = Color("#3ce678") if hit else Color("#ff4d5a")
	if _shoot_score_lbl != null:
		_shoot_score_lbl.text = "HITS  %d / %d  •  NEED %d" % [_shoot_hits, _shoot_shots_total, _shoot_need]
	if _shoot_clock_lbl != null:
		_shoot_clock_lbl.text = "SHOT CLOCK  %.1fs" % _shoot_clock

	if _shoot_count >= _shoot_shots_total:
		if _shoot_throw_btn != null:
			_shoot_throw_btn.disabled = true
		_end_game(_shoot_hits >= _shoot_need)
		return

	var token := _shoot_reset_token
	_hint_lbl.text = "Nice shot! Get ready for the next one." if hit else "Not enough - line up the next shot."
	if _shoot_reset_delay > 0.0:
		await get_tree().create_timer(_shoot_reset_delay).timeout
		if not is_active or token != _shoot_reset_token or _result_box.visible:
			return
	_reset_after_shot()


func _reset_after_shot() -> void:
	if _shoot_view != null:
		_shoot_view.reset_ball()
	_shoot_clock = _shoot_clock_max
	_shoot_last_tick = -1
	if _shoot_clock_lbl != null:
		_shoot_clock_lbl.text = "SHOT CLOCK  %.1fs" % _shoot_clock
	if _shoot_throw_btn != null:
		_shoot_throw_btn.disabled = false
	_hint_lbl.text = "Mouse / drag = aim  •  Click court or THROW = shoot  •  Arrows + SPACE = keyboard"
	_shoot_busy = false


# ------------------------------------------------------------------ CMD (QTE Parade/Dance)

func _start_cmd() -> void:
	var n: int = int(_config.get("n", 8))
	_cmd_need = int(_config.get("need", 6))
	_cmd_time_per = float(_config.get("time", 1.7))
	_cmd_idx = 0
	_cmd_ok = 0

	var keys: Array = _config.get("keys", ["ArrowUp", "ArrowLeft", "ArrowRight"])
	_cmd_seq.clear()
	for i in n:
		_cmd_seq.append(keys[randi() % keys.size()])

	_sub_lbl.text = "Press the arrow key (or WASD / button) that is called.\nGet %d of %d correct!" % [_cmd_need, n]
	_hint_lbl.text = "Arrow keys / WASD / On-screen buttons"

	_cmd_symbol_lbl = Label.new()
	_cmd_symbol_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cmd_symbol_lbl.add_theme_font_size_override("font_size", 54)
	_cmd_symbol_lbl.add_theme_color_override("font_color", Color("#ffd54a"))
	_content_box.add_child(_cmd_symbol_lbl)

	_cmd_name_lbl = Label.new()
	_cmd_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cmd_name_lbl.add_theme_font_size_override("font_size", 18)
	_content_box.add_child(_cmd_name_lbl)

	_cmd_bar = ProgressBar.new()
	_cmd_bar.custom_minimum_size = Vector2(360, 14)
	_cmd_bar.show_percentage = false
	_cmd_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_content_box.add_child(_cmd_bar)

	# Touch D-pad row
	var dpad := HBoxContainer.new()
	dpad.alignment = BoxContainer.ALIGNMENT_CENTER
	dpad.add_theme_constant_override("separation", 12)
	_content_box.add_child(dpad)

	var dir_keys: Array[String] = ["ArrowLeft", "ArrowUp", "ArrowDown", "ArrowRight"]
	var dir_symbols: Array[String] = ["←", "↑", "↓", "→"]
	for i in dir_keys.size():
		var btn := Button.new()
		btn.text = dir_symbols[i]
		btn.custom_minimum_size = Vector2(48, 40)
		var k: String = dir_keys[i]
		btn.pressed.connect(func(): _handle_cmd_key(k))
		dpad.add_child(btn)

	_show_cmd_step()


func _show_cmd_step() -> void:
	if _cmd_idx >= _cmd_seq.size():
		_end_game(_cmd_ok >= _cmd_need)
		return

	var current_key: String = _cmd_seq[_cmd_idx]
	var names: Dictionary = _config.get("names", {})
	var entry: Array = names.get(current_key, [current_key, current_key])
	_cmd_symbol_lbl.text = str(entry[0])
	_cmd_name_lbl.text = str(entry[1])
	_cmd_time_left = _cmd_time_per


func _handle_cmd_key(key: String) -> void:
	if not is_active or _cmd_idx >= _cmd_seq.size():
		return

	if key == _cmd_seq[_cmd_idx]:
		_cmd_ok += 1
	_cmd_idx += 1
	_show_cmd_step()


func _on_cmd_timeout() -> void:
	_cmd_idx += 1
	_show_cmd_step()


# ------------------------------------------------------------------ MASH (Samosa eating)

func _start_mash() -> void:
	_mash_count = 0
	_mash_needed = int(_config.get("hits", 25))
	_mash_secs = float(_config.get("secs", 8.0))
	_mash_started = false

	_sub_lbl.text = "Tap SPACE or tap the button %d times in %d seconds!\nTimer starts on your first tap." % [_mash_needed, int(_mash_secs)]
	_hint_lbl.text = "SPACE = Tap fast!"

	_mash_lbl = Label.new()
	_mash_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mash_lbl.add_theme_font_size_override("font_size", 42)
	_mash_lbl.add_theme_color_override("font_color", Color("#ffd54a"))
	_mash_lbl.text = "0 / %d" % _mash_needed
	_content_box.add_child(_mash_lbl)

	_mash_bar = ProgressBar.new()
	_mash_bar.custom_minimum_size = Vector2(400, 24)
	_mash_bar.show_percentage = false
	_mash_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_content_box.add_child(_mash_bar)

	var tap_btn := Button.new()
	tap_btn.text = "TAP! TAP! TAP!"
	tap_btn.custom_minimum_size = Vector2(220, 50)
	tap_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tap_btn.pressed.connect(_mash_hit)
	_content_box.add_child(tap_btn)


func _mash_hit() -> void:
	if not is_active or _mash_secs <= 0.0:
		return
	if not _mash_started:
		_mash_started = true

	_mash_count += 1
	_mash_lbl.text = "%d / %d" % [_mash_count, _mash_needed]
	_mash_bar.value = minf(100.0, float(_mash_count) / float(_mash_needed) * 100.0)

	if _mash_count >= _mash_needed:
		_finish_mash()


func _finish_mash() -> void:
	_end_game(_mash_count >= _mash_needed)


# ------------------------------------------------------------------ QUIZ

func _start_quiz() -> void:
	_quiz_qs = _config.get("qs", [])
	_quiz_idx = 0
	_quiz_ok = 0
	_quiz_need = int(_config.get("need", 2))
	_quiz_opt_btns.clear()

	_sub_lbl.text = "Answer %d of %d questions correctly to pass." % [_quiz_need, _quiz_qs.size()]
	_hint_lbl.text = "Click an option or press keys 1 - 4"

	_quiz_q_lbl = Label.new()
	_quiz_q_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quiz_q_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quiz_q_lbl.add_theme_font_size_override("font_size", 18)
	_quiz_q_lbl.add_theme_color_override("font_color", Color.WHITE)
	_content_box.add_child(_quiz_q_lbl)

	for i in 4:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(440, 36)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var opt_idx := i
		btn.pressed.connect(func(): _pick_quiz_opt(opt_idx))
		_content_box.add_child(btn)
		_quiz_opt_btns.append(btn)

	_show_quiz_question()


func _show_quiz_question() -> void:
	if _quiz_idx >= _quiz_qs.size():
		_end_game(_quiz_ok >= _quiz_need)
		return

	var q_data: Array = _quiz_qs[_quiz_idx]
	_title_lbl.text = "%s (%d / %d)" % [str(_config.get("title", "QUIZ")), _quiz_idx + 1, _quiz_qs.size()]
	_quiz_q_lbl.text = str(q_data[0])

	var opts: Array = q_data[1]
	for i in _quiz_opt_btns.size():
		if i < opts.size():
			_quiz_opt_btns[i].visible = true
			_quiz_opt_btns[i].text = "  %d. %s" % [i + 1, str(opts[i])]
		else:
			_quiz_opt_btns[i].visible = false


func _pick_quiz_opt(index: int) -> void:
	if not is_active or _quiz_idx >= _quiz_qs.size():
		return

	var q_data: Array = _quiz_qs[_quiz_idx]
	var correct: int = int(q_data[2])
	if index == correct:
		_quiz_ok += 1
	_play_sfx("success" if index == correct else "error", -14.0)

	_quiz_idx += 1
	_show_quiz_question()


# ------------------------------------------------------------------ RESULTS

func _end_game(won: bool) -> void:
	_content_box.visible = false
	_result_box.visible = true
	_play_sfx("success" if won else "error", -8.0)

	if won:
		_result_lbl.text = "MISSION COMPLETE!"
		_result_lbl.add_theme_color_override("font_color", Color("#6dff9f"))
		_retry_btn.visible = false
		_hint_lbl.text = ""
		var timer := get_tree().create_timer(1.2)
		await timer.timeout
		_close(true)
	else:
		_result_lbl.text = "NOT ENOUGH, TRY AGAIN!"
		_result_lbl.add_theme_color_override("font_color", Color("#ff7a85"))
		_retry_btn.visible = true
		_hint_lbl.text = "Press ENTER or click TRY AGAIN"


func _on_retry() -> void:
	_play_ui_sfx("ui_click", -12.0)
	_result_box.visible = false
	_content_box.visible = true
	_clear_content()
	_shoot_view = null
	match _kind:
		"shoot": _start_shoot()
		"cmd": _start_cmd()
		"mash": _start_mash()
		"typing": _start_typing()
		"drill": _start_drill()
		"dance": _start_dance()
		"quiz": _start_quiz()


# ------------------------------------------------------------------ TYPING (Samosa Speed-Eating)

func _start_typing() -> void:
	_type_words = _config.get("words", ["SAMOSA", "CHAI", "CRISPY", "MIRCHI", "CHUTNEY", "ANITS"])
	_type_idx = 0
	_type_eaten = 0
	_type_need = int(_config.get("need", 5))
	_type_time_per = float(_config.get("time_per_word", 6.5))

	_sub_lbl.text = "Type each canteen food word on your keyboard to eat!\nFinish %d samosas before time runs out!" % _type_need
	_hint_lbl.text = "Type letters on keyboard or tap letter buttons below"

	# Samosa Platter display
	_type_platter_lbl = Label.new()
	_type_platter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_platter_lbl.add_theme_font_size_override("font_size", 28)
	_type_platter_lbl.add_theme_color_override("font_color", Color("#ffd54a"))
	_content_box.add_child(_type_platter_lbl)

	# Word display with BBCode formatting
	_type_word_lbl = RichTextLabel.new()
	_type_word_lbl.bbcode_enabled = true
	_type_word_lbl.fit_content = true
	_type_word_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_type_word_lbl.custom_minimum_size = Vector2(400, 52)
	_type_word_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_content_box.add_child(_type_word_lbl)

	_type_bar = ProgressBar.new()
	_type_bar.custom_minimum_size = Vector2(400, 16)
	_type_bar.show_percentage = false
	_type_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_content_box.add_child(_type_bar)

	# Touch keypad row
	_type_keys_box = HBoxContainer.new()
	_type_keys_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_type_keys_box.add_theme_constant_override("separation", 6)
	_content_box.add_child(_type_keys_box)

	_show_typing_word()


func _show_typing_word() -> void:
	if _type_eaten >= _type_need or _type_idx >= _type_words.size():
		_end_game(_type_eaten >= _type_need)
		return

	_type_current_word = str(_type_words[_type_idx]).to_upper()
	_type_input = ""
	_type_time_left = _type_time_per

	# Update Samosa platter string
	var platter := "Canteen Plate: "
	for i in _type_need:
		if i < _type_eaten:
			platter += "🍽️ "
		else:
			platter += "🥟 "
	_type_platter_lbl.text = platter

	_update_typing_display()
	_rebuild_typing_keypad()


func _update_typing_display() -> void:
	if _type_word_lbl == null:
		return
	var typed_part := _type_input
	var remaining_part := _type_current_word.substr(_type_input.length())
	_type_word_lbl.text = "[center][font_size=36][color=#4cd964][b]%s[/b][/color][color=#ffffff]%s[/color][/font_size][/center]" % [typed_part, remaining_part]


func _rebuild_typing_keypad() -> void:
	if _type_keys_box == null:
		return
	for c in _type_keys_box.get_children():
		c.queue_free()

	var letters: Array[String] = []
	for i in _type_current_word.length():
		var ch := _type_current_word.substr(i, 1)
		if not letters.has(ch):
			letters.append(ch)
	letters.sort()

	for ch in letters:
		var btn := Button.new()
		btn.text = ch
		btn.custom_minimum_size = Vector2(44, 40)
		var c_val: String = ch
		btn.pressed.connect(func(): _handle_type_char(c_val))
		_type_keys_box.add_child(btn)


func _handle_type_char(c: String) -> void:
	if not is_active or _type_current_word == "":
		return
	var expected_idx := _type_input.length()
	if expected_idx < _type_current_word.length():
		if _type_current_word.substr(expected_idx, 1) == c:
			_type_input += c
			_play_sfx("type", -13.0)
			_update_typing_display()
			if _type_input == _type_current_word:
				_type_eaten += 1
				_type_idx += 1
				_play_sfx("success", -15.0)
				_show_typing_word()


func _on_typing_timeout() -> void:
	_type_idx += 1
	_play_sfx("error", -18.0)
	_show_typing_word()


# ------------------------------------------------------------------ DRILL (NCC Parade Running Challenge)

func _start_drill() -> void:
	_drill_dist = 0.0
	_drill_target = 100.0
	_drill_cadence_step = 0
	_drill_time_left = float(_config.get("time", 25.0))
	_drill_salute_cue = false

	_sub_lbl.text = "Alternate LEFT and RIGHT foot in sharp cadence with the company!\nSprint 100 metres to Colonel Singh's reviewing stand!"
	_hint_lbl.text = "Keys A / D or ← / → or tap LEFT / RIGHT foot buttons"

	_drill_cadence_lbl = Label.new()
	_drill_cadence_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_drill_cadence_lbl.add_theme_font_size_override("font_size", 34)
	_drill_cadence_lbl.add_theme_color_override("font_color", Color("#ffd54a"))
	_drill_cadence_lbl.text = "NEXT: 👟 LEFT FOOT!"
	_content_box.add_child(_drill_cadence_lbl)

	_drill_dist_bar = ProgressBar.new()
	_drill_dist_bar.custom_minimum_size = Vector2(440, 24)
	_drill_dist_bar.max_value = 100.0
	_drill_dist_bar.value = 0.0
	_drill_dist_bar.show_percentage = true
	_drill_dist_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_content_box.add_child(_drill_dist_bar)

	var foot_row := HBoxContainer.new()
	foot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	foot_row.add_theme_constant_override("separation", 24)
	_content_box.add_child(foot_row)

	var left_btn := Button.new()
	left_btn.text = "👟 LEFT (A / ←)"
	left_btn.custom_minimum_size = Vector2(170, 56)
	left_btn.pressed.connect(func(): _step_foot(0))
	foot_row.add_child(left_btn)

	var right_btn := Button.new()
	right_btn.text = "👟 RIGHT (D / →)"
	right_btn.custom_minimum_size = Vector2(170, 56)
	right_btn.pressed.connect(func(): _step_foot(1))
	foot_row.add_child(right_btn)


func _step_foot(which: int) -> void:
	if not is_active:
		return
	if which == _drill_cadence_step:
		_drill_dist += 5.5
		_drill_cadence_step = 1 - _drill_cadence_step
		_play_footstep(true)
		_drill_cadence_lbl.text = "NEXT: " + ("👟 LEFT FOOT!" if _drill_cadence_step == 0 else "👟 RIGHT FOOT!")
		_drill_dist_bar.value = minf(100.0, _drill_dist)
		if _drill_dist >= _drill_target:
			_end_game(true)
	else:
		_play_sfx("error", -18.0)
		_drill_cadence_lbl.text = "⚠️ STUMBLE! Match the march cadence!"


func _drill_salute() -> void:
	_drill_dist += 12.0
	_drill_dist_bar.value = minf(100.0, _drill_dist)
	if _drill_dist >= _drill_target:
		_end_game(true)


# ------------------------------------------------------------------ DANCE (Fest Dance Battle)

func _start_dance() -> void:
	_dance_hype = 30.0
	_dance_target_hype = 80.0
	_dance_time_left = float(_config.get("time", 25.0))
	_dance_timer = 0.0

	_sub_lbl.text = "Hit the dance buttons to keep the rhythm going!\nHype up the ANITS crowd to 80% to win the dance battle!"
	_hint_lbl.text = "Keys W, A, S, D or Arrows or Tap Dance Buttons"

	_dance_prompt_lbl = Label.new()
	_dance_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dance_prompt_lbl.add_theme_font_size_override("font_size", 34)
	_dance_prompt_lbl.add_theme_color_override("font_color", Color("#ffd54a"))
	_content_box.add_child(_dance_prompt_lbl)

	var hype_title := Label.new()
	hype_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hype_title.text = "CROWD HYPE LEVEL (Reach 80%)"
	_content_box.add_child(hype_title)

	_dance_hype_bar = ProgressBar.new()
	_dance_hype_bar.custom_minimum_size = Vector2(440, 24)
	_dance_hype_bar.max_value = 100.0
	_dance_hype_bar.value = _dance_hype
	_dance_hype_bar.show_percentage = true
	_dance_hype_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_content_box.add_child(_dance_hype_bar)

	var dance_grid := GridContainer.new()
	dance_grid.columns = 2
	dance_grid.add_theme_constant_override("h_separation", 16)
	dance_grid.add_theme_constant_override("v_separation", 12)
	dance_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_content_box.add_child(dance_grid)

	var move_defs := [
		["SPIN LEFT (← / A)", 0],
		["JUMP HIGH (↑ / W)", 1],
		["DROP BASS (↓ / S)", 2],
		["SLIDE RIGHT (→ / D)", 3]
	]
	for m in move_defs:
		var btn := Button.new()
		btn.text = m[0]
		btn.custom_minimum_size = Vector2(190, 46)
		var idx: int = m[1]
		btn.pressed.connect(func(): _hit_dance_move(idx))
		dance_grid.add_child(btn)

	_next_dance_move()


func _next_dance_move() -> void:
	var moves := ["SPIN LEFT! (← / A)", "JUMP HIGH! (↑ / W)", "DROP BASS! (↓ / S)", "SLIDE RIGHT! (→ / D)"]
	_dance_target_move = randi() % 4
	if _dance_prompt_lbl:
		_dance_prompt_lbl.text = "BEAT CALL: " + moves[_dance_target_move]


func _hit_dance_move(move_idx: int) -> void:
	if not is_active:
		return
	if move_idx == _dance_target_move:
		_dance_hype = minf(100.0, _dance_hype + 14.0)
		_play_sfx("success", -15.0)
		if _dance_hype_bar:
			_dance_hype_bar.value = _dance_hype
		if _dance_prompt_lbl:
			_dance_prompt_lbl.text = "✨ PERFECT MOVE! HYPE UP! ✨"
		_next_dance_move()
		if _dance_hype >= _dance_target_hype:
			_end_game(true)
	else:
		_dance_hype = maxf(0.0, _dance_hype - 4.0)
		_play_sfx("error", -19.0)
		if _dance_hype_bar:
			_dance_hype_bar.value = _dance_hype


func _close(won: bool) -> void:
	is_active = false
	visible = false
	minigame_completed.emit(won)
	if _callback.is_valid():
		_callback.call(won)


# ------------------------------------------------------------------ audio

## Null-safe wrappers: the headless test runner compiles this script before the
## autoload globals exist, so never reference the `Audio` singleton directly.
func _play_sfx(id: String, volume_db: float = -8.0, pitch: float = 1.0) -> void:
	var a: Node = get_node_or_null("/root/Audio")
	if a:
		a.play(id, volume_db, pitch)


func _play_ui_sfx(id: String, volume_db: float = -14.0) -> void:
	var a: Node = get_node_or_null("/root/Audio")
	if a:
		a.play_ui(id, volume_db)


func _play_footstep(running: bool) -> void:
	var a: Node = get_node_or_null("/root/Audio")
	if a:
		a.footstep(running)
