extends Control
## Title screen, the first scene the game opens. It is light on purpose: a drawn picture of
## Route 66 as the background and one panel that first offers the circuits, then (the same panel)
## the cars, with the chosen car turning in a small 3D window. Only that one car model is read
## from disk. VIA! opens the race scene (main.gd), which builds just the chosen circuit and the
## cars of that race.

const RACE_SCENE := "res://scenes/main.tscn"
const BACKGROUND := "res://assets/ui/route66_menu.jpg"
const ACCENT := Color(1, 0.18, 0.55)
const CYAN := Color(0.1, 0.9, 1)
const INK := Color(0.07, 0.03, 0.1)
const PANEL_W := 500.0

## Position of the chosen car in the garage list (kept when coming back from a race).
static var car_index := -1

var _garage: Array = []
var _page := "track"
var _panel_title: Label
var _track_page: VBoxContainer
var _car_page: VBoxContainer
var _track_buttons := {}
var _back_button: Button
var _go_button: Button
var _car_name: Label
var _car_info: Label
var _car_status: Label
var _viewport: SubViewport
var _stage: Node3D
var _preview: Node3D
var _cam: Camera3D
var _pending: Array[String] = []  # car models being read in the background
var _swipe := 0.0
var _turn := 0.0
var _leaving := false


func _ready() -> void:
	DisplayServer.screen_set_keep_on(true)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# The title screen has no 3D world of its own (the car window has its own): skip it entirely.
	# The race scene turns it back on when its level is ready.
	get_viewport().disable_3d = true
	ComicStyle.install(get_tree())  # the car on show gets the drawn look and its ink outline

	var bg := TextureRect.new()
	bg.texture = load(BACKGROUND)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_title()
	_build_panel()
	_garage = CarCatalog.available()
	if car_index < 0 or car_index >= _garage.size():
		car_index = 0
		for i in _garage.size():
			if _garage[i]["id"] == Car.player_body:
				car_index = i
	_show_page("track")

	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--menushot="):
			# Test aid: picture of the title screen (--page=car for the car page).
			if args.has("--page=car"):
				_show_page("car")
			await get_tree().create_timer(4.0).timeout
			get_viewport().get_texture().get_image().save_png(a.substr(11))
			get_tree().quit()
		if a == "--menutest":
			# Test aid: pick the coast, step through two cars and start.
			await get_tree().create_timer(1.0).timeout
			_pick_track("coast")
			await get_tree().create_timer(2.0).timeout
			_step_car(1)
			await get_tree().create_timer(2.0).timeout
			_start_race()


# ---------- Layout ----------

func _build_title() -> void:
	var title := Label.new()
	title.text = "NITRO\nUNDERGROUND"
	title.position = Vector2(36, 18)
	title.add_theme_font_size_override("font_size", 76)
	title.add_theme_constant_override("line_spacing", -18)
	title.add_theme_color_override("font_color", Color(1, 0.86, 0.2))
	title.add_theme_color_override("font_outline_color", INK)
	title.add_theme_constant_override("outline_size", 18)
	title.add_theme_color_override("font_shadow_color", ACCENT)
	title.add_theme_constant_override("shadow_offset_x", 7)
	title.add_theme_constant_override("shadow_offset_y", 7)
	title.add_theme_constant_override("shadow_outline_size", 18)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)


func _comic_box(fill: Color, border: Color, width := 5) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(INK.r, INK.g, INK.b, 0.9)
	sb.shadow_offset = Vector2(7, 7)
	sb.shadow_size = 1
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	return sb


func _button(text: String, color: Color, font := 30, height := 84.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, height)
	b.add_theme_font_size_override("font_size", font)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_outline_color", INK)
	b.add_theme_constant_override("outline_size", 8)
	var sb := _comic_box(Color(color.r * 0.55, color.g * 0.55, color.b * 0.55, 0.95), INK, 4)
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	var on := _comic_box(color, INK, 4)
	on.content_margin_top = 6
	on.content_margin_bottom = 6
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", on)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("focus", sb)
	return b


