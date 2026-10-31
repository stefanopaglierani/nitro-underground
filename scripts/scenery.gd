class_name Scenery
## Realistic roadside models (trees, houses, signs, cones, barriers) from assets/scenery, made
## ready for the tracks: each model's meshes come back with their transforms baked in, scaled to
## a real-world height, standing on y = 0 and centred. Licences: assets/LICENSES.md.

const DIR := "res://assets/scenery/%s/scene.gltf"
## Colour multiplied into the leaves of some trees, whose textures are greyish.
const LEAF_TINT := {"spruce": Color(0.7, 1.0, 0.55), "pine": Color(0.85, 1.0, 0.75), "scots_pine": Color(0.7, 0.95, 0.55)}

## name -> [[mesh, transform], ...] in the model's own space, before scaling.
static var _parts := {}
## name -> AABB of all its parts.
static var _bounds := {}


static func exists(name: String) -> bool:
	return ResourceLoader.exists(_path(name))


## assets/scenery/<name>/scene.gltf (older models) or assets/scenery/<name>.glb.
static func _path(name: String) -> String:
	var glb := "res://assets/scenery/%s.glb" % name
	return glb if ResourceLoader.exists(glb) else DIR % name


## The meshes of a model and their transforms, scaled so the whole model is `height` metres tall,
## standing on y = 0 and centred on x and z. `only` keeps just those parts (index in the file),
## useful for packs such as the street signs.
static func parts(name: String, height: float, only: Array = []) -> Array:
	_load(name)
	var list: Array = _parts[name]
	var box: AABB = _bounds[name]
	if not only.is_empty():
		box = AABB()
		var first := true
		for i in only:
			var b: AABB = (list[i][1] as Transform3D) * (list[i][0] as Mesh).get_aabb()
			box = b if first else box.merge(b)
			first = false
		var picked := []
		for i in only:
			picked.append(list[i])
		list = picked
	var s := height / maxf(box.size.y, 0.001)
	var fix := Transform3D(Basis.from_scale(Vector3(s, s, s)), Vector3.ZERO) * Transform3D(Basis.IDENTITY, -Vector3(box.get_center().x, box.position.y, box.get_center().z))
	var out := []
	for p in list:
		out.append([p[0], fix * (p[1] as Transform3D)])
	return out


static func part_count(name: String) -> int:
	_load(name)
	return (_parts[name] as Array).size()


## One copy of a model as a node. Its parts are merged into a single mesh with one surface per
## material, so a model made of a hundred little pieces costs a handful of draw calls on the phone.
static func instance(name: String, height: float, only: Array = []) -> Node3D:
	var root := Node3D.new()
	root.name = name
	var mi := MeshInstance3D.new()
	mi.mesh = merged(name, height, only)
	root.add_child(mi)
	return root


## name|height|only -> merged ArrayMesh.
static var _merged := {}


static func merged(name: String, height: float, only: Array = []) -> ArrayMesh:
	var key := "%s|%.3f|%s" % [name, height, only]
	if _merged.has(key):
		return _merged[key]
	var tools := {}  # material -> SurfaceTool
	var order := []
	for p in parts(name, height, only):
		var mesh: Mesh = p[0]
		for si in mesh.get_surface_count():
			var mat: Material = mesh.surface_get_material(si)
			var k: Variant = mat if mat != null else "none"
			if not tools.has(k):
				var st := SurfaceTool.new()
				tools[k] = st
				order.append(k)
			(tools[k] as SurfaceTool).append_from(mesh, si, p[1])
	var out := ArrayMesh.new()
	for k in order:
		var st: SurfaceTool = tools[k]
		st.commit(out)
		if k is Material:
			out.surface_set_material(out.get_surface_count() - 1, k)
	_merged[key] = out
	return out


