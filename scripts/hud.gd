class_name Hud
extends CanvasLayer
## Touch controls, race info, menu and end screen. Everything is built in code.

signal mode_chosen(mode: String)
signal restart_pressed
signal menu_pressed
## Garage: the player asked for the previous (-1) or next (+1) car.
signal car_step(dir: int)
## Title screen: switch to the next look (realistic, anime, 2.5D comic).
signal style_toggled

const ACCENT := Color(1, 0.18, 0.55)
const CYAN := Color(0.1, 0.9, 1)

var root: Control
var touch: Node2D
var dashboard: Dashboard
var info_label: Label
var message_label: Label
var heat_label: Label
var heat_boxes: Array[ColorRect] = []
var escape_bar: ProgressBar
var menu_panel: Control
var end_panel: Control
var end_title: Label
var end_text: Label
var car_name_label: Label
var pause: Button
var loading_panel: Control
var loading_bar: ProgressBar
var loading_label: Label
var car_index_label: Label
var speed_lines: ColorRect  # drawn styles only
var _buttons: Dictionary = {}
var _message_t := 0.0


func _ready() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	if AnimeStyle.enabled:
		speed_lines = AnimeStyle.make_speed_lines()
		root.add_child(speed_lines)

	dashboard = Dashboard.new()
	root.add_child(dashboard)

	info_label = _label(26, Color.WHITE)
	info_label.position = Vector2(24, 18)

	message_label = _label(48, Color(1, 0.85, 0.2))
	message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.offset_left = -500
	message_label.offset_right = 500
	message_label.offset_top = 120
	message_label.offset_bottom = 200

	heat_label = _label(22, Color(0.8, 0.85, 1))
	heat_label.text = "POLIZIA"
	heat_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	heat_label.offset_left = -330
	heat_label.offset_top = 20
	for i in 5:
		var r := ColorRect.new()
		r.size = Vector2(26, 26)
		r.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		r.offset_left = -215 + i * 34
		r.offset_top = 22
		r.offset_right = r.offset_left + 26
		r.offset_bottom = r.offset_top + 26
		root.add_child(r)
		heat_boxes.append(r)

	escape_bar = _bar(Color(0.3, 1, 0.5))
	escape_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	escape_bar.offset_left = -330
	escape_bar.offset_right = -30
	escape_bar.offset_top = 60
	escape_bar.offset_bottom = 76
	escape_bar.visible = false

	pause = Button.new()
	pause.text = "MENU"
	pause.add_theme_font_size_override("font_size", 22)
	pause.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause.offset_left = -130
	pause.offset_right = -24
	pause.offset_top = 90
	pause.offset_bottom = 140
	pause.pressed.connect(func(): menu_pressed.emit())
	root.add_child(pause)

	touch = Node2D.new()
	add_child(touch)
	_make_touch("steer_left", "", 0, CYAN)
	_make_touch("steer_right", "", 1, CYAN)
	_make_touch("throttle", "GAS", 2, Color(0.3, 1, 0.45))
	_make_touch("brake", "FRENO", 3, Color(1, 0.3, 0.3))
	_make_touch("handbrake", "DERAPA", 4, Color(1, 0.75, 0.2))
	_make_touch("nitro", "NITRO", 5, Color(0.3, 0.6, 1))
	_build_menu()
	_build_end()
	_build_loading()
	get_viewport().size_changed.connect(_layout)
	_layout()


func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(l)
	return l


