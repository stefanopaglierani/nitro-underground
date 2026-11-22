extends SceneTree
## Turns the tropical island made in the Unreal period (Stefano's folder Isola-Tropicale, generated
## by our own IsolaGen: no third-party licence) into a tiled world for TropicalIsland, the same way
## as the Isola X5 (TiledWorld): assets/worlds/isola_tropicale/world.scn plus one tile_X_Y.scn per
## 512 m square with the ground (detailed and light), its collision, the pieces of road that fall
## in it (with their collision) and its trees, palms, pines, grass and rocks.
##
## Run after the island data changes (about a minute). NOT with --headless: without a renderer the
## plants' positions (MultiMesh) are not kept and every plant would be saved at the tile's corner.
##   godot --path . --windowed --resolution 320x200 --script tools/import_isola_tropicale.gd -- "<folder Isola-Tropicale/dati>"

const OUT := "res://assets/worlds/isola_tropicale/"
const DEFAULT_SRC := "C:/Progetti Software/NitroUnderground/Isola-Tropicale/dati"
const TILES := 16
const TILE := 512.0
const ORIGIN := -4096.0
## The race: a stretch of this road of the island, from its start.
const RACE_ROAD := "Strada_Costiera"
const RACE_LENGTH := 6500.0
const SAMPLE := 2.0
## Positions and normals stored in 16 bits: about half the size on disk and in video memory.
const COMPRESS := Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES
## Detailed ground up to this distance from the camera, the light one (every 4th point) beyond.
const NEAR_END := 760.0
## Plants and rocks come in squares of VEG_CHUNK metres (16 per tile), one MultiMesh per kind and
## square, drawn up to `end` metres; their mesh has lighter versions (LOD) that the engine picks by
## distance, square by square.
const VEG_CHUNK := 128.0
## Vegetation models (already in the repository: assets/scenery, see assets/LICENSES.md), the height
## they get, the triangle budget of their most detailed version and how far they are drawn.
const VEG := {
	"palma": {"model": "res://assets/scenery/coast_arabic_palm.glb", "height": 12.0, "tris": 3000, "end": 700.0, "shadow": true},
	"albero": {"model": "res://assets/scenery/env/oak.glb", "height": 9.0, "tris": 2500, "end": 700.0, "shadow": true},
	"pino": {"model": "res://assets/scenery/env/pine_tree.glb", "height": 13.0, "tris": 1500, "end": 700.0, "shadow": true},
	"erba": {"model": "res://assets/scenery/env/grass_patches.glb", "height": 0.7, "tris": 300, "end": 110.0, "shadow": false},
	"roccia": {"model": "res://assets/scenery/env/boulders.glb", "height": 1.6, "tris": 500, "end": 260.0, "shadow": false},
	# v0.32 (zone, boschi e radure): "node" prende un solo oggetto da un file che ne contiene diversi
	"cocco": {"model": "res://assets/scenery/coast_coconut_palm.glb", "height": 11.0, "tris": 2500, "end": 700.0, "shadow": true},
	"felce": {"model": "res://assets/scenery/env/vegetation_pack.glb", "node": "3_paporotnik", "height": 0.9, "tris": 120, "end": 120.0, "shadow": false},
	"cespuglio": {"model": "res://assets/scenery/env/bush.glb", "node": "Medium_bush_1", "height": 1.5, "tris": 100, "end": 260.0, "shadow": false},
	"roccia_muschio": {"model": "res://assets/scenery/env/rock_moss.glb", "node": "rock_moss_set_01_rock05", "height": 1.3, "tris": 600, "end": 260.0, "shadow": false},
}

