class_name TrackLayout
extends RefCounted
## A circuit drawn as a "map": a small text file (tracks/<id>.txt) that lists the pieces of road
## one after the other, as a driver would describe them: straight 300 m, right-hand hairpin,
## chicane, 90-degree corner... The file is read here and turned into the road centre line
## (seen from above) plus the grade, which Mountain and the levels built on it use instead of
## their old formula. Anyone can edit the file with a text editor: see tracks/COME_FARE.md.
##
## Commands (one per line, upper or lower case, # starts a comment):
##   DRITTO <metri>                     straight
##   DESTRA <gradi> [raggio]            right-hand bend (raggio = radius in m, default 60)
##   SINISTRA <gradi> [raggio]          left-hand bend
##   TORNANTE DESTRA|SINISTRA [raggio]  hairpin: 180 degrees, radius 16 m by default
##   GOMITO DESTRA|SINISTRA [raggio]    elbow corner: 90 degrees, radius 14 m by default
##   CHICANE DESTRA|SINISTRA [gradi]    quick S: first one way, then the other (35 degrees)
##   ESSE DESTRA|SINISTRA <gradi> [raggio]  long S bend (two opposite bends)
##   SALITA <percento> / DISCESA <percento> / PIANO   grade of the road from here on
##   PARTENZA                           start and finish line here
## The loop is closed automatically: the turns are trimmed so they add up to a full circle and
## the straights are stretched or shortened a little so the end meets the start.

const DEFAULT_RADIUS := 60.0
const HAIRPIN_RADIUS := 16.0
const ELBOW_RADIUS := 14.0
const CHICANE_RADIUS := 26.0
const MIN_STRAIGHT := 8.0
const STEP := 1.0  # metres between output points

## Road centre seen from above, one point every STEP metres, closed (last point != first).
var points := PackedVector2Array()
## Grade (rise per metre) at each point.
var grades := PackedFloat32Array()
## Where the start line is, as a fraction of the lap (0..1), or -1 to let the level choose.
var start_frac := -1.0
## Problems found while reading the file (shown in the log).
var warnings: PackedStringArray = []
## Pieces after closing: [kind, value, radius, grade]; kind "S" straight (value = length),
## "T" turn (value = signed angle in radians, + is right).
var pieces: Array = []


static func path_for(id: String) -> String:
	return "res://tracks/%s.txt" % id


static func exists(id: String) -> bool:
	return FileAccess.file_exists(path_for(id))


static func load_id(id: String) -> TrackLayout:
	var f := FileAccess.open(path_for(id), FileAccess.READ)
	if f == null:
		return null
	var l := TrackLayout.new()
	l.parse(f.get_as_text())
	l.build()
	return l


func parse(text: String) -> void:
	pieces.clear()
	var grade := 0.0
	var start_piece := -1
	var line_no := 0
	for raw_line in text.split("\n"):
		line_no += 1
		var line := raw_line.split("#")[0].strip_edges().to_upper()
		if line.is_empty():
			continue
		var w := line.split(" ", false)
		var cmd := w[0]
		var nums: Array[float] = []
		var side := 0.0
		for i in range(1, w.size()):
			if w[i] in ["DESTRA", "DX", "D"]:
				side = 1.0
			elif w[i] in ["SINISTRA", "SX", "S"]:
				side = -1.0
			elif w[i].is_valid_float():
				nums.append(w[i].to_float())
		match cmd:
			"DRITTO", "RETTILINEO":
				pieces.append(["S", nums[0] if nums.size() > 0 else 100.0, 0.0, grade])
			"DESTRA", "SINISTRA":
				var s := 1.0 if cmd == "DESTRA" else -1.0
				var ang: float = nums[0] if nums.size() > 0 else 90.0
				var r: float = nums[1] if nums.size() > 1 else DEFAULT_RADIUS
				pieces.append(["T", deg_to_rad(ang) * s, r, grade])
			"TORNANTE", "GOMITO":
				if side == 0.0:
					warnings.append("riga %d: manca DESTRA o SINISTRA" % line_no)
					side = 1.0
				var hair := cmd == "TORNANTE"
				var r: float = nums[0] if nums.size() > 0 else (HAIRPIN_RADIUS if hair else ELBOW_RADIUS)
				# Hairpins are flatter than the road around them, like real ones.
				pieces.append(["T", (PI if hair else PI / 2.0) * side, r, grade * (0.5 if hair else 1.0)])
			"CHICANE":
				if side == 0.0:
					side = 1.0
				var a := deg_to_rad(nums[0] if nums.size() > 0 else 35.0)
				pieces.append(["T", a * side, CHICANE_RADIUS, grade])
				pieces.append(["S", 6.0, 0.0, grade])
				pieces.append(["T", -2.0 * a * side, CHICANE_RADIUS, grade])
				pieces.append(["S", 6.0, 0.0, grade])
				pieces.append(["T", a * side, CHICANE_RADIUS, grade])
			"ESSE":
				if side == 0.0:
					side = 1.0
				var a := deg_to_rad(nums[0] if nums.size() > 0 else 45.0)
				var r: float = nums[1] if nums.size() > 1 else DEFAULT_RADIUS
				pieces.append(["T", a * side, r, grade])
				pieces.append(["T", -a * side, r, grade])
			"SALITA":
				grade = (nums[0] if nums.size() > 0 else 5.0) / 100.0
			"DISCESA":
				grade = -(nums[0] if nums.size() > 0 else 5.0) / 100.0
			"PIANO":
				grade = 0.0
			"PARTENZA":
				start_piece = pieces.size()
			_:
				warnings.append("riga %d: non capisco '%s'" % [line_no, cmd])
	if start_piece >= 0:
		pieces.insert(start_piece, ["START", 0.0, 0.0, grade])


