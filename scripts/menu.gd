extends Control
## The garage, the first screen of the game (v0.17, it replaces the old title menu). The player is
## inside the garage: one car big in the middle (about a third of the screen), its name and a few
## figures under it, arrows on its sides to browse the three starting cars and SELEZIONA above it.
## Once a car is chosen it is the player's for good (kept in SaveGame) and the arrows go away.
## Top right: money and reputation; top left: the map button; bottom right: INIZIO GARA, which
## opens the first race, on the coast. Only the cars on offer are read from disk.

const RACE_SCENE := "res://scenes/main.tscn"
const BACKGROUND := "res://assets/ui/garage_bg.jpg"
## The first race of the game.
const FIRST_RACE := "coast"
const GOLD := Color(1, 0.8, 0.25)
const INK := Color(0.05, 0.04, 0.03)
const GREEN := Color(0.25, 0.8, 0.35)

## Position of the car on show in the list (kept when coming back from a race).
static var car_index := -1

var _garage: Array = []
var _locked := false
var _confirming := false
var _select_button: Button
var _go_button: Button
var _arrows: Array[Button] = []
var _car_name: Label
var _car_info: Label
var _car_status: Label
var _toast: Label
var _toast_t := 0.0
var _money_label: Label
var _rep_label: Label
var _viewport: SubViewport
var _stage: Node3D
var _preview: Node3D
var _cam: Camera3D
var _pending: Array[String] = []  # car models being read in the background
var _loaded := {}  # car models already read, kept so switching back to a car is instant
var _swipe := 0.0
var _turn := 0.6
var _leaving := false


func _ready() -> void:
	DisplayServer.screen_set_keep_on(true)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# The garage has no 3D world of its own (the car window has its own): skip it entirely.
	# The race scene turns it back on when its level is ready.
	get_viewport().disable_3d = true
	var args := OS.get_cmdline_user_args()
	if args.has("--reset-garage"):
		SaveGame.reset()
	SaveGame.load_game()

	var bg := TextureRect.new()
	bg.texture = load(BACKGROUND)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_car_window()
	_build_top_bar()
	_build_buttons()
	_set_locked(SaveGame.car != "" and not CarCatalog.available([SaveGame.car]).is_empty())

	for a in args:
		if a.begins_with("--menushot="):
			# Test aid: picture of the garage screen.
			await get_tree().create_timer(5.0).timeout
			get_viewport().get_texture().get_image().save_png(a.substr(11))
			get_tree().quit()
		if a == "--menutest":
			# Test aid: next car, choose it (two taps), start the race.
			await get_tree().create_timer(1.5).timeout
			_step_car(1)
			await get_tree().create_timer(1.5).timeout
			_on_select()
			_on_select()
			await get_tree().create_timer(1.5).timeout
			_start_race()


# ---------- Layout ----------

func _box(fill: Color, border: Color, radius := 10) -> StyleBoxFlat:
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


func _button(text: String, color: Color, font := 30) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.45))
	b.add_theme_color_override("font_outline_color", INK)
	b.add_theme_constant_override("outline_size", 8)
	var normal := _box(Color(color.r * 0.7, color.g * 0.7, color.b * 0.7, 0.92), Color(1, 1, 1, 0.75))
	var on := _box(color, Color.WHITE)
	var off := _box(Color(0.15, 0.15, 0.15, 0.75), Color(1, 1, 1, 0.25))
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("focus", normal)
	b.add_theme_stylebox_override("disabled", off)
	return b


