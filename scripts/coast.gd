class_name Coast
extends Mountain
## Daytime coastal road: the same kind of closed loop as the mountain pass, but stretched along
## the sea. The southern half runs a few metres above the beach with palms on the sea side, the
## northern half climbs into green hills with white houses. A lighthouse stands on a headland.
## The sea is a big transparent plane at y = 0 (SEA); the terrain under it is sand fading to blue.

const SEA := 0.0
const SHORE_GAP := 34.0  # from the most seaward stretch of road to the waterline, roughly
const BIN := 10.0  # shore line: one point every BIN metres along x

var _shore := PackedFloat32Array()  # z of the shore for each x bin (sea towards +z)
var _shore_x0 := 0.0
var _cape := Vector2.ZERO  # headland with the lighthouse


func _init() -> void:
	super()
	rng_seed = 5151
	noise_seed = 21
	road_floor = SEA + 4.5
	tree_tries = 3500
	layout_id = "costa"
	snow_line = 100000.0


func build_steps() -> Array:
	return [
		["Tracciato", _make_road_line],
		["Costa e colline", _build_terrain],
		["Mare", _build_sea],
		["Asfalto", _build_road],
		["Guardrail", _build_rails],
		["Palme e pini", _build_trees],
		["Case e faro", _build_village],
		["Erba", _build_grass],
		["Scogli e cartelli", _build_rocks],
		["Coni e segnali", func(): Scenery.dress_road(self, false)],
		["Rampe", _build_ramps],
		["Traiettoria", _build_racing_line],
	]


# ---------- Road line and shore ----------

func _loop_point(th: float) -> Vector2:
	var r := 330.0 + 70.0 * sin(3.0 * th + 1.1) + 35.0 * sin(5.0 * th + 0.4) + 15.0 * sin(7.0 * th + 2.0)
	return Vector2(1.3 * r * cos(th), 0.85 * r * sin(th))


## Lowest along the sea (the southern half, +z), up into the hills on the far side.
func _loop_grade(u: float) -> float:
	return -0.055 * cos(u) + 0.025 * sin(3.0 * u + 0.7)


func _make_road_line() -> void:
	super()
	# The shore follows the most seaward stretch of road SHORE_GAP metres further out, smoothed;
	# past the ends of the loop it curves back inland into two bays.
	var lo := INF
	var hi := -INF
	for p in pts:
		lo = minf(lo, p.x)
		hi = maxf(hi, p.x)
	_shore_x0 = lo - MARGIN - 200.0
	var bins := ceili((hi + MARGIN + 200.0 - _shore_x0) / BIN) + 1
	var raw := PackedFloat32Array()
	raw.resize(bins)
	raw.fill(-INF)
	for p in pts:
		var b := clampi(roundi((p.x - _shore_x0) / BIN), 0, bins - 1)
		raw[b] = maxf(raw[b], p.z)
	var first := -1
	var last := -1
	for b in bins:
		if raw[b] > -INF:
			if first < 0:
				first = b
			last = b
	for b in bins:
		if b < first:
			raw[b] = raw[first] - (first - b) * BIN * 0.35
		elif b > last:
			raw[b] = raw[last] - (b - last) * BIN * 0.35
		elif raw[b] == -INF:
			raw[b] = raw[b - 1]
	_shore.resize(bins)
	for b in bins:
		var sum := 0.0
		var cnt := 0
		for j in range(b - 6, b + 7):
			if j >= 0 and j < bins:
				sum += raw[j]
				cnt += 1
		_shore[b] = sum / cnt + SHORE_GAP
	# Headland: out to sea from the most seaward point of the road.
	var best := 0
	for k in pts.size():
		if pts[k].z > pts[best].z:
			best = k
	_cape = Vector2(pts[best].x + 40.0, pts[best].z + SHORE_GAP + 70.0)


func _shore_z(x: float) -> float:
	var f := clampf((x - _shore_x0) / BIN, 0.0, _shore.size() - 1.001)
	var i := int(f)
	return lerpf(_shore[i], _shore[i + 1], f - i)