var src := DEFAULT_SRC


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		src = args[0]
	DirAccess.make_dir_recursive_absolute(OUT)
	var t0 := Time.get_ticks_msec()
	var roads: Array = JSON.parse_string(FileAccess.get_file_as_string(src.path_join("strade.json")))
	var race := _race_road(roads)
	print("race road: %d samples, %.0f m" % [race.path.size(), (race.path.size() - 1) * SAMPLE])
	var road_tris := _road_triangles()
	print("roads cut into tiles (%d ms)" % (Time.get_ticks_msec() - t0))
	var veg_meshes := _veg_meshes()
	var veg := _veg_by_tile()
	print("vegetation sorted (%d ms)" % (Time.get_ticks_msec() - t0))
	var list: Array[Vector2i] = []
	var total := 0
	for j in TILES:
		for i in TILES:
			var at := Vector2i(i, j)
			var tile := _tile(at, road_tris.get(at, {}), veg.get(at, {}), veg_meshes)
			if tile == null:
				continue
			var packed := PackedScene.new()
			packed.pack(tile)
			var path := OUT + "tile_%d_%d.scn" % [i, j]
			var err := ResourceSaver.save(packed, path, ResourceSaver.FLAG_COMPRESS)
			if err != OK:
				push_error("%s: %s" % [path, error_string(err)])
			total += FileAccess.get_file_as_bytes(path).size()
			tile.free()
			list.append(at)
	var world := Node3D.new()
	world.name = "World"
	world.set_meta("terrain_data", {
		"sea_level": 0.0,
		"roads": [race],
		"tiles": {"size": TILE, "origin": Vector2(ORIGIN, ORIGIN), "list": list},
	})
	var packed := PackedScene.new()
	packed.pack(world)
	ResourceSaver.save(packed, OUT + "world.scn", ResourceSaver.FLAG_COMPRESS)
	world.free()
	print("%d tiles, %.1f MB, %d ms" % [list.size(), total / 1048576.0, Time.get_ticks_msec() - t0])
	quit()


## The race road resampled every SAMPLE metres. The json has [x, south, height]: in Godot x, z, y.
func _race_road(roads: Array) -> Dictionary:
	var road: Dictionary = {}
	for r in roads:
		if r.name == RACE_ROAD:
			road = r
	var pts: Array = road.points
	var path := PackedVector2Array()
	var heights := PackedFloat32Array()
	var along := 0.0
	var next := 0.0
	for k in range(1, pts.size()):
		var a := Vector3(pts[k - 1][0], pts[k - 1][2], pts[k - 1][1])
		var b := Vector3(pts[k][0], pts[k][2], pts[k][1])
		var seg := Vector2(b.x - a.x, b.z - a.z).length()
		while next <= along + seg and next <= RACE_LENGTH:
			var p := a.lerp(b, (next - along) / maxf(seg, 0.001))
			path.append(Vector2(p.x, p.z))
			heights.append(p.y)
			next += SAMPLE
		along += seg
		if next > RACE_LENGTH:
			break
	return {"path": path, "heights": heights, "width": float(road.width), "sample_spacing": SAMPLE, "closed": false, "street": false, "name": road.name}


func _tile_of(x: float, z: float) -> Vector2i:
	return Vector2i(clampi(floori((x - ORIGIN) / TILE), 0, TILES - 1), clampi(floori((z - ORIGIN) / TILE), 0, TILES - 1))


