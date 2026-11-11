class_name BakedWorld
extends Track
## A level read from a world file made with the world tools. The game only opens the file:
## ground, road, buildings, trees and collisions are all inside it. Its first road is the race.

const WORLD_PATH := "res://assets/worlds/isola_gara.scn"
const LANE := 3.2
## Grass allowed on each side of the road before the game calls the car back.
const RUN_OFF := 16.0
const PATH_STRIDE := 5  # road samples between race path points
const CHECKPOINTS := 4
## The race starts and ends this many samples inside the road, so that every car has road around it.
const ROAD_MARGIN := 24
const SIDE_GRIP := 16.0  # m/s2, used to work out how fast the corners can be taken
const DECEL := 14.0
const LANE_POINT_STRIDE := 4
const NEAREST_STRIDE := 12
## Seconds added to the first stretch of the clock, for the standing start.
const START_TIME := 5.0

var pts := PackedVector3Array()
var tangents := PackedVector3Array()
var limits := PackedFloat32Array()
var half_width := 4.0
var spacing := 2.0
var sea_level := 0.0
var world_path := WORLD_PATH
## Which road of the world is the race.
var race_road := 0
## The race road is a ring: the race is one lap, and the finish is the start.
var closed := false
## The data stored in the world file.
var world_data: Dictionary
var sea_size := 5000.0
## Slowest frame since the race started, in milliseconds.
var worst_frame_ms := 0.0
var _lane_curve: Curve3D
var _stats: Label
var _stats_wait := 0.0
var _lowest_fps := 1000.0
var _race_time := 0.0


func _init() -> void:
	extent = 600.0
	view_distance = 1400.0


func build_steps() -> Array:
	return [["Mondo", _load_world], ["Mare", _build_sea]]


func _load_world() -> void:
	var world := (load(world_path) as PackedScene).instantiate() as Node3D
	add_child(world)
	var data: Dictionary = world.get_meta("terrain_data")
	world_data = data
	sea_level = data.sea_level
	var road: Dictionary = (data.roads as Array)[race_road]
	closed = road.get("closed", false)
	half_width = road.width * 0.5
	spacing = road.sample_spacing
	var path: PackedVector2Array = road.path
	var heights: PackedFloat32Array = road.heights
	pts.resize(path.size())
	for i in path.size():
		pts[i] = Vector3(path[i].x, heights[i], path[i].y)
	tangents.resize(pts.size())
	limits.resize(pts.size())
	if Perf.mobile:
		_add_stats()
	var last := pts.size() - 1
	for i in pts.size():
		var a := pts[posmod(i - 5, last)] if closed else pts[maxi(i - 5, 0)]
		var b := pts[i]
		var c := pts[(i + 5) % last] if closed else pts[mini(i + 5, last)]
		tangents[i] = (c - a).normalized()
		limits[i] = sqrt(SIDE_GRIP * _radius(a, b, c))


## Numbers on the screen for the phone test: how fast it runs and how much it uses.
func _add_stats() -> void:
	var layer := CanvasLayer.new()
	_stats = Label.new()
	_stats.position = Vector2(232, 72)
	_stats.add_theme_font_size_override("font_size", 18)
	_stats.add_theme_color_override("font_outline_color", Color.BLACK)
	_stats.add_theme_constant_override("outline_size", 4)
	layer.add_child(_stats)
	add_child(layer)


func _process(delta: float) -> void:
	if _stats == null:
		return
	var fps := Performance.get_monitor(Performance.TIME_FPS)
	# The loading screen would spoil the numbers: they count from the start of the race.
	var racing := get_parent() is Main and (get_parent() as Main).state == "race"
	if racing:
		_race_time += delta
		if _race_time > 2.0:
			worst_frame_ms = maxf(worst_frame_ms, delta * 1000.0)
	_stats_wait -= delta
	if _stats_wait > 0.0:
		return
	_stats_wait = 0.5
	if racing and _race_time > 2.0:
		_lowest_fps = minf(_lowest_fps, fps)
	_stats.text = "FPS %d  min %d\nRAM %d MB  video %d MB\n%d mila triangoli  %d draw\n%s" % [fps, _lowest_fps,
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), stats_extra()]


## One more line for the numbers on the screen.
func stats_extra() -> String:
	return "Peggior frame %d ms" % worst_frame_ms


## Radius of the circle through three points, on the ground plane.
static func _radius(a: Vector3, b: Vector3, c: Vector3) -> float:
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var ac := Vector2(c.x - a.x, c.z - a.z)
	var bc := Vector2(c.x - b.x, c.z - b.z)
	var area := absf(ab.cross(ac)) * 0.5
	if area < 0.001:
		return 4000.0
	return minf(ab.length() * ac.length() * bc.length() / (4.0 * area), 4000.0)


func _build_sea() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(sea_size, sea_size)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.42, 0.62)
	material.roughness = 0.25
	var sea := MeshInstance3D.new()
	sea.name = "Sea"
	sea.mesh = plane
	sea.material_override = material
	sea.position.y = sea_level
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sea)


func nearest(pos: Vector3) -> int:
	var best := 0
	var best_d := INF
	for i in range(0, pts.size(), NEAREST_STRIDE):
		var d := Vector2(pos.x - pts[i].x, pos.z - pts[i].z).length_squared()
		if d < best_d:
			best_d = d
			best = i
	for i in range(maxi(best - NEAREST_STRIDE, 0), mini(best + NEAREST_STRIDE + 1, pts.size())):
		var d := Vector2(pos.x - pts[i].x, pos.z - pts[i].z).length_squared()
		if d < best_d:
			best_d = d
			best = i
	return best


