class_name CarModel
extends RefCounted
## Builds a low-poly placeholder car out of primitive meshes. The front of the car points to -Z.


static func mat(color: Color, emission := Color.BLACK, energy := 0.0, metallic := 0.0, rough := 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = rough
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m


static func box(parent: Node3D, size: Vector3, pos: Vector3, material: Material, node_name := "") -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = material
	if node_name != "":
		mi.name = node_name
	parent.add_child(mi)
	return mi


static func build(paint: Color, police := false) -> Node3D:
	var root := Node3D.new()
	root.name = "Model"
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)

	var paint_mat := mat(paint, Color.BLACK, 0.0, 0.6, 0.3)
	var dark := mat(Color(0.05, 0.05, 0.07), Color.BLACK, 0.0, 0.2, 0.2)
	var glass := mat(Color(0.08, 0.1, 0.16), Color.BLACK, 0.0, 0.5, 0.1)

	if police:
		box(body, Vector3(1.9, 0.55, 4.3), Vector3(0, 0.6, 0), mat(Color(0.92, 0.92, 0.95), Color.BLACK, 0.0, 0.4, 0.3))
		box(body, Vector3(1.94, 0.3, 1.9), Vector3(0, 0.55, 0.1), dark)
	else:
		box(body, Vector3(1.9, 0.5, 4.2), Vector3(0, 0.58, 0), paint_mat)
		# front splitter and side skirts give a "tuned" silhouette
		box(body, Vector3(1.96, 0.12, 4.0), Vector3(0, 0.36, 0), dark)
	box(body, Vector3(1.6, 0.45, 2.0), Vector3(0, 1.05, 0.25), glass)
	box(body, Vector3(1.5, 0.06, 1.7), Vector3(0, 1.29, 0.25), paint_mat if not police else mat(Color.WHITE))

	if not police:
		box(body, Vector3(1.8, 0.07, 0.45), Vector3(0, 1.08, 1.95), paint_mat)
		box(body, Vector3(0.08, 0.25, 0.2), Vector3(-0.6, 0.92, 1.95), dark)
		box(body, Vector3(0.08, 0.25, 0.2), Vector3(0.6, 0.92, 1.95), dark)

	var head := mat(Color.WHITE, Color(1, 0.97, 0.85), 4.0)
	box(body, Vector3(0.45, 0.14, 0.06), Vector3(-0.6, 0.65, -2.11), head)
	box(body, Vector3(0.45, 0.14, 0.06), Vector3(0.6, 0.65, -2.11), head)
	var tail := mat(Color(0.6, 0, 0), Color(1, 0.05, 0.05), 1.5)
	box(body, Vector3(0.5, 0.12, 0.06), Vector3(-0.6, 0.68, 2.11), tail, "TailL")
	box(body, Vector3(0.5, 0.12, 0.06), Vector3(0.6, 0.68, 2.11), tail, "TailR")
	root.set_meta("tail_mat", tail)

	if police:
		var red := mat(Color(0.5, 0, 0), Color(1, 0.05, 0.05), 0.2)
		var blue := mat(Color(0, 0, 0.5), Color(0.1, 0.3, 1), 0.2)
		box(body, Vector3(0.6, 0.18, 0.4), Vector3(-0.35, 1.4, 0.2), red)
		box(body, Vector3(0.6, 0.18, 0.4), Vector3(0.35, 1.4, 0.2), blue)
		root.set_meta("siren_red", red)
		root.set_meta("siren_blue", blue)

	var tire := mat(Color(0.03, 0.03, 0.03), Color.BLACK, 0.0, 0.0, 0.9)
	var rim := mat(Color(0.75, 0.75, 0.8), Color.BLACK, 0.0, 0.9, 0.2)
	for w in [["WheelFL", -0.95, -1.35], ["WheelFR", 0.95, -1.35], ["WheelRL", -0.95, 1.35], ["WheelRR", 0.95, 1.35]]:
		var pivot := Node3D.new()
		pivot.name = w[0]
		pivot.position = Vector3(w[1], 0.38, w[2])
		root.add_child(pivot)
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.38
		cyl.bottom_radius = 0.38
		cyl.height = 0.3
		cyl.radial_segments = 12
		var wheel := MeshInstance3D.new()
		wheel.mesh = cyl
		wheel.material_override = tire
		wheel.rotation_degrees.z = 90
		pivot.add_child(wheel)
		var hub := CylinderMesh.new()
		hub.top_radius = 0.22
		hub.bottom_radius = 0.22
		hub.height = 0.32
		hub.radial_segments = 8
		var hub_mi := MeshInstance3D.new()
		hub_mi.mesh = hub
		hub_mi.material_override = rim
		hub_mi.rotation_degrees.z = 90
		pivot.add_child(hub_mi)
	return root
