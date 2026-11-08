extends Control
## The garage (v0.17, after the START page): one car big in the middle, its name and a few figures
## under it, arrows on its sides. Before the first choice the arrows browse the three starting cars
## and SELEZIONA (two taps) makes one the player's for good (kept in SaveGame); after that they
## browse the cars the player owns, and the one on show is the one driven. Top right: money and
## reputation; top left: the map button; bottom left: DEALER (v0.19, scenes/dealer.tscn); bottom
## right: INIZIO GARA, the next race of the campaign (Main.CAMPAIGN). Only the cars on offer are
## read from disk.

const RACE_SCENE := "res://scenes/main.tscn"
const DEALER_SCENE := "res://scenes/dealer.tscn"
const BACKGROUND := "res://assets/ui/garage_bg.jpg"
const GREEN := Color(0.25, 0.8, 0.35)

## Position of the car on show in the list (kept when coming back from a race).
static var car_index := -1

var _garage: Array = []
var _locked := false
var _confirming := false
var _select_button: Neon.NeonButton
var _go_button: Neon.NeonButton
var _dealer_button: Neon.NeonButton
var _arrows: Array[Button] = []
var _car_name: Label
var _car_info: Label
var _car_status: Label
var _toast: Label
var _toast_t := 0.0
var _stage: Node3D
var _preview: Node3D
var _cam: Camera3D
var _pending: Array[String] = []  # car models being read in the background
var _loaded := {}  # car models already read, kept so switching back to a car is instant
## The car stands still, almost side on (Stefano, v0.20.4); dragging turns it.
const VIEW_ANGLE := 1.9
var _turn := VIEW_ANGLE
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
		if a == "--to-dealer":
			_open_dealer.call_deferred()


# ---------- Layout ----------

## The car in the middle: a 3D window about 60% of the screen wide (the car fills about 40% of
## it), a soft shadow under it, the name and figures below.
func _build_car_window() -> void:
	var shadow := UiKit.Icon.new()
	shadow.kind = "shadow"
	UiKit.anchor(shadow, 0.26, 0.8, 0.74, 0.9)
	add_child(shadow)

	var win := UiKit.car_window(self)
	UiKit.anchor(win[0], 0.2, 0.34, 0.8, 0.98)
	_stage = win[1]
	_cam = win[2]
	_car_status = UiKit.label(26)
	_car_status.text = "Carico l'auto..."
	_car_status.set_anchors_preset(Control.PRESET_FULL_RECT)
	_car_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_car_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	(win[0] as Control).add_child(_car_status)

	var names := VBoxContainer.new()
	UiKit.anchor(names, 0.25, 0.865, 0.75, 1.0)
	names.add_theme_constant_override("separation", -2)
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(names)
	_car_name = UiKit.label(38, UiKit.GOLD, 12)
	_car_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	names.add_child(_car_name)
	_car_info = UiKit.label(22, Color(0.95, 0.93, 0.88))
	_car_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	names.add_child(_car_info)

	# Arrows on the two sides of the car.
	for dir in [-1, 1]:
		var b := UiKit.ArrowButton.new()
		b.dir = dir
		var x := 0.18 if dir < 0 else 0.82
		UiKit.anchor(b, x, 0.62, x, 0.62)
		b.offset_left = -50
		b.offset_right = 50
		b.offset_top = -55
		b.offset_bottom = 55
		b.pressed.connect(_step_car.bind(dir))
		add_child(b)
		_arrows.append(b)


## Money and reputation (top right), the map button (top left), the message in the middle.
func _build_top_bar() -> void:
	UiKit.money_and_rep(self)

	var map := UiKit.button("", Color(0.25, 0.45, 0.75))
	map.set_anchors_preset(Control.PRESET_TOP_LEFT)
	map.offset_left = 20
	map.offset_top = 18
	map.offset_right = 100
	map.offset_bottom = 98
	var icon := UiKit.Icon.new()
	icon.kind = "map"
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 12
	icon.offset_top = 12
	icon.offset_right = -12
	icon.offset_bottom = -12
	map.add_child(icon)
	map.pressed.connect(func(): _say("La mappa arriverà presto"))
	add_child(map)

	_toast = UiKit.label(34, Color.WHITE, 12)
	_toast.set_anchors_preset(Control.PRESET_CENTER)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.offset_left = -500
	_toast.offset_right = 500
	_toast.offset_top = -30
	_toast.offset_bottom = 30
	_toast.visible = false
	add_child(_toast)


