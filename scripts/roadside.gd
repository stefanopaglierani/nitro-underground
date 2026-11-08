class_name Roadside
## Dressing of the circuits with the "ambientazione vendibile" models of v0.20 (assets/scenery/env,
## all CC BY 4.0 or CC0, credits in assets/LICENSES.md): plenty of vegetation and rocks, plus a
## measured amount of houses, street furniture, industrial bits and power lines, one model per
## kind of object (Stefano, 2026-11-08: "dove abbiamo cose doppie, ne prendiamo uno solo").
##
## Each circuit has a kit: a list of entries
##   [model, pieces, min height, max height, count, min distance, max distance, flags]
## - model: file in assets/scenery/env (without .glb);
## - pieces: indexes of the pieces of a pack (see tools/piece_grid.gd), [] = the whole file;
## - heights in metres (each copy gets a random one), count = copies wanted;
## - distances from the road centre, in metres;
## - flags: "face" turns the model's front (+z) to the road, "solid" gives it a collision box,
##   "plant" asks the level whether plants may grow there (sea, beach), "flat" wants level ground,
##   "loose" makes it a light body that cars knock over, "noshadow" skips shadows (small things).
## Copies are drawn as MultiMeshes grouped in squares of CHUNK metres, so far groups are culled
## and hidden past their visibility distance, which keeps the phone's draw calls in check.

const CHUNK := 128.0
const DIR := "env/"

## Mountain pass: forest, scrub and rocks; a farm, a cabin and picnic spots.
const MOUNTAIN := [
	["pine_tree", [], 9.0, 16.0, 80, 14.0, 90.0, ["plant", "solid"]],
	["conifer_pack", [5], 7.0, 11.0, 60, 16.0, 120.0, ["plant"]],
	["conifer_pack", [4], 7.0, 10.0, 28, 14.0, 80.0, ["plant", "solid"]],
	["conifer_pack", [0, 1, 2, 3, 6, 7], 0.6, 2.2, 80, 10.0, 60.0, ["plant", "noshadow"]],
	["trees_collection", [0, 2, 3], 8.0, 13.0, 50, 14.0, 100.0, ["plant", "solid"]],
	["trees_collection", [1, 4], 3.0, 5.0, 60, 11.0, 70.0, ["plant"]],
	["vegetation_pack", [2, 6, 7], 0.6, 1.6, 180, 10.0, 45.0, ["plant", "noshadow"]],
	["oak", [], 8.0, 12.0, 36, 15.0, 90.0, ["plant", "solid"]],
	["oak_set", [], 7.0, 9.0, 12, 16.0, 80.0, ["plant", "solid"]],
	["bush", [], 0.8, 1.4, 180, 9.5, 40.0, ["plant", "noshadow"]],
	["grass_patches", [0, 1], 0.5, 0.9, 240, 9.0, 35.0, ["plant", "noshadow"]],
	["shrub", [], 0.5, 0.8, 120, 9.0, 30.0, ["plant", "noshadow"]],
	["stump", [], 0.5, 0.8, 32, 10.0, 40.0, ["plant", "noshadow"]],
	["rock_moss", [0, 1, 2, 3, 4, 5], 0.6, 1.6, 100, 9.5, 50.0, ["noshadow"]],
	["boulders", [0, 1], 0.7, 1.4, 60, 9.5, 40.0, ["noshadow"]],
	["rock_face", [], 4.0, 7.0, 16, 13.0, 50.0, ["solid", "sink", "noshadow"]],
	["rock_scan", [], 5.0, 9.0, 5, 18.0, 70.0, ["solid", "sink", "noshadow"]],
	["cliff_rock", [], 7.0, 12.0, 10, 18.0, 80.0, ["solid", "sink", "noshadow"]],
	["cliffs", [], 6.0, 10.0, 10, 20.0, 90.0, ["solid", "sink", "noshadow"]],
	["wooden_house", [], 6.0, 6.5, 3, 20.0, 40.0, ["face", "solid", "flat"]],
	["rural_set", [0, 18], 7.0, 8.0, 2, 24.0, 45.0, ["face", "solid", "flat"]],
	["picnic_table", [], 0.75, 0.75, 6, 11.0, 15.0, ["flat", "noshadow"]],
]

