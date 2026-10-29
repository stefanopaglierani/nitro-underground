class_name CarModel
extends RefCounted
## Builds the car models: CC0 rgsdev cars, CC0 KayKit cars with lights added on top (see
## assets/LICENSES.md), or a blocky placeholder made of primitive meshes if the model is missing.
## The front points to -Z.
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
## rgsdev cars (Free Low Poly Vehicles Pack): real size but a little wide for the physics body,
## facing +Z, one mesh per wheel and named materials ("body red", "rear lights", "flashers siren red").
const RGSDEV_DIR := "res://assets/cars_rgsdev/"
const RGSDEV_SCALE := 0.78
const RGSDEV_WHEELS := {"WheelFL": " wheel front left", "WheelFR": " wheel front right", "WheelRL": " wheel rear left", "WheelRR": " wheel rear right"}
## Materials whose meshes belong to a wheel in the detailed glTF cars (tyres, rims, brakes).
## "rim" only at a word start, so "Trim" does not count.
const WHEEL_PARTS := ["wheel", "_rim", "calliper", "tire", "breaks"]
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
	var entry := CarCatalog.find(body)
	if entry.get("kind", "") in ["hd", "kenney"]:
		if ResourceLoader.exists(CarCatalog.model_path(entry)):
			return build_generic(paint, entry)
		body = "sports"
	if ResourceLoader.exists(RGSDEV_DIR + body + ".fbx"):
		return build_rgsdev(paint, body)
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


## rgsdev car. A paint with alpha 0 keeps the model's own colours; otherwise it replaces the main
## body colour. Lights and sirens get their own emissive materials for car.gd to drive.
static func build_rgsdev(paint: Color, body: String) -> Node3D:
	var path := RGSDEV_DIR + body + ".fbx"
	if body.begins_with("police"):
		paint = Color(0, 0, 0, 0)
	if not _scenes.has(path):
		_scenes[path] = load(path)
	var root := Node3D.new()
	root.name = "Model"
	var model := (_scenes[path] as PackedScene).instantiate() as Node3D
	model.scale = Vector3.ONE * RGSDEV_SCALE
	model.rotation.y = PI
	root.add_child(model)

	var tail := mat(Color(0.6, 0, 0), Color(1, 0.05, 0.05), 1.5)
	var head := mat(Color.WHITE, Color(1, 0.97, 0.85), 3.0)
	var glass := mat(Color(0.06, 0.08, 0.11), Color.BLACK, 0.0, 0.6, 0.05)
	var red := mat(Color(0.5, 0, 0), Color(1, 0.05, 0.05), 0.3)
	var blue := mat(Color(0, 0, 0.5), Color(0.1, 0.3, 1), 0.3)
	var materials := {}
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := (mi as MeshInstance3D).mesh
		for i in mesh.get_surface_count():
			var src := mesh.surface_get_material(i) as BaseMaterial3D
			var key := src.resource_name if src else ""
			if not materials.has(key):
				materials[key] = _rgsdev_material(key, src, i == 0 and not String(mi.name).contains("wheel"), paint, tail, head, glass, red, blue)
			(mi as MeshInstance3D).set_surface_override_material(i, materials[key])

	for pivot_name in RGSDEV_WHEELS:
		var pivot := Node3D.new()
		pivot.name = pivot_name
		root.add_child(pivot)
		var wheel := model.find_child("*" + RGSDEV_WHEELS[pivot_name], false, false) as Node3D
		if wheel == null:
			continue
		var xf := model.transform * wheel.transform
		# Some wheel meshes have their origin at the car's centre: use the middle of the mesh.
		pivot.position = (xf * (wheel as MeshInstance3D).get_aabb()).get_center()
		model.remove_child(wheel)
		wheel.owner = null
		pivot.add_child(wheel)
		wheel.transform = Transform3D(Basis(), -pivot.position) * xf
	root.set_meta("tail_mat", tail)
	if body.begins_with("police"):
		root.set_meta("siren_red", red)
		root.set_meta("siren_blue", blue)
	return root


## Transform of node relative to root (works before the model is in the scene tree).
static func _xf_in(node: Node3D, root: Node3D) -> Transform3D:
	var xf := node.transform
	var n := node.get_parent() as Node3D
	while n != root:
		xf = n.transform * xf
		n = n.get_parent() as Node3D
	return xf


