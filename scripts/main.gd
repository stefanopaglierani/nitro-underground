class_name Main
extends Node3D
## The race scene: builds the circuit chosen on the title screen (scenes/menu.tscn), loads only
## the cars it needs, then runs the sprint race against 3 rivals (the police join after a while).
## The clock counts down: every checkpoint adds the seconds needed to reach the next one, and the
## race is lost when it gets to zero.
## Levels (circuits): "mountain" (daytime mountain pass, default), "coast" (seaside road),
## "night" (lit-up night city circuit) and the old grid "city" (tests only), see Track.

static var level := "mountain"
## Circuits offered on the title screen: [id, name, short description].
const TRACKS := [
	["mountain", "MONTAGNA", "Passo alpino: tornanti e vette"],
	["coast", "COSTA", "Riviera: lungomare, palme e faro"],
	["night", "CITTÀ DI NOTTE", "Downtown: gomiti tra i palazzi"],
	["desert", "DESERTO", "Route 66: canyon e motel"],
]
## Map file of each circuit (tracks/<name>.txt), drawn on its button in the menu.
const TRACK_MAPS := {"mountain": "montagna", "coast": "costa", "night": "citta_notte", "desert": "deserto"}
## The level object for a circuit id (not built yet).
static func make_level(id: String) -> Track:
	match id:
		"city":
			return City.new()
		"coast":
			return Coast.new()
		"night":
			return NightCity.new()
		"desert":
			return Desert.new()
	return Mountain.new()


const MENU_SCENE := "res://scenes/menu.tscn"
## Countdown clock: seconds given for each checkpoint stretch = its length / CLOCK_SPEED (m/s)
## + CLOCK_EXTRA. Tuned on the autopilot, which needs about 2/3 of the time given; what is left over carries on.
const CLOCK_SPEED := 26.0
const CLOCK_EXTRA := 4.0
## On circuits that know their racing line speeds (Track.drive_time): seconds = ideal time on the
## racing line * CLOCK_SLACK + CLOCK_EXTRA, so a stretch full of hairpins gets more time.
const CLOCK_SLACK := 1.55
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

var state := "loading"  # loading, countdown, race, end
var countdown := 0.0
var race_time := 0.0
## Countdown clock: seconds left to reach the next checkpoint.
var time_left := 0.0
var _clock_times: Array[float] = []  # seconds given for the stretch that ends at checkpoint i
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

var autotest := false
var screenshot_dir := ""
var _test_t := 0.0
var _shots_taken := 0
var _auto_wp := 1


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
		if a.begins_with("--shots="):
			screenshot_dir = a.substr(8)
		if a.begins_with("--level="):
			level = a.substr(8)
		if a.begins_with("--car="):
			Car.player_body = a.substr(6)

	_setup_input()
	hud = Hud.new()
	add_child(hud)
	hud.show_controls(false)
	hud.pause.visible = false
	hud.restart_pressed.connect(_restart)
	hud.menu_pressed.connect(_to_menu)
	camera = Camera3D.new()
	camera.fov = CAM_FOV
	camera.near = 0.1
	add_child(camera)
	# Nothing to see until the level is complete: drawing the half-built world behind the loading
	# page at every step only slows the phone down.
	get_viewport().disable_3d = true

	# Start reading the car models from disk now, in the background, while the level is built.
	var car_paths := _request_car_models()

	# Build the level one step at a time, drawing the loading bar in between.
	city = make_level(level)
	add_child(city)
	var steps := city.build_steps()
	var total := steps.size() + 6.0
	for i in steps.size():
		await _loading(steps[i][0], i / total)
		(steps[i][1] as Callable).call()
	await _loading("Cielo e sole", steps.size() / total)
	city.setup_environment(self)
	ComicStyle.setup_environment(self, city.night)
	ComicStyle.add_stylize_pass(camera)
	camera.far = city.view_distance
	await _loading("Stile fumetto", (steps.size() + 1) / total)
	ComicStyle.install(get_tree())
	await _loading("Traffico", (steps.size() + 2) / total)
	var traffic: Array[TrafficCar] = []
	var grid_front: Vector3 = city.start_grid(1)[0][0]
	for i in (0 if OS.get_cmdline_user_args().has("--notraffic") else TRAFFIC_CARS):
		var t := TrafficCar.new()
		add_child(t)
		t.setup(city, rng)
		t.place_clear(rng, traffic, grid_front)
		traffic.append(t)
	TrafficCar.link_lanes(traffic)
	checkpoints = city.race_checkpoints()
	race_path = city.race_path()
	_build_markers()
	_plan_clock()
	# The car models were loading in the background: wait for the last ones.
	var from := (steps.size() + 3) / total
	var span := 1.0 / total
	while true:
		var done := 0.0
		for path in car_paths:
			var progress := []
			var status := ResourceLoader.load_threaded_get_status(path, progress)
			done += 1.0 if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS else float(progress[0])
		await _loading("Auto", from + span * (done / maxf(car_paths.size(), 1.0)))
		if done >= car_paths.size():
			break
	for path in car_paths:
		ResourceLoader.load_threaded_get(path)
	await _loading("Griglia di partenza", (steps.size() + 4) / total)
	_start()
	# First frames of the finished level, still under the loading page: the phone prepares the
	# shaders, lights and shadows here instead of stuttering at the start of the race.
	await _loading("Luci e ombre", (steps.size() + 5) / total)
	get_viewport().disable_3d = false
	for i in 4:
		await get_tree().process_frame
	await _loading("Pronto", 1.0)
	hud.hide_loading()
	hud.show_race_hud()
	state = "countdown"