func _bar(color: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.max_value = 1.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	bg.set_corner_radius_all(6)
	var fg := StyleBoxFlat.new()
	fg.bg_color = color
	fg.set_corner_radius_all(6)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(b)
	return b


static func _circle(radius: int, color: Color, arrow: int) -> ImageTexture:
	var size := radius * 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var p := Vector2(x - radius + 0.5, y - radius + 0.5)
			var d := p.length()
			var c := Color(0, 0, 0, 0)
			if d < radius - 5:
				c = Color(color.r, color.g, color.b, 0.22)
			elif d < radius:
				c = Color(color.r, color.g, color.b, 0.85)
			# Steering arrows: a triangle pointing left (-1) or right (+1).
			if arrow != 0:
				var ax := p.x * arrow
				if ax > -radius * 0.3 and ax < radius * 0.35 and absf(p.y) < (radius * 0.35 - ax) * 0.9:
					c = Color(1, 1, 1, 0.9)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _make_touch(action: String, text: String, slot: int, color: Color) -> void:
	var radius := 78
	var arrow := -1 if action == "steer_left" else (1 if action == "steer_right" else 0)
	var b := TouchScreenButton.new()
	b.texture_normal = _circle(radius, color, arrow)
	b.texture_pressed = _circle(radius, color.lightened(0.5), arrow)
	b.action = action
	b.passby_press = true
	b.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	var shape := CircleShape2D.new()
	shape.radius = radius
	b.shape = shape
	b.shape_centered = true
	if text != "":
		var l := Label.new()
		l.text = text
		l.add_theme_font_size_override("font_size", 24)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size = Vector2(radius * 2, radius * 2)
		b.add_child(l)
	touch.add_child(b)
	_buttons[slot] = b


func _layout() -> void:
	var s := root.get_viewport_rect().size
	var d := 156.0
	var bottom := s.y - d - 26.0
	(_buttons[0] as Node2D).position = Vector2(30, bottom)
	(_buttons[1] as Node2D).position = Vector2(30 + d + 24, bottom)
	# Right thumb: GAS in the corner, FRENO beside it, NITRO above GAS and DERAPA above FRENO.
	(_buttons[2] as Node2D).position = Vector2(s.x - d - 30, bottom)
	(_buttons[3] as Node2D).position = Vector2(s.x - 2 * d - 54, bottom)
	(_buttons[4] as Node2D).position = Vector2(s.x - 2 * d - 54, bottom - d - 24)
	(_buttons[5] as Node2D).position = Vector2(s.x - d - 30, bottom - d - 24)
	dashboard.size = Vector2(260, 200)
	dashboard.position = Vector2((s.x - dashboard.size.x) / 2.0, s.y - dashboard.size.y - 6.0)


func show_controls(on: bool) -> void:
	touch.visible = on
	dashboard.visible = on


func set_heat(heat: float) -> void:
	for i in 5:
		var on := heat > i
		heat_boxes[i].color = (Color(1, 0.15, 0.15) if i % 2 == 0 else Color(0.2, 0.4, 1)) if on else Color(1, 1, 1, 0.15)


func flash(text: String, seconds := 2.5) -> void:
	message_label.text = text
	message_label.modulate.a = 1.0
	_message_t = seconds


func _process(delta: float) -> void:
	if _message_t > 0.0:
		_message_t -= delta
		if _message_t < 0.5:
			message_label.modulate.a = maxf(_message_t / 0.5, 0.0)


# ---------- Menu and end screen ----------

func _panel_base() -> VBoxContainer:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.01, 0.06, 0.72)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	box.custom_minimum_size = Vector2(620, 0)
	box.offset_left = -310
	box.offset_right = 310
	box.offset_top = -260
	box.offset_bottom = 260
	bg.add_child(box)
	return box


func _big_button(parent: Control, text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 84)
	b.add_theme_font_size_override("font_size", 32)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color.r, color.g, color.b, 0.25)
	sb.border_color = color
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	var sb_hover := sb.duplicate()
	sb_hover.bg_color = Color(color.r, color.g, color.b, 0.5)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb_hover)
	b.add_theme_stylebox_override("pressed", sb_hover)
	b.add_theme_stylebox_override("focus", sb)
	parent.add_child(b)
	return b


## Title screen with the garage: the chosen car turns on the road behind the menu (main.gd);
## arrows or a sideways swipe change it, the two buttons start a race with it.
func _build_menu() -> void:
	menu_panel = Control.new()
	menu_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(menu_panel)

	var top := ColorRect.new()
	top.color = Color(0.02, 0.01, 0.06, 0.6)
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 130
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_panel.add_child(top)
	var title := Label.new()
	title.text = "NITRO UNDERGROUND"
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_color_override("font_outline_color", CYAN)
	title.add_theme_constant_override("outline_size", 4)
	top.add_child(title)
	var style := _big_button(top, "STILE: " + AnimeStyle.style_name(), CYAN)
	style.custom_minimum_size = Vector2(0, 0)
	style.add_theme_font_size_override("font_size", 22)
	style.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	style.offset_left = -340
	style.offset_right = -20
	style.offset_top = 36
	style.offset_bottom = 94
	style.pressed.connect(func(): style_toggled.emit())

	var bottom := ColorRect.new()
	bottom.color = Color(0.02, 0.01, 0.06, 0.65)
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -270
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_panel.add_child(bottom)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 40
	box.offset_right = -40
	box.offset_top = 14
	box.offset_bottom = -18
	box.add_theme_constant_override("separation", 14)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	var prev := _big_button(row, "<", CYAN)
	prev.custom_minimum_size = Vector2(120, 96)
	prev.pressed.connect(func(): car_step.emit(-1))
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(names)
	car_name_label = Label.new()
	car_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	car_name_label.add_theme_font_size_override("font_size", 44)
	car_name_label.add_theme_color_override("font_color", Color.WHITE)
	names.add_child(car_name_label)
	car_index_label = Label.new()
	car_index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	car_index_label.add_theme_font_size_override("font_size", 22)
	car_index_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
	names.add_child(car_index_label)
	var next := _big_button(row, ">", CYAN)
	next.custom_minimum_size = Vector2(120, 96)
	next.pressed.connect(func(): car_step.emit(1))

	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 24)
	modes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(modes)
	var sprint := _big_button(modes, "GARA SPRINT", ACCENT)
	sprint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sprint.pressed.connect(func(): mode_chosen.emit("sprint"))
	var escape := _big_button(modes, "FUGA DALLA POLIZIA", CYAN)
	escape.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	escape.pressed.connect(func(): mode_chosen.emit("escape"))