## Riviera: palms and Mediterranean-looking scrub along the sea, American seaside houses with
## their mailboxes, a couple of phone booths and picnic tables.
const COAST := [
	["palm", [0, 1, 3, 5, 10, 11, 13, 14, 15, 16, 17], 9.0, 15.0, 90, 10.0, 45.0, ["plant", "solid"]],
	["trees_collection", [0, 2, 3], 7.0, 11.0, 50, 14.0, 80.0, ["plant", "solid"]],
	["trees_collection", [4], 2.0, 3.5, 50, 10.0, 50.0, ["plant", "noshadow"]],
	["oak", [], 7.0, 10.0, 20, 15.0, 70.0, ["plant", "solid"]],
	["vegetation_pack", [2, 6, 7], 0.6, 1.4, 120, 9.5, 40.0, ["plant", "noshadow"]],
	["bush", [], 0.8, 1.3, 140, 9.5, 35.0, ["plant", "noshadow"]],
	["grass_patches", [0, 1], 0.5, 0.9, 180, 9.0, 30.0, ["plant", "noshadow"]],
	["shrub", [], 0.5, 0.8, 80, 9.0, 30.0, ["plant", "noshadow"]],
	["rock_moss", [0, 1, 2, 3, 4, 5], 0.6, 1.5, 60, 9.5, 40.0, ["noshadow"]],
	["boulders", [0, 1], 0.7, 1.3, 50, 9.5, 35.0, ["noshadow"]],
	["suburban_house", [], 8.0, 8.5, 6, 20.0, 34.0, ["face", "solid", "flat", "plant"]],
	["shabby_house", [], 8.0, 8.5, 4, 20.0, 34.0, ["face", "solid", "flat", "plant"]],
	["house_mobile", [], 6.5, 7.0, 6, 19.0, 32.0, ["face", "solid", "flat", "plant"]],
	["brick_house", [], 7.0, 7.5, 4, 20.0, 34.0, ["face", "solid", "flat", "plant"]],
	["mailbox", [], 1.25, 1.25, 10, 9.6, 10.2, ["face", "loose", "noshadow"]],
	["phone_booth", [], 2.4, 2.4, 2, 10.5, 12.0, ["face", "solid", "flat", "noshadow"]],
	["picnic_table", [], 0.75, 0.75, 12, 11.0, 15.0, ["flat", "noshadow", "plant"]],
	["street_light", [], 6.0, 6.0, 12, 9.4, 9.6, ["face", "solid", "noshadow"]],
]

## Route 66 desert: rocks and dry grass, a gas stop and small-town buildings by the road, junk
## around the yards. The old town of the circuit stays as it is.
const DESERT := [
	["grass_patches", [0, 1], 0.5, 1.0, 180, 9.0, 60.0, ["noshadow"]],
	["shrub", [], 0.5, 0.9, 90, 9.0, 40.0, ["noshadow"]],
	["bush", [], 0.6, 1.0, 60, 9.5, 40.0, ["noshadow"]],
	["boulders", [0, 1], 0.8, 1.8, 75, 9.5, 60.0, ["noshadow"]],
	["rock_moss", [0, 1, 2, 3, 4, 5], 0.8, 2.0, 45, 9.5, 60.0, ["noshadow"]],
	["rock_face", [], 4.0, 8.0, 15, 14.0, 80.0, ["solid", "sink", "noshadow"]],
	["rock_scan", [], 6.0, 10.0, 5, 20.0, 90.0, ["solid", "sink", "noshadow"]],
	["cliff_rock", [], 9.0, 16.0, 9, 25.0, 110.0, ["solid", "sink", "noshadow"]],
	["cliffs", [], 8.0, 14.0, 9, 25.0, 110.0, ["solid", "sink", "noshadow"]],
	["stump", [], 0.5, 0.7, 15, 10.0, 40.0, ["noshadow"]],
	["rural_set", [1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 16, 17], 5.0, 7.5, 10, 18.0, 30.0, ["face", "solid", "flat"]],
	["wooden_house", [], 6.0, 6.5, 2, 20.0, 36.0, ["face", "solid", "flat"]],
	["container_building", [], 3.0, 3.0, 3, 15.0, 26.0, ["face", "solid", "flat"]],
	["warehouse", [], 5.5, 6.0, 2, 20.0, 34.0, ["face", "solid", "flat"]],
	["gas_pump", [], 1.9, 1.9, 4, 11.0, 13.0, ["face", "solid", "flat", "noshadow"]],
	["gas_sign", [], 7.0, 7.0, 2, 10.5, 11.5, ["face", "solid", "noshadow"]],
	["tyre", [], 0.7, 0.7, 14, 10.5, 25.0, ["noshadow"]],
	["propane", [], 1.1, 1.1, 8, 12.0, 25.0, ["noshadow", "loose"]],
	["barrels_pack", [5, 6, 8, 9], 1.0, 1.0, 14, 11.0, 25.0, ["noshadow", "loose"]],
	["container", [], 2.6, 2.6, 3, 20.0, 40.0, ["solid", "flat"]],
	["chain_fence", [0], 2.4, 2.4, 10, 13.0, 30.0, ["face", "noshadow"]],
	["mailbox", [], 1.25, 1.25, 5, 9.6, 10.2, ["face", "loose", "noshadow"]],
]

