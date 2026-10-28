extends SceneTree
## Physics test bench: drives the Car through fixed scenarios on a flat floor and prints the
## measurements as one JSON line. Run from the project folder:
## godot --headless -s res://tests/physics_bench.gd -- --tps=60

var tps := 60
var car: Car
var t := 0.0
var phase := ""
var results := {}
var start_pos := Vector3.ZERO
var mark_t := 0.0
var max_yaw_rate := 0.0
var prev_yaw := 0.0
var queue: Array[String] = ["accel", "brake", "turn_low", "turn_high", "drift", "nitro", "reverse", "wall", "jump_15", "jump_25"]
var wall: StaticBody3D
var jump_parts: Array[Node] = []
var jump_speed := 0.0
var jump_data := {}
const RAMP_START := -60.0
const RAMP_LENGTH := 16.0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tps="):
			tps = int(a.substr(6))
	Engine.physics_ticks_per_second = tps
	Engine.max_physics_steps_per_frame = 64
	var floor_body := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4000, 1, 4000)
	var col := CollisionShape3D.new()
	col.shape = shape
	floor_body.add_child(col)
	floor_body.position.y = -0.5
	root.add_child(floor_body)
	car = Car.new()
	root.add_child(car)
	car.setup(Car.Driver.PLAYER, Color.RED, null)
	physics_frame.connect(_step)
	_next()


func _reset(speed: float) -> void:
	car.transform = Transform3D(Basis(), Vector3(0, 0.05, 0))
	car.linear_velocity = Vector3(0, 0, -speed)
	car.angular_velocity = Vector3.ZERO
	car.nitro = 1.0
	car.frozen = false
	car.in_throttle = 0.0
	car.in_brake = 0.0
	car.in_steer = 0.0
	car.in_handbrake = false
	car.in_nitro = false
	t = 0.0
	mark_t = -1.0
	max_yaw_rate = 0.0
	prev_yaw = 0.0
	start_pos = car.position


func _next() -> void:
	if queue.is_empty():
		print("RESULT tps=%d %s" % [tps, JSON.stringify(results)])
		quit()
		return
	phase = queue.pop_front()
	match phase:
		"accel", "nitro", "reverse":
			_reset(0.0)
		"brake":
			_reset(40.0)
		"turn_low":
			_reset(12.0)
		"turn_high", "drift":
			_reset(38.0)
		"wall":
			_reset(0.0)
			wall = StaticBody3D.new()
			var s := BoxShape3D.new()
			s.size = Vector3(20, 4, 1)
			var c := CollisionShape3D.new()
			c.shape = s
			wall.add_child(c)
			wall.position = Vector3(0, 2, -150)
			root.add_child(wall)
		"jump_15", "jump_25":
			# Ramp onto a long plateau at the height of the lip, so take-off and landing heights
			# match the textbook range formula d = v^2 sin(2a) / g.
			if wall:
				wall.queue_free()
				wall = null
			for n in jump_parts:
				n.queue_free()
			jump_parts.clear()
			var deg := 15.0 if phase == "jump_15" else 25.0
			jump_speed = 25.0 if phase == "jump_15" else 30.0
			var ramp := Ramp.create(RAMP_LENGTH, 8.0, deg)
			var h := ramp.height()
			ramp.position = Vector3(0, 0, RAMP_START)
			root.add_child(ramp)
			var deck := StaticBody3D.new()
			var s := BoxShape3D.new()
			s.size = Vector3(40, h, 400)
			var c := CollisionShape3D.new()
			c.shape = s
			deck.add_child(c)
			deck.position = Vector3(0, h / 2.0, RAMP_START - RAMP_LENGTH - 200.0)
			root.add_child(deck)
			jump_parts.append_array([ramp, deck])
			jump_data = {"ramp_deg": deg, "ramp_h": h}
			_reset(jump_speed)


