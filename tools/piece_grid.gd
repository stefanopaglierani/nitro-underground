extends SceneTree
## Every piece of a model pack in a numbered grid, each scaled to fit its cell, seen from +z
## (or from "back", "left", "right", "top"). Used to pick pieces by index:
##   xvfb-run godot --rendering-driver opengl3 --script tools/piece_grid.gd -- <res path> <out.png> [view] [cols]

func _initialize() -> void:
	await process_frame
	var a := OS.get_cmdline_user_args()
	var pieces := Scenery.pieces_of((load(a[0]) as PackedScene).instantiate())
	var view := a[2] if a.size() > 2 else "front"
	var cols := int(a[3]) if a.size() > 3 else int(ceil(sqrt(pieces.size() * 1.8)))
	var world := Node3D.new()
	root.add_child(world)
	var rows := int(ceil(pieces.size() / float(cols)))
	var yaw: float = {"front": 0.0, "back": PI, "left": -PI / 2, "right": PI / 2, "top": 0.0}[view]
	for i in pieces.size():
		var p: Dictionary = pieces[i]
		var box: AABB = p["box"]
		var s := 0.8 / maxf(box.size.y, maxf(box.size.x, box.size.z))
		var node := Node3D.new()
		for part in p["parts"]:
			var mi := MeshInstance3D.new()
			mi.mesh = part[0]
			mi.transform = part[1]
			node.add_child(mi)
		node.scale = Vector3.ONE * s
		node.rotation.y = yaw
		node.position = Vector3(i % cols, -(i / cols) * 1.0, 0)
		world.add_child(node)
		var l := Label3D.new()
		l.text = str(i)
		l.font_size = 48
		l.pixel_size = 0.004
		l.modulate = Color.YELLOW
		l.outline_size = 8
		l.position = node.position + Vector3(-0.4, 0.85, 0.5)
		world.add_child(l)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.6, 0.7)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.8, 0.8)
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 20, 0)
	world.add_child(sun)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = maxf(rows, cols * 9.0 / 16.0) * 1.05
	cam.position = Vector3((cols - 1) / 2.0, -(rows - 1) / 2.0 + 0.4, 100)
	if view == "top":
		pass
	cam.far = 300.0
	world.add_child(cam)
	root.size = Vector2i(1600, 900)
	for f in 8:
		await process_frame
	root.get_texture().get_image().save_png(a[1])
	quit()
