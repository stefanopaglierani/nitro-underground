extends SceneTree
## Debug: builds a level and lists the objects near a point.  godot --headless --script tools/probe.gd -- <level> x z [r]
func _initialize() -> void:
	await process_frame
	var a := OS.get_cmdline_user_args()
	var lv: Mountain = Mountain.new()
	if a[0] == "coast": lv = Coast.new()
	if a[0] == "night": lv = NightCity.new()
	root.add_child(lv)
	lv.build()
	var p := Vector3(float(a[1]), 0, float(a[2]))
	var r := float(a[3]) if a.size() > 3 else 15.0
	for n in lv.find_children("*", "Node3D", true, false):
		var g := (n as Node3D).global_position
		if Vector2(g.x - p.x, g.z - p.z).length() < r:
			print(n.get_class(), " ", n.name, " ", g.round(), " parent=", n.get_parent().name)
	var k := lv.nearest(p)
	print("nearest sample ", k, " ", lv.pts[k], " limit ", lv.limits[k])
	quit()
