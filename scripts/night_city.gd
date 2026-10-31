class_name NightCity
extends Mountain
## Night street circuit: a closed loop round city blocks (long avenues, square-ish corners, two
## chicanes), flat, lined with towers full of lit windows, shop fronts, neon signs and street
## lamps every 26 m. The old night city was too dark, so here the light is everywhere: bright
## moonlight and sky, warm pools of light on the asphalt, real lights that follow the camera
## from lamp to lamp, and a strong glow on everything that shines.

const LAMP_STEP := 13  # samples between street lamps (26 m), alternating sides
const LAMP_HEIGHT := 8.0
const LAMP_REACH := 3.2  # how far the arm reaches over the road
const LIVE_LIGHTS := 8  # real lights moved to the lamps nearest the camera
const NEON := [Color(1, 0.15, 0.6), Color(0.1, 0.85, 1), Color(0.7, 0.3, 1), Color(1, 0.55, 0.1), Color(0.3, 1, 0.45), Color(1, 0.95, 0.3)]
const WALLS := [Color(0.22, 0.23, 0.3), Color(0.3, 0.24, 0.22), Color(0.18, 0.21, 0.26), Color(0.33, 0.3, 0.29), Color(0.22, 0.18, 0.26)]

var _lamps: Array[Vector3] = []  # lamp heads
var _lamp_colors: Array[Color] = []
var _live: Array[OmniLight3D] = []
var _live_t := 0.0


func _init() -> void:
	super()
	rng_seed = 9090
	noise_seed = 33
	road_floor = 0.25
	view_distance = 1300.0
	night = true


func build_steps() -> Array:
	return [
		["Tracciato", _make_road_line],
		["Strade", _build_terrain],
		["Asfalto", _build_road],
		["Guardrail", _build_rails],
		["Palazzi", _build_buildings],
		["Lampioni", _build_lamps],
		["Insegne e cartelli", _build_signs],
		["Rampe", _build_ramps],
		["Traiettoria", _build_racing_line],
	]


## Rounded square round the blocks, with a chicane dent on two sides.
func _loop_point(th: float) -> Vector2:
	var p := 5.0
	var r := 330.0 / pow(pow(absf(cos(th)), p) + pow(absf(sin(th)), p), 1.0 / p)
	r -= 70.0 * _bump(th, 1.15, 0.13) + 55.0 * _bump(th, 3.9, 0.11)
	return Vector2(1.15 * r * cos(th), r * sin(th))


func _bump(th: float, at: float, width: float) -> float:
	var d := wrapf(th - at, -PI, PI)
	return exp(-d * d / (2.0 * width * width))


func _loop_grade(_u: float) -> float:
	return 0.0


func _natural(_x: float, _z: float) -> float:
	return 0.0


func _terrain_material() -> Material:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/terrain.gdshader")
	mat.set_shader_parameter("grass_albedo", _tex("asphalt_02", "diff"))
	mat.set_shader_parameter("rock_albedo", _tex("brushed_concrete", "diff"))
	mat.set_shader_parameter("gravel_albedo", _tex("checkered_pavement_tiles", "diff"))
	mat.set_shader_parameter("grass_scale", 0.08)
	mat.set_shader_parameter("grass_tint", Vector3(0.55, 0.55, 0.6))
	return mat


# ---------- Buildings ----------