## Closes the loop and draws the points.
func build() -> void:
	_close_heading()
	_close_position()
	_trace()


func _close_heading() -> void:
	var total := 0.0
	var turn_sum := 0.0
	for p in pieces:
		if p[0] == "T":
			total += p[1]
			turn_sum += absf(p[1])
	if turn_sum == 0.0:
		warnings.append("nessuna curva: il circuito non può chiudersi")
		return
	var goal := TAU * signf(total)
	var err := goal - total
	if absf(err) > deg_to_rad(40.0):
		warnings.append("le curve sommano %.0f gradi invece di %.0f: corretto" % [rad_to_deg(total), rad_to_deg(goal)])
	# Spread the error over the turns in proportion to their size (hairpins stay hairpins).
	for p in pieces:
		if p[0] == "T":
			p[1] += err * absf(p[1]) / turn_sum


func _close_position() -> void:
	# The end point is linear in the straight lengths: least-squares change of the lengths that
	# brings the end back to the start; straights that would get too short are frozen and the
	# rest solved again.
	var frozen := {}
	for _round in 6:
		var end := _end_point()
		if end.length() < 0.05:
			return
		var dirs: Array = []  # [piece index, direction]
		var h := 0.0
		for i in pieces.size():
			var p: Array = pieces[i]
			if p[0] == "S" and not frozen.has(i):
				dirs.append([i, Vector2(cos(h), sin(h))])
			elif p[0] == "T":
				h += p[1]
		# A = sum d d^T (2x2); solve A x = -end; dL_i = d_i . x
		var a := 0.0
		var b := 0.0
		var c := 0.0
		for e in dirs:
			var d: Vector2 = e[1]
			a += d.x * d.x
			b += d.x * d.y
			c += d.y * d.y
		var det := a * c - b * b
		if dirs.is_empty() or absf(det) < 1e-6:
			warnings.append("non riesco a chiudere il giro: servono rettilinei in più direzioni")
			return
		var tx := -end.x
		var ty := -end.y
		var x := Vector2((c * tx - b * ty) / det, (a * ty - b * tx) / det)
		var any_frozen := false
		for e in dirs:
			var p: Array = pieces[e[0]]
			var nl: float = p[1] + (e[1] as Vector2).dot(x)
			if nl < MIN_STRAIGHT:
				nl = MIN_STRAIGHT
				frozen[e[0]] = true
				any_frozen = true
			p[1] = nl
		if not any_frozen:
			return
	warnings.append("il giro si chiude solo in parte: allunga i rettilinei")


func _end_point() -> Vector2:
	var pos := Vector2.ZERO
	var h := 0.0
	for p in pieces:
		if p[0] == "S":
			pos += Vector2(cos(h), sin(h)) * p[1]
		elif p[0] == "T":
			var r: float = p[2]
			var a: float = p[1]
			var s := signf(a)
			# Centre of the arc on the inside of the turn.
			var right := Vector2(-sin(h), cos(h))
			var centre := pos + right * r * s
			var h2 := h + a
			pos = centre - Vector2(-sin(h2), cos(h2)) * r * s
			h = h2
	return pos


func _trace() -> void:
	points.clear()
	grades.clear()
	var pos := Vector2.ZERO
	var h := 0.0
	var length := 0.0
	var start_len := -1.0
	for p in pieces:
		var g: float = p[3]
		if p[0] == "START":
			start_len = length
		elif p[0] == "S":
			var n := maxi(int(round(p[1] / STEP)), 1)
			var d := Vector2(cos(h), sin(h))
			for i in n:
				points.append(pos + d * (p[1] * i / n))
				grades.append(g)
			pos += d * p[1]
			length += p[1]
		elif p[0] == "T":
			var r: float = p[2]
			var a: float = p[1]
			var s := signf(a)
			var right := Vector2(-sin(h), cos(h))
			var centre := pos + right * r * s
			var arc := absf(a) * r
			var n := maxi(int(round(arc / STEP)), 2)
			for i in n:
				var hh := h + a * i / n
				points.append(centre - Vector2(-sin(hh), cos(hh)) * r * s)
				grades.append(g)
			h += a
			pos = centre - Vector2(-sin(h), cos(h)) * r * s
			length += arc
	if start_len >= 0.0 and length > 0.0:
		start_frac = start_len / length
	# Centre the circuit on the origin.
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for q in points:
		lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
		hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
	var mid := (lo + hi) / 2.0
	for i in points.size():
		points[i] -= mid


## Total length in metres.
func length() -> float:
	return points.size() * STEP


## Grade at a fraction (0..1) of the lap.
func grade_at(frac: float) -> float:
	if grades.is_empty():
		return 0.0
	return grades[clampi(int(frac * grades.size()), 0, grades.size() - 1)]


## Closest distance between two stretches of road that are more than `gap` metres apart along
## the lap: below about 30 m the two roads overlap.
func min_crossing_distance(gap := 80.0) -> float:
	var best := INF
	var n := points.size()
	var step := 4
	for i in range(0, n, step):
		for j in range(i + int(gap), n, step):
			if n - (j - i) < gap:
				continue
			best = minf(best, points[i].distance_to(points[j]))
	return best
