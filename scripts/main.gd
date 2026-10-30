extends Node3D
## Sets up the level, cars, camera and HUD, and runs the race and police rules.
## Modes: "sprint" (race against 3 rivals, police join after a while) and "escape" (lose the police).
## Levels: "mountain" (daytime mountain road, default) and "city" (night city), see Track.

static var start_mode := ""
static var level := "mountain"
## Position of the chosen car in the garage list (kept across scene reloads).
static var car_index := -1
const RIVAL_COLORS := [Color(0.1, 0.85, 0.3), Color(1, 0.55, 0.05), Color(0.1, 0.55, 1)]
const CHECKPOINT_RADIUS := 16.0
const AI_ADVANCE_RADIUS := 12.0
const PRIZE := 5000
const ESCAPE_DISTANCE := 110.0
const ESCAPE_TIME := 10.0
const OFF_TRACK_WARN := 1.0
const OFF_TRACK_LIMIT := 3.0
const OFF_TRACK_TIME := 3.0
const OFF_TRACK_FAR := 45.0

var city: Track
var hud: Hud
var camera: Camera3D
var player: Car
var racers: Array[Car] = []
var police: Array[Car] = []
var checkpoints: Array[Vector3] = []
var race_path: Array[Vector3] = []
var cp_marker: Node3D
var cp_beam: Node3D
var arrow: Node3D
var rng := RandomNumberGenerator.new()

var mode := ""
var _garage: Array = []  # CarCatalog entries available in this build
var _preview: Node3D
var _preview_dist := 8.0
var _swipe := 0.0
var state := "loading"  # loading, menu, countdown, race, end
var countdown := 0.0
var race_time := 0.0
var player_cp := 1
var player_wp := 1  # index in race_path, for the race position
var finish_order: Array[Car] = []
var heat := 0.0
var bust_t := 0.0
var escape_t := 0.0
var police_called := false
var _off_track_t := {}
var _warn_t := 0.0
var cam_yaw := 0.0
var _cam_dist := CAM_DIST
var _cam_y := 0.0
var _cam_ray := PhysicsRayQueryParameters3D.new()
# Chase camera: behind the car and a little above it, looking down the road.
const CAM_DIST := 6.8
const CAM_HEIGHT := 2.5
const CAM_LOOK_AHEAD := 8.0
## Always the same distance and the same field of view: only nitro widens the view a little.
## Civilian cars on the road (they are real rigid bodies, so they can be shoved and wrecked).
const TRAFFIC_CARS := 24
const CAM_FOV := 70.0
const CAM_FOV_NITRO := 76.0
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
		if a.begins_with("--level="):
			level = a.substr(8)
		if a.begins_with("--car="):
			Car.player_body = a.substr(6)

	AnimeStyle.load_setting()
	_setup_input()
	hud = Hud.new()
	add_child(hud)
	hud.show_menu(false)
	hud.show_controls(false)
	hud.pause.visible = false
	hud.mode_chosen.connect(_begin_race)
	hud.restart_pressed.connect(func(): _reload(mode))
	hud.menu_pressed.connect(func(): _reload(""))
	hud.car_step.connect(_step_car)
	hud.style_toggled.connect(func():
		AnimeStyle.next_style()
		_reload(""))
	camera = Camera3D.new()
	camera.fov = CAM_FOV
	camera.near = 0.1
	add_child(camera)

	# Build the level one step at a time, drawing the loading bar in between.
	city = City.new() if level == "city" else Mountain.new()
	add_child(city)
	var steps := city.build_steps()
	var total := steps.size() + 4
	for i in steps.size():
		await _loading(steps[i][0], float(i) / total)
		(steps[i][1] as Callable).call()
	await _loading("Cielo e luce", float(steps.size()) / total)
	city.setup_environment(self)
	if AnimeStyle.enabled:
		AnimeStyle.setup_environment(self)
		AnimeStyle.add_ink_pass(camera)
	AnimeStyle.install(get_tree())
	camera.far = city.view_distance
	await _loading("Traffico", float(steps.size() + 1) / total)
	var traffic: Array[TrafficCar] = []
	for i in TRAFFIC_CARS:
		var t := TrafficCar.new()
		add_child(t)
		t.setup(city, rng)
		t.place_clear(rng, traffic)
		traffic.append(t)
	TrafficCar.link_lanes(traffic)
	checkpoints = city.race_checkpoints()
	race_path = city.race_path()
	_build_markers()

	if start_mode == "":
		await _loading("Garage", float(steps.size() + 2) / total)
		state = "menu"
		_open_garage()
		await _loading("Pronto", 1.0)
		hud.hide_loading()
		hud.show_menu(true)
	else:
		await _begin_race(start_mode, float(steps.size() + 2) / total)