func _build_buildings() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/night_building.gdshader")
	var chunk_size := CHUNK * CELL
	var per_chunk := {}  # Vector2i -> SurfaceTool
	var body := StaticBody3D.new()
	add_child(body)
	var neon_xf: Array[Transform3D] = []
	var neon_col: Array[Color] = []
	var grid := 34.0
	var size := (_gw - 1) * CELL
	var centre := Vector2.ZERO
	for p in pts:
		centre += Vector2(p.x, p.z)
	centre /= pts.size()
	var gx := 0.0
	while gx < size:
		var gz := 0.0
		while gz < size:
			var c := Vector2(_min.x + gx + _rng.randf_range(-4, 4), _min.y + gz + _rng.randf_range(-4, 4))
			gz += grid
			var d := _road_dist_at(c.x, c.y)
			var hs := _rng.randf_range(8.0, 14.5)
			var yaw := 0.0
			var k := -1
			if d < INF:
				hs = minf(hs, (d - RAIL_OFFSET - 4.5) / 1.3)
				if hs < 5.0:
					continue
				# Front rows line up with the street.
				k = nearest(Vector3(c.x, 0, c.y))
				yaw = atan2(tangents[k].x, tangents[k].z)
			var downtown := 1.0 - smoothstep(150.0, 420.0, c.distance_to(centre))
			var h := _rng.randf_range(10.0, 28.0) + downtown * _rng.randf_range(0.0, 40.0)
			if _rng.randf() < 0.08 + 0.2 * downtown:
				h = _rng.randf_range(60.0, 120.0)
			var hx := hs * _rng.randf_range(0.8, 1.0)
			var hz := hs * _rng.randf_range(0.8, 1.0)
			var basis := Basis(Vector3.UP, yaw)
			var key := Vector2i(floori((c.x - _min.x) / chunk_size), floori((c.y - _min.y) / chunk_size))
			if not per_chunk.has(key):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				per_chunk[key] = st
			var wall: Color = WALLS[_rng.randi() % WALLS.size()]
			wall.a = _rng.randf()
			_box(per_chunk[key], Vector3(c.x, 0, c.y), basis, Vector3(hx, h, hz), wall)
			# A setback tower on top of some tall ones.
			if h > 45.0 and _rng.randf() < 0.6:
				_box(per_chunk[key], Vector3(c.x, h, c.y), basis, Vector3(hx * 0.6, h * 0.25, hz * 0.6), wall)
			if d < 44.0:
				var shape := BoxShape3D.new()
				shape.size = Vector3(hx * 2.0, 12.0, hz * 2.0)
				var col := CollisionShape3D.new()
				col.shape = shape
				col.transform = Transform3D(basis, Vector3(c.x, 6.0, c.y))
				body.add_child(col)
				# Neon signs on the side facing the road: vertical blades and wide boards.
				var to_road := Vector3(pts[k].x - c.x, 0, pts[k].z - c.y).normalized()
				var lx := basis.x
				var lz := basis.z
				var face := lx if absf(to_road.dot(lx)) > absf(to_road.dot(lz)) else lz
				var half := hx if face == lx else hz
				var along := hz if face == lx else hx
				if face.dot(to_road) < 0.0:
					face = -face
				var across := Vector3.UP.cross(face).normalized()
				var front := Vector3(c.x, 0, c.y) + face * (half + 0.15)
				var n_signs := _rng.randi_range(1, 2)
				for s in n_signs:
					var col_n: Color = NEON[_rng.randi() % NEON.size()]
					var y := _rng.randf_range(5.0, minf(h - 4.0, 16.0))
					if y < 5.0:
						continue
					var off := _rng.randf_range(-along * 0.6, along * 0.6)
					var sb := Basis(across, face, Vector3.UP).orthonormalized()
					if _rng.randf() < 0.5:
						# Vertical blade sticking out of the wall.
						neon_xf.append(Transform3D(Basis(face, Vector3.UP, across).scaled(Vector3(1.6, 6.0, 0.25)), front + across * off + face * 0.8 + Vector3(0, y, 0)))
					else:
						neon_xf.append(Transform3D(sb.scaled(Vector3(along * 1.1, 0.2, 1.8)), front + Vector3(0, y, 0)))
					neon_col.append(col_n)
		gx += grid
	for key in per_chunk:
		var st: SurfaceTool = per_chunk[key]
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = mat
		add_child(mi)
	_neon_multimesh(BoxMesh.new(), neon_xf, neon_col, 3.2)


## Box from the ground up (no bottom face): centre of the base at `at`, half sizes x and z.
func _box(st: SurfaceTool, at: Vector3, basis: Basis, s: Vector3, col: Color) -> void:
	var c := [
		Vector3(-s.x, 0, -s.z), Vector3(s.x, 0, -s.z), Vector3(s.x, 0, s.z), Vector3(-s.x, 0, s.z),
		Vector3(-s.x, s.y, -s.z), Vector3(s.x, s.y, -s.z), Vector3(s.x, s.y, s.z), Vector3(-s.x, s.y, s.z),
	]
	for i in 8:
		c[i] = at + basis * c[i]
	var faces := [[0, 4, 5, 1], [1, 5, 6, 2], [2, 6, 7, 3], [3, 7, 4, 0], [4, 7, 6, 5]]
	for f in faces:
		var a: Vector3 = c[f[0]]
		var b: Vector3 = c[f[1]]
		var cc: Vector3 = c[f[2]]
		var d: Vector3 = c[f[3]]
		var n := (b - a).cross(d - a).normalized()
		for v in [a, b, cc, a, cc, d]:
			st.set_color(col)
			st.set_normal(n)
			st.add_vertex(v)


