extends RefCounted
## ---------------------------------------------------------------------------
## UIIcons - one procedural icon language for the whole game UI.
##
## Every glyph is drawn on a 48x48 design grid and scaled to the target rect,
## so the same code gives a crisp 18 px HUD bolt and a 64 px interaction badge
## with no raster assets.  The look follows the clean game reference:
##
##   * white glyphs on near-black circular badges
##   * a thin white rim and a gold accent arc on the upper right
##   * cream keycaps with a dark lip for keyboard prompts
##
## Usage:
##   UIIcons.badge(canvas_item, centre, radius)          # dark disc + gold arc
##   UIIcons.draw_glyph(canvas_item, "door", rect)       # white glyph
##
## Glyph names: door, gear, box, cart, bed, talk, loot, wrench, fuel, star,
## person, flag, bolt, pause, bag, book, water, basketball, whistle, run,
## hand, salute, coin, chevron, spark, check.
## ---------------------------------------------------------------------------

const WHITE := Color(0.965, 0.975, 1.0)
const CREAM := Color(0.98, 0.96, 0.90)
const GOLD := Color(1.0, 0.80, 0.32)
const GOLD_HI := Color(1.0, 0.90, 0.58)
const DISC := Color(0.030, 0.050, 0.082, 0.92)


static func badge(ci: CanvasItem, center: Vector2, radius: float,
		arc_alpha: float = 0.92, arc_from: float = PI * 1.06,
		arc_to: float = TAU * 0.99) -> void:
	## The shared badge: soft shadow, near-black disc, thin white rim and a
	## gold accent arc across the upper right, like the reference icons.
	if ci == null or radius <= 0.0:
		return
	ci.draw_circle(center + Vector2(0.0, radius * 0.06), radius * 1.02,
			Color(0.0, 0.0, 0.0, 0.30))
	ci.draw_circle(center, radius, DISC)
	ci.draw_arc(center, radius * 0.985, 0.0, TAU, 64,
			Color(1.0, 1.0, 1.0, 0.14), maxf(1.0, radius * 0.055), true)
	if arc_alpha > 0.0:
		ci.draw_arc(center, radius * 0.90, arc_from, arc_to, 32,
				Color(GOLD.r, GOLD.g, GOLD.b, arc_alpha),
				maxf(1.6, radius * 0.11), true)


static func draw_glyph(ci: CanvasItem, kind: String, rect: Rect2,
		colour: Color = WHITE, stroke: float = -1.0) -> void:
	## Paints one glyph centred in `rect`.  `stroke` < 0 picks a width that
	## scales with the icon, so the same call works at every HUD size.
	if ci == null or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var s := minf(rect.size.x, rect.size.y)
	var u := s / 48.0
	var o := rect.position + (rect.size - Vector2(s, s)) * 0.5
	var w := stroke if stroke > 0.0 else maxf(1.8, 4.4 * u)
	match kind:
		"door": _door(ci, o, u, colour, w)
		"gear": _gear(ci, o, u, colour, w)
		"box": _box(ci, o, u, colour, w)
		"cart": _cart(ci, o, u, colour, w)
		"bed": _bed(ci, o, u, colour, w)
		"talk": _talk(ci, o, u, colour, w)
		"loot": _loot(ci, o, u, colour, w)
		"wrench": _wrench(ci, o, u, colour, w)
		"fuel": _fuel(ci, o, u, colour, w)
		"star": _star(ci, o, u, colour, w)
		"person": _person(ci, o, u, colour, w)
		"flag": _flag(ci, o, u, colour, w)
		"bolt": _bolt(ci, o, u, colour, w)
		"pause": _pause(ci, o, u, colour, w)
		"bag": _bag(ci, o, u, colour, w)
		"book": _book(ci, o, u, colour, w)
		"water": _water(ci, o, u, colour, w)
		"basketball": _basketball(ci, o, u, colour, w)
		"whistle": _whistle(ci, o, u, colour, w)
		"run": _run(ci, o, u, colour, w)
		"hand": _hand(ci, o, u, colour, w)
		"salute": _salute(ci, o, u, colour, w)
		"coin": _coin(ci, o, u, colour, w)
		"chevron": _chevron(ci, o, u, colour, w)
		"spark": _spark(ci, o, u, colour, w)
		"check": _check(ci, o, u, colour, w)
		_: _star(ci, o, u, colour, w)


