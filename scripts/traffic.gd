class_name TrafficCar
extends RigidBody3D
## Civilian car that drives along one lane of the track. It is a real rigid body with the weight
## of a car: while it drives, a limited push keeps it on its lane at its own speed, so a hit
## shoves it sideways instead of stopping the player dead. A hard hit (or being shoved off the
## lane) turns the driver into a passenger: the car spins, slides and rolls under gravity until it
## stops. Out of sight of every racer it goes back on its lane and drives on.
## On an open lane it wraps around to the start when it reaches the end.

## Strongest push the driver can give to stay on the lane, in m/s². A hit bigger than this wins.
const DRIVE_ACCEL := 12.0
## Shoved this far (in m/s) from the speed it wants and the driver loses control.
const CRASH_DV := 4.5
## Gap kept to the traffic car in front on the same lane, in metres.
const FOLLOW_GAP := 16.0
## After any hit from a racing car (even a light rear-end) the driver stops: the car stands
## still for this many seconds (it can still be pushed), then drives off again on its own,
## steering round a racing car that is in its way.
const STOP_TIME := 3.0
## Sideways step (m) a car takes to get round a racing car blocking it, and how fast it steps.
const DODGE_STEP := 3.2
const DODGE_RATE := 1.6
## How far ahead (m) a car looks for a racing car in its way.
const DODGE_LOOK := 18.0
## A wreck goes back on its lane after this many seconds, once no racer is near enough to see it.
const WRECK_TIME := 7.0
const WRECK_HIDE_DIST := 70.0
const WORLD_LAYER := 1
## Physics layer of the traffic; the racing cars (car.gd) look for it in their mask.
const TRAFFIC_LAYER := 2
## Extra physics layer the racing cars sit on, so a driving traffic car can meet them alone.
const CARS_LAYER := 4

var curve: Curve3D
var offset := 3.5
var dir := 1.0
var loop := false
## Speed this driver likes to drive at, and the speed it drives at now (slower behind a car).
var cruise := 11.0
var speed := 11.0
var t := 0.0
var crashed := false
var _length := 0.0
var _wreck_t := 0.0
var _lane_mates: Array[TrafficCar] = []
## Sideways shift (m, + to the right) from the lane while getting back to it or round a car.
var _shift := 0.0
var _shift_goal := 0.0
## Seconds left in which a touch doesn't stop the car: it is pulling away from the car it hit.
var _pull_away_t := 0.0
## A racing car is right against the front: back up a little before stepping round it.
var _too_close := false


func setup(track: Track, rng: RandomNumberGenerator, start_t := -1.0) -> void:
	add_to_group("traffic")
	var lane := track.traffic_lane(rng)
	curve = lane["curve"]
	offset = lane["offset"]
	dir = lane["dir"]
	loop = lane["loop"]
	_length = curve.get_baked_length()
	cruise = rng.randf_range(9.0, 14.0)
	speed = cruise
	t = start_t if start_t >= 0.0 else rng.randf_range(0.0, _length)
	# A little heavier than the racers: hitting a van at speed should hurt, but it moves.
	mass = 1400.0 if rng.randf() < 0.3 else 1250.0
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, 0.55, 0)
	gravity_scale = 0.0
	can_sleep = false
	continuous_cd = true
	angular_damp = 0.6
	var phys := PhysicsMaterial.new()
	phys.friction = 0.7
	phys.bounce = 0.1
	physics_material_override = phys
	var body: String = CarCatalog.TRAFFIC[rng.randi() % CarCatalog.TRAFFIC.size()]
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.9, 1.5, minf(float(CarCatalog.find(body).get("len", 4.5)) - 0.3, 5.4))
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 0.85
	add_child(col)
	add_child(CarModel.build(Color(0, 0, 0, 0), false, body))
	contact_monitor = true
	max_contacts_reported = 4
	_set_driving_layers(true)
	global_transform = _lane_transform(t)
	linear_velocity = -global_transform.basis.z * speed


