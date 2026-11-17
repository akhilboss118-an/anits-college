class_name BasketballCourt
extends Control
## The playable half of the basketball shootout: a drawn court, a hoop and a
## real projectile.  The player aims with the mouse (or a finger) and throws
## with the THROW button; the ball follows a gravity arc, can hit the rim or
## the backboard and only counts when it drops through the hoop.
##
## The view is resolution independent: everything is drawn in a 600 x 330
## design space and scaled to the Control's real size.

signal shot_resolved(hit: bool)
signal throw_requested

const DESIGN := Vector2(600.0, 330.0)
const BALL_START := Vector2(96.0, 262.0)
const BALL_RADIUS := 10.0
const RIM_CENTER := Vector2(452.0, 150.0)
const RIM_HALF := 34.0
const RIM_Y := 150.0
const BOARD_X := 488.0
const BOARD_TOP := 64.0
const BOARD_BOTTOM := 176.0
const FLOOR_Y := 318.0
const GRAVITY := 1250.0
const AIM_MARGIN := 24.0

var aim: Vector2 = Vector2(388.0, 168.0)
var ball_pos: Vector2 = BALL_START
var flying: bool = false
var scored: bool = false
var last_result: String = ""
var shots_taken: int = 0
var shots_hit: int = 0

var _velocity := Vector2.ZERO
var _flight_time: float = 0.0
var _result_time: float = 0.0
var _awaiting_result: bool = false
var _rim_hit: bool = false
var _board_hit: bool = false
var _trail: Array[Vector2] = []
var _spin: float = 0.0
var _pulse: float = 0.0
var _flash: float = 0.0
var _throw_origin := BALL_START
var _scale: float = 1.0
var _offset := Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = DESIGN
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	focus_mode = Control.FOCUS_NONE
	set_process(true)
	reset_ball()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_transform()
		queue_redraw()


func _update_transform() -> void:
	_scale = minf(size.x / DESIGN.x, size.y / DESIGN.y)
	if _scale <= 0.0:
		_scale = 1.0
	_offset = (size - DESIGN * _scale) * 0.5


func _to_design(local: Vector2) -> Vector2:
	if _scale <= 0.0:
		_update_transform()
	return (local - _offset) / _scale


# ------------------------------------------------------------------ public API

func reset_ball() -> void:
	ball_pos = BALL_START
	_throw_origin = BALL_START
	flying = false
	scored = false
	last_result = ""
	_velocity = Vector2.ZERO
	_flight_time = 0.0
	_result_time = 0.0
	_awaiting_result = false
	_rim_hit = false
	_board_hit = false
	_trail.clear()
	queue_redraw()


func set_aim(point: Vector2) -> void:
	aim = Vector2(
		clampf(point.x, AIM_MARGIN, DESIGN.x - AIM_MARGIN),
		clampf(point.y, AIM_MARGIN, DESIGN.y - AIM_MARGIN))
	queue_redraw()


func aim_at_rim() -> void:
	set_aim(RIM_CENTER)


## Returns false while a ball is still in the air (or after the shot resolved).
func throw_ball() -> bool:
	if flying or _awaiting_result:
		return false
	shots_taken += 1
	_throw_origin = BALL_START
	ball_pos = BALL_START
	_trail.clear()
	scored = false
	last_result = ""
	_rim_hit = false
	_board_hit = false
	_flight_time = 0.0
	_result_time = 0.0
	_flash = 0.0
	flying = true
	_play_sfx("throw", -10.0)

	# A fixed flight time per distance keeps every shot readable: the ball
	# always arcs high and comes down onto the aim point, exactly like a real
	# jump shot instead of a flat line drive.
	var dist := BALL_START.distance_to(aim)
	var flight := clampf(dist / 430.0, 0.62, 1.05)
	_velocity = (aim - BALL_START) / flight
	_velocity.y -= 0.5 * GRAVITY * flight
	queue_redraw()
	return true