func _natural(x: float, z: float) -> float:
	var s := z - _shore_z(x)  # metres past the waterline (negative: inland)
	var inland := maxf(14.0 + _noise.get_noise_2d(x, z) * 34.0, 5.0) + maxf(0.0, -s - 260.0) * 0.35
	var h := lerpf(inland, SEA - 3.0 - s * 0.06, smoothstep(-45.0, 25.0, s))
	# The headland: a rocky hump rising out of the water.
	var dc := Vector2(x, z).distance_to(_cape)
	h = maxf(h, SEA + 9.0 - dc * dc * 0.0045 + _noise.get_noise_2d(x * 4.0, z * 4.0) * 2.0)
	return h


func _terrain_material() -> Material:
	var mat := super()
	mat.set_shader_parameter("sand_albedo", _tex("aerial_beach_01", "diff"))
	mat.set_shader_parameter("sand_top", SEA + 2.2)
	mat.set_shader_parameter("sea_level", SEA)
	mat.set_shader_parameter("grass_tint", Vector3(0.8, 0.92, 0.55))
	return mat


func _build_sea() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(7000, 7000)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/sea.gdshader")
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(pts[start_i].x, SEA, pts[start_i].z)
	add_child(mi)


# ---------- Vegetation ----------

## Pines and birches only up in the hills; the shore gets palms.
func _plant_ok(x: float, z: float, h: float) -> bool:
	return h > SEA + 2.5 and (h > SEA + 10.0 or _rng.randf() < 0.15) and z < _shore_z(x) - 5.0


func _build_trees() -> void:
	super()
	_build_palms()


## Palm: a curved trunk and a crown of drooping fronds, all procedural and low-poly.
func _palm_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 9
	var sides := 7
	var height := 9.0
	var rings: Array = []
	for i in segs + 1:
		var t := float(i) / segs
		var c := Vector3(1.4 * t * t, height * t, 0)  # leans and bends a little
		var r := lerpf(0.3, 0.17, t)
		var ring: Array[Vector3] = []
		for j in sides:
			var a := TAU * j / sides
			ring.append(c + Vector3(cos(a) * r, 0, sin(a) * r))
		rings.append(ring)
	for i in segs:
		var shade := 0.8 if i % 2 == 0 else 1.0  # bands of old leaf scars
		for j in sides:
			var j2 := (j + 1) % sides
			var a: Vector3 = rings[i][j]
			var b: Vector3 = rings[i][j2]
			var c: Vector3 = rings[i + 1][j]
			var d: Vector3 = rings[i + 1][j2]
			for v in [a, c, b, b, c, d]:
				st.set_color(Color(0.5 * shade, 0.4 * shade, 0.29 * shade))
				st.add_vertex(v)
	st.generate_normals()
	var bark := StandardMaterial3D.new()
	bark.vertex_color_use_as_albedo = true
	bark.roughness = 0.95
	st.set_material(bark)
	st.commit(mesh)

	# Fronds: a folded strip along a drooping spine, wide in the middle, pointed at the tip.
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(1.4, height, 0)
	var fronds := 9
	for f in fronds:
		var a := TAU * f / fronds + 0.3 * sin(f * 2.3)
		var dir := Vector3(cos(a), 0, sin(a))
		var side := dir.cross(Vector3.UP)
		var lift := 0.9 + 0.5 * sin(f * 1.7)
		var steps := 8
		var prev_c := top
		var prev_l := top
		var prev_r := top
		for s in range(1, steps + 1):
			var t := float(s) / steps
			var c := top + dir * 4.8 * t + Vector3(0, lift * t - 3.2 * t * t, 0)
			var w := 1.05 * sin(PI * minf(t * 1.15, 1.0))
			var droop := Vector3(0, -0.45 * w, 0)  # V fold, edges hang lower than the spine
			var l := c - side * w + droop
			var r := c + side * w + droop
			var col := Color(0.16, 0.42, 0.13).lerp(Color(0.38, 0.62, 0.18), t)
			for v in [prev_c, c, prev_l, prev_l, c, l, prev_c, prev_r, c, prev_r, r, c]:
				st.set_color(col)
				st.add_vertex(v)
			prev_c = c
			prev_l = l
			prev_r = r
	st.generate_normals()
	var leaves := StandardMaterial3D.new()
	leaves.vertex_color_use_as_albedo = true
	leaves.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaves.roughness = 0.8
	st.set_material(leaves)
	st.commit(mesh)
	return mesh


