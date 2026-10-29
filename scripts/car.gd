class_name Car
extends RigidBody3D
## Car shared by the player, the AI racers and the police.
## A rigid body carried by four raycast wheels: each wheel has a spring-damper suspension and a
## tyre that pushes along and across the road, limited by the load on that wheel. Jumps, landings
## and crashes come out of the physics engine; a few arcade assists keep it fun to drive.
## Each frame a controller fills the in_* inputs; _physics_process turns them into forces.

signal crashed(impact: float, other: Object)
## Emitted once the car has been off the ground for JUMP_MIN_AIR seconds (bumps don't count).
signal took_off
## Emitted when a wheel touches down after a jump; impact_speed is the downward speed in m/s.
signal landed(air_time: float, impact_speed: float)

enum Driver { PLAYER, RACER, POLICE }

const WHEEL_X := 0.86
const WHEEL_Z := 1.35
const MOUNT_Y := 0.55
const JUMP_MIN_AIR := 0.15
## Car models (assets/cars_rgsdev) for the AI racers and the police.
const RACER_BODIES := ["muscle", "roadster", "muscle_2", "hatchback"]
const POLICE_BODIES := ["police_sedan", "police_sports", "police_muscle", "police_suv"]
## Car the player picked in the garage (CarCatalog id); it keeps its own colours.
static var player_body := "mclaren_600lt"

var driver: Driver = Driver.PLAYER
var frozen := true:
	set(value):
		frozen = value
		freeze = value

# ---- Tuning (SI units: kg, m, s, N). 42 m/s is about 150 km/h. ----
var max_speed := 42.0
var engine_force := 11000.0
var brake_force := 15000.0
var reverse_max := 10.0
var nitro_mult := 1.35
var nitro_force_mult := 1.8
var gravity_mult := 1.5
var spring_rest := 0.3
var wheel_radius := 0.35
var spring_k := 45000.0
var damper := 4200.0
## Extension is damped harder than compression, like a real shock absorber, so hard landings
## don't throw the car back into the air.
var rebound_ratio := 1.8
var bump_stop := 0.08
var grip := 1.05
var handbrake_rear_grip := 0.5
var front_drive := 0.35
var max_steer_low := deg_to_rad(32)
var max_steer_high := deg_to_rad(7)
var steer_rate := 4.0
var yaw_assist := 0.55
var downforce := 1.0
var drag := 0.42
var roll_reduction := 0.75
## Air control (player only): steering spins the car, brake lifts the nose, handbrake drops it.
var air_yaw_rate := 4.0
var air_pitch_rate := 3.0
var air_response := 3.0
## Kept for the AI corner-speed estimate: roughly the deceleration of a full brake.
var brake_decel := 11.0

var nitro := 1.0
var nitro_drain := 0.35
var nitro_refill := 0.05

# Inputs, -1..1 or 0..1.
var in_throttle := 0.0
var in_brake := 0.0
var in_steer := 0.0
var in_handbrake := false
var in_nitro := false

# Read by the game and the AI.
var speed := 0.0
var lateral := 0.0
var drifting := false
var using_nitro := false
var wheels_on_ground := 0
var airborne_time := 0.0
var jumping := false
## Position and velocity on the last frame with a wheel on the ground before the current jump.
var takeoff_position := Vector3.ZERO
var takeoff_velocity := Vector3.ZERO
## Rotation in degrees since the wheels left the ground (x pitch, y yaw, z roll, signed), kept
## after landing until the next jump. A backflip is about +360 on x, a full spin to the right -360 on y.
var air_rotation := Vector3.ZERO
## How the last jump ended: tilt of the body from upright and angle between the nose and the
## direction of travel, in degrees. Small values mean a clean landing.
var landing_tilt := 0.0
var landing_slip := 0.0
var velocity: Vector3:
	get:
		return linear_velocity

# AI state
var city: Track
var waypoints: Array[Vector3] = []
var wp_index := 0
var lane_offset := 0.0
## Extra sideways shift a racer takes to get round a traffic car, eased in and out.
var _dodge := 0.0
## Speed limit set by a traffic car blocking both sides of the road (INF when the road is clear).
var _traffic_limit := INF
var chase_target: Car
var finished := false
var _stuck := 0.0
var _reverse_t := 0.0

