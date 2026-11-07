extends Control
## Waiting page, the first thing the game shows (v0.18): Stefano's title picture and one START
## button at the bottom centre, which opens the garage (scenes/menu.tscn). Nothing else is loaded.

const GARAGE_SCENE := "res://scenes/menu.tscn"
const BACKGROUND := "res://assets/ui/title.jpg"

var _start: Button
var _leaving := false
var _t := 0.0


func _ready() -> void:
	DisplayServer.screen_set_keep_on(true)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_viewport().disable_3d = true
	var bg := TextureRect.new()
	bg.texture = load(BACKGROUND)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_start = Button.new()
	_start.text = "START"
	_start.focus_mode = Control.FOCUS_NONE
	_start.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_start.offset_left = -170
	_start.offset_right = 170
	_start.offset_top = -120
	_start.offset_bottom = -32
	_start.pivot_offset = Vector2(170, 44)
	_start.add_theme_font_size_override("font_size", 46)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_start.add_theme_color_override(state, Color.WHITE)
	_start.add_theme_color_override("font_outline_color", Color(0.1, 0.02, 0.0))
	_start.add_theme_constant_override("outline_size", 10)
	var normal := _box(Color(0.85, 0.15, 0.05, 0.92))
	var on := _box(Color(1, 0.45, 0.1))
	_start.add_theme_stylebox_override("normal", normal)
	_start.add_theme_stylebox_override("hover", normal)
	_start.add_theme_stylebox_override("focus", normal)
	_start.add_theme_stylebox_override("pressed", on)
	_start.pressed.connect(_go)
	add_child(_start)

	for a in OS.get_cmdline_user_args():
		if a.begins_with("--titleshot="):
			# Test aid: picture of the waiting page.
			await get_tree().create_timer(2.0).timeout
			get_viewport().get_texture().get_image().save_png(a.substr(12))
			get_tree().quit()
		if a == "--skiptitle" or a.begins_with("--menu"):
			# Test aid: straight to the garage.
			_go.call_deferred()


func _box(fill: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = Color(1, 0.85, 0.3)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 10
	return sb


## The button breathes gently so it is clear where to tap.
func _process(delta: float) -> void:
	_t += delta
	_start.scale = Vector2.ONE * (1.0 + 0.04 * sin(_t * 3.0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_go()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not _leaving:
		get_tree().quit()


func _go() -> void:
	if _leaving:
		return
	_leaving = true
	get_tree().change_scene_to_file(GARAGE_SCENE)