## Many copies of a model, one MultiMesh per part. Returns the new nodes (already added).
static func scatter(parent: Node, name: String, height: float, transforms: Array, visibility_end := 0.0, only: Array = []) -> Array:
	var nodes := []
	if transforms.is_empty():
		return nodes
	for p in parts(name, height, only):
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = p[0]
		mm.instance_count = transforms.size()
		for i in transforms.size():
			mm.set_instance_transform(i, (transforms[i] as Transform3D) * (p[1] as Transform3D))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.visibility_range_end = visibility_end
		parent.add_child(mmi)
		nodes.append(mmi)
	return nodes


## Foliage drawn with alpha blending is sorted badly, leaves a pale fringe and costs more on
## phones: cut it out with alpha scissor instead. `tint` livens up greyish needles.
static func _opaque_leaves(mesh: Mesh, tint: Color) -> Mesh:
	var copy: Mesh = null
	for i in mesh.get_surface_count():
		var m := mesh.surface_get_material(i) as BaseMaterial3D
		if m and m.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			if copy == null:
				copy = mesh.duplicate()
			var cut := m.duplicate() as BaseMaterial3D
			cut.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			cut.alpha_scissor_threshold = 0.4
			cut.albedo_color = cut.albedo_color * tint
			copy.surface_set_material(i, cut)
	return copy if copy else mesh


static func _load(name: String) -> void:
	if _parts.has(name):
		return
	var list := []
	var box := AABB()
	if exists(name):
		var scene := (load(_path(name)) as PackedScene).instantiate() as Node3D
		var first := true
		for mi in scene.find_children("*", "MeshInstance3D", true, false):
			var xf := (mi as Node3D).transform
			var n := mi.get_parent() as Node3D
			while n != scene:
				xf = n.transform * xf
				n = n.get_parent() as Node3D
			var mesh := _opaque_leaves((mi as MeshInstance3D).mesh, LEAF_TINT.get(name, Color.WHITE))
			list.append([mesh, xf])
			var b := xf * mesh.get_aabb()
			box = b if first else box.merge(b)
			first = false
		scene.free()
	_parts[name] = list
	_bounds[name] = box


# ---------- Packs: one file holding many separate models ----------

## name -> pieces (see pieces_of).
static var _pieces := {}


## The separate models of a pack (buildings of a city set, rocks of a rock pack...): meshes whose
## footprints overlap belong to the same piece. Each piece: {"parts": [[mesh, transform]...],
## "box": AABB} standing on y = 0, centred on x and z, in metres as in the file. Sorted left to
## right as laid out in the file.
static func pieces(name: String) -> Array:
	if not _pieces.has(name):
		_pieces[name] = pieces_of((load(_path(name)) as PackedScene).instantiate()) if exists(name) else []
	return _pieces[name]


static func pieces_of(scene: Node3D) -> Array:
	var items := []  # [mesh, transform, aabb]
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		var xf := (mi as Node3D).transform
		var n := mi.get_parent() as Node3D
		while n != scene and n != null:
			xf = n.transform * xf
			n = n.get_parent() as Node3D
		var mesh := _opaque_leaves((mi as MeshInstance3D).mesh, Color.WHITE)
		items.append([mesh, xf, xf * mesh.get_aabb()])
	scene.free()
	# Union-find on overlapping footprints.
	var parent := range(items.size())
	var find := func(i: int) -> int:
		while parent[i] != i:
			i = parent[i]
		return i
	for i in items.size():
		for j in range(i + 1, items.size()):
			var a: AABB = items[i][2]
			var b: AABB = items[j][2]
			if a.position.x < b.end.x + 0.05 and b.position.x < a.end.x + 0.05 and a.position.z < b.end.z + 0.05 and b.position.z < a.end.z + 0.05:
				var ri: int = find.call(i)
				var rj: int = find.call(j)
				if ri != rj:
					parent[rj] = ri
	var groups := {}
	for i in items.size():
		var r: int = find.call(i)
		if not groups.has(r):
			groups[r] = []
		groups[r].append(items[i])
	var out := []
	for r in groups:
		var list: Array = groups[r]
		var box: AABB = list[0][2]
		for it in list:
			box = box.merge(it[2])
		var fix := Transform3D(Basis.IDENTITY, -Vector3(box.get_center().x, box.position.y, box.get_center().z))
		var parts := []
		for it in list:
			parts.append([it[0], fix * (it[1] as Transform3D)])
		out.append({"parts": parts, "box": AABB(Vector3(-box.size.x / 2.0, 0, -box.size.z / 2.0), box.size), "x": box.get_center().x + box.get_center().z * 0.001})
	out.sort_custom(func(p, q): return p["x"] < q["x"])
	return out