## Shows the loading page and waits for it to be drawn before the next (blocking) step.
func _loading(text: String, progress: float) -> void:
	print("[loading] %5d ms  %3d%%  %s" % [Time.get_ticks_msec(), roundi(progress * 100.0), text])
	hud.show_loading(text, progress)
	await get_tree().process_frame
	await get_tree().process_frame


## Starts reading (in background threads) the models of the player's car, the rivals and the
## police. Returns the paths being read.
func _request_car_models() -> Array[String]:
	var paths: Array[String] = []
	for id in [Car.player_body] + Car.RACER_BODIES + Car.POLICE_BODIES:
		var entry := CarCatalog.find(id)
		var path: String = CarModel.RGSDEV_DIR + id + ".fbx" if entry.is_empty() else CarCatalog.model_path(entry)
		if ResourceLoader.exists(path) and not ResourceLoader.has_cached(path) and not paths.has(path):
			paths.append(path)
			ResourceLoader.load_threaded_request(path)
	return paths


## Seconds given for each checkpoint stretch, from its length along the race path.
func _plan_clock() -> void:
	_clock_times.clear()
	_clock_times.append(0.0)
	var wp := 0
	for i in range(1, checkpoints.size()):
		var length := 0.0
		while wp + 1 < race_path.size():
			length += race_path[wp].distance_to(race_path[wp + 1])
			wp += 1
			if race_path[wp].distance_to(checkpoints[i]) < 1.0:
				break
		var ideal := city.drive_time(checkpoints[i - 1], checkpoints[i])
		if ideal > 0.0:
			_clock_times.append(roundf(ideal * CLOCK_SLACK + CLOCK_EXTRA))
		else:
			_clock_times.append(roundf(length / CLOCK_SPEED + CLOCK_EXTRA))