func _plain_multimesh(mesh: Mesh, xfs: Array[Transform3D], mat: Material) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
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


# ---------- Street lamps ----------

func _build_lamps() -> void:
	var n := pts.size()
	var poles: Array[Transform3D] = []
	var arms: Array[Transform3D] = []
	var heads: Array[Transform3D] = []
	var head_cols: Array[Color] = []
	var pools: Array[Transform3D] = []
	var pool_cols: Array[Color] = []
	var body := StaticBody3D.new()
	add_child(body)
	var i := 0
	for k in range(0, n, LAMP_STEP):
		var side := 1.0 if i % 2 == 0 else -1.0
		i += 1
		var r := _right(k) * side
		var base := pts[k] + r * (RAIL_OFFSET + 0.9)
		var lamp_col := Color(1.0, 0.78, 0.5) if i % 3 != 0 else Color(0.85, 0.92, 1.0)
		poles.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1, LAMP_HEIGHT, 1)), base + Vector3(0, LAMP_HEIGHT / 2.0, 0)))
		var arm_mid := base - r * (LAMP_REACH / 2.0) + Vector3(0, LAMP_HEIGHT, 0)
		arms.append(Transform3D(Basis.looking_at(r, Vector3.UP).scaled(Vector3(0.18, 0.18, LAMP_REACH + 0.4)), arm_mid))
		var head := base - r * LAMP_REACH + Vector3(0, LAMP_HEIGHT - 0.2, 0)
		heads.append(Transform3D(Basis.looking_at(r, Vector3.UP).scaled(Vector3(0.6, 0.18, 1.4)), head))
		head_cols.append(lamp_col)
		var ground := head - r * 1.5
		pools.append(Transform3D(Basis.IDENTITY.scaled(Vector3(19, 1, 19)), Vector3(ground.x, pts[k].y + 0.06, ground.z)))
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
	var pole := CylinderMesh.new()
	pole.top_radius = 0.09
	pole.bottom_radius = 0.14
	pole.height = 1.0
	pole.radial_segments = 6
	pole.rings = 1
	var metal := CarModel.mat(Color(0.22, 0.23, 0.26), Color.BLACK, 0.0, 0.7, 0.4)
	var box := BoxMesh.new()
	_plain_multimesh(pole, poles, metal)
	_plain_multimesh(box, arms, metal)
	_neon_multimesh(box, heads, head_cols, 4.0)
	var pool_mesh := PlaneMesh.new()
	pool_mesh.size = Vector2.ONE
	var pmat := ShaderMaterial.new()
	pmat.shader = preload("res://shaders/light_pool.gdshader")
	var mm_pool := MultiMesh.new()
	mm_pool.transform_format = MultiMesh.TRANSFORM_3D
	mm_pool.use_colors = true
	mm_pool.mesh = pool_mesh
	mm_pool.instance_count = pools.size()
	for j in pools.size():
		mm_pool.set_instance_transform(j, pools[j])
		mm_pool.set_instance_color(j, pool_cols[j])
	var pmi := MultiMeshInstance3D.new()
	pmi.multimesh = mm_pool
	pmi.material_override = pmat
	pmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pmi)
	# Real lights, moved to the lamps nearest the camera (see _process): cars and walls light up
	# as they pass under them, while the far lamps are only the glowing heads and the pools.
	for j in LIVE_LIGHTS:
		var l := OmniLight3D.new()
		l.omni_range = 17.0
		l.omni_attenuation = 1.2
		l.light_energy = 2.6
		l.shadow_enabled = false
		l.visible = false
		add_child(l)
		_live.append(l)


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
	for j in _live.size():
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
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	# Bright night: a strong blue-violet ambient so nothing is ever black.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.55, 0.85)
	env.ambient_light_energy = 0.62
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.15
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.95
	env.fog_enabled = true
	env.fog_light_color = Color(0.22, 0.14, 0.32)
	env.fog_density = 0.0012
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
	moon.light_energy = 0.75
	moon.shadow_enabled = true
	moon.shadow_opacity = 0.6
	moon.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	moon.directional_shadow_max_distance = 120.0
	parent.add_child(moon)


func menu_camera(t: float) -> Array:
	var c := pts[start_i]
	return [c + Vector3(sin(t) * 280, 75, cos(t) * 280), c + Vector3(0, 12, 0)]
