class_name Desert
extends Mountain
## Route 66 in the desert: the circuit drawn on tracks/deserto.txt. A very long straight, a fast
## sweeper, an S through a red-rock canyon, a hairpin at the bottom of it and a little desert
## town with elbow corners: gas station, motel with its big sign, bank, shacks and a water tower.
## Red mesas and buttes all around, cactus and boulders on the sand. Models: Sketchfab, CC-BY
## (assets/LICENSES.md).

## Town buildings: [model, height in metres].
const TOWN := [
	["desert_western_bank", 9.0], ["desert_shanty", 9.0], ["desert_roadside_motel", 11.0],
	["desert_western_bank", 9.5], ["desert_shanty", 8.5],
]
## Where the town is, as a fraction of the lap from the start line (the elbow corners).
const TOWN_FROM := 0.72
const TOWN_TO := 0.93
## Roadside stops along the long straight.
const STOPS_FROM := 0.03
const STOPS_TO := 0.2

var _mesa_noise := FastNoiseLite.new()
## Points along the town's main street: the mesas keep away from them, so the town sits on
## flat sand instead of perching on the rocks.
var _town_pts := PackedVector2Array()
var _town_box := Rect2()


func _init() -> void:
	super()
	layout_id = "deserto"
	rng_seed = 6666
	noise_seed = 66
	road_floor = 2.0
	tree_tries = 0
	snow_line = 100000.0
	view_distance = 1800.0
	road_tint = Color(0.82, 0.8, 0.78)
	verge_tint = Color(1.25, 1.05, 0.85)
	_mesa_noise.seed = 1966
	_mesa_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_mesa_noise.frequency = 0.0042


func build_steps() -> Array:
	return [
		["Tracciato", _make_road_line],
		["Deserto e canyon", _build_terrain],
		["Asfalto", _build_road],
		["Guardrail", _build_rails],
		["Cactus e rocce", _build_desert_plants],
		["Paese", _build_town],
		["Cartelli", _build_rocks],
		["Rampe", _build_ramps],
		["Traiettoria", _build_racing_line],
	]


func _loop_grade(_u: float) -> float:
	return 0.0


## Sand with soft dunes; flat-topped red mesas rise with steep cliffs where the second noise is
## high (the road cuts through them in the canyon).
func _natural(x: float, z: float) -> float:
	if _town_pts.is_empty():
		var n := pts.size()
		var f := TOWN_FROM - 0.02
		while f < TOWN_TO + 0.02:
			var p := pts[(start_i + int(f * n)) % n]
			_town_pts.append(Vector2(p.x, p.z))
			f += 0.01
		_town_box = Rect2(_town_pts[0], Vector2.ZERO)
		for t in _town_pts:
			_town_box = _town_box.expand(t)
	var open := 1.0
	if _town_box.grow(150.0).has_point(Vector2(x, z)):
		var town := INF
		for t in _town_pts:
			town = minf(town, t.distance_to(Vector2(x, z)))
		open = smoothstep(70.0, 150.0, town)
	var dunes := 2.0 + _noise.get_noise_2d(x, z) * 6.0 * (0.3 + 0.7 * open)
	var m := _mesa_noise.get_noise_2d(x, z)
	var r := Vector2(x, z).length()
	var far := smoothstep(_reach - 40.0, _reach + 200.0, r) * 0.25
	var mesa := smoothstep(0.22, 0.3, m + far) * (38.0 + 30.0 * smoothstep(0.3, 0.6, m + far))
	return dunes + mesa * open


func _terrain_material() -> Material:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/terrain.gdshader")
	mat.set_shader_parameter("grass_albedo", _tex("aerial_beach_01", "diff"))
	mat.set_shader_parameter("rock_albedo", _tex("rock_face", "diff"))
	mat.set_shader_parameter("gravel_albedo", _tex("rocky_terrain_02", "diff"))
	mat.set_shader_parameter("grass_tint", Vector3(1.25, 0.92, 0.66))
	mat.set_shader_parameter("grass_scale", 0.035)
	mat.set_shader_parameter("rock_tint", Vector3(1.35, 0.72, 0.5))
	return mat


# ---------- Cactus and boulders ----------