# --------------------------------------------------------------------- glyphs

static func _door(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	var tl := _v(o, u, 11, 7)
	var tr := _v(o, u, 37, 7)
	var bl := _v(o, u, 11, 42)
	var br := _v(o, u, 37, 42)
	ci.draw_line(tl, tr, col, w, true)
	ci.draw_line(tr, br, col, w, true)
	ci.draw_line(bl, br, col, w, true)
	ci.draw_line(tl, bl, col, w * 0.8, true)
	var leaf := PackedVector2Array([
		_v(o, u, 12, 9), _v(o, u, 26, 12.5),
		_v(o, u, 26, 36.5), _v(o, u, 12, 40)])
	ci.draw_colored_polygon(leaf, Color(col.r, col.g, col.b, col.a * 0.20))
	_outline(ci, leaf, col, w * 0.85)
	ci.draw_circle(_v(o, u, 23, 24.5), 1.9 * u, col)
	ci.draw_arc(_v(o, u, 29.5, 24.5), 4.0 * u, -PI * 0.45, PI * 0.45, 12,
			Color(col.r, col.g, col.b, col.a * 0.55), w * 0.6, true)


static func _gear(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	var c := _v(o, u, 24, 24)
	for i in 8:
		var a := float(i) * TAU / 8.0 + PI * 0.125
		var d := Vector2(cos(a), sin(a))
		ci.draw_line(c + d * 9.5 * u, c + d * 15.0 * u, col, w * 1.4, true)
	ci.draw_arc(c, 9.6 * u, 0.0, TAU, 40, col, w, true)
	ci.draw_arc(c, 3.6 * u, 0.0, TAU, 20, col, w * 0.85, true)


static func _box(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	var top := PackedVector2Array([
		_v(o, u, 24, 6), _v(o, u, 41, 15), _v(o, u, 24, 24), _v(o, u, 7, 15)])
	_outline(ci, top, col, w)
	ci.draw_line(_v(o, u, 7, 15), _v(o, u, 7, 31), col, w, true)
	ci.draw_line(_v(o, u, 41, 15), _v(o, u, 41, 31), col, w, true)
	ci.draw_line(_v(o, u, 24, 24), _v(o, u, 24, 40), col, w, true)
	ci.draw_line(_v(o, u, 7, 31), _v(o, u, 24, 40), col, w, true)
	ci.draw_line(_v(o, u, 41, 31), _v(o, u, 24, 40), col, w, true)
	ci.draw_line(_v(o, u, 24, 6), _v(o, u, 24, 24),
			Color(col.r, col.g, col.b, col.a * 0.45), w * 0.6, true)


static func _cart(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	var basket := PackedVector2Array([
		_v(o, u, 15, 15), _v(o, u, 39, 15), _v(o, u, 34, 29), _v(o, u, 20, 29)])
	_outline(ci, basket, col, w)
	_polyline(ci, PackedVector2Array([
		_v(o, u, 7, 7), _v(o, u, 11, 10), _v(o, u, 15, 15)]), col, w)
	ci.draw_circle(_v(o, u, 22, 37), 2.7 * u, col)
	ci.draw_circle(_v(o, u, 33, 37), 2.7 * u, col)


static func _bed(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	ci.draw_line(_v(o, u, 10, 9), _v(o, u, 10, 34), col, w, true)
	ci.draw_line(_v(o, u, 10, 9), _v(o, u, 21, 9), col, w, true)
	_rrect(ci, Rect2(_v(o, u, 10, 24), Vector2(29, 8) * u), 2.5 * u, col, w)
	_rrect(ci, Rect2(_v(o, u, 13, 17), Vector2(11, 7) * u), 2.5 * u, col, w * 0.8)
	ci.draw_line(_v(o, u, 13, 32), _v(o, u, 13, 38), col, w, true)
	ci.draw_line(_v(o, u, 36, 32), _v(o, u, 36, 38), col, w, true)


static func _talk(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	_rrect(ci, Rect2(_v(o, u, 7, 9), Vector2(34, 23) * u), 8.0 * u, col, w)
	ci.draw_colored_polygon(PackedVector2Array([
		_v(o, u, 17, 31), _v(o, u, 14, 40), _v(o, u, 27, 31)]), col)
	for dx in [16.0, 24.0, 32.0]:
		ci.draw_circle(_v(o, u, dx, 20.5), 2.0 * u, col)


static func _loot(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	ci.draw_arc(_v(o, u, 24, 22), 15.0 * u, PI, TAU, 28, col, w, true)
	_rrect(ci, Rect2(_v(o, u, 9, 22), Vector2(30, 16) * u), 3.0 * u, col, w)
	ci.draw_line(_v(o, u, 9, 27), _v(o, u, 39, 27),
			Color(col.r, col.g, col.b, col.a * 0.55), w * 0.6, true)
	ci.draw_rect(Rect2(_v(o, u, 21, 25), Vector2(6, 7) * u), col)


static func _wrench(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	ci.draw_line(_v(o, u, 14, 34), _v(o, u, 30, 18), col, w * 1.5, true)
	ci.draw_arc(_v(o, u, 34, 14), 7.0 * u, -PI * 0.88, PI * 0.30, 22,
			col, w * 1.25, true)
	ci.draw_arc(_v(o, u, 12, 36), 4.5 * u, PI * 0.15, PI * 1.35, 18,
			col, w * 1.1, true)


static func _fuel(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	_rrect(ci, Rect2(_v(o, u, 9, 8), Vector2(18, 30) * u), 3.0 * u, col, w)
	ci.draw_rect(Rect2(_v(o, u, 13, 12), Vector2(10, 7) * u),
			Color(col.r, col.g, col.b, col.a * 0.9))
	_polyline(ci, PackedVector2Array([
		_v(o, u, 27, 15), _v(o, u, 36, 20), _v(o, u, 36, 30)]), col, w)
	_rrect(ci, Rect2(_v(o, u, 33, 29), Vector2(8, 6) * u), 1.5 * u, col, w)
	ci.draw_line(_v(o, u, 7, 39), _v(o, u, 30, 39), col, w, true)


static func _star(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	var c := _v(o, u, 24, 25)
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI * 0.5 + float(i) * PI / 5.0
		var r := (14.5 if i % 2 == 0 else 6.4) * u
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	ci.draw_colored_polygon(pts, col)


static func _person(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	ci.draw_circle(_v(o, u, 24, 14), 6.3 * u, col)
	ci.draw_arc(_v(o, u, 24, 42), 15.0 * u, PI * 1.02, TAU * 0.98, 26,
			col, w * 1.35, true)


static func _flag(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	ci.draw_line(_v(o, u, 13, 5), _v(o, u, 13, 43), col, w, true)
	ci.draw_colored_polygon(PackedVector2Array([
		_v(o, u, 13, 7), _v(o, u, 37, 9), _v(o, u, 31, 17),
		_v(o, u, 37, 25), _v(o, u, 13, 25)]), col)


static func _bolt(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	ci.draw_colored_polygon(PackedVector2Array([
		_v(o, u, 27, 4), _v(o, u, 11, 26), _v(o, u, 22, 26),
		_v(o, u, 18, 44), _v(o, u, 37, 20), _v(o, u, 26, 20)]), col)


static func _pause(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	_fill_rrect(ci, Rect2(_v(o, u, 15, 12), Vector2(6.5, 24) * u), 2.5 * u, col)
	_fill_rrect(ci, Rect2(_v(o, u, 26.5, 12), Vector2(6.5, 24) * u), 2.5 * u, col)


static func _bag(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	_rrect(ci, Rect2(_v(o, u, 12, 15), Vector2(24, 27) * u), 8.0 * u, col, w)
	ci.draw_arc(_v(o, u, 24, 15), 6.0 * u, PI, TAU, 18, col, w, true)
	_rrect(ci, Rect2(_v(o, u, 17, 26), Vector2(14, 10) * u), 3.0 * u, col, w * 0.8)


static func _book(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	var left := PackedVector2Array([
		_v(o, u, 6, 11), _v(o, u, 22, 14), _v(o, u, 22, 38), _v(o, u, 6, 34)])
	var right := PackedVector2Array([
		_v(o, u, 42, 11), _v(o, u, 26, 14), _v(o, u, 26, 38), _v(o, u, 42, 34)])
	_outline(ci, left, col, w * 0.9)
	_outline(ci, right, col, w * 0.9)
	ci.draw_line(_v(o, u, 24, 14), _v(o, u, 24, 38), col, w, true)


static func _water(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	ci.draw_circle(_v(o, u, 24, 30), 10.4 * u, col)
	ci.draw_colored_polygon(PackedVector2Array([
		_v(o, u, 24, 4), _v(o, u, 34.2, 29), _v(o, u, 13.8, 29)]), col)


static func _basketball(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	var c := _v(o, u, 24, 24)
	ci.draw_arc(c, 16.0 * u, 0.0, TAU, 44, col, w, true)
	ci.draw_line(_v(o, u, 8, 24), _v(o, u, 40, 24), col, w * 0.75, true)
	ci.draw_line(_v(o, u, 24, 8), _v(o, u, 24, 40), col, w * 0.75, true)
	ci.draw_arc(_v(o, u, 40, 24), 14.0 * u, PI * 0.62, PI * 1.38, 18,
			col, w * 0.7, true)
	ci.draw_arc(_v(o, u, 8, 24), 14.0 * u, -PI * 0.38, PI * 0.38, 18,
			col, w * 0.7, true)


static func _whistle(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	ci.draw_arc(_v(o, u, 19, 27), 11.0 * u, 0.0, TAU, 32, col, w * 1.15, true)
	ci.draw_circle(_v(o, u, 19, 27), 3.0 * u, col)
	ci.draw_line(_v(o, u, 29, 22), _v(o, u, 42, 17), col, w * 1.5, true)
	ci.draw_line(_v(o, u, 29, 32), _v(o, u, 42, 32), col, w * 1.5, true)


static func _run(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	ci.draw_circle(_v(o, u, 31, 9), 4.0 * u, col)
	var hip := _v(o, u, 24, 27)
	_seg(ci, _v(o, u, 29, 16), hip, w * 0.9, col)
	_seg(ci, hip, _v(o, u, 32, 33), w * 0.9, col)
	_seg(ci, _v(o, u, 32, 33), _v(o, u, 40, 39), w * 0.9, col)
	_seg(ci, hip, _v(o, u, 18, 35), w * 0.9, col)
	_seg(ci, _v(o, u, 18, 35), _v(o, u, 10, 40), w * 0.9, col)
	_seg(ci, _v(o, u, 28, 18), _v(o, u, 38, 23), w * 0.9, col)
	_seg(ci, _v(o, u, 28, 18), _v(o, u, 18, 22), w * 0.9, col)
	ci.draw_line(_v(o, u, 4, 24), _v(o, u, 12, 24),
			Color(col.r, col.g, col.b, col.a * 0.55), w * 0.6, true)
	ci.draw_line(_v(o, u, 2, 30), _v(o, u, 9, 30),
			Color(col.r, col.g, col.b, col.a * 0.55), w * 0.6, true)


static func _hand(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	_fill_rrect(ci, Rect2(_v(o, u, 15, 22), Vector2(20, 18) * u), 8.0 * u, col)
	_fill_rrect(ci, Rect2(_v(o, u, 21, 8), Vector2(6.5, 18) * u), 3.2 * u, col)
	_polyline(ci, PackedVector2Array([
		_v(o, u, 15, 28), _v(o, u, 9, 23), _v(o, u, 9, 17)]), col, w * 0.85)


static func _salute(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	ci.draw_circle(_v(o, u, 27, 12), 5.6 * u, col)
	_seg(ci, _v(o, u, 27, 18), _v(o, u, 25, 31), w, col)
	_seg(ci, _v(o, u, 25, 31), _v(o, u, 18, 41), w, col)
	_seg(ci, _v(o, u, 25, 31), _v(o, u, 32, 41), w, col)
	_seg(ci, _v(o, u, 26, 21), _v(o, u, 34, 17), w * 0.85, col)
	_seg(ci, _v(o, u, 34, 17), _v(o, u, 31, 10), w * 0.85, col)
	_seg(ci, _v(o, u, 26, 21), _v(o, u, 17, 27), w * 0.85, col)


static func _coin(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	var c := _v(o, u, 24, 24)
	ci.draw_circle(c, 18.5 * u, GOLD)
	ci.draw_arc(c, 13.2 * u, 0.0, TAU, 40, Color(0.72, 0.50, 0.10), 3.4 * u, true)
	ci.draw_circle(c, 10.0 * u, Color(0.98, 0.80, 0.32))
	ci.draw_arc(c, 16.0 * u, PI * 1.02, PI * 1.52, 20,
			Color(1.0, 0.97, 0.72, 0.9), 2.2 * u, true)


static func _chevron(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	_polyline(ci, PackedVector2Array([
		_v(o, u, 18, 14), _v(o, u, 30, 24), _v(o, u, 18, 34)]), col, w * 1.1)


static func _spark(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	var c := _v(o, u, 24, 24)
	var pts := PackedVector2Array()
	for i in 8:
		var a := -PI * 0.5 + float(i) * TAU / 8.0
		var r := (18.0 if i % 2 == 0 else 6.4) * u
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	ci.draw_colored_polygon(pts, GOLD)
	ci.draw_circle(c, 3.0 * u, GOLD_HI)


static func _check(ci: CanvasItem, o: Vector2, u: float, col: Color, w: float) -> void:
	_polyline(ci, PackedVector2Array([
		_v(o, u, 10, 25), _v(o, u, 20, 35), _v(o, u, 39, 13)]), col, w * 1.3)


# --------------------------------------------------------------------- helpers

static func _v(o: Vector2, u: float, x: float, y: float) -> Vector2:
	return o + Vector2(x, y) * u


static func _seg(ci: CanvasItem, a: Vector2, b: Vector2, width: float,
		colour: Color) -> void:
	ci.draw_line(a, b, colour, width, true)
	ci.draw_circle(a, width * 0.5, colour)
	ci.draw_circle(b, width * 0.5, colour)


static func _polyline(ci: CanvasItem, pts: PackedVector2Array, colour: Color,
		width: float) -> void:
	ci.draw_polyline(pts, colour, width, true)
	for p in pts:
		ci.draw_circle(p, width * 0.5, colour)


static func _outline(ci: CanvasItem, pts: PackedVector2Array, colour: Color,
		width: float) -> void:
	var loop := pts.duplicate()
	loop.append(pts[0])
	_polyline(ci, loop, colour, width)


static func _fill_rrect(ci: CanvasItem, rect: Rect2, radius: float,
		colour: Color) -> void:
	ci.draw_colored_polygon(_rrect_poly(rect, radius), colour)


static func _rrect(ci: CanvasItem, rect: Rect2, radius: float, colour: Color,
		width: float) -> void:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	if r <= 0.5:
		ci.draw_rect(rect, colour, false, width)
		return
	var l := rect.position.x
	var t := rect.position.y
	var rr := rect.end.x
	var b := rect.end.y
	ci.draw_line(Vector2(l + r, t), Vector2(rr - r, t), colour, width, true)
	ci.draw_line(Vector2(l + r, b), Vector2(rr - r, b), colour, width, true)
	ci.draw_line(Vector2(l, t + r), Vector2(l, b - r), colour, width, true)
	ci.draw_line(Vector2(rr, t + r), Vector2(rr, b - r), colour, width, true)
	ci.draw_arc(Vector2(l + r, t + r), r, PI, PI * 1.5, 10, colour, width, true)
	ci.draw_arc(Vector2(rr - r, t + r), r, PI * 1.5, TAU, 10, colour, width, true)
	ci.draw_arc(Vector2(rr - r, b - r), r, 0.0, PI * 0.5, 10, colour, width, true)
	ci.draw_arc(Vector2(l + r, b - r), r, PI * 0.5, PI, 10, colour, width, true)


static func _rrect_poly(rect: Rect2, radius: float) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var pts := PackedVector2Array()
	var corners := [
		[Vector2(rect.position.x + r, rect.position.y + r), PI, PI * 1.5],
		[Vector2(rect.end.x - r, rect.position.y + r), PI * 1.5, TAU],
		[Vector2(rect.end.x - r, rect.end.y - r), 0.0, PI * 0.5],
		[Vector2(rect.position.x + r, rect.end.y - r), PI * 0.5, PI]]
	for corner in corners:
		var c: Vector2 = corner[0]
		var a0: float = corner[1]
		var a1: float = corner[2]
		for j in 9:
			var a := a0 + (a1 - a0) * float(j) / 8.0
			pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts
