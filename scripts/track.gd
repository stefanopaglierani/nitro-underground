class_name Track
extends Node3D
## A level: builds the world and tells the game where to race, where cars spawn and how the AI
## follows the roads. City and Mountain extend it; main.gd only talks to this interface.

## Size of the area the menu camera circles around.
var extent := 0.0
## Camera far plane for this level.
var view_distance := 900.0
## Night level: the drawn styles keep its own sky and lights instead of the daytime ones.
var night := false
## Racing line painted on the road (hidden unless the game shows it), or null.
var guide: Node3D


func build() -> void:
	pass


## The build split into steps, so the loading screen can show progress between them: an array of
## [label, Callable]. By default one step that runs build().
func build_steps() -> Array:
	return [["Livello", build]]


## How far `pos` is outside the drivable area, in metres (0 or less: inside). INF-safe default:
## levels without a limit always answer 0.
func off_track_distance(_pos: Vector3) -> float:
	return 0.0


## Where to put a car back on the road near `pos`: [position, facing].
func recovery_point(pos: Vector3) -> Array:
	return [pos + Vector3(0, 1, 0), Vector3.FORWARD]


## Racing line drawn on the road, if the level has one (see Mountain).
func racing_line() -> Array[Vector3]:
	return []


## Sky, sun and fog for this level, added under `parent`.
func setup_environment(_parent: Node) -> void:
	pass


## Next point to drive to on the way from pos to target, following the roads.
func route_point(_pos: Vector3, target: Vector3) -> Vector3:
	return target


## Highest speed (m/s) at which a car at pos, heading along fwd, can still make the corners ahead.
## INF when the level does not know.
func advised_speed(_pos: Vector3, _fwd: Vector3) -> float:
	return INF


## Seconds a fast driver needs from a to b along the race, or -1 if the level does not know.
func drive_time(_a: Vector3, _b: Vector3) -> float:
	return -1.0


## Points the AI racers drive through, from the start to the finish line.
func race_path() -> Array[Vector3]:
	return []


## Checkpoints the player drives through: the first is the start, the last the finish.
## Every checkpoint is also a point of race_path().
func race_checkpoints() -> Array[Vector3]:
	return []


## Start grid for the sprint: `count` [position, facing] pairs, front row first.
func start_grid(count: int) -> Array:
	var path := race_path()
	var start := path[0]
	var dir := (path[1] - path[0]).normalized()
	var side := Vector3(-dir.z, 0, dir.x)
	var slots := [Vector2(-3.5, 22), Vector2(3.5, 22), Vector2(-3.5, 12), Vector2(3.5, 12)]
	var out := []
	for i in count:
		var s: Vector2 = slots[i % slots.size()]
		out.append([start + dir * (s.y - 10.0 * (i / slots.size())) + side * s.x, dir])
	return out


## [position, facing] of the player at the start of an escape.
func escape_start() -> Array:
	return [Vector3.ZERO, Vector3.FORWARD]


## [position, facing] for a police car joining the chase. `behind` prefers spots behind the player.
func police_spawn(player_pos: Vector3, _player_fwd: Vector3, _behind: bool, _min_d: float, _max_d: float, _rng: RandomNumberGenerator) -> Array:
	return [player_pos + Vector3(90, 0, 0), Vector3(-1, 0, 0)]


## [camera position, look-at point] for the title screen, t in seconds.
func menu_camera(t: float) -> Array:
	var c := Vector3(extent / 2.0, 0, extent / 2.0)
	return [c + Vector3(sin(t) * 260, 150, cos(t) * 260), c]


## Where the autopilot (tests only) drives next in an escape, once it has reached `goal`.
func autopilot_goal(_pos: Vector3, goal: Vector3) -> Vector3:
	return goal


## A lane for a civilian car: {"curve": Curve3D, "offset": metres to the right of the curve,
## "dir": 1 or -1 along the curve, "loop": true if the curve is closed}.
func traffic_lane(_rng: RandomNumberGenerator) -> Dictionary:
	return {}
