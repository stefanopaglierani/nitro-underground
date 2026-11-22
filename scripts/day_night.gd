class_name DayNight
extends Node
## Day and night cycle of the cinematic look (Stefano 22/11/2026): the sun goes round the world,
## then the moon; sky, clouds, stars, light, shadows, fog and colours change smoothly with it.
## Cheap: a few values are recomputed 4 times a second, nothing is rebuilt.
## Created by CinematicLook (start option --look=cinema). Test aid: --hour=H starts at hour H.

## Real minutes for 24 hours of game time. THE ONE PLACE TO CHANGE THE LENGTH OF THE DAY.
const DAY_MINUTES := 20.0
## Hour at the start of a race: golden hour, the sun low ahead of the driver.
const START_HOUR := 17.0
## Highest the sun gets at noon (degrees above the horizon).
const NOON_ELEVATION := 70.0
## The light never comes from lower than this (degrees), even when the sun or moon touches the
## horizon: shadows stay clean instead of stretching for kilometres.
const MIN_LIGHT_ELEVATION := 9.0
const UPDATE_EVERY := 0.25

## Look at each sun elevation (degrees), blended in between. sky: zenith, mid, horizon, sun glow,
## lit cloud, cloud shadow. light: colour, energy (sun above -4, moon below). amb: ambient colour,
## energy. fog: colour. exp: exposure. sat: saturation. night: stars and moon (0-1).
const KEYS := [
	{"e": -90.0, "sky": [Color(0.01, 0.015, 0.05), Color(0.02, 0.035, 0.09), Color(0.04, 0.06, 0.13), Color(0.12, 0.14, 0.26), Color(0.13, 0.15, 0.24), Color(0.03, 0.04, 0.08)],
		"light": Color(0.6, 0.7, 1.0), "energy": 0.28, "amb": Color(0.14, 0.18, 0.36), "amb_e": 0.55, "fog": Color(0.05, 0.07, 0.15), "exp": 1.3, "sat": 1.1, "night": 1.0},
	{"e": -12.0, "sky": [Color(0.015, 0.025, 0.08), Color(0.04, 0.06, 0.16), Color(0.1, 0.1, 0.22), Color(0.3, 0.2, 0.3), Color(0.18, 0.16, 0.28), Color(0.05, 0.05, 0.1)],
		"light": Color(0.6, 0.7, 1.0), "energy": 0.28, "amb": Color(0.16, 0.18, 0.38), "amb_e": 0.55, "fog": Color(0.07, 0.08, 0.17), "exp": 1.3, "sat": 1.12, "night": 1.0},
	{"e": -4.0, "sky": [Color(0.05, 0.08, 0.26), Color(0.2, 0.2, 0.46), Color(0.78, 0.4, 0.36), Color(0.95, 0.42, 0.3), Color(0.85, 0.42, 0.4), Color(0.18, 0.15, 0.3)],
		"light": Color(1.0, 0.5, 0.32), "energy": 0.0, "amb": Color(0.3, 0.3, 0.56), "amb_e": 0.58, "fog": Color(0.34, 0.28, 0.44), "exp": 1.2, "sat": 1.25, "night": 0.3},
	{"e": 4.0, "sky": [Color(0.08, 0.14, 0.42), Color(0.34, 0.4, 0.76), Color(1.0, 0.55, 0.3), Color(1.0, 0.58, 0.28), Color(1.0, 0.62, 0.4), Color(0.36, 0.28, 0.5)],
		"light": Color(1.0, 0.62, 0.38), "energy": 1.5, "amb": Color(0.42, 0.46, 0.8), "amb_e": 0.62, "fog": Color(0.62, 0.52, 0.68), "exp": 1.1, "sat": 1.3, "night": 0.0},
	{"e": 15.0, "sky": [Color(0.08, 0.18, 0.52), Color(0.36, 0.5, 0.86), Color(1.0, 0.72, 0.48), Color(1.0, 0.72, 0.42), Color(1.0, 0.8, 0.6), Color(0.48, 0.44, 0.64)],
		"light": Color(1.0, 0.76, 0.52), "energy": 1.75, "amb": Color(0.46, 0.52, 0.84), "amb_e": 0.65, "fog": Color(0.66, 0.66, 0.8), "exp": 1.05, "sat": 1.3, "night": 0.0},
	{"e": 40.0, "sky": [Color(0.08, 0.28, 0.76), Color(0.34, 0.58, 0.94), Color(0.74, 0.86, 0.96), Color(1.0, 0.92, 0.78), Color(1.0, 1.0, 0.98), Color(0.6, 0.66, 0.8)],
		"light": Color(1.0, 0.96, 0.88), "energy": 2.0, "amb": Color(0.52, 0.62, 0.9), "amb_e": 0.7, "fog": Color(0.64, 0.78, 0.95), "exp": 1.0, "sat": 1.25, "night": 0.0},
	{"e": 90.0, "sky": [Color(0.07, 0.26, 0.74), Color(0.32, 0.56, 0.94), Color(0.72, 0.85, 0.96), Color(1.0, 0.94, 0.82), Color(1.0, 1.0, 1.0), Color(0.62, 0.68, 0.82)],
		"light": Color(1.0, 0.97, 0.9), "energy": 2.0, "amb": Color(0.52, 0.62, 0.9), "amb_e": 0.7, "fog": Color(0.64, 0.78, 0.95), "exp": 1.0, "sat": 1.25, "night": 0.0},
]