## Shows the loading page and waits for it to be drawn before the next (blocking) step.
func _loading(text: String, progress: float) -> void:
	hud.show_loading(text, progress)
	await get_tree().process_frame
	await get_tree().process_frame


## Loads the cars for a race with the loading bar running (from `from` to 100 %), then starts it.
## The level is already built, so leaving the menu doesn't rebuild it.
func _begin_race(m: String, from := 0.0) -> void:
	if state != "menu" and state != "loading":
		return
	state = "loading"
	hud.show_menu(false)
	hud.show_controls(false)
	hud.pause.visible = false
	if _preview:
		_preview.queue_free()
		_preview = null
	# Read the car models from disk in the background, with the bar following the progress.
	var paths: Array[String] = []
	for id in [Car.player_body] + Car.RACER_BODIES + Car.POLICE_BODIES:
		var entry := CarCatalog.find(id)
		var path: String = CarModel.RGSDEV_DIR + id + ".fbx" if entry.is_empty() else CarCatalog.model_path(entry)
		if ResourceLoader.exists(path) and not ResourceLoader.has_cached(path) and not paths.has(path):
			paths.append(path)
			ResourceLoader.load_threaded_request(path)
	var span := (1.0 - from) * 0.8
	while true:
		var done := 0.0
		for path in paths:
			var progress := []
			var status := ResourceLoader.load_threaded_get_status(path, progress)
			done += 1.0 if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS else float(progress[0])
		await _loading("Auto", from + span * (done / maxf(paths.size(), 1.0)))
		if done >= paths.size():
			break
	for path in paths:
		ResourceLoader.load_threaded_get(path)
	await _loading("Griglia di partenza", from + span)
	_start(m)
	await _loading("Pronto", 1.0)
	hud.hide_loading()
	hud.show_menu(false)


# ---------- Garage (car choice on the title screen) ----------

func _open_garage() -> void:
	_garage = CarCatalog.available()
	if car_index < 0 or car_index >= _garage.size():
		car_index = 0
		for i in _garage.size():
			if _garage[i]["id"] == Car.player_body:
				car_index = i
	_show_car()


func _step_car(dir: int) -> void:
	if state != "menu" or _garage.is_empty():
		return
	car_index = posmod(car_index + dir, _garage.size())
	_show_car()


func _show_car() -> void:
	var entry: Dictionary = _garage[car_index]
	Car.player_body = entry["id"]
	hud.set_car(entry["name"], car_index, _garage.size())
	if _preview:
		_preview.queue_free()
	_preview = CarModel.build(Color(0, 0, 0, 0), entry["id"].contains("police"), entry["id"])
	_preview.set_meta("anime_ink", true)
	add_child(_preview)
	var grid := city.start_grid(1)
	_preview.global_transform = Transform3D(Basis.looking_at(grid[0][1], Vector3.UP), grid[0][0])
	var length := 0.0
	for mi in _preview.find_children("*", "MeshInstance3D", true, false):
		var bb: AABB = CarModel._xf_in(mi, _preview) * (mi as MeshInstance3D).get_aabb()
		length = maxf(length, maxf(absf(bb.position.z), absf(bb.end.z)))
	_preview_dist = clampf(length * 2.6, 6.5, 30.0)


