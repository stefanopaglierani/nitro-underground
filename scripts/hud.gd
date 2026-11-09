class_name Hud
extends CanvasLayer
## Touch controls, race info, countdown clock, loading page and end screen of the race scene.
## Everything is built in code. The title screen is a separate scene (menu.gd).

signal restart_pressed
signal menu_pressed
## The MENU button in the race: the game pauses (see Main.pause_race).
signal pause_pressed
signal resume_pressed

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
var end_panel: Control
var end_title: Label
var end_text: Label
var pause: Button
## "GARA IN PAUSA" panel with MENÙ and RIPRENDI GARA, over the frozen race.
var pause_panel: Control
var minimap: Minimap
const MINIMAP_SIZE := 200.0
## Loading page (v0.17): the inside of the garage seen from the bonnet, with the roller door that
## opens as the loading goes on (pictures made by tools/art/garage_images.py).
var loading_panel: Control
var loading_label: Label
var loading_percent: Label
var _loading_stage: Control
var _door: TextureRect
var _floor_shade: ColorRect
var _door_target := 0.0
var _door_shown := 0.0
var speed_lines: ColorRect
## Countdown clock, big at the top centre, and the "+N s" that pops up under it at a checkpoint.
var clock_label: Label
var clock_bonus_label: Label
var _bonus_t := 0.0
var _buttons: Dictionary = {}
var _message_t := 0.0
var wrong_way_label: Label
## "Derapata x2  +40 REP": reputation just earned, under the MENU button (v0.18).
var rep_label: Label
var _rep_t := 0.0
var _wrong_way_t := 0.0


func _ready() -> void:
	# Keeps working while the race is paused, so the pause panel can be used.
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	speed_lines = ComicStyle.make_speed_lines()
	root.add_child(speed_lines)

	dashboard = Dashboard.new()
	root.add_child(dashboard)

	# Map of the circuit in the top left corner, the race info under it (v0.17).
	minimap = Minimap.new()
	minimap.position = Vector2(16, 14)
	minimap.size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	root.add_child(minimap)
	info_label = _label(24, Color.WHITE)
	info_label.position = Vector2(22, MINIMAP_SIZE + 20)

	message_label = _label(48, Color(1, 0.85, 0.2))
	message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.offset_left = -500
	message_label.offset_right = 500
	message_label.offset_top = 150
	message_label.offset_bottom = 230

	clock_label = _label(64, Color.WHITE)
	clock_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_label.offset_left = -200
	clock_label.offset_right = 200
	clock_label.offset_top = 6
	clock_label.offset_bottom = 86
	clock_label.add_theme_constant_override("outline_size", 12)
	clock_bonus_label = _label(34, Color(0.3, 1, 0.5))
	clock_bonus_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	clock_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_bonus_label.offset_left = -200
	clock_bonus_label.offset_right = 200
	clock_bonus_label.offset_top = 84
	clock_bonus_label.offset_bottom = 130
	clock_bonus_label.visible = false

	# Red warning in the middle of the screen when the player drives against the race (v0.16).
	wrong_way_label = _label(56, Color(1, 0.15, 0.1))
	wrong_way_label.text = "SENSO DI MARCIA SBAGLIATO"
	wrong_way_label.set_anchors_preset(Control.PRESET_CENTER)
	wrong_way_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wrong_way_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wrong_way_label.offset_left = -600
	wrong_way_label.offset_right = 600
	wrong_way_label.offset_top = -60
	wrong_way_label.offset_bottom = 20
	wrong_way_label.add_theme_constant_override("outline_size", 14)
	wrong_way_label.visible = false

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

	rep_label = _label(28, Color(0.45, 0.8, 1))
	rep_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	rep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rep_label.offset_left = -520
	rep_label.offset_right = -24
	rep_label.offset_top = 150
	rep_label.offset_bottom = 190
	rep_label.visible = false

	pause = Button.new()
	pause.text = "MENU"
	pause.add_theme_font_size_override("font_size", 22)
	pause.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause.offset_left = -130
	pause.offset_right = -24
	pause.offset_top = 90
	pause.offset_bottom = 140
	pause.pressed.connect(func(): pause_pressed.emit())
	root.add_child(pause)

	touch = Node2D.new()
	add_child(touch)
	_make_touch("steer_left", 0, CYAN, BTN_BIG)
	_make_touch("steer_right", 1, CYAN, BTN_BIG)
	_make_touch("throttle", 2, Color(0.3, 1, 0.45), BTN_BIG)
	_make_touch("brake", 3, Color(1, 0.3, 0.3), BTN_BIG)
	_make_touch("handbrake", 4, Color(1, 0.75, 0.2), BTN_SMALL)
	_make_touch("nitro", 5, Color(0.3, 0.6, 1), BTN_SMALL)
	_build_end()
	_build_pause()
	_build_loading()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_show_race_info(false)


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


