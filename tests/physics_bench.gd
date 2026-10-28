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
var queue: Array[String] = ["accel", "brake", "turn_low", "turn_high", "drift", "nitro", "reverse", "wall"]
var wall: StaticBody3D


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
	car.global_transform = Transform3D(Basis(), Vector3(0, 0.05, 0))
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
	start_pos = car.global_position


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