var _wheel_pos: Array[Vector3] = [
	Vector3(-WHEEL_X, MOUNT_Y, -WHEEL_Z), Vector3(WHEEL_X, MOUNT_Y, -WHEEL_Z),
	Vector3(-WHEEL_X, MOUNT_Y, WHEEL_Z), Vector3(WHEEL_X, MOUNT_Y, WHEEL_Z),
]
var _rays: Array[RayCast3D] = []
var _wheel_nodes: Array[Node3D] = []
var _wheel_base_y: Array[float] = []  # height of each wheel pivot in the model (its tyre radius)
var _susp_len: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _steer := 0.0
var _upside_down_t := 0.0
var _body_on_ground := false

var _model: Node3D
var _smoke: CPUParticles3D
var _flame: CPUParticles3D
var _tail_mat: StandardMaterial3D
var _siren_red: StandardMaterial3D
var _siren_blue: StandardMaterial3D
var _siren_light: OmniLight3D
var _hit_cooldown := 0.0
var _time := 0.0


func setup(kind: Driver, paint: Color, the_city: Track) -> void:
	driver = kind
	city = the_city
	mass = 1200.0
	gravity_scale = gravity_mult
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, 0.15, 0)
	# Air drag and rolling resistance are modelled in _apply_vehicle_forces; no engine damping.
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	linear_damp = 0.0
	angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	angular_damp = 0.8
	can_sleep = false
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 6
	var phys := PhysicsMaterial.new()
	phys.friction = 0.35
	phys.bounce = 0.15
	physics_material_override = phys

	var shape := BoxShape3D.new()
	# Covers the body from the sills to the roof, so a car on its roof rests on it.
	shape.size = Vector3(1.9, 1.15, 4.2)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 1.0
	add_child(col)

	for i in 4:
		var ray := RayCast3D.new()
		ray.position = _wheel_pos[i]
		ray.target_position = Vector3(0, -(spring_rest + wheel_radius), 0)
		ray.add_exception(self)
		ray.enabled = true
		add_child(ray)
		_rays.append(ray)
		_susp_len[i] = spring_rest

	var body := player_body
	var model_paint := Color(0, 0, 0, 0) if kind == Driver.PLAYER else paint
	if kind == Driver.RACER:
		body = RACER_BODIES[absi(hash(paint)) % RACER_BODIES.size()]
	elif kind == Driver.POLICE:
		body = POLICE_BODIES[get_instance_id() % POLICE_BODIES.size()]
	_model = CarModel.build(model_paint, kind == Driver.POLICE, body)
	add_child(_model)
	for n in ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]:
		_wheel_nodes.append(_model.get_node(n))
		_wheel_base_y.append((_model.get_node(n) as Node3D).position.y)
	_tail_mat = _model.get_meta("tail_mat")

	_smoke = _make_particles(Color(0.75, 0.75, 0.8, 0.35), Vector3(0, 0.3, 1.6), 0.9, 48)
	_smoke.direction = Vector3(0, 1, 0.3)
	_smoke.initial_velocity_min = 1.0
	_smoke.initial_velocity_max = 2.5
	_smoke.scale_amount_min = 0.6
	_smoke.scale_amount_max = 1.4
	_smoke.local_coords = false
	_flame = _make_particles(Color(0.3, 0.7, 1.0), Vector3(0, 0.45, 2.2), 0.18, 24, true)
	_flame.direction = Vector3(0, 0, 1)
	_flame.initial_velocity_min = 6.0
	_flame.initial_velocity_max = 9.0
	_flame.local_coords = true

	match kind:
		Driver.PLAYER:
			var head := SpotLight3D.new()
			head.position = Vector3(0, 0.8, -2.2)
			head.rotation_degrees.x = -8
			head.spot_range = 32
			head.spot_angle = 32
			head.light_energy = 4.0
			head.light_color = Color(1, 0.95, 0.85)
			add_child(head)
			var glow := OmniLight3D.new()
			glow.position = Vector3(0, 0.25, 0)
			glow.omni_range = 4.5
			glow.light_energy = 3.0
			glow.light_color = paint.lightened(0.3)
			add_child(glow)
		Driver.RACER:
			max_speed = 40.0
		Driver.POLICE:
			max_speed = 41.0
			engine_force = 11500.0
			_siren_red = _model.get_meta("siren_red")
			_siren_blue = _model.get_meta("siren_blue")
			_siren_light = OmniLight3D.new()
			_siren_light.position = Vector3(0, 2.2, 0)
			_siren_light.omni_range = 12
			_siren_light.light_energy = 3.0
			add_child(_siren_light)
	freeze = frozen


