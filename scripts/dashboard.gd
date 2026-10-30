class_name Dashboard
extends Control
## Digital dashboard at the bottom of the screen: rev counter arc with the red line, speed in big
## digits, the gear in use and the nitro tank. Drawn in code; main.gd fills the values each frame.

const ARC_FROM := deg_to_rad(150.0)
const ARC_TO := deg_to_rad(390.0)
const SEGMENTS := 40
const REDLINE := 0.86  # share of the rev range drawn in red
const CYAN := Color(0.1, 0.9, 1)
const RED := Color(1, 0.2, 0.3)
const NITRO := Color(0.3, 0.6, 1)

var speed_kmh := 0.0
var rpm := 0.0
var max_rpm := 8000.0
var gear := 1
var nitro := 1.0
var nitro_on := false
var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(260, 200)
	_font = ThemeDB.fallback_font


func set_values(kmh: float, revs: float, top_revs: float, in_gear: int, tank: float, boosting: bool) -> void:
	speed_kmh = kmh
	rpm = revs
	max_rpm = top_revs
	gear = in_gear
	nitro = tank
	nitro_on = boosting
	queue_redraw()


func _draw() -> void:
	var c := Vector2(size.x / 2.0, size.y * 0.56)
	var r := minf(size.x / 2.0, size.y * 0.56) - 8.0
	# Dark disc behind the gauge so it reads on any background.
	draw_circle(c, r + 6.0, Color(0.02, 0.02, 0.06, 0.62))

	# Rev counter: lit segments up to the current revs, red ones past the red line.
	var revs := clampf(rpm / max_rpm, 0.0, 1.0)
	var step := (ARC_TO - ARC_FROM) / SEGMENTS
	for i in SEGMENTS:
		var t := float(i) / SEGMENTS
		var a0 := ARC_FROM + i * step + step * 0.12
		var a1 := ARC_FROM + (i + 1) * step - step * 0.12
		var lit := t < revs
		var col := RED if t >= REDLINE else CYAN
		if not lit:
			col = Color(col.r, col.g, col.b, 0.16)
		draw_arc(c, r - 8.0, a0, a1, 4, col, 12.0, true)
	# Thousands marks.
	var thousands := int(max_rpm / 1000.0)
	for k in thousands + 1:
		var a := ARC_FROM + (ARC_TO - ARC_FROM) * (k * 1000.0 / max_rpm)
		var p := c + Vector2(cos(a), sin(a)) * (r - 32.0)
		_text(str(k), p, 15, Color(1, 1, 1, 0.6))

	# Nitro tank: inner arc, bright while the boost is on.
	var n_col := NITRO.lightened(0.4) if nitro_on else NITRO
	draw_arc(c, r - 46.0, ARC_FROM, ARC_TO, 48, Color(NITRO.r, NITRO.g, NITRO.b, 0.15), 7.0, true)
	if nitro > 0.01:
		draw_arc(c, r - 46.0, ARC_FROM, ARC_FROM + (ARC_TO - ARC_FROM) * nitro, 48, n_col, 7.0, true)
	_text("NITRO", c + Vector2(0, r - 4.0), 14, n_col)

	# Speed in the middle, gear below it.
	_text("%d" % roundi(speed_kmh), c + Vector2(0, -6), 64, Color.WHITE)
	_text("km/h", c + Vector2(0, 30), 18, Color(0.75, 0.8, 0.9))
	var g := "R" if gear < 0 else ("N" if gear == 0 else str(gear))
	var box := Rect2(c + Vector2(-24, 46), Vector2(48, 46))
	draw_rect(box, Color(0.02, 0.02, 0.06, 0.8))
	draw_rect(box, RED if rpm / max_rpm > REDLINE else CYAN, false, 2.0)
	_text(g, box.get_center() + Vector2(0, 2), 34, Color.WHITE)


## Draws text centred on `p` (horizontally and vertically).
func _text(s: String, p: Vector2, font_size: int, col: Color) -> void:
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var base := p + Vector2(-w.x / 2.0, _font.get_ascent(font_size) / 2.0 - _font.get_descent(font_size) / 2.0)
	draw_string_outline(_font, base, s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color(0, 0, 0, 0.8))
	draw_string(_font, base, s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
