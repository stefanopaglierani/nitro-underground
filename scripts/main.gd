extends Node3D
## Sets up the city, cars, camera and HUD, and runs the race and police rules.
## Modes: "sprint" (race against 3 rivals, police join after a while) and "escape" (lose the police).

static var start_mode := ""

const ROUTE: Array[Vector2i] = [
	Vector2i(0, 6), Vector2i(0, 3), Vector2i(2, 3), Vector2i(2, 0),
	Vector2i(4, 0), Vector2i(4, 4), Vector2i(6, 4), Vector2i(6, 1),
]
const RIVAL_COLORS := [Color(0.1, 0.85, 0.3), Color(1, 0.55, 0.05), Color(0.1, 0.55, 1)]
const CHECKPOINT_RADIUS := 16.0
const AI_ADVANCE_RADIUS := 12.0
const PRIZE := 5000
const ESCAPE_DISTANCE := 110.0
const ESCAPE_TIME := 10.0

var city: City
var hud: Hud
var camera: Camera3D
var player: Car
var racers: Array[Car] = []
var police: Array[Car] = []
var checkpoints: Array[Vector3] = []
var cp_marker: Node3D
var arrow: Node3D
var rng := RandomNumberGenerator.new()

var mode := ""
var state := "menu"  # menu, countdown, race, end
var countdown := 0.0
var race_time := 0.0
var player_cp := 1
var finish_order: Array[Car] = []
var heat := 0.0
var bust_t := 0.0
var escape_t := 0.0
var police_called := false
var cam_yaw := 0.0
var _cam_dist := CAM_DIST
var _cam_ray := PhysicsRayQueryParameters3D.new()
# Chase camera: behind the car and a little above it, looking down the road.
const CAM_DIST := 6.8
const CAM_HEIGHT := 2.5
const CAM_LOOK_AHEAD := 8.0
const CAM_FOV := 68.0
const CAM_FOV_FAST := 84.0
var _orbit := 0.0

var autotest := false
var screenshot_dir := ""
var _test_t := 0.0
var _shots_taken := 0
var _auto_wp := 1
var _auto_goal := Vector3.ZERO


func _ready() -> void:
	rng.seed = Time.get_ticks_usec()
	DisplayServer.screen_set_keep_on(true)
	var args := OS.get_cmdline_user_args()
	autotest = args.has("--autotest")
	if autotest:
		rng.seed = 1234  # same city traffic and rivals on every test run
	for a in args:
		if a.begins_with("--seed="):
			rng.seed = int(a.substr(7))
	for a in args:
		if a.begins_with("--shots="):
			screenshot_dir = a.substr(8)
	if autotest and start_mode == "":
		start_mode = "sprint"
	for a in args:
		if a.begins_with("--mode="):
			start_mode = a.substr(7)

	_setup_input()
	_setup_environment()
	city = City.new()
	add_child(city)
	city.build()
	for i in 16:
		var t := TrafficCar.new()
		add_child(t)
		t.setup(city, rng)

	camera = Camera3D.new()
	camera.fov = CAM_FOV
	camera.near = 0.1
	camera.far = 900
	add_child(camera)

	hud = Hud.new()
	add_child(hud)
	hud.mode_chosen.connect(_on_mode_chosen)
	hud.restart_pressed.connect(func(): _on_mode_chosen(mode))
	hud.menu_pressed.connect(func(): _on_mode_chosen(""))

	for p in ROUTE:
		checkpoints.append(city.node_pos(p))
	_build_markers()

	if start_mode == "":
		hud.show_menu(true)
		state = "menu"
	else:
		_start(start_mode)


func _on_mode_chosen(m: String) -> void:
	start_mode = m
	get_tree().reload_current_scene()


func _setup_input() -> void:
	var keys := {
		"steer_left": [KEY_LEFT, KEY_A],
		"steer_right": [KEY_RIGHT, KEY_D],
		"brake": [KEY_DOWN, KEY_S],
		"handbrake": [KEY_SPACE],
		"nitro": [KEY_SHIFT, KEY_N],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for k in keys[action]:
				var ev := InputEventKey.new()
				ev.physical_keycode = k
				InputMap.action_add_event(action, ev)


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.38, 0.6)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color(0.08, 0.05, 0.15)
	env.fog_density = 0.004
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55, 30, 0)
	moon.light_color = Color(0.6, 0.65, 1)
	moon.light_energy = 0.45
	add_child(moon)


