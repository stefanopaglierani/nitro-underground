extends SceneTree
## Prepares every car the game shows (garage, police, traffic) ahead of time and saves it to
## assets/cars_baked/<id>.res: turned, scaled, split into body and wheels, welded into few meshes
## and lightened to a triangle budget. The phone then only loads the result.
##
## Run after adding or changing a car:
##   godot --headless --path . --script tools/bake_cars.gd [-- id id ...]

const BUDGET_GARAGE := 45000
const BUDGET_POLICE := 30000
const BUDGET_TRAFFIC := 18000
## Triangles of the far version (whole car in one mesh), shown beyond CarModel.FAR_DISTANCE.
const BUDGET_FAR := 4000
## Surfaces with fewer triangles than this are left as they are.
const MIN_TRIS := 400
const MIN_TRIS_FAR := 60


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var ids: Array = []
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		ids.append_array(CarCatalog.GARAGE)
		ids.append_array(Car.POLICE_BODIES)
		ids.append_array(CarCatalog.TRAFFIC)
		ids.append_array(CarCatalog.NEW)  # needs the originals copied to assets/cars_new
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
				var s := _lighten(m, maxf(ratio, 0.3))
				after += _tris(s)
				list.append(s)
			baked.wheel_meshes[corner] = list
		# Far version: body and wheels welded by material, then lightened hard.
		var far := _weld(data)
		var far_before := _tris(far)
		var lean := _lighten(far, minf(1.0, float(BUDGET_FAR) / maxf(far_before, 1.0)), MIN_TRIS_FAR)
		baked.far.append(lean)
		if CarCatalog.model_path(entry).begins_with(NEW_DIR):
			_embed_textures(baked)
		var err := ResourceSaver.save(baked, CarModel.baked_path(id), ResourceSaver.FLAG_COMPRESS)
		print("%s: %d -> %d triangles, far %d, %d draws near / %d far (%s)" % [id, before, after, _tris(lean), _surfaces(baked), lean.get_surface_count(), error_string(err)])
		CarModel.clear_cache()
	quit()


## The originals of the v0.28 dealer cars stay out of the repository and of the build, and so do
## the pictures the importer takes out of them: their prepared version must carry its own.
const NEW_DIR := "res://assets/cars_new/"
## Side of the pictures kept inside those cars (pixels); only the colour and glow pictures are
## kept, the relief and shine pictures are left out (v0.31: these are trial versions, to choose from).
const NEW_TEX_SIZE := 512
const KEEP_TEX := ["albedo_texture", "emission_texture"]
const DROP_TEX := ["normal_texture", "orm_texture", "roughness_texture", "metallic_texture", "ao_texture",
	"heightmap_texture", "clearcoat_texture", "rim_texture", "anisotropy_flowmap", "subsurf_scatter_texture",
	"backlight_texture", "refraction_texture", "detail_albedo", "detail_normal", "detail_mask"]


## v0.31: the build had none of the pictures of the new cars, so their prepared file could not be
## read and the dealer closed the game. Now each picture is put inside the file, small and compressed.
func _embed_textures(baked: BakedCar) -> void:
	var meshes: Array[ArrayMesh] = []
	meshes.append_array(baked.body)
	meshes.append_array(baked.far)
	for corner in baked.wheel_meshes:
		for m in baked.wheel_meshes[corner]:
			meshes.append(m)
	var done := {}
	for m in meshes:
		for s in m.get_surface_count():
			var mat := m.surface_get_material(s)
			if not (mat is BaseMaterial3D):
				continue
			if not done.has(mat):
				var copy := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
				for prop in DROP_TEX:
					var t = copy.get(prop)
					if t is Texture2D and (t as Texture2D).resource_path.begins_with(NEW_DIR):
						copy.set(prop, null)
				copy.normal_enabled = copy.normal_texture != null
				for prop in KEEP_TEX:
					var t = copy.get(prop)
					if t is Texture2D and (t as Texture2D).resource_path.begins_with(NEW_DIR):
						copy.set(prop, _small_texture(t))
				done[mat] = copy
			m.surface_set_material(s, done[mat])


static func _small_texture(t: Texture2D) -> ImageTexture:
	var img := t.get_image()
	if img.is_compressed():
		img.decompress()
	var side := maxi(img.get_width(), img.get_height())
	if side > NEW_TEX_SIZE:
		var k := float(NEW_TEX_SIZE) / side
		img.resize(maxi(4, roundi(img.get_width() * k)), maxi(4, roundi(img.get_height() * k)), Image.INTERPOLATE_LANCZOS)
	img.generate_mipmaps()
	img.compress(Image.COMPRESS_S3TC)
	return ImageTexture.create_from_image(img)


static func _tris(m: ArrayMesh) -> int:
	var n := 0
	for s in m.get_surface_count():
		var c := m.surface_get_array_index_len(s)
		n += (c if c > 0 else m.surface_get_array_len(s)) / 3
	return n


static func _surfaces(b: BakedCar) -> int:
	var n := 0
	for m in b.body:
		n += m.get_surface_count()
	for c in b.wheel_meshes:
		for m in b.wheel_meshes[c]:
			n += (m as ArrayMesh).get_surface_count()
	return n


## Body and wheels (moved to their pivots) in one mesh, one surface per material and format.
static func _weld(data: Dictionary) -> ArrayMesh:
	var parts := []
	for m in data["body"]:
		parts.append([m, Transform3D()])
	for corner in data["wheels"]:
		for m in data["wheels"][corner][1]:
			parts.append([m, Transform3D(Basis(), data["wheels"][corner][0])])
	var tools := {}
	var order := []
	for e in parts:
		var m: ArrayMesh = e[0]
		for s in m.get_surface_count():
			var mat := m.surface_get_material(s)
			var key := "%d/%d" % [mat.get_instance_id() if mat else 0, m.surface_get_format(s) & Mesh.ARRAY_FORMAT_CUSTOM_BASE - 1]
			if not tools.has(key):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				st.set_material(mat)
				tools[key] = st
				order.append(key)
			(tools[key] as SurfaceTool).append_from(m, s, e[1])
	var out := ArrayMesh.new()
	for key in order:
		var st: SurfaceTool = tools[key]
		st.index()
		out = st.commit(out)
	return out


## The mesh with each big surface simplified to about `ratio` of its triangles.
static func _lighten(mesh: ArrayMesh, ratio: float, min_tris := MIN_TRIS) -> ArrayMesh:
	var out := ArrayMesh.new()
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		# Extra channels (glTF's third and fourth UV sets, skin weights) are not used by the game.
		for k in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3, Mesh.ARRAY_BONES, Mesh.ARRAY_WEIGHTS]:
			arrays[k] = null
		var mat := mesh.surface_get_material(s)
		var tris := _tris_of(arrays)
		if ratio < 0.95 and tris >= min_tris:
			# Each pass halves the triangles at most: repeat until near the target.
			var target := int(tris * ratio)
			for i in 6:
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