func _step() -> void:
	var dt := 1.0 / tps
	t += dt
	var spd := car.speed
	match phase:
		"accel":
			car.in_throttle = 1.0
			if mark_t < 0 and spd * 3.6 >= 100.0:
				mark_t = t
				results["accel_0_100_s"] = snappedf(t, 0.01)
			if t >= 12.0:
				results["top_speed_kmh"] = snappedf(spd * 3.6, 0.1)
				results["dist_12s_m"] = snappedf(start_pos.distance_to(car.global_position), 0.1)
				_next()
		"nitro":
			car.in_throttle = 1.0
			car.in_nitro = true
			if mark_t < 0 and spd * 3.6 >= 100.0:
				mark_t = t
				results["nitro_0_100_s"] = snappedf(t, 0.01)
			if t >= 3.0:
				results["nitro_speed_3s_kmh"] = snappedf(spd * 3.6, 0.1)
				_next()
		"brake":
			car.in_brake = 1.0
			if spd <= 0.5 or t > 10.0:
				results["brake_144kmh_dist_m"] = snappedf(start_pos.distance_to(car.global_position), 0.1)
				results["brake_144kmh_time_s"] = snappedf(t, 0.01)
				_next()
		"turn_low", "turn_high":
			car.in_throttle = 1.0
			car.in_steer = 1.0
			var yaw := car.rotation.y
			if t > dt * 2:
				max_yaw_rate = maxf(max_yaw_rate, absf(angle_difference(prev_yaw, yaw)) / dt)
			prev_yaw = yaw
			if t >= 2.0:
				var v := absf(spd)
				results[phase + "_speed_kmh"] = snappedf(v * 3.6, 0.1)
				results[phase + "_yaw_deg_s"] = snappedf(rad_to_deg(max_yaw_rate), 0.1)
				results[phase + "_radius_m"] = snappedf(v / maxf(max_yaw_rate, 0.001), 0.1)
				results[phase + "_lateral_g"] = snappedf(v * max_yaw_rate / 9.81, 0.01)
				_next()
		"drift":
			# Handbrake turn for 0.6 s, then straighten the wheel and see if the car recovers.
			car.in_throttle = 1.0
			car.in_steer = 1.0 if t < 0.6 else 0.0
			car.in_handbrake = t < 0.6
			var flat := Vector3(car.linear_velocity.x, 0, car.linear_velocity.z)
			var angle := 0.0
			if flat.length() > 3.0:
				angle = rad_to_deg(flat.angle_to(-car.global_transform.basis.z))
			results["drift_max_angle_deg"] = maxf(results.get("drift_max_angle_deg", 0.0), snappedf(angle, 0.1))
			if t > 0.6 and angle < 10.0 and not results.has("drift_recover_s"):
				results["drift_recover_s"] = snappedf(t - 0.6, 0.01)
			if t >= 4.0:
				results["drift_exit_kmh"] = snappedf(car.speed * 3.6, 0.1)
				_next()
		"reverse":
			car.in_brake = 1.0
			if t >= 3.0:
				results["reverse_3s_kmh"] = snappedf(spd * 3.6, 0.1)
				_next()
		"wall":
			car.in_throttle = 1.0
			if mark_t < 0 and car.global_position.z < -146.0:
				mark_t = t
				results["wall_impact_kmh"] = snappedf(prev_yaw * 3.6, 0.1)
			prev_yaw = car.speed
			if mark_t > 0 and t > mark_t + 0.5:
				results["wall_after_0_5s_kmh"] = snappedf(car.speed * 3.6, 0.1)
				results["wall_bounce_z_m"] = snappedf(car.global_position.z + 149.0, 0.01)
				results["wall_yaw_change_deg"] = snappedf(rad_to_deg(car.rotation.y), 0.1)
				_next()
			if t > 15:
				_next()
		"jump_15", "jump_25":
			_jump_step()


func _jump_step() -> void:
	# Hold the approach speed, then let go of the throttle in the air.
	car.in_throttle = 1.0 if car.speed < jump_speed and not car.jumping else 0.0
	var g := float(ProjectSettings.get_setting("physics/3d/default_gravity")) * car.gravity_scale
	if car.jumping and not jump_data.has("v0"):
		var v0: Vector3 = car.takeoff_velocity
		var vh := Vector2(v0.x, v0.z).length()
		jump_data["v0"] = v0
		jump_data["p0"] = car.takeoff_position
		jump_data["launch_deg"] = rad_to_deg(atan2(v0.y, vh))
		jump_data["max_y"] = car.takeoff_position.y
		jump_data["max_pitch"] = 0.0
		jump_data["t0"] = t - Car.JUMP_MIN_AIR
	if car.jumping:
		jump_data["max_y"] = maxf(jump_data["max_y"], car.global_position.y)
		var pitch := rad_to_deg(asin(clampf(-car.global_transform.basis.z.y, -1.0, 1.0)))
		jump_data["max_pitch"] = maxf(jump_data["max_pitch"], absf(pitch))
	elif jump_data.has("v0") and not jump_data.has("air_s"):
		var v0: Vector3 = jump_data["v0"]
		var p0: Vector3 = jump_data["p0"]
		var p1 := car.global_position
		var vh := Vector2(v0.x, v0.z).length()
		var actual := Vector2(p1.x - p0.x, p1.z - p0.z).length()
		# Ballistic flight from the measured take-off state down to the measured landing height.
		var dy := p1.y - p0.y
		var t_flight := (v0.y + sqrt(maxf(v0.y * v0.y - 2.0 * g * dy, 0.0))) / g
		var ballistic := vh * t_flight
		# Textbook range for the take-off speed and the ramp angle (same take-off/landing height).
		var nominal := v0.length_squared() * sin(2.0 * deg_to_rad(jump_data["ramp_deg"])) / g
		var key := phase + "_"
		results[key + "takeoff_kmh"] = snappedf(v0.length() * 3.6, 0.1)
		results[key + "launch_deg"] = snappedf(jump_data["launch_deg"], 0.1)
		results[key + "air_s"] = snappedf(t - jump_data["t0"], 0.01)
		results[key + "dist_m"] = snappedf(actual, 0.1)
		results[key + "ballistic_m"] = snappedf(ballistic, 0.1)
		results[key + "ballistic_err_pct"] = snappedf(100.0 * (actual - ballistic) / ballistic, 0.1)
		results[key + "textbook_m"] = snappedf(nominal, 0.1)
		results[key + "textbook_err_pct"] = snappedf(100.0 * (actual - nominal) / nominal, 0.1)
		results[key + "apex_above_lip_m"] = snappedf(jump_data["max_y"] - jump_data["ramp_h"], 0.1)
		results[key + "max_pitch_deg"] = snappedf(jump_data["max_pitch"], 0.1)
		jump_data["air_s"] = t
		if OS.get_environment("BENCH_DEBUG") != "":
			print(phase, " p0=", p0, " p1=", p1, " v0=", v0)
		jump_data["land_t"] = t
	if jump_data.has("land_t") and t > jump_data["land_t"] + 2.0:
		results[phase + "_upright_2s"] = car.global_transform.basis.y.dot(Vector3.UP) > 0.8
		results[phase + "_speed_2s_kmh"] = snappedf(car.speed * 3.6, 0.1)
		_next()
	if t > 20.0:
		results[phase + "_timeout"] = true
		_next()