## Night downtown: street furniture on the sidewalks (the circuit already has lamps, traffic
## lights, hydrants and bins) and an industrial yard here and there in the gaps behind.
const NIGHT_SIDEWALK := [
	["dumpster", [0], 1.4, 1.4, 30, 0.0, 0.0, ["face", "solid", "noshadow"]],
	["trashbag", [], 0.6, 0.8, 60, 0.0, 0.0, ["noshadow"]],
	["phone_booth", [], 2.4, 2.4, 10, 0.0, 0.0, ["face", "solid", "noshadow"]],
	["parking_meter", [], 1.4, 1.4, 50, 0.0, 0.0, ["face", "loose", "noshadow"]],
	["mailbox", [], 1.25, 1.25, 0, 0.0, 0.0, ["face", "loose", "noshadow"]],
	["utility_box", [], 1.2, 1.2, 25, 0.0, 0.0, ["face", "solid", "noshadow"]],
]
const NIGHT_YARDS := [
	["container", [], 2.6, 2.6, 8, 18.0, 70.0, ["solid", "flat"]],
	["transformer", [], 4.0, 4.0, 3, 18.0, 70.0, ["face", "solid", "flat"]],
	["warehouse", [], 6.0, 6.0, 3, 18.0, 80.0, ["face", "solid", "flat"]],
	["industrial", [], 16.0, 18.0, 2, 25.0, 100.0, ["face", "solid", "flat"]],
	["bricks", [], 1.2, 1.2, 6, 16.0, 60.0, ["noshadow"]],
	["barrels_pack", [5, 6, 8, 9, 10, 12], 1.0, 1.0, 20, 16.0, 60.0, ["noshadow"]],
	["chain_fence", [0], 2.4, 2.4, 12, 16.0, 60.0, ["noshadow"]],
	["concrete_fence", [], 2.5, 2.5, 8, 16.0, 60.0, ["noshadow"]],
	["oak", [], 7.0, 10.0, 12, 16.0, 60.0, ["solid"]],
	["trees_collection", [0, 2, 3], 7.0, 10.0, 12, 16.0, 60.0, ["solid"]],
]

## Power line on one side of the road: pole every SPAN metres or so, cables between them.
const POLE := "power_pole"
const POLE_HEIGHT := 11.5


## level id -> kit and power line.
static func dress(t: Mountain, level: String) -> void:
	if OS.has_environment("NO_ROADSIDE"):
		return  # for before/after measurements
	var r := Roadside.new()
	r._t = t
	r._rng.seed = t.rng_seed + 2026
	r._collect_occupied()
	match level:
		"mountain":
			r._kit(MOUNTAIN)
			r._power_line(1.0, 10.5)
		"coast":
			r._kit(COAST)
			r._power_line(-1.0, 10.5)
		"desert":
			r._kit(DESERT)
			r._power_line(1.0, 12.0)
			r._power_line(-1.0, 16.0)
		"night":
			r._sidewalks(NIGHT_SIDEWALK)
			r._kit(NIGHT_YARDS)
	r._flush()


var _t: Mountain
var _rng := RandomNumberGenerator.new()
var _occ := {}  # Vector2i cell (8 m) -> [[Vector2 centre, radius], ...]
var _batches := {}  # [model, piece, chunk, shadow] -> transforms
var _body: StaticBody3D


# ---------- Free space ----------

static func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / 8.0), floori(p.y / 8.0))


func _occupy(p: Vector2, r: float) -> void:
	var c := _cell(p)
	if not _occ.has(c):
		_occ[c] = []
	_occ[c].append([p, r])


func _clear(p: Vector2, r: float) -> bool:
	var c := _cell(p)
	var reach := ceili((r + 20.0) / 8.0)
	for dx in range(-reach, reach + 1):
		for dz in range(-reach, reach + 1):
			for o in _occ.get(c + Vector2i(dx, dz), []):
				if (o[0] as Vector2).distance_to(p) < r + float(o[1]):
					return false
	return true


