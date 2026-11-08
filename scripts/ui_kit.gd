class_name UiKit
extends RefCounted
## Pieces shared by the garage (menu.gd) and the dealer (dealer.gd): button and panel styles, the
## money and reputation panels, a 3D window for a car, drawn arrows and icons.

const INK := Color(0.05, 0.04, 0.03)
const GOLD := Color(1, 0.8, 0.25)


static func box(fill: Color, border: Color, radius := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 6
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


static func button(text: String, color: Color, font := 30) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.45))
	b.add_theme_color_override("font_outline_color", INK)
	b.add_theme_constant_override("outline_size", 8)
	var normal := box(Color(color.r * 0.7, color.g * 0.7, color.b * 0.7, 0.92), Color(1, 1, 1, 0.75))
	var on := box(color, Color.WHITE)
	var off := box(Color(0.15, 0.15, 0.15, 0.75), Color(1, 1, 1, 0.25))
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("focus", normal)
	b.add_theme_stylebox_override("disabled", off)
	return b


static func label(size: int, color := Color.WHITE, outline := 8) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func anchor(c: Control, l: float, t: float, r: float, b: float) -> void:
	c.anchor_left = l
	c.anchor_top = t
	c.anchor_right = r
	c.anchor_bottom = b
	c.offset_left = 0
	c.offset_top = 0
	c.offset_right = 0
	c.offset_bottom = 0


## Money and reputation panels in the top right corner; returns their value labels.
static func money_and_rep(parent: Control) -> Array[Label]:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	row.offset_left = -400
	row.offset_right = -20
	row.offset_top = 18
	row.offset_bottom = 70
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var out: Array[Label] = [stat_panel(row, "money"), stat_panel(row, "rep")]
	out[0].text = thousands(SaveGame.money)
	out[1].text = thousands(SaveGame.reputation)
	return out


## A small panel with an icon and a value; returns the value label.
static func stat_panel(parent: Control, kind: String) -> Label:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box(Color(0.06, 0.05, 0.04, 0.78), Color(1, 1, 1, 0.3), 26))
	panel.custom_minimum_size = Vector2(150, 0)
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var icon := Icon.new()
	icon.kind = kind
	icon.custom_minimum_size = Vector2(34, 34)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var value := Label.new()
	value.add_theme_font_size_override("font_size", 26)
	value.add_theme_color_override("font_color", Color.WHITE)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	return value


## 12345 -> "12.345".
static func thousands(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


## The little 3D set of a car window: its own world, warm light and a camera. Returns
## [viewport container, stage node, camera].
static func car_window(parent: Control) -> Array:
	var view := SubViewportContainer.new()
	view.stretch = true
	view.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(view)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_2X
	view.add_child(vp)
	var stage := Node3D.new()
	vp.add_child(stage)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.78, 0.7)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	stage.add_child(we)
	# Daylight from the open door behind the car, a lamp in front of it.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 160, 0)
	sun.light_color = Color(1, 0.88, 0.7)
	sun.light_energy = 1.2
	stage.add_child(sun)
	var lamp := DirectionalLight3D.new()
	lamp.rotation_degrees = Vector3(-40, -25, 0)
	lamp.light_color = Color(1, 0.85, 0.65)
	lamp.light_energy = 1.5
	stage.add_child(lamp)
	var cam := Camera3D.new()
	cam.fov = 30
	stage.add_child(cam)
	return [view, stage, cam]


## Puts the camera so the whole car `model` fills the window (`zoom` 1.55 = garage framing).
static func frame_car(model: Node3D, cam: Camera3D, zoom := 1.55, look_y := 0.9) -> void:
	var length := 4.5
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var bb: AABB = CarModel._xf_in(mi, model) * (mi as MeshInstance3D).get_aabb()
		length = maxf(length, maxf(absf(bb.position.z), absf(bb.end.z)) * 2.0)
	var dist := length * zoom
	cam.position = Vector3(0, dist * 0.22, dist)
	cam.look_at(Vector3(0, look_y, 0), Vector3.UP)


