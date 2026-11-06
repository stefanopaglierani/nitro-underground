class_name CarModel
extends RefCounted
## Builds the car models from the catalog's detailed glTF cars (see assets/LICENSES.md), or a
## blocky placeholder made of primitive meshes if the model is missing.
## The front points to -Z.
## Every model has WheelFL/FR/RL/RR pivots and the tail_mat meta (police: siren_red/siren_blue).

## Materials whose meshes belong to a wheel in the detailed glTF cars (tyres, rims, brakes).
## "rim" only at a word start, so "Trim" does not count.
const WHEEL_PARTS := ["wheel", "_rim", "calliper", "caliper", "tire", "tyre", "breaks", "disc", "rubber"]
## Mesh or material names that mark the back and the front of a model, to find which way it faces.
const REAR_PARTS := ["tail", "brakelight", "brake_light", "rear", "reverse", "trunk", "exhaust"]
const FRONT_PARTS := ["headlight", "head_light", "front", "hood", "grill", "windshield"]
static var _scenes := {}
## Detailed cars already merged: path -> {"body": meshes, "wheels": {pivot: [position, meshes]}, "height"}.
static var _merged := {}
## True while tools/bake_cars.gd prepares the cars: always weld, never read a baked file.
static var bake_mode := false
## Node or material names left out of the car being built (catalog "hide": logos, a backdrop).
static var _hide: Array = []
const BAKED_DIR := "res://assets/cars_baked/"
## Models with more pieces than this are welded together when built (see build_generic).
const MERGE_MIN_SURFACES := 40


## Forgets the car models read so far, so their memory is freed once no car uses them (the title
## screen keeps only the car on show; leaving a race frees the race cars).
## Lets go of one car's model, read again the next time it is built.
static func forget(path: String) -> void:
	_merged.erase(path)
	_scenes.erase(path)