func _build_palms() -> void:
	var mesh := _palm_mesh()
	var xfs: Array[Transform3D] = []
	var trunks: Array[Vector3] = []
	var n := pts.size()
	# A row along the sea side of the road wherever it runs near the beach.
	for k in range(0, n, 9):
		var p := pts[k]
		if _shore_z(p.x) - p.z > SHORE_GAP + 45.0:
			continue
		var r := _right(k)
		var side := 1.0 if r.z > 0.0 else -1.0  # towards the sea
		var q := p + r * side * (RAIL_OFFSET + _rng.randf_range(2.5, 5.0)) + tangents[k] * _rng.randf_range(-3.0, 3.0)
		var h := ground_height(q.x, q.z)
		if h < SEA + 0.3:
			continue
		xfs.append(_palm_xf(Vector3(q.x, h - 0.1, q.z)))
		trunks.append(Vector3(q.x, h, q.z))
	# Clumps on the beaches and the low ground behind them.
	var size := (_gw - 1) * CELL
	for i in 5000:
		var x := _min.x + _rng.randf() * size
		var z := _min.y + _rng.randf() * size
		var h := ground_height(x, z)
		if h < SEA + 0.6 or h > SEA + 14.0:
			continue
		var d := _road_dist_at(x, z)
		if d < RAIL_OFFSET + 5.0 or d > 260.0:
			continue
		if _noise.get_noise_2d(x * 2.0, z * 2.0 + 300.0) < 0.0:
			continue
		xfs.append(_palm_xf(Vector3(x, h - 0.1, z)))
		if d < 40.0:
			trunks.append(Vector3(x, h, z))
	if Scenery.exists("coast_coconut_palm"):
		# Real palms (Sketchfab, CC-BY): double coconut palms and tall single date palms.
		var a: Array = []
		var b: Array = []
		for i in xfs.size():
			(a if i % 3 != 0 else b).append(xfs[i])
		Scenery.scatter(self, "coast_coconut_palm", 10.5, a, 650.0)
		Scenery.scatter(self, "coast_arabic_palm", 13.0, b, 650.0)
	else:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = xfs.size()
		for i in xfs.size():
			mm.set_instance_transform(i, xfs[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		add_child(mmi)
	var body := StaticBody3D.new()
	add_child(body)
	for t in trunks:
		var shape := CylinderShape3D.new()
		shape.radius = 0.4
		shape.height = 3.0
		var col := CollisionShape3D.new()
		col.shape = shape
		col.position = t + Vector3(0, 1.5, 0)
		body.add_child(col)


func _palm_xf(at: Vector3) -> Transform3D:
	var s := _rng.randf_range(0.85, 1.3)
	return Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s)), at)


# ---------- Houses and lighthouse ----------

