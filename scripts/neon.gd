class_name Neon
extends RefCounted
## Neon look of the dealer (v0.20, Stefano: "più moderni, leggermente graffitari, colori al neon"):
## icons drawn as glowing tubes, buttons with a glowing border and the labels in a marker font
## (Permanent Marker, Apache 2.0, assets/fonts). Icons are drawn in code, so they stay sharp at
## any size and add nothing to download.

const FONT := "res://assets/fonts/PermanentMarker-Regular.ttf"
const CYAN := Color(0.15, 0.9, 1.0)
const PINK := Color(1.0, 0.2, 0.75)
const LIME := Color(0.7, 1.0, 0.15)
const GREEN := Color(0.2, 1.0, 0.45)
const ORANGE := Color(1.0, 0.55, 0.1)
const RED := Color(1.0, 0.2, 0.3)
const YELLOW := Color(1.0, 0.88, 0.2)
const INK := Color(0.03, 0.02, 0.06)


static func font() -> Font:
	return load(FONT)


## A label in the marker font, neon coloured with a dark outline.
static func label(size: int, color: Color, outline := 8) -> Label:
	var l := UiKit.label(size, color, outline)
	l.add_theme_font_override("font", font())
	return l


## Icon names drawn by draw_icon: garage, spray, tuning, key, tag, motore, centralina, scarico,
## nitro, freni, sospensioni.
const PART_ICONS := ["motore", "centralina", "scarico", "nitro", "freni", "sospensioni"]