func _unhandled_input(event: InputEvent) -> void:
	if state != "menu":
		return
	var dx := 0.0
	if event is InputEventScreenDrag:
		dx = (event as InputEventScreenDrag).relative.x
	elif event is InputEventMouseMotion and (event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT:
		dx = (event as InputEventMouseMotion).relative.x
	elif event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed:
		_swipe = 0.0
	elif event.is_action_pressed("steer_left"):
		_step_car(-1)
	elif event.is_action_pressed("steer_right"):
		_step_car(1)
	_swipe += dx
	if absf(_swipe) > 90.0:
		_step_car(-1 if _swipe > 0.0 else 1)
		_swipe = 0.0


## Restart or back to the menu: rebuild the scene (the loading page shows while it does).
func _reload(m: String) -> void:
	start_mode = m
	hud.show_loading("Riavvio", 0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().reload_current_scene()


func _setup_input() -> void:
	var keys := {
		"steer_left": [KEY_LEFT, KEY_A],
		"steer_right": [KEY_RIGHT, KEY_D],
		"throttle": [KEY_UP, KEY_W],
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
	cp_beam = beam_mi
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
		var grid := city.start_grid(4)
		for i in 3:
			var r := _make_car(Car.Driver.RACER, RIVAL_COLORS[i])
			r.place(grid[i][0], grid[i][1])
			r.waypoints = race_path
			r.wp_index = 1
			# Close to the racing line, each a little to one side so they don't all queue on it.
			r.lane_offset = (i - 1) * 1.6 + rng.randf_range(-0.4, 0.4)
			r.max_speed = 39.0 + i * 1.2
			racers.append(r)
		player = _make_car(Car.Driver.PLAYER, Color(0.95, 0.1, 0.5))
		player.place(grid[3][0], grid[3][1])
		cp_marker.visible = true
		cp_marker.position = checkpoints[1]
		# The racing line on the road shows the way; the floating arrow only where there is none.
		if city.guide:
			city.guide.visible = true
			cp_beam.visible = false
		else:
			arrow.visible = true
	else:
		player = _make_car(Car.Driver.PLAYER, Color(0.95, 0.1, 0.5))
		var es := city.escape_start()
		player.place(es[0], es[1])
		_auto_goal = city.autopilot_goal(es[0], Vector3.ZERO)
		heat = 3.0
		police_called = true
	cam_yaw = player.heading()
	_snap_camera()
	hud.set_heat(heat)


func _process(delta: float) -> void:
	match state:
		"loading":
			return
		"menu":
			_orbit += delta * 0.08
			if _preview:
				# Slow turn around the chosen car, a little above it.
				var c := _preview.global_position
				var a := _orbit * 3.0
				camera.global_position = c + Vector3(sin(a), 0, cos(a)) * _preview_dist + Vector3(0, _preview_dist * 0.28, 0)
				# Aim below the car so it sits in the clear band between the title and the garage bar.
				camera.look_at(c - Vector3(0, _preview_dist * 0.12, 0), Vector3.UP)
				return
			var view := city.menu_camera(_orbit)
			camera.global_position = view[0]
			camera.look_at(view[1], Vector3.UP)
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
	player.in_throttle = 0.0 if player.in_brake > 0.0 else Input.get_action_strength("throttle")
	player.in_handbrake = Input.is_action_pressed("handbrake")
	player.in_nitro = Input.is_action_pressed("nitro")


func _race_logic(delta: float) -> void:
	_off_track_logic(delta)
	if mode == "sprint":
		_checkpoints_logic()
		if not police_called and race_time > 14.0:
			police_called = true
			heat = maxf(heat, 1.0)
			hud.flash("Qualcuno ha chiamato la polizia!", 3.0)
	_police_logic(delta)


## Keeps every car inside the level: past OFF_TRACK_WARN metres beyond the guardrail the player
## gets a warning, and a car that stays past OFF_TRACK_LIMIT for OFF_TRACK_TIME seconds (or goes
## much further, or falls down the mountain) is put back on the road.
func _off_track_logic(delta: float) -> void:
	for c: Car in [player] + racers:
		var d := city.off_track_distance(c.global_position)
		var t: float = _off_track_t.get(c, 0.0)
		t = t + delta if d > OFF_TRACK_LIMIT else 0.0
		_off_track_t[c] = t
		if c == player and d > OFF_TRACK_WARN and t == 0.0:
			if _warn_t <= 0.0:
				hud.flash("Torna in pista!", 1.0)
				_warn_t = 1.0
		if t > OFF_TRACK_TIME or d > OFF_TRACK_FAR:
			_off_track_t[c] = 0.0
			var spot := city.recovery_point(c.global_position)
			var facing: Vector3 = spot[1]
			if c.driver != Car.Driver.RACER and facing.dot(-c.global_transform.basis.z) < 0.0:
				facing = -facing
			c.place(spot[0], facing)
			if c == player:
				hud.flash("Rientro in pista", 1.5)
				cam_yaw = player.heading()
				_snap_camera()
	_warn_t -= delta


func _checkpoints_logic() -> void:
	for r in racers:
		if r.finished:
			continue
		var d := r.global_position.distance_to(race_path[r.wp_index])
		# Also move on if the racer went past the point without touching it.
		var passed := d < 40.0 and r.wp_index + 1 < race_path.size() and r.global_position.distance_to(race_path[r.wp_index + 1]) < race_path[r.wp_index].distance_to(race_path[r.wp_index + 1])
		if d < AI_ADVANCE_RADIUS or passed:
			r.wp_index += 1
			if r.wp_index >= race_path.size():
				r.finished = true
				finish_order.append(r)
	if player_wp < race_path.size() - 1 and player.global_position.distance_to(race_path[player_wp]) < CHECKPOINT_RADIUS:
		player_wp += 1
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
	var spot := city.police_spawn(player.global_position, fwd, behind, min_d, max_d, rng)
	p.place(spot[0], spot[1])


func _on_crash(impact: float, other: Object, car: Car) -> void:
	if autotest:
		print("[autotest] crash %s impact=%.1f other=%s at %s" % ["player" if car == player else str(car.driver), impact, other, car.global_position.round()])
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
	var back := Basis(Vector3.UP, cam_yaw) * Vector3(0, 0, 1)
	# Only the height is smoothed, so bumps in the road don't shake the picture.
	_cam_y = car_pos.y if delta >= 1.0 else lerpf(_cam_y, car_pos.y, clampf(10.0 * delta, 0.0, 1.0))
	var pivot := Vector3(car_pos.x, _cam_y + 1.2, car_pos.z)
	var desired := pivot + back * CAM_DIST + Vector3(0, CAM_HEIGHT - 1.2, 0)
	# Keep the camera out of buildings: stop it short of anything between it and the car.
	_cam_ray.from = pivot
	_cam_ray.to = desired
	_cam_ray.exclude = [player.get_rid()]
	var hit := player.get_world_3d().direct_space_state.intersect_ray(_cam_ray)
	var max_dist := pivot.distance_to(desired)
	if not hit.is_empty():
		max_dist = maxf(pivot.distance_to(hit.position) - 0.4, 1.5)
	_cam_dist = minf(lerpf(_cam_dist, max_dist, clampf(4.0 * delta, 0.0, 1.0)), max_dist)
	# Placed straight from the car's position every frame (only the angle is smoothed), so the
	# camera never lags further behind as the speed grows.
	camera.global_position = pivot + (desired - pivot).normalized() * _cam_dist
	var look := car_pos + Vector3(0, 1.0, 0) - back * CAM_LOOK_AHEAD
	camera.look_at(look, Vector3.UP)
	var fov := CAM_FOV_NITRO if player.using_nitro else CAM_FOV
	camera.fov = lerpf(camera.fov, fov, clampf(3.0 * delta, 0.0, 1.0))


func _update_hud() -> void:
	if hud.speed_lines:
		var fast := clampf((absf(player.speed) - 24.0) / 18.0, 0.0, 1.0)
		hud.speed_lines.material.set_shader_parameter("amount", 1.0 if player.using_nitro else fast * 0.8)
	hud.dashboard.set_values(absf(player.speed) * 3.6, player.rpm, Car.REDLINE_RPM + 200.0, player.gear, player.nitro, player.using_nitro)
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
	var mine := _progress(player_wp if not finish_order.has(player) else race_path.size(), player)
	var pos := 1
	for r in racers:
		if r.finished and not finish_order.has(player):
			pos += 1
		elif not r.finished and _progress(r.wp_index, r) > mine:
			pos += 1
	return pos


func _progress(wp: int, car: Car) -> float:
	if wp >= race_path.size():
		return 1e9
	return wp * 10000.0 - car.global_position.distance_to(race_path[wp])


func _fmt_time(t: float) -> String:
	return "%d:%04.1f" % [int(t) / 60, fmod(t, 60.0)]


# ---------- Automated test run (headless or screenshots) ----------

func _autopilot() -> void:
	# Drive the player like a racer, through the checkpoints, to exercise every system.
	var dt := get_physics_process_delta_time()
	if mode == "sprint" and _auto_wp < race_path.size():
		if player.global_position.distance_to(race_path[_auto_wp]) < AI_ADVANCE_RADIUS and _auto_wp + 1 < race_path.size():
			_auto_wp += 1
		var after := race_path[_auto_wp + 1] if _auto_wp + 1 < race_path.size() else Vector3.INF
		player._steer_towards(race_path[_auto_wp], dt, after)
	else:
		if player.global_position.distance_to(_auto_goal) < 20.0:
			_auto_goal = city.autopilot_goal(player.global_position, _auto_goal)
		var goal := _auto_goal
		var target := city.route_point(player.global_position, goal)
		player._steer_towards(target, dt, city.route_point(target, goal))


## Test of the crash physics (--ram): throws the player sideways into the nearest driving
## traffic car at 25 m/s and prints how both move off.
func _ram_traffic() -> void:
	var best: TrafficCar
	for tc: TrafficCar in get_tree().get_nodes_in_group("traffic"):
		if not tc.crashed and (best == null or tc.global_position.distance_to(player.global_position) < best.global_position.distance_to(player.global_position)):
			best = tc
	if best == null:
		return
	var side := best.global_transform.basis.x
	# Traffic keeps right, so the open road is on its left.
	player.place(best.global_position - side * 9.0, side)
	player.linear_velocity = side * 25.0
	print("[autotest] RAM traffic at %s mass=%.0f" % [best.global_position.round(), best.mass])
	await get_tree().create_timer(0.6).timeout
	print("[autotest] RAM after 0.6s: traffic v=%.1f crashed=%s up=%.2f | player v=%.1f up=%.2f" % [best.linear_velocity.length(), best.crashed, best.global_transform.basis.y.y, player.linear_velocity.length(), player.global_transform.basis.y.y])


func _autotest_tick(delta: float) -> void:
	_test_t += delta
	if screenshot_dir != "" and _shots_taken < 6 and _test_t > 1.0 + _shots_taken * 6.0:
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/shot_%s_%d.png" % [screenshot_dir, mode, _shots_taken])
		_shots_taken += 1
	if int(_test_t * 2.0) != int((_test_t - delta) * 2.0):
		print("[autotest] t=%.1f state=%s speed=%.1f cp=%d heat=%.1f police=%d pos=%s wheels=%d up=%.2f in=(%.1f,%.1f,%.1f,%s)" % [_test_t, state, player.speed, player_cp, heat, police.size(), player.global_position.round(), player.wheels_on_ground, player.global_transform.basis.y.y, player.in_throttle, player.in_brake, player.in_steer, player.in_handbrake])
	if OS.get_cmdline_user_args().has("--ram") and int(_test_t / 4.0) != int((_test_t - delta) / 4.0):
		_ram_traffic()
	if int(_test_t / 5.0) != int((_test_t - delta) / 5.0):
		var wrecks := 0
		for tc: TrafficCar in get_tree().get_nodes_in_group("traffic"):
			wrecks += 1 if tc.crashed else 0
		print("[autotest]   traffic %d cars, %d wrecked" % [get_tree().get_nodes_in_group("traffic").size(), wrecks])
		for r in racers:
			print("[autotest]   racer wp=%d speed=%.1f pos=%s up=%.2f" % [r.wp_index, r.speed, r.global_position.round(), r.global_transform.basis.y.y])
	if state == "end" or _test_t > 150.0:
		print("[autotest] END state=%s title=%s text=%s" % [state, hud.end_title.text, hud.end_text.text.replace("\n", " | ")])
		for r in racers:
			print("[autotest] racer wp=%d finished=%s pos=%s" % [r.wp_index, r.finished, r.global_position.round()])
		get_tree().quit()
