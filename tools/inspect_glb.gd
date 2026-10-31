extends SceneTree
## Lists the parts of .glb files (outside the project too): godot --headless --script tools/inspect_glb.gd -- a.glb b.glb
## For each mesh: path, triangles, size (after node transforms) and centre.
func _initialize() -> void:
	await process_frame
	for f in OS.get_cmdline_user_args():
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		if doc.append_from_file(f, st) != OK:
			print("cannot read ", f)
			continue
		var scene := doc.generate_scene(st) as Node3D
		root.add_child(scene)
		var total := 0
		var lines := []
		var box := AABB()
		var first := true
		for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
			var tris := 0
			for s in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(s)
				tris += (arr[Mesh.ARRAY_INDEX].size() if arr[Mesh.ARRAY_INDEX] else arr[Mesh.ARRAY_VERTEX].size()) / 3
			total += tris
			var b: AABB = mi.global_transform * mi.mesh.get_aabb()
			box = b if first else box.merge(b)
			first = false
			lines.append("  %-40s tris=%6d size=%s centre=%s" % [str(scene.get_path_to(mi)).right(40), tris, b.size.snapped(Vector3.ONE * 0.1), b.get_center().snapped(Vector3.ONE * 0.1)])
		var texs := []
		for t in st.get_images():
			texs.append("%dx%d" % [t.get_width(), t.get_height()])
		print("%s: %d meshes, %d tris, size %s, textures %s" % [f.get_file(), lines.size(), total, box.size.snapped(Vector3.ONE * 0.1), texs])
		if lines.size() <= int(OS.get_environment("MAXL") if OS.get_environment("MAXL") != "" else "30"):
			for l in lines:
				print(l)
		scene.queue_free()
	quit()