func _build_village() -> void:
	var walls := [
		CarModel.mat(Color(0.96, 0.94, 0.9), Color.BLACK, 0.0, 0.0, 0.9),
		CarModel.mat(Color(0.98, 0.86, 0.62), Color.BLACK, 0.0, 0.0, 0.9),
		CarModel.mat(Color(0.95, 0.72, 0.6), Color.BLACK, 0.0, 0.0, 0.9),
		CarModel.mat(Color(0.75, 0.86, 0.95), Color.BLACK, 0.0, 0.0, 0.9),
	]
	var roof := CarModel.mat(Color(0.75, 0.32, 0.18), Color.BLACK, 0.0, 0.0, 0.8)
	var shutters := CarModel.mat(Color(0.15, 0.45, 0.4), Color.BLACK, 0.0, 0.0, 0.8)
	var body := StaticBody3D.new()
	add_child(body)
	var placed := 0
	var tries := 0
	while placed < 40 and tries < 4000:
		tries += 1
		var k := _rng.randi_range(0, pts.size() - 1)
		var side := 1.0 if _rng.randf() < 0.5 else -1.0
		var off := RAIL_OFFSET + _rng.randf_range(12.0, 70.0)
		var p := pts[k] + _right(k) * side * off
		var h := ground_height(p.x, p.z)
		if h < SEA + 3.0 or _road_dist_at(p.x, p.z) < RAIL_OFFSET + 9.0:
			continue
		var w := _rng.randf_range(7.0, 11.0)
		var dpt := _rng.randf_range(6.0, 9.0)
		var floors := _rng.randi_range(1, 3)
		var hgt := floors * 3.2
		var corners := [Vector2(-w, -dpt), Vector2(w, -dpt), Vector2(-w, dpt), Vector2(w, dpt)]
		var lo := INF
		var hi := -INF
		var basis := Basis.looking_at(-_right(k) * side, Vector3.UP)  # front faces the road
		for c in corners:
			var q := p + basis * Vector3(c.x / 2.0, 0, c.y / 2.0)
			var g := ground_height(q.x, q.z)
			lo = minf(lo, g)
			hi = maxf(hi, g)
		if hi - lo > 2.5:
			continue  # too steep to build on
		var house := Node3D.new()
		add_child(house)
		house.transform = Transform3D(basis, Vector3(p.x, lo, p.z))
		var base := hi - lo
		CarModel.box(house, Vector3(w, hgt + base, dpt), Vector3(0, (hgt + base) / 2.0, 0), walls[_rng.randi() % walls.size()])
		var prism := PrismMesh.new()
		prism.size = Vector3(w + 0.8, 2.2, dpt + 0.8)
		var rmi := MeshInstance3D.new()
		rmi.mesh = prism
		rmi.material_override = roof
		rmi.position = Vector3(0, hgt + base + 1.1, 0)
		house.add_child(rmi)
		# Windows with green shutters on the front.
		for f in floors:
			for wx in [-w * 0.28, w * 0.28]:
				CarModel.box(house, Vector3(1.4, 1.5, 0.12), Vector3(wx, base + f * 3.2 + 1.7, -dpt / 2.0 - 0.05), shutters)
		var shape := BoxShape3D.new()
		shape.size = Vector3(w, hgt + base, dpt)
		var col := CollisionShape3D.new()
		col.shape = shape
		col.transform = Transform3D(basis, Vector3(p.x, lo + (hgt + base) / 2.0, p.z))
		body.add_child(col)
		for g in house.find_children("*", "GeometryInstance3D", true, false):
			(g as GeometryInstance3D).visibility_range_end = 700.0
		placed += 1
	_build_lighthouse()


func _build_lighthouse() -> void:
	var g := ground_height(_cape.x, _cape.y)
	if Scenery.exists("coast_lighthouse_2"):
		var lhm := Scenery.instance("coast_lighthouse_2", 26.0)
		lhm.position = Vector3(_cape.x, g - 0.8, _cape.y)
		lhm.rotation.y = _rng.randf() * TAU
		add_child(lhm)
		var lbody := StaticBody3D.new()
		var lshape := CylinderShape3D.new()
		lshape.radius = 6.0
		lshape.height = 20.0
		var lcol := CollisionShape3D.new()
		lcol.shape = lshape
		lcol.position = lhm.position + Vector3(0, 10, 0)
		lbody.add_child(lcol)
		add_child(lbody)
		_build_beach()
		return
	var lh := Node3D.new()
	lh.position = Vector3(_cape.x, g - 0.5, _cape.y)
	add_child(lh)
	var white := CarModel.mat(Color(0.97, 0.97, 0.95), Color.BLACK, 0.0, 0.0, 0.8)
	var red := CarModel.mat(Color(0.85, 0.12, 0.1), Color.BLACK, 0.0, 0.0, 0.8)
	for i in 6:
		var cyl := CylinderMesh.new()
		cyl.height = 3.5
		cyl.bottom_radius = 3.0 - i * 0.3
		cyl.top_radius = 3.0 - (i + 1) * 0.3
		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		mi.material_override = red if i % 2 == 1 else white
		mi.position.y = 1.75 + i * 3.5
		lh.add_child(mi)
	var lamp := CylinderMesh.new()
	lamp.height = 2.4
	lamp.top_radius = 1.3
	lamp.bottom_radius = 1.3
	var lmi := MeshInstance3D.new()
	lmi.mesh = lamp
	lmi.material_override = CarModel.mat(Color(1, 0.95, 0.7), Color(1, 0.9, 0.5), 2.5)
	lmi.position.y = 22.2
	lh.add_child(lmi)
	var cap := CylinderMesh.new()
	cap.height = 1.4
	cap.top_radius = 0.2
	cap.bottom_radius = 1.8
	var cmi := MeshInstance3D.new()
	cmi.mesh = cap
	cmi.material_override = red
	cmi.position.y = 24.1
	lh.add_child(cmi)


