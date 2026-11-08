class_name Neon
extends RefCounted
## Look of the buttons of the dealer and the garage (icons: see ICON_DIR) (v0.20, Stefano: "più moderni, leggermente
## graffitari"): a small coloured picture and a caption in a marker font (Permanent Marker, Apache
## 2.0, assets/fonts), nothing else. History: neon tubes on dark plates (v0.20), pastel (v0.20.1),
## strong colours (v0.20.3); since v0.20.4 no plate and no border, and the pictures are flat and
## coloured like the map icon of the garage, Stefano's favourite. Pictures are drawn in code, so
## they stay sharp at any size and add nothing to download.

const FONT := "res://assets/fonts/PermanentMarker-Regular.ttf"
const CYAN := Color("35a8ff")
const PINK := Color("ffc247")
const LIME := Color("35a8ff")
const GREEN := Color("65e58b")
const ORANGE := Color(1.0, 0.5, 0.0)
const RED := Color("ff454f")
const YELLOW := Color("ffc247")
const INK := Color(0.03, 0.02, 0.06)


static var _font: Font


static func font() -> Font:
	if not _font:
		_font = load(FONT)
	return _font


## A label in the marker font, coloured, with a dark outline.
static func label(size: int, color: Color, outline := 8) -> Label:
	var l := UiKit.label(size, color, outline)
	l.add_theme_font_override("font", font())
	return l


## Icon names drawn by draw_icon. Since v0.20.4 they are small flat coloured pictures with a dark
## outline, like the map icon of the garage that Stefano liked best.
const PART_ICONS := ["motore", "centralina", "scarico", "nitro", "freni", "sospensioni"]

const _SILVER := Color(0.78, 0.8, 0.84)
const _STEEL := Color(0.5, 0.53, 0.58)
const _DARK := Color(0.16, 0.17, 0.2)
const _CREAM := Color(0.93, 0.88, 0.74)


