class_name NightCity
extends Mountain
## Downtown at night, rebuilt from scratch (v0.11): a street circuit drawn on the map
## tracks/citta_notte.txt (avenues, elbow corners between the blocks, a chicane), lined with
## real building models (Sketchfab, CC-BY: see assets/LICENSES.md) whose windows light up at
## night, a skyline of lit towers all around, street lamps with real light near the camera,
## traffic lights at the crossings and neon blades on the shop fronts.
## The old night city was found too dark, so the light is everywhere: bright blue-violet
## ambient, warm windows and lamp pools on the asphalt, strong glow.

const SIDEWALK := 5.0  # from the guardrail to the building fronts
const LAMP_STEP := 13  # samples between street lamps (26 m), alternating sides
const LIVE_LIGHTS := 8  # real lights moved to the lamps nearest the camera
const BUILD_CHUNK := 160.0  # buildings are grouped in squares this big, so far ones are culled
const NEON := [Color(1, 0.15, 0.6), Color(0.1, 0.85, 1), Color(0.7, 0.3, 1), Color(1, 0.55, 0.1), Color(0.3, 1, 0.45), Color(1, 0.95, 0.3)]
## Buildings along the streets: [pack, piece, scale, weight]. Piece indexes as shown by
## tools/pack_sheet.gd; the fronts of these models face +z.
const STREET_BUILDINGS := [
	["city_downtown_set", 0, 1.0, 2], ["city_downtown_set", 1, 1.0, 2], ["city_downtown_set", 3, 1.0, 2],
	["city_downtown_set", 4, 1.0, 2], ["city_downtown_set", 5, 1.0, 1], ["city_downtown_set", 6, 1.0, 2],
	["city_downtown_set", 7, 1.0, 2], ["city_downtown_set", 8, 1.0, 2], ["city_downtown_set", 9, 1.0, 2],
	["city_downtown_set", 10, 1.0, 2], ["city_downtown_set", 11, 1.0, 1], ["city_downtown_set", 12, 1.0, 2],
	["city_downtown_set", 13, 1.0, 2], ["city_downtown_set", 14, 1.0, 1], ["city_downtown_set", 15, 1.0, 2],
	["city_downtown_set", 16, 1.0, 2], ["city_downtown_set", 17, 1.0, 2],
	["city_nyc_homes", 0, 0.19, 3], ["city_chicago_buildings", 0, 0.23, 3],
	["city_midcity_set", 2, 1.2, 1], ["city_midcity_set", 5, 1.2, 1], ["city_midcity_set", 7, 1.2, 1],
	["city_midcity_set", 11, 1.2, 1], ["city_midcity_set", 13, 1.2, 1],
]
## Taller ones for the second row and the gaps: they show above the street fronts.
const TOWERS := [
	["city_downtown_set", 10, 1.3, 2], ["city_downtown_set", 13, 1.3, 2], ["city_downtown_set", 15, 1.2, 2],
	["city_singapore_skyscraper", 0, 1.1, 2], ["city_downtown_set", 16, 1.4, 1],
]
const LAMP := ["city_street_lights", 0, 1.55]
const TRAFFIC_LIGHT := ["city_street_props_traffic_light", 2, 1.35]
const HYDRANT := ["city_street_props_traffic_light", 4, 1.2]
const BIN := ["city_street_props_traffic_light", 5, 1.2]

var _lamps: Array[Vector3] = []  # lamp heads
var _lamp_colors: Array[Color] = []
var _live: Array[OmniLight3D] = []
var _live_t := 0.0
var _placed: Array[PackedVector2Array] = []  # building footprints
var _fronts: Array = []  # [front centre, outward normal, width, height] of street buildings
var _batches := {}  # [pack, piece, chunk] -> transforms
var _night_meshes := {}  # original mesh -> night copy


func _init() -> void:
	super()
	layout_id = "citta_notte"
	rng_seed = 9090
	noise_seed = 33
	road_floor = 0.25
	view_distance = 1400.0
	tree_tries = 0
	night = true
	road_tint = Color(0.4, 0.4, 0.46)
	verge_tint = Color(0.62, 0.6, 0.66)


func build_steps() -> Array:
	return [
		["Tracciato", _make_road_line],
		["Strade e piazze", _build_terrain],
		["Asfalto", _build_road],
		["Barriere", _build_rails],
		["Palazzi", _build_buildings],
		["Grattacieli", _build_skyline],
		["Lampioni e semafori", _build_lamps],
		["Insegne", _build_neon],
		["Rampe", _build_ramps],
		["Traiettoria", _build_racing_line],
	]


func _loop_grade(_u: float) -> float:
	return 0.0


func _natural(_x: float, _z: float) -> float:
	return 0.0