## Moves the car along its lane until it is clear of the cars already placed.
func place_clear(rng: RandomNumberGenerator, placed: Array[TrafficCar], keep_away := Vector3.INF) -> void:
	for attempt in 20:
		# Not right in front of the start grid: the race would open with a pile-up.
		var clear := keep_away == Vector3.INF or global_position.distance_to(keep_away) > 160.0
		for o in placed:
			if o.global_position.distance_to(global_position) < 14.0:
				clear = false
				break
		if clear:
			return
		t = rng.randf_range(0.0, _length)
		global_transform = _lane_transform(t)
		linear_velocity = -global_transform.basis.z * speed


## Lets each car know the others on its lane, for keeping a gap. Called once all are spawned.
static func link_lanes(cars: Array[TrafficCar]) -> void:
	for a in cars:
		a._lane_mates.clear()
		for b in cars:
			if b != a and b.curve == a.curve and b.dir == a.dir and absf(b.offset - a.offset) < 0.5:
				a._lane_mates.append(b)


func _wrap(x: float) -> float:
	if loop:
		return fposmod(x, _length)
	if x > _length:
		return 0.0
	if x < 0.0:
		return _length
	return x


## Where the car sits on its lane at distance `at` along the curve, facing its way of travel.
func _lane_transform(at: float) -> Transform3D:
	var pos := curve.sample_baked(at)
	var ahead_t := fposmod(at + dir * 2.0, _length) if loop else clampf(at + dir * 2.0, 0.0, _length)
	var facing := curve.sample_baked(ahead_t) - pos
	if loop == false and (ahead_t == 0.0 or ahead_t == _length):
		facing = pos - curve.sample_baked(clampf(at - dir * 2.0, 0.0, _length))
	var flat := Vector3(facing.x, 0, facing.z)
	if flat.length() < 0.01:
		return global_transform
	var right := flat.normalized().cross(Vector3.UP)
	# Pitch with the road so the car sits on slopes.
	return Transform3D(Basis.looking_at(facing.normalized(), Vector3.UP), pos + right * offset)


func _physics_process(delta: float) -> void:
	if crashed:
		_wreck_t += delta
		if _wreck_t > STOP_TIME and _can_drive_off():
			_drive_off()
		elif _wreck_t > WRECK_TIME and not _seen():
			_back_on_lane()
		elif _wreck_t > WRECK_TIME * 3.0:
			_back_on_lane()  # still stuck in plain sight: clear the road anyway, or the lane jams
		return
	# Slow down behind a slower car on the same lane instead of driving into it.
	var want := cruise
	for m in _lane_mates:
		var gap := fposmod((m.t - t) * dir, _length) if loop else (m.t - t) * dir
		if gap > 0.0 and gap < FOLLOW_GAP + 10.0:
			if m.crashed and m.global_position.distance_to(m._lane_transform(m.t).origin) > 3.0:
				continue  # the wreck lies off the lane
			var m_speed := 0.0 if m.crashed else m.speed
			want = minf(want, m_speed + (gap - FOLLOW_GAP) * 0.6)
	# A racing car right in front: step round it, slowly. Otherwise ease back onto the lane.
	_pull_away_t -= delta
	_shift_goal = _dodge_goal()
	if absf(_shift - _shift_goal) > 0.5:
		want = minf(want, 5.0)
	if _too_close:
		want = -2.0  # reverse a few metres first
	_shift = move_toward(_shift, _shift_goal, DODGE_RATE * delta)
	speed = move_toward(speed, clampf(want, -2.0, cruise), 6.0 * delta)
	t = _wrap(t + dir * speed * delta)
	if not loop and (t == 0.0 or t == _length):
		# Wrapped to the other end of an open road: jump there.
		global_transform = _lane_transform(t)
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if crashed:
		return
	var target := _lane_transform(t)
	target.origin += target.basis.x * _shift
	var tangent := -target.basis.z
	# Velocity that keeps the car on its lane point: the lane speed plus a pull back to the point.
	var desired := tangent * speed + (target.origin - state.transform.origin) * 3.0
	var dv := desired - state.linear_velocity
	# While it drives it only meets racing cars: any touch from one stops the driver (STOP_TIME).
	var hit := state.get_contact_count() > 0
	if hit and _pull_away_t <= 0.0:
		_lose_control()
		return
	# Without contacts a big gap is a tight bend the push is catching up on.
	if dv.length() > CRASH_DV * 3.0:
		_lose_control()
		return
	state.linear_velocity += dv.limit_length(DRIVE_ACCEL * state.step)
	# Turn towards the lane direction (and level with the road) with a limited rate.
	var err := (target.basis * state.transform.basis.inverse()).orthonormalized().get_rotation_quaternion()
	var ang := err.get_angle()
	var axis := err.get_axis() if ang > 0.001 else Vector3.UP
	if ang > PI:
		ang -= TAU
	if absf(ang) > 1.2:
		_lose_control()
		return
	state.angular_velocity = state.angular_velocity.move_toward(axis * ang * 4.0, 8.0 * state.step)