## The car in the middle: a 3D window about 45% of the screen wide (the car fills about a third
## of the screen), a soft shadow under it, the name and figures below.
func _build_car_window() -> void:
	var shadow := _Icon.new()
	shadow.kind = "shadow"
	_anchor(shadow, 0.26, 0.8, 0.74, 0.9)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shadow)

	var view := SubViewportContainer.new()
	view.stretch = true
	_anchor(view, 0.2, 0.34, 0.8, 0.98)
	view.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(view)
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	view.add_child(_viewport)
	_build_stage()
	_car_status = Label.new()
	_car_status.text = "Carico l'auto..."
	_car_status.add_theme_font_size_override("font_size", 26)
	_car_status.add_theme_color_override("font_outline_color", INK)
	_car_status.add_theme_constant_override("outline_size", 8)
	_car_status.set_anchors_preset(Control.PRESET_FULL_RECT)
	_car_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_car_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_car_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(_car_status)

	var names := VBoxContainer.new()
	_anchor(names, 0.25, 0.865, 0.75, 1.0)
	names.alignment = BoxContainer.ALIGNMENT_BEGIN
	names.add_theme_constant_override("separation", -2)
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(names)
	_car_name = Label.new()
	_car_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_car_name.add_theme_font_size_override("font_size", 38)
	_car_name.add_theme_color_override("font_color", GOLD)
	_car_name.add_theme_color_override("font_outline_color", INK)
	_car_name.add_theme_constant_override("outline_size", 12)
	names.add_child(_car_name)
	_car_info = Label.new()
	_car_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_car_info.add_theme_font_size_override("font_size", 22)
	_car_info.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
	_car_info.add_theme_color_override("font_outline_color", INK)
	_car_info.add_theme_constant_override("outline_size", 8)
	names.add_child(_car_info)

	# Arrows on the two sides of the car.
	for dir in [-1, 1]:
		var b := _ArrowButton.new()
		b.dir = dir
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		if dir < 0:
			_anchor(b, 0.18, 0.62, 0.18, 0.62)
		else:
			_anchor(b, 0.82, 0.62, 0.82, 0.62)
		b.offset_left = -50
		b.offset_right = 50
		b.offset_top = -55
		b.offset_bottom = 55
		b.pressed.connect(_step_car.bind(dir))
		add_child(b)
		_arrows.append(b)


func _anchor(c: Control, l: float, t: float, r: float, b: float) -> void:
	c.anchor_left = l
	c.anchor_top = t
	c.anchor_right = r
	c.anchor_bottom = b
	c.offset_left = 0
	c.offset_top = 0
	c.offset_right = 0
	c.offset_bottom = 0


## Money and reputation (top right), the map button (top left).
func _build_top_bar() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	row.offset_left = -400
	row.offset_right = -20
	row.offset_top = 18
	row.offset_bottom = 70
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	_money_label = _stat_panel(row, "money")
	_rep_label = _stat_panel(row, "rep")
	_money_label.text = _thousands(SaveGame.money)
	_rep_label.text = _thousands(SaveGame.reputation)

	var map := _button("", Color(0.25, 0.45, 0.75))
	map.set_anchors_preset(Control.PRESET_TOP_LEFT)
	map.offset_left = 20
	map.offset_top = 18
	map.offset_right = 100
	map.offset_bottom = 98
	map.focus_mode = Control.FOCUS_NONE
	var icon := _Icon.new()
	icon.kind = "map"
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 12
	icon.offset_top = 12
	icon.offset_right = -12
	icon.offset_bottom = -12
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.add_child(icon)
	map.pressed.connect(func(): _say("La mappa arriverà presto"))
	add_child(map)

	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.offset_left = -500
	_toast.offset_right = 500
	_toast.offset_top = -30
	_toast.offset_bottom = 30
	_toast.add_theme_font_size_override("font_size", 34)
	_toast.add_theme_color_override("font_outline_color", INK)
	_toast.add_theme_constant_override("outline_size", 12)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.visible = false
	add_child(_toast)


## A small panel with an icon and a value; returns the value label.
func _stat_panel(parent: Control, kind: String) -> Label:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color(0.06, 0.05, 0.04, 0.78), Color(1, 1, 1, 0.3), 26))
	panel.custom_minimum_size = Vector2(150, 0)
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var icon := _Icon.new()
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