## Strokes of an icon in a 100 x 100 box: each one is [points, width factor, closed].
static func _strokes(kind: String) -> Array:
	var s: Array = []
	match kind:
		"garage":
			s.append([[Vector2(6, 46), Vector2(50, 10), Vector2(94, 46)], 1.3, false])
			s.append([[Vector2(17, 37), Vector2(17, 90), Vector2(83, 90), Vector2(83, 37)], 1.0, false])
			s.append([[Vector2(29, 52), Vector2(71, 52), Vector2(71, 90), Vector2(29, 90)], 0.9, true])
			for y in [61, 70, 79]:
				s.append([[Vector2(33, y), Vector2(67, y)], 0.6, false])
		"spray":
			s.append([_round_rect(Rect2(30, 38, 34, 54), 6), 1.0, true])
			s.append([[Vector2(30, 40), Vector2(37, 30), Vector2(57, 30), Vector2(64, 40)], 1.0, false])
			s.append([[Vector2(41, 30), Vector2(41, 21), Vector2(53, 21), Vector2(53, 30)], 0.9, false])
			s.append([[Vector2(44, 21), Vector2(44, 14), Vector2(54, 14)], 0.8, false])
			s.append([[Vector2(30, 56), Vector2(64, 56)], 0.6, false])
			s.append([[Vector2(30, 76), Vector2(64, 76)], 0.6, false])
			for p in [Vector2(66, 12), Vector2(76, 8), Vector2(74, 18), Vector2(86, 12), Vector2(84, 24), Vector2(94, 18), Vector2(92, 6)]:
				s.append([_circle(p, 1.6, 8), 0.8, true])
		"tuning":
			# Wrench from bottom left to top right, screwdriver from bottom right to top left.
			s.append([[Vector2(18, 84), Vector2(60, 42)], 1.6, false])
			s.append([_arc(Vector2(70, 32), 15, deg_to_rad(80), deg_to_rad(370), 14), 1.2, false])
			s.append([_circle(Vector2(18, 84), 4, 10), 0.8, true])
			s.append([[Vector2(86, 86), Vector2(66, 66)], 2.6, false])
			s.append([[Vector2(64, 64), Vector2(24, 24)], 0.9, false])
			s.append([[Vector2(24, 24), Vector2(16, 16)], 1.5, false])
		"key":
			s.append([_circle(Vector2(28, 50), 15, 20), 1.1, true])
			s.append([[Vector2(43, 50), Vector2(88, 50), Vector2(88, 62)], 1.1, false])
			s.append([[Vector2(74, 50), Vector2(74, 60)], 1.1, false])
		"tag":
			s.append([[Vector2(14, 32), Vector2(58, 32), Vector2(86, 56), Vector2(58, 80), Vector2(14, 80)], 1.1, true])
			s.append([_circle(Vector2(28, 56), 5, 12), 0.9, true])
		"motore":
			s.append([[Vector2(22, 44), Vector2(78, 44), Vector2(78, 84), Vector2(22, 84)], 1.0, true])
			s.append([[Vector2(28, 44), Vector2(28, 30), Vector2(72, 30), Vector2(72, 44)], 1.0, false])
			for x in [38, 50, 62]:
				s.append([[Vector2(x, 30), Vector2(x, 20)], 0.9, false])
			s.append([[Vector2(32, 18), Vector2(68, 18)], 1.0, false])
			s.append([_circle(Vector2(12, 64), 8, 16), 0.9, true])
			s.append([[Vector2(20, 64), Vector2(22, 64)], 0.9, false])
			s.append([[Vector2(78, 56), Vector2(90, 56), Vector2(90, 72), Vector2(78, 72)], 0.9, false])
			s.append([[Vector2(32, 56), Vector2(68, 56)], 0.6, false])
			s.append([[Vector2(32, 70), Vector2(68, 70)], 0.6, false])
		"centralina":
			s.append([[Vector2(28, 28), Vector2(72, 28), Vector2(72, 72), Vector2(28, 72)], 1.1, true])
			s.append([[Vector2(40, 40), Vector2(60, 40), Vector2(60, 60), Vector2(40, 60)], 0.8, true])
			for v in [37, 50, 63]:
				s.append([[Vector2(14, v), Vector2(28, v)], 0.8, false])
				s.append([[Vector2(72, v), Vector2(86, v)], 0.8, false])
				s.append([[Vector2(v, 14), Vector2(v, 28)], 0.8, false])
				s.append([[Vector2(v, 72), Vector2(v, 86)], 0.8, false])
		"scarico":
			s.append([[Vector2(6, 46), Vector2(26, 46)], 1.2, false])
			s.append([_round_rect(Rect2(26, 32, 40, 28), 10), 1.1, true])
			s.append([[Vector2(66, 46), Vector2(80, 46)], 1.2, false])
			s.append([_ellipse(Vector2(86, 46), 6, 9), 1.1, true])
			s.append([_circle(Vector2(78, 74), 6, 14), 0.7, true])
			s.append([_circle(Vector2(64, 82), 8, 16), 0.7, true])
			s.append([_circle(Vector2(90, 84), 5, 12), 0.7, true])
		"nitro":
			s.append([_round_rect(Rect2(34, 36, 32, 56), 7), 1.1, true])
			s.append([[Vector2(34, 40), Vector2(41, 27), Vector2(59, 27), Vector2(66, 40)], 1.0, false])
			s.append([[Vector2(44, 27), Vector2(44, 17), Vector2(56, 17), Vector2(56, 27)], 0.9, false])
			s.append([[Vector2(36, 12), Vector2(64, 12)], 1.1, false])
			s.append([[Vector2(50, 12), Vector2(50, 17)], 0.9, false])
			# A lightning bolt on the bottle.
			s.append([[Vector2(54, 46), Vector2(44, 64), Vector2(54, 64), Vector2(46, 82)], 0.9, false])
		"freni":
			s.append([_circle(Vector2(46, 54), 32, 40), 1.1, true])
			s.append([_circle(Vector2(46, 54), 11, 18), 0.9, true])
			for i in 6:
				var a := TAU * i / 6.0 + 0.3
				s.append([_circle(Vector2(46, 54) + Vector2(cos(a), sin(a)) * 21.0, 2.5, 8), 0.6, true])
			s.append([_arc(Vector2(46, 54), 37, deg_to_rad(-75), deg_to_rad(-5), 10), 2.8, false])
		"sospensioni":
			s.append([[Vector2(28, 14), Vector2(72, 14)], 1.3, false])
			s.append([[Vector2(28, 88), Vector2(72, 88)], 1.3, false])
			var coil: Array = []
			for i in 13:
				coil.append(Vector2(50 + (19 if i % 2 == 0 else -19), 22 + i * 5.3))
			coil[0] = Vector2(50, 18)
			coil[12] = Vector2(50, 84)
			s.append([coil, 1.0, false])
			s.append([[Vector2(50, 4), Vector2(50, 14)], 1.2, false])
			s.append([[Vector2(50, 88), Vector2(50, 97)], 1.2, false])
	return s


static func _circle(c: Vector2, r: float, n: int) -> Array:
	return _ellipse(c, r, r, n)


static func _ellipse(c: Vector2, rx: float, ry: float, n := 18) -> Array:
	var out: Array = []
	for i in n:
		var a := TAU * i / n
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return out


static func _arc(c: Vector2, r: float, a0: float, a1: float, n: int) -> Array:
	var out: Array = []
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		out.append(c + Vector2(cos(a), sin(a)) * r)
	return out


static func _round_rect(r: Rect2, k: float) -> Array:
	var out: Array = []
	var corners := [[r.end - Vector2(k, k), 0.0], [Vector2(r.position.x + k, r.end.y - k), PI / 2],
		[r.position + Vector2(k, k), PI], [Vector2(r.end.x - k, r.position.y + k), PI * 1.5]]
	for c in corners:
		for i in 5:
			var a: float = c[1] + PI / 2 * i / 4.0
			out.append((c[0] as Vector2) + Vector2(cos(a), sin(a)) * k)
	return out


