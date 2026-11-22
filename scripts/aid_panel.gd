class_name AidPanel
extends Control
## The two driving-aid keys in the bottom right corner of the race (v0.28, Stefano 22/11/2026):
## "R  ABS" and "T  TCS". Switched on the key is red, switched off it is black at 50%.
## While an aid is correcting the car (for the first tests, Stefano: "mettere in mostra le
## correzioni MENTRE entrano in funzione") its key blinks amber like the warning light on a real
## dashboard, the bar under it shows how hard it is working, the number counts its interventions
## in this race, and a small amber tag lights up in the middle of the screen, next to the dashboard.
## Drawn in code; Main fills the values every frame (set_values).

const KEY_SIZE := Vector2(138, 54)
const GAP := 12.0
const BAR_H := 6.0
const RED := Color(0.86, 0.08, 0.08, 0.95)
const OFF := Color(0.0, 0.0, 0.0, 0.5)
const AMBER := Color(1.0, 0.68, 0.1)
## Seconds a short correction stays on screen as it fades out, so a quick one is still seen.
const FADE := 0.45

var abs_on := true
var tcs_on := true
## How hard each aid is working, 0..1, held for a moment and faded out (see FADE).
var abs_level := 0.0
var tcs_level := 0.0
## Interventions in this race (a new one starts when the aid steps in after a quiet moment).
var abs_count := 0
var tcs_count := 0
var _abs_quiet := 1.0
var _tcs_quiet := 1.0
var _t := 0.0
## The tag in the middle of the screen, a sibling drawn by this panel's values.
var center_tag: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(KEY_SIZE.x * 2.0 + GAP, KEY_SIZE.y + BAR_H + 30.0)
	size = custom_minimum_size


## The state of the aids and how hard they are working right now (raw, 0..1).
func set_values(abs_enabled: bool, tcs_enabled: bool, abs_work: float, tcs_work: float, delta: float) -> void:
	_t += delta
	abs_on = abs_enabled
	tcs_on = tcs_enabled
	if abs_work > 0.05:
		if _abs_quiet > 0.4:
			abs_count += 1
		_abs_quiet = 0.0
	else:
		_abs_quiet += delta
	if tcs_work > 0.05:
		if _tcs_quiet > 0.4:
			tcs_count += 1
		_tcs_quiet = 0.0
	else:
		_tcs_quiet += delta
	abs_level = maxf(abs_work if abs_on else 0.0, abs_level - delta / FADE)
	tcs_level = maxf(tcs_work if tcs_on else 0.0, tcs_level - delta / FADE)
	queue_redraw()
	if center_tag:
		center_tag.queue_redraw()


func _draw() -> void:
	_draw_key(Vector2.ZERO, "R", "ABS", abs_on, abs_level, abs_count)
	_draw_key(Vector2(KEY_SIZE.x + GAP, 0), "T", "TCS", tcs_on, tcs_level, tcs_count)


func _draw_key(at: Vector2, key: String, name: String, on: bool, level: float, count: int) -> void:
	var r := Rect2(at, KEY_SIZE)
	var working := level > 0.02
	# Blinks about 7 times a second while the aid works, like a dashboard warning light.
	var blink := working and fmod(_t * 7.0, 1.0) < 0.5
	var fill := RED if on else OFF
	if blink:
		fill = fill.lerp(AMBER, 0.55)
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(3 if working else 2)
	sb.border_color = AMBER if working else (Color(1, 0.55, 0.5, 0.9) if on else Color(1, 1, 1, 0.25))
	if working:
		sb.shadow_color = Color(AMBER.r, AMBER.g, AMBER.b, 0.6 * level)
		sb.shadow_size = int(6 + 10 * level)
	draw_style_box(sb, r)
	var font := ThemeDB.fallback_font
	var text_col := Color.WHITE if on else Color(1, 1, 1, 0.6)
	# The key letter in a small square, then the name of the aid.
	var kr := Rect2(at + Vector2(9, 11), Vector2(32, 32))
	var ks := StyleBoxFlat.new()
	ks.bg_color = Color(0, 0, 0, 0.35)
	ks.set_corner_radius_all(6)
	ks.set_border_width_all(1)
	ks.border_color = Color(1, 1, 1, 0.5)
	draw_style_box(ks, kr)
	draw_string(font, kr.position + Vector2(0, 24), key, HORIZONTAL_ALIGNMENT_CENTER, kr.size.x, 22, text_col)
	draw_string(font, at + Vector2(48, 36), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, text_col)
	if not on:
		draw_string(font, at + Vector2(98, 35), "OFF", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.55))
	# Under the key: how hard it is working, and how many times it stepped in.
	var bar := Rect2(at + Vector2(0, KEY_SIZE.y + 6), Vector2(KEY_SIZE.x, BAR_H))
	draw_rect(bar, Color(0, 0, 0, 0.45))
	if level > 0.0:
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(level, 0.0, 1.0), BAR_H)), AMBER)
	if on:
		draw_string(font, at + Vector2(0, KEY_SIZE.y + BAR_H + 24), "interventi %d" % count, HORIZONTAL_ALIGNMENT_CENTER, KEY_SIZE.x, 15, Color(1, 1, 1, 0.7))


## The amber tag in the middle of the screen, next to the dashboard: "ABS" and/or "TCS" while they
## correct the car, brighter the harder they work.
class CenterTag:
	extends Control
	var panel: AidPanel

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if panel == null:
			return
		var names := []
		var level := 0.0
		if panel.abs_level > 0.02:
			names.append("ABS")
			level = maxf(level, panel.abs_level)
		if panel.tcs_level > 0.02:
			names.append("TCS")
			level = maxf(level, panel.tcs_level)
		if names.is_empty():
			return
		var text := "  ".join(names)
		var font := ThemeDB.fallback_font
		var fs := 30
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 44
		var r := Rect2(Vector2((size.x - w) * 0.5, 0), Vector2(w, 44))
		var a := clampf(0.45 + level, 0.45, 1.0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.05, 0.03, 0.0, 0.55 * a)
		sb.set_corner_radius_all(22)
		sb.set_border_width_all(2)
		sb.border_color = Color(AMBER.r, AMBER.g, AMBER.b, a)
		sb.shadow_color = Color(AMBER.r, AMBER.g, AMBER.b, 0.35 * level)
		sb.shadow_size = int(4 + 12 * level)
		draw_style_box(sb, r)
		draw_string(font, r.position + Vector2(0, 32), text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, Color(AMBER.r, AMBER.g, AMBER.b, a))