func _build_markers() -> void:
	cp_marker = Node3D.new()
	add_child(cp_marker)
	var ring := TorusMesh.new()
	ring.inner_radius = CHECKPOINT_RADIUS - 1.2
	ring.outer_radius = CHECKPOINT_RADIUS
	ring.rings = 32
	var ring_mi := MeshInstance3D.new()
	ring_mi.mesh = ring
	ring_mi.material_override = CarModel.mat(Color(1, 0.8, 0.1), Color(1, 0.75, 0.1), 3.0)
	ring_mi.position.y = 0.2
	cp_marker.add_child(ring_mi)
	var beam := CylinderMesh.new()
	beam.top_radius = 0.6
	beam.bottom_radius = 0.6
	beam.height = 40
	var beam_mat := CarModel.mat(Color(1, 0.8, 0.1, 0.35), Color(1, 0.75, 0.1), 2.0)
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var beam_mi := MeshInstance3D.new()
	beam_mi.mesh = beam
	beam_mi.material_override = beam_mat
	beam_mi.position.y = 20
	cp_marker.add_child(beam_mi)
	cp_marker.visible = false

	arrow = Node3D.new()
	add_child(arrow)
	var prism := PrismMesh.new()
	prism.size = Vector3(1.8, 2.6, 0.35)
	var arrow_mi := MeshInstance3D.new()
	arrow_mi.mesh = prism
	arrow_mi.material_override = CarModel.mat(Color(1, 0.85, 0.2), Color(1, 0.8, 0.1), 2.5)
	arrow_mi.rotation_degrees.x = -90
	arrow.add_child(arrow_mi)
	arrow.visible = false


func _make_car(kind: Car.Driver, paint: Color) -> Car:
	var c := Car.new()
	add_child(c)
	c.setup(kind, paint, city)
	c.crashed.connect(_on_crash.bind(c))
	return c


func _start(m: String) -> void:
	mode = m
	hud.show_menu(false)
	state = "countdown"
	countdown = 3.5
	if mode == "sprint":
		var start := checkpoints[0]
		var dir := (checkpoints[1] - checkpoints[0]).normalized()
		var side := Vector3(-dir.z, 0, dir.x)
		var slots := [Vector2(-3.5, 22), Vector2(3.5, 22), Vector2(-3.5, 12), Vector2(3.5, 12)]
		for i in 3:
			var r := _make_car(Car.Driver.RACER, RIVAL_COLORS[i])
			var slot: Vector2 = slots[i]
			r.place(start + dir * slot.y + side * slot.x, dir)
			r.waypoints = checkpoints
			r.wp_index = 1
			r.lane_offset = rng.randf_range(-3.0, 3.0)
			r.max_speed = 39.0 + i * 1.2
			racers.append(r)
		player = _make_car(Car.Driver.PLAYER, Color(0.95, 0.1, 0.5))
		var ps: Vector2 = slots[3]
		player.place(start + dir * ps.y + side * ps.x, dir)
		cp_marker.visible = true
		cp_marker.position = checkpoints[1]
		arrow.visible = true
	else:
		player = _make_car(Car.Driver.PLAYER, Color(0.95, 0.1, 0.5))
		player.place(city.node_pos(Vector2i(3, 3)) + Vector3(0, 0, -20), Vector3(0, 0, -1))
		heat = 3.0
		police_called = true
	cam_yaw = player.heading()
	_snap_camera()
	hud.set_heat(heat)


