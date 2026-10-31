class_name Mountain
extends Track
## Daytime mountain pass: a closed 2.7 km road that winds, climbs and drops across hills, with
## guardrails on both sides, rock cuttings where it runs into the slope and pine woods around.
## Everything is generated from fixed seeds, so the track is the same on every run.
## The road is a list of samples every SAMPLE_STEP metres; the AI follows it in either direction.

const SAMPLE_STEP := 2.0
const ROAD_HALF := 6.0  # asphalt: two 6 m lanes
const VERGE := 2.5  # gravel strip between asphalt and guardrail
const RAIL_OFFSET := ROAD_HALF + VERGE + 0.1
const LANE := 3.0  # traffic drives this far right of the centre line
const CELL := 4.0  # terrain grid
const CHUNK := 32  # terrain cells per chunk side
const BLEND := 44.0  # terrain meets the natural ground this far from the road centre
const MARGIN := 280.0  # terrain beyond the road
const GRIP := 0.85  # assumed tyre grip for corner speeds (fraction of g)
const DECEL := 8.0  # braking used to plan corner speeds, m/s^2
const PATH_STRIDE := 10  # race path: one point every PATH_STRIDE samples (20 m)
const CHECKPOINTS := 8

## Tree models (Quaternius textured trees, CC0) and how often each is picked.
const TREES := {"Pine_1": 3, "Pine_2": 3, "Pine_3": 3, "Pine_5": 3, "Birch_1": 1, "Birch_3": 1}
const TREE_DIR := "res://assets/props/trees/"
## Realistic conifers from assets/scenery (see Scenery). All of them line the road; the light
## first one also fills the far slopes. Used instead of TREES when present.
const SCENERY_TREES := ["pine", "spruce", "scots_pine", "pine_scan"]
## Grass clump textures (Yughues grass packs, CC0).
const GRASS := ["grass_01", "grass_02", "grass_04"]
const TEX := "res://assets/materials/%s/%s_%s_1k.jpg"

var pts: Array[Vector3] = []  # road centre, every SAMPLE_STEP m, closed loop
var tangents: Array[Vector3] = []
var limits: PackedFloat32Array  # corner speed at each sample, m/s
var line_off := PackedFloat32Array()  # racing line: offset to the right of the centre at each sample
var line_speed := PackedFloat32Array()  # speed along the racing line, braking and accelerating
var start_i := 0
var _buckets := {}
var _lane_curve: Curve3D
var _rng := RandomNumberGenerator.new()
var _noise := FastNoiseLite.new()
var _min := Vector2.ZERO  # terrain grid origin (x, z)
var _gw := 0  # terrain vertices per side
var _heights := PackedFloat32Array()
var _road_d := PackedFloat32Array()  # distance from each terrain vertex to the road centre
## Height of the lowest point of the road; -INF keeps the loop where the grade profile puts it.
var road_floor := -INF
var rng_seed := 4242
var noise_seed := 7
var tree_tries := 9000


func _init() -> void:
	view_distance = 1600.0
	extent = 1200.0


func build() -> void:
	for step in build_steps():
		(step[1] as Callable).call()


func build_steps() -> Array:
	return [
		["Tracciato", _make_road_line],
		["Montagne", _build_terrain],
		["Asfalto", _build_road],
		["Guardrail", _build_rails],
		["Alberi", _build_trees],
		["Erba", _build_grass],
		["Rocce e cartelli", _build_rocks],
		["Case, coni e segnali", func(): Scenery.dress_road(self, true)],
		["Rampe", _build_ramps],
		["Traiettoria", _build_racing_line],
	]


# ---------- Road line ----------

func _make_road_line() -> void:
	_rng.seed = rng_seed
	_noise.seed = noise_seed
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.0035
	_noise.fractal_octaves = 4
	# Closed loop around the origin: the radius wobbles to make bends, the height follows a grade
	# profile (at most about 12 %) that adds up to zero over the lap.
	var raw: Array[Vector2] = []
	var n := 1400
	for i in n:
		raw.append(_loop_point(TAU * i / n))
	# Resample evenly.
	var total := 0.0
	for i in n:
		total += raw[i].distance_to(raw[(i + 1) % n])
	var count := int(total / SAMPLE_STEP)
	var step := total / count
	var flat: Array[Vector2] = []
	var seg := 0
	var seg_start := 0.0
	for k in count:
		var s := k * step
		while seg < n - 1 and seg_start + raw[seg].distance_to(raw[(seg + 1) % n]) < s:
			seg_start += raw[seg].distance_to(raw[(seg + 1) % n])
			seg += 1
		var a := raw[seg]
		var b := raw[(seg + 1) % n]
		flat.append(a.lerp(b, (s - seg_start) / a.distance_to(b)))
	var h := 0.0
	for k in count:
		var u := TAU * k / count
		pts.append(Vector3(flat[k].x, h, flat[k].y))
		h += _loop_grade(u) * step
	# Spread the tiny closing error over the lap, then lift the whole loop to the level's base.
	var lowest := INF
	for k in count:
		pts[k].y -= h * k / count
		lowest = minf(lowest, pts[k].y)
	if road_floor > -INF:
		for k in count:
			pts[k].y += road_floor - lowest
	for k in count:
		tangents.append((pts[(k + 1) % count] - pts[(k - 1 + count) % count]).normalized())
	# Corner speed from the curvature over +-10 m.
	limits.resize(count)
	for k in count:
		var t0 := tangents[(k - 5 + count) % count]
		var t1 := tangents[(k + 5) % count]
		var ang := absf(Vector2(t0.x, t0.z).angle_to(Vector2(t1.x, t1.z)))
		var radius := 10.0 * step / maxf(ang, 0.0001)
		limits[k] = sqrt(GRIP * 9.8 * radius)
	for k in count:
		var key := _bucket_key(pts[k])
		if not _buckets.has(key):
			_buckets[key] = []
		_buckets[key].append(k)
	# Start on the straightest stretch, so the grid and the first metres are easy.
	var best := -INF
	for k in range(0, count, 5):
		var worst := INF
		for j in range(-20, 50):
			worst = minf(worst, limits[(k + j + count) % count])
		if worst > best:
			best = worst
			start_i = k


