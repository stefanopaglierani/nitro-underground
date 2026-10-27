class_name Car
extends CharacterBody3D
## Arcade car shared by the player, the AI racers and the police.
## Each frame a controller fills the in_* inputs; _physics_process turns them into motion.

signal crashed(impact: float, other: Object)

enum Driver { PLAYER, RACER, POLICE }

var driver: Driver = Driver.PLAYER
var frozen := true

# Tuning (metres and seconds). 42 m/s is about 150 km/h.
var max_speed := 42.0
var accel := 15.0
var brake_decel := 32.0
var reverse_max := 10.0
var turn_speed := 2.5
var grip := 7.0
var drift_grip := 1.1
var nitro_mult := 1.4

var nitro := 1.0
var nitro_drain := 0.35
var nitro_refill := 0.05

# Inputs, -1..1 or 0..1.
var in_throttle := 0.0
var in_brake := 0.0
var in_steer := 0.0
var in_handbrake := false
var in_nitro := false

var speed := 0.0
var lateral := 0.0
var drifting := false
var using_nitro := false

# AI state
var city: City
var waypoints: Array[Vector3] = []
var wp_index := 0
var lane_offset := 0.0
var chase_target: Car
var finished := false
var _stuck := 0.0
var _reverse_t := 0.0

var _model: Node3D
var _body: Node3D
var _wheel_fl: Node3D
var _wheel_fr: Node3D
var _smoke: CPUParticles3D
var _flame: CPUParticles3D
var _tail_mat: StandardMaterial3D
var _siren_red: StandardMaterial3D
var _siren_blue: StandardMaterial3D
var _siren_light: OmniLight3D
var _hit_cooldown := 0.0
var _time := 0.0


func setup(kind: Driver, paint: Color, the_city: City) -> void:
	driver = kind
	city = the_city
	floor_max_angle = deg_to_rad(50)
	safe_margin = 0.02
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.9, 1.0, 4.2)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 0.6
	add_child(col)

	_model = CarModel.build(paint, kind == Driver.POLICE)
	add_child(_model)
	_body = _model.get_node("Body")
	_wheel_fl = _model.get_node("WheelFL")
	_wheel_fr = _model.get_node("WheelFR")
	_tail_mat = _model.get_meta("tail_mat")

	_smoke = _make_particles(Color(0.75, 0.75, 0.8, 0.35), Vector3(0, 0.3, 1.6), 0.9, 48)
	_smoke.direction = Vector3(0, 1, 0.3)
	_smoke.initial_velocity_min = 1.0
	_smoke.initial_velocity_max = 2.5
	_smoke.scale_amount_min = 0.6
	_smoke.scale_amount_max = 1.4
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
			accel = 16.0
			_siren_red = _model.get_meta("siren_red")
			_siren_blue = _model.get_meta("siren_blue")
			_siren_light = OmniLight3D.new()
			_siren_light.position = Vector3(0, 2.2, 0)
			_siren_light.omni_range = 12
			_siren_light.light_energy = 3.0
			add_child(_siren_light)


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
	global_position = pos
	look_at(pos + Vector3(facing.x, 0, facing.z), Vector3.UP)
	velocity = Vector3.ZERO


