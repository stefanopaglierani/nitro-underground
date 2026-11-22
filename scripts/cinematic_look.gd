class_name CinematicLook
## The new look (Stefano 22/11/2026, "Cinematic 2.5D Graphic Novel / Stylized Realism"): realistic
## 3D, a continuous day and night cycle (scripts/day_night.gd, starting at the golden hour),
## saturated warm/cool colours, painted sky and ground, thin contours on the
## race cars, deep atmosphere. PROTOTYPE: on only with the start option --look=cinema, so without
## it the game is exactly as before. It only changes light, colours and materials when a race
## loads: no physics, race, camera, world geometry or car files are touched.
##
## Quality (start option --lookq=N, default 1):
##   0 Basso  colours, light, sky, fog, car materials, painted ground (almost free)
##   1 Medio  + contour on the player's car
##   2 Alto   + contour on every car in the race + light glow on lamps and sun

## True only when the game is started with --look=cinema.
static var enabled: bool = OS.get_cmdline_user_args().has("--look=cinema")
static var quality := 1
static var _outline: ShaderMaterial
static var _mats := {}  # original material -> cinematic copy
static var _player: Node = null


static func _read_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lookq="):
			quality = clampi(int(a.substr(8)), 0, 2)


## Light, sky, fog, colour grading, ground and sea. Called after the level built its sky and sun.
static func apply_environment(parent: Node, level: Node) -> void:
	if not enabled:
		return
	_read_args()
	print("[look] cinema, quality %d" % quality)
	if level and level.get("night") == true:
		return  # the night levels keep their own light: the day and night cycle is for daytime places
	var we: WorldEnvironment = null
	var sun: DirectionalLight3D = null
	for c in parent.get_children():
		if c is WorldEnvironment:
			we = c
		elif c is DirectionalLight3D:
			sun = c
	if we and we.environment:
		_grade(we.environment, level, sun, parent)
	if level:
		_paint_world(level)


## Direction of the start of the race, flat: the cycle puts the start-hour sun ahead-left of it.
static func _race_fwd(level: Node) -> Vector3:
	if level and level.has_method("race_path"):
		var path: Array = level.race_path()
		if path.size() > 1:
			var fwd := (path[1] as Vector3) - (path[0] as Vector3)
			fwd.y = 0.0
			if fwd.length() > 0.01:
				return fwd.normalized()
	return Vector3.FORWARD


static func _grade(env: Environment, level: Node, sun: DirectionalLight3D, parent: Node) -> void:
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = preload("res://shaders/cinematic_sky.gdshader")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	# The cycle changes the sky slowly: its light map is updated a little at every frame.
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	# Cool blue-violet light in the shadows against the warm sun: the warm/cool contrast.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	# Atmosphere: warm haze lit by the sun, thicker low down (sea and valleys), hills fading blue.
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_energy = 1.0
	env.fog_density = 0.0011
	env.fog_aerial_perspective = 0.35
	env.fog_sky_affect = 0.15
	var sea: float = level.get("sea_level") if level and level.get("sea_level") != null else 0.0
	env.fog_height = sea + 25.0
	env.fog_height_density = 0.006
	env.glow_enabled = quality >= 2
	env.glow_intensity = 0.35
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.3
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.1
	env.adjustment_brightness = 1.0
	env.adjustment_color_correction = _split_tone_lut()
	if sun:
		sun.shadow_opacity = 0.9
		sun.shadow_blur = 1.4
		sun.light_angular_distance = 0.6
	var cycle := DayNight.new()
	cycle.name = "DayNight"
	parent.add_child(cycle)
	cycle.setup(env, sun, sky_mat, _race_fwd(level))