## Everything the level already placed with a collision (houses, trunks, ramps, signs...).
func _collect_occupied() -> void:
	for col in _t.find_children("*", "CollisionShape3D", true, false):
		var cs := col as CollisionShape3D
		var xf := cs.global_transform if cs.is_inside_tree() else cs.transform
		var p := xf.origin
		var r := 1.0
		if cs.shape is BoxShape3D:
			# A row of circles along the long side: a single circle round a long building
			# would also cover the sidewalk in front of it.
			var s := (cs.shape as BoxShape3D).size
			var ax := xf.basis.x.normalized()
			var az := xf.basis.z.normalized()
			var long_x := s.x >= s.z
			var long := s.x if long_x else s.z
			var short := s.z if long_x else s.x
			if long > 120.0:
				continue
			var dir := ax if long_x else az
			var count := maxi(1, ceili(long / maxf(short, 0.5)))
			for i in count:
				var c := p + dir * ((i + 0.5) / count - 0.5) * long
				_occupy(Vector2(c.x, c.z), maxf(short, long / count) * 0.55)
			continue
		elif cs.shape is CylinderShape3D:
			r = (cs.shape as CylinderShape3D).radius
		elif cs.shape is SphereShape3D:
			r = (cs.shape as SphereShape3D).radius
		else:
			continue  # terrain and road meshes
		if r > 60.0:
			continue
		_occupy(Vector2(p.x, p.z), r)


# ---------- Placing ----------

func _kit(kit: Array) -> void:
	for e in kit:
		_entry(e)


## Size of a piece (or of the whole model) in its own units.
static func _box(model: String, piece: int) -> AABB:
	if piece < 0:
		Scenery.parts(DIR + model, 1.0)
		return Scenery._bounds[DIR + model]
	return Scenery.pieces(DIR + model)[piece]["box"]


func _entry(e: Array) -> void:
	var model: String = e[0]
	if not Scenery.exists(DIR + model):
		return
	var pieces: Array = e[1]
	var flags: Array = e[7]
	var want: int = maxi(1, roundi(int(e[4]) * Perf.density()))
	var n := _t.pts.size()
	var placed := 0
	var tries := 0
	while placed < want and tries < want * 40:
		tries += 1
		var piece: int = pieces[_rng.randi() % pieces.size()] if not pieces.is_empty() else -1
		var box := _box(model, piece)
		var s := _rng.randf_range(e[2], e[3]) / maxf(box.size.y, 0.001)
		var half := Vector2(box.size.x, box.size.z) * s / 2.0
		var radius := half.length() * (0.8 if "solid" in flags else 0.6)
		var k := _rng.randi() % n
		var side := 1.0 if _rng.randf() < 0.5 else -1.0
		var dist := _rng.randf_range(e[5], e[6])
		var right := _t._right(k) * side
		# Big models keep their whole footprint off the asphalt.
		var centre := _t.pts[k] + right * (dist + (half.y if "face" in flags else 0.0))
		var p2 := Vector2(centre.x, centre.z)
		if _t._road_dist_at(centre.x, centre.z) < minf(e[5], dist) - 0.5:
			continue  # another stretch of road is closer
		if not _clear(p2, radius):
			continue
		var h := _t.ground_height(centre.x, centre.z)
		var lo := h
		var hi := h
		for o in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			var g := _t.ground_height(centre.x + o.x * half.x, centre.z + o.y * half.y)
			lo = minf(lo, g)
			hi = maxf(hi, g)
		if hi - lo > (1.2 if "flat" in flags else 3.0):
			continue
		if "plant" in flags and not _t._plant_ok(centre.x, centre.z, h):
			continue
		var basis: Basis
		if "face" in flags:
			basis = Basis.looking_at(right, Vector3.UP)  # model front (+z) towards the road
		else:
			basis = Basis(Vector3.UP, _rng.randf() * TAU)
		var ground := lo if ("solid" in flags or "flat" in flags) else h
		if "sink" in flags:
			ground = lo - box.size.y * s * 0.2
		var xf := Transform3D(basis.scaled(Vector3.ONE * s), Vector3(centre.x, ground - 0.05, centre.z))
		_occupy(p2, radius)
		_add(model, piece, xf, box, s, flags)
		placed += 1
	if OS.has_environment("ROADSIDE_DEBUG"):
		print("roadside %s: %d/%d" % [model, placed, want])