## Draws a picture inside a square 100 x 100 box placed in `rect`: every shape gets a fill and a
## dark outline.
class _Pen:
	var ci: CanvasItem
	var o: Vector2
	var k: float
	var line: float

	func _init(canvas: CanvasItem, rect: Rect2) -> void:
		ci = canvas
		var side := minf(rect.size.x, rect.size.y)
		k = side / 100.0
		o = rect.position + (rect.size - Vector2(side, side)) * 0.5
		line = maxf(1.5, side * 0.035)

	func pts(a: Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		for p in a:
			out.append(o + (p as Vector2) * k)
		return out

	func poly(a: Array, fill: Color, outline := true) -> void:
		var p := pts(a)
		ci.draw_colored_polygon(p, fill)
		if outline:
			p.append(p[0])
			ci.draw_polyline(p, Neon.INK, line, true)

	func rect(r: Rect2, fill: Color, outline := true) -> void:
		poly([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)], fill, outline)

	func circle(c: Vector2, r: float, fill: Color, outline := true) -> void:
		ci.draw_circle(o + c * k, r * k, fill)
		if outline:
			ci.draw_arc(o + c * k, r * k, 0, TAU, 32, Neon.INK, line, true)

	func bar(a: Vector2, b: Vector2, w: float, fill: Color, outline := true) -> void:
		var n := (b - a).normalized().orthogonal() * w * 0.5
		poly([a + n, b + n, b - n, a - n], fill, outline)

	func stroke(a: Array, w: float, color: Color) -> void:
		ci.draw_polyline(pts(a), color, w * k, true)

	func text(t: String, c: Vector2, size: float, color: Color) -> void:
		var f := Neon.font()
		var fs := int(size * k)
		var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		ci.draw_string(f, o + c * k + Vector2(-w * 0.5, fs * 0.35), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


static func _ring(c: Vector2, r0: float, r1: float, a0: float, a1: float, n := 16) -> Array:
	var out: Array = []
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		out.append(c + Vector2(cos(a), sin(a)) * r1)
	for i in n + 1:
		var a := lerpf(a1, a0, float(i) / n)
		out.append(c + Vector2(cos(a), sin(a)) * r0)
	return out


## Stefano's icon set (v0.20.5, "Nitro UI Icon Pack", assets/ui/icons): metallic line icons with
## a blue, amber, red or green accent. An icon of the set is used when there is one with that
## name; the tuning parts, which the set doesn't have, keep the drawn pictures below.
const ICON_DIR := "res://assets/ui/icons/%s.png"
static var _textures := {}


static func icon_texture(kind: String) -> Texture2D:
	if not _textures.has(kind):
		var path := ICON_DIR % kind
		_textures[kind] = load(path) if kind != "" and ResourceLoader.exists(path) else null
	return _textures[kind]


## Draws icon `kind` in `rect` of canvas item `ci`: from the icon set, or drawn in code.
static func draw_icon(ci: CanvasItem, kind: String, rect: Rect2) -> void:
	var tex := icon_texture(kind)
	if tex:
		var side := minf(rect.size.x, rect.size.y)
		ci.draw_texture_rect(tex, Rect2(rect.position + (rect.size - Vector2(side, side)) * 0.5, Vector2(side, side)), false)
		return
	var p := _Pen.new(ci, rect)
	match kind:
		"garage":
			p.rect(Rect2(16, 40, 68, 52), _CREAM)
			p.poly([Vector2(6, 46), Vector2(50, 10), Vector2(94, 46)], Color(0.85, 0.2, 0.15))
			p.rect(Rect2(30, 54, 40, 38), _STEEL)
			for y in [61, 68, 75, 82]:
				p.stroke([Vector2(32, y), Vector2(68, y)], 2.2, _DARK)
		"spray":
			for d in [[Vector2(70, 14), Color(0.25, 0.6, 1)], [Vector2(80, 8), Color(1, 0.85, 0.1)], [Vector2(84, 20), Color(1, 0.3, 0.6)], [Vector2(92, 10), Color(0.3, 0.9, 0.4)], [Vector2(76, 26), Color(1, 0.55, 0.1)]]:
				p.circle(d[0], 4, d[1], false)
			p.poly([Vector2(30, 40), Vector2(37, 30), Vector2(59, 30), Vector2(66, 40)], _SILVER)
			p.rect(Rect2(30, 40, 36, 52), Color(0.9, 0.15, 0.15))
			p.rect(Rect2(30, 56, 36, 16), Color(0.97, 0.95, 0.9))
			p.rect(Rect2(41, 18, 14, 12), Color(0.97, 0.97, 0.97))
			p.rect(Rect2(45, 11, 8, 7), _DARK)
		"tuning":
			p.poly(_ring(Vector2(70, 28), 8, 17, deg_to_rad(100), deg_to_rad(350)), _SILVER)
			p.bar(Vector2(16, 84), Vector2(60, 40), 12, _SILVER)
			p.bar(Vector2(64, 64), Vector2(22, 22), 6, _SILVER)
			p.bar(Vector2(22, 22), Vector2(14, 14), 9, _STEEL)
			p.bar(Vector2(90, 90), Vector2(64, 64), 17, Color(1, 0.8, 0.1))
			p.stroke([Vector2(84, 78), Vector2(76, 70)], 2.5, Color(0.6, 0.4, 0.0))
		"key":
			p.bar(Vector2(40, 50), Vector2(90, 50), 10, Color(1, 0.8, 0.2))
			p.rect(Rect2(70, 50, 7, 13), Color(1, 0.8, 0.2))
			p.rect(Rect2(82, 50, 7, 10), Color(1, 0.8, 0.2))
			p.circle(Vector2(28, 50), 17, Color(1, 0.8, 0.2))
			p.circle(Vector2(26, 50), 6, _DARK)
		"tag":
			p.poly([Vector2(10, 30), Vector2(58, 30), Vector2(90, 55), Vector2(58, 80), Vector2(10, 80)], Color(1, 0.6, 0.12))
			p.circle(Vector2(24, 55), 5, Color(0.97, 0.97, 0.97))
			p.text("$", Vector2(52, 56), 38, _DARK)
		"car":
			p.poly([Vector2(6, 64), Vector2(10, 50), Vector2(30, 45), Vector2(42, 30), Vector2(70, 30), Vector2(82, 44), Vector2(94, 48), Vector2(95, 64)], Color(0.2, 0.45, 0.95))
			p.poly([Vector2(46, 35), Vector2(66, 35), Vector2(75, 45), Vector2(38, 45)], Color(0.75, 0.9, 1))
			for x in [27, 76]:
				p.circle(Vector2(x, 66), 10, _DARK)
				p.circle(Vector2(x, 66), 4, _SILVER, false)
		"shop":
			p.rect(Rect2(12, 40, 76, 52), _CREAM)
			p.rect(Rect2(22, 8, 56, 18), Color(1, 0.85, 0.15))
			p.text("$", Vector2(50, 18), 22, _DARK)
			for i in 6:
				p.rect(Rect2(8 + i * 14, 28, 14, 16), Color(0.9, 0.15, 0.15) if i % 2 == 0 else Color(0.97, 0.97, 0.97))
			p.rect(Rect2(40, 58, 20, 34), Color(0.45, 0.7, 0.95))
			p.rect(Rect2(18, 52, 16, 16), Color(0.45, 0.7, 0.95))
			p.rect(Rect2(66, 52, 16, 16), Color(0.45, 0.7, 0.95))
		"flag":
			p.bar(Vector2(22, 8), Vector2(22, 96), 6, _STEEL)
			p.rect(Rect2(25, 12, 64, 42), Color.WHITE)
			for r in 4:
				for c in 6:
					if (r + c) % 2 == 0:
						p.rect(Rect2(25 + c * 64.0 / 6.0, 12 + r * 10.5, 64.0 / 6.0, 10.5), _DARK, false)
			p.rect(Rect2(25, 12, 64, 42), Color(0, 0, 0, 0))
		"cash":
			p.rect(Rect2(8, 28, 84, 46), Color(0.3, 0.72, 0.38))
			p.circle(Vector2(50, 51), 15, Color(0.6, 0.9, 0.6))
			p.text("$", Vector2(50, 52), 28, Color(0.1, 0.35, 0.15))
		"check":
			p.poly([Vector2(10, 52), Vector2(24, 40), Vector2(42, 58), Vector2(78, 18), Vector2(92, 30), Vector2(42, 82)], Color(0.2, 0.85, 0.3))
		"undo":
			p.poly(_ring(Vector2(52, 56), 18, 32, deg_to_rad(-200), deg_to_rad(60)), Color(0.3, 0.6, 1))
			p.poly([Vector2(4, 50), Vector2(36, 50), Vector2(20, 72)], Color(0.3, 0.6, 1))
		"motore":
			p.rect(Rect2(20, 44, 60, 42), _STEEL)
			for x in [34, 46, 58]:
				p.rect(Rect2(x, 14, 8, 16), _SILVER)
			p.rect(Rect2(26, 28, 48, 16), Color(0.9, 0.15, 0.15))
			p.rect(Rect2(80, 54, 12, 16), _STEEL)
			p.circle(Vector2(13, 64), 10, _DARK)
			p.circle(Vector2(13, 64), 4, _SILVER, false)
			p.stroke([Vector2(28, 58), Vector2(72, 58)], 2.5, _DARK)
			p.stroke([Vector2(28, 70), Vector2(72, 70)], 2.5, _DARK)
		"centralina":
			p.rect(Rect2(14, 14, 72, 72), Color(0.15, 0.55, 0.3))
			for v in [40, 50, 60]:
				p.rect(Rect2(24, v - 2, 10, 4), Color(1, 0.8, 0.2), false)
				p.rect(Rect2(66, v - 2, 10, 4), Color(1, 0.8, 0.2), false)
				p.rect(Rect2(v - 2, 24, 4, 10), Color(1, 0.8, 0.2), false)
				p.rect(Rect2(v - 2, 66, 4, 10), Color(1, 0.8, 0.2), false)
			p.rect(Rect2(34, 34, 32, 32), Color(0.12, 0.12, 0.14))
			p.circle(Vector2(40, 40), 2.5, _STEEL, false)
		"scarico":
			for c in [[Vector2(80, 74), 7], [Vector2(66, 82), 9], [Vector2(90, 86), 6]]:
				p.circle(c[0], c[1], Color(0.75, 0.76, 0.8))
			p.bar(Vector2(4, 46), Vector2(30, 46), 9, _STEEL)
			p.bar(Vector2(64, 46), Vector2(84, 46), 10, _SILVER)
			p.poly([Vector2(28, 34), Vector2(66, 34), Vector2(70, 46), Vector2(66, 58), Vector2(28, 58), Vector2(24, 46)], _SILVER)
			p.circle(Vector2(87, 46), 8, _DARK)
			p.circle(Vector2(87, 46), 4, Color(1, 0.5, 0.1), false)
		"nitro":
			p.rect(Rect2(45, 12, 10, 14), _SILVER)
			p.bar(Vector2(34, 12), Vector2(66, 12), 6, _DARK)
			p.poly([Vector2(34, 40), Vector2(41, 26), Vector2(59, 26), Vector2(66, 40)], Color(0.15, 0.35, 0.85))
			p.rect(Rect2(34, 38, 32, 54), Color(0.15, 0.35, 0.85))
			p.rect(Rect2(34, 52, 32, 16), Color(0.97, 0.97, 0.97))
			p.text("N2O", Vector2(50, 60), 13, Color(0.9, 0.1, 0.1))
		"freni":
			p.circle(Vector2(46, 54), 33, _SILVER)
			p.circle(Vector2(46, 54), 13, _DARK)
			for i in 6:
				var a := TAU * i / 6.0 + 0.3
				p.circle(Vector2(46, 54) + Vector2(cos(a), sin(a)) * 23.0, 2.5, _STEEL, false)
			p.poly(_ring(Vector2(46, 54), 26, 41, deg_to_rad(-80), deg_to_rad(-5)), Color(0.9, 0.12, 0.12))
		"sospensioni":
			p.rect(Rect2(44, 6, 12, 88), _DARK)
			var coil: Array = []
			for i in 13:
				coil.append(Vector2(50 + (20 if i % 2 == 0 else -20), 20 + i * 5.3))
			p.stroke(coil, 11, Neon.INK)
			p.stroke(coil, 7, Color(1, 0.8, 0.1))
			p.bar(Vector2(26, 14), Vector2(74, 14), 8, _STEEL)
			p.bar(Vector2(26, 88), Vector2(74, 88), 8, _STEEL)


## Text with a dark outline, centred on `center`.
static func draw_text(ci: CanvasItem, text: String, center: Vector2, size: int, color: Color) -> void:
	var f := font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := center + Vector2(-w * 0.5, size * 0.35)
	ci.draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, maxi(3, size / 7), INK)
	ci.draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## A dark glassy plate with a pastel border; `lift` is the size of its soft dark shadow.