## Point of the loop (seen from above) at angle th: the radius wobbles to make bends.
func _loop_point(th: float) -> Vector2:
	var r := 330.0 + 110.0 * sin(3.0 * th + 0.5) + 45.0 * sin(5.0 * th + 1.3) + 20.0 * sin(8.0 * th + 0.2)
	return Vector2(r * cos(th), r * sin(th))


## Road grade (rise per metre) at u, from 0 to TAU round the lap. Must average to zero.
func _loop_grade(u: float) -> float:
	return 0.085 * sin(2.0 * u) + 0.04 * sin(5.0 * u + 1.0)


func _bucket_key(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / 40.0), floori(p.z / 40.0))


## Index of the road sample nearest to p.
func nearest(p: Vector3) -> int:
	var key := _bucket_key(p)
	var best := -1
	var best_d := INF
	for r in 3:
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if r > 0 and absi(dx) != r and absi(dz) != r:
					continue
				var b: Variant = _buckets.get(key + Vector2i(dx, dz))
				if b == null:
					continue
				for k in b:
					var d := Vector2(pts[k].x - p.x, pts[k].z - p.z).length_squared()
					if d < best_d:
						best_d = d
						best = k
		if best >= 0:
			return best
	for k in pts.size():
		var d := Vector2(pts[k].x - p.x, pts[k].z - p.z).length_squared()
		if d < best_d:
			best_d = d
			best = k
	return best


func _right(k: int) -> Vector3:
	var t := tangents[k]
	return Vector3(t.x, 0, t.z).normalized().cross(Vector3.UP)


# ---------- Terrain ----------

func _natural(x: float, z: float) -> float:
	var r := Vector2(x, z).length()
	return 16.0 + _noise.get_noise_2d(x, z) * 48.0 + maxf(0.0, r - 540.0) * 0.45


func _build_terrain() -> void:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in pts:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.z))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.z))
	var cells := ceili(maxf(hi.x - lo.x, hi.y - lo.y) / CELL + 2.0 * MARGIN / CELL)
	cells = ceili(float(cells) / CHUNK) * CHUNK
	_gw = cells + 1
	_min = (lo + hi) / 2.0 - Vector2.ONE * cells * CELL / 2.0
	_heights.resize(_gw * _gw)
	_road_d.resize(_gw * _gw)
	_road_d.fill(INF)
	var road_h := PackedFloat32Array()
	road_h.resize(_gw * _gw)
	# Distance to the road and road height, splatted around every other sample.
	var reach := ceili(BLEND / CELL)
	for k in range(0, pts.size(), 2):
		var p := pts[k]
		var cx := roundi((p.x - _min.x) / CELL)
		var cz := roundi((p.z - _min.y) / CELL)
		for gz in range(maxi(cz - reach, 0), mini(cz + reach, _gw - 1) + 1):
			for gx in range(maxi(cx - reach, 0), mini(cx + reach, _gw - 1) + 1):
				var i := gz * _gw + gx
				var d := Vector2(_min.x + gx * CELL - p.x, _min.y + gz * CELL - p.z).length()
				if d < _road_d[i]:
					_road_d[i] = d
					road_h[i] = p.y
	var flat_r := RAIL_OFFSET + 1.5
	for gz in _gw:
		for gx in _gw:
			var i := gz * _gw + gx
			var nat := _natural(_min.x + gx * CELL, _min.y + gz * CELL)
			var d := _road_d[i]
			if d == INF:
				_heights[i] = nat
			else:
				var bed := road_h[i] - 0.4
				_heights[i] = lerpf(bed, nat, smoothstep(flat_r, BLEND, d))

	var mat := _terrain_material()
	var body := StaticBody3D.new()
	add_child(body)
	var chunks := cells / CHUNK
	for cz in chunks:
		for cx in chunks:
			var mesh := _terrain_chunk(cx * CHUNK, cz * CHUNK, mat)
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			add_child(mi)
			var col := CollisionShape3D.new()
			col.shape = mesh.create_trimesh_shape()
			body.add_child(col)