## SELEZIONA above the car, DEALER bottom left, INIZIO GARA bottom right: since v0.20.4 a
## coloured picture and a caption, no box (Neon, like the dealer).
func _build_buttons() -> void:
	_select_button = Neon.NeonButton.new().setup("SELEZIONA", "check", Neon.GREEN, false, 32)
	_select_button.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_select_button.offset_left = -190
	_select_button.offset_right = 190
	_select_button.offset_top = 18
	_select_button.offset_bottom = 92
	_select_button.pressed.connect(_on_select)
	add_child(_select_button)

	_dealer_button = Neon.NeonButton.new().setup("DEALER", "shop", Neon.YELLOW, true, 26)
	_dealer_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_dealer_button.offset_left = 18
	_dealer_button.offset_right = 178
	_dealer_button.offset_top = -168
	_dealer_button.offset_bottom = -12
	_dealer_button.pressed.connect(_open_dealer)
	add_child(_dealer_button)

	var race: Array = Main.CAMPAIGN[SaveGame.race_index % Main.CAMPAIGN.size()]
	_go_button = Neon.NeonButton.new().setup("INIZIO GARA", "flag", Neon.RED, true, 26)
	_go_button.sub = race[1]
	_go_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_go_button.offset_left = -218
	_go_button.offset_right = -18
	_go_button.offset_top = -190
	_go_button.offset_bottom = -12
	_go_button.pressed.connect(_start_race)
	add_child(_go_button)


# ---------- Choosing the car ----------

## Locked: the starting car is chosen; the arrows browse the cars the player owns.
func _set_locked(on: bool) -> void:
	_locked = on
	_confirming = false
	_garage = CarCatalog.available(SaveGame.owned if on else CarCatalog.STARTER)
	if _garage.is_empty():
		_garage = CarCatalog.available()
	car_index = 0
	for i in _garage.size():
		if on and _garage[i]["id"] == SaveGame.car:
			car_index = i
	for b in _arrows:
		b.visible = _garage.size() > 1
	_select_button.set_caption("LA TUA AUTO" if on else "SELEZIONA")
	_select_button.icon_kind = "key" if on else "check"
	_select_button.disabled = on
	_go_button.disabled = not on
	_dealer_button.disabled = not on
	_show_car()


func _on_select() -> void:
	if _locked or _leaving:
		return
	if not _confirming:
		# First tap: one more tap to confirm, the choice is for good.
		_confirming = true
		_select_button.set_caption("CONFERMI?")
		_say("Tocca ancora: poi non potrai più cambiarla")
		return
	SaveGame.car = _garage[car_index]["id"]
	SaveGame.owned = [SaveGame.car]
	SaveGame.save_game()
	var chosen: String = _garage[car_index]["name"]
	_set_locked(true)
	_say("%s è tua!" % chosen)


func _step_car(dir: int) -> void:
	if _garage.size() < 2 or _leaving:
		return
	car_index = posmod(car_index + dir, _garage.size())
	_turn = VIEW_ANGLE
	if _confirming:
		_confirming = false
		_select_button.set_caption("SELEZIONA")
	if _locked:
		# The car on show is the one the player drives.
		SaveGame.car = _garage[car_index]["id"]
		SaveGame.save_game()
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
	if _garage.size() > 1:
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
	var id: String = _garage[car_index]["id"]
	_preview = CarModel.build(Color(0, 0, 0, 0), false, id)
	CarModel.paint_model(_preview, id, SaveGame.color_of(id))
	_stage.add_child(_preview)
	_preview.rotation.y = _turn
	UiKit.frame_car(_preview, _cam)


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
	# Then read the next and the previous car in the background, so the arrows show them straight
	# away. Only these stay in memory: the phone has little RAM.
	if _pending.is_empty() and not _leaving and _garage.size() > 1:
		for step in [1, -1]:
			var next := _model_file(_garage[posmod(car_index + step, _garage.size())])
			if not _loaded.has(next):
				_pending.append(next)
				ResourceLoader.load_threaded_request(next)
				break
	if _preview:
		_preview.rotation.y = _turn
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t / 0.5, 0.0, 1.0)
		_toast.visible = _toast_t > 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		# Dragging turns the car (the arrows change it).
		_turn += (event as InputEventScreenDrag).relative.x * 0.012
	elif event.is_action_pressed("ui_left"):
		_step_car(-1)
	elif event.is_action_pressed("ui_right"):
		_step_car(1)
	elif event.is_action_pressed("ui_accept"):
		if _locked:
			_start_race()
		else:
			_on_select()


## Android back button (the game no longer quits on it by itself): from the garage out of the game.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not _leaving:
		get_tree().quit()


## Lets go of the models before changing scene, so nothing stays half-loaded in memory.
func _leave(scene: String) -> void:
	_leaving = true
	await get_tree().process_frame
	await get_tree().process_frame
	if _preview:
		_preview.queue_free()
		_preview = null
	for path in _pending:
		ResourceLoader.load_threaded_get(path)
	_pending.clear()
	_loaded.clear()
	CarModel.clear_cache()
	get_tree().change_scene_to_file(scene)


func _open_dealer() -> void:
	if _leaving:
		return
	if not _locked:
		_say("Prima scegli la tua auto")
		return
	_leave(DEALER_SCENE)


## INIZIO GARA: frees the garage and opens the race scene on the next circuit of the campaign.
func _start_race() -> void:
	if _leaving:
		return
	if not _locked:
		_say("Prima scegli la tua auto")
		return
	Main.level = Main.CAMPAIGN[SaveGame.race_index % Main.CAMPAIGN.size()][0]
	_go_button.set_caption("CARICAMENTO...")
	_go_button.disabled = true
	_leave(RACE_SCENE)