func _terrain_material() -> Material:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/terrain.gdshader")
	mat.set_shader_parameter("grass_albedo", _tex("checkered_pavement_tiles", "diff"))
	mat.set_shader_parameter("rock_albedo", _tex("brushed_concrete", "diff"))
	mat.set_shader_parameter("gravel_albedo", _tex("checkered_pavement_tiles", "diff"))
	mat.set_shader_parameter("grass_scale", 0.18)
	mat.set_shader_parameter("grass_tint", Vector3(0.62, 0.6, 0.66))
	return mat


# ---------- Buildings ----------

## A copy of the mesh with the night facade material (lit windows) on every surface.
func _night_mesh(mesh: Mesh) -> Mesh:
	if _night_meshes.has(mesh):
		return _night_meshes[mesh]
	var copy := mesh.duplicate() as Mesh
	for i in copy.get_surface_count():
		var m := copy.surface_get_material(i) as BaseMaterial3D
		var sm := ShaderMaterial.new()
		sm.shader = preload("res://shaders/city_facade.gdshader")
		if m:
			sm.set_shader_parameter("albedo_tex", m.albedo_texture)
			sm.set_shader_parameter("tint", m.albedo_color)
		copy.surface_set_material(i, sm)
	_night_meshes[mesh] = copy
	return copy


func _footprint(centre: Vector3, basis: Basis, w: float, d: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var p := centre + basis.x * (c.x * w / 2.0) + basis.z * (c.y * d / 2.0)
		out.append(Vector2(p.x, p.z))
	return out


## Whether a footprint is clear of the roads (and of the other buildings).
func _free(fp: PackedVector2Array, road_gap: float) -> bool:
	var probe := Array(fp)
	for i in 4:
		probe.append((fp[i] + fp[(i + 1) % 4]) / 2.0)
	probe.append((fp[0] + fp[2]) / 2.0)
	for q: Vector2 in probe:
		if _road_dist_at(q.x, q.y) < road_gap:
			return false
	var shrunk := PackedVector2Array()
	var c := (fp[0] + fp[2]) / 2.0
	for q in fp:
		shrunk.append(c + (q - c) * 0.96)
	for other in _placed:
		if not Geometry2D.intersect_polygons(shrunk, other).is_empty():
			return false
	return true


func _pick(list: Array) -> Array:
	var total := 0
	for e in list:
		total += e[3]
	var r := _rng.randi() % total
	for e in list:
		r -= e[3]
		if r < 0:
			return e
	return list[0]


func _add_building(e: Array, xf: Transform3D, body: StaticBody3D, size: Vector3) -> void:
	var key := [e[0], e[1], Vector2i(floori(xf.origin.x / BUILD_CHUNK), floori(xf.origin.z / BUILD_CHUNK))]
	if not _batches.has(key):
		_batches[key] = []
	_batches[key].append(xf)
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, minf(size.y, 30.0), size.z)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.transform = Transform3D(xf.basis.orthonormalized(), xf.origin + Vector3(0, shape.size.y / 2.0, 0))
	body.add_child(col)


func _build_buildings() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	var n := pts.size()
	var front_off := RAIL_OFFSET + SIDEWALK
	# Street fronts: walk along both sides of the road, one building after the other.
	for side: float in [-1.0, 1.0]:
		var k := 0
		var fails := 0
		while k < n:
			var e := _pick(STREET_BUILDINGS)
			var box: AABB = Scenery.pieces(e[0])[e[1]]["box"]
			var s: float = e[2]
			var w := box.size.x * s
			var d := box.size.z * s
			var r := _right(k) * side
			var centre := pts[k] + r * (front_off + d / 2.0)
			centre.y = road_floor - 0.3
			var basis := Basis.looking_at(r, Vector3.UP)  # model front (+z) towards the road
			var fp := _footprint(centre, basis, w, d)
			if _free(fp, front_off - 1.0):
				_placed.append(fp)
				_add_building(e, Transform3D(basis.scaled(Vector3.ONE * s), centre), body, Vector3(w, box.size.y * s, d))
				_fronts.append([pts[k] + r * front_off, -r, w, box.size.y * s])
				k += int((w + _rng.randf_range(0.5, 4.0)) / SAMPLE_STEP)
				fails = 0
			else:
				fails += 1
				k += 2 if fails < 6 else 6
	# Second row and gaps: taller buildings further back, facing the nearest road.
	var size := (_gw - 1) * CELL
	for i in 900:
		var e := _pick(TOWERS if _rng.randf() < 0.5 else STREET_BUILDINGS)
		var box: AABB = Scenery.pieces(e[0])[e[1]]["box"]
		var s: float = e[2]
		var x := _min.x + _rng.randf() * size
		var z := _min.y + _rng.randf() * size
		var dist := _road_dist_at(x, z)
		if dist < front_off + 8.0 or dist > 150.0:
			continue
		var k := nearest(Vector3(x, 0, z))
		var to_road := Vector3(pts[k].x - x, 0, pts[k].z - z).normalized()
		var basis := Basis.looking_at(-to_road, Vector3.UP)
		var centre := Vector3(x, road_floor - 0.3, z)
		var fp := _footprint(centre, basis, box.size.x * s, box.size.z * s)
		if _free(fp, front_off):
			_placed.append(fp)
			_add_building(e, Transform3D(basis.scaled(Vector3.ONE * s), centre), body, box.size * s)
	for key in _batches:
		_scatter_night(key[0], key[1], _batches[key], 900.0)


