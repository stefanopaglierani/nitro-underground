class_name ComicStyle
## The game's look: 2.5D comic, like a comic book brought to life (Spider-Verse style).
## It keeps the 3D models: every material that enters the scene gets toon (cel) light with hard
## shadow bands, cars get a black ink outline, a full-screen pass (shaders/stylize.gdshader)
## flattens the colours into bands, draws ink lines where the depth jumps and adds halftone dots,
## hatching and misprinted colour plates; the sky is a painted pop-art one and speed lines appear
## at high speed or with nitro.

static var _materials := {}  # original material -> toon copy
static var _shaders := {}  # original shader -> toon copy
static var _outline: ShaderMaterial
static var _queue: Array[GeometryInstance3D] = []
static var _flush_queued := false


## Converts what is already in the tree and everything added later (cars, debris, the garage car).
static func install(tree: SceneTree) -> void:
	_materials.clear()  # the level was rebuilt: its materials are new
	_scan(tree.root)
	if not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)


static func _on_node_added(node: Node) -> void:
	if node is GeometryInstance3D:
		# Materials are often set right after add_child: convert at the end of the frame.
		_queue.append(node)
		if not _flush_queued:
			_flush_queued = true
			_flush.call_deferred()


static func _flush() -> void:
	_flush_queued = false
	var q := _queue
	_queue = []
	for g in q:
		if is_instance_valid(g):
			_convert(g)


static func _scan(node: Node) -> void:
	if node is GeometryInstance3D:
		_convert(node)
	for c in node.get_children():
		_scan(c)


static func _convert(g: GeometryInstance3D) -> void:
	if g.has_meta("comic"):
		return
	g.set_meta("comic", true)
	var mesh: Mesh = null
	if g is MeshInstance3D:
		mesh = (g as MeshInstance3D).mesh
	elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh:
		mesh = (g as MultiMeshInstance3D).multimesh.mesh
	var ink := _is_car_part(g)
	if g.material_override:
		g.material_override = _toon(g.material_override, ink)
	if mesh == null:
		return
	for i in mesh.get_surface_count():
		var m: Material = null
		if g is MeshInstance3D:
			m = (g as MeshInstance3D).get_surface_override_material(i)
		if m == null:
			m = mesh.surface_get_material(i)
		if m == null or g.material_override:
			continue
		if g is MeshInstance3D:
			(g as MeshInstance3D).set_surface_override_material(i, _toon(m, ink))
		else:
			mesh.surface_set_material(i, _toon(m, ink))


static func _is_car_part(n: Node) -> bool:
	var p := n.get_parent()
	while p:
		# Player, rivals, police, traffic and the garage car (tagged by main.gd). Not the guardrail
		# debris: its pieces are flat panels, and the outline would draw them as black slabs.
		if p is Car or p is TrafficCar or p.has_meta("comic_ink"):
			return true
		p = p.get_parent()
	return false


static func _toon(m: Material, ink: bool) -> Material:
	var key := [m, ink]
	if _materials.has(key):
		return _materials[key]
	var out: Material = m
	if m is BaseMaterial3D:
		var b := (m as BaseMaterial3D).duplicate() as BaseMaterial3D
		if b.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
			b.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			b.specular_mode = BaseMaterial3D.SPECULAR_TOON
			# Brighter, flatter colours, like painted cels.
			if b.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
				var c := b.albedo_color
				b.albedo_color = Color.from_hsv(c.h, minf(c.s * 1.1, 1.0), minf(c.v * 1.05, 1.0), c.a)
			b.metallic = minf(b.metallic, 0.4)
			# Rim light and shine on solid things only: on leaf cards they turn whole trees white.
			if b.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				b.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
				b.normal_enabled = false
			else:
				b.rim_enabled = true
				b.rim = 0.35
				b.rim_tint = 0.6
		if ink and b.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
			b.next_pass = _outline_material()
		out = b
	elif m is ShaderMaterial and (m as ShaderMaterial).shader:
		var s := (m as ShaderMaterial).duplicate() as ShaderMaterial
		s.shader = _toon_shader(s.shader)
		if ink:
			s.next_pass = _outline_material()
		out = s
	_materials[key] = out
	return out