func _terrain_material() -> Material:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/terrain.gdshader")
	mat.set_shader_parameter("grass_albedo", _tex("aerial_grass_rock", "diff"))
	mat.set_shader_parameter("rock_albedo", _tex("rock_face", "diff"))
	mat.set_shader_parameter("gravel_albedo", _tex("rocky_terrain_02", "diff"))
	return mat


func _terrain_chunk(x0: int, z0: int, mat: Material) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var idx := PackedInt32Array()
	var side := CHUNK + 1
	for gz in range(z0, z0 + side):
		for gx in range(x0, x0 + side):
			var i := gz * _gw + gx
			verts.append(Vector3(_min.x + gx * CELL, _heights[i], _min.y + gz * CELL))
			var hl := _heights[gz * _gw + maxi(gx - 1, 0)]
			var hr := _heights[gz * _gw + mini(gx + 1, _gw - 1)]
			var hd := _heights[maxi(gz - 1, 0) * _gw + gx]
			var hu := _heights[mini(gz + 1, _gw - 1) * _gw + gx]
			normals.append(Vector3(hl - hr, 2.0 * CELL, hd - hu).normalized())
			var near := 1.0 - smoothstep(RAIL_OFFSET + 2.0, RAIL_OFFSET + 8.0, _road_d[i])
			colors.append(Color(near, 0, 0))
	for z in CHUNK:
		for x in CHUNK:
			var a := z * side + x
			var b := a + 1
			var c := a + side
			var d := c + 1
			for v in [a, b, c, b, d, c]:
				idx.append(v)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, mat)
	return mesh


## Terrain height at (x, z), bilinear between grid vertices.
func ground_height(x: float, z: float) -> float:
	var fx := clampf((x - _min.x) / CELL, 0.0, _gw - 1.001)
	var fz := clampf((z - _min.y) / CELL, 0.0, _gw - 1.001)
	var ix := int(fx)
	var iz := int(fz)
	var tx := fx - ix
	var tz := fz - iz
	var h00 := _heights[iz * _gw + ix]
	var h10 := _heights[iz * _gw + ix + 1]
	var h01 := _heights[(iz + 1) * _gw + ix]
	var h11 := _heights[(iz + 1) * _gw + ix + 1]
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)


func _road_dist_at(x: float, z: float) -> float:
	var gx := clampi(roundi((x - _min.x) / CELL), 0, _gw - 1)
	var gz := clampi(roundi((z - _min.y) / CELL), 0, _gw - 1)
	return _road_d[gz * _gw + gx]


func _tex(folder: String, kind: String) -> Texture2D:
	var path := TEX % [folder, folder, kind]
	return load(path) if ResourceLoader.exists(path) else null


func _pbr(folder: String) -> BaseMaterial3D:
	var m := ORMMaterial3D.new()
	m.albedo_texture = _tex(folder, "diff")
	m.orm_texture = _tex(folder, "arm")
	m.normal_enabled = true
	m.normal_texture = _tex(folder, "nor_gl")
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


# ---------- Road, verges, markings ----------

func _build_road() -> void:
	# Ribbons across the road, from the left guardrail to the right one: (lateral offset, u).
	var asphalt := _ribbon([-ROAD_HALF, ROAD_HALF], 0.0, 8.0)
	asphalt.surface_set_material(0, _pbr("asphalt_02"))
	var verge_l := _ribbon([-RAIL_OFFSET, -ROAD_HALF], -0.03, 4.0)
	var verge_r := _ribbon([ROAD_HALF, RAIL_OFFSET], -0.03, 4.0)
	var gravel := _pbr("clean_asphalt")
	gravel.albedo_color = Color(1.25, 1.22, 1.15)
	verge_l.surface_set_material(0, gravel)
	verge_r.surface_set_material(0, gravel)
	var body := StaticBody3D.new()
	add_child(body)
	for m in [asphalt, verge_l, verge_r]:
		var mi := MeshInstance3D.new()
		mi.mesh = m
		add_child(mi)
		var col := CollisionShape3D.new()
		col.shape = (m as ArrayMesh).create_trimesh_shape()
		body.add_child(col)
	# Skirts under the outer edges, so embankments never show a gap under the road.
	for side: float in [-1.0, 1.0]:
		var skirt := _skirt(side * RAIL_OFFSET)
		var skirt_mat := gravel.duplicate() as BaseMaterial3D
		skirt_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		skirt.surface_set_material(0, skirt_mat)
		var smi := MeshInstance3D.new()
		smi.mesh = skirt
		add_child(smi)
	_markings()


## Strip along the whole loop between two lateral offsets. Texture repeats every `tile` metres.
func _ribbon(across: Array, dy: float, tile: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := pts.size()
	var a: float = across[0]
	var b: float = across[1]
	for k in n + 1:
		var i := k % n
		var r := _right(i)
		var v := k * SAMPLE_STEP / tile
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(a / tile, v))
		st.add_vertex(pts[i] + r * a + Vector3(0, dy, 0))
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(b / tile, v))
		st.add_vertex(pts[i] + r * b + Vector3(0, dy, 0))
	for k in n:
		var i0 := k * 2
		# Left edge, right edge; clockwise seen from above.
		st.add_index(i0)
		st.add_index(i0 + 2)
		st.add_index(i0 + 1)
		st.add_index(i0 + 1)
		st.add_index(i0 + 2)
		st.add_index(i0 + 3)
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


