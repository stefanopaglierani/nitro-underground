class_name Ramp
extends StaticBody3D
## Jump ramp that rises along -Z and launches cars at `angle_deg` from its lip.
## The first half of the ramp is a curved transition from flat to the full slope, so cars roll
## onto it instead of being kicked into the air at the bottom edge.
## The node's origin is the middle of the low edge: place it where the ramp starts and turn it to
## face the direction of travel.

const SEGMENTS := 8


static func create(length: float, width: float, angle_deg: float, material: Material = null) -> Ramp:
	var ramp := Ramp.new()
	var k := tan(deg_to_rad(angle_deg))
	var a := length * 0.5
	var profile: Array[Vector2] = []  # (distance along the ramp, height)
	for i in SEGMENTS + 1:
		var x := a * i / SEGMENTS
		profile.append(Vector2(x, k * x * x / (2.0 * a)))
	profile.append(Vector2(length, k * a / 2.0 + k * (length - a)))
	var height := profile[-1].y
	var w := width / 2.0

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Triangles are wound clockwise seen from outside (Godot front faces). No bottom face.
	for i in profile.size() - 1:
		var p := profile[i]
		var q := profile[i + 1]
		var l0 := Vector3(-w, p.y, -p.x)
		var r0 := Vector3(w, p.y, -p.x)
		var l1 := Vector3(-w, q.y, -q.x)
		var r1 := Vector3(w, q.y, -q.x)
		_quad(st, l0, l1, r1, r0)
		_tri(st, Vector3(-w, 0, -p.x), Vector3(-w, 0, -q.x), l1)
		_tri(st, Vector3(-w, 0, -p.x), l1, l0)
		_tri(st, Vector3(w, 0, -p.x), r1, Vector3(w, 0, -q.x))
		_tri(st, Vector3(w, 0, -p.x), r0, r1)
	var top := Vector3(0, height, -length)
	_quad(st, Vector3(-w, 0, top.z), Vector3(w, 0, top.z), Vector3(w, height, top.z), Vector3(-w, height, top.z))
	st.generate_normals()
	var mesh := st.commit()

	var col := CollisionShape3D.new()
	col.shape = mesh.create_trimesh_shape()
	ramp.add_child(col)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material if material else CarModel.mat(Color(0.35, 0.33, 0.3), Color.BLACK, 0.0, 0.0, 0.8)
	ramp.add_child(mi)
	ramp.set_meta("length", length)
	ramp.set_meta("height", height)
	ramp.set_meta("angle_deg", angle_deg)
	return ramp


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, b, c)
	_tri(st, a, c, d)


## Height of the lip above the ground.
func height() -> float:
	return get_meta("height")