## Draws icon `kind` as glowing neon tubes inside `rect` of canvas item `ci`.
static func draw_icon(ci: CanvasItem, kind: String, rect: Rect2, color: Color, bright := 1.0) -> void:
	var side := minf(rect.size.x, rect.size.y)
	var k := side / 100.0
	var o := rect.position + (rect.size - Vector2(side, side)) * 0.5
	var base := maxf(2.0, side * 0.045)
	var strokes := _strokes(kind)
	# Three passes: wide soft glow, the coloured tube, a white hot core.
	for pass_i in 3:
		for st in strokes:
			var pts := PackedVector2Array()
			for p in st[0]:
				pts.append(o + (p as Vector2) * k)
			if st[2]:
				pts.append(pts[0])
			var w: float = base * st[1]
			match pass_i:
				0:
					ci.draw_polyline(pts, Color(color, 0.16 * bright), w * 3.2, true)
					ci.draw_polyline(pts, Color(color, 0.22 * bright), w * 2.0, true)
				1:
					ci.draw_polyline(pts, Color(color, bright), w, true)
				2:
					ci.draw_polyline(pts, Color(1, 1, 1, 0.75 * bright), w * 0.35, true)


## Text with a dark outline and a soft glow, centred on `center`.
static func draw_text(ci: CanvasItem, text: String, center: Vector2, size: int, color: Color) -> void:
	var f := font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := center + Vector2(-w * 0.5, size * 0.35)
	ci.draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, maxi(4, size / 4), Color(color, 0.25))
	ci.draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, maxi(3, size / 7), INK)
	ci.draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color.lerp(Color.WHITE, 0.25))


## A dark glassy plate with a neon border.
static func plate(color: Color, radius := 18, glow := 10, fill_alpha := 0.72) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.02, 0.07, fill_alpha)
	sb.border_color = color
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(color, 0.45)
	sb.shadow_size = glow
	sb.anti_aliasing = true
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sb.set_content_margin(side, 12)
	return sb


## A button drawn by hand: a plate with a neon border, an icon (optional) and a marker-font
## caption. With `tall` the icon sits on top and the caption under it (the dealer's big icons);
## otherwise it is a pill with the caption in the middle and the icon on its left.
class NeonButton:
	extends Button
	var caption := ""
	var icon_kind := ""
	var neon := Color.WHITE
	var tall := false
	var caption_size := 26
	## Tabs: the selected one is filled.
	var active := false

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		button_down.connect(queue_redraw)
		button_up.connect(queue_redraw)
		resized.connect(queue_redraw)

	func setup(text: String, kind: String, color: Color, is_tall := false, font_size := 26) -> NeonButton:
		caption = text
		icon_kind = kind
		neon = color
		tall = is_tall
		caption_size = font_size
		queue_redraw()
		return self

	func set_caption(text: String, color := Color(0, 0, 0, 0)) -> void:
		caption = text
		if color.a > 0.0:
			neon = color
		queue_redraw()

	func _draw() -> void:
		var c := neon if not disabled else Color(0.55, 0.55, 0.6)
		var lit := 1.0 if not disabled else 0.45
		var hot := is_hovered() or button_pressed or active
		var sb := Neon.plate(c, 22 if tall else int(size.y * 0.5), 14 if hot else 8, 0.8 if not disabled else 0.55)
		if active:
			sb.bg_color = Color(c.r * 0.35, c.g * 0.35, c.b * 0.35, 0.9)
		if is_pressed():
			sb.bg_color = Color(c.r * 0.5, c.g * 0.5, c.b * 0.5, 0.95)
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		if tall:
			var cap_h := caption_size * 1.5
			var icon_rect := Rect2(Vector2(size.x * 0.16, 8), Vector2(size.x * 0.68, size.y - cap_h - 10))
			Neon.draw_icon(self, icon_kind, icon_rect, c, lit)
			Neon.draw_text(self, caption, Vector2(size.x * 0.5, size.y - cap_h * 0.5 - 4), caption_size, c)
		else:
			var text_x := size.x * 0.5
			if icon_kind != "":
				var s := size.y * 0.62
				Neon.draw_icon(self, icon_kind, Rect2(Vector2(size.y * 0.3, (size.y - s) * 0.5), Vector2(s, s)), c, lit)
				text_x += s * 0.45
			Neon.draw_text(self, caption, Vector2(text_x, size.y * 0.5), caption_size, c if not disabled else Color(0.7, 0.7, 0.75))


## Just an icon (the big pictures of the tuning parts).
class NeonIcon:
	extends Control
	var kind := ""
	var neon := Color.WHITE

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		Neon.draw_icon(self, kind, Rect2(Vector2.ZERO, size), neon)


## A round colour swatch; the chosen one has a white ring.
class Swatch:
	extends Button
	var color := Color.WHITE
	var chosen := false

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 4
		if chosen:
			draw_circle(c, r + 4, Color(1, 1, 1, 0.35))
			draw_arc(c, r + 1, 0, TAU, 40, Color.WHITE, 4, true)
		draw_circle(c, r - 2, Color(0, 0, 0, 0.6))
		draw_circle(c, r - 4, color)
		# A highlight, like a drop of glossy paint.
		draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.22, Color(1, 1, 1, 0.35))