func _right(k: int) -> Vector3:
	return Vector3(-tangents[k].z, 0.0, tangents[k].x)


func off_track_distance(pos: Vector3) -> float:
	var k := nearest(pos)
	var d := Vector2(pos.x - pts[k].x, pos.z - pts[k].z).length() - half_width - RUN_OFF
	if pos.y < pts[k].y - 12.0 or pos.y < sea_level - 1.0:
		d = maxf(d, 60.0)
	return d


func recovery_point(pos: Vector3) -> Array:
	var k := clampi(nearest(pos), 2, pts.size() - 3)
	var side := signf((pos - pts[k]).dot(_right(k)))
	return [pts[k] + _right(k) * side * LANE * 0.6 + Vector3(0, 0.6, 0), tangents[k]]


func setup_environment(parent: Node) -> void:
	var env := Environment.new()
	var sky := Sky.new()
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.fog_enabled = true
	env.fog_light_color = Color(0.62, 0.76, 0.9)
	env.fog_density = 0.0004
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.15
	var environment := WorldEnvironment.new()
	environment.environment = env
	parent.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 160, 0)
	sun.light_color = Color(1.0, 0.95, 0.84)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 220.0
	parent.add_child(sun)


func route_point(pos: Vector3, target: Vector3) -> Vector3:
	if pos.distance_to(target) < 40.0:
		return target
	var i := nearest(pos)
	var j := nearest(target)
	if absi(j - i) <= 12:
		return target
	return pts[i + 12 * signi(j - i)]


func advised_speed(pos: Vector3, fwd: Vector3) -> float:
	var i := nearest(pos)
	var dir := 1 if fwd.dot(tangents[i]) >= 0.0 else -1
	var best := INF
	for j in range(1, 80):
		var k := i + dir * j
		if closed:
			k = posmod(k, pts.size() - 1)
		elif k < 0 or k >= pts.size():
			break
		best = minf(best, sqrt(limits[k] * limits[k] + 2.0 * DECEL * j * spacing))
	return best


## Seconds a fast driver needs from a to b along the race road, from how tight the corners are.
func drive_time(a: Vector3, b: Vector3) -> float:
	var i := nearest(a)
	var j := nearest(b)
	var ring := pts.size() - 1
	var steps := posmod(j - i, ring) if closed else j - i
	if steps <= 0:
		return -1.0
	var t := 0.0
	for s in steps:
		var k := (i + s) % ring if closed else i + s
		t += spacing / clampf(limits[k], 12.0, 45.0)
	# From the start line the cars set off standing still.
	if absi(i - ROAD_MARGIN) < 3:
		t += START_TIME
	return t


func race_path() -> Array[Vector3]:
	var out: Array[Vector3] = []
	if closed:
		# One lap, from the start line back to it.
		var ring := pts.size() - 1
		var k := 0
		while k < ring:
			out.append(pts[(ROAD_MARGIN + k) % ring])
			k += PATH_STRIDE
		out.append(pts[ROAD_MARGIN])
		return out
	var last := pts.size() - 1 - ROAD_MARGIN
	var k := ROAD_MARGIN
	while k < last:
		out.append(pts[k])
		k += PATH_STRIDE
	out.append(pts[last])
	return out


func race_checkpoints() -> Array[Vector3]:
	var path := race_path()
	var out: Array[Vector3] = []
	for c in CHECKPOINTS:
		out.append(path[c * (path.size() - 1) / CHECKPOINTS])
	out.append(path[path.size() - 1])
	return out


## Two by two, behind the start line.
func start_grid(count: int) -> Array:
	var out := []
	for i in count:
		var back := 2 + 5 * (i / 2)
		var k := maxi(ROAD_MARGIN - back, 0)
		var side := -LANE if i % 2 == 0 else LANE
		out.append([pts[k] + _right(k) * side, tangents[k]])
	return out


func escape_start() -> Array:
	var k := mini(ROAD_MARGIN + 30, pts.size() - 1)
	return [pts[k] + _right(k) * LANE, tangents[k]]


func police_spawn(player_pos: Vector3, player_fwd: Vector3, behind: bool, min_d: float, max_d: float, rng: RandomNumberGenerator) -> Array:
	var best := -1
	var best_score := -INF
	for k in range(0, pts.size(), 5):
		var to := pts[k] - player_pos
		var d := to.length()
		if d < min_d or d > max_d:
			continue
		var score := -to.normalized().dot(player_fwd) if behind else rng.randf()
		if score > best_score:
			best_score = score
			best = k
	if best < 0:
		best = maxi(nearest(player_pos) - 45, 0)
	var p := pts[best] + Vector3.UP * 0.4
	return [p, route_point(p, player_pos) - p]


func menu_camera(t: float) -> Array:
	return [Vector3(sin(t) * 420, 180, cos(t) * 420), Vector3(0, 20, 0)]


func autopilot_goal(pos: Vector3, _goal: Vector3) -> Vector3:
	return pts[mini(nearest(pos) + pts.size() / 4, pts.size() - 1)]


func traffic_lane(rng: RandomNumberGenerator) -> Dictionary:
	if _lane_curve == null:
		_lane_curve = Curve3D.new()
		_lane_curve.bake_interval = 1.0
		for k in range(0, pts.size(), LANE_POINT_STRIDE):
			_lane_curve.add_point(pts[k])
		_lane_curve.add_point(pts[pts.size() - 1])
	return {"curve": _lane_curve, "offset": LANE, "dir": 1.0 if rng.randf() < 0.5 else -1.0, "loop": closed}