func _make_particles(color: Color, pos: Vector3, life: float, amount: int, emissive := false) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.emitting = false
	p.position = pos
	p.spread = 25
	p.gravity = Vector3.ZERO
	var mesh := SphereMesh.new()
	mesh.radius = 0.35
	mesh.height = 0.7
	mesh.radial_segments = 6
	mesh.rings = 3
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	if emissive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mesh.material = m
	p.mesh = mesh
	add_child(p)
	return p


func place(pos: Vector3, facing: Vector3) -> void:
	var flat := Vector3(facing.x, 0, facing.z).normalized()
	global_transform = Transform3D(Basis.looking_at(flat, Vector3.UP), pos + Vector3(0, 0.1, 0))
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	jumping = false


## Yaw angle of the car's nose on the ground plane (ignores pitch and roll).
func heading() -> float:
	var f := -global_transform.basis.z
	return atan2(-f.x, -f.z)


func _physics_process(delta: float) -> void:
	_time += delta
	if frozen:
		_update_visuals(delta)
		return
	match driver:
		Driver.RACER:
			_drive_racer(delta)
		Driver.POLICE:
			_drive_police(delta)
	_apply_vehicle_forces(delta)
	_check_recovery(delta)
	_update_visuals(delta)


func _apply_vehicle_forces(delta: float) -> void:
	var b := global_transform.basis
	var fwd := -b.z
	var up := b.y
	var right := b.x
	var v := linear_velocity
	speed = v.dot(fwd)
	lateral = v.dot(right)

	using_nitro = in_nitro and nitro > 0.02 and in_throttle > 0.1
	if using_nitro:
		nitro = maxf(0.0, nitro - nitro_drain * delta)
	else:
		nitro = minf(1.0, nitro + nitro_refill * delta + (0.15 * delta if drifting else 0.0))

	# Steering gets smaller as speed grows, like an arcade racer.
	var speed_t := clampf((absf(speed) - 8.0) / (max_speed - 8.0), 0.0, 1.0)
	var max_steer := lerpf(max_steer_low, max_steer_high, sqrt(speed_t))
	_steer = move_toward(_steer, in_steer * max_steer, steer_rate * max_steer * delta)

	var top := max_speed * (nitro_mult if using_nitro else 1.0)
	var drive := 0.0
	var braking := 0.0
	if in_brake > 0.0 and speed > 1.0:
		braking = in_brake
	elif in_brake > 0.0:
		drive = -in_brake * 0.6 if speed > -reverse_max else 0.0
	else:
		drive = in_throttle * (nitro_force_mult if using_nitro else 1.0)
		drive *= clampf(1.0 - pow(maxf(speed, 0.0) / top, 3.0), 0.0, 1.0)

	wheels_on_ground = 0
	for i in 4:
		var ray := _rays[i]
		ray.force_raycast_update()
		if not ray.is_colliding():
			_susp_len[i] = spring_rest
			continue
		wheels_on_ground += 1
		var hit := ray.get_collision_point()
		var mount := global_transform * _wheel_pos[i]
		var dist := mount.distance_to(hit)
		# Below zero the wheel has been pushed past full travel (hard landing at a low tick rate):
		# the bump stop keeps pushing harder instead of the force topping out.
		var susp := minf(dist - wheel_radius, spring_rest)
		var compression := spring_rest - maxf(susp, 0.0)
		# Compression speed from the body's motion against the road surface under the wheel,
		# which stays right at any tick rate (also when the road tilts, like on a ramp).
		var n := ray.get_collision_normal()
		var mount_v := v + angular_velocity.cross(mount - global_position)
		var susp_speed := -mount_v.dot(n) / maxf(n.dot(up), 0.2)
		_susp_len[i] = maxf(susp, 0.0)
		var spring := spring_k * compression
		var damping := damper * susp_speed * (rebound_ratio if susp_speed < 0.0 else 1.0)
		if susp < bump_stop:
			# Rubber bump stop: stiff, and it soaks up energy instead of giving it back.
			spring += spring_k * 4.0 * (bump_stop - susp)
			damping += damper * 2.0 * maxf(susp_speed, 0.0)
		# Never damp harder than what stops this corner within one step: on a hard landing at a
		# low tick rate a bigger force would overshoot and throw the car back up.
		var max_damp := (mass / 4.0) * absf(susp_speed) / delta
		var load := spring + clampf(damping, -max_damp, max_damp)
		load = maxf(load, 0.0)
		apply_force(up * load, mount - global_position)

		# Tyre forces in the wheel's own frame.
		var front := i < 2
		var wheel_basis := b.rotated(up, -_steer) if front else b
		var w_fwd := -wheel_basis.z
		var w_right := wheel_basis.x
		var contact := hit - global_position
		var pv := v + angular_velocity.cross(contact)
		var v_long := pv.dot(w_fwd)
		var v_lat := pv.dot(w_right)

		var mu := grip
		if in_handbrake and not front:
			mu = handbrake_rear_grip
		var max_f := mu * load
		# Lateral: the force that would cancel sideways sliding this step, capped by grip.
		var f_lat := -v_lat * (mass / 4.0) / delta
		# Longitudinal: engine, brake, handbrake, rolling resistance.
		var share := front_drive if front else (1.0 - front_drive)
		var f_long := drive * engine_force * share * 0.5
		if braking > 0.0:
			f_long -= signf(v_long) * brake_force * braking * 0.25
		if in_handbrake and not front:
			f_long -= signf(v_long) * minf(absf(v_long) * mass / 4.0 / delta, max_f * 0.8)
		if drive == 0.0 and braking == 0.0:
			f_long -= v_long * 30.0
		var f := Vector2(f_long, f_lat)
		if f.length() > max_f:
			f = f.normalized() * max_f
		# Push a little above the contact point to limit body roll (arcade).
		var com := b * center_of_mass
		var at := Vector3(contact.x, lerpf(contact.y, com.y, roll_reduction), contact.z)
		apply_force(w_fwd * f.x + w_right * f.y, at)

	drifting = absf(lateral) > 4.0 and absf(speed) > 8.0 and wheels_on_ground >= 2

	# Touching down on the roof or a side also ends a jump.
	var on_ground := wheels_on_ground > 0 or _body_on_ground
	if on_ground:
		if jumping:
			jumping = false
			landing_tilt = rad_to_deg(acos(clampf(up.dot(Vector3.UP), -1.0, 1.0)))
			var flat := Vector3(v.x, 0, v.z)
			landing_slip = rad_to_deg(flat.angle_to(Vector3(fwd.x, 0, fwd.z))) if flat.length() > 3.0 else 0.0
			landed.emit(airborne_time, maxf(-v.y, 0.0))
		airborne_time = 0.0
		takeoff_position = global_position
		takeoff_velocity = v
	if wheels_on_ground > 0:
		# Yaw assist: pull the spin rate towards what the steering asks for.
		var target_yaw := -speed * tan(_steer) / (WHEEL_Z * 2.0)
		var yaw := angular_velocity.dot(up)
		var assist := yaw_assist * (0.5 if in_handbrake else 1.0)
		apply_torque(up * (target_yaw - yaw) * assist * mass * 1.5 * float(wheels_on_ground) / 4.0)
		apply_central_force(-up * downforce * v.length_squared())
	elif not on_ground:
		if airborne_time == 0.0:
			air_rotation = Vector3.ZERO
		airborne_time += delta
		air_rotation += rad_to_deg(1.0) * (b.inverse() * angular_velocity) * delta
		if driver == Driver.PLAYER:
			_air_control(b)
		if not jumping and airborne_time >= JUMP_MIN_AIR:
			jumping = true
			took_off.emit()

	apply_central_force(-v * v.length() * drag)


