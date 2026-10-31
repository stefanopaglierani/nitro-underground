extends SceneTree
## Draws every circuit map in tracks/ as a picture seen from above, and checks it:
##   godot --headless --script tools/map_preview.gd -- <output dir>
## For each tracks/<id>.txt it writes <output dir>/<id>.png and prints the length, the warnings
## and how close two different stretches of road come (under ~30 m they would overlap).

func _init() -> void:
	var out := "build/maps"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	var dir := DirAccess.open("res://tracks")
	for f in dir.get_files():
		if not f.ends_with(".txt"):
			continue
		var id := f.get_basename()
		var l := TrackLayout.load_id(id)
		var cross := l.min_crossing_distance()
		print("%s: %.0f m, distanza minima tra due tratti %.0f m %s" % [id, l.length(), cross, "OK" if cross > 32.0 else "TROPPO VICINI!"])
		for w in l.warnings:
			print("   attenzione: ", w)
		_draw(l, "%s/%s.png" % [out, id])
	quit()


func _draw(l: TrackLayout, path: String) -> void:
	var size := 900
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.1, 0.12, 0.16))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in l.points:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	var scale := (size - 80.0) / maxf(hi.x - lo.x, hi.y - lo.y)
	var off := Vector2(size, size) / 2.0 - (lo + hi) / 2.0 * scale
	# 100 m grid
	for gx in range(int(floor(lo.x / 100.0)) * 100, int(hi.x) + 100, 100):
		var x := int(gx * scale + off.x)
		if x >= 0 and x < size:
			img.fill_rect(Rect2i(x, 0, 1, size), Color(0.18, 0.2, 0.25))
	for gz in range(int(floor(lo.y / 100.0)) * 100, int(hi.y) + 100, 100):
		var y := int(gz * scale + off.y)
		if y >= 0 and y < size:
			img.fill_rect(Rect2i(0, y, size, 1), Color(0.18, 0.2, 0.25))
	var road := maxi(int(12.0 * scale), 3)
	var h := 0.0
	var hmin := INF
	var hmax := -INF
	var heights := PackedFloat32Array()
	for i in l.points.size():
		heights.append(h)
		hmin = minf(hmin, h)
		hmax = maxf(hmax, h)
		h += l.grades[i] * TrackLayout.STEP
	for i in l.points.size():
		var q := l.points[i] * scale + off
		var t := (heights[i] - hmin) / maxf(hmax - hmin, 0.01)
		var c := Color(0.95, 0.85, 0.2).lerp(Color(1.0, 0.3, 0.25), t)
		img.fill_rect(Rect2i(int(q.x) - road / 2, int(q.y) - road / 2, road, road), c)
	# Start line and direction.
	var s := int(maxf(l.start_frac, 0.0) * l.points.size()) % l.points.size()
	var sp := l.points[s] * scale + off
	img.fill_rect(Rect2i(int(sp.x) - 9, int(sp.y) - 9, 18, 18), Color.WHITE)
	var ahead := l.points[(s + 40) % l.points.size()] * scale + off
	img.fill_rect(Rect2i(int(ahead.x) - 5, int(ahead.y) - 5, 10, 10), Color(0.3, 1, 0.4))
	img.save_png(path)