## The same spatial shader with toon light: render_mode gets diffuse_toon and specular_toon.
static func _toon_shader(sh: Shader) -> Shader:
	if _shaders.has(sh):
		return _shaders[sh]
	var code := sh.code
	var out := sh
	if code.contains("shader_type spatial") and not code.contains("unshaded") and not code.contains("diffuse_toon"):
		var rx := RegEx.create_from_string("render_mode\\s+([^;]*);")
		var found := rx.search(code)
		if found:
			code = code.replace(found.get_string(0), "render_mode " + found.get_string(1) + ", diffuse_toon, specular_toon;")
		else:
			code = code.replace("shader_type spatial;", "shader_type spatial;\nrender_mode diffuse_toon, specular_toon;")
		out = Shader.new()
		out.code = code
	_shaders[sh] = out
	return out


static func _outline_material() -> ShaderMaterial:
	if _outline == null:
		_outline = ShaderMaterial.new()
		_outline.shader = preload("res://shaders/comic_outline.gdshader")
		_outline.set_shader_parameter("width", 0.06)
	return _outline


## Painted sky, light shadows, vivid colours. Called after Track.setup_environment().
## A night level keeps its own sky, ambient and moon: only the colours get the drawn look.
static func setup_environment(parent: Node, night := false) -> void:
	var we: WorldEnvironment = null
	var sun: DirectionalLight3D = null
	for c in parent.get_children():
		if c is WorldEnvironment:
			we = c
		elif c is DirectionalLight3D:
			sun = c
	if night:
		if we and we.environment:
			var env := we.environment
			env.tonemap_exposure *= 1.1
			env.glow_intensity = maxf(env.glow_intensity, 0.9)
			env.adjustment_enabled = true
			env.adjustment_saturation = 1.45
			env.adjustment_contrast = 1.12
		return
	if we and we.environment:
		var env := we.environment
		var sky_mat := ShaderMaterial.new()
		sky_mat.shader = preload("res://shaders/comic_sky.gdshader")
		# Pop-art sky: deeper blue on top, a warm pink band at the horizon.
		sky_mat.set_shader_parameter("zenith", Color(0.05, 0.22, 0.85))
		sky_mat.set_shader_parameter("horizon", Color(1.0, 0.72, 0.78))
		sky_mat.set_shader_parameter("cloud_shade", Color(0.78, 0.62, 0.9))
		var sky := Sky.new()
		sky.sky_material = sky_mat
		# Small light map: the toon shading only needs a rough idea of the sky colours.
		sky.radiance_size = Sky.RADIANCE_SIZE_64
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.62, 0.7, 0.95)
		env.ambient_light_energy = 0.55
		env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.tonemap_exposure = 1.1
		env.glow_enabled = true
		env.glow_intensity = 0.5
		env.glow_bloom = 0.05
		env.glow_hdr_threshold = 1.0
		env.fog_enabled = true
		env.fog_light_color = Color(0.7, 0.82, 1.0)
		env.fog_density = 0.0009
		env.fog_aerial_perspective = 0.0
		env.fog_sky_affect = 0.0
		env.adjustment_enabled = true
		env.adjustment_saturation = 1.35
		env.adjustment_contrast = 1.15
		env.adjustment_brightness = 1.03
	if sun:
		sun.light_color = Color(1.0, 0.97, 0.9)
		sun.light_energy = 1.35
		sun.shadow_opacity = 0.7


## Full-screen stylize pass (cel bands, ink lines, comic print), as a child of the camera.
static func add_stylize_pass(camera: Camera3D) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	quad.flip_faces = true
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/stylize.gdshader")
	mat.render_priority = Material.RENDER_PRIORITY_MAX
	quad.material = mat
	var mi := MeshInstance3D.new()
	mi.name = "Stylize"
	mi.mesh = quad
	mi.extra_cull_margin = 16384.0
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta("comic", true)
	camera.add_child(mi)


## Speed lines at the screen edges, on the HUD layer below the controls.
static func make_speed_lines() -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/comic_speed_lines.gdshader")
	r.material = mat
	return r