## Full-screen loading page with a progress bar, shown while the level and the cars are built.
func _build_loading() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.07)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	loading_panel = bg
	var title := Label.new()
	title.text = "NITRO UNDERGROUND"
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_left = -500
	title.offset_right = 500
	title.offset_top = -150
	title.offset_bottom = -60
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_color_override("font_outline_color", CYAN)
	title.add_theme_constant_override("outline_size", 4)
	bg.add_child(title)
	loading_bar = ProgressBar.new()
	loading_bar.show_percentage = false
	loading_bar.max_value = 1.0
	var back := StyleBoxFlat.new()
	back.bg_color = Color(1, 1, 1, 0.08)
	back.border_color = Color(CYAN.r, CYAN.g, CYAN.b, 0.6)
	back.set_border_width_all(2)
	back.set_corner_radius_all(10)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ACCENT
	fill.set_corner_radius_all(10)
	loading_bar.add_theme_stylebox_override("background", back)
	loading_bar.add_theme_stylebox_override("fill", fill)
	loading_bar.set_anchors_preset(Control.PRESET_CENTER)
	loading_bar.offset_left = -360
	loading_bar.offset_right = 360
	loading_bar.offset_top = -10
	loading_bar.offset_bottom = 26
	bg.add_child(loading_bar)
	loading_label = Label.new()
	loading_label.set_anchors_preset(Control.PRESET_CENTER)
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.offset_left = -500
	loading_label.offset_right = 500
	loading_label.offset_top = 40
	loading_label.offset_bottom = 90
	loading_label.add_theme_font_size_override("font_size", 26)
	loading_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	bg.add_child(loading_label)
	bg.visible = false


func show_loading(text: String, progress: float) -> void:
	loading_panel.visible = true
	loading_bar.value = progress
	loading_label.text = "Caricamento: %s   %d%%" % [text, roundi(progress * 100.0)]


func hide_loading() -> void:
	loading_panel.visible = false


func set_car(car_name: String, index: int, total: int) -> void:
	car_name_label.text = car_name
	car_index_label.text = "%d / %d   (scorri o usa le frecce)" % [index + 1, total]


func _build_end() -> void:
	var box := _panel_base()
	end_panel = box.get_parent()
	end_title = Label.new()
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title.add_theme_font_size_override("font_size", 64)
	box.add_child(end_title)
	end_text = Label.new()
	end_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_text.add_theme_font_size_override("font_size", 28)
	end_text.add_theme_color_override("font_color", Color(0.85, 0.87, 0.95))
	box.add_child(end_text)
	_big_button(box, "RIPROVA", ACCENT).pressed.connect(func(): restart_pressed.emit())
	_big_button(box, "MENU", CYAN).pressed.connect(func(): menu_pressed.emit())
	end_panel.visible = false


func show_menu(on: bool) -> void:
	menu_panel.visible = on
	pause.visible = not on
	show_controls(not on)
	info_label.visible = not on
	heat_label.visible = not on
	for r in heat_boxes:
		r.visible = not on


func show_end(won: bool, title: String, text: String) -> void:
	end_title.text = title
	end_title.add_theme_color_override("font_color", Color(0.3, 1, 0.5) if won else Color(1, 0.3, 0.3))
	end_text.text = text
	end_panel.visible = true
	show_controls(false)