func _physics_process(delta: float) -> void:
	_time += delta
	if frozen:
		velocity = Vector3.ZERO
		_update_visuals(delta)
		return
	match driver:
		Driver.RACER:
			_drive_racer(delta)
		Driver.POLICE:
			_drive_police(delta)

	var fwd := -global_transform.basis.z
	var flat_v := Vector3(velocity.x, 0, velocity.z)
	var vf_now := flat_v.dot(fwd)

	# Steering: no turning when stopped, slightly less at top speed, more with the handbrake.
	var steer_factor := clampf(absf(vf_now) / 6.0, 0.0, 1.0)
	var high_speed := lerpf(1.0, 0.65, clampf(absf(vf_now) / max_speed, 0.0, 1.0))
	var turn := in_steer * turn_speed * steer_factor * high_speed * (1.55 if in_handbrake else 1.0)
	if vf_now < -0.5:
		turn = -turn
	rotate_y(-turn * delta)

	fwd = -global_transform.basis.z
	var right := global_transform.basis.x
	var vf := flat_v.dot(fwd)
	var vr := flat_v.dot(right)

	using_nitro = in_nitro and nitro > 0.02 and in_throttle > 0.1
	var top := max_speed * (nitro_mult if using_nitro else 1.0)
	var acc := accel * (1.9 if using_nitro else 1.0)
	if in_throttle > 0.0 and vf < top:
		vf += acc * in_throttle * delta * (1.0 - 0.55 * clampf(vf / top, 0.0, 1.0))
	if in_brake > 0.0:
		if vf > 0.5:
			vf -= brake_decel * in_brake * delta
		else:
			vf = maxf(vf - accel * 0.6 * in_brake * delta, -reverse_max)
	if in_handbrake:
		vf = move_toward(vf, 0.0, 5.0 * delta)
	if in_throttle == 0.0 and in_brake == 0.0:
		vf = move_toward(vf, 0.0, 4.0 * delta)
	if vf > top:
		vf = move_toward(vf, top, 18.0 * delta)

	var g := drift_grip if in_handbrake else grip
	vr = lerpf(vr, 0.0, clampf(g * delta, 0.0, 1.0))
	drifting = absf(vr) > 3.5 and absf(vf) > 8.0

	if using_nitro:
		nitro = maxf(0.0, nitro - nitro_drain * delta)
	else:
		nitro = minf(1.0, nitro + nitro_refill * delta + (0.15 * delta if drifting else 0.0))

	flat_v = fwd * vf + right * vr
	velocity.x = flat_v.x
	velocity.z = flat_v.z
	velocity.y = -1.0 if is_on_floor() else velocity.y - 25.0 * delta
	move_and_slide()
	speed = vf
	lateral = vr

	_hit_cooldown -= delta
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var n := c.get_normal()
		if absf(n.y) > 0.7:
			continue
		var impact := -flat_v.dot(n)
		if impact > 5.0 and _hit_cooldown <= 0.0:
			_hit_cooldown = 0.6
			velocity.x *= 0.7
			velocity.z *= 0.7
			crashed.emit(impact, c.get_collider())
	_update_visuals(delta)


func _update_visuals(delta: float) -> void:
	var steer_angle := -in_steer * 0.45
	_wheel_fl.rotation.y = lerpf(_wheel_fl.rotation.y, steer_angle, 10.0 * delta)
	_wheel_fr.rotation.y = _wheel_fl.rotation.y
	_body.rotation.z = lerpf(_body.rotation.z, clampf(lateral * 0.012, -0.08, 0.08), 6.0 * delta)
	_body.rotation.x = lerpf(_body.rotation.x, -0.03 if in_brake > 0.0 else 0.0, 6.0 * delta)
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
	if absf(ang) > 1.0 and speed > 10.0:
		in_handbrake = true
	in_nitro = absf(ang) < 0.12 and nitro > 0.5 and dist > 60.0
	# Slow down before a corner so the car can make the turn at the intersection.
	if after != Vector3.INF:
		var next := after - target
		next.y = 0
		var turn_ang := absf(to.signed_angle_to(next, Vector3.UP))
		if turn_ang > 0.5:
			var corner_speed := lerpf(24.0, 11.0, clampf((turn_ang - 0.5) / 1.0, 0.0, 1.0))
			var brake_dist := maxf(0.0, (speed * speed - corner_speed * corner_speed) / (2.0 * brake_decel * 0.75)) + 10.0
			if dist < brake_dist + 40.0:
				in_nitro = false
			if dist < brake_dist and speed > corner_speed:
				in_throttle = 0.0
				in_brake = 1.0
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
	_steer_towards(target + side * lane_offset, delta, after)


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