## Every road triangle, by tile (where its middle falls) and by material: {tile: {material: [pos, normal, uv]}}.
func _road_triangles() -> Dictionary:
	var out := {}
	for f in DirAccess.get_files_at(src.path_join("strade")):
		if not f.ends_with(".glb"):
			continue
		var scene := _read_glb(src.path_join("strade").path_join(f))
		for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
			var xf := _global_xf(mi)
			for s in mi.mesh.get_surface_count():
				var mat := mi.mesh.surface_get_material(s)
				var kind: String = mat.resource_name if mat else "Asfalto"
				var a := mi.mesh.surface_get_arrays(s)
				var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
				var nrm: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
				var uv: PackedVector2Array = a[Mesh.ARRAY_TEX_UV] if a[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
				var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
				for t in range(0, idx.size(), 3):
					var p0 := xf * v[idx[t]]
					var p1 := xf * v[idx[t + 1]]
					var p2 := xf * v[idx[t + 2]]
					var c := (p0 + p1 + p2) / 3.0
					var at := _tile_of(c.x, c.z)
					if not out.has(at):
						out[at] = {}
					if not out[at].has(kind):
						out[at][kind] = [[], [], []]  # plain arrays: packed ones would be copied
					var bucket: Array = out[at][kind]
					for k in [t, t + 1, t + 2]:
						(bucket[0] as Array).append(xf * v[idx[k]])
						(bucket[1] as Array).append((xf.basis * nrm[idx[k]]).normalized())
						(bucket[2] as Array).append(uv[idx[k]] if not uv.is_empty() else Vector2.ZERO)
		scene.free()
	return out


func _global_xf(n: Node3D) -> Transform3D:
	var xf := n.transform
	var p := n.get_parent()
	while p is Node3D:
		xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf


func _read_glb(path: String) -> Node3D:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	doc.append_from_file(path, state)
	return doc.generate_scene(state) as Node3D


## Vegetation by tile and kind, in a shuffled order so the game can show any share of it by drawing
## only the first instances: {tile: {kind: [Transform3D]}}.
func _veg_by_tile() -> Dictionary:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(src.path_join("vegetazione.json")))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1977
	var out := {}
	for kind: String in VEG:
		if not data.has(kind):
			push_error("no " + kind + " in vegetazione.json")
			continue
		for p: Array in data[kind]:
			var at := _tile_of(p[0], p[1])
			if not out.has(at):
				out[at] = {}
			if not out[at].has(kind):
				out[at][kind] = []
			var b := Basis(Vector3.UP, deg_to_rad(p[3])).scaled(Vector3.ONE * float(p[4]))
			out[at][kind].append(Transform3D(b, Vector3(p[0], p[2], p[1])))
	for at in out:
		for kind in out[at]:
			var list: Array = out[at][kind]
			for k in range(list.size() - 1, 0, -1):
				var r := rng.randi_range(0, k)
				var tmp = list[k]
				list[k] = list[r]
				list[r] = tmp
	return out


## The mesh of every kind of plant or rock: welded, standing on y = 0, scaled to its height,
## lightened to its budget, with lighter versions (LOD) for the distance. Saved once and shared by
## every tile.
func _veg_meshes() -> Dictionary:
	var out := {}
	for kind: String in VEG:
		var spec: Dictionary = VEG[kind]
		var model := (load(spec.model) as PackedScene).instantiate() as Node3D
		var welded := _weld(model, spec.get("node", ""))
		model.free()
		var aabb := welded.get_aabb()
		var k: float = spec.height / maxf(aabb.size.y, 0.001)
		var center := aabb.get_center()
		var xf := Transform3D(Basis().scaled(Vector3.ONE * k), Vector3(-center.x * k, -aabb.position.y * k, -center.z * k))
		var placed := _transformed(welded, xf)
		var light := _lighten(placed, spec.tris)
		var im := ImporterMesh.new()
		for s in light.get_surface_count():
			im.add_surface(Mesh.PRIMITIVE_TRIANGLES, light.surface_get_arrays(s), [], {}, light.surface_get_material(s))
		im.generate_lods(25.0, 60.0, [])
		var with_lods := im.get_mesh()
		var path := OUT + "veg_%s.res" % kind
		ResourceSaver.save(with_lods, path, ResourceSaver.FLAG_COMPRESS)
		out[kind] = load(path)
		print("%s: %d triangles -> %d, %d lighter versions" % [kind, _tris(placed), _tris(light), im.get_surface_lod_count(0)])
	return out


func _weld(root: Node3D, only := "") -> ArrayMesh:
	var tools := {}
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if not mi.visible or mi.mesh == null:
			continue
		if only != "" and not String(mi.name).begins_with(only.validate_node_name()) and not String(mi.get_parent().name).begins_with(only.validate_node_name()):
			continue
		var xf := _global_xf(mi)
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(s)
			if mat == null:
				mat = mi.mesh.surface_get_material(s)
			var key := mat.get_instance_id() if mat else 0
			if not tools.has(key):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				st.set_material(mat)
				tools[key] = st
			(tools[key] as SurfaceTool).append_from(mi.mesh, s, xf)
	var out := ArrayMesh.new()
	for key in tools:
		var st: SurfaceTool = tools[key]
		st.index()
		out = st.commit(out)
	return out