## Game hour, 0-24.
var hour := START_HOUR
var env: Environment
var light: DirectionalLight3D
var sky_mat: ShaderMaterial
## Turns the sun's path round the world: at START_HOUR the sun is ahead-left of the race start.
var _path_turn := Basis.IDENTITY
var _wait := 0.0
var _headlights: Array[SpotLight3D] = []
var _head_base := {}
## 0 by day, 1 at night: read by anyone who wants to know (HUD, lamps).
var night := 0.0


func setup(environment: Environment, sun: DirectionalLight3D, sky_material: ShaderMaterial, race_fwd: Vector3) -> void:
	env = environment
	light = sun
	sky_mat = sky_material
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--hour="):
			hour = fposmod(float(a.substr(7)), 24.0)
	# Where the sun would be at the start hour with no turn, and where we want it: turn the path.
	var natural := _sun_dir(START_HOUR, Basis.IDENTITY)
	var want := race_fwd.rotated(Vector3.UP, deg_to_rad(38.0))
	var a1 := atan2(natural.x, natural.z)
	var a2 := atan2(want.x, want.z)
	_path_turn = Basis(Vector3.UP, a2 - a1)
	_update()


## Direction towards the sun at hour h: rises at 6, highest at 12, sets at 18.
func _sun_dir(h: float, turn: Basis) -> Vector3:
	var t := (h - 6.0) / 24.0 * TAU
	var tilt := deg_to_rad(90.0 - NOON_ELEVATION)
	var east := Vector3(1, 0, 0)
	var arc := Vector3(0, cos(tilt), -sin(tilt))
	return turn * (east * cos(t) + arc * sin(t)).normalized()


func _process(delta: float) -> void:
	hour = fposmod(hour + delta * 24.0 / (DAY_MINUTES * 60.0), 24.0)
	_wait -= delta
	if _wait <= 0.0:
		_wait = UPDATE_EVERY
		_update()


func _update() -> void:
	var sun := _sun_dir(hour, _path_turn)
	var e := rad_to_deg(asin(clampf(sun.y, -1.0, 1.0)))
	var k := _blend(e)
	night = k.night
	# The one directional light is the sun by day and the moon (opposite the sun) by night.
	var toward: Vector3 = sun if e > -4.0 else -sun
	var flat := Vector3(toward.x, 0.0, toward.z).normalized()
	var elev := maxf(rad_to_deg(asin(clampf(toward.y, -1.0, 1.0))), MIN_LIGHT_ELEVATION)
	var dir := flat * cos(deg_to_rad(elev)) + Vector3.UP * sin(deg_to_rad(elev))
	if light:
		light.basis = Basis.looking_at(-dir, Vector3.UP if absf(dir.y) < 0.99 else Vector3.FORWARD)
		light.light_color = k.light
		light.light_energy = k.energy
		light.visible = k.energy > 0.01
	if env:
		env.ambient_light_color = k.amb
		env.ambient_light_energy = k.amb_e
		env.fog_light_color = k.fog
		env.tonemap_exposure = k.exp
		env.adjustment_saturation = k.sat
		env.fog_sun_scatter = 0.45 * (1.0 - k.night)
	if sky_mat:
		var names := ["zenith", "mid", "horizon", "sun_glow", "cloud_lit", "cloud_shade"]
		for i in names.size():
			sky_mat.set_shader_parameter(names[i], k.sky[i])
		sky_mat.set_shader_parameter("sun_dir", sun)
		sky_mat.set_shader_parameter("night", k.night)
	_light_headlights()


## Blend of the two keys around elevation e.
func _blend(e: float) -> Dictionary:
	for i in range(1, KEYS.size()):
		var b: Dictionary = KEYS[i]
		if e <= b.e:
			var a: Dictionary = KEYS[i - 1]
			var t := smoothstep(a.e, b.e, e)
			var sky := []
			for j in 6:
				sky.append((a.sky[j] as Color).lerp(b.sky[j], t))
			return {"sky": sky, "light": (a.light as Color).lerp(b.light, t), "energy": lerpf(a.energy, b.energy, t),
				"amb": (a.amb as Color).lerp(b.amb, t), "amb_e": lerpf(a.amb_e, b.amb_e, t), "fog": (a.fog as Color).lerp(b.fog, t),
				"exp": lerpf(a.exp, b.exp, t), "sat": lerpf(a.sat, b.sat, t), "night": lerpf(a.night, b.night, t)}
	return _blend(89.9)


## The player's headlight (car.gd) shines brighter and further at night.
func _light_headlights() -> void:
	if _headlights.is_empty():
		for car in get_tree().get_nodes_in_group("cinema_car"):
			for c in car.get_children():
				if c is SpotLight3D:
					_headlights.append(c)
					_head_base[c] = [c.light_energy, c.spot_range]
	for h in _headlights:
		if is_instance_valid(h):
			var base: Array = _head_base[h]
			h.light_energy = base[0] * lerpf(1.0, 1.6, night)
			h.spot_range = base[1] * lerpf(1.0, 1.8, night)