func _skirt(off: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := pts.size()
	for k in n + 1:
		var i := k % n
		var p := pts[i] + _right(i) * off
		st.set_uv(Vector2(k * SAMPLE_STEP / 4.0, 0))
		st.add_vertex(p + Vector3(0, -0.03, 0))
		st.set_uv(Vector2(k * SAMPLE_STEP / 4.0, 0.5))
		st.add_vertex(p + Vector3(0, -2.0, 0))
	for k in n:
		var i0 := k * 2
		# Drawn with culling off, so one winding shows from both sides.
		for tri in [[i0, i0 + 2, i0 + 1], [i0 + 1, i0 + 2, i0 + 3]]:
			for v in tri:
				st.add_index(v)
	st.generate_normals()
	return st.commit()


func _markings() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := pts.size()
	var lift := Vector3(0, 0.015, 0)
	for k in n:
		var k2 := (k + 1) % n
		var lines: Array[float] = [-ROAD_HALF + 0.35, ROAD_HALF - 0.35]
		if k % 5 < 2:
			lines.append(0.0)  # dashed centre line: 4 m painted, 6 m gap
		for off in lines:
			var w := 0.08
			var a0 := pts[k] + _right(k) * (off - w) + lift
			var a1 := pts[k] + _right(k) * (off + w) + lift
			var b0 := pts[k2] + _right(k2) * (off - w) + lift
			var b1 := pts[k2] + _right(k2) * (off + w) + lift
			for v in [a0, b0, a1, a1, b0, b1]:
				st.set_normal(Vector3.UP)
				st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = CarModel.mat(Color(0.92, 0.92, 0.88), Color.BLACK, 0.0, 0.0, 0.5)
	add_child(mi)


# ---------- Guardrails ----------

func _build_rails() -> void:
	# Straight 4 m sections on both sides; each one can be torn off by a hard hit (GuardRails).
	var steel := CarModel.mat(Color(0.72, 0.74, 0.76), Color.BLACK, 0.0, 0.85, 0.35)
	var n := pts.size()
	var sections := []
	for side: float in [-1.0, 1.0]:
		for k in range(0, n, 2):
			var k2 := (k + 2) % n
			sections.append([pts[k] + _right(k) * side * RAIL_OFFSET, pts[k2] + _right(k2) * side * RAIL_OFFSET])
	var rails := GuardRails.new()
	add_child(rails)
	rails.build(sections, steel)


# ---------- Trees and rocks ----------

func _pine_mesh() -> ArrayMesh:
	var bark := CarModel.mat(Color(0.28, 0.2, 0.14), Color.BLACK, 0.0, 0.0, 0.95)
	var needles := CarModel.mat(Color(0.11, 0.25, 0.12), Color.BLACK, 0.0, 0.0, 0.9)
	needles.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mesh := ArrayMesh.new()
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.18
	trunk.bottom_radius = 0.3
	trunk.height = 3.0
	trunk.radial_segments = 6
	trunk.rings = 1
	var arr := trunk.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for i in v.size():
		v[i].y += 1.5
	arr[Mesh.ARRAY_VERTEX] = v
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mesh.surface_set_material(0, bark)
	# Three stacked cones of needles.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var layers := [[2.0, 2.6, 4.2], [4.2, 2.0, 3.6], [6.0, 1.4, 3.2]]  # base height, radius, cone height
	for l in layers:
		var base: float = l[0]
		var rad: float = l[1]
		var h: float = l[2]
		var segs := 7
		for s in segs:
			var a0 := TAU * s / segs
			var a1 := TAU * (s + 1) / segs
			var p0 := Vector3(cos(a0) * rad, base, sin(a0) * rad)
			var p1 := Vector3(cos(a1) * rad, base, sin(a1) * rad)
			var top := Vector3(0, base + h, 0)
			st.add_vertex(p0)
			st.add_vertex(top)
			st.add_vertex(p1)
			st.add_vertex(p1)
			st.add_vertex(Vector3(0, base, 0))
			st.add_vertex(p0)
	st.generate_normals()
	st.commit(mesh)
	mesh.surface_set_material(1, needles)
	return mesh


## Tree meshes with the model's own transform baked in: {name: [mesh, transform]}. Empty if the
## models are missing; the procedural pine is used then.
func _tree_models() -> Dictionary:
	var out := {}
	var leaves_mats := {}
	for tname in TREES:
		var path: String = TREE_DIR + tname + ".fbx"
		if not ResourceLoader.exists(path):
			continue
		var scene := (load(path) as PackedScene).instantiate() as Node3D
		var mi := scene.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		var xf := mi.transform
		var n := mi.get_parent() as Node3D
		while n != scene:
			xf = n.transform * xf
			n = n.get_parent() as Node3D
		var mesh := mi.mesh.duplicate() as ArrayMesh
		var birch: bool = tname.begins_with("Birch")
		var bark := StandardMaterial3D.new()
		bark.albedo_texture = load(TREE_DIR + ("Birch_Bark.png" if birch else "Tree_Bark.jpg"))
		bark.roughness = 0.95
		var leaf_tex: String = "Birch_Leaves_Green.png" if birch else "Pine_Leaves.png"
		if not leaves_mats.has(leaf_tex):
			var leaves := StandardMaterial3D.new()
			leaves.albedo_texture = load(TREE_DIR + leaf_tex)
			# Darker, less saturated than the cartoon texture, closer to real conifers.
			leaves.albedo_color = Color(0.5, 0.66, 0.5) if not birch else Color(0.6, 0.75, 0.55)
			leaves.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			leaves.alpha_scissor_threshold = 0.5
			leaves.cull_mode = BaseMaterial3D.CULL_DISABLED
			leaves.roughness = 0.9
			leaves_mats[leaf_tex] = leaves
		mesh.surface_set_material(0, bark)
		if mesh.get_surface_count() > 1:
			mesh.surface_set_material(1, leaves_mats[leaf_tex])
		out[tname] = [mesh, xf]
		scene.free()
	return out


func _build_trees() -> void:
	var real := Scenery.exists(SCENERY_TREES[0])
	var models := {} if real else _tree_models()
	var names: Array = []
	for tname in models:
		for k in TREES[tname]:
			names.append(tname)
	if names.is_empty() and not real:
		models = {"pine": [_pine_mesh(), Transform3D.IDENTITY]}
		names = ["pine"]
	# Realistic trees come in two meshes (trunk and leaves): bigger groups keep draw calls down.
	var chunk_size := CHUNK * CELL * (2.0 if real else 1.0)
	var per_chunk := {}  # Vector3i(chunk x, chunk z, model) -> transforms
	var trunks: Array[Vector3] = []
	var size := (_gw - 1) * CELL
	for i in tree_tries:
		var x := _min.x + _rng.randf() * size
		var z := _min.y + _rng.randf() * size
		var d := _road_dist_at(x, z)
		if d < RAIL_OFFSET + 6.0 or d > 320.0:
			continue
		var h := ground_height(x, z)
		var slope := absf(ground_height(x + 2.0, z) - h) + absf(ground_height(x, z + 2.0) - h)
		if slope > 1.3 or not _plant_ok(x, z, h):
			continue  # too steep: rock
		# Woods in patches.
		if _noise.get_noise_2d(x * 3.0 + 500.0, z * 3.0) < -0.05:
			continue
		var model_i: int
		var s: float
		if real:
			model_i = _rng.randi() % SCENERY_TREES.size() if d < 55.0 else 0
			s = _rng.randf_range(12.0, 22.0)  # Scenery models are 1 m tall
		else:
			model_i = names.find(names[_rng.randi() % names.size()])
			# The models are about 7 m tall; mountain conifers are 12 to 20 m.
			s = _rng.randf_range(1.7, 2.7)
		var key := Vector3i(floori((x - _min.x) / chunk_size), floori((z - _min.y) / chunk_size), model_i)
		if not per_chunk.has(key):
			per_chunk[key] = []
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.9, 1.2), s))
		per_chunk[key].append(Transform3D(basis, Vector3(x, h - 0.2, z)))
		if d < 40.0:
			trunks.append(Vector3(x, h, z))
	for key in per_chunk:
		var list: Array = per_chunk[key]
		if real:
			# The detailed trees only show up close; far slopes keep the light one.
			Scenery.scatter(self, SCENERY_TREES[key.z], 1.0, list, 700.0 if key.z == 0 else 260.0)
			continue
		var model: Array = models[names[key.z]]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = model[0]
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i] * (model[1] as Transform3D))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.visibility_range_end = 700.0
		add_child(mmi)
	# Trunks block cars that leave the road.
	var body := StaticBody3D.new()
	add_child(body)
	for t in trunks:
		var shape := CylinderShape3D.new()
		shape.radius = 0.5
		shape.height = 3.0
		var col := CollisionShape3D.new()
		col.shape = shape
		col.position = t + Vector3(0, 1.5, 0)
		body.add_child(col)


