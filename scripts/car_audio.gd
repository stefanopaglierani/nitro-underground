class_name CarAudio
extends Node3D
## Sounds of one car, driven by what the car is doing: engine revs and throttle, gear changes,
## turbo blow-off and exhaust pops on lift-off, tyres squealing under braking, drifts and the
## handbrake, nitro, wind, crashes, landings and the police siren.
## The engine is a set of seamless loops recorded at ENGINE_RPM, each in two versions: on load
## (throttle open) and off load (throttle closed). Every frame the two loops nearest to the revs
## are crossfaded and pitched to the exact revs, and the on/off versions are blended with the
## throttle. The player hears its own car from the middle of the screen; the other cars are 3D
## sounds placed on the car. Files and how they were made: assets/LICENSES.md.

const DIR := "res://assets/audio/"
const ENGINE_RPM := [1000.0, 2000.0, 3200.0, 4500.0, 6000.0, 7600.0]
## Other cars go silent past this distance from the camera, to save mixing on the phone.
const HEAR_DISTANCE := 140.0

static var _streams := {}

var car: Car
var is_player := false

var _on: Array[Node] = []
var _off: Array[Node] = []
var _wind: Node
var _tyres: Node
var _nitro: Node
var _siren: Node
var _rpm := Car.IDLE_RPM
var _load := 0.0
var _gear := 0
var _throttle_was := 0.0
var _handbrake_was := false
var _blowoff_cd := 0.0
var _pops_left := 0
var _pop_t := 0.0
var _start_t := -1.0
var _engine_gain := 0.0
var _squeal := 0.0
var _nitro_vol := 0.0
var _shift_dip := 0.0


func setup(the_car: Car) -> void:
	car = the_car
	_add_limiter()
	is_player = car.driver == Car.Driver.PLAYER
	for r in ENGINE_RPM:
		_on.append(_make_loop("engine_on_%d.wav" % r))
		_off.append(_make_loop("engine_off_%d.wav" % r))
	_tyres = _make_loop("tyre_squeal.wav")
	if is_player:
		_wind = _make_loop("wind.wav")
		_nitro = _make_loop("nitro_loop.wav")
		# Starter motor, then the engine catches and flares the revs (see _engine_rpm).
		_start_t = 0.0
		_shot("starter.wav", -6.0)
	if car.driver == Car.Driver.POLICE:
		_siren = _make_loop("siren.wav", true)
		_siren.volume_db = -9.0
		_siren.play()
	car.crashed.connect(_on_crash)
	car.landed.connect(_on_landed)


## One-off sound at a place in the world (a guardrail breaking, for example).
static func play_at(parent: Node, pos: Vector3, file: String, db := 0.0, pitch := 1.0) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = _stream(file)
	p.volume_db = db
	p.pitch_scale = pitch
	p.unit_size = 12.0
	p.max_distance = HEAR_DISTANCE
	parent.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()


## A limiter on the master bus, so a big crash on top of a screaming engine never clips.
static func _add_limiter() -> void:
	for i in AudioServer.get_bus_effect_count(0):
		if AudioServer.get_bus_effect(0, i) is AudioEffectHardLimiter:
			return
	var lim := AudioEffectHardLimiter.new()
	lim.pre_gain_db = -1.0
	lim.ceiling_db = -0.5
	AudioServer.add_bus_effect(0, lim)


static func _stream(file: String) -> AudioStream:
	if not _streams.has(file):
		_streams[file] = load(DIR + file)
	return _streams[file]


func _make_loop(file: String, autoplay := false) -> Node:
	var p := _new_player()
	p.stream = _stream(file)
	p.volume_db = -80.0
	add_child(p)
	if autoplay:
		p.play()
	return p


func _new_player() -> Node:
	if is_player:
		return AudioStreamPlayer.new()
	var p := AudioStreamPlayer3D.new()
	p.unit_size = 9.0
	p.max_distance = HEAR_DISTANCE
	return p


func _shot(file: String, db: float, pitch := 1.0) -> void:
	var p := _new_player()
	p.stream = _stream(file)
	p.volume_db = db
	p.pitch_scale = pitch
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