## glTF car from the catalog (detailed Sketchfab cars, Kenney Car Kit), scaled to entry.len
## metres and set on the ground. Meshes that are wheel parts (by node or material name) go under
## the pivot of their corner; the paint and the tail lights get materials car.gd can drive.
static func build_generic(paint: Color, entry: Dictionary) -> Node3D:
	var path := CarCatalog.model_path(entry)
	if not _scenes.has(path):
		_scenes[path] = load(path)
	var root := Node3D.new()
	root.name = "Model"
	var model := (_scenes[path] as PackedScene).instantiate() as Node3D
	root.add_child(model)

	var tail := mat(Color(0.6, 0, 0), Color(1, 0.05, 0.05), 1.5)
	var paint_mat: Material = null
	if paint.a > 0.0:
		var pm := mat(paint, Color.BLACK, 0.0, 0.4, 0.25)
		pm.clearcoat_enabled = true
		pm.clearcoat = 1.0
		pm.clearcoat_roughness = 0.05
		paint_mat = pm
	var meshes: Array[MeshInstance3D] = []
	var bounds := AABB()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		meshes.append(mi)
		var bb: AABB = _xf_in(mi, model) * mi.get_aabb()
		bounds = bb if meshes.size() == 1 else bounds.merge(bb)
	# Facing +Z in the file: turn to -Z, scale to the wanted length, wheels on the ground.
	var k: float = entry["len"] / maxf(bounds.size.z, 0.001)
	model.scale = Vector3.ONE * k
	model.rotation.y = PI
	model.position = Vector3(bounds.get_center().x * k, -bounds.position.y * k, bounds.get_center().z * k)

	var corners := {"WheelFL": [], "WheelFR": [], "WheelRL": [], "WheelRR": []}
	var wheel_bounds := {}
	for mi in meshes:
		var all_wheel := String(mi.name).to_lower().contains("wheel")
		var named := all_wheel
		if not named:
			all_wheel = true
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i)
			var key: String = src.resource_name if src else ""
			if key != "" and key == entry.get("paint", "") and paint_mat:
				mi.set_surface_override_material(i, paint_mat)
			elif key != "" and key == entry.get("tail", ""):
				mi.set_surface_override_material(i, tail)
			if not named:
				var is_wheel := false
				var low := key.to_lower()
				for part in WHEEL_PARTS:
					if low.contains(part) or low.begins_with(part.trim_prefix("_")):
						is_wheel = true
				all_wheel = all_wheel and is_wheel
		if not all_wheel:
			continue
		var xf := model.transform * _xf_in(mi, model)
		var bb: AABB = xf * mi.get_aabb()
		var c := bb.get_center()
		# A mesh holding several wheels at once cannot steer, and parts near the middle or up high
		# (badges, trims sharing a material) are not wheels: leave them on the body.
		if bb.size.x > 0.8 or bb.size.z > 1.6 or absf(c.x) < bounds.size.x * k * 0.25 or c.y > 0.9:
			continue
		var corner := "Wheel%s%s" % ["F" if c.z < 0.0 else "R", "L" if c.x < 0.0 else "R"]
		corners[corner].append([mi, xf])
		# The pivot goes at the middle of the biggest part of the corner: the tyre.
		if not wheel_bounds.has(corner) or bb.get_volume() > (wheel_bounds[corner] as AABB).get_volume():
			wheel_bounds[corner] = bb
	for corner in corners:
		var pivot := Node3D.new()
		pivot.name = corner
		root.add_child(pivot)
		if not wheel_bounds.has(corner):
			continue
		pivot.position = (wheel_bounds[corner] as AABB).get_center()
		for e in corners[corner]:
			var mi: MeshInstance3D = e[0]
			mi.get_parent().remove_child(mi)
			mi.owner = null
			pivot.add_child(mi)
			mi.transform = Transform3D(Basis(), -pivot.position) * (e[1] as Transform3D)
	root.set_meta("tail_mat", tail)
	if entry["id"].contains("police"):
		var red := mat(Color(0.5, 0, 0), Color(1, 0.05, 0.05), 0.3)
		var blue := mat(Color(0, 0, 0.5), Color(0.1, 0.3, 1), 0.3)
		box(root, Vector3(0.5, 0.12, 0.3), Vector3(-0.3, bounds.size.y * k + 0.02, 0.0), red)
		box(root, Vector3(0.5, 0.12, 0.3), Vector3(0.3, bounds.size.y * k + 0.02, 0.0), blue)
		root.set_meta("siren_red", red)
		root.set_meta("siren_blue", blue)
	return root


static func _rgsdev_material(key: String, src: BaseMaterial3D, main_body: bool, paint: Color, tail: StandardMaterial3D, head: StandardMaterial3D, glass: StandardMaterial3D, red: StandardMaterial3D, blue: StandardMaterial3D) -> Material:
	if key.contains("siren red"):
		return red
	if key.contains("siren blue"):
		return blue
	if key == "rear lights":
		return tail
	if key == "headlights":
		return head
	if key == "windows":
		return glass
	var col := src.albedo_color if src else Color.GRAY
	if key.begins_with("body"):
		if main_body and paint.a > 0.0:
			col = paint
		# Glossy car paint: a clear coat over a slightly metallic base.
		var m := mat(col, Color.BLACK, 0.0, 0.0 if key == "body black" else 0.35, 0.18 if key == "body black" else 0.28)
		m.clearcoat_enabled = true
		m.clearcoat = 0.8
		m.clearcoat_roughness = 0.1
		return m
	if key == "wheels":
		return mat(col, Color.BLACK, 0.0, 0.9, 0.25)
	return mat(col, Color.BLACK, 0.0, 0.0, 0.85)


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