func _air_control(b: Basis) -> void:
	# Pull the spin rate on each axis towards what the input asks for; with no input the car keeps
	# the rotation it took off with.
	var torque_k := mass * 1.8 * air_response
	if absf(in_steer) > 0.05:
		var wy := angular_velocity.dot(b.y)
		apply_torque(b.y * (-in_steer * air_yaw_rate - wy) * torque_k)
	var pitch_in := (1.0 if in_brake > 0.1 else 0.0) - (1.0 if in_handbrake else 0.0)
	if pitch_in != 0.0:
		var wx := angular_velocity.dot(b.x)
		apply_torque(b.x * (pitch_in * air_pitch_rate - wx) * torque_k)


func _check_recovery(delta: float) -> void:
	# Lying on its roof or side: put the car back on its wheels after 1.5 s once it has nearly
	# stopped, or after 3 s if it is still sliding.
	var upright := global_transform.basis.y.dot(Vector3.UP)
	if upright < 0.4 and wheels_on_ground == 0 and airborne_time == 0.0:
		_upside_down_t += delta
	else:
		_upside_down_t = 0.0
	if _upside_down_t > 3.0 or (_upside_down_t > 1.5 and linear_velocity.length() < 6.0):
		_upside_down_t = 0.0
		var f := -global_transform.basis.z
		f.y = 0
		if f.length() < 0.1:
			f = Vector3.FORWARD
		place(global_position + Vector3(0, 1.0, 0), f)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	_body_on_ground = false
	for i in state.get_contact_count():
		if state.get_contact_local_normal(i).y > 0.7:
			_body_on_ground = true
			break
	_hit_cooldown -= state.step
	if frozen or _hit_cooldown > 0.0:
		return
	for i in state.get_contact_count():
		var n := state.get_contact_local_normal(i)
		if n.y > 0.7:
			continue  # ground
		var impact := state.get_contact_impulse(i).length() / mass
		if impact > 5.0:
			_hit_cooldown = 0.6
			crashed.emit(impact, state.get_contact_collider_object(i))
			return