## One piece of a pack as a node, scaled by `s`.
static func piece_instance(name: String, index: int, s := 1.0) -> Node3D:
	var root := Node3D.new()
	var p: Dictionary = pieces(name)[index]
	for part in p["parts"]:
		var mi := MeshInstance3D.new()
		mi.mesh = part[0]
		mi.transform = Transform3D(Basis.from_scale(Vector3.ONE * s), Vector3.ZERO) * (part[1] as Transform3D)
		root.add_child(mi)
	return root


## Many copies of one piece, one MultiMesh per mesh. Transforms include any scaling.
static func scatter_piece(parent: Node, name: String, index: int, transforms: Array, visibility_end := 0.0) -> Array:
	var nodes := []
	if transforms.is_empty():
		return nodes
	var p: Dictionary = pieces(name)[index]
	for part in p["parts"]:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = part[0]
		mm.instance_count = transforms.size()
		for i in transforms.size():
			mm.set_instance_transform(i, (transforms[i] as Transform3D) * (part[1] as Transform3D))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.visibility_range_end = visibility_end
		parent.add_child(mmi)
		nodes.append(mmi)
	return nodes


# ---------- Dressing a road (Mountain and the tracks built on it) ----------

## Street sign pack parts (assets/scenery/street_signs): plates and the plain pole.
const SIGN_PLATES := [9, 1, 5]  # no overtaking, no lorries, no bicycles
const SIGN_POLE := 12
## Barrier pack parts (assets/scenery/barriers).
const CONE := 0
const BARRELS := [10, 11]
const JERSEY := [13, 14]
const SAWHORSE := 15


