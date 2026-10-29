class_name City
extends Node3D
## Night city on a square grid: roads every SPACING metres, one block of buildings between them.
## Grid nodes (intersections) go from (0, 0) to (BLOCKS, BLOCKS).

const BLOCKS := 6
const SPACING := 64.0
const ROAD := 14.0
const BLOCK := SPACING - ROAD
const NEON := [Color(1, 0.12, 0.6), Color(0.1, 0.9, 1), Color(0.65, 0.25, 1), Color(1, 0.55, 0.1), Color(0.25, 1, 0.45)]

var extent := BLOCKS * SPACING
var _rng := RandomNumberGenerator.new()
var _building_shader: Shader = preload("res://shaders/building.gdshader")
var _prop_rng := RandomNumberGenerator.new()  # separate from _rng so buildings stay the same
var _props := {}

# CC0 materials and props: see assets/LICENSES.md.
const MAT_GROUND := preload("res://assets/materials/road_asphalt.tres")
const MAT_ROAD := preload("res://assets/materials/road_asphalt_wet.tres")
const MAT_WALK := preload("res://assets/materials/sidewalk_tiles.tres")
const CLUTTER: Array[String] = ["barrel_03", "wooden_crate_02", "plastic_crate_02"]


func node_pos(n: Vector2i) -> Vector3:
	return Vector3(n.x * SPACING, 0.0, n.y * SPACING)


func snap(pos: Vector3) -> Vector2i:
	return Vector2i(clampi(roundi(pos.x / SPACING), 0, BLOCKS), clampi(roundi(pos.z / SPACING), 0, BLOCKS))


func _clamp_node(n: Vector2i) -> Vector2i:
	return Vector2i(clampi(n.x, 0, BLOCKS), clampi(n.y, 0, BLOCKS))


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## Next point to drive to on the way from pos to target, following the roads.
func route_point(pos: Vector3, target: Vector3) -> Vector3:
	var a := snap(pos)
	var b := snap(target)
	if a == b or pos.distance_to(target) < 40.0:
		return target
	var near := node_pos(a)
	if pos.distance_to(near) < 10.0:
		var d := b - a
		var step := Vector2i(signi(d.x), 0) if absi(d.x) >= absi(d.y) else Vector2i(0, signi(d.y))
		return node_pos(_clamp_node(a + step))
	# Between two intersections: head to the end of this road that is closer to the target.
	var gx := pos.x / SPACING
	var gz := pos.z / SPACING
	var c1: Vector2i
	var c2: Vector2i
	if absf(gz - roundf(gz)) < absf(gx - roundf(gx)):
		c1 = Vector2i(floori(gx), roundi(gz))
		c2 = Vector2i(ceili(gx), roundi(gz))
	else:
		c1 = Vector2i(roundi(gx), floori(gz))
		c2 = Vector2i(roundi(gx), ceili(gz))
	c1 = _clamp_node(c1)
	c2 = _clamp_node(c2)
	return node_pos(c1) if _manhattan(c1, b) <= _manhattan(c2, b) else node_pos(c2)


func build() -> void:
	_rng.seed = 2077
	_prop_rng.seed = 1977
	var asphalt: Material = MAT_GROUND
	var road: Material = MAT_ROAD
	var walk: Material = MAT_WALK
	var mid := extent / 2.0

	# Ground with collision.
	_static_box(Vector3(mid, -0.5, mid), Vector3(extent + 200, 1.0, extent + 200), asphalt)

	for i in BLOCKS + 1:
		var c := i * SPACING
		CarModel.box(self, Vector3(extent + ROAD, 0.02, ROAD), Vector3(mid, 0.01, c), road)
		CarModel.box(self, Vector3(ROAD, 0.022, extent + ROAD), Vector3(c, 0.011, mid), road)
	_lane_marks()
	_ramps()

	for bx in BLOCKS:
		for bz in BLOCKS:
			var center := Vector3(bx * SPACING + SPACING / 2.0, 0.0, bz * SPACING + SPACING / 2.0)
			CarModel.box(self, Vector3(BLOCK, 0.3, BLOCK), center + Vector3(0, 0.15, 0), walk)
			_collider(center + Vector3(0, 3, 0), Vector3(BLOCK - 0.5, 6, BLOCK - 0.5))
			_buildings(center)

	for i in BLOCKS + 1:
		for j in BLOCKS + 1:
			_street_lamp(node_pos(Vector2i(i, j)) + Vector3(ROAD / 2.0 + 1.0, 0, ROAD / 2.0 + 1.0))
			# Utility box on the opposite corner, every other intersection, only where there is a sidewalk.
			if i < BLOCKS and j > 0 and (i + j) % 2 == 0:
				_prop("utility_box_01", node_pos(Vector2i(i, j)) + Vector3(ROAD / 2.0 + 1.0, 0.3, -ROAD / 2.0 - 1.0), PI)

	# Barriers around the city edge.
	var barrier := CarModel.mat(Color(0.15, 0.12, 0.1), Color(1, 0.45, 0.05), 1.2)
	var e := extent + ROAD / 2.0 + 1.0
	var s := -ROAD / 2.0 - 1.0
	_static_box(Vector3(mid, 0.6, s), Vector3(extent + ROAD + 4, 1.2, 2), barrier)
	_static_box(Vector3(mid, 0.6, e), Vector3(extent + ROAD + 4, 1.2, 2), barrier)
	_static_box(Vector3(s, 0.6, mid), Vector3(2, 1.2, extent + ROAD + 4), barrier)
	_static_box(Vector3(e, 0.6, mid), Vector3(2, 1.2, extent + ROAD + 4), barrier)