## Arrow drawn as a triangle (left or right) with a dark border, used beside the car.
class ArrowButton:
	extends Button
	var dir := 1

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE

	func _draw() -> void:
		var c := size * 0.5
		var w := size.x * 0.32
		var h := size.y * 0.42
		var tip := c + Vector2(w * dir, 0)
		var pts := PackedVector2Array([tip, c + Vector2(-w * dir, -h), c + Vector2(-w * dir, h)])
		var fill := Color(1, 1, 1, 1.0 if is_hovered() or button_pressed else 0.88)
		draw_colored_polygon(pts, Color(0, 0, 0, 0.35))
		var inner := PackedVector2Array()
		for p in pts:
			inner.append(c + (p - c) * 0.86)
		draw_colored_polygon(inner, fill)
		pts.append(pts[0])
		draw_polyline(pts, Color(0.05, 0.04, 0.03, 0.9), 4.0, true)


## Small drawn icons: "money" (gold coin), "rep" (star), "map" (folded map with a pin),
## "shadow" (soft oval shadow under a car), "dot" / "dot_on" (tuning level).
class Icon:
	extends Control
	var kind := "money"

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		match kind:
			"shadow":
				for i in 8:
					var k := 1.0 - i * 0.11
					var pts := PackedVector2Array()
					for j in 48:
						var a := TAU * j / 48.0
						pts.append(c + Vector2(cos(a) * size.x * 0.5 * k, sin(a) * size.y * 0.5 * k))
					draw_colored_polygon(pts, Color(0, 0, 0, 0.28))
			"dot", "dot_on":
				draw_circle(c, r, Color(0, 0, 0, 0.6))
				draw_circle(c, r * 0.72, Color(1, 0.75, 0.15) if kind == "dot_on" else Color(1, 1, 1, 0.15))
			"money":
				draw_circle(c, r, Color(0.55, 0.38, 0.05))
				draw_circle(c, r * 0.84, Color(1, 0.8, 0.2))
				var f := get_theme_default_font()
				var fs := int(r * 1.3)
				var tw := f.get_string_size("$", HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
				draw_string(f, c + Vector2(-tw.x * 0.5, fs * 0.36), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.5, 0.33, 0.02))
			"rep":
				var pts := PackedVector2Array()
				for i in 10:
					var a := -PI / 2.0 + i * PI / 5.0
					pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
				draw_colored_polygon(pts, Color(0.35, 0.75, 1))
				pts.append(pts[0])
				draw_polyline(pts, Color(0.05, 0.2, 0.4), 2.0, true)
			"map":
				# Three folded panels, zig-zag like a paper road map.
				var w := size.x / 3.0
				var o := size.y * 0.1
				var cols := [Color(0.88, 0.85, 0.72), Color(0.7, 0.68, 0.56), Color(0.88, 0.85, 0.72)]
				for i in 3:
					var dl := o * float(i % 2)
					var dr := o * float((i + 1) % 2)
					draw_colored_polygon(PackedVector2Array([Vector2(i * w, dl), Vector2((i + 1) * w, dr),
						Vector2((i + 1) * w, size.y - o + dr), Vector2(i * w, size.y - o + dl)]), cols[i])
				draw_polyline(PackedVector2Array([Vector2(size.x * 0.12, size.y * 0.75), Vector2(size.x * 0.4, size.y * 0.55),
					Vector2(size.x * 0.6, size.y * 0.65), Vector2(size.x * 0.8, size.y * 0.35)]), Color(0.85, 0.15, 0.1), 3.0, true)
				draw_circle(Vector2(size.x * 0.8, size.y * 0.3), r * 0.2, Color(0.85, 0.15, 0.1))
				draw_circle(Vector2(size.x * 0.8, size.y * 0.3), r * 0.08, Color.WHITE)
