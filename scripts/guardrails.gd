class_name GuardRails
extends Node3D
## Guardrails made of straight 4 m sections on posts. A car that hits a section hard enough tears it
## off: the section and its post fly away as loose pieces (cleared after a while) and leave a gap.
## Sections are drawn with two MultiMeshes and collide through static bodies of BODY_SECTIONS
## sections each, so a break only rebuilds one small body.

const HEIGHT := 0.35  # rail band, from 0.5 to 0.85 m
const THICK := 0.08
const POST := Vector3(0.12, 0.9, 0.12)
const BODY_SECTIONS := 16
## Impact (speed change in m/s along the contact) that tears a section off.
const BREAK_IMPACT := 6.0
const DEBRIS_LIFE := 7.0
const MAX_DEBRIS := 16

var _ends: Array = []  # [a, b] per section, at ground level
var _rails: MultiMesh
var _posts: MultiMesh
var _shapes: Array[CollisionShape3D] = []
var _broken := {}
var _debris: Array[RigidBody3D] = []
var _rail_mesh: BoxMesh
var _post_mesh: BoxMesh


## Builds the sections from consecutive pairs [a, b] of ground points.
func build(sections: Array, steel: Material) -> void:
	_ends = sections
	_rail_mesh = BoxMesh.new()
	_rail_mesh.size = Vector3(THICK, HEIGHT, 1.0)
	_rail_mesh.material = steel
	_post_mesh = BoxMesh.new()
	_post_mesh.size = POST
	_post_mesh.material = steel
	_rails = _multimesh(_rail_mesh, sections.size())
	_posts = _multimesh(_post_mesh, sections.size())
	var body: StaticBody3D
	for i in sections.size():
		_rails.set_instance_transform(i, _rail_xf(i))
		_posts.set_instance_transform(i, _post_xf(i))
		if i % BODY_SECTIONS == 0:
			body = StaticBody3D.new()
			body.set_meta("breakable", self)
			add_child(body)
		var a: Vector3 = sections[i][0]
		var b: Vector3 = sections[i][1]
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.3, 1.2, a.distance_to(b) + 0.3)
		var col := CollisionShape3D.new()
		col.shape = shape
		col.transform = Transform3D(Basis.looking_at(b - a, Vector3.UP), (a + b) / 2.0 + Vector3(0, 0.6, 0))
		col.set_meta("section", i)
		body.add_child(col)
		_shapes.append(col)


func _multimesh(mesh: Mesh, count: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)
	return mm


func _rail_xf(i: int) -> Transform3D:
	var a: Vector3 = _ends[i][0]
	var b: Vector3 = _ends[i][1]
	var basis := Basis.looking_at(b - a, Vector3.UP).scaled_local(Vector3(1, 1, a.distance_to(b) + 0.05))
	return Transform3D(basis, (a + b) / 2.0 + Vector3(0, 0.5 + HEIGHT / 2.0, 0))


func _post_xf(i: int) -> Transform3D:
	var a: Vector3 = _ends[i][0]
	var b: Vector3 = _ends[i][1]
	return Transform3D(Basis.looking_at(b - a, Vector3.UP), a + Vector3(0, POST.y / 2.0, 0))


## Called by a car that hit one of the bodies. Returns true if the section broke.
func smash(body: Object, shape_index: int, impact: float, car_velocity: Vector3) -> bool:
	if impact < BREAK_IMPACT or not (body is StaticBody3D):
		return false
	var sb := body as StaticBody3D
	var owner_id := sb.shape_find_owner(shape_index)
	var col := sb.shape_owner_get_owner(owner_id) as CollisionShape3D
	if col == null or not col.has_meta("section"):
		return false
	var i: int = col.get_meta("section")
	_break_section(i, car_velocity)
	# A really hard hit takes the next section along too.
	if impact > BREAK_IMPACT * 2.5:
		var along: Vector3 = (_ends[i][1] - _ends[i][0]).normalized()
		_break_section(i + (1 if car_velocity.dot(along) > 0.0 else -1), car_velocity * 0.7)
	return true


func _break_section(i: int, car_velocity: Vector3) -> void:
	if i < 0 or i >= _ends.size() or _broken.has(i):
		return
	_broken[i] = true
	var hidden := Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO)
	var rail_xf := _rail_xf(i)
	var post_xf := _post_xf(i)
	_rails.set_instance_transform(i, hidden)
	_posts.set_instance_transform(i, hidden)
	_shapes[i].set_deferred("disabled", true)
	var length: float = (_ends[i][0] as Vector3).distance_to(_ends[i][1])
	_spawn_piece(_rail_mesh, Vector3(THICK, HEIGHT, length), Transform3D(rail_xf.basis.orthonormalized(), rail_xf.origin), 60.0, car_velocity)
	_spawn_piece(_post_mesh, POST, post_xf, 15.0, car_velocity * 0.8)
	CarAudio.play_at(self, to_global(rail_xf.origin), "crash_metal.wav", 2.0, randf_range(0.85, 1.0))


func _spawn_piece(mesh: BoxMesh, size: Vector3, xf: Transform3D, kg: float, car_velocity: Vector3) -> void:
	var rb := RigidBody3D.new()
	rb.mass = kg
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	rb.add_child(col)
	var mi := MeshInstance3D.new()
	var m := mesh.duplicate() as BoxMesh
	m.size = size
	mi.mesh = m
	rb.add_child(mi)
	add_child(rb)
	rb.global_transform = xf
	var flat := Vector3(car_velocity.x, 0, car_velocity.z)
	rb.linear_velocity = flat * randf_range(0.55, 0.8) + Vector3(0, randf_range(2.0, 4.5), 0)
	rb.angular_velocity = Vector3(randf_range(-6, 6), randf_range(-4, 4), randf_range(-6, 6))
	_debris.append(rb)
	get_tree().create_timer(DEBRIS_LIFE).timeout.connect(func():
		if is_instance_valid(rb):
			_debris.erase(rb)
			rb.queue_free())
	while _debris.size() > MAX_DEBRIS:
		var old: RigidBody3D = _debris.pop_front()
		if is_instance_valid(old):
			old.queue_free()