func _process(delta: float) -> void:
	match state:
		"menu":
			_orbit += delta * 0.08
			var c := Vector3(city.extent / 2.0, 0, city.extent / 2.0)
			camera.global_position = c + Vector3(sin(_orbit) * 260, 150, cos(_orbit) * 260)
			camera.look_at(c, Vector3.UP)
			return
		"countdown":
			countdown -= delta
			var n := ceili(countdown - 0.5)
			hud.message_label.text = str(n) if n > 0 else "VIA!"
			hud.message_label.modulate.a = 1.0
			if countdown <= 0.5:
				_go()
		"race":
			race_time += delta
			_race_logic(delta)
	if player:
		_update_camera(delta)
		_update_hud()
	if autotest:
		_autotest_tick(delta)


func _go() -> void:
	state = "race"
	hud.flash("VIA!", 1.0)
	player.frozen = false
	for r in racers:
		r.frozen = false
	if mode == "escape":
		for i in 2:
			_spawn_police(true)
		hud.flash("Semina la polizia!", 3.0)


func _physics_process(_delta: float) -> void:
	if player == null or player.frozen:
		return
	if autotest:
		_autopilot()
		return
	player.in_steer = Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	player.in_brake = Input.get_action_strength("brake")
	player.in_throttle = 0.0 if player.in_brake > 0.0 else 1.0
	player.in_handbrake = Input.is_action_pressed("handbrake")
	player.in_nitro = Input.is_action_pressed("nitro")


func _race_logic(delta: float) -> void:
	if mode == "sprint":
		_checkpoints_logic()
		if not police_called and race_time > 14.0:
			police_called = true
			heat = maxf(heat, 1.0)
			hud.flash("Qualcuno ha chiamato la polizia!", 3.0)
	_police_logic(delta)


func _checkpoints_logic() -> void:
	for r in racers:
		if r.finished:
			continue
		if r.global_position.distance_to(checkpoints[r.wp_index]) < AI_ADVANCE_RADIUS:
			r.wp_index += 1
			if r.wp_index >= checkpoints.size():
				r.finished = true
				finish_order.append(r)
	if player.global_position.distance_to(checkpoints[player_cp]) < CHECKPOINT_RADIUS:
		player_cp += 1
		if player_cp >= checkpoints.size():
			finish_order.append(player)
			var pos := finish_order.find(player) + 1
			var won := pos == 1
			var prize := PRIZE if won else (PRIZE / (pos * 2))
			_end(won, "%d° POSTO" % pos, "Tempo %s\nVincita: %d $" % [_fmt_time(race_time), prize])
			return
		cp_marker.position = checkpoints[player_cp]
		hud.flash("Checkpoint %d/%d" % [player_cp - 1, checkpoints.size() - 1], 1.0)


func _police_logic(delta: float) -> void:
	var wanted := clampi(floori(heat), 0, 3)
	if police.size() < wanted:
		_spawn_police(false)
	var nearest := INF
	for p in police:
		nearest = minf(nearest, p.global_position.distance_to(player.global_position))

	if heat > 0.0 and police.size() > 0:
		if nearest < 8.0 and absf(player.speed) < 3.5:
			bust_t += delta
		else:
			bust_t = maxf(0.0, bust_t - delta * 0.5)
		if bust_t > 3.0:
			var text := "La polizia ti ha preso."
			if mode == "sprint":
				text += "\nNiente vincita stavolta."
			_end(false, "ARRESTATO", text)
			return
		if nearest > ESCAPE_DISTANCE:
			escape_t += delta
		else:
			escape_t = maxf(0.0, escape_t - delta * 2.0)
		if escape_t > ESCAPE_TIME:
			escape_t = 0.0
			heat = 0.0
			for p in police:
				p.queue_free()
			police.clear()
			hud.set_heat(heat)
			if mode == "escape":
				_end(true, "SEMINATI!", "Tempo di fuga %s\nVincita: %d $" % [_fmt_time(race_time), PRIZE / 2])
				return
			hud.flash("Polizia seminata!", 2.5)
	hud.escape_bar.visible = heat > 0.0 and escape_t > 0.0
	hud.escape_bar.value = escape_t / ESCAPE_TIME


func _spawn_police(behind: bool) -> void:
	var p := _make_car(Car.Driver.POLICE, Color.WHITE)
	p.chase_target = player
	if behind:
		_respawn_police(p, true, 35.0, 90.0)
	else:
		_respawn_police(p, false)
	p.frozen = false
	police.append(p)