static func plate(color: Color, radius := 18, lift := 6, fill_alpha := 0.72) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.02, 0.07, fill_alpha)
	sb.border_color = color
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = lift
	sb.anti_aliasing = true
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sb.set_content_margin(side, 12)
	return sb


## A button drawn by hand: a plate with a coloured border, an icon (optional) and a marker-font
## caption. With `tall` the icon sits on top and the caption under it (the dealer's big icons);
## otherwise it is a pill with the caption in the middle and the icon on its left.
class NeonButton:
	extends Button
	var caption := ""
	var icon_kind := ""
	var neon := Color.WHITE
	var tall := false
	var caption_size := 26
	## Tabs: the selected one is underlined.
	var active := false
	## A second, smaller line under the caption (tall buttons), e.g. the name of the next race.
	var sub := ""

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
		var c := neon if not disabled else Color(0.6, 0.6, 0.62)
		self_modulate.a = 0.5 if disabled else 1.0
		var hot := is_hovered() or active
		# Pressed: everything a little smaller, like a real key going down.
		var sc := 0.94 if is_pressed() else 1.0
		draw_set_transform(size * (1.0 - sc) * 0.5, 0.0, Vector2(sc, sc))
		var text_col := c.lerp(Color.WHITE, 0.25) if hot else c
		if tall:
			var cap_h := caption_size * 1.45
			var sub_h := caption_size * 1.1 if sub != "" else 0.0
			var icon_rect := Rect2(Vector2(size.x * 0.12, 4), Vector2(size.x * 0.76, size.y - cap_h - sub_h - 6))
			Neon.draw_icon(self, icon_kind, icon_rect)
			Neon.draw_text(self, caption, Vector2(size.x * 0.5, size.y - sub_h - cap_h * 0.5), caption_size, text_col)
			if sub != "":
				Neon.draw_text(self, sub, Vector2(size.x * 0.5, size.y - sub_h * 0.5), int(caption_size * 0.8), Color.WHITE)
		else:
			var text_x := size.x * 0.5
			if icon_kind != "":
				var s := size.y * 0.85
				Neon.draw_icon(self, icon_kind, Rect2(Vector2(size.y * 0.05, (size.y - s) * 0.5), Vector2(s, s)))
				text_x += s * 0.5
			Neon.draw_text(self, caption, Vector2(text_x, size.y * 0.5), caption_size, text_col)
		if active:
			# Selected tab: a thick line of its colour under the caption.
			var w := minf(size.x * 0.8, Neon.font().get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, caption_size).x + 30)
			var x0 := size.x * 0.5 - w * 0.5 + (size.y * 0.42 if icon_kind != "" else 0.0)
			draw_rect(Rect2(x0 - 1, size.y - 7, w + 2, 7), Neon.INK)
			draw_rect(Rect2(x0, size.y - 6, w, 5), c)
		draw_set_transform(Vector2.ZERO)


## Just an icon (the big pictures of the tuning parts).
class NeonIcon:
	extends Control
	var kind := ""
	var neon := Color.WHITE

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		Neon.draw_icon(self, kind, Rect2(Vector2.ZERO, size))


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
