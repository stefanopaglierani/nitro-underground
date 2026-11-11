class_name TiledWorld
extends BakedWorld
## A world too big to keep in memory: the ground comes in tiles, read in the background around
## the camera. Roads and everything else stay in the world file (BakedWorld).

const FOLDER := "res://assets/worlds/isola_x5/"
const RINGS_PC := 3
const RINGS_PHONE := 2
## At most this many tiles being read at the same time.
const MAX_PENDING := 3
const CHECK_EVERY := 0.2
const SEA_SIZE := 14000.0

var tile_size := 320.0
var tile_origin := Vector2.ZERO
var rings := RINGS_PHONE
var _available := {}
var _tiles := {}
var _pending := {}
var _terrain_material: Material
var _wait := 0.0
var _slowest_add_ms := 0.0
var _print_wait := 5.0


func _init() -> void:
	super()
	world_path = FOLDER + "world.scn"
	extent = 2500.0
	view_distance = 1200.0
	sea_size = SEA_SIZE
	rings = RINGS_PHONE if Perf.mobile else RINGS_PC


func build_steps() -> Array:
	return [["Mondo", _load_world], ["Mare", _build_sea], ["Terreno", _load_start_tiles]]


func _load_start_tiles() -> void:
	var tiles: Dictionary = world_data.tiles
	tile_size = tiles.size
	tile_origin = tiles.origin
	for at: Vector2i in tiles.list:
		_available[at] = true
	_terrain_material = world_data.terrain_material
	var center := _tile_at(pts[ROAD_MARGIN])
	for at in _wanted(center):
		var scene := load(_path(at)) as PackedScene
		_place(at, scene)
	_slowest_add_ms = 0.0


func _tile_at(pos: Vector3) -> Vector2i:
	return Vector2i(floori((pos.x - tile_origin.x) / tile_size), floori((pos.z - tile_origin.y) / tile_size))


func _path(at: Vector2i) -> String:
	return FOLDER + "tile_%d_%d.scn" % [at.x, at.y]


## Existing tiles around `center`, the nearest first.
func _wanted(center: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for z in range(center.y - rings, center.y + rings + 1):
		for x in range(center.x - rings, center.x + rings + 1):
			var at := Vector2i(x, z)
			if _available.has(at):
				out.append(at)
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return (a - center).length_squared() < (b - center).length_squared())
	return out


func _place(at: Vector2i, scene: PackedScene) -> void:
	var t0 := Time.get_ticks_usec()
	var tile := scene.instantiate() as Node3D
	for mesh_name: String in ["Near", "Far"]:
		var mesh := tile.get_node(mesh_name) as MeshInstance3D
		mesh.material_override = _terrain_material
	# Perf.apply() must not shorten the range of the detailed mesh: the light one starts there.
	(tile.get_node("Near") as MeshInstance3D).visibility_range_begin = 0.001
	add_child(tile)
	_tiles[at] = tile
	_slowest_add_ms = maxf(_slowest_add_ms, (Time.get_ticks_usec() - t0) / 1000.0)


func _process(delta: float) -> void:
	super(delta)
	if _available.is_empty():
		return
	_finish_one()
	_wait -= delta
	if _wait <= 0.0:
		_wait = CHECK_EVERY
		_stream()
	if OS.get_cmdline_user_args().has("--autotest"):
		if delta > 0.05 and get_parent() is Main:
			var main := get_parent() as Main
			print("[slow] %d ms at race %.1f s, state %s, police %d, tiles %d, pending %d" % [delta * 1000.0, main.race_time, main.state, main.police.size(), _tiles.size(), _pending.size()])
		_print_wait -= delta
		if _print_wait <= 0.0:
			_print_wait = 5.0
			print("[tiles] %s" % stats_extra())


func _stream() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var center := _tile_at(camera.global_position)
	for at in _wanted(center):
		if _pending.size() >= MAX_PENDING:
			break
		if not _tiles.has(at) and not _pending.has(at):
			_pending[at] = true
			ResourceLoader.load_threaded_request(_path(at), "PackedScene", false, ResourceLoader.CACHE_MODE_REUSE)
	for at: Vector2i in _tiles.keys():
		if maxi(absi(at.x - center.x), absi(at.y - center.y)) > rings + 1:
			(_tiles[at] as Node3D).queue_free()
			_tiles.erase(at)


## One new tile per frame goes into the scene, so that the cost is spread out.
func _finish_one() -> void:
	for at: Vector2i in _pending.keys():
		var status := ResourceLoader.load_threaded_get_status(_path(at))
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		_pending.erase(at)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_place(at, ResourceLoader.load_threaded_get(_path(at)) as PackedScene)
		return


func stats_extra() -> String:
	return "Tessere %d  aggiunta max %d ms  peggior frame %d ms" % [_tiles.size(), _slowest_add_ms, worst_frame_ms]