func _transformed(mesh: ArrayMesh, xf: Transform3D) -> ArrayMesh:
	var out := ArrayMesh.new()
	for s in mesh.get_surface_count():
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_material(mesh.surface_get_material(s))
		st.append_from(mesh, s, xf)
		st.index()
		out = st.commit(out)
	return out


func _tris(m: Mesh) -> int:
	var n := 0
	for s in m.get_surface_count():
		var c := (m as ArrayMesh).surface_get_array_index_len(s)
		n += (c if c > 0 else (m as ArrayMesh).surface_get_array_len(s)) / 3
	return n


## The mesh lightened to about `budget` triangles (each surface by the same share).
func _lighten(mesh: ArrayMesh, budget: int) -> ArrayMesh:
	var ratio := minf(1.0, float(budget) / maxf(_tris(mesh), 1.0))
	var out := ArrayMesh.new()
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		for k in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3, Mesh.ARRAY_BONES, Mesh.ARRAY_WEIGHTS]:
			arrays[k] = null
		var mat := mesh.surface_get_material(s)
		if ratio < 0.95:
			var im := ImporterMesh.new()
			im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, mat)
			im.generate_lods(25.0, 60.0, [])
			var target := int((arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 * ratio)
			var best: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for l in im.get_surface_lod_count(0):
				var lod := im.get_surface_lod_indices(0, l)
				if absi(lod.size() / 3 - target) < absi(best.size() / 3 - target):
					best = lod
			arrays = CarModel.subset_arrays(im.get_surface_arrays(0), best)
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		out.surface_set_material(out.get_surface_count() - 1, mat)
	return out


## One tile: ground (Near, Far), its collision (Body), the road pieces in it (Roads, with their
## collision) and the plants (one MultiMesh per kind and distance).
func _tile(at: Vector2i, roads: Dictionary, veg: Dictionary, veg_meshes: Dictionary) -> Node3D:
	var path := src.path_join("terreno").path_join("terreno_%d_%d.glb" % [at.x, at.y])
	if not FileAccess.file_exists(path):
		return null
	var scene := _read_glb(path)
	var src_mi := scene.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var a := src_mi.mesh.surface_get_arrays(0)
	scene.free()
	var origin := Vector3(ORIGIN + at.x * TILE, 0, ORIGIN + at.y * TILE)
	var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var side := roundi(sqrt(verts.size()))  # 129 on land (4 m), 17 on the open sea (32 m)
	var local := PackedVector3Array()
	local.resize(verts.size())
	for k in verts.size():
		local[k] = verts[k] - origin
	a[Mesh.ARRAY_VERTEX] = local
	var root := Node3D.new()
	root.name = "Tile_%d_%d" % [at.x, at.y]
	root.position = origin
	var near := MeshInstance3D.new()
	near.name = "Near"
	a[Mesh.ARRAY_TEX_UV] = null  # the ground shader works in world space
	var near_mesh := ArrayMesh.new()
	near_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a, [], {}, COMPRESS)
	near.mesh = near_mesh
	root.add_child(near)
	var far := MeshInstance3D.new()
	far.name = "Far"
	far.mesh = _grid_mesh(a, side, 4 if side > 64 else 1)
	far.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(far)
	if side > 64:
		near.visibility_range_end = NEAR_END
		far.visibility_range_begin = NEAR_END
	else:
		near.visible = false  # open sea: one light mesh is enough
	# Ground collision: a height map with the tile's own points (uniform scale, like Isola X5).
	var cell := TILE / float(side - 1)
	var heights := PackedFloat32Array()
	heights.resize(side * side)
	for k in side * side:
		heights[k] = local[k].y / cell
	var hm := HeightMapShape3D.new()
	hm.map_width = side
	hm.map_depth = side
	hm.map_data = heights
	var body := StaticBody3D.new()
	body.name = "Body"
	var shape := CollisionShape3D.new()
	shape.name = "Shape"
	shape.shape = hm
	shape.transform = Transform3D(Basis().scaled(Vector3.ONE * cell), Vector3(TILE * 0.5, 0, TILE * 0.5))
	body.add_child(shape)
	root.add_child(body)
	if not roads.is_empty():
		_add_roads(root, roads, origin)
	for kind: String in veg:
		_add_veg(root, kind, veg[kind], veg_meshes[kind], origin)
	for n in root.find_children("*", "", true, false):
		n.owner = root
	return root