## Life on the beaches: rowing boats pulled up on the sand, umbrellas, and a wooden pier out
## into the sea near the most seaward stretch of road.
func _build_beach() -> void:
	var size := (_gw - 1) * CELL
	var boats := []
	var umbrellas := []
	for i in 4000:
		var x := _min.x + _rng.randf() * size
		var z := _min.y + _rng.randf() * size
		var h := ground_height(x, z)
		if h < SEA + 0.2 or h > SEA + 1.6:
			continue
		var d := _road_dist_at(x, z)
		if d < RAIL_OFFSET + 4.0 or d > 220.0:
			continue
		var xf := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), Vector3(x, h - 0.05, z))
		if _rng.randf() < 0.25:
			if boats.size() < 14:
				boats.append(xf)
		elif umbrellas.size() < 70 and _noise.get_noise_2d(x * 3.0, z * 3.0) > 0.05:
			umbrellas.append(xf)
	if Scenery.exists("coast_rowboat"):
		var half := boats.size() / 2
		Scenery.scatter(self, "coast_rowboat", 1.2, boats.slice(0, half), 300.0)
		Scenery.scatter(self, "coast_wooden_boat", 1.0, boats.slice(half), 300.0)
	if Scenery.exists("coast_beach_umbrella"):
		Scenery.scatter(self, "coast_beach_umbrella", 2.6, umbrellas, 260.0)
	# Pier: dock pieces in a line straight out to sea from the shore below the road.
	if Scenery.exists("coast_old_pier"):
		var best := 0
		for k in pts.size():
			if pts[k].z > pts[best].z:
				best = k
		var x := pts[(best + pts.size() / 6) % pts.size()].x
		var z0 := _shore_z(x) - 6.0
		var xfs := []
		var box: AABB = Scenery.pieces("coast_old_pier")[0]["box"]
		var s := 3.2 / box.size.x
		var step := box.size.z * s
		var zz := z0
		while zz < z0 + 70.0:
			xfs.append(Transform3D(Basis.from_scale(Vector3.ONE * s), Vector3(x, SEA - 1.2, zz)))
			zz += step * 0.98
		Scenery.scatter_piece(self, "coast_old_pier", 0, xfs, 500.0)


# ---------- Track interface ----------

func setup_environment(parent: Node) -> void:
	super(parent)
	for c in parent.get_children():
		if c is WorldEnvironment:
			var env := (c as WorldEnvironment).environment
			env.ambient_light_energy = 0.95
			env.fog_light_color = Color(0.62, 0.76, 0.9)
			env.fog_density = 0.0004
			env.adjustment_saturation = 1.2
			env.adjustment_brightness = 1.05
		elif c is DirectionalLight3D:
			var sun := c as DirectionalLight3D
			# High over the sea, so the water shines while driving along the beach.
			sun.rotation_degrees = Vector3(-50, 160, 0)
			sun.light_color = Color(1.0, 0.95, 0.84)
			sun.light_energy = 1.35


func menu_camera(t: float) -> Array:
	var c := pts[start_i]
	return [c + Vector3(sin(t) * 380, 120, cos(t) * 380), c + Vector3(0, 10, 0)]