func _update_visuals(delta: float) -> void:
	for i in 4:
		var w := _wheel_nodes[i]
		# The physics wheel has radius wheel_radius; models with bigger or smaller tyres keep
		# their own height and only follow the suspension travel.
		w.position.y = _wheel_base_y[i] + MOUNT_Y - _susp_len[i] - wheel_radius
		if i < 2:
			w.rotation.y = -_steer
	_smoke.emitting = drifting and not frozen
	_flame.emitting = using_nitro and not frozen
	_tail_mat.emission_energy_multiplier = 5.0 if (in_brake > 0.0 or in_handbrake) else 1.5
	if _siren_red:
		var on := fmod(_time * 4.0, 2.0) < 1.0
		_siren_red.emission_energy_multiplier = 6.0 if on else 0.3
		_siren_blue.emission_energy_multiplier = 0.3 if on else 6.0
		_siren_light.light_color = Color(1, 0.1, 0.1) if on else Color(0.15, 0.3, 1)


# ---------- AI ----------

func _steer_towards(target: Vector3, delta: float, after := Vector3.INF) -> float:
	var to := target - global_position
	to.y = 0
	var dist := to.length()
	var fwd := -global_transform.basis.z
	var ang := fwd.signed_angle_to(to.normalized(), Vector3.UP)
	in_steer = clampf(-ang * 2.2, -1.0, 1.0)
	in_throttle = 1.0
	in_brake = 0.0
	in_handbrake = false
	if absf(ang) > 0.45 and speed > 17.0:
		in_throttle = 0.0
		in_brake = 0.7
	# The AI never uses the handbrake: with real tyre physics it spins the car.
	if absf(ang) > 1.0 and speed > 10.0:
		in_throttle = 0.0
		in_brake = 1.0
	in_nitro = absf(ang) < 0.12 and nitro > 0.5 and dist > 60.0
	# Slow down before a corner so the car can make the turn at the intersection.
	if after != Vector3.INF:
		var next := after - target
		next.y = 0
		var turn_ang := absf(to.signed_angle_to(next, Vector3.UP))
		if turn_ang > 0.5:
			var corner_speed := lerpf(22.0, 9.5, clampf((turn_ang - 0.5) / 1.0, 0.0, 1.0))
			var brake_dist := maxf(0.0, (speed * speed - corner_speed * corner_speed) / (2.0 * brake_decel * 0.75)) + 10.0
			if dist < brake_dist + 40.0:
				in_nitro = false
			if dist < brake_dist and speed > corner_speed:
				in_throttle = 0.0
				in_brake = 1.0
	# On winding roads the level knows the corners ahead better than the next point does.
	if city and speed > city.advised_speed(global_position, -global_transform.basis.z):
		in_throttle = 0.0
		in_brake = 1.0
		in_nitro = false
	_handle_stuck(delta)
	return dist