static func clear_cache() -> void:
	_scenes.clear()
	_merged.clear()


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
		body = "police_car" if police else CarCatalog.GARAGE[0]
	var entry := CarCatalog.find(body)
	if not entry.is_empty() and (ResourceLoader.exists(baked_path(body)) or ResourceLoader.exists(CarCatalog.model_path(entry))):
		return build_generic(paint, entry)
	return build_blocky(paint, police)


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
	var tail := mat(Color(0.6, 0, 0), Color(1, 0.05, 0.05), 1.5)
	var paint_mat: Material = null
	if paint.a > 0.0:
		var pm := mat(paint, Color.BLACK, 0.0, 0.4, 0.25)
		pm.clearcoat_enabled = true
		pm.clearcoat = 1.0
		pm.clearcoat_roughness = 0.05
		paint_mat = pm
	if _merged.has(path):
		return _from_merged(_merged[path], entry, paint_mat, tail)
	# A car prepared ahead of time (tools/bake_cars.gd) is ready to show as it is.
	var baked := baked_path(entry["id"])
	if not bake_mode and ResourceLoader.exists(baked):
		var res := load(baked) as BakedCar
		if res:
			_merged[path] = res.to_data()
			return _from_merged(_merged[path], entry, paint_mat, tail)
	if not _scenes.has(path):
		_scenes[path] = load(path)
	var root := Node3D.new()
	root.name = "Model"
	var model := (_scenes[path] as PackedScene).instantiate() as Node3D
	root.add_child(model)
	_unskin(model)
	# Bounds of the car body, leaving out flat ground planes (shadow cards), which are hidden.
	_hide = entry.get("hide", [])
	var meshes: Array[MeshInstance3D] = []
	var boxes: Array[AABB] = []
	var bounds := AABB()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		# Parts the catalog leaves out (a showroom backdrop shipped with the model).
		if String(mi.name) in _hide or _all_hidden(mi):
			mi.visible = false
			continue
		var bb: AABB = _xf_in(mi, model) * mi.get_aabb()
		if bb.size.y < 0.02 * maxf(bb.size.x, bb.size.z) and bb.size.x * bb.size.z > 0.0:
			var flat := bb.size.x * bb.size.z
			if bounds.size == Vector3.ZERO or flat > 0.5 * bounds.size.x * bounds.size.z:
				mi.visible = false
				continue
		meshes.append(mi)
		boxes.append(bb)
		bounds = bb if meshes.size() == 1 else bounds.merge(bb)
	# Turn the model so its length runs along Z and its front points to -Z. Models are expected to
	# face +Z; one that is longer across X is turned a quarter, and then lights or parts named
	# rear/front tell which end is which. A catalog "yaw" (degrees) overrides the guess.
	var turn := PI
	if entry.has("yaw"):
		turn += deg_to_rad(entry["yaw"])
	else:
		if bounds.size.x > bounds.size.z:
			turn += PI / 2.0
		var rear := 0.0
		var front := 0.0
		for i in meshes.size():
			var label := (String(meshes[i].name) + " " + _material_names(meshes[i])).to_lower()
			var z := (Basis(Vector3.UP, turn) * boxes[i].get_center()).z
			for part in REAR_PARTS:
				if label.contains(part):
					rear += z
			for part in FRONT_PARTS:
				if label.contains(part):
					front += z
		if bounds.size.x > bounds.size.z and rear < front:
			turn += PI  # the back of the car would end up at the front
	var r := Basis(Vector3.UP, turn)
	var rb: AABB = Transform3D(r, Vector3.ZERO) * bounds
	var k: float = entry["len"] / maxf(rb.size.z, 0.001)
	model.transform = Transform3D(r.scaled(Vector3.ONE * k), Vector3(-rb.get_center().x * k, -rb.position.y * k, -rb.get_center().z * k))
	bounds = AABB(Vector3.ZERO, rb.size)  # only its size is used below

	# Some models keep all four tyres (or rims) in one mesh: cut it into one piece per corner, so
	# each wheel can still turn and steer.
	var extra: Array = entry.get("wheel", [])
	for mi in meshes.duplicate():
		var xf0 := model.transform * _xf_in(mi, model)
		var bb0: AABB = xf0 * mi.get_aabb()
		if (bb0.size.x > 0.8 or bb0.size.z > 1.6) and bb0.end.y < 1.1 and bb0.size.y < 1.0 and _is_wheel_part(mi, extra):
			meshes.erase(mi)
			mi.visible = false
			for piece in _split_corners(mi, xf0):
				meshes.append(piece)
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
			if not named:
				var is_wheel := false
				var low := key.to_lower()
				for part in WHEEL_PARTS + extra:
					if low.contains(part) or low.begins_with(part.trim_prefix("_")):
						is_wheel = true
				all_wheel = all_wheel and is_wheel
		var xf := model.transform * _xf_in(mi, model)
		var bb: AABB = xf * mi.get_aabb()
		var c := bb.get_center()
		if not all_wheel:
			# Unnamed parts: a wheel is a round, narrow part low in a corner of the car.
			var round := absf(bb.size.y - bb.size.z) < 0.25 * bb.size.y
			if not (round and bb.size.y > 0.35 and bb.size.y < 1.3 and bb.size.x < 0.5):
				continue
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
	# A detailed model comes in hundreds of pieces (1,630 for the Porsche): each one is a separate
	# draw on the phone, twice with the comic outline. Weld them into one mesh per material for the
	# body and one per wheel; the look does not change. A model already in few pieces stays as it
	# is, so it keeps the lighter versions (LODs) the importer made for when it is far away.
	var surfaces := 0
	for mi in meshes:
		surfaces += mi.mesh.get_surface_count()
	if surfaces <= MERGE_MIN_SURFACES and not bake_mode:
		for mi in meshes:
			_apply_paint(mi, entry, paint_mat, tail)
		return _finish(root, entry, tail, bounds.size.y * k)
	var data := {"body": _merge_meshes(model, root), "wheels": {}, "height": bounds.size.y * k}
	for corner in corners:
		var pivot := root.get_node(corner) as Node3D
		data["wheels"][corner] = [pivot.position, _merge_meshes(pivot, pivot)]
	root.free()
	_merged[path] = data
	return _from_merged(data, entry, paint_mat, tail)


static func baked_path(id: String) -> String:
	return BAKED_DIR + id + ".res"