## Sets a looping player's level (0..1) and pitch; it stops mixing while silent.
func _level(p: Node, gain: float, pitch := 1.0) -> void:
	if gain < 0.002:
		if p.playing:
			p.stop()
		return
	p.volume_db = linear_to_db(gain)
	p.pitch_scale = clampf(pitch, 0.3, 3.0)
	if not p.playing:
		# Start each loop at a random point so layers that come in together don't phase.
		var length: float = p.stream.get_length()
		p.play(randf() * length * 0.9)


func _process(delta: float) -> void:
	if car == null:
		return
	if not is_player:
		var cam := get_viewport().get_camera_3d()
		if cam and cam.global_position.distance_to(global_position) > HEAR_DISTANCE:
			_silence()
			return
	var throttle := car.in_throttle
	if is_player and car.frozen:
		# On the grid the car can't move, but the engine revs with the pedal.
		throttle = Input.get_action_strength("throttle")
	_engine(delta, throttle)
	_gearbox_and_lift_off(delta, throttle)
	_tyre_noise(delta)
	if is_player:
		var spd := absf(car.speed)
		var w := clampf(spd / 45.0, 0.0, 1.3)
		_level(_wind, 0.38 * w * w, 0.75 + 0.4 * w)
		_nitro_vol = move_toward(_nitro_vol, 1.0 if car.using_nitro else 0.0, delta * (6.0 if car.using_nitro else 3.0))
		_level(_nitro, 0.45 * _nitro_vol, 0.9 + 0.2 * _nitro_vol)
	_handbrake_was = car.in_handbrake
	_throttle_was = throttle


func _silence() -> void:
	for p in _on + _off + [_tyres]:
		_level(p, 0.0)


func _engine_rpm(delta: float, throttle: float) -> float:
	if _start_t >= 0.0:
		# Engine start: cranking, then it catches and flares to about 2500 before settling.
		_start_t += delta
		if _start_t < 0.6:
			_engine_gain = 0.0
			return Car.IDLE_RPM
		var t := _start_t - 0.6
		_engine_gain = minf(1.0, t * 6.0)
		if t > 1.2:
			_start_t = -1.0
		return Car.IDLE_RPM + 1600.0 * sin(clampf(t / 1.2, 0.0, 1.0) * PI) * exp(-t * 1.5) * 2.0
	_engine_gain = 1.0
	if car.frozen:
		# Free revving in neutral: quick to rise, slower to fall, like a light flywheel.
		var want := Car.IDLE_RPM + (Car.REDLINE_RPM - Car.IDLE_RPM) * 0.85 * throttle
		return move_toward(_rpm, want, delta * (9000.0 if want > _rpm else 5000.0))
	return car.rpm


func _engine(delta: float, throttle: float) -> void:
	_rpm = _engine_rpm(delta, throttle)
	# A hint of rough idle, so a stopped engine doesn't sound like a tone generator.
	var r := _rpm + (sin(Time.get_ticks_msec() * 0.0071) * 25.0 if _rpm < 1200.0 else 0.0)
	var load_want := clampf(throttle, 0.0, 1.0)
	if car.using_nitro:
		load_want = 1.0
	_shift_dip -= delta
	if _shift_dip > 0.0:
		load_want = 0.15  # the clutch is in for the shift
	_load = move_toward(_load, load_want, delta * (7.0 if load_want > _load else 4.0))
	# Pick the two recordings either side of the revs.
	var n := ENGINE_RPM.size()
	var k := 0
	while k < n - 2 and r > ENGINE_RPM[k + 1]:
		k += 1
	var x := clampf((r - ENGINE_RPM[k]) / (ENGINE_RPM[k + 1] - ENGINE_RPM[k]), 0.0, 1.0)
	# Louder with revs and with the throttle open.
	var rev_t := clampf((r - Car.IDLE_RPM) / (Car.REDLINE_RPM - Car.IDLE_RPM), 0.0, 1.0)
	var base := (0.5 + 0.5 * rev_t) * _engine_gain * (0.85 if is_player else 1.0)
	var on_gain := base * _load * (0.35 + 0.65 * _load)
	var off_gain := base * 0.75 * (1.0 - _load)
	for i in n:
		var w := 0.0
		if i == k:
			w = cos(x * PI * 0.5)
		elif i == k + 1:
			w = sin(x * PI * 0.5)
		var pitch: float = r / ENGINE_RPM[i]
		_level(_on[i], w * on_gain, pitch)
		_level(_off[i], w * off_gain, pitch)


