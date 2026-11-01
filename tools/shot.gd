extends SceneTree
## Pictures of a circuit without racing it: builds the level with the game's look and takes a
## shot from a chase-camera position at some points of the lap.
##   xvfb-run godot --rendering-driver opengl3 --script tools/shot.gd -- <level> <out dir> [fractions...]
## level: mountain, coast, night, desert. Fractions of the lap, default 0 .1 .2 ... .9.
## A fraction followed by "h" (e.g. 0.3h) shoots from high above instead, "s" from a scenic
## spot behind and above the car looking far down the road (used for the menu pictures).

func _initialize() -> void:
	await process_frame
	var a := OS.get_cmdline_user_args()
	var level := a[0]
	var out := a[1]
	DirAccess.make_dir_recursive_absolute(out)
	var fr: Array = []
	for i in range(2, a.size()):
		fr.append(a[i])
	if fr.is_empty():
		for i in 10:
			fr.append(str(i / 10.0))
	root.size = Vector2i(1280, 720)
	var holder := Node3D.new()
	root.add_child(holder)
	var t: Mountain = Main.make_level(level)
	holder.add_child(t)
	for step in t.build_steps():
		var t0 := Time.get_ticks_msec()
		(step[1] as Callable).call()
		print("step %s: %d ms" % [step[0], Time.get_ticks_msec() - t0])
	t.setup_environment(holder)
	ComicStyle.setup_environment(holder, t.night)
	var cam := Camera3D.new()
	cam.fov = 70
	cam.far = t.view_distance
	holder.add_child(cam)
	ComicStyle.add_stylize_pass(cam)
	ComicStyle.install(self)
	var n := t.pts.size()
	for f: String in fr:
		var high := f.ends_with("h")
		var scenic := f.ends_with("s")
		var k := int(f.trim_suffix("h").trim_suffix("s").to_float() * n + t.start_i) % n
		var p := t.pts[k]
		var ahead := t.pts[(k + 14) % n]
		if scenic:
			cam.position = p - t.tangents[k] * 24.0 + Vector3(0, 10.0, 0)
			cam.look_at(t.pts[(k + 90) % n] + Vector3(0, 4.0, 0))
		elif high:
			cam.position = p + Vector3(60, 140, 60)
			cam.look_at(p)
		else:
			cam.position = p - t.tangents[k] * 7.0 + Vector3(0, 3.0, 0)
			cam.look_at(ahead + Vector3(0, 1.0, 0))
		for i in 12:
			await process_frame
		root.get_texture().get_image().save_png("%s/%s_%s.png" % [out, level, f])
		print("shot ", f, " at ", p.round(), " RAM ", OS.get_static_memory_usage() / 1048576, " MB, prims ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), " draws ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	quit()