## Model node made from a merged detailed car: body mesh, wheel pivots, paint and tail materials.
static func _from_merged(data: Dictionary, entry: Dictionary, paint_mat: Material, tail: StandardMaterial3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Model"
	_add_merged(root, "Body", data["body"], entry, paint_mat, tail)
	for corner in data["wheels"]:
		var pivot := Node3D.new()
		pivot.name = corner
		pivot.position = data["wheels"][corner][0]
		root.add_child(pivot)
		_add_merged(pivot, "Wheel", data["wheels"][corner][1], entry, paint_mat, tail)
	return _finish(root, entry, tail, data["height"])


## Tail-light material and, for the police, the siren lights on the roof.
static func _finish(root: Node3D, entry: Dictionary, tail: StandardMaterial3D, bounds_y: float) -> Node3D:
	root.set_meta("tail_mat", tail)
	if entry["id"].contains("police"):
		var red := mat(Color(0.5, 0, 0), Color(1, 0.05, 0.05), 0.3)
		var blue := mat(Color(0, 0, 0.5), Color(0.1, 0.3, 1), 0.3)
		box(root, Vector3(0.5, 0.12, 0.3), Vector3(-0.3, bounds_y + 0.02, 0.0), red)
		box(root, Vector3(0.5, 0.12, 0.3), Vector3(0.3, bounds_y + 0.02, 0.0), blue)
		root.set_meta("siren_red", red)
		root.set_meta("siren_blue", blue)
	return root


static func _add_merged(parent: Node3D, node_name: String, meshes: Array[ArrayMesh], entry: Dictionary, paint_mat: Material, tail: StandardMaterial3D) -> void:
	for mesh in meshes:
		var mi := MeshInstance3D.new()
		mi.name = node_name
		mi.mesh = mesh
		parent.add_child(mi)
		_apply_paint(mi, entry, paint_mat, tail)


## Gives the catalog's paint and tail-light surfaces the materials car.gd drives.
static func _apply_paint(mi: MeshInstance3D, entry: Dictionary, paint_mat: Material, tail: StandardMaterial3D) -> void:
	for i in mi.mesh.get_surface_count():
		var src := mi.mesh.surface_get_material(i)
		var key: String = src.resource_name if src else ""
		if key != "" and key == entry.get("paint", "") and paint_mat:
			mi.set_surface_override_material(i, paint_mat)
		elif key != "" and key == entry.get("tail", ""):
			mi.set_surface_override_material(i, tail)


## The visible meshes under `node` welded into as few meshes as possible, in the space of `space`.
## Solid parts become one mesh with a surface per material and vertex format. See-through parts
## (glass) stay one mesh per original part: the phone sorts see-through things by object, and a
## single welded glass mesh would hide the seats behind the windows.
static func _merge_meshes(node: Node3D, space: Node3D) -> Array[ArrayMesh]:
	var tools := {}
	var order := []
	for n in node.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not mi.visible:
			continue
		var hidden := false
		var q: Node = mi
		while q and q != node:
			if q is Node3D and not (q as Node3D).visible:
				hidden = true
			q = q.get_parent()
		if hidden:
			continue
		var xf := _xf_in(mi, space)
		for si in mi.mesh.get_surface_count():
			if mi.mesh.surface_get_primitive_type(si) != Mesh.PRIMITIVE_TRIANGLES:
				continue
			var m: Material = mi.mesh.surface_get_material(si)
			if m and m.resource_name in _hide:
				continue
			var fmt: int = mi.mesh.surface_get_format(si) & (Mesh.ARRAY_FORMAT_NORMAL | Mesh.ARRAY_FORMAT_TANGENT | Mesh.ARRAY_FORMAT_COLOR | Mesh.ARRAY_FORMAT_TEX_UV | Mesh.ARRAY_FORMAT_TEX_UV2)
			var solid := m is BaseMaterial3D and (m as BaseMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_DISABLED
			var key := [m, fmt, 0 if solid else mi.get_instance_id()]
			if not tools.has(key):
				tools[key] = SurfaceTool.new()
				order.append(key)
			(tools[key] as SurfaceTool).append_from(mi.mesh, si, xf)
	var out: Array[ArrayMesh] = []
	var meshes := {}  # 0 for the solid mesh, else the id of the see-through part
	for key in order:
		if not meshes.has(key[2]):
			meshes[key[2]] = ArrayMesh.new()
			out.append(meshes[key[2]])
		var mesh: ArrayMesh = meshes[key[2]]
		(tools[key] as SurfaceTool).commit(mesh)
		if key[0] is Material:
			mesh.surface_set_material(mesh.get_surface_count() - 1, key[0])
	return out


## Some Sketchfab cars (rigged for opening doors) come as skinned meshes: in glTF their own node
## transform is ignored and, in the rest pose, the vertices are already in the space of the model
## root. Turn them into plain meshes placed there, so bounds and wheel pivots work as for the others.
static func _unskin(model: Node3D) -> void:
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.skin == null:
			continue
		mi.skin = null
		mi.skeleton = NodePath("")
		mi.transform = _xf_in(mi.get_parent() as Node3D, model).affine_inverse() if mi.get_parent() != model else Transform3D.IDENTITY


## True if every surface of the mesh is a tyre, rim or brake (by material name).
static func _is_wheel_part(mi: MeshInstance3D, extra: Array) -> bool:
	for i in mi.mesh.get_surface_count():
		var src := mi.mesh.surface_get_material(i)
		var low: String = src.resource_name.to_lower() if src else ""
		var hit := false
		for part in WHEEL_PARTS + extra:
			if low.contains(part) or low.begins_with(part.trim_prefix("_")):
				hit = true
		if not hit:
			return false
	return true


## Cuts a mesh holding the four wheels into four meshes, one per corner of the car (`xf` places
## it in the car's space, centred on the car). The pieces sit next to the original, which is hidden.
static func _split_corners(mi: MeshInstance3D, xf: Transform3D) -> Array[MeshInstance3D]:
	var meshes := [ArrayMesh.new(), ArrayMesh.new(), ArrayMesh.new(), ArrayMesh.new()]
	for si in mi.mesh.get_surface_count():
		if mi.mesh.surface_get_primitive_type(si) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arrays := mi.mesh.surface_get_arrays(si)
		for k in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3, Mesh.ARRAY_BONES, Mesh.ARRAY_WEIGHTS]:
			arrays[k] = null
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(verts.size()))
		var parts := [PackedInt32Array(), PackedInt32Array(), PackedInt32Array(), PackedInt32Array()]
		for t in range(0, idx.size() - 2, 3):
			var c := xf * ((verts[idx[t]] + verts[idx[t + 1]] + verts[idx[t + 2]]) / 3.0)
			var q := (0 if c.z < 0.0 else 2) + (0 if c.x < 0.0 else 1)
			parts[q].append_array([idx[t], idx[t + 1], idx[t + 2]])
		for q in 4:
			if parts[q].is_empty():
				continue
			var sub := subset_arrays(arrays, parts[q])
			meshes[q].add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, sub)
			meshes[q].surface_set_material(meshes[q].get_surface_count() - 1, mi.mesh.surface_get_material(si))
	var out: Array[MeshInstance3D] = []
	for q in 4:
		if meshes[q].get_surface_count() == 0:
			continue
		var piece := MeshInstance3D.new()
		piece.name = "%s_%d" % [mi.name, q]
		piece.mesh = meshes[q]
		piece.transform = mi.transform
		mi.get_parent().add_child(piece)
		out.append(piece)
	return out