## One panel on the right that shows the circuits, then the cars; the VIA! button under it.
func _build_panel() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -PANEL_W - 28
	panel.offset_right = -28
	panel.offset_top = 24
	panel.offset_bottom = -140
	panel.add_theme_stylebox_override("panel", _comic_box(Color(0.06, 0.03, 0.14, 0.8), INK, 6))
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	box.add_child(head)
	_back_button = _button("<", CYAN, 30, 56)
	_back_button.custom_minimum_size = Vector2(64, 56)
	_back_button.pressed.connect(func(): _show_page("track"))
	head.add_child(_back_button)
	_panel_title = Label.new()
	_panel_title.add_theme_font_size_override("font_size", 34)
	_panel_title.add_theme_color_override("font_color", Color(1, 0.86, 0.2))
	_panel_title.add_theme_color_override("font_outline_color", INK)
	_panel_title.add_theme_constant_override("outline_size", 10)
	_panel_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_panel_title.custom_minimum_size = Vector2(0, 56)
	_panel_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_panel_title)

	# Page 1: the circuits.
	_track_page = VBoxContainer.new()
	_track_page.add_theme_constant_override("separation", 14)
	_track_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_track_page)
	for t in Main.TRACKS:
		var id: String = t[0]
		var b := _button("%s\n%s" % [t[1], t[2]], ACCENT, 26, 0)
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_pick_track.bind(id))
		_track_page.add_child(b)
		_track_buttons[id] = b

	# Page 2: the cars, in the same panel.
	_car_page = VBoxContainer.new()
	_car_page.add_theme_constant_override("separation", 8)
	_car_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_car_page)
	var view := SubViewportContainer.new()
	view.stretch = true
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.mouse_filter = Control.MOUSE_FILTER_PASS
	_car_page.add_child(view)
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	view.add_child(_viewport)
	_build_stage()
	_car_status = Label.new()
	_car_status.text = "Carico l'auto..."
	_car_status.add_theme_font_size_override("font_size", 24)
	_car_status.add_theme_color_override("font_color", Color(0.8, 0.85, 1))
	_car_status.set_anchors_preset(Control.PRESET_CENTER)
	_car_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_car_status.offset_left = -200
	_car_status.offset_right = 200
	_car_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(_car_status)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_car_page.add_child(row)
	var prev := _button("<", CYAN, 36, 76)
	prev.custom_minimum_size = Vector2(76, 76)
	prev.pressed.connect(_step_car.bind(-1))
	row.add_child(prev)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.add_theme_constant_override("separation", 0)
	row.add_child(names)
	_car_name = Label.new()
	_car_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_car_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_car_name.add_theme_font_size_override("font_size", 28)
	_car_name.add_theme_color_override("font_outline_color", INK)
	_car_name.add_theme_constant_override("outline_size", 8)
	names.add_child(_car_name)
	_car_info = Label.new()
	_car_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_car_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_car_info.add_theme_font_size_override("font_size", 19)
	_car_info.add_theme_color_override("font_color", Color(0.75, 0.8, 0.95))
	names.add_child(_car_info)
	var next := _button(">", CYAN, 36, 76)
	next.custom_minimum_size = Vector2(76, 76)
	next.pressed.connect(_step_car.bind(1))
	row.add_child(next)

	_go_button = _button("VIA!", ACCENT, 52, 0)
	_go_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_go_button.offset_left = -PANEL_W - 28
	_go_button.offset_right = -28
	_go_button.offset_top = -118
	_go_button.offset_bottom = -24
	_go_button.add_theme_stylebox_override("normal", _go_button.get_theme_stylebox("hover"))
	_go_button.add_theme_stylebox_override("focus", _go_button.get_theme_stylebox("hover"))
	_go_button.pressed.connect(_start_race)
	add_child(_go_button)


## The little 3D set of the car window: its own world, a sun, soft light and a camera.
func _build_stage() -> void:
	_stage = Node3D.new()
	_viewport.add_child(_stage)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.72, 0.95)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	_stage.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -30, 0)
	sun.light_color = Color(1, 0.9, 0.8)
	sun.light_energy = 1.3
	_stage.add_child(sun)
	var back := DirectionalLight3D.new()
	back.rotation_degrees = Vector3(-20, 150, 0)
	back.light_color = Color(1, 0.4, 0.7)
	back.light_energy = 0.6
	_stage.add_child(back)
	_cam = Camera3D.new()
	_cam.fov = 32
	_stage.add_child(_cam)


# ---------- Pages ----------