## Light ground: every `step`-th point of the grid.
func _grid_mesh(a: Array, side: int, step: int) -> ArrayMesh:
	var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var nrm: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var col: PackedColorArray = a[Mesh.ARRAY_COLOR]
	var n := (side - 1) / step + 1
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var pv := PackedVector3Array()
	var pn := PackedVector3Array()
	var pc := PackedColorArray()
	for z in n:
		for x in n:
			var k := z * step * side + x * step
			pv.append(v[k])
			pn.append(nrm[k])
			pc.append(col[k])
	var idx := PackedInt32Array()
	for z in n - 1:
		for x in n - 1:
			var i0 := z * n + x
			idx.append_array([i0, i0 + 1, i0 + n, i0 + 1, i0 + n + 1, i0 + n])
	arrays[Mesh.ARRAY_VERTEX] = pv
	arrays[Mesh.ARRAY_NORMAL] = pn
	arrays[Mesh.ARRAY_COLOR] = pc
	arrays[Mesh.ARRAY_INDEX] = idx
	# The winding must match the detailed ground: flip if the first triangle faces down.
	var f := (pv[idx[1]] - pv[idx[0]]).cross(pv[idx[2]] - pv[idx[0]])
	if f.y < 0.0:
		for t in range(0, idx.size(), 3):
			var tmp := idx[t + 1]
			idx[t + 1] = idx[t + 2]
			idx[t + 2] = tmp
		arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, COMPRESS)
	return mesh


## The road pieces of the tile: one surface per road material (named after it, the game gives
## them their look), and a collision for the drivable ones (not the painted lines on top).
func _add_roads(root: Node3D, roads: Dictionary, origin: Vector3) -> void:
	var mesh := ArrayMesh.new()
	var faces := PackedVector3Array()
	for kind: String in roads:
		var b: Array = roads[kind]
		var pv := PackedVector3Array()
		for p: Vector3 in b[0]:
			pv.append(p - origin)
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = pv
		arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(b[1])
		arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(b[2])
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, COMPRESS)
		mesh.surface_set_name(mesh.get_surface_count() - 1, kind)
		if kind != "Segnaletica":
			faces.append_array(pv)
	var mi := MeshInstance3D.new()
	mi.name = "Roads"
	mi.mesh = mesh
	root.add_child(mi)
	if faces.is_empty():
		return
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var body := StaticBody3D.new()
	body.name = "RoadBody"
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	root.add_child(body)


## The plants of one kind in the tile, square by square (still in shuffled order, so the game can
## draw any share of them with visible_instance_count).
func _add_veg(root: Node3D, kind: String, list: Array, mesh: Mesh, origin: Vector3) -> void:
	var spec: Dictionary = VEG[kind]
	var squares := {}
	for xf: Transform3D in list:
		var p := xf.origin - origin
		var sq := Vector2i(clampi(floori(p.x / VEG_CHUNK), 0, 3), clampi(floori(p.z / VEG_CHUNK), 0, 3))
		if not squares.has(sq):
			squares[sq] = []
		squares[sq].append(Transform3D(xf.basis, p))
	for sq: Vector2i in squares:
		var items: Array = squares[sq]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = items.size()
		var box := AABB()
		for k in items.size():
			mm.set_instance_transform(k, items[k])
			var b: AABB = (items[k] as Transform3D) * mesh.get_aabb()
			box = b if k == 0 else box.merge(b)
		# Stored with the square: a MultiMesh read back from the tile file had an empty box, and
		# the engine then never drew it.
		mm.custom_aabb = box
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Veg_%s_%d_%d" % [kind, sq.x, sq.y]
		mmi.multimesh = mm
		mmi.visibility_range_end = spec.end
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if spec.shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.set_meta("veg", kind)
		root.add_child(mmi)