func _respawn_police(p: Car, behind := true, min_d := 70.0, max_d := 160.0) -> void:
	var fwd := -player.global_transform.basis.z
	var best := Vector2i(-1, -1)
	var best_score := -INF
	for i in City.BLOCKS + 1:
		for j in City.BLOCKS + 1:
			var n := Vector2i(i, j)
			var pos := city.node_pos(n)
			var to := pos - player.global_position
			var d := to.length()
			if d < min_d or d > max_d:
				continue
			var score := -to.normalized().dot(fwd) if behind else rng.randf()
			if score > best_score:
				best_score = score
				best = n
	if best.x < 0:
		best = city.snap(player.global_position + Vector3(90, 0, 0))
	var spawn := city.node_pos(best)
	p.place(spawn, player.global_position - spawn)


func _on_crash(impact: float, other: Object, car: Car) -> void:
	if car != player or state != "race":
		return
	if other is TrafficCar:
		heat = minf(5.0, heat + 0.6)
		hud.flash("Incidente! Sale l'allerta", 2.0)
	elif other is Car and (other as Car).driver == Car.Driver.POLICE:
		heat = minf(5.0, heat + 0.4)
	elif impact > 14.0:
		heat = minf(5.0, heat + 0.25)
	hud.set_heat(heat)


func _end(won: bool, title: String, text: String) -> void:
	state = "end"
	player.frozen = true
	for p in police:
		p.frozen = true
	arrow.visible = false
	hud.escape_bar.visible = false
	hud.show_end(won, title, text)


func _snap_camera() -> void:
	_update_camera(1.0)


func _update_camera(delta: float) -> void:
	var car_pos := player.global_position
	var flat_v := Vector3(player.velocity.x, 0, player.velocity.z)
	# Follow the nose, leaning towards the direction of travel in a drift; hold still when the car
	# is in the air or on its roof so spins and flips stay readable.
	var want := player.heading()
	if flat_v.length() > 8.0 and player.speed > 0.0:
		want = lerp_angle(want, atan2(-flat_v.x, -flat_v.z), 0.35)
	if player.wheels_on_ground > 0 and player.speed > -2.0:
		cam_yaw = lerp_angle(cam_yaw, want, clampf(5.0 * delta, 0.0, 1.0))
	var speed_t := clampf(flat_v.length() / player.max_speed, 0.0, 1.3)
	var back := Basis(Vector3.UP, cam_yaw) * Vector3(0, 0, 1)
	# Pull back a little at speed and with nitro.
	var dist := CAM_DIST + speed_t * 1.6 + (0.8 if player.using_nitro else 0.0)
	var pivot := car_pos + Vector3(0, 1.2, 0)
	var desired := pivot + back * dist + Vector3(0, CAM_HEIGHT - 1.2 + speed_t * 0.4, 0)
	# Keep the camera out of buildings: stop it short of anything between it and the car.
	_cam_ray.from = pivot
	_cam_ray.to = desired
	_cam_ray.exclude = [player.get_rid()]
	var hit := player.get_world_3d().direct_space_state.intersect_ray(_cam_ray)
	var max_dist := pivot.distance_to(desired)
	if not hit.is_empty():
		max_dist = maxf(pivot.distance_to(hit.position) - 0.4, 1.5)
	_cam_dist = minf(lerpf(_cam_dist, max_dist, clampf(4.0 * delta, 0.0, 1.0)), max_dist)
	var cam_pos := pivot + (desired - pivot).normalized() * _cam_dist
	camera.global_position = camera.global_position.lerp(cam_pos, clampf(12.0 * delta, 0.0, 1.0))
	var look := car_pos + Vector3(0, 1.0, 0) - back * CAM_LOOK_AHEAD
	camera.look_at(look, Vector3.UP)
	var fov := lerpf(CAM_FOV, CAM_FOV_FAST, clampf(speed_t, 0.0, 1.0)) + (6.0 if player.using_nitro else 0.0)
	camera.fov = lerpf(camera.fov, fov, clampf(3.0 * delta, 0.0, 1.0))


