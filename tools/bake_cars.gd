extends SceneTree
## Prepares every car the game shows (garage, police, traffic) ahead of time and saves it to
## assets/cars_baked/<id>.res: turned, scaled, split into body and wheels, welded into few meshes
## and lightened to a triangle budget. The phone then only loads the result.
##
## Run after adding or changing a car:
##   godot --headless --path . --script tools/bake_cars.gd [-- id id ...]

const BUDGET_GARAGE := 90000
const BUDGET_POLICE := 50000
const BUDGET_TRAFFIC := 30000
## Surfaces with fewer triangles than this are left as they are.
const MIN_TRIS := 400


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var ids: Array = []
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		ids.append_array(CarCatalog.GARAGE)
		ids.append_array(["police_mondeo", "police_car"])
		ids.append_array(CarCatalog.TRAFFIC)
	else:
		ids.append_array(args)
	DirAccess.make_dir_recursive_absolute(CarModel.BAKED_DIR)
	CarModel.bake_mode = true
	for id in ids:
		var entry := CarCatalog.find(id)
		if entry.is_empty():
			push_error("unknown car " + id)
			continue
		var budget := BUDGET_TRAFFIC if id in CarCatalog.TRAFFIC else (BUDGET_POLICE if id.contains("police") else BUDGET_GARAGE)
		# A catalog "tris" overrides the budget (the jeep's tyres are part of its body).
		budget = entry.get("tris", budget)
		CarModel.build_generic(Color(0, 0, 0, 0), entry).free()
		var data: Dictionary = CarModel._merged[CarCatalog.model_path(entry)]
		var all: Array[ArrayMesh] = []
		all.append_array(data["body"])
		for corner in data["wheels"]:
			all.append_array(data["wheels"][corner][1])
		var before := 0
		for m in all:
			before += _tris(m)
		var ratio := minf(1.0, float(budget) / maxf(before, 1.0))
		var baked := BakedCar.new()
		baked.height = data["height"]
		var after := 0
		for m in data["body"]:
			var s := _lighten(m, ratio)
			after += _tris(s)
			baked.body.append(s)
		for corner in data["wheels"]:
			baked.wheel_pos[corner] = data["wheels"][corner][0]
			var list: Array[ArrayMesh] = []
			for m in data["wheels"][corner][1]:
				# Round tyres turn polygonal quickly: they are lightened at most by half.
				var s := _lighten(m, maxf(ratio, 0.5))
				after += _tris(s)
				list.append(s)
			baked.wheel_meshes[corner] = list
		var err := ResourceSaver.save(baked, CarModel.baked_path(id), ResourceSaver.FLAG_COMPRESS)
		print("%s: %d -> %d triangles (%s)" % [id, before, after, error_string(err)])
		CarModel.clear_cache()
	quit()


static func _tris(m: ArrayMesh) -> int:
	var n := 0
	for s in m.get_surface_count():
		var c := m.surface_get_array_index_len(s)
		n += (c if c > 0 else m.surface_get_array_len(s)) / 3
	return n


## The mesh with each big surface simplified to about `ratio` of its triangles.
static func _lighten(mesh: ArrayMesh, ratio: float) -> ArrayMesh:
	var out := ArrayMesh.new()
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		# Extra channels (glTF's third and fourth UV sets, skin weights) are not used by the game.
		for k in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3, Mesh.ARRAY_BONES, Mesh.ARRAY_WEIGHTS]:
			arrays[k] = null
		var mat := mesh.surface_get_material(s)
		var tris := _tris_of(arrays)
		if ratio < 0.95 and tris >= MIN_TRIS:
			# Each pass halves the triangles at most: repeat until near the target.
			var target := int(tris * ratio)
			for i in 4:
				arrays = _simplify(arrays, mat, target)
				var now := _tris_of(arrays)
				if now < target * 1.3 or now > tris * 0.9:
					break
				tris = now
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		out.surface_set_material(out.get_surface_count() - 1, mat)
	return out


static func _tris_of(arrays: Array) -> int:
	if arrays[Mesh.ARRAY_INDEX] != null:
		return (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	return (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3


## Simplifies one surface with the importer's LOD maker and keeps the level nearest to `target`
## triangles, with only the vertices that level still uses.
static func _simplify(arrays: Array, mat: Material, target: int) -> Array:
	if arrays[Mesh.ARRAY_INDEX] == null:
		var st := SurfaceTool.new()
		st.create_from_arrays(arrays)
		st.index()
		arrays = st.commit_to_arrays()
	var im := ImporterMesh.new()
	im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, mat)
	im.generate_lods(25.0, 60.0, [])
	var src := im.get_surface_arrays(0)
	var best: PackedInt32Array = src[Mesh.ARRAY_INDEX]
	for l in im.get_surface_lod_count(0):
		var idx := im.get_surface_lod_indices(0, l)
		if absi(idx.size() / 3 - target) < absi(best.size() / 3 - target):
			best = idx
	# Keep only the vertices the chosen level uses.
	return CarModel.subset_arrays(src, best)