func _scatter_night(pack: String, piece: int, xfs: Array, vis_end: float) -> void:
	var p: Dictionary = Scenery.pieces(pack)[piece]
	for part in p["parts"]:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _night_mesh(part[0])
		mm.instance_count = xfs.size()
		for i in xfs.size():
			mm.set_instance_transform(i, (xfs[i] as Transform3D) * (part[1] as Transform3D))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.visibility_range_end = vis_end
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)


## Lit towers all round the circuit, far out: the skyline seen above the streets.
func _build_skyline() -> void:
	if not Scenery.exists("city_night_skyline"):
		return
	var centre := Vector3.ZERO
	var reach := 0.0
	for p in pts:
		reach = maxf(reach, Vector2(p.x, p.z).length())
	var xfs := []
	var count := 14
	for i in count:
		var a := TAU * i / count + _rng.randf_range(-0.1, 0.1)
		var r := reach + _rng.randf_range(260.0, 420.0)
		var at := centre + Vector3(cos(a) * r, road_floor - 1.0, sin(a) * r)
		var s := _rng.randf_range(1.8, 2.6)
		xfs.append(Transform3D(Basis.looking_at(at - centre, Vector3.UP).scaled(Vector3.ONE * s), at))
	# The skyline model already has a night texture with lit windows.
	var nodes := Scenery.scatter_piece(self, "city_night_skyline", 0, xfs)
	for nd in nodes:
		(nd as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# ---------- Street lamps, traffic lights, hydrants ----------

func _build_lamps() -> void:
	var n := pts.size()
	var body := StaticBody3D.new()
	add_child(body)
	var lamp_xf := []
	var pools: Array[Transform3D] = []
	var pool_cols: Array[Color] = []
	var heads: Array[Transform3D] = []
	var i := 0
	for k in range(0, n, LAMP_STEP):
		var side := 1.0 if i % 2 == 0 else -1.0
		i += 1
		var r := _right(k) * side
		var base := pts[k] + r * (RAIL_OFFSET + 0.8)
		var lamp_col := Color(1.0, 0.8, 0.52) if i % 3 != 0 else Color(0.85, 0.92, 1.0)
		# The model's arm points along -x: turn it over the road.
		lamp_xf.append(Transform3D(Basis.looking_at(r.cross(Vector3.UP), Vector3.UP).scaled(Vector3.ONE * LAMP[2]), base))
		var head := base - r * 2.6 + Vector3(0, 7.6, 0)
		heads.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.9, 0.25, 0.9)), head))
		var ground := head - r * 1.0
		pools.append(Transform3D(Basis.IDENTITY.scaled(Vector3(18, 1, 18)), Vector3(ground.x, pts[k].y + 0.06, ground.z)))
		pool_cols.append(lamp_col)
		_lamps.append(head)
		_lamp_colors.append(lamp_col)
		var shape := CylinderShape3D.new()
		shape.radius = 0.25
		shape.height = 4.0
		var col := CollisionShape3D.new()
		col.shape = shape
		col.position = base + Vector3(0, 2.0, 0)
		body.add_child(col)
	if Scenery.exists(LAMP[0]):
		Scenery.scatter_piece(self, LAMP[0], LAMP[1], lamp_xf, 500.0)
	var head_cols: Array[Color] = []
	for c in _lamp_colors:
		head_cols.append(c)
	var sphere := SphereMesh.new()
	sphere.radial_segments = 8
	sphere.rings = 4
	_neon_multimesh(sphere, heads, head_cols, 4.5)
	_light_pools(pools, pool_cols)
	# Traffic lights over the road before the tight corners, hydrants and bins on the pavement.
	var tl := []
	var small := {HYDRANT: [], BIN: []}
	var k := 0
	while k < n:
		if limits[k] < 16.0:
			var kk := posmod(k - 14, n)
			var r := _right(kk)
			tl.append(Transform3D(Basis.looking_at(-r.cross(Vector3.UP), Vector3.UP).scaled(Vector3.ONE * TRAFFIC_LIGHT[2]), pts[kk] + r * (RAIL_OFFSET + 1.2)))
			k += 40
		else:
			k += 1
	for j in range(0, n, 23):
		var side := 1.0 if _rng.randf() < 0.5 else -1.0
		var what: Array = HYDRANT if _rng.randf() < 0.4 else BIN
		var p := pts[j] + _right(j) * side * (RAIL_OFFSET + _rng.randf_range(1.5, 3.5))
		small[what].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * what[2]), p))
	if Scenery.exists(TRAFFIC_LIGHT[0]):
		Scenery.scatter_piece(self, TRAFFIC_LIGHT[0], TRAFFIC_LIGHT[1], tl, 400.0)
		for what in small:
			Scenery.scatter_piece(self, what[0], what[1], small[what], 160.0)
	# Real lights, moved to the lamps nearest the camera (see _process).
	for j in LIVE_LIGHTS:
		var l := OmniLight3D.new()
		l.omni_range = 18.0
		l.omni_attenuation = 1.2
		l.light_energy = 2.8
		l.shadow_enabled = false
		l.visible = false
		add_child(l)
		_live.append(l)