## Touch buttons: a hexagon with a drawn icon, made from SVG at the size it is shown.
const HEX := "M50 3 L90.7 26.5 L90.7 73.5 L50 97 L9.3 73.5 L9.3 26.5 Z"
const ICONS := {
	# Steering: a bold arrow.
	"steer_left": "<path d='M64 24 L30 50 L64 76 Z' fill='#fff' stroke='#fff' stroke-width='8' stroke-linejoin='round'/>",
	"steer_right": "<path d='M36 24 L70 50 L36 76 Z' fill='#fff' stroke='#fff' stroke-width='8' stroke-linejoin='round'/>",
	# Accelerator: a tall narrow pedal with grooves.
	"throttle": "<rect x='37' y='20' width='26' height='60' rx='7' fill='#fff'/>"
		+ "<g stroke='#000' stroke-opacity='0.45' stroke-width='3.5' stroke-linecap='round'>"
		+ "<line x1='43' y1='32' x2='57' y2='32'/><line x1='43' y1='42' x2='57' y2='42'/>"
		+ "<line x1='43' y1='52' x2='57' y2='52'/><line x1='43' y1='62' x2='57' y2='62'/></g>",
	# Brake: a wide pedal on its arm, with grooves.
	"brake": "<line x1='50' y1='18' x2='50' y2='40' stroke='#fff' stroke-width='7' stroke-linecap='round'/>"
		+ "<rect x='24' y='38' width='52' height='34' rx='8' fill='#fff'/>"
		+ "<g stroke='#000' stroke-opacity='0.45' stroke-width='3.5' stroke-linecap='round'>"
		+ "<line x1='32' y1='48' x2='68' y2='48'/><line x1='32' y1='56' x2='68' y2='56'/>"
		+ "<line x1='32' y1='64' x2='68' y2='64'/></g>",
	# Handbrake: the lever on its base, with the release button on the tip.
	"handbrake": "<rect x='20' y='68' width='60' height='12' rx='4' fill='#fff'/>"
		+ "<line x1='34' y1='70' x2='68' y2='32' stroke='#fff' stroke-width='12' stroke-linecap='round'/>"
		+ "<circle cx='70' cy='29' r='7' fill='#fff' stroke='#000' stroke-opacity='0.4' stroke-width='3'/>"
		+ "<circle cx='34' cy='70' r='6' fill='#000' fill-opacity='0.4'/>",
	# NOS: a gas bottle with its valve and a band.
	"nitro": "<rect x='41' y='14' width='18' height='7' rx='2' fill='#fff'/>"
		+ "<rect x='45' y='20' width='10' height='10' fill='#fff'/>"
		+ "<rect x='33' y='28' width='34' height='58' rx='12' fill='#fff'/>"
		+ "<rect x='33' y='48' width='34' height='12' fill='#000' fill-opacity='0.4'/>"
		+ "<line x1='59' y1='17' x2='72' y2='17' stroke='#fff' stroke-width='5' stroke-linecap='round'/>",
}
## Button size (hexagon height) in pixels at the 720 px reference height.
const BTN_BIG := 110.0
const BTN_SMALL := 92.0


static func _hex_texture(action: String, color: Color, size: float, pressed: bool) -> ImageTexture:
	var col := color.to_html(false)
	var fill_a := 0.6 if pressed else 0.28
	var svg := "<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100' viewBox='0 0 100 100'>"
	svg += "<path d='%s' fill='#%s' fill-opacity='%.2f' stroke='#%s' stroke-width='5' stroke-linejoin='round'/>" % [HEX, col, fill_a, col]
	svg += "<g opacity='%.2f' transform='translate(50 50) scale(0.82) translate(-50 -50)'>%s</g>" % [1.0 if pressed else 0.92, ICONS[action]]
	svg += "</svg>"
	var img := Image.new()
	img.load_svg_from_string(svg, size / 100.0)
	return ImageTexture.create_from_image(img)


func _make_touch(action: String, slot: int, color: Color, size: float) -> void:
	var b := TouchScreenButton.new()
	b.texture_normal = _hex_texture(action, color, size, false)
	b.texture_pressed = _hex_texture(action, color.lightened(0.35), size, true)
	b.action = action
	b.passby_press = true
	b.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	var shape := CircleShape2D.new()
	shape.radius = size * 0.5
	b.shape = shape
	b.shape_centered = true
	touch.add_child(b)
	_buttons[slot] = b


