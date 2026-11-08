class_name Minimap
extends Control
## Small map of the circuit in a corner of the race screen (v0.17, Stefano's request): the whole
## race path seen from above, a black arrow for the player and red arrows for the rivals, moving
## and turning with the cars. North stays up. The track is drawn once (it never changes); only the
## arrows are drawn again every frame, so it costs almost nothing on the phone.

const PAD := 14.0
const PLAYER_COLOR := Color(0.02, 0.02, 0.02)
const RIVAL_COLOR := Color(0.95, 0.08, 0.08)

var _track: Array[Vector3] = []
var _min := Vector2.ZERO
var _scale := 1.0
var _offset := Vector2.ZERO
var _line: _TrackLine
## [position, forward] of the player and of each rival, in world coordinates.
var _player: Array = []
var _rivals: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line = _TrackLine.new()
	_line.map = self
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line.show_behind_parent = true  # the arrows (drawn by the map itself) go on top
	add_child(_line)
	resized.connect(_fit)


## The race path to draw (Main.race_path, start to finish).
func set_track(points: Array[Vector3]) -> void:
	_track = points
	_fit()


## Where the cars are now. Called by the race every frame.
func set_cars(player: Node3D, rivals: Array) -> void:
	_player = [player.global_position, -player.global_transform.basis.z] if player else []
	_rivals.clear()
	for r: Node3D in rivals:
		_rivals.append([r.global_position, -r.global_transform.basis.z])
	queue_redraw()


## Scale and offset so the whole path fits the box, keeping its proportions.
func _fit() -> void:
	_line.size = size
	if _track.size() < 2:
		return
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in _track:
		lo = lo.min(Vector2(p.x, p.z))
		hi = hi.max(Vector2(p.x, p.z))
	var span := (hi - lo).max(Vector2.ONE)
	var room := size - Vector2(PAD, PAD) * 2.0
	_scale = minf(room.x / span.x, room.y / span.y)
	_min = lo
	_offset = Vector2(PAD, PAD) + (room - span * _scale) * 0.5
	_line.queue_redraw()
	queue_redraw()


func to_map(p: Vector3) -> Vector2:
	return _offset + (Vector2(p.x, p.z) - _min) * _scale


func _draw() -> void:
	for r in _rivals:
		_arrow(r[0], r[1], RIVAL_COLOR, 12.0)
	if not _player.is_empty():
		_arrow(_player[0], _player[1], PLAYER_COLOR, 15.0)


## An arrow head pointing where the car is heading, with a white border so it reads on the track.
func _arrow(pos: Vector3, fwd: Vector3, color: Color, length: float) -> void:
	var d := Vector2(fwd.x, fwd.z)
	d = d.normalized() if d.length() > 0.01 else Vector2.UP
	var side := Vector2(-d.y, d.x)
	var c := to_map(pos)
	var pts := PackedVector2Array([c + d * length, c - d * length * 0.6 + side * length * 0.7,
		c - d * length * 0.25, c - d * length * 0.6 - side * length * 0.7])
	draw_colored_polygon(pts, color)
	pts.append(pts[0])
	draw_polyline(pts, Color.WHITE, 1.5, true)


## The background box and the track: drawn once, under the arrows.
class _TrackLine:
	extends Control
	var map: Minimap

	func _draw() -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.05, 0.06, 0.08, 0.62)
		box.border_color = Color(1, 1, 1, 0.35)
		box.set_border_width_all(2)
		box.set_corner_radius_all(12)
		draw_style_box(box, Rect2(Vector2.ZERO, size))
		if map._track.size() < 2:
			return
		var pts := PackedVector2Array()
		for p in map._track:
			pts.append(map.to_map(p))
		draw_polyline(pts, Color(0, 0, 0, 0.6), 9.0, true)
		draw_polyline(pts, Color(0.86, 0.88, 0.9), 5.0, true)
		# Start (green) and finish (chequered white) dots.
		draw_circle(pts[0], 5.0, Color(0.2, 0.9, 0.35))
		draw_circle(pts[pts.size() - 1], 6.0, Color.WHITE)
		draw_circle(pts[pts.size() - 1], 3.0, Color.BLACK)