func _light_pools(pools: Array[Transform3D], cols: Array[Color]) -> void:
	var pool_mesh := PlaneMesh.new()
	pool_mesh.size = Vector2.ONE
	var pmat := ShaderMaterial.new()
	pmat.shader = preload("res://shaders/light_pool.gdshader")
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = pool_mesh
	mm.instance_count = pools.size()
	for j in pools.size():
		mm.set_instance_transform(j, pools[j])
		mm.set_instance_color(j, cols[j])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = pmat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func _neon_multimesh(mesh: Mesh, xfs: Array[Transform3D], cols: Array[Color], energy: float) -> MultiMeshInstance3D:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/neon.gdshader")
	mat.set_shader_parameter("energy", energy)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_color(i, cols[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mmi


## Neon on the shop fronts: vertical blades sticking out of the walls and long strips over the
## shop windows, in pop colours.
func _build_neon() -> void:
	var xfs: Array[Transform3D] = []
	var cols: Array[Color] = []
	for f in _fronts:
		var at: Vector3 = f[0]
		var out: Vector3 = f[1]
		var w: float = f[2]
		var h: float = f[3]
		var across := Vector3.UP.cross(out).normalized()
		var col: Color = NEON[_rng.randi() % NEON.size()]
		if _rng.randf() < 0.75:
			# Strip above the ground floor.
			xfs.append(Transform3D(Basis(across, Vector3.UP, out).scaled(Vector3(w * 0.8, 0.22, 0.15)), at + out * 0.25 + Vector3(0, 4.2, 0)))
			cols.append(col)
		if h > 12.0 and _rng.randf() < 0.55:
			var y := _rng.randf_range(7.0, minf(h - 3.0, 18.0))
			var off := _rng.randf_range(-w * 0.35, w * 0.35)
			xfs.append(Transform3D(Basis(out, Vector3.UP, across).scaled(Vector3(1.4, 5.5, 0.22)), at + across * off + out * 0.9 + Vector3(0, y, 0)))
			cols.append(NEON[_rng.randi() % NEON.size()])
	_neon_multimesh(BoxMesh.new(), xfs, cols, 3.4)


func _process(delta: float) -> void:
	_live_t -= delta
	if _live_t > 0.0 or _lamps.is_empty():
		return
	_live_t = 0.15
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var at := cam.global_position
	var order: Array = []
	for j in _lamps.size():
		order.append([at.distance_squared_to(_lamps[j]), j])
	order.sort_custom(func(a, b): return a[0] < b[0])
	for j in mini(_live.size(), order.size()):
		var idx: int = order[j][1]
		_live[j].global_position = _lamps[idx] - Vector3(0, 0.6, 0)
		_live[j].light_color = _lamp_colors[idx]
		_live[j].visible = true


# ---------- Track interface ----------

func setup_environment(parent: Node) -> void:
	var env := Environment.new()
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = preload("res://shaders/night_sky.gdshader")
	var sky := Sky.new()
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	# Bright night: a strong blue-violet ambient so nothing is ever black.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.52, 0.56, 0.88)
	env.ambient_light_energy = 0.7
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.15
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.95
	env.fog_enabled = true
	env.fog_light_color = Color(0.24, 0.15, 0.34)
	env.fog_density = 0.0009
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.2
	env.adjustment_contrast = 1.05
	var we := WorldEnvironment.new()
	we.environment = env
	parent.add_child(we)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-38, 140, 0)
	moon.light_color = Color(0.7, 0.78, 1.0)
	moon.light_energy = 0.8
	moon.shadow_enabled = true
	moon.shadow_opacity = 0.6
	moon.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	moon.directional_shadow_max_distance = 120.0
	parent.add_child(moon)


func menu_camera(t: float) -> Array:
	var c := pts[start_i]
	return [c + Vector3(sin(t) * 280, 75, cos(t) * 280), c + Vector3(0, 12, 0)]