## Colour table: shadows towards blue-violet, highlights towards amber, a gentle S curve.
static func _split_tone_lut() -> ImageTexture3D:
	const N := 17
	var layers: Array[Image] = []
	for b in N:
		var img := Image.create(N, N, false, Image.FORMAT_RGB8)
		for g in N:
			for r in N:
				var c := Vector3(r, g, b) / float(N - 1)
				var l := c.dot(Vector3(0.299, 0.587, 0.114))
				var shadow := pow(1.0 - l, 2.0)
				var light := pow(l, 2.0)
				c += Vector3(-0.03, -0.005, 0.06) * shadow + Vector3(0.06, 0.02, -0.05) * light
				# Gentle S curve around the middle grey.
				c = c + (c - Vector3(0.5, 0.5, 0.5)) * 0.08 * (Vector3.ONE - (c - Vector3(0.5, 0.5, 0.5)).abs() * 2.0)
				img.set_pixel(r, g, Color(clampf(c.x, 0, 1), clampf(c.y, 0, 1), clampf(c.z, 0, 1)))
		layers.append(img)
	var tex := ImageTexture3D.new()
	tex.create(Image.FORMAT_RGB8, N, N, N, false, layers)
	return tex


## Painted ground and a richer sea, through the materials the level already shares.
static func _paint_world(level: Node) -> void:
	var ground = level.get("_terrain_material")
	if ground is ShaderMaterial:
		var g := ground as ShaderMaterial
		g.set_shader_parameter("paint_amount", 1.0)
		g.set_shader_parameter("grass_tint", Vector3(0.86, 0.98, 0.5))
		g.set_shader_parameter("sand_tint", Vector3(1.05, 0.9, 0.72))
	var sea := level.get_node_or_null("Sea") as MeshInstance3D
	if sea and sea.material_override is ShaderMaterial:
		var s := sea.material_override as ShaderMaterial
		s.set_shader_parameter("deep", Color(0.01, 0.12, 0.36))
		s.set_shader_parameter("shallow", Color(0.04, 0.62, 0.7))


## Car materials and contours. Called once the cars are on the grid; police cars that join later
## are converted as they enter the scene.
static func install_cars(tree: SceneTree, player: Node) -> void:
	if not enabled:
		return
	_player = player
	if player:
		player.add_to_group("cinema_car")
	_scan(tree.root)
	if not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)


static func _on_node_added(node: Node) -> void:
	if node is MeshInstance3D:
		_convert_deferred.call_deferred(node)


static func _convert_deferred(node: Node) -> void:
	if is_instance_valid(node):
		_convert(node as MeshInstance3D)


static func _scan(node: Node) -> void:
	if node is MeshInstance3D:
		_convert(node as MeshInstance3D)
	for c in node.get_children():
		_scan(c)


static func _car_of(n: Node) -> Node:
	var p := n.get_parent()
	while p:
		if p is Car:
			return p
		p = p.get_parent()
	return null


static func _convert(mi: MeshInstance3D) -> void:
	if mi.has_meta("cinema") or mi.mesh == null:
		return
	var car := _car_of(mi)
	if car == null:
		return
	mi.set_meta("cinema", true)
	for i in mi.mesh.get_surface_count():
		var m := mi.get_active_material(i)
		var out := _car_material(m)
		if out != m:
			mi.set_surface_override_material(i, out)
	if quality >= 2 or (quality >= 1 and car == _player):
		mi.material_overlay = _outline_material()


## Sharper edges in the light (rim), deeper paint. Lamps (emissive) stay the very same material:
## car.gd drives their brightness for the brake and siren lights.
static func _car_material(m: Material) -> Material:
	if not (m is BaseMaterial3D):
		return m
	var b := m as BaseMaterial3D
	if b.emission_enabled or b.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		return m
	if _mats.has(m):
		return _mats[m]
	var c := b.duplicate() as BaseMaterial3D
	if c.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
		c.rim_enabled = true
		c.rim = 0.45
		c.rim_tint = 0.55
	if c.clearcoat_enabled:
		# The body paint: deeper, more saturated colour and a crisper coat.
		var col := c.albedo_color
		c.albedo_color = Color.from_hsv(col.h, minf(col.s * 1.15, 1.0), col.v * 0.92, col.a)
		c.clearcoat_roughness = 0.03
	_mats[m] = c
	return c


static func _outline_material() -> ShaderMaterial:
	if _outline == null:
		_outline = ShaderMaterial.new()
		_outline.shader = preload("res://shaders/cinematic_outline.gdshader")
	return _outline