## Whether trees and grass may grow at (x, z), ground height h.
func _plant_ok(_x: float, _z: float, _h: float) -> bool:
	return true


## Two crossed quads with a grass texture, rooted at y = 0.
func _grass_mesh(tex_name: String) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for a in [0.0, PI / 2.0]:
		var r := Vector3(cos(a), 0, sin(a)) * 0.8
		var hgt := Vector3(0, 1.1, 0)
		var quad := [[-r, Vector2(0, 1)], [r, Vector2(1, 1)], [r + hgt, Vector2(1, 0)], [-r + hgt, Vector2(0, 0)]]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.set_uv(quad[idx][1])
			st.add_vertex(quad[idx][0])
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/props/grass/%s.png" % tex_name)
	m.albedo_color = Color(0.95, 1.15, 0.75)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.4
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 1.0
	st.set_material(m)
	return st.commit()


## Tall grass clumps in the fields near the road, where the camera sees them up close.
func _build_grass() -> void:
	var meshes: Array[ArrayMesh] = []
	for g in GRASS:
		if ResourceLoader.exists("res://assets/props/grass/%s.png" % g):
			meshes.append(_grass_mesh(g))
	if meshes.is_empty():
		return
	var chunk_size := CHUNK * CELL
	var per_chunk := {}
	for i in pts.size() * 6:
		var p := pts[_rng.randi() % pts.size()]
		var x := p.x + _rng.randf_range(-70.0, 70.0)
		var z := p.z + _rng.randf_range(-70.0, 70.0)
		var d := _road_dist_at(x, z)
		if d < RAIL_OFFSET + 0.8 or d > 70.0:
			continue
		var h := ground_height(x, z)
		var slope := absf(ground_height(x + 2.0, z) - h) + absf(ground_height(x, z + 2.0) - h)
		if slope > 0.9 or not _plant_ok(x, z, h):
			continue
		var m := _rng.randi() % meshes.size()
		var key := Vector3i(floori((x - _min.x) / chunk_size), floori((z - _min.y) / chunk_size), m)
		if not per_chunk.has(key):
			per_chunk[key] = []
		var s := _rng.randf_range(0.7, 1.4)
		per_chunk[key].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s)), Vector3(x, h - 0.05, z)))
	for key in per_chunk:
		var list: Array = per_chunk[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = meshes[key.z]
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = 160.0
		add_child(mmi)


## Chevron signs on the outer verge of the tight bends. They are loose bodies resting in place:
## a car knocks them flying.
func _build_signs() -> void:
	var n := pts.size()
	var tex := _chevron_texture()
	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_texture = tex
	panel_mat.roughness = 0.6
	var post_mat := CarModel.mat(Color(0.75, 0.75, 0.75), Color.BLACK, 0.0, 0.6, 0.4)
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.08, 1.5, 0.08)
	post_mesh.material = post_mat
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(0.8, 0.6, 0.04)
	panel_mesh.material = panel_mat
	var k := 0
	while k < n:
		if limits[k] > 20.0:
			k += 1
			continue
		# Outer side: away from the middle of the chord across the bend.
		var mid := (pts[(k - 12 + n) % n] + pts[(k + 12) % n]) / 2.0
		var out_side := -signf((mid - pts[k]).dot(_right(k)))
		var base := pts[k] + _right(k) * out_side * (ROAD_HALF + 1.4)
		var sign := RigidBody3D.new()
		sign.mass = 25.0
		sign.can_sleep = true
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.8, 2.1, 0.12)
		col.shape = shape
		col.position.y = 1.05
		sign.add_child(col)
		var post := MeshInstance3D.new()
		post.mesh = post_mesh
		post.position.y = 0.75
		sign.add_child(post)
		var panel := MeshInstance3D.new()
		panel.mesh = panel_mesh
		panel.position.y = 1.75
		# The arrow points into the bend; mirror the panel on the other side.
		panel.scale.x = out_side
		sign.add_child(panel)
		add_child(sign)
		sign.global_transform = Transform3D(Basis.looking_at(-tangents[k], Vector3.UP), base + Vector3(0, 0.02, 0))
		sign.sleeping = true
		k += 9


