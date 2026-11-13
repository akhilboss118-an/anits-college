class_name Campus
extends RefCounted
## Plan-pixel <-> world-metre conversion for the ANITS campus.
##
## V2 layout: the campus plan is digitised from the new campus plan image.
##   origin  = (745, 465) plan px  (campus centre)
##   scale   = 0.2 m per plan px  (derived from the 12 m main road)
## (+X = east, +Z = south). Keep authoring in plan pixels; convert at load time.
##
## V1 layout (the original web build) used origin (215, 250) and 0.7 m/px.

const MAP_SCALE := 0.7
const MAP_ORIGIN := Vector2(215.0, 250.0)

## Campus extent in plan pixels (x0, y0, x1, y1).
const EXTENT_MAP := Rect2(58, 58, 310, 374)


static func map_to_world(p: Vector2) -> Vector3:
	return Vector3(
		(p.x - MAP_ORIGIN.x) * MAP_SCALE,
		0.0,
		(p.y - MAP_ORIGIN.y) * MAP_SCALE
	)


static func world_to_map(w: Vector3) -> Vector2:
	return Vector2(
		w.x / MAP_SCALE + MAP_ORIGIN.x,
		w.z / MAP_SCALE + MAP_ORIGIN.y
	)


static func map_to_world_x(px: float) -> float:
	return (px - MAP_ORIGIN.x) * MAP_SCALE


static func map_to_world_z(py: float) -> float:
	return (py - MAP_ORIGIN.y) * MAP_SCALE


## Map rect [x0,y0,x1,y1] -> world rect on the XZ plane.
static func map_rect_to_world(r: Rect2) -> Rect2:
	var a := map_to_world(r.position)
	var b := map_to_world(r.end)
	return Rect2(
		Vector2(minf(a.x, b.x), minf(a.z, b.z)),
		Vector2(absf(b.x - a.x), absf(b.z - a.z))
	)


## World metres per map pixel.
static func map_len_to_world(px: float) -> float:
	return px * MAP_SCALE


## World size of the campus in metres (217.0 x 261.8).
static func campus_size_m() -> Vector2:
	return Vector2(EXTENT_MAP.size.x, EXTENT_MAP.size.y) * MAP_SCALE