## Two-way jump ramps in the middle of a few roads, between the two traffic lanes (traffic drives
## at 3.5 m from the centre line, so a 5 m wide ramp leaves both lanes free).
func _ramps() -> void:
	var mat: Material = load("res://assets/materials/wall_metal_sheet.tres") if ResourceLoader.exists("res://assets/materials/wall_metal_sheet.tres") else null
	var length := 14.0
	# [along_x, road index, block index along the road]
	for r in [[true, 1, 2], [true, 5, 3], [false, 2, 4], [false, 4, 1]]:
		var ramp := Ramp.create(length, 5.0, 15.0, mat, true)
		var mid: float = (r[2] + 0.5) * SPACING
		if r[0]:
			ramp.position = Vector3(mid - length, 0, r[1] * SPACING)
			ramp.rotation.y = -PI / 2
		else:
			ramp.position = Vector3(r[1] * SPACING, 0, mid - length)
			ramp.rotation.y = PI
		add_child(ramp)


func _lane_marks() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.25, 0.03, 3.0)
	mesh.material = CarModel.mat(Color(0.85, 0.85, 0.8), Color(0.9, 0.9, 0.8), 0.4)
	var xforms: Array[Transform3D] = []
	for i in BLOCKS + 1:
		var c := i * SPACING
		for b in BLOCKS:
			var t := ROAD / 2.0 + 4.0
			while t < SPACING - ROAD / 2.0 - 3.0:
				var along := b * SPACING + t
				xforms.append(Transform3D(Basis(), Vector3(c, 0.03, along)))
				xforms.append(Transform3D(Basis(Vector3.UP, PI / 2), Vector3(along, 0.03, c)))
				t += 8.0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for k in xforms.size():
		mm.set_instance_transform(k, xforms[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)


func _buildings(center: Vector3) -> void:
	var lot := (BLOCK - 6.0) / 2.0
	for ix in 2:
		for iz in 2:
			if _rng.randf() < 0.12:
				_parking(center + Vector3((ix - 0.5) * lot, 0.3, (iz - 0.5) * lot))
				continue  # empty lot: parking
			var w := lot - _rng.randf_range(1.0, 4.0)
			var d := lot - _rng.randf_range(1.0, 4.0)
			var h := _rng.randf_range(7.0, 24.0)
			var pos := center + Vector3((ix - 0.5) * lot, h / 2.0 + 0.3, (iz - 0.5) * lot)
			var m := ShaderMaterial.new()
			m.shader = _building_shader
			var shade := _rng.randf_range(0.05, 0.11)
			m.set_shader_parameter("base_color", Color(shade, shade, shade * 1.25))
			m.set_shader_parameter("seed", _rng.randf() * 100.0)
			m.set_shader_parameter("lit_ratio", _rng.randf_range(0.2, 0.5))
			CarModel.box(self, Vector3(w, h, d), pos, m)
			# Neon band around the roof edge.
			var neon: Color = NEON[_rng.randi() % NEON.size()]
			CarModel.box(self, Vector3(w + 0.3, 0.35, d + 0.3), pos + Vector3(0, h / 2.0 - 0.6, 0), CarModel.mat(neon * 0.5, neon, 3.0))
			if _rng.randf() < 0.35:
				var sign_col: Color = NEON[_rng.randi() % NEON.size()]
				CarModel.box(self, Vector3(w * 0.5, 1.6, 0.3), pos + Vector3(0, h / 2.0 + 1.2, 0), CarModel.mat(sign_col * 0.4, sign_col, 4.0))


## Empty lot: a couple of parked covered cars and some clutter (visual only, the block collider covers it).
func _parking(pos: Vector3) -> void:
	for k in _prop_rng.randi_range(1, 2):
		_prop("covered_car", pos + Vector3((k - 0.5) * 3.2, 0.0, _prop_rng.randf_range(-2.0, 2.0)), _prop_rng.randf_range(-0.15, 0.15))
	for k in _prop_rng.randi_range(2, 4):
		var spot := pos + Vector3(_prop_rng.randf_range(-8.0, 8.0), 0.0, _prop_rng.randf_range(6.0, 8.0) * (1 if _prop_rng.randf() < 0.5 else -1))
		_prop(CLUTTER[k % CLUTTER.size()], spot, _prop_rng.randf() * TAU)


## Instances a glTF prop from assets/props/<name>/. Does nothing if the asset is missing.
func _prop(prop_name: String, pos: Vector3, yaw: float) -> void:
	if not _props.has(prop_name):
		var path := "res://assets/props/%s/%s.gltf" % [prop_name, prop_name]
		_props[prop_name] = load(path) if ResourceLoader.exists(path) else null
	var scene: PackedScene = _props[prop_name]
	if scene == null:
		return
	var inst := scene.instantiate() as Node3D
	inst.position = pos
	inst.rotation.y = yaw
	add_child(inst)


func _street_lamp(pos: Vector3) -> void:
	var pole := CarModel.mat(Color(0.2, 0.2, 0.22))
	CarModel.box(self, Vector3(0.25, 7, 0.25), pos + Vector3(0, 3.5, 0), pole)
	CarModel.box(self, Vector3(0.8, 0.25, 0.8), pos + Vector3(-0.6, 7, -0.6), CarModel.mat(Color(1, 0.8, 0.5), Color(1, 0.75, 0.4), 6.0))


func _collider(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	add_child(body)


func _static_box(pos: Vector3, size: Vector3, material: Material) -> void:
	CarModel.box(self, size, pos, material)
	_collider(pos, size)
