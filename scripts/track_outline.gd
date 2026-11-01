class_name TrackOutline
extends Control
## The shape of a circuit seen from above (from its map, TrackLayout), drawn as a thick ink line
## with a white road on top and the start marked: used on the circuit buttons of the menu.

var layout: TrackLayout


func _draw() -> void:
	if layout == null or layout.points.is_empty():
		return
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in layout.points:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	var span := hi - lo
	var s := minf(size.x / maxf(span.x, 1.0), size.y / maxf(span.y, 1.0)) * 0.9
	var off := size / 2.0 - (lo + hi) / 2.0 * s
	var line := PackedVector2Array()
	for i in range(0, layout.points.size(), 6):
		line.append(layout.points[i] * s + off)
	line.append(line[0])
	draw_polyline(line, Color(0.07, 0.03, 0.1, 0.9), 9.0, true)
	draw_polyline(line, Color.WHITE, 4.0, true)
	var st := int(maxf(layout.start_frac, 0.0) * layout.points.size()) % layout.points.size()
	draw_circle(layout.points[st] * s + off, 6.0, Color(0.07, 0.03, 0.1))
	draw_circle(layout.points[st] * s + off, 4.0, Color(1, 0.86, 0.2))