# ------------------------------------------------------------------ simulation

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_pulse += delta
	_flash = maxf(0.0, _flash - delta * 2.4)

	if flying:
		# Sub-step so a fast ball cannot tunnel through the rim or the board.
		var steps := 5
		var dt := delta / float(steps)
		for i in steps:
			if not flying:
				break
			_step_ball(dt)

	if _awaiting_result:
		# The result delay runs even while the scored ball is still dropping
		# through the net, so a swish is never held up by the floor bounce.
		_result_time -= delta
		if _result_time <= 0.0:
			_finish_shot()
	elif not flying:
		# Idle: only the slow ball bob and the reticle pulse animate.
		ball_pos = BALL_START + Vector2(0.0, sin(_pulse * 2.2) * 1.5)
	queue_redraw()


func _step_ball(delta: float) -> void:
	var prev := ball_pos
	_flight_time += delta
	ball_pos += _velocity * delta
	_velocity.y += GRAVITY * delta
	_spin += delta * 9.0

	_trail.append(ball_pos)
	if _trail.size() > 14:
		_trail.pop_front()

	# Backboard: a solid vertical plane behind the rim.  Hitting it kills the
	# forward speed and drops the ball back toward the court.
	if not _board_hit and _velocity.x > 0.0 \
			and prev.x + BALL_RADIUS < BOARD_X and ball_pos.x + BALL_RADIUS >= BOARD_X \
			and ball_pos.y > BOARD_TOP - BALL_RADIUS and ball_pos.y < BOARD_BOTTOM + BALL_RADIUS:
		ball_pos.x = BOARD_X - BALL_RADIUS
		_velocity.x = -absf(_velocity.x) * 0.42
		_velocity.y *= 0.72
		_board_hit = true
		_flash = 1.0
		_play_sfx("ball_bounce", -10.0, 0.88)

	# The two rim ends are solid circles.  A ball that clips one bounces away.
	for side in [-1.0, 1.0]:
		var rim_end := Vector2(RIM_CENTER.x + float(side) * RIM_HALF, RIM_Y)
		var offset := ball_pos - rim_end
		var min_dist := BALL_RADIUS + 3.5
		if offset.length() < min_dist:
			var normal := offset.normalized() if offset.length() > 0.01 else Vector2.UP
			ball_pos = rim_end + normal * min_dist
			_velocity = _velocity.bounce(normal) * 0.48
			if not _rim_hit:
				_play_sfx("rim", -8.0)
			_rim_hit = true
			_flash = 1.0

	# Score: the centre of the ball crosses the rim plane moving downward,
	# inside the opening.  This is checked before the floor so a swish is never
	# counted as a miss.
	if not scored and _velocity.y > 0.0 and prev.y < RIM_Y and ball_pos.y >= RIM_Y:
		var inner := RIM_HALF - BALL_RADIUS * 0.55
		if absf(ball_pos.x - RIM_CENTER.x) < inner:
			scored = true
			last_result = "SWISH!"
			_play_sfx("success", -9.0)
			_awaiting_result = true
			_result_time = 0.42
			_velocity.x *= 0.35
			_velocity.y = maxf(_velocity.y, 260.0)
			return

	if ball_pos.y > FLOOR_Y:
		ball_pos.y = FLOOR_Y
		_play_sfx("ball_bounce", -10.0, 0.95)
		if scored:
			_awaiting_result = true
			_result_time = minf(_result_time, 0.12)
		else:
			last_result = "RIM OUT!" if _rim_hit else ("OFF THE BOARD!" if _board_hit else "MISS!")
			_awaiting_result = true
			_result_time = 0.30
		flying = false
		return

	if ball_pos.x > DESIGN.x + 80.0 or ball_pos.x < -80.0 or ball_pos.y < -160.0 \
			or _flight_time > 2.4:
		if not scored:
			last_result = "RIM OUT!" if _rim_hit else "MISS!"
			_awaiting_result = true
			_result_time = 0.24
		flying = false


func _finish_shot() -> void:
	_awaiting_result = false
	flying = false
	if scored:
		shots_hit += 1
	shot_resolved.emit(scored)


## Null-safe: the headless test runner compiles this script before the autoload
## globals exist, so never reference the `Audio` singleton directly.
func _play_sfx(id: String, volume_db: float = -8.0, pitch: float = 1.0) -> void:
	var a: Node = get_node_or_null("/root/Audio")
	if a:
		a.play(id, volume_db, pitch)