## Sidewalk furniture of the night city: between the kerb and the building fronts.
func _sidewalks(kit: Array) -> void:
	var front := Mountain.RAIL_OFFSET + NightCity.SIDEWALK
	for e in kit:
		var list: Array = (e as Array).duplicate()
		list[5] = Mountain.ROAD_HALF + 1.2
		list[6] = front - 1.0
		_entry(list)


func _add(model: String, piece: int, xf: Transform3D, box: AABB, s: float, flags: Array) -> void:
	if "loose" in flags:
		_loose(model, piece, xf, box, s)
		return
	var key := [model, piece, Vector2i(floori(xf.origin.x / CHUNK), floori(xf.origin.z / CHUNK)), not ("noshadow" in flags), flags]
	if not _batches.has(key):
		_batches[key] = []
	_batches[key].append(xf)
	if "solid" in flags:
		if _body == null:
			_body = StaticBody3D.new()
			_t.add_child(_body)
		var col := CollisionShape3D.new()
		var size := box.size * s
		if size.y > 3.0 * maxf(size.x, size.z):  # poles and trunks
			var c := CylinderShape3D.new()
			c.radius = clampf(minf(size.x, size.z) * 0.15, 0.25, 0.6)
			c.height = minf(size.y, 4.0)
			col.shape = c
			col.position = xf.origin + Vector3(0, c.height / 2.0, 0)
		else:
			var b := BoxShape3D.new()
			b.size = Vector3(size.x * 0.9, minf(size.y, 12.0), size.z * 0.9)
			col.shape = b
			col.transform = Transform3D(xf.basis.orthonormalized(), xf.origin + Vector3(0, b.size.y / 2.0, 0))
		_body.add_child(col)


