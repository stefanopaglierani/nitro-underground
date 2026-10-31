extends SceneTree
## Picture of the pieces of a model pack, to choose which ones a level uses:
##   xvfb-run godot --rendering-driver opengl3 --script tools/pack_sheet.gd -- <file.glb|res path> <out.png>
## The pack is split into pieces as Scenery.pieces() does; they stand in a row, left to right in
## index order, seen from the front (+z side) with the sun behind the camera. Sizes are printed.

func _initialize() -> void:
	await process_frame
	var a := OS.get_cmdline_user_args()
	var src := a[0]
	var pieces := Scenery.pieces_of(_load_scene(src))
	var world := Node3D.new()
	root.add_child(world)
	var x := 0.0
	var tallest := 1.0
	var i := 0
	for p in pieces:
		var box: AABB = p["box"]
		var node := Node3D.new()
		for part in p["parts"]:
			var mi := MeshInstance3D.new()
			mi.mesh = part[0]
			mi.transform = part[1]
			node.add_child(mi)
		node.position = Vector3(x + box.size.x / 2.0, 0, 0)
		world.add_child(node)
		print("piece %d: size %s at x=%.0f" % [i, box.size.snapped(Vector3.ONE * 0.1), x])
		x += box.size.x + maxf(2.0, box.size.x * 0.15)
		tallest = maxf(tallest, box.size.y)
		i += 1
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
	cam.size = maxf(x * 9.0 / 16.0, tallest) * 1.1
	var aim := Vector3(x / 2.0, tallest / 2.0, 0)
	cam.position = aim + Vector3(0, sin(deg_to_rad(8.0)), cos(deg_to_rad(8.0))) * 1000.0
	cam.rotation_degrees = Vector3(-8, 0, 0)
	if a.size() > 2 and a[2] == "back":
		cam.position = aim + Vector3(0, sin(deg_to_rad(8.0)), -cos(deg_to_rad(8.0))) * 1000.0
		cam.rotation_degrees = Vector3(-8, 180, 0)
	if a.size() > 2 and a[2] == "top":
		cam.position = Vector3(x / 2.0, 1000.0, 0)
		cam.rotation_degrees = Vector3(-90, 0, 0)
	cam.far = 3000.0
	world.add_child(cam)
	root.size = Vector2i(1600, 900)
	for f in 8:
		await process_frame
	root.get_texture().get_image().save_png(a[1])
	quit()


func _load_scene(src: String) -> Node3D:
	if src.begins_with("res://"):
		return (load(src) as PackedScene).instantiate()
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	doc.append_from_file(src, st)
	return doc.generate_scene(st)