# ------------------------------------------------------------------ input

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		set_aim(_to_design((event as InputEventMouseMotion).position))
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			set_aim(_to_design(mb.position))
			throw_requested.emit()
	elif event is InputEventScreenDrag:
		set_aim(_to_design((event as InputEventScreenDrag).position))
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			# Touch aims; the big THROW button releases the shot, so a drag
			# never fires by accident.
			set_aim(_to_design(touch.position))
	accept_event()


# ------------------------------------------------------------------ drawing

func _draw() -> void:
	_update_transform()
	draw_set_transform(_offset, 0.0, Vector2(_scale, _scale))
	_draw_arena()
	_draw_court()
	_draw_crowd()
	_draw_hoop()
	_draw_trail()
	_draw_ball(ball_pos, BALL_RADIUS)
	_draw_reticle()
	if last_result != "":
		_draw_result()


func _draw_arena() -> void:
	# Dusk sky: deep blue at the top, warm floodlit horizon behind the hoop.
	var top := Color("#071426")
	var horizon := Color("#c87546")
	var bands := 22
	for i in bands:
		var t := float(i) / float(bands - 1)
		var col := top.lerp(horizon, pow(t, 1.55))
		draw_rect(Rect2(0.0, t * 196.0, DESIGN.x, 196.0 / float(bands) + 1.0), col)

	# Distant campus silhouette and the gym wall.
	draw_rect(Rect2(0.0, 168.0, DESIGN.x, 38.0), Color("#16243a"))
	var blocks := [
		Rect2(18.0, 142.0, 70.0, 32.0),
		Rect2(96.0, 154.0, 54.0, 20.0),
		Rect2(158.0, 134.0, 92.0, 40.0),
		Rect2(262.0, 158.0, 70.0, 16.0),
		Rect2(344.0, 146.0, 58.0, 28.0),
		Rect2(512.0, 136.0, 68.0, 38.0),
	]
	for r in blocks:
		draw_rect(r, Color("#0d1a2d"))
	# A few warm windows in the silhouette.
	var windows := [
		Vector2(34, 152), Vector2(48, 152), Vector2(62, 152), Vector2(34, 164),
		Vector2(176, 146), Vector2(192, 146), Vector2(208, 146), Vector2(224, 146),
		Vector2(176, 160), Vector2(208, 160), Vector2(532, 150), Vector2(550, 150),
	]
	for w in windows:
		draw_rect(Rect2(w.x, w.y, 4.0, 4.0), Color("#ffd27a"))

	# Two floodlight glows.
	for x in [36.0, 564.0]:
		draw_circle(Vector2(x, 54.0), 26.0, Color(1.0, 0.82, 0.52, 0.10))
		draw_circle(Vector2(x, 54.0), 9.0, Color(1.0, 0.94, 0.78, 0.75))
		draw_line(Vector2(x, 54.0), Vector2(x, 172.0), Color("#26354c"), 3.0)


func _draw_court() -> void:
	# Perspective wooden floor.
	var floor_col := Color("#b96a45")
	var floor_dark := Color("#8f4a2f")
	draw_rect(Rect2(0.0, 196.0, DESIGN.x, 134.0), floor_col)
	# Plank seams, closer together toward the horizon.
	for i in range(1, 13):
		var t := float(i) / 12.0
		var y := 196.0 + pow(t, 1.45) * 134.0
		draw_line(Vector2(0.0, y), Vector2(DESIGN.x, y), floor_dark, 1.0)
	# Perspective side lines converging on the hoop.
	for x in [-120.0, 120.0, 300.0, 480.0, 720.0]:
		draw_line(Vector2(x, 196.0), Vector2(300.0 + (x - 300.0) * 1.55, 330.0),
			Color(0.45, 0.20, 0.11, 0.55), 1.0)
	# Free-throw key and the free-throw circle at the top of the key.  The
	# ellipse is the perspective projection of a circle on the floor.
	var key := PackedVector2Array([
		Vector2(250.0, 214.0), Vector2(356.0, 214.0),
		Vector2(390.0, 318.0), Vector2(216.0, 318.0)])
	draw_colored_polygon(key, Color(0.07, 0.18, 0.30, 0.58))
	var key_outline := PackedVector2Array(key)
	key_outline.append(key[0])
	draw_polyline(key_outline, Color(0.96, 0.90, 0.78, 0.8), 2.0)
	var ft_circle := PackedVector2Array()
	for i in 33:
		var a := TAU * float(i) / 32.0
		ft_circle.append(Vector2(300.0 + cos(a) * 58.0, 214.0 + sin(a) * 16.0))
	draw_polyline(ft_circle, Color(0.96, 0.90, 0.78, 0.75), 2.0)
	# Three-point arc around the hoop's floor projection.
	var three := PackedVector2Array()
	for i in 33:
		var a := PI + PI * float(i) / 32.0
		var p := Vector2(452.0 + cos(a) * 230.0, 318.0 + sin(a) * 52.0)
		if p.x >= 0.0 and p.x <= DESIGN.x:
			three.append(p)
	if three.size() > 1:
		draw_polyline(three, Color(0.96, 0.90, 0.78, 0.7), 2.0)
	# Baseline.
	draw_line(Vector2(0.0, 318.0), Vector2(DESIGN.x, 318.0), Color(0.96, 0.90, 0.78, 0.7), 2.0)