## While it drives on its lane the car only meets the racing cars (and wrecks): the lane can
## brush a guardrail or the hillside on a hairpin, and the opposite lane on a tight bend.
## A wreck meets everything, so it lands on the road and slides into the rails.
func _set_driving_layers(driving: bool) -> void:
	collision_layer = TRAFFIC_LAYER
	collision_mask = CARS_LAYER if driving else WORLD_LAYER | TRAFFIC_LAYER | CARS_LAYER


## The driver loses the car: from now on it is just a heavy box under gravity.
func _lose_control() -> void:
	_set_driving_layers.call_deferred(false)
	crashed = true
	_wreck_t = 0.0
	gravity_scale = 1.5
	linear_damp = 0.3
	angular_damp = 1.0
	speed = 0.0


## A car that came to rest upright, roughly along its lane (it may have been shoved a few metres
## aside), can simply drive on from there.
func _can_drive_off() -> bool:
	if linear_velocity.length() > 1.0 or global_transform.basis.y.y < 0.85:
		return false
	var tr := _lane_transform(curve.get_closest_offset(global_position))
	return tr.origin.distance_to(global_position) < 6.0 and (-global_transform.basis.z).dot(-tr.basis.z) > 0.5


## Sideways shift that takes the car round a racing car stopped or slow right in front of it.
func _dodge_goal() -> float:
	var fwd := -global_transform.basis.z
	var right := global_transform.basis.x
	_too_close = false
	for c: Node3D in get_tree().get_nodes_in_group("cars"):
		var rel := c.global_position - global_position
		var along := rel.dot(fwd)
		var lat := rel.dot(right)
		if along > 0.0 and along < DODGE_LOOK and absf(lat) < 2.4:
			_too_close = along < 6.0 and _pull_away_t > -3.0
			if absf(_shift_goal) > 0.1:
				return _shift_goal  # already stepping round it
			return clampf(_shift + (-DODGE_STEP if lat > 0.0 else DODGE_STEP), -6.0, 6.0)
	# Hold the step until the car it is passing is behind it.
	if absf(_shift_goal) > 0.1:
		for c: Node3D in get_tree().get_nodes_in_group("cars"):
			var rel := c.global_position - global_position
			var along := rel.dot(fwd)
			if along > -6.0 and along < DODGE_LOOK and absf(rel.dot(right)) < 4.5:
				return _shift_goal
	return 0.0


func _drive_off() -> void:
	t = curve.get_closest_offset(global_position)
	# Start from where it stands, then ease back onto the lane.
	var lane := _lane_transform(t)
	_shift = (global_position - lane.origin).dot(lane.basis.x)
	_pull_away_t = 1.5
	crashed = false
	_set_driving_layers(true)
	gravity_scale = 0.0
	linear_damp = 0.0
	angular_damp = 0.6
	speed = 0.0


func _seen() -> bool:
	for c: Node3D in get_tree().get_nodes_in_group("cars"):
		if c.global_position.distance_to(global_position) < WRECK_HIDE_DIST:
			return true
	return false


## Back on the lane where the wreck lies, driving again, once nothing is in the way there.
func _back_on_lane() -> void:
	var at := curve.get_closest_offset(global_position) if global_position.y > -50.0 else t
	var tr := _lane_transform(at)
	for n: Node3D in get_tree().get_nodes_in_group("traffic"):
		if n != self and n.global_position.distance_to(tr.origin) < 8.0:
			return  # try again next frame
	t = at
	_shift = 0.0
	_shift_goal = 0.0
	crashed = false
	_set_driving_layers(true)
	gravity_scale = 0.0
	linear_damp = 0.0
	angular_damp = 0.6
	global_transform = tr
	speed = 0.0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