func _gearbox_and_lift_off(delta: float, throttle: float) -> void:
	_blowoff_cd -= delta
	if car.gear != _gear:
		if car.gear > _gear and _gear >= 1 and not car.frozen:
			_shift_dip = Car.SHIFT_TIME + 0.05
			if is_player:
				_shot("gear_%d.wav" % (1 + randi() % 2), -14.0, randf_range(0.95, 1.05))
			if _rpm > 4500.0 and _blowoff_cd <= 0.0:
				_blowoff()
		_gear = car.gear
	# Snapping off the throttle at high revs: turbo blow-off, then a few exhaust pops.
	if _throttle_was > 0.6 and throttle < 0.1 and _rpm > 4000.0:
		if _blowoff_cd <= 0.0:
			_blowoff()
		_pops_left = randi_range(2, 4) if _rpm > 5000.0 else 1
		_pop_t = randf_range(0.08, 0.2)
	if _pops_left > 0:
		_pop_t -= delta
		if throttle > 0.3:
			_pops_left = 0
		elif _pop_t <= 0.0:
			_pops_left -= 1
			_pop_t = randf_range(0.07, 0.22)
			_shot("pop_%d.wav" % (randi() % 3), (-10.0 if is_player else -6.0) + randf_range(-3.0, 1.0), randf_range(0.85, 1.2))


func _blowoff() -> void:
	_blowoff_cd = 0.8
	_shot("blowoff.wav", -9.0 if is_player else -6.0, randf_range(0.92, 1.08))


func _tyre_noise(delta: float) -> void:
	var want := 0.0
	var pitch := 1.0
	var spd := absf(car.speed)
	if car.wheels_on_ground >= 2 and not car.frozen:
		# Sliding sideways: drifts and spins.
		var slide := clampf((absf(car.lateral) - 3.0) / 9.0, 0.0, 1.0)
		if slide > 0.0:
			want = slide
			pitch = 0.95 + 0.15 * slide
		# Hard braking at speed.
		if car.in_brake > 0.3 and car.speed > 9.0:
			var b := car.in_brake * clampf((spd - 9.0) / 20.0, 0.0, 1.0) * 0.8
			if b > want:
				want = b
				pitch = 0.85 + 0.1 * b
		# Handbrake: rear wheels lock.
		if car.in_handbrake and spd > 5.0:
			var h := clampf(spd / 25.0, 0.3, 0.9)
			if h > want:
				want = h
				pitch = 0.9
		# Launch from standstill with the pedal down: wheelspin.
		if car.in_throttle > 0.9 and car.gear == 1 and spd < 7.0 and spd > 0.3:
			want = maxf(want, 0.35 * (1.0 - spd / 7.0))
	_squeal = move_toward(_squeal, want, delta * (5.0 if want > _squeal else 3.0))
	_level(_tyres, 0.6 * _squeal, pitch)
	if is_player and car.in_handbrake and not _handbrake_was:
		_shot("handbrake.wav", -12.0)


func _on_crash(impact: float, _other: Object) -> void:
	# impact is the change of speed in m/s: 5 is a knock, 15 or more a big crash.
	var t := clampf((impact - 5.0) / 15.0, 0.0, 1.0)
	var db := lerpf(-10.0, 0.0, t) + (0.0 if is_player else 2.0)
	var pitch := randf_range(0.9, 1.1)
	if impact < 8.0:
		_shot("crash_light.wav", db - 2.0, pitch)
		_shot("crash_metal.wav", db - 10.0, pitch * 1.2)
	elif impact < 14.0:
		_shot("crash_medium.wav", db, pitch)
		_shot("crash_metal.wav", db - 6.0, pitch)
	else:
		_shot("crash_heavy.wav", db, pitch)
		_shot("crash_medium.wav", db - 4.0, pitch * 0.9)


func _on_landed(air_time: float, impact_speed: float) -> void:
	if impact_speed < 2.5 and air_time < 0.4:
		return
	var t := clampf((impact_speed - 2.5) / 10.0, 0.0, 1.0)
	_shot("land_thud.wav", lerpf(-14.0, -1.0, t), randf_range(0.9, 1.05))
	if impact_speed > 9.0:
		_shot("crash_light.wav", -10.0, 0.8)