func _layout() -> void:
	var s := root.get_viewport_rect().size
	var big := BTN_BIG
	var small := BTN_SMALL
	var gap := 14.0
	var bottom := s.y - big - 22.0
	var raised := bottom - small - 6.0
	# Left thumb: the two steering arrows, with NOS just above between them, so the right thumb
	# can stay on the accelerator.
	(_buttons[0] as Node2D).position = Vector2(28, bottom)
	(_buttons[1] as Node2D).position = Vector2(28 + big + gap, bottom)
	(_buttons[5] as Node2D).position = Vector2(28 + big + gap * 0.5 - small * 0.5, raised)
	# Right thumb: accelerator in the corner, brake beside it, handbrake above between them.
	(_buttons[2] as Node2D).position = Vector2(s.x - big - 28, bottom)
	(_buttons[3] as Node2D).position = Vector2(s.x - 2 * big - gap - 28, bottom)
	(_buttons[4] as Node2D).position = Vector2(s.x - big - 28 - gap * 0.5 - small * 0.5, raised)
	_layout_loading(s)
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


## Shows or hides the blinking wrong-way warning.
func set_wrong_way(on: bool) -> void:
	if on and not wrong_way_label.visible:
		_wrong_way_t = 0.0
	wrong_way_label.visible = on


## Shows the reputation just earned for a moment.
func rep_popup(text: String) -> void:
	rep_label.text = text
	rep_label.visible = true
	rep_label.modulate.a = 1.0
	_rep_t = 2.0


func _process(delta: float) -> void:
	_animate_door(delta)
	if _rep_t > 0.0:
		_rep_t -= delta
		rep_label.modulate.a = clampf(_rep_t / 0.5, 0.0, 1.0)
		rep_label.visible = _rep_t > 0.0
	if wrong_way_label.visible:
		_wrong_way_t += delta
		wrong_way_label.modulate.a = 1.0 if fmod(_wrong_way_t, 0.8) < 0.55 else 0.25
	if _message_t > 0.0:
		_message_t -= delta
		if _message_t < 0.5:
			message_label.modulate.a = maxf(_message_t / 0.5, 0.0)
	if _bonus_t > 0.0:
		_bonus_t -= delta
		clock_bonus_label.modulate.a = clampf(_bonus_t / 0.6, 0.0, 1.0)
		clock_label.scale = Vector2.ONE * (1.0 + 0.25 * clampf(_bonus_t - 1.2, 0.0, 0.6) / 0.6)
		clock_bonus_label.visible = _bonus_t > 0.0


## Countdown clock: white, yellow under 10 seconds, blinking red under 5.
func set_clock(seconds: float) -> void:
	clock_label.text = "%d.%d" % [int(seconds), int(fmod(seconds, 1.0) * 10.0)] if seconds < 10.0 else "%d" % ceili(seconds)
	var col := Color.WHITE
	if seconds < 5.0:
		col = Color(1, 0.2, 0.2) if fmod(seconds, 0.5) > 0.2 else Color(1, 0.75, 0.75)
	elif seconds < 10.0:
		col = Color(1, 0.85, 0.2)
	clock_label.add_theme_color_override("font_color", col)


## Time added at a checkpoint: "+N s" under the clock, which jumps a little.
func clock_bonus(seconds: float) -> void:
	clock_bonus_label.text = "+%d s" % roundi(seconds)
	clock_bonus_label.visible = true
	clock_label.pivot_offset = clock_label.size / 2.0
	_bonus_t = 1.8


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


## Picture of the garage behind the loading page, in its own pixels.
const LOADING_PIC := "res://assets/ui/loading_garage.jpg"
const LOADING_DOOR := "res://assets/ui/loading_door.png"
const LOADING_PIC_SIZE := Vector2(1672, 941)
## The roller door in the picture: its columns, where its bottom edge is at 100% (as in the
## picture) and at 0% (closed, on the floor).
const DOOR_LEFT := 388.0
const DOOR_RIGHT := 1332.0
const DOOR_OPEN_Y := 258.0
const DOOR_CLOSED_Y := 590.0


