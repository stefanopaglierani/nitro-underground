extends SceneTree
# Car thrown into the air nose-up and spinning, with the brake held: does it land on its wheels?
func _initialize() -> void:
	await process_frame
	for a in ["steer_left", "steer_right", "throttle", "brake", "handbrake", "nitro"]:
		InputMap.add_action(a)
	Input.action_press("brake")
	var floor := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 1, 400)
	cs.shape = box
	cs.position.y = -0.5
	floor.add_child(cs)
	root.add_child(floor)
	var car := Car.new()
	root.add_child(car)
	car.setup(Car.Driver.PLAYER, Color.RED, null)
	car.frozen = false
	car.global_position = Vector3(0, 12, 0)
	car.linear_velocity = Vector3(0, 8, -30)
	car.angular_velocity = Vector3(1.5, 0, 0.6)
	var mn := 1.0
	for i in 240:
		car.in_brake = 1.0
		car.in_throttle = 0.0
		await physics_frame
		mn = minf(mn, car.global_transform.basis.y.y)
		if i % 30 == 0:
			print("t=%.1f y=%.1f up=%.2f wheels=%d" % [i / 60.0, car.global_position.y, car.global_transform.basis.y.y, car.wheels_on_ground])
	print("END up=%.2f min_up=%.2f wheels=%d" % [car.global_transform.basis.y.y, mn, car.wheels_on_ground])
	quit()