func _chevron_texture() -> ImageTexture:
	var w := 96
	var h := 72
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var u := float(x) / w
			var v := absf(float(y) / h - 0.5)
			# Two white chevrons pointing right on red.
			var c := Color(0.85, 0.08, 0.06)
			for off in [0.18, 0.5]:
				var d: float = u - off - (0.5 - v) * 0.45
				if d > 0.0 and d < 0.13:
					c = Color(0.97, 0.97, 0.95)
			if x < 3 or y < 3 or x >= w - 3 or y >= h - 3:
				c = Color(0.97, 0.97, 0.95)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _build_rocks() -> void:
	_build_signs()
	var kinds := ["moon_rock_02", "rock_09", "rock_face_01"]
	var scenes := {}
	for kname in kinds:
		var path := "res://assets/props/%s/%s.gltf" % [kname, kname]
		if ResourceLoader.exists(path):
			scenes[kname] = load(path)
	if scenes.is_empty():
		return
	var placed := 0
	var tries := 0
	while placed < 45 and tries < 2000:
		tries += 1
		var k := _rng.randi_range(0, pts.size() - 1)
		var side := 1.0 if _rng.randf() < 0.5 else -1.0
		var off := RAIL_OFFSET + _rng.randf_range(3.0, 14.0)
		var p := pts[k] + _right(k) * side * off
		var h := ground_height(p.x, p.z)
		# Boulders sit where the ground rises above the road (cuttings), so they look like they fell.
		if h < pts[k].y + 1.0:
			continue
		var kname: String = kinds[placed % kinds.size()]
		if not scenes.has(kname):
			continue
		var inst: Node3D = (scenes[kname] as PackedScene).instantiate()
		var s := _rng.randf_range(2.0, 4.0) if kname != "rock_face_01" else _rng.randf_range(1.5, 2.5)
		inst.scale = Vector3.ONE * s
		inst.rotation.y = _rng.randf() * TAU
		inst.position = Vector3(p.x, h - 0.3 * s, p.z)
		add_child(inst)
		for c in inst.find_children("*", "GeometryInstance3D", true, false):
			(c as GeometryInstance3D).visibility_range_end = 350.0
		placed += 1


# ---------- Ramps ----------