func _thousands(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


## SELEZIONA above the car, INIZIO GARA bottom right.
func _build_buttons() -> void:
	_select_button = _button("SELEZIONA", GREEN, 34)
	_select_button.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_select_button.offset_left = -170
	_select_button.offset_right = 170
	_select_button.offset_top = 22
	_select_button.offset_bottom = 92
	_select_button.focus_mode = Control.FOCUS_NONE
	_select_button.pressed.connect(_on_select)
	add_child(_select_button)

	_go_button = _button("INIZIO GARA", Color(0.9, 0.2, 0.15), 36)
	_go_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_go_button.offset_left = -330
	_go_button.offset_right = -24
	_go_button.offset_top = -110
	_go_button.offset_bottom = -24
	_go_button.focus_mode = Control.FOCUS_NONE
	_go_button.pressed.connect(_start_race)
	add_child(_go_button)


## The little 3D set of the car window: its own world, warm garage light and a camera.
func _build_stage() -> void:
	_stage = Node3D.new()
	_viewport.add_child(_stage)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.78, 0.7)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	_stage.add_child(we)
	# Daylight from the open door behind the car, the garage lamp in front of it.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 160, 0)
	sun.light_color = Color(1, 0.88, 0.7)
	sun.light_energy = 1.2
	_stage.add_child(sun)
	var lamp := DirectionalLight3D.new()
	lamp.rotation_degrees = Vector3(-40, -25, 0)
	lamp.light_color = Color(1, 0.85, 0.65)
	lamp.light_energy = 1.5
	_stage.add_child(lamp)
	_cam = Camera3D.new()
	_cam.fov = 30
	_stage.add_child(_cam)


# ---------- Choosing the car ----------

## Locked: the player's car is chosen for good, only that one is shown.
func _set_locked(on: bool) -> void:
	_locked = on
	_confirming = false
	_garage = CarCatalog.available([SaveGame.car] if on else CarCatalog.STARTER)
	if _garage.is_empty():
		_garage = CarCatalog.available()
	if on:
		car_index = 0
	elif car_index < 0 or car_index >= _garage.size():
		car_index = 0
	for b in _arrows:
		b.visible = not on and _garage.size() > 1
	_select_button.text = "LA TUA AUTO" if on else "SELEZIONA"
	_select_button.disabled = on
	_go_button.disabled = not on
	_show_car()


func _on_select() -> void:
	if _locked or _leaving:
		return
	if not _confirming:
		# First tap: one more tap to confirm, the choice is for good.
		_confirming = true
		_select_button.text = "CONFERMI?"
		_say("Tocca ancora: poi non potrai più cambiarla")
		return
	SaveGame.car = _garage[car_index]["id"]
	SaveGame.save_game()
	_set_locked(true)
	_say("%s è tua!" % _garage[0]["name"])


func _step_car(dir: int) -> void:
	if _locked or _garage.size() < 2 or _leaving:
		return
	car_index = posmod(car_index + dir, _garage.size())
	if _confirming:
		_confirming = false
		_select_button.text = "SELEZIONA"
	_show_car()


func _say(text: String, seconds := 2.5) -> void:
	_toast.text = text
	_toast.visible = true
	_toast.modulate.a = 1.0
	_toast_t = seconds


## Shows the chosen car: its name at once, its model as soon as it is read from disk.
func _show_car() -> void:
	var entry: Dictionary = _garage[car_index]
	Car.player_body = entry["id"]
	_car_name.text = entry["name"]
	var drive := {"RWD": "Trazione posteriore", "FWD": "Trazione anteriore", "AWD": "4 ruote motrici"}
	var info := "Velocità max %d km/h   ·   %s" % [CarCatalog.top_speed(entry["id"]), drive[CarCatalog.drivetrain(entry["id"])]]
	if not _locked and _garage.size() > 1:
		info = "%d / %d   ·   " % [car_index + 1, _garage.size()] + info
	_car_info.text = info
	var path := _model_file(entry)
	if _loaded.has(path) or ResourceLoader.has_cached(path):
		_build_preview()
		return
	if _preview:
		_preview.visible = false
	_car_status.visible = true
	if not _pending.has(path):
		_pending.append(path)
		ResourceLoader.load_threaded_request(path)