## Same race again: the scene is built anew (with the loading page).
func _restart() -> void:
	hud.show_loading("Riavvio", 0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().reload_current_scene()


## Back to the title screen. The race scene and its models are freed.
func _to_menu() -> void:
	hud.show_loading("Menu", 0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	CarModel.clear_cache()
	get_tree().change_scene_to_file(MENU_SCENE)


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


func _start() -> void:
	countdown = 3.5
	var grid := city.start_grid(4)
	for i in 3:
		var r := _make_car(Car.Driver.RACER, RIVAL_COLORS[i])
		r.place(grid[i][0], grid[i][1])
		r.waypoints = race_path
		r.wp_index = 1
		# Close to the racing line, each a little to one side so they don't all queue on it.
		r.lane_offset = (i - 1) * 1.6 + rng.randf_range(-0.4, 0.4)
		r.max_speed = 57.0 + i * 1.5
		racers.append(r)
	player = _make_car(Car.Driver.PLAYER, Color(0.95, 0.1, 0.5))
	player.place(grid[3][0], grid[3][1])
	cp_marker.visible = true
	cp_marker.position = checkpoints[1]
	time_left = _clock_times[1]
	# The racing line on the road shows the way; the floating arrow only where there is none.
	if city.guide:
		city.guide.visible = true
		cp_beam.visible = false
	else:
		arrow.visible = true
	cam_yaw = player.heading()
	_snap_camera()
	hud.set_heat(heat)


func _process(delta: float) -> void:
	match state:
		"loading":
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
	_checkpoints_logic()
	if state != "race":
		return
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		_end(false, "TEMPO SCADUTO", "Non sei arrivato in tempo %s.\nNiente vincita stavolta." % ("al traguardo" if player_cp == checkpoints.size() - 1 else "al checkpoint %d" % player_cp))
		return
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
		var bonus := _clock_times[player_cp]
		if autotest:
			print("[autotest] CHECKPOINT %d at %.1f s, %.1f s left, +%d s for the next one" % [player_cp - 1, race_time, time_left, bonus])
		time_left += bonus
		hud.flash("Checkpoint %d/%d   +%d s" % [player_cp - 1, checkpoints.size() - 1, bonus], 1.5)
		hud.clock_bonus(bonus)


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
			_end(false, "ARRESTATO", "La polizia ti ha preso.\nNiente vincita stavolta.")
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
		print("[autotest] crash %s impact=%.1f other=%s %s at %s" % ["player" if car == player else str(car.driver), impact, other, (other.get_child(1).name if other is Node and other.get_child_count() > 1 else ""), car.global_position.round()])
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
	var fast := clampf((absf(player.speed) - 24.0) / 18.0, 0.0, 1.0)
	hud.speed_lines.material.set_shader_parameter("amount", 1.0 if player.using_nitro else fast * 0.8)
	hud.dashboard.set_values(absf(player.speed) * 3.6, player.rpm, Car.REDLINE_RPM + 200.0, player.gear, player.nitro, player.using_nitro)
	var lines := PackedStringArray()
	lines.append("POSIZIONE %d/%d" % [_player_position(), racers.size() + 1])
	lines.append("CHECKPOINT %d/%d" % [mini(player_cp - 1, checkpoints.size() - 1), checkpoints.size() - 1])
	lines.append("GARA %s" % _fmt_time(race_time))
	hud.info_label.text = "\n".join(lines)
	hud.set_clock(time_left)
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
	if _auto_wp < race_path.size():
		if player.global_position.distance_to(race_path[_auto_wp]) < AI_ADVANCE_RADIUS and _auto_wp + 1 < race_path.size():
			_auto_wp += 1
		var after := race_path[_auto_wp + 1] if _auto_wp + 1 < race_path.size() else Vector3.INF
		player._steer_towards(race_path[_auto_wp], dt, after)


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
		img.save_png("%s/shot_%s_%d.png" % [screenshot_dir, level, _shots_taken])
		_shots_taken += 1
	if int(_test_t * 2.0) != int((_test_t - delta) * 2.0):
		print("[autotest] t=%.1f state=%s speed=%.1f cp=%d clock=%.1f heat=%.1f police=%d pos=%s wheels=%d up=%.2f in=(%.1f,%.1f,%.1f,%s)" % [_test_t, state, player.speed, player_cp, time_left, heat, police.size(), player.global_position.round(), player.wheels_on_ground, player.global_transform.basis.y.y, player.in_throttle, player.in_brake, player.in_steer, player.in_handbrake])
	if OS.get_cmdline_user_args().has("--ram") and int(_test_t / 4.0) != int((_test_t - delta) / 4.0):
		_ram_traffic()
	if int(_test_t / 5.0) != int((_test_t - delta) / 5.0):
		print("[autotest]   render: %d triangles, %d draw calls, %.0f fps" % [RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), Engine.get_frames_per_second()])
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