## Alpine chalets beside the road (`houses`), road signs on the straights, cones along the
## start straight and a road-works spot on the verge. Cones, signs and barrels can be knocked
## over; houses are solid.
static func dress_road(t: Mountain, houses: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = t.rng_seed + 77
	var n := t.pts.size()
	if houses and exists("alpine_chalet"):
		_houses(t, rng)
	if exists("street_signs"):
		var k := (t.start_i + 60) % n
		var placed := 0
		while placed < n:
			# Only on straights: the bends already have their chevrons.
			if t.limits[k] > 26.0:
				var side := 1.0 if rng.randf() < 0.7 else -1.0
				var base := t.pts[k] + t._right(k) * side * (Mountain.ROAD_HALF + 1.6)
				var face := -t.tangents[k] * side  # towards the oncoming traffic on that side
				_sign(t, base, face, SIGN_PLATES[rng.randi() % SIGN_PLATES.size()])
				placed += 170
				k = (k + 170) % n
			else:
				placed += 10
				k = (k + 10) % n
	if exists("barriers"):
		# Cones on both verges of the start straight, past the grid.
		for i in range(14, 60, 4):
			var k := (t.start_i + i + n) % n
			for side: float in [-1.0, 1.0]:
				var p := t.pts[k] + t._right(k) * side * (Mountain.ROAD_HALF + 0.8)
				_loose(t, [CONE], 0.75, p, t.tangents[k], 4.0, Vector3(0.45, 0.75, 0.45))
		# Road works on the right verge halfway round, with cones closing the edge of the lane.
		var w := (t.start_i + n / 2) % n
		for j in 5:
			var k := (w + j * 2) % n
			var p := t.pts[k] + t._right(k) * (Mountain.ROAD_HALF + 1.3)
			if j == 0 or j == 4:
				_loose(t, [SAWHORSE], 1.0, p, t._right(k), 12.0, Vector3(1.2, 1.0, 0.4))
			elif j == 2:
				_loose(t, [JERSEY[rng.randi() % 2]], 0.85, p, t.tangents[k], 400.0, Vector3(0.6, 0.85, 2.0))
			else:
				_loose(t, [BARRELS[rng.randi() % 2]], 1.05, p, t.tangents[k], 15.0, Vector3(0.6, 1.05, 0.6))
		for j in range(-6, 12, 2):
			var k := (w + j + n) % n
			var p := t.pts[k] + t._right(k) * (Mountain.ROAD_HALF - 0.4)
			_loose(t, [CONE], 0.75, p, t.tangents[k], 4.0, Vector3(0.45, 0.75, 0.45))


## A model as a rigid body that can be knocked over, standing at `pos` (on the ground) and facing
## along `fwd`. `box` is the collision size; the body sleeps until hit.
static func _loose(t: Node3D, only: Array, height: float, pos: Vector3, fwd: Vector3, mass: float, box: Vector3, name := "barriers") -> RigidBody3D:
	var body := RigidBody3D.new()
	body.mass = mass
	body.can_sleep = true
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box
	col.shape = shape
	col.position.y = box.y / 2.0
	body.add_child(col)
	var model := instance(name, height, only)
	body.add_child(model)
	t.add_child(body)
	var f := Vector3(fwd.x, 0, fwd.z).normalized()
	body.global_transform = Transform3D(Basis.looking_at(f, Vector3.UP), pos + Vector3(0, 0.03, 0))
	body.sleeping = true
	return body


static func _sign(t: Node3D, base: Vector3, face: Vector3, plate: int) -> void:
	var body := _loose(t, [SIGN_POLE], 2.6, base, face, 25.0, Vector3(0.7, 2.6, 0.15), "street_signs")
	var p := instance("street_signs", 0.7, [plate])
	p.position.y = 2.15
	body.add_child(p)


## A few chalets 22-34 m from the road, on fairly flat ground clear of the other road parts,
## facing the road.
static func _houses(t: Mountain, rng: RandomNumberGenerator) -> void:
	var n := t.pts.size()
	var want := 7
	var tries := 0
	var placed: Array[Vector3] = []
	while placed.size() < want and tries < 400:
		tries += 1
		var k := rng.randi() % n
		var side := 1.0 if rng.randf() < 0.5 else -1.0
		var dist := rng.randf_range(22.0, 34.0)
		var p := t.pts[k] + t._right(k) * side * dist
		if absf(t._road_dist_at(p.x, p.z) - dist) > 3.0:
			continue  # another stretch of road is closer
		var h := t.ground_height(p.x, p.z)
		var lo := h
		var hi := h
		for o in [Vector3(5, 0, 0), Vector3(-5, 0, 0), Vector3(0, 0, 5), Vector3(0, 0, -5)]:
			var g := t.ground_height(p.x + o.x, p.z + o.z)
			lo = minf(lo, g)
			hi = maxf(hi, g)
		if hi - lo > 2.5:
			continue
		var far := true
		for q in placed:
			if q.distance_to(p) < 120.0:
				far = false
		if not far:
			continue
		placed.append(p)
		var house := instance("alpine_chalet", rng.randf_range(8.0, 9.5))
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(9.0, 8.0, 5.5)
		col.shape = shape
		col.position.y = 4.0
		body.add_child(col)
		body.add_child(house)
		t.add_child(body)
		var to_road := t.pts[k] - p
		# Sink the base into the slope so no corner floats.
		body.global_transform = Transform3D(Basis.looking_at(Vector3(to_road.x, 0, to_road.z).normalized(), Vector3.UP), Vector3(p.x, lo - 0.3, p.z))