## A light object that cars knock over: a sleeping rigid body (like the cones).
func _loose(model: String, piece: int, xf: Transform3D, box: AABB, s: float) -> void:
	var body := RigidBody3D.new()
	var size := box.size * s
	body.mass = clampf(size.x * size.y * size.z * 60.0, 4.0, 60.0)
	body.can_sleep = true
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size.max(Vector3.ONE * 0.15)
	col.shape = shape
	col.position.y = size.y / 2.0
	body.add_child(col)
	var node: Node3D
	if piece < 0:
		node = Scenery.instance(DIR + model, size.y)
	else:
		node = Scenery.piece_instance(DIR + model, piece, s)
	for g in node.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).visibility_range_end = 220.0
		(g as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(node)
	_t.add_child(body)
	body.global_transform = Transform3D(xf.basis.orthonormalized(), xf.origin + Vector3(0, 0.08, 0))
	body.sleeping = true


## Draws everything batched by _add: one MultiMesh per part, model and square of the map.
func _flush() -> void:
	for key in _batches:
		var model: String = key[0]
		var piece: int = key[1]
		var shadow: bool = key[3]
		var xfs: Array = _batches[key]
		var parts: Array
		if piece < 0:
			var box: AABB = _box(model, -1)
			parts = Scenery.parts(DIR + model, box.size.y)  # own units, standing on y = 0
		else:
			parts = Scenery.pieces(DIR + model)[piece]["parts"]
		var size := _box(model, piece).size * (xfs[0] as Transform3D).basis.get_scale().y
		var vis := clampf(size.y * 30.0, 80.0, 500.0)
		shadow = shadow and size.y > 4.0 and not ("plant" in key[4])
		for part in parts:
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = part[0]
			mm.instance_count = xfs.size()
			for i in xfs.size():
				mm.set_instance_transform(i, (xfs[i] as Transform3D) * (part[1] as Transform3D))
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			mmi.visibility_range_end = vis
			mmi.name = model
			if not shadow:
				mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_t.add_child(mmi)
	_batches.clear()


# ---------- Power line ----------

## Poles about one span apart on one side of the road at `off` metres from the centre, with the
## cables of the model stretched to the next pole. Where the line would cross another stretch of
## road it stops and starts again further on.
func _power_line(side: float, off: float) -> void:
	if not Scenery.exists(DIR + POLE):
		return
	var split := _pole_meshes()
	var span: float = split[2]
	var n := _t.pts.size()
	var poles: Array = []  # Vector3 bases, null for a gap
	var last := Vector3.INF
	for k in n:
		var p := _t.pts[k] + _t._right(k) * side * off
		if last != Vector3.INF and Vector2(p.x - last.x, p.z - last.z).length() < span * 0.98:
			continue
		var ok := _t._road_dist_at(p.x, p.z) > off - 1.5 and _clear(Vector2(p.x, p.z), 0.8)
		if ok:
			p.y = _t.ground_height(p.x, p.z)
			poles.append(p)
			_occupy(Vector2(p.x, p.z), 0.8)
			last = p
		else:
			if not poles.is_empty() and poles[-1] != null:
				poles.append(null)
			last = p
	var pole_xf: Array = []
	var cable_xf: Array = []
	for i in poles.size():
		var p: Variant = poles[i]
		if p == null:
			continue
		var nxt: Variant = poles[(i + 1) % poles.size()]
		var dir: Vector3
		if nxt != null:
			dir = (nxt as Vector3) - (p as Vector3)
		else:
			var prev: Variant = poles[i - 1]
			dir = (p as Vector3) - (prev as Vector3) if prev != null else Vector3.FORWARD
		var flat := Vector3(dir.x, 0, dir.z).normalized()
		var x := Vector3.UP.cross(flat).normalized()
		pole_xf.append(Transform3D(Basis(x, Vector3.UP, flat), p))
		if nxt != null and dir.length() < span * 1.6 and absf(dir.y) < 6.0:
			cable_xf.append(Transform3D(Basis(x, Vector3.UP, dir / span), p))
	_multi(split[0], pole_xf, 350.0, false)
	_multi(split[1], cable_xf, 260.0, false)
	if _body == null:
		_body = StaticBody3D.new()
		_t.add_child(_body)
	for xf in pole_xf:
		var c := CylinderShape3D.new()
		c.radius = 0.3
		c.height = 4.0
		var col := CollisionShape3D.new()
		col.shape = c
		col.position = (xf as Transform3D).origin + Vector3(0, 2.0, 0)
		_body.add_child(col)


func _multi(mesh: Mesh, xfs: Array, vis: float, shadow: bool) -> void:
	# Grouped by squares of the map like the rest.
	var groups := {}
	for xf in xfs:
		var c := Vector2i(floori((xf as Transform3D).origin.x / CHUNK), floori((xf as Transform3D).origin.z / CHUNK))
		if not groups.has(c):
			groups[c] = []
		groups[c].append(xf)
	for c in groups:
		var list: Array = groups[c]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.visibility_range_end = vis
		if not shadow:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_t.add_child(mmi)


static var _split_cache: Array = []


## The power pole model holds a pole and the cables of one span, in one mesh: split them into a
## pole (base at the origin) and cables (starting at the origin, running along +z for `span`).
## Returns [pole mesh, cable mesh, span].
static func _pole_meshes() -> Array:
	if not _split_cache.is_empty():
		return _split_cache
	var parts := Scenery.parts(DIR + POLE, POLE_HEIGHT)
	var box: AABB = Scenery._bounds[DIR + POLE]
	var s := POLE_HEIGHT / box.size.y
	var span := box.size.z * s
	# parts are centred: the pole stands at the -z end.
	var shift := Transform3D(Basis.IDENTITY, Vector3(0, 0, span / 2.0))
	var pole := ArrayMesh.new()
	var cable := ArrayMesh.new()
	for p in parts:
		var mesh: Mesh = p[0]
		var xf: Transform3D = shift * (p[1] as Transform3D)
		for si in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(si)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in verts.size():
				verts[i] = xf * verts[i]
				if norms.size() > i:
					norms[i] = (xf.basis * norms[i]).normalized()
			arr[Mesh.ARRAY_VERTEX] = verts
			if norms.size() > 0:
				arr[Mesh.ARRAY_NORMAL] = norms
			arr[Mesh.ARRAY_TANGENT] = null
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			var a := PackedInt32Array()
			var b := PackedInt32Array()
			for t in range(0, idx.size(), 3):
				var z := (verts[idx[t]].z + verts[idx[t + 1]].z + verts[idx[t + 2]].z) / 3.0
				var target := a if z < 1.5 else b
				target.append(idx[t])
				target.append(idx[t + 1])
				target.append(idx[t + 2])
			for pair in [[pole, a], [cable, b]]:
				if (pair[1] as PackedInt32Array).is_empty():
					continue
				var copy := arr.duplicate()
				copy[Mesh.ARRAY_INDEX] = pair[1]
				(pair[0] as ArrayMesh).add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, copy)
				var m := (pair[0] as ArrayMesh)
				m.surface_set_material(m.get_surface_count() - 1, mesh.surface_get_material(si))
	_split_cache = [pole, cable, span]
	return _split_cache