## Surface arrays keeping only the triangles in `indices` and the vertices they use.
static func subset_arrays(src: Array, indices: PackedInt32Array) -> Array:
	var nverts := (src[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var remap := PackedInt32Array()
	remap.resize(nverts)
	remap.fill(-1)
	var keep := PackedInt32Array()
	var new_idx := PackedInt32Array()
	new_idx.resize(indices.size())
	for i in indices.size():
		var v := indices[i]
		if remap[v] < 0:
			remap[v] = keep.size()
			keep.append(v)
		new_idx[i] = remap[v]
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	for k in Mesh.ARRAY_MAX:
		var a = src[k]
		if a == null or k == Mesh.ARRAY_INDEX:
			continue
		var per: int = (a.size() / nverts) if nverts > 0 else 1
		var b = a.duplicate()
		b.resize(keep.size() * per)
		for j in keep.size():
			for c in per:
				b[j * per + c] = a[keep[j] * per + c]
		out[k] = b
	out[Mesh.ARRAY_INDEX] = new_idx
	return out


## True if every surface of the mesh uses a material the catalog hides.
static func _all_hidden(mi: MeshInstance3D) -> bool:
	if _hide.is_empty():
		return false
	for i in mi.mesh.get_surface_count():
		var m := mi.mesh.surface_get_material(i)
		if m == null or not (m.resource_name in _hide):
			return false
	return true


static func _material_names(mi: MeshInstance3D) -> String:
	var out := PackedStringArray()
	for i in mi.mesh.get_surface_count():
		var m := mi.mesh.surface_get_material(i)
		if m:
			out.append(m.resource_name)
	return " ".join(out)


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