func _build_ramps() -> void:
	# Two jumps on the middle of long, gentle stretches, far from the start and from each other,
	# with at least 120 m of easy road after the lip for the landing.
	var mat: Material = load("res://assets/materials/wall_metal_sheet.tres") if ResourceLoader.exists("res://assets/materials/wall_metal_sheet.tres") else null
	var n := pts.size()
	var chosen: Array[int] = []
	var candidates: Array = []
	for k in range(0, n, 5):
		var worst := INF
		var max_drop := 0.0
		for j in range(-10, 75):
			var i := (k + j + n) % n
			worst = minf(worst, limits[i])
		for j in range(0, 75):
			var i := (k + j) % n
			max_drop = maxf(max_drop, absf(tangents[i].y))
		var from_start := mini(absi(k - start_i), n - absi(k - start_i))
		if worst > 34.0 and max_drop < 0.09 and from_start > 150:
			candidates.append([worst, k])
	candidates.sort_custom(func(a, b): return a[0] > b[0])
	for c in candidates:
		var k: int = c[1]
		var ok := true
		for o in chosen:
			if mini(absi(k - o), n - absi(k - o)) < n / 4:
				ok = false
		if ok:
			chosen.append(k)
		if chosen.size() >= 2:
			break
	for k in chosen:
		var ramp := Ramp.create(14.0, 4.0, 15.0, mat, true)
		ramp.transform = Transform3D(Basis.looking_at(tangents[k], Vector3.UP), pts[k] - Vector3(0, 0.05, 0))
		add_child(ramp)


# ---------- Racing line ----------

## The best line round the loop: a band pulled tight inside the road (as straight as the road
## allows), so it swings wide before a bend, touches the inside and runs wide again. Drawn on the
## asphalt as dashes coloured by what to do: green accelerate, yellow lift, red brake.
func _build_racing_line() -> void:
	var n := pts.size()
	var room := ROAD_HALF - 1.6
	line_off.resize(n)
	line_off.fill(0.0)
	var flat := PackedVector2Array()
	var rights := PackedVector2Array()
	flat.resize(n)
	rights.resize(n)
	for k in n:
		flat[k] = Vector2(pts[k].x, pts[k].z)
		var r := _right(k)
		rights[k] = Vector2(r.x, r.z)
	# Coarse passes with far neighbours shape the whole bend, fine passes smooth it.
	for pass_i in 220:
		var reach := 6 if pass_i < 150 else 2
		for k in n:
			var ka := (k - reach + n) % n
			var kb := (k + reach) % n
			var pa := flat[ka] + rights[ka] * line_off[ka]
			var pb := flat[kb] + rights[kb] * line_off[kb]
			var pk := flat[k] + rights[k] * line_off[k]
			line_off[k] = clampf(line_off[k] + ((pa + pb) * 0.5 - pk).dot(rights[k]) * 0.8, -room, room)
	# Speed along the line: corner limits from its own curvature, then braking (backwards) and
	# accelerating (forwards) between them, twice round so the loop closes.
	line_speed.resize(n)
	for k in n:
		var a := flat[(k - 6 + n) % n] + rights[(k - 6 + n) % n] * line_off[(k - 6 + n) % n]
		var m := flat[k] + rights[k] * line_off[k]
		var b := flat[(k + 6) % n] + rights[(k + 6) % n] * line_off[(k + 6) % n]
		var ang := absf((m - a).angle_to(b - m))
		var radius := m.distance_to(a) / maxf(2.0 * sin(ang / 2.0), 0.0001)
		line_speed[k] = minf(sqrt(GRIP * 1.3 * 9.8 * radius), 64.0)
	for _round in 2:
		for j in n:
			var k := n - 1 - j
			line_speed[k] = minf(line_speed[k], sqrt(line_speed[(k + 1) % n] ** 2 + 2.0 * DECEL * SAMPLE_STEP))
		for k in n:
			line_speed[k] = minf(line_speed[k], sqrt(line_speed[(k - 1 + n) % n] ** 2 + 2.0 * 4.0 * SAMPLE_STEP))
	# Dashes: 4 m painted every 8 m, 0.6 m wide.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lift := Vector3(0, 0.03, 0)
	for k in range(0, n, 4):
		var k2 := (k + 2) % n
		var drop := line_speed[k] - line_speed[(k + 4) % n]
		var col := Color(0.2, 1.0, 0.35)
		if drop > 0.6:
			col = Color(1.0, 0.15, 0.1)
		elif drop > 0.05 or line_speed[k] < 30.0:
			col = Color(1.0, 0.8, 0.1)
		col.a = 0.9
		var a0 := _line_point(k) - _right(k) * 0.3 + lift
		var a1 := _line_point(k) + _right(k) * 0.3 + lift
		var b0 := _line_point(k2) - _right(k2) * 0.3 + lift
		var b1 := _line_point(k2) + _right(k2) * 0.3 + lift
		for v in [a0, b0, a1, a1, b0, b1]:
			st.set_color(col)
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	add_child(mi)
	guide = mi


# ---------- Track interface ----------