func _handle_stuck(delta: float) -> void:
	if _reverse_t > 0.0:
		_reverse_t -= delta
		in_throttle = 0.0
		in_brake = 1.0
		in_steer = -in_steer
		in_nitro = false
		in_handbrake = false
		return
	if absf(speed) < 1.5 and in_throttle > 0.0:
		_stuck += delta
	else:
		_stuck = 0.0
	if _stuck > 1.2:
		_stuck = 0.0
		_reverse_t = 1.1


func _drive_racer(delta: float) -> void:
	if finished or wp_index >= waypoints.size():
		in_throttle = 0.0
		in_brake = 1.0
		in_steer = 0.0
		in_nitro = false
		return
	var target := waypoints[wp_index]
	var after := waypoints[wp_index + 1] if wp_index + 1 < waypoints.size() else Vector3.INF
	var prev := waypoints[wp_index - 1] if wp_index > 0 else global_position
	var dir := (target - prev).normalized()
	var side := Vector3(-dir.z, 0, dir.x)
	var want := _avoid_traffic(prev, dir, side)
	_dodge = move_toward(_dodge, want, 9.0 * delta)
	_steer_towards(target + side * (lane_offset + _dodge), delta, after)
	if speed > _traffic_limit:
		in_throttle = 0.0
		in_brake = 1.0
		in_nitro = false


## Looks for traffic in the racer's way and returns the sideways shift (from the racing line) that
## takes it through the traffic car's other lane. If that lane is blocked too, sets _traffic_limit
## so the racer slows down behind the traffic car.
func _avoid_traffic(prev: Vector3, dir: Vector3, side: Vector3) -> float:
	_traffic_limit = INF
	var flat_v := Vector3(linear_velocity.x, 0, linear_velocity.z)
	var vdir := flat_v.normalized() if flat_v.length() > 3.0 else -global_transform.basis.z
	var vside := Vector3(-vdir.z, 0, vdir.x)
	var blocker: Node3D
	var blocker_along := INF
	var blocker_speed := 0.0
	for tc in get_tree().get_nodes_in_group("traffic"):
		var rel: Vector3 = tc.global_position - global_position
		var along := rel.dot(vdir)
		if along < 2.0 or along > 120.0:
			continue
		var tc_v: Vector3 = -tc.global_transform.basis.z * tc.speed
		var closing := flat_v.length() - tc_v.dot(vdir)
		# Look further ahead the faster we close in: about three seconds plus a margin.
		if closing <= 0.5 or along > closing * 3.0 + 15.0:
			continue
		# In the way if it is near the line we are driving along, or near the line we are steering to.
		var in_way := absf(rel.dot(vside)) < 2.8 or absf((tc.global_position - prev).dot(side) - (lane_offset + _dodge)) < 2.8
		if in_way and along < blocker_along:
			blocker = tc
			blocker_along = along
			blocker_speed = tc_v.dot(vdir)
	if blocker == null:
		# Ease back to the racing line once the road ahead is clear.
		return 0.0
	# The traffic car's other lane: mirror it across the road centre (it drives `offset` metres to the
	# right of the centre line).
	var b_right := blocker.global_transform.basis.x
	var b_off: float = blocker.get("offset") if blocker.get("offset") != null else 3.0
	if absf(b_off) < 1.0:
		b_off = 3.0 * signf((global_position - blocker.global_position).dot(b_right) + 0.01) * -1.0
	var pass_point := blocker.global_position - b_right * 2.0 * b_off
	for tc in get_tree().get_nodes_in_group("traffic"):
		if tc == blocker:
			continue
		if (tc.global_position - pass_point).length() < 16.0:
			# Both lanes blocked: follow the traffic car until there is room.
			_traffic_limit = maxf(blocker_speed - 1.0, 0.0) + maxf(blocker_along - 12.0, 0.0) * 0.5
			return _dodge
	return (pass_point - prev).dot(side) - lane_offset


func _drive_police(delta: float) -> void:
	if chase_target == null:
		in_throttle = 0.0
		in_brake = 1.0
		return
	var tp := chase_target.global_position
	var aim := tp + chase_target.velocity * 0.4
	var target := city.route_point(global_position, aim)
	var after := city.route_point(target, aim) if target != aim else Vector3.INF
	_steer_towards(target, delta, after)
	# Police ram at full speed when close.
	if global_position.distance_to(tp) < 30.0 and _reverse_t <= 0.0:
		in_brake = 0.0
		in_throttle = 1.0
		in_nitro = nitro > 0.2
