class_name TrafficCar
extends RigidBody3D
## Civilian car that drives along one lane of the track. It is a real rigid body with the weight
## of a car: while it drives, a limited push keeps it on its lane at its own speed, so a hit
## shoves it sideways instead of stopping the player dead. A hard hit (or being shoved off the
## lane) turns the driver into a passenger: the car spins, slides and rolls under gravity until it
## stops. Out of sight of every racer it goes back on its lane and drives on.
## On an open lane it wraps around to the start when it reaches the end.

const BODIES := ["sedan", "hatchback", "suv", "van", "taxi", "pickup"]
## Strongest push the driver can give to stay on the lane, in m/s². A hit bigger than this wins.
const DRIVE_ACCEL := 12.0
## Shoved this far (in m/s) from the speed it wants and the driver loses control.
const CRASH_DV := 4.5
## Gap kept to the traffic car in front on the same lane, in metres.
const FOLLOW_GAP := 16.0
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
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.9, 1.5, 4.2)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 0.85
	add_child(col)
	add_child(CarModel.build(Color(0, 0, 0, 0), false, BODIES[rng.randi() % BODIES.size()]))
	contact_monitor = true
	max_contacts_reported = 4
	_set_driving_layers(true)
	global_transform = _lane_transform(t)
	linear_velocity = -global_transform.basis.z * speed


## Moves the car along its lane until it is clear of the cars already placed.
func place_clear(rng: RandomNumberGenerator, placed: Array[TrafficCar]) -> void:
	for attempt in 20:
		var clear := true
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
		if _wreck_t > WRECK_TIME and not _seen():
			_back_on_lane()
		elif _wreck_t > WRECK_TIME and _can_drive_off():
			_drive_off()
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
	speed = move_toward(speed, clampf(want, 0.0, cruise), 6.0 * delta)
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
	var tangent := -target.basis.z
	# Velocity that keeps the car on its lane point: the lane speed plus a pull back to the point.
	var desired := tangent * speed + (target.origin - state.transform.origin) * 3.0
	var dv := desired - state.linear_velocity
	# Only a hit counts: without contacts a big gap is a tight bend the push is catching up on.
	var hit := state.get_contact_count() > 0
	if dv.length() > CRASH_DV * (1.0 if hit else 3.0):
		_lose_control()
		return
	state.linear_velocity += dv.limit_length(DRIVE_ACCEL * state.step)
	# Turn towards the lane direction (and level with the road) with a limited rate.
	var err := (target.basis * state.transform.basis.inverse()).orthonormalized().get_rotation_quaternion()
	var ang := err.get_angle()
	var axis := err.get_axis() if ang > 0.001 else Vector3.UP
	if ang > PI:
		ang -= TAU
	if absf(ang) > (0.6 if hit else 1.2):
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


## A wreck that came to rest upright, roughly along its lane, can simply drive on from there.
func _can_drive_off() -> bool:
	if linear_velocity.length() > 1.0 or global_transform.basis.y.y < 0.85:
		return false
	var tr := _lane_transform(curve.get_closest_offset(global_position))
	return tr.origin.distance_to(global_position) < 3.0 and (-global_transform.basis.z).dot(-tr.basis.z) > 0.7


func _drive_off() -> void:
	t = curve.get_closest_offset(global_position)
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
	crashed = false
	_set_driving_layers(true)
	gravity_scale = 0.0
	linear_damp = 0.0
	angular_damp = 0.6
	global_transform = tr
	speed = 0.0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

