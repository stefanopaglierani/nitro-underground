class_name CarModel
extends RefCounted
## Builds the car models: CC0 KayKit cars (see assets/LICENSES.md) with lights added on top, or a
## blocky placeholder made of primitive meshes if the model is missing. The front points to -Z.
## Every model has WheelFL/FR/RL/RR pivots and the tail_mat meta (police: siren_red/siren_blue).

const KAYKIT_DIR := "res://assets/kaykit_city_builder_bits/"
## KayKit cars are about 1/5 scale and face +Z.
const KAYKIT_SCALE := 4.5
## Lifts the model so its wheels touch the ground when the wheel pivots sit at WHEEL_Y.
const KAYKIT_Y := 0.3
const WHEEL_Y := 0.35
## Body colour swatch of each car in the atlas (u0, v0, u1, v1) and its average linear brightness.
const PAINT_SWATCH := {
	"car_sedan": [Vector4(0.25, 0.25, 0.375, 0.5), 0.14],
	"car_hatchback": [Vector4(0.5, 0.25, 0.625, 0.5), 0.219],
	"car_stationwagon": [Vector4(0.25, 0.5, 0.375, 0.75), 0.158],
}
const WHEEL_SUFFIX := {"WheelFL": "_wheel_front_left", "WheelFR": "_wheel_front_right", "WheelRL": "_wheel_rear_left", "WheelRR": "_wheel_rear_right"}
static var _scenes := {}
static var _paint_shader: Shader = preload("res://shaders/car_paint.gdshader")


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


## body: KayKit model name (car_sedan, car_hatchback, car_stationwagon, car_taxi, car_police).
## A paint with alpha 0 keeps the model's own colours.
static func build(paint: Color, police := false, body := "") -> Node3D:
	if body == "":
		body = "car_police" if police else "car_sedan"
	var path := KAYKIT_DIR + body + ".gltf"
	if not _scenes.has(path):
		_scenes[path] = load(path) if ResourceLoader.exists(path) else null
	if _scenes[path] == null:
		return build_blocky(paint, police)
	var root := Node3D.new()
	root.name = "Model"
	var model := (_scenes[path] as PackedScene).instantiate() as Node3D
	model.scale = Vector3.ONE * KAYKIT_SCALE
	model.rotation.y = PI
	model.position.y = KAYKIT_Y
	root.add_child(model)

	var m := ShaderMaterial.new()
	m.shader = _paint_shader
	var tex: Texture2D
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var surf_mat := (mi as MeshInstance3D).mesh.surface_get_material(0)
		if surf_mat is BaseMaterial3D:
			tex = surf_mat.albedo_texture
		(mi as MeshInstance3D).material_override = m
	m.set_shader_parameter("atlas", tex)
	if paint.a > 0.0 and PAINT_SWATCH.has(body):
		m.set_shader_parameter("paint_rect", PAINT_SWATCH[body][0])
		m.set_shader_parameter("swatch_luma", PAINT_SWATCH[body][1])
		m.set_shader_parameter("paint", paint)

	# Move each wheel under a pivot the car can raise with the suspension and turn to steer.
	for pivot_name in WHEEL_SUFFIX:
		var wheel := model.find_child(body + WHEEL_SUFFIX[pivot_name], true, false) as Node3D
		var pivot := Node3D.new()
		pivot.name = pivot_name
		root.add_child(pivot)
		if wheel == null:
			continue
		# Wheel transform in the root's space (the model is not in the scene tree yet).
		var xf := wheel.transform
		var n := wheel.get_parent() as Node3D
		while n != model:
			xf = n.transform * xf
			n = n.get_parent() as Node3D
		xf = model.transform * xf
		pivot.position = Vector3(xf.origin.x, WHEEL_Y, xf.origin.z)
		wheel.get_parent().remove_child(wheel)
		wheel.owner = null
		pivot.add_child(wheel)
		wheel.transform = Transform3D(xf.basis, Vector3.ZERO)

	var lights := Node3D.new()
	lights.name = "Lights"
	root.add_child(lights)
	var head := mat(Color.WHITE, Color(1, 0.97, 0.85), 4.0)
	box(lights, Vector3(0.4, 0.12, 0.05), Vector3(-0.62, 0.78, -2.13), head)
	box(lights, Vector3(0.4, 0.12, 0.05), Vector3(0.62, 0.78, -2.13), head)
	var tail := mat(Color(0.6, 0, 0), Color(1, 0.05, 0.05), 1.5)
	box(lights, Vector3(0.45, 0.12, 0.05), Vector3(-0.62, 0.85, 2.11), tail, "TailL")
	box(lights, Vector3(0.45, 0.12, 0.05), Vector3(0.62, 0.85, 2.11), tail, "TailR")
	root.set_meta("tail_mat", tail)
	if police:
		var red := mat(Color(0.5, 0, 0), Color(1, 0.05, 0.05), 0.2)
		var blue := mat(Color(0, 0, 0.5), Color(0.1, 0.3, 1), 0.2)
		box(lights, Vector3(0.55, 0.16, 0.35), Vector3(-0.32, 1.72, 0.1), red)
		box(lights, Vector3(0.55, 0.16, 0.35), Vector3(0.32, 1.72, 0.1), blue)
		root.set_meta("siren_red", red)
		root.set_meta("siren_blue", blue)
	return root


## Placeholder car made of boxes, used when a model file is missing.
static func build_blocky(paint: Color, police := false) -> Node3D:
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