func _build_desert_plants() -> void:
	var size := (_gw - 1) * CELL
	var cactus_n := Scenery.pieces("desert_cactus_pack").size() if Scenery.exists("desert_cactus_pack") else 0
	var rock_n := Scenery.pieces("desert_desert_rocks").size() if Scenery.exists("desert_desert_rocks") else 0
	var cactus := {}
	var rocks := {}
	var body := StaticBody3D.new()
	add_child(body)
	for i in 3500:
		var x := _min.x + _rng.randf() * size
		var z := _min.y + _rng.randf() * size
		var d := _road_dist_at(x, z)
		if d < RAIL_OFFSET + 3.0 or d > 300.0:
			continue
		var h := ground_height(x, z)
		var slope := absf(ground_height(x + 2.0, z) - h) + absf(ground_height(x, z + 2.0) - h)
		if slope > 1.2:
			continue
		var is_rock := _rng.randf() < 0.35
		var target := rocks if is_rock else cactus
		var count := rock_n if is_rock else cactus_n
		if count == 0:
			continue
		var idx := _rng.randi() % count
		if not target.has(idx):
			target[idx] = []
		var name := "desert_desert_rocks" if is_rock else "desert_cactus_pack"
		var box: AABB = Scenery.pieces(name)[idx]["box"]
		var want := _rng.randf_range(1.5, 5.0) if is_rock else _rng.randf_range(2.5, 6.5)
		var s := want / maxf(box.size.y, 0.01)
		target[idx].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * s), Vector3(x, h - 0.15, z)))
		if d < 40.0:
			var shape := CylinderShape3D.new()
			shape.radius = maxf(box.size.x, box.size.z) * s * 0.3
			shape.height = 3.0
			var col := CollisionShape3D.new()
			col.shape = shape
			col.position = Vector3(x, h + 1.5, z)
			body.add_child(col)
	for idx in cactus:
		Scenery.scatter_piece(self, "desert_cactus_pack", idx, cactus[idx], 420.0)
	for idx in rocks:
		Scenery.scatter_piece(self, "desert_desert_rocks", idx, rocks[idx], 520.0)


# ---------- Town ----------

func _place(name: String, height: float, k: int, side: float, gap: float, body: StaticBody3D, turn := 0.0) -> float:
	var parts := Scenery.parts(name, height)
	var box := AABB()
	var first := true
	for p in parts:
		var b: AABB = (p[1] as Transform3D) * (p[0] as Mesh).get_aabb()
		box = b if first else box.merge(b)
		first = false
	var r := _right(k) * side
	var depth := box.size.z
	var at := pts[k] + r * (RAIL_OFFSET + gap + depth / 2.0)
	if _road_dist_at(at.x, at.z) < RAIL_OFFSET + gap + depth / 2.0 - 3.0:
		return 0.0  # another stretch of road is in the way
	at.y = ground_height(at.x, at.z) - 0.2
	var node := Scenery.instance(name, height)
	node.transform = Transform3D(Basis.looking_at(r, Vector3.UP).rotated(Vector3.UP, turn), at)
	add_child(node)
	for g in node.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).visibility_range_end = 900.0
	var shape := BoxShape3D.new()
	shape.size = Vector3(box.size.x, box.size.y, box.size.z)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.transform = Transform3D(node.transform.basis, at + Vector3(0, box.size.y / 2.0, 0))
	body.add_child(col)
	return box.size.x


func _build_town() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	var n := pts.size()
	# Main street: buildings on both sides.
	for side: float in [-1.0, 1.0]:
		var f := TOWN_FROM
		while f < TOWN_TO:
			var k := (start_i + int(f * n)) % n
			var e: Array = TOWN[_rng.randi() % TOWN.size()]
			var w := _place(e[0], e[1], k, side, 4.0, body)
			f += (maxf(w, 8.0) + _rng.randf_range(6.0, 16.0)) / (n * SAMPLE_STEP)
	# Water tower behind the town, roadside stops along the long straight.
	var mid := (start_i + int((TOWN_FROM + TOWN_TO) / 2.0 * n)) % n
	_place("desert_western_watertower", 16.0, mid, -1.0, 34.0, body)
	var k1 := (start_i + int(STOPS_FROM * n) + 40) % n
	_place("desert_gas_station", 9.0, k1, 1.0, 6.0, body)
	var k2 := (start_i + int(STOPS_TO * n)) % n
	_place("desert_roadside_motel", 12.0, k2, -1.0, 8.0, body)
	_place("desert_mojave_motel_sign", 14.0, (k2 + 20) % n, -1.0, 1.5, body, PI / 2.0)
	# Red buttes far out in the desert.
	if Scenery.exists("desert_desert_cliff"):
		var xfs := []
		for i in 16:
			var a := TAU * i / 16.0 + _rng.randf_range(-0.12, 0.12)
			var r := _reach + _rng.randf_range(180.0, 330.0)
			var at := Vector3(cos(a) * r, 0, sin(a) * r)
			at.y = ground_height(at.x, at.z) - 8.0
			xfs.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), at))
		var h := _rng.randf_range(45.0, 70.0)
		var nodes := Scenery.scatter(self, "desert_desert_cliff", h, xfs)
		for nd in nodes:
			(nd as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# ---------- Track interface ----------

func setup_environment(parent: Node) -> void:
	super(parent)
	for c in parent.get_children():
		if c is WorldEnvironment:
			var env := (c as WorldEnvironment).environment
			env.ambient_light_energy = 0.95
			env.fog_light_color = Color(0.95, 0.78, 0.62)
			env.fog_density = 0.00045
			env.adjustment_saturation = 1.15
		elif c is DirectionalLight3D:
			var sun := c as DirectionalLight3D
			sun.rotation_degrees = Vector3(-38, 60, 0)
			sun.light_color = Color(1.0, 0.9, 0.76)
			sun.light_energy = 1.45


func menu_camera(t: float) -> Array:
	var c := pts[start_i]
	return [c + Vector3(sin(t) * 380, 110, cos(t) * 380), c + Vector3(0, 10, 0)]