## The file read for a car: its ready-made light version (assets/cars_baked) when there is one.
func _model_file(entry: Dictionary) -> String:
	var baked := CarModel.baked_path(entry["id"])
	return baked if ResourceLoader.exists(baked) else CarCatalog.model_path(entry)


func _build_preview() -> void:
	_car_status.visible = false
	if _preview:
		_preview.queue_free()
	var entry: Dictionary = _garage[car_index]
	_preview = CarModel.build(Color(0, 0, 0, 0), false, entry["id"])
	_stage.add_child(_preview)
	_preview.rotation.y = _turn
	var length := 4.5
	for mi in _preview.find_children("*", "MeshInstance3D", true, false):
		var bb: AABB = CarModel._xf_in(mi, _preview) * (mi as MeshInstance3D).get_aabb()
		length = maxf(length, maxf(absf(bb.position.z), absf(bb.end.z)) * 2.0)
	var dist := length * 1.55
	_cam.position = Vector3(0, dist * 0.22, dist)
	_cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)


func _process(delta: float) -> void:
	# Models read in the background: collect the finished ones, show the one still wanted.
	for path in _pending.duplicate():
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		_pending.erase(path)
		var res := ResourceLoader.load_threaded_get(path)
		_loaded[path] = res  # null if it could not be read: not asked for again
		if res and not _garage.is_empty() and _model_file(_garage[car_index]) == path and not _leaving:
			_build_preview()
	# Then read the other cars on offer in the background (three at most), so the arrows show
	# them straight away.
	if _pending.is_empty() and not _leaving:
		for entry in _garage:
			var next := _model_file(entry)
			if not _loaded.has(next):
				_pending.append(next)
				ResourceLoader.load_threaded_request(next)
				break
	_turn += delta * 0.3
	if _preview:
		_preview.rotation.y = _turn
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t / 0.5, 0.0, 1.0)
		_toast.visible = _toast_t > 0.0


func _unhandled_input(event: InputEvent) -> void:
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
		if _locked:
			_start_race()
		else:
			_on_select()
	_swipe += dx
	if absf(_swipe) > 90.0:
		_step_car(-1 if _swipe > 0.0 else 1)
		_swipe = 0.0


## Android back button (the game no longer quits on it by itself): from the garage out of the game.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not _leaving:
		get_tree().quit()


## INIZIO GARA: frees the garage and opens the race scene on the first circuit (the coast).
func _start_race() -> void:
	if _leaving:
		return
	if not _locked:
		_say("Prima scegli la tua auto")
		return
	_leaving = true
	Main.level = FIRST_RACE
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
	_loaded.clear()
	CarModel.clear_cache()
	get_tree().change_scene_to_file(RACE_SCENE)


## Arrow drawn as a triangle (left or right) with a dark border, used beside the car.
class _ArrowButton:
	extends Button
	var dir := 1

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


## Small drawn icons: "money" (gold coin), "rep" (star), "map" (folded map with a pin).
class _Icon:
	extends Control
	var kind := "money"

	func _init() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		match kind:
			"shadow":
				# Soft oval shadow on the garage floor: a few see-through ovals one inside the other.
				for i in 8:
					var k := 1.0 - i * 0.11
					var pts := PackedVector2Array()
					for j in 48:
						var a := TAU * j / 48.0
						pts.append(c + Vector2(cos(a) * size.x * 0.5 * k, sin(a) * size.y * 0.5 * k))
					draw_colored_polygon(pts, Color(0, 0, 0, 0.28))
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
				# Route and pin.
				draw_polyline(PackedVector2Array([Vector2(size.x * 0.12, size.y * 0.75), Vector2(size.x * 0.4, size.y * 0.55),
					Vector2(size.x * 0.6, size.y * 0.65), Vector2(size.x * 0.8, size.y * 0.35)]), Color(0.85, 0.15, 0.1), 3.0, true)
				draw_circle(Vector2(size.x * 0.8, size.y * 0.3), r * 0.2, Color(0.85, 0.15, 0.1))
				draw_circle(Vector2(size.x * 0.8, size.y * 0.3), r * 0.08, Color.WHITE)