func setup_environment(parent: Node) -> void:
	var env := Environment.new()
	# The sky material itself comes from ComicStyle.setup_environment (painted pop-art sky): no
	# photo sky to load here (the 2k HDR panorama took memory and time on the phone for nothing).
	var sky := Sky.new()
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_hdr_threshold = 1.4
	env.fog_enabled = true
	env.fog_light_color = Color(0.55, 0.66, 0.82)
	env.fog_density = 0.0006
	env.fog_aerial_perspective = 0.3
	env.fog_sky_affect = 0.1
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	env.adjustment_contrast = 1.05
	var we := WorldEnvironment.new()
	we.environment = env
	parent.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -35, 0)
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 140.0
	parent.add_child(sun)


func route_point(pos: Vector3, target: Vector3) -> Vector3:
	if pos.distance_to(target) < 40.0:
		return target
	var n := pts.size()
	var i := nearest(pos)
	var j := nearest(target)
	var fwd := posmod(j - i, n)
	var dir := 1 if fwd <= n - fwd else -1
	var steps := fwd if dir == 1 else n - fwd
	if steps <= 12:
		return target
	return pts[posmod(i + dir * 12, n)]


func advised_speed(pos: Vector3, fwd: Vector3) -> float:
	var n := pts.size()
	var i := nearest(pos)
	var dir := 1 if fwd.dot(tangents[i]) >= 0.0 else -1
	var best := INF
	for j in range(1, 80):
		var lim := limits[posmod(i + dir * j, n)]
		best = minf(best, sqrt(lim * lim + 2.0 * DECEL * j * SAMPLE_STEP))
	return best


func race_path() -> Array[Vector3]:
	# Along the racing line once it is built: the AI racers then cut the corners like a driver.
	var out: Array[Vector3] = []
	var n := pts.size()
	for k in range(0, n, PATH_STRIDE):
		out.append(_line_point((start_i + k) % n))
	out.append(pts[start_i])  # one full lap: the finish is the start line
	return out


func _line_point(k: int) -> Vector3:
	return pts[k] + _right(k) * (line_off[k] if line_off.size() == pts.size() else 0.0)


func off_track_distance(pos: Vector3) -> float:
	var k := nearest(pos)
	var d := Vector2(pos.x - pts[k].x, pos.z - pts[k].z).length() - RAIL_OFFSET
	if pos.y < pts[k].y - 12.0:
		d = maxf(d, 60.0)  # fell down a slope
	return d


func recovery_point(pos: Vector3) -> Array:
	var k := nearest(pos)
	# Back on the near lane, facing the way the race goes.
	var side := signf((pos - pts[k]).dot(_right(k)))
	return [pts[k] + _right(k) * side * LANE * 0.6 + Vector3(0, 0.6, 0), tangents[k]]


func racing_line() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for k in pts.size():
		out.append(_line_point(k))
	return out


func race_checkpoints() -> Array[Vector3]:
	var path := race_path()
	var out: Array[Vector3] = []
	for c in CHECKPOINTS:
		out.append(path[c * (path.size() - 1) / CHECKPOINTS])
	out.append(path[path.size() - 1])
	return out


func start_grid(count: int) -> Array:
	# Two by two just past the start line, so the start line is also the finish line.
	var out := []
	var n := pts.size()
	var rows: Array[int] = [11, 11, 6, 6, 1, 1]
	for c in count:
		var k := (start_i + rows[c % rows.size()]) % n
		var side := -2.8 if c % 2 == 0 else 2.8
		out.append([pts[k] + _right(k) * side, tangents[k]])
	return out


func escape_start() -> Array:
	var k := (start_i + 30) % pts.size()
	return [pts[k] + _right(k) * LANE, tangents[k]]


func police_spawn(player_pos: Vector3, player_fwd: Vector3, behind: bool, min_d: float, max_d: float, rng: RandomNumberGenerator) -> Array:
	var best := -1
	var best_score := -INF
	for k in range(0, pts.size(), 5):
		var to := pts[k] - player_pos
		var d := to.length()
		if d < min_d or d > max_d:
			continue
		var score := -to.normalized().dot(player_fwd) if behind else rng.randf()
		if score > best_score:
			best_score = score
			best = k
	if best < 0:
		best = posmod(nearest(player_pos) - 45, pts.size())
	var p := pts[best]
	return [p, route_point(p, player_pos) - p]


func menu_camera(t: float) -> Array:
	var c := pts[start_i]
	return [c + Vector3(sin(t) * 420, 170, cos(t) * 420), c + Vector3(0, 20, 0)]


func autopilot_goal(pos: Vector3, _goal: Vector3) -> Vector3:
	# Keep driving round the loop: a quarter of a lap ahead is always reached the same way.
	return pts[posmod(nearest(pos) + pts.size() / 4, pts.size())]


func traffic_lane(rng: RandomNumberGenerator) -> Dictionary:
	if _lane_curve == null:
		_lane_curve = Curve3D.new()
		_lane_curve.bake_interval = 1.0
		for k in range(0, pts.size(), 4):
			_lane_curve.add_point(pts[k])
		_lane_curve.add_point(pts[0])
	return {"curve": _lane_curve, "offset": LANE, "dir": 1.0 if rng.randf() < 0.5 else -1.0, "loop": true}