func _update_hud() -> void:
	hud.speed_label.text = "%d km/h" % roundi(absf(player.speed) * 3.6)
	hud.nitro_bar.value = player.nitro
	var lines := PackedStringArray()
	if mode == "sprint":
		lines.append("POSIZIONE %d/%d" % [_player_position(), racers.size() + 1])
		lines.append("CHECKPOINT %d/%d" % [mini(player_cp - 1, checkpoints.size() - 1), checkpoints.size() - 1])
	lines.append("TEMPO %s" % _fmt_time(race_time))
	hud.info_label.text = "\n".join(lines)
	if arrow.visible and player_cp < checkpoints.size():
		var t := checkpoints[player_cp]
		var to := t - player.global_position
		to.y = 0
		if to.length() > 1.0:
			arrow.global_position = player.global_position + to.normalized() * 9.0 + Vector3(0, 3.4, 0)
			arrow.look_at(arrow.global_position + to, Vector3.UP)


func _player_position() -> int:
	var mine := _progress(player_cp, player)
	var pos := 1
	for r in racers:
		if r.finished and not finish_order.has(player):
			pos += 1
		elif not r.finished and _progress(r.wp_index, r) > mine:
			pos += 1
	return pos


func _progress(cp: int, car: Car) -> float:
	if cp >= checkpoints.size():
		return 1e9
	return cp * 10000.0 - car.global_position.distance_to(checkpoints[cp])


func _fmt_time(t: float) -> String:
	return "%d:%04.1f" % [int(t) / 60, fmod(t, 60.0)]


# ---------- Automated test run (headless or screenshots) ----------

func _autopilot() -> void:
	# Drive the player like a racer, through the checkpoints, to exercise every system.
	var dt := get_physics_process_delta_time()
	if mode == "sprint" and _auto_wp < checkpoints.size():
		if player.global_position.distance_to(checkpoints[_auto_wp]) < AI_ADVANCE_RADIUS and _auto_wp + 1 < checkpoints.size():
			_auto_wp += 1
		var after := checkpoints[_auto_wp + 1] if _auto_wp + 1 < checkpoints.size() else Vector3.INF
		player._steer_towards(checkpoints[_auto_wp], dt, after)
	else:
		if player.global_position.distance_to(_auto_goal) < 20.0:
			_auto_goal = city.node_pos(Vector2i(6, 6)) if _auto_goal.x < 1.0 else city.node_pos(Vector2i(0, 0))
		var goal := _auto_goal
		var target := city.route_point(player.global_position, goal)
		player._steer_towards(target, dt, city.route_point(target, goal))


func _autotest_tick(delta: float) -> void:
	_test_t += delta
	if screenshot_dir != "" and _shots_taken < 6 and _test_t > 1.0 + _shots_taken * 6.0:
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/shot_%s_%d.png" % [screenshot_dir, mode, _shots_taken])
		_shots_taken += 1
	if int(_test_t * 2.0) != int((_test_t - delta) * 2.0):
		print("[autotest] t=%.1f state=%s speed=%.1f cp=%d heat=%.1f police=%d pos=%s wheels=%d up=%.2f in=(%.1f,%.1f,%.1f,%s)" % [_test_t, state, player.speed, player_cp, heat, police.size(), player.global_position.round(), player.wheels_on_ground, player.global_transform.basis.y.y, player.in_throttle, player.in_brake, player.in_steer, player.in_handbrake])
	if int(_test_t / 5.0) != int((_test_t - delta) / 5.0):
		for r in racers:
			print("[autotest]   racer wp=%d speed=%.1f pos=%s up=%.2f" % [r.wp_index, r.speed, r.global_position.round(), r.global_transform.basis.y.y])
	if state == "end" or _test_t > 90.0:
		print("[autotest] END state=%s title=%s text=%s" % [state, hud.end_title.text, hud.end_text.text.replace("\n", " | ")])
		for r in racers:
			print("[autotest] racer wp=%d finished=%s pos=%s" % [r.wp_index, r.finished, r.global_position.round()])
		get_tree().quit()
