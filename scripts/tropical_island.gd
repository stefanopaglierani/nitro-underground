class_name TropicalIsland
extends TiledWorld
## The tropical island of the Unreal period (v0.30, Stefano 22/11/2026: the first race of the
## campaign). 8 x 8 km, a volcano of about 600 m, 79 roads; made by our own generator (Isola-Tropicale
## folder) and turned into tiles by tools/import_isola_tropicale.gd. It works like the Isola X5
## (TiledWorld): tiles of 512 m read in the background around the camera, each with its ground,
## collision, pieces of road and plants. The race is the first 6.5 km of the coast road.

const ISLAND_FOLDER := "res://assets/worlds/isola_tropicale/"
## Tiles of 512 m: 5 x 5 around the camera (2.5 km), 3 x 3 with the light profile.
const ISLAND_RINGS_PC := 2
const ISLAND_RINGS_LIGHT := 1
## Share of each kind of plant drawn (the tiles hold all 250,000, in shuffled order; measured on
## Stefano's PC: all of them ran at 14 FPS, none at 27, these at 21.6 like the Isola X5; see
## docs/TECNICO.md). The light profile (--mobile) halves them again.
const VEG_SHARE := {"palma": 0.35, "albero": 0.2, "pino": 0.35, "erba": 0.25, "roccia": 0.35}
const DIRT := "res://assets/materials/rocky_terrain_02/rocky_terrain_02_diff_1k.jpg"

var _road_mats := {}
## Test aid --vegshare: the same share for every kind of plant.
var _share_override := {}
## Plants cast no shadow: measured on Stefano's PC (1920x1080) the same share of plants runs at
## 21.6 FPS without and 20.3 with, and 21.6 is what the Isola X5 does. --vegshadow=1 turns them on.
var _veg_shadows := false


func _init(road_index := 0) -> void:
	super(road_index)
	folder = ISLAND_FOLDER
	world_path = folder + "world.scn"
	extent = 4096.0
	view_distance = 1600.0
	sea_size = 24000.0
	rings = ISLAND_RINGS_LIGHT if Perf.mobile else ISLAND_RINGS_PC
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--vegshare="):
			# Test aid: one share for every kind of plant (0 = none, 1 = all), to measure their cost.
			var share := float(a.substr(11))
			for k in VEG_SHARE:
				_share_override[k] = share
		if a == "--vegshadow=1":
			_veg_shadows = true  # test aid: plants cast shadows


func _place(at: Vector2i, scene: PackedScene) -> void:
	super(at, scene)
	var tile := _tiles[at] as Node3D
	var roads := tile.get_node_or_null("Roads") as MeshInstance3D
	if roads:
		for s in roads.mesh.get_surface_count():
			roads.set_surface_override_material(s, _road_material(roads.mesh.surface_get_name(s)))
	for c in tile.get_children():
		if c is MultiMeshInstance3D and c.has_meta("veg"):
			var kind: String = c.get_meta("veg")
			var mm := (c as MultiMeshInstance3D).multimesh
			var share: float = _share_override.get(kind, VEG_SHARE.get(kind, 1.0)) * Perf.density()
			mm.visible_instance_count = roundi(mm.instance_count * share)
			c.visible = mm.visible_instance_count > 0
			c.visibility_range_end *= Perf.visibility()
			if not _veg_shadows:
				(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Asphalt as on the hand-made circuits, gravel for the dirt roads, white for the painted lines.
func _road_material(kind: String) -> Material:
	if _road_mats.has(kind):
		return _road_mats[kind]
	var mat: Material
	match kind:
		"Sterrato":
			var m := StandardMaterial3D.new()
			m.albedo_texture = load(DIRT)
			m.albedo_color = Color(0.85, 0.75, 0.62)
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3(0.15, 0.15, 0.15)
			m.roughness = 0.95
			mat = m
		"Segnaletica":
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.92, 0.92, 0.88)
			m.roughness = 0.7
			mat = m
		_:
			mat = load(ASPHALT)
	_road_mats[kind] = mat
	return mat


func menu_camera(t: float) -> Array:
	return [Vector3(sin(t) * 3000, 1400, cos(t) * 3000), Vector3(0, 200, 0)]