func _draw_crowd() -> void:
	# A dark stand with simple spectator silhouettes behind the floor.
	draw_rect(Rect2(0.0, 184.0, DESIGN.x, 16.0), Color("#101d30"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 54:
		var x := 6.0 + float(i) * 11.0
		var h := 5.0 + rng.randf() * 4.0
		var y := 184.0 - h * 0.35
		var tint := Color(0.16, 0.22, 0.34).lerp(Color(0.42, 0.30, 0.24), rng.randf())
		draw_circle(Vector2(x, y), 2.4, tint)
		draw_rect(Rect2(x - 2.0, y + 1.0, 4.0, h), tint.darkened(0.18))


func _draw_hoop() -> void:
	var pole := Color("#2b3442")
	var white := Color("#f3f4f0")
	# Pole, arm and braces.
	draw_rect(Rect2(548.0, 92.0, 7.0, 112.0), pole)
	draw_rect(Rect2(508.0, 92.0, 40.0, 6.0), pole)
	draw_line(Vector2(548.0, 112.0), Vector2(512.0, 92.0), pole, 3.0)
	# Backboard with a soft shadow and an orange target square.
	draw_rect(Rect2(BOARD_X + 3.0, BOARD_TOP + 3.0, 12.0, BOARD_BOTTOM - BOARD_TOP), Color(0.0, 0.0, 0.0, 0.28))
	draw_rect(Rect2(BOARD_X, BOARD_TOP, 10.0, BOARD_BOTTOM - BOARD_TOP), white)
	draw_rect(Rect2(BOARD_X, BOARD_TOP, 10.0, BOARD_BOTTOM - BOARD_TOP), Color("#9aa6b2"), false, 2.0)
	draw_rect(Rect2(BOARD_X - 2.0, 116.0, 4.0, 42.0), Color("#e05a2c"))
	# Rim.
	var left := RIM_CENTER - Vector2(RIM_HALF, 0.0)
	var right := RIM_CENTER + Vector2(RIM_HALF, 0.0)
	draw_line(left, right, Color("#e05a2c"), 6.0, true)
	draw_circle(left, 3.5, Color("#ff7a45"))
	draw_circle(right, 3.5, Color("#ff7a45"))
	# Net: 11 hanging cords plus three rings.
	var net_col := Color(0.95, 0.95, 0.90, 0.82)
	var net_bottom_y := RIM_Y + 44.0
	var net_half := 17.0
	for i in 11:
		var t := float(i) / 10.0
		var top_x := lerpf(left.x, right.x, t)
		var bot_x := RIM_CENTER.x + lerpf(-net_half, net_half, t)
		draw_line(Vector2(top_x, RIM_Y + 2.0), Vector2(bot_x, net_bottom_y), net_col, 1.2, true)
	for ring_i in 3:
		var t := float(ring_i + 1) / 4.0
		var y := lerpf(RIM_Y + 3.0, net_bottom_y, t)
		var half := lerpf(RIM_HALF, net_half, t)
		draw_line(Vector2(RIM_CENTER.x - half, y), Vector2(RIM_CENTER.x + half, y),
			Color(net_col.r, net_col.g, net_col.b, 0.55), 1.0, true)
	# Rim flash when the ball clips it.
	if _flash > 0.0:
		draw_arc(RIM_CENTER, RIM_HALF + 4.0, PI, TAU, 24,
			Color(1.0, 0.55, 0.2, _flash * 0.8), 3.0, true)


func _draw_trail() -> void:
	for i in _trail.size():
		var t := float(i) / float(maxi(_trail.size(), 1))
		draw_circle(_trail[i], BALL_RADIUS * (0.25 + t * 0.55),
			Color(1.0, 0.55, 0.2, 0.05 + t * 0.14))


func _draw_ball(center: Vector2, radius: float) -> void:
	# Floor shadow when the ball is low, a soft offset blob otherwise.
	var shadow_y := minf(FLOOR_Y, center.y + radius + 6.0)
	var shadow_scale := clampf(1.0 - (shadow_y - center.y) / 220.0, 0.25, 1.0)
	draw_circle(Vector2(center.x, shadow_y), radius * 0.9 * shadow_scale,
		Color(0.0, 0.0, 0.0, 0.20))
	draw_circle(center, radius, Color("#e8792f"), true, -1.0, true)
	draw_arc(center, radius, 0.0, TAU, 24, Color("#8a3f19"), 1.5, true)
	# Seams rotate with the shot spin.
	for i in 2:
		var a := _spin + float(i) * PI * 0.5
		draw_arc(center, radius * 0.92, a, a + PI, 12, Color("#7a3514"), 1.2, true)
	draw_line(center + Vector2(-radius * 0.85, 0.0), center + Vector2(radius * 0.85, 0.0),
		Color("#7a3514"), 1.0, true)


func _draw_reticle() -> void:
	if flying or _awaiting_result:
		return
	var near := aim.distance_to(RIM_CENTER)
	var col := Color("#54e08a")
	if near > 44.0:
		col = Color("#ff6b6b")
	elif near > 20.0:
		col = Color("#ffd54a")
	# Aimed trajectory preview: a handful of dots, enough to read the arc.
	var preview := _preview_velocity()
	var p := BALL_START
	for i in 11:
		p += preview * 0.055
		preview.y += GRAVITY * 0.055
		if p.y > FLOOR_Y:
			break
		draw_circle(p, 2.2, Color(col.r, col.g, col.b, 0.10 + float(i) * 0.018))
	# Reticle.
	var pulse := 1.0 + sin(_pulse * 4.0) * 0.08
	draw_arc(aim, 17.0 * pulse, 0.0, TAU, 24, col, 2.0, true)
	draw_arc(aim, 27.0, 0.0, TAU, 24, Color(col.r, col.g, col.b, 0.30), 1.0, true)
	draw_line(aim - Vector2(25.0, 0.0), aim - Vector2(8.0, 0.0), col, 2.0, true)
	draw_line(aim + Vector2(8.0, 0.0), aim + Vector2(25.0, 0.0), col, 2.0, true)
	draw_line(aim - Vector2(0.0, 25.0), aim - Vector2(0.0, 8.0), col, 2.0, true)
	draw_line(aim + Vector2(0.0, 8.0), aim + Vector2(0.0, 25.0), col, 2.0, true)
	draw_circle(aim, 2.4, col)


func _preview_velocity() -> Vector2:
	var dist := BALL_START.distance_to(aim)
	var flight := clampf(dist / 430.0, 0.62, 1.05)
	var v := (aim - BALL_START) / flight
	v.y -= 0.5 * GRAVITY * flight
	return v


func _draw_result() -> void:
	var font := ThemeDB.fallback_font
	var col := Color("#6dff9f") if scored else Color("#ff8a7a")
	var y := 44.0
	draw_string(font, Vector2(0.0, y), last_result, HORIZONTAL_ALIGNMENT_CENTER,
		DESIGN.x, 26, col)
	if _rim_hit and not scored:
		draw_string(font, Vector2(0.0, y + 22.0), "SO CLOSE!", HORIZONTAL_ALIGNMENT_CENTER,
			DESIGN.x, 14, Color(1.0, 0.85, 0.45, 0.9))