func _show_page(page: String) -> void:
	_page = page
	_track_page.visible = page == "track"
	_car_page.visible = page == "car"
	_back_button.visible = page == "car"
	_go_button.visible = page == "car"
	if page == "track":
		_panel_title.text = "1 · SCEGLI IL CIRCUITO"
		for id in _track_buttons:
			var b: Button = _track_buttons[id]
			var chosen: bool = id == Main.level
			b.add_theme_stylebox_override("normal", (b.get_theme_stylebox("hover") if chosen else b.get_theme_stylebox("focus")))
	else:
		var track_name := ""
		for t in Main.TRACKS:
			if t[0] == Main.level:
				track_name = t[1]
		_panel_title.text = "2 · AUTO  (%s)" % track_name
		_show_car()


func _pick_track(id: String) -> void:
	Main.level = id
	_show_page("car")


func _step_car(dir: int) -> void:
	if _page != "car" or _garage.is_empty():
		return
	car_index = posmod(car_index + dir, _garage.size())
	_show_car()


## Shows the chosen car: its name at once, its model as soon as it is read from disk.
func _show_car() -> void:
	var entry: Dictionary = _garage[car_index]
	Car.player_body = entry["id"]
	_car_name.text = entry["name"]
	var drive := {"RWD": "trazione posteriore", "FWD": "trazione anteriore", "AWD": "4 ruote motrici"}
	_car_info.text = "%d / %d  ·  %d km/h  ·  %s" % [car_index + 1, _garage.size(), CarCatalog.top_speed(entry["id"]), drive[CarCatalog.drivetrain(entry["id"])]]
	var path := CarCatalog.model_path(entry)
	if ResourceLoader.has_cached(path):
		_build_preview()
		return
	if _preview:
		_preview.visible = false
	_car_status.visible = true
	if not _pending.has(path):
		_pending.append(path)
		ResourceLoader.load_threaded_request(path)


func _build_preview() -> void:
	_car_status.visible = false
	if _preview:
		_preview.queue_free()
	var entry: Dictionary = _garage[car_index]
	_preview = CarModel.build(Color(0, 0, 0, 0), false, entry["id"])
	_preview.set_meta("comic_ink", true)
	_stage.add_child(_preview)
	_preview.rotation.y = _turn
	# Keep only this model in memory: the others the player looked at are let go.
	CarModel.clear_cache()
	var length := 4.5
	for mi in _preview.find_children("*", "MeshInstance3D", true, false):
		var bb: AABB = CarModel._xf_in(mi, _preview) * (mi as MeshInstance3D).get_aabb()
		length = maxf(length, maxf(absf(bb.position.z), absf(bb.end.z)) * 2.0)
	var dist := length * 1.45
	_cam.position = Vector3(0, dist * 0.32, dist)
	_cam.look_at(Vector3(0, 0.6, 0), Vector3.UP)


func _process(delta: float) -> void:
	# Models read in the background: collect the finished ones, show the one still wanted.
	for path in _pending.duplicate():
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		_pending.erase(path)
		var res := ResourceLoader.load_threaded_get(path)
		if res and not _garage.is_empty() and CarCatalog.model_path(_garage[car_index]) == path and not _leaving:
			_build_preview()
	_turn += delta * 0.5
	if _preview:
		_preview.rotation.y = _turn


func _unhandled_input(event: InputEvent) -> void:
	if _page != "car":
		return
	var dx := 0.0
	if event is InputEventScreenDrag:
		dx = (event as InputEventScreenDrag).relative.x
	elif event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed:
		_swipe = 0.0
	elif event.is_action_pressed("ui_left"):
		_step_car(-1)
	elif event.is_action_pressed("ui_right"):
		_step_car(1)
	elif event.is_action_pressed("ui_accept"):
		_start_race()
	_swipe += dx
	if absf(_swipe) > 90.0:
		_step_car(-1 if _swipe > 0.0 else 1)
		_swipe = 0.0


## VIA!: frees the title screen and opens the race scene, which builds the chosen circuit.
func _start_race() -> void:
	if _leaving or _page != "car":
		return
	_leaving = true
	_go_button.text = "CARICAMENTO..."
	_go_button.disabled = true
	await get_tree().process_frame
	await get_tree().process_frame
	if _preview:
		_preview.queue_free()
		_preview = null
	# Let the models still being read finish, so nothing stays half-loaded in memory.
	for path in _pending:
		ResourceLoader.load_threaded_get(path)
	_pending.clear()
	CarModel.clear_cache()
	get_tree().change_scene_to_file(RACE_SCENE)