## Full-screen loading page: the garage seen from the bonnet; the roller door is the loading bar,
## it goes up as the percentage grows, and the light from outside comes in with it.
func _build_loading() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	loading_panel = bg
	# The picture and the door live in the picture's own pixels, scaled to cover the screen.
	_loading_stage = Control.new()
	_loading_stage.size = LOADING_PIC_SIZE
	_loading_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(_loading_stage)
	var pic := TextureRect.new()
	pic.texture = load(LOADING_PIC)
	pic.size = LOADING_PIC_SIZE
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_stage.add_child(pic)
	# The floor and the bonnet only catch the sun once the door is up.
	_floor_shade = ColorRect.new()
	_floor_shade.position = Vector2(0, DOOR_CLOSED_Y)
	_floor_shade.size = Vector2(LOADING_PIC_SIZE.x, LOADING_PIC_SIZE.y - DOOR_CLOSED_Y)
	_floor_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_stage.add_child(_floor_shade)
	var clip := Control.new()
	clip.clip_contents = true
	clip.position = Vector2(DOOR_LEFT, 0)
	clip.size = Vector2(DOOR_RIGHT - DOOR_LEFT, DOOR_CLOSED_Y)
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_stage.add_child(clip)
	_door = TextureRect.new()
	_door.texture = load(LOADING_DOOR)
	_door.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(_door)

	var title := Label.new()
	title.text = "NITRO UNDERGROUND"
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_left = -500
	title.offset_right = 500
	title.offset_top = 14
	title.offset_bottom = 84
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color(1, 0.86, 0.3))
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02))
	title.add_theme_constant_override("outline_size", 14)
	bg.add_child(title)
	loading_percent = Label.new()
	loading_percent.set_anchors_preset(Control.PRESET_CENTER_TOP)
	loading_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_percent.offset_left = -300
	loading_percent.offset_right = 300
	loading_percent.offset_top = 82
	loading_percent.offset_bottom = 132
	loading_percent.add_theme_font_size_override("font_size", 40)
	loading_percent.add_theme_color_override("font_color", Color.WHITE)
	loading_percent.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02))
	loading_percent.add_theme_constant_override("outline_size", 12)
	bg.add_child(loading_percent)
	loading_label = Label.new()
	loading_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.offset_left = -500
	loading_label.offset_right = 500
	loading_label.offset_top = 132
	loading_label.offset_bottom = 170
	loading_label.add_theme_font_size_override("font_size", 24)
	loading_label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.85))
	loading_label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02))
	loading_label.add_theme_constant_override("outline_size", 9)
	bg.add_child(loading_label)
	bg.visible = false
	_place_door(0.0)


## The picture covers the whole screen (cut at the edges if the screen is longer or taller).
func _layout_loading(s: Vector2) -> void:
	var k := maxf(s.x / LOADING_PIC_SIZE.x, s.y / LOADING_PIC_SIZE.y)
	_loading_stage.scale = Vector2(k, k)
	_loading_stage.position = (s - LOADING_PIC_SIZE * k) * 0.5


## Door bottom edge for a loading fraction (0 closed, 1 as high as in the picture).
func _place_door(open: float) -> void:
	var y := lerpf(DOOR_CLOSED_Y, DOOR_OPEN_Y, clampf(open, 0.0, 1.0))
	_door.position = Vector2(0, y - _door.texture.get_height())
	_floor_shade.color = Color(0, 0, 0, 0.5 * (1.0 - open))


func show_loading(text: String, progress: float) -> void:
	if not loading_panel.visible:
		_door_shown = progress  # a new loading page starts where it is, no slide from elsewhere
	loading_panel.visible = true
	_door_target = progress
	_place_door(_door_shown)
	loading_percent.text = "%d%%" % roundi(progress * 100.0)
	loading_label.text = text


## True once the door has slid up to the last percentage given.
func door_settled() -> bool:
	return absf(_door_target - _door_shown) < 0.004


## Moves the door towards the loading percentage with a short slide (called every frame).
func _animate_door(delta: float) -> void:
	if not loading_panel.visible or door_settled():
		return
	_door_shown = move_toward(_door_shown, _door_target, maxf(absf(_door_target - _door_shown) * 12.0, 0.25) * delta)
	_place_door(_door_shown)


func hide_loading() -> void:
	loading_panel.visible = false


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
	_big_button(box, "GARAGE", CYAN).pressed.connect(func(): menu_pressed.emit())
	end_panel.visible = false


## Pause panel: the race is frozen behind it until RIPRENDI GARA (or MENÙ to leave).
func _build_pause() -> void:
	var box := _panel_base()
	pause_panel = box.get_parent()
	var title := Label.new()
	title.text = "GARA IN PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	box.add_child(title)
	_big_button(box, "RIPRENDI GARA", Color(0.3, 1, 0.45)).pressed.connect(func(): resume_pressed.emit())
	_big_button(box, "GARAGE", CYAN).pressed.connect(func(): menu_pressed.emit())
	pause_panel.visible = false


## Shows or hides the pause panel; the touch controls and the MENU button go away meanwhile.
func show_pause(on: bool) -> void:
	pause_panel.visible = on
	pause.visible = not on
	show_controls(not on)


## The race is about to start: controls, info, clock and the MENU button come up.
func show_race_hud() -> void:
	_show_race_info(true)
	show_controls(true)


func _show_race_info(on: bool) -> void:
	pause.visible = on
	info_label.visible = on
	minimap.visible = on
	clock_label.visible = on
	heat_label.visible = on
	for r in heat_boxes:
		r.visible = on


func show_end(won: bool, title: String, text: String) -> void:
	set_wrong_way(false)
	end_title.text = title
	end_title.add_theme_color_override("font_color", Color(0.3, 1, 0.5) if won else Color(1, 0.3, 0.3))
	end_text.text = text
	end_panel.visible = true
	show_controls(false)
