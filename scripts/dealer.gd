extends Control
## The dealer (v0.19, redone in v0.20 on Stefano's notes): the car turns on the platform of his
## showroom picture, big and right on its centre. Three sections, chosen with the tabs at the top:
## LE MIE AUTO (the cars owned: drive one, paint it, sell it if it isn't the last), IN VENDITA (the
## cars to buy) and TUNING (six parts, five stages each, as big cards scrolling sideways). The
## buttons are neon icons with marker-font captions (Neon). Everything is kept in SaveGame.
## Opened from the garage (menu.gd), GARAGE goes back.

const GARAGE_SCENE := "res://scenes/menu.tscn"
const BACKGROUND := "res://assets/ui/dealer_bg.jpg"
## Where the turntable is in the background picture (pixels of the 1672 x 941 image): centre of
## its top and its width. The car is placed there whatever the shape of the screen.
const IMAGE_SIZE := Vector2(1672, 941)
const PLATFORM_CENTER := Vector2(852, 722)
const PLATFORM_WIDTH := 1275.0
## Length of a car seen from the side, as a share of the platform width (v0.20: about twice v0.19).
const CAR_FILL := 0.85
## The camera looks down a little, like the picture (the platform is a flat ellipse).
const CAM_PITCH := 7.0
const CAM_FOV := 20.0

## The 15 paints (v0.20, Stefano: a choice of colours instead of RGB).
const PALETTE := [
	Color(0.95, 0.95, 0.95), Color(0.72, 0.74, 0.78), Color(0.32, 0.33, 0.36), Color(0.03, 0.03, 0.04),
	Color(0.85, 0.04, 0.04), Color(0.42, 0.02, 0.07), Color(1.0, 0.4, 0.02), Color(1.0, 0.82, 0.05),
	Color(0.45, 0.92, 0.08), Color(0.02, 0.32, 0.14), Color(0.0, 0.72, 0.72), Color(0.3, 0.62, 1.0),
	Color(0.04, 0.14, 0.72), Color(0.42, 0.08, 0.72), Color(1.0, 0.32, 0.68),
]
const PART_COLORS := [Neon.ORANGE, Neon.CYAN, Neon.RED, Neon.PINK, Neon.YELLOW, Neon.LIME]

var _all: Array = []
## Cars of the section on show, and the one on the platform.
var _list: Array = []
var _index := 0
var _mode := "mine"
var _money_label: Label
var _rep_label: Label
var _name: Label
var _info: Label
var _status: Label
var _toast: Label
var _toast_t := 0.0
var _tabs := {}
var _back_button: Neon.NeonButton
var _paint_button: Neon.NeonButton
var _tune_button: Neon.NeonButton
var _action: Neon.NeonButton
var _sell: Neon.NeonButton
var _sell_armed := 0.0
var _arrows: Array[Button] = []
var _color_panel: PanelContainer
var _swatches: Array[Neon.Swatch] = []
var _tune_box: Control
var _tune_card: PanelContainer
var _tune_icon: Neon.NeonIcon
var _tune_title: Label
var _tune_what: Label
var _tune_dots: Array[UiKit.Icon] = []
var _tune_buy: Neon.NeonButton
var _tune_page: Label
## The part shown on the tuning card (index in Tuning.PARTS).
var _part := 0
var _paint_mats: Array[StandardMaterial3D] = []
var _view: SubViewportContainer
var _stage: Node3D
var _cam: Camera3D
var _preview: Node3D
var _car_length := 4.5
var _car_width := 1.8
var _shadow: FloorShadow
var _pending: Array[String] = []
var _loaded := {}
var _turn := 0.6
var _leaving := false


func _ready() -> void:
	DisplayServer.screen_set_keep_on(true)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_viewport().disable_3d = true
	SaveGame.load_game()
	_all = CarCatalog.available()

	var bg := TextureRect.new()
	bg.texture = load(BACKGROUND)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_shadow = FloorShadow.new()
	UiKit.anchor(_shadow, 0, 0, 1, 1)
	add_child(_shadow)
	# The car's 3D window covers the whole screen, so a big car is never cut.
	var win := UiKit.car_window(self)
	_view = win[0]
	UiKit.anchor(_view, 0, 0, 1, 1)
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage = win[1]
	_cam = win[2]
	_cam.fov = CAM_FOV
	resized.connect(_place_camera)
	_status = UiKit.label(28)
	_status.text = "Carico l'auto..."
	_status.set_anchors_preset(Control.PRESET_FULL_RECT)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_status)

	_build_header()
	_build_bottom()
	_build_color_panel()
	_build_tune_card()

	var start_mode := "mine"
	var show := SaveGame.car
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--dealercar="):
			show = a.substr(12)  # test aid: open on this car
		if a.begins_with("--tab="):
			start_mode = a.substr(6)  # test aid: mine, shop or tune
		if a == "--panel=tune":
			start_mode = "tune"
		if a.begins_with("--part="):
			_part = int(a.substr(7))  # test aid: tuning card shown
	_set_mode(start_mode, show)

	for a in args:
		if a.begins_with("--dealershot="):
			# Test aid: picture of the dealer (--panel=color opens the paints).
			if args.has("--panel=color"):
				_open_colors()
			if args.has("--sell"):
				_on_sell()
			await get_tree().create_timer(5.0).timeout
			get_viewport().get_texture().get_image().save_png(a.substr(13))
			get_tree().quit()


# ---------- Layout ----------

func _build_header() -> void:
	_back_button = Neon.NeonButton.new().setup("GARAGE", "garage", Neon.CYAN, true, 24)
	_back_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_back_button.offset_left = 18
	_back_button.offset_top = 14
	_back_button.offset_right = 158
	_back_button.offset_bottom = 154
	_back_button.pressed.connect(_back)
	add_child(_back_button)

	var labels := UiKit.money_and_rep(self)
	_money_label = labels[0]
	_rep_label = labels[1]

	var head := VBoxContainer.new()
	UiKit.anchor(head, 0.18, 0.0, 0.82, 0.0)
	head.offset_top = 4
	head.offset_bottom = 96
	head.add_theme_constant_override("separation", -6)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(head)
	_name = Neon.label(40, UiKit.GOLD, 10)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_name)
	_info = UiKit.label(22, Color(0.95, 0.93, 0.88))
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_info)

	# The three sections (v0.20, Stefano).
	var tabs := HBoxContainer.new()
	UiKit.anchor(tabs, 0.5, 0.0, 0.5, 0.0)
	tabs.offset_left = -300
	tabs.offset_right = 300
	tabs.offset_top = 102
	tabs.offset_bottom = 152
	tabs.add_theme_constant_override("separation", 14)
	add_child(tabs)
	for t in [["mine", "LE MIE AUTO", Neon.CYAN], ["shop", "IN VENDITA", Neon.YELLOW], ["tune", "TUNING", Neon.LIME]]:
		var b := Neon.NeonButton.new().setup(t[1], "", t[2], false, 22)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_on_tab.bind(t[0]))
		tabs.add_child(b)
		_tabs[t[0]] = b

	for dir in [-1, 1]:
		var b := UiKit.ArrowButton.new()
		b.dir = dir
		var x := 0.07 if dir < 0 else 0.93
		UiKit.anchor(b, x, 0.5, x, 0.5)
		b.offset_left = -45
		b.offset_right = 45
		b.offset_top = -50
		b.offset_bottom = 50
		b.pressed.connect(_step.bind(dir))
		add_child(b)
		_arrows.append(b)

	_toast = Neon.label(34, Color.WHITE, 12)
	_toast.set_anchors_preset(Control.PRESET_CENTER)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.offset_left = -500
	_toast.offset_right = 500
	_toast.offset_top = -150
	_toast.offset_bottom = -100
	_toast.visible = false
	add_child(_toast)


## VERNICIATURA bottom left, the main button (drive / buy / buy a new one) in the middle with
## VENDI beside it, TUNING bottom right.
func _build_bottom() -> void:
	_paint_button = Neon.NeonButton.new().setup("VERNICIATURA", "spray", Neon.PINK, true, 21)
	_paint_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_paint_button.offset_left = 18
	_paint_button.offset_right = 178
	_paint_button.offset_top = -158
	_paint_button.offset_bottom = -14
	_paint_button.pressed.connect(_open_colors)
	add_child(_paint_button)

	_tune_button = Neon.NeonButton.new().setup("TUNING", "tuning", Neon.LIME, true, 24)
	_tune_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_tune_button.offset_left = -158
	_tune_button.offset_right = -18
	_tune_button.offset_top = -158
	_tune_button.offset_bottom = -14
	_tune_button.pressed.connect(_on_tab.bind("tune"))
	add_child(_tune_button)

	_action = Neon.NeonButton.new().setup("", "key", Neon.GREEN, false, 28)
	_action.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_action.offset_left = -200
	_action.offset_right = 200
	_action.offset_top = -92
	_action.offset_bottom = -18
	_action.pressed.connect(_on_action)
	add_child(_action)

	_sell = Neon.NeonButton.new().setup("VENDI", "tag", Neon.RED, false, 22)
	_sell.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_sell.offset_left = 214
	_sell.offset_right = 444
	_sell.offset_top = -84
	_sell.offset_bottom = -26
	_sell.pressed.connect(_on_sell)
	add_child(_sell)


## The 15 paints in three rows, ORIGINALE (the car's own colours) and OK.
func _build_color_panel() -> void:
	_color_panel = PanelContainer.new()
	_color_panel.add_theme_stylebox_override("panel", Neon.plate(Neon.PINK, 18, 10, 0.85))
	UiKit.anchor(_color_panel, 0.0, 0.0, 0.0, 0.0)
	_color_panel.offset_left = 18
	_color_panel.offset_top = 168
	_color_panel.offset_right = 410
	_color_panel.visible = false
	add_child(_color_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_color_panel.add_child(box)
	var t := Neon.label(30, Neon.PINK, 8)
	t.text = "VERNICIATURA"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	for c in PALETTE:
		var s := Neon.Swatch.new()
		s.color = c
		s.custom_minimum_size = Vector2(66, 66)
		s.pressed.connect(_pick_color.bind(c))
		grid.add_child(s)
		_swatches.append(s)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var reset := Neon.NeonButton.new().setup("ORIGINALE", "", Neon.CYAN, false, 20)
	reset.custom_minimum_size = Vector2(0, 52)
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset.pressed.connect(_reset_color)
	row.add_child(reset)
	var ok := Neon.NeonButton.new().setup("OK", "", Neon.GREEN, false, 22)
	ok.custom_minimum_size = Vector2(100, 52)
	ok.pressed.connect(_close_colors)
	row.add_child(ok)


## TUNING as a catalogue (v0.21, Stefano): one card at the bottom right, the arrows beside it turn
## to the next part. The card: icon, name, what it does, the five stage dots, the price of the
## next stage and which page it is.
func _build_tune_card() -> void:
	_tune_box = Control.new()
	UiKit.anchor(_tune_box, 1.0, 1.0, 1.0, 1.0)
	_tune_box.offset_left = -470
	_tune_box.offset_right = -10
	_tune_box.offset_top = -372
	_tune_box.offset_bottom = -12
	_tune_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tune_box.visible = false
	add_child(_tune_box)
	_tune_card = PanelContainer.new()
	UiKit.anchor(_tune_card, 0.0, 0.0, 1.0, 1.0)
	_tune_card.offset_left = 62
	_tune_card.offset_right = -62
	_tune_box.add_child(_tune_card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_tune_card.add_child(box)
	_tune_icon = Neon.NeonIcon.new()
	_tune_icon.custom_minimum_size = Vector2(0, 92)
	box.add_child(_tune_icon)
	_tune_title = Neon.label(30, Color.WHITE, 7)
	_tune_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_tune_title)
	_tune_what = UiKit.label(16, Color(0.92, 0.92, 0.92), 4)
	_tune_what.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tune_what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tune_what.custom_minimum_size = Vector2(300, 42)
	box.add_child(_tune_what)
	var dots_row := HBoxContainer.new()
	dots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dots_row.add_theme_constant_override("separation", 6)
	box.add_child(dots_row)
	for k in Tuning.LEVELS:
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 0)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dots_row.add_child(cell)
		var d := UiKit.Icon.new()
		d.kind = "dot"
		d.custom_minimum_size = Vector2(50, 26)
		cell.add_child(d)
		var l := UiKit.label(13, Color(0.88, 0.88, 0.88), 3)
		l.text = "stage %d" % (k + 1)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(l)
		_tune_dots.append(d)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	box.add_child(spacer)
	_tune_buy = Neon.NeonButton.new().setup("", "", Color.WHITE, false, 21)
	_tune_buy.custom_minimum_size = Vector2(0, 54)
	_tune_buy.pressed.connect(func(): _buy_part(_part))
	box.add_child(_tune_buy)
	_tune_page = UiKit.label(15, Color(0.85, 0.85, 0.85), 4)
	_tune_page.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_tune_page)
	for dir in [-1, 1]:
		var b := UiKit.ArrowButton.new()
		b.dir = dir
		var x := 0.0 if dir < 0 else 1.0
		UiKit.anchor(b, x, 0.5, x, 0.5)
		b.offset_left = 0 if dir < 0 else -60
		b.offset_right = 60 if dir < 0 else 0
		b.offset_top = -45
		b.offset_bottom = 45
		b.pressed.connect(_turn_page.bind(dir))
		_tune_box.add_child(b)


func _turn_page(dir: int) -> void:
	_part = posmod(_part + dir, Tuning.PARTS.size())
	_refresh()


# ---------- Sections ----------

func _on_tab(mode: String) -> void:
	if _leaving or mode == _mode:
		return
	_set_mode(mode, _id() if not _list.is_empty() else SaveGame.car)


## Shows a section, on car `show` when it is in it (else on the car in use, else the first).
func _set_mode(mode: String, show := "") -> void:
	_mode = mode
	_close_colors()
	_list = []
	for entry in _all:
		var mine := SaveGame.owned.has(entry["id"])
		if mine == (mode != "shop"):
			_list.append(entry)
	_index = 0
	for want in [show, SaveGame.car]:
		var found := false
		for i in _list.size():
			if _list[i]["id"] == want:
				_index = i
				found = true
				break
		if found:
			break
	for k in _tabs:
		_tabs[k].active = k == mode
		_tabs[k].queue_redraw()
	_tune_box.visible = mode == "tune"
	_show_car()


# ---------- Showing a car ----------

func _id() -> String:
	return _list[_index]["id"] if not _list.is_empty() else ""


func _owned() -> bool:
	return SaveGame.owned.has(_id())


func _step(dir: int) -> void:
	if _leaving or _list.size() < 2:
		return
	_close_colors()
	_index = posmod(_index + dir, _list.size())
	_show_car()


func _show_car() -> void:
	_refresh()
	if _list.is_empty():
		if _preview:
			_preview.queue_free()
			_preview = null
		_name.text = ""
		_info.text = ""
		_status.text = "Hai già tutte le auto!"
		_status.visible = true
		return
	var entry: Dictionary = _list[_index]
	var id := _id()
	_name.text = entry["name"]
	var drive := {"RWD": "Trazione posteriore", "FWD": "Trazione anteriore", "AWD": "4 ruote motrici"}
	_info.text = "%d / %d   ·   %d km/h   ·   %s" % [_index + 1, _list.size(), CarCatalog.top_speed(id), drive[CarCatalog.drivetrain(id)]]
	if _mode == "tune":
		_info.text = "Stage montati: %d / %d" % [Tuning.points(id), Tuning.PARTS.size() * Tuning.LEVELS]
	var path := _model_file(entry)
	if _loaded.has(path) or ResourceLoader.has_cached(path):
		_build_preview()
		return
	if _preview:
		_preview.visible = false
	_status.text = "Carico l'auto..."
	_status.visible = true
	if not _pending.has(path):
		_pending.append(path)
		ResourceLoader.load_threaded_request(path)


## Buttons, prices and money after any change.
func _refresh() -> void:
	var id := _id()
	var owned := _owned()
	_money_label.text = UiKit.thousands(SaveGame.money)
	_rep_label.text = UiKit.thousands(SaveGame.reputation)
	var tune := _mode == "tune"
	for b in _arrows:
		b.visible = not tune and _list.size() > 1 and not _color_panel.visible
	_paint_button.visible = _mode == "mine" and owned
	_tune_button.visible = _mode == "mine" and owned
	_action.visible = not tune and id != ""
	_sell.visible = _mode == "mine" and owned and SaveGame.owned.size() > 1
	_sell_armed = 0.0
	if _sell.visible:
		_sell.set_caption("VENDI  %s $" % UiKit.thousands(Tuning.sale_value(id)))
	_action.disabled = false
	if _mode == "shop" and id != "":
		var price := CarCatalog.price(id)
		_action.icon_kind = "tag"
		_action.set_caption("COMPRA  %s $" % UiKit.thousands(price), Neon.YELLOW)
		_action.disabled = SaveGame.money < price
	elif id == SaveGame.car:
		# Stefano: on the car in use the button becomes "buy a new one".
		_action.icon_kind = "tag"
		_action.set_caption("ACQUISTA NUOVA", Neon.YELLOW)
	else:
		_action.icon_kind = "key"
		_action.set_caption("GUIDA QUESTA", Neon.GREEN)
	if tune and id != "":
		var lv := SaveGame.levels_of(id)
		var col: Color = PART_COLORS[_part]
		_tune_card.add_theme_stylebox_override("panel", Neon.plate(col, 22, 8, 0.85))
		_tune_icon.kind = Neon.PART_ICONS[_part]
		_tune_icon.neon = col
		_tune_icon.queue_redraw()
		_tune_title.text = Tuning.PARTS[_part].to_upper()
		_tune_title.add_theme_color_override("font_color", col)
		_tune_what.text = Tuning.describe(_part)
		for k in Tuning.LEVELS:
			_tune_dots[k].kind = "dot_on" if k < lv[_part] else "dot"
			_tune_dots[k].queue_redraw()
		_tune_buy.neon = col
		if lv[_part] >= Tuning.LEVELS:
			_tune_buy.set_caption("MAX")
			_tune_buy.disabled = true
		else:
			var cost := Tuning.cost(id, _part, lv[_part] + 1)
			_tune_buy.set_caption("STAGE %d · %s $" % [lv[_part] + 1, UiKit.thousands(cost)])
			_tune_buy.disabled = SaveGame.money < cost
		_tune_page.text = "%d / %d" % [_part + 1, Tuning.PARTS.size()]


func _model_file(entry: Dictionary) -> String:
	var baked := CarModel.baked_path(entry["id"])
	return baked if ResourceLoader.exists(baked) else CarCatalog.model_path(entry)


func _build_preview() -> void:
	_status.visible = false
	if _preview:
		_preview.queue_free()
	var id := _id()
	_preview = CarModel.build(Color(0, 0, 0, 0), false, id)
	_paint_mats.clear()
	if _owned():
		_paint_mats = CarModel.paint_model(_preview, id, SaveGame.color_of(id))
	_stage.add_child(_preview)
	_preview.rotation.y = _turn
	# Size of the car and how low it goes: it is lowered so the tyres touch the platform.
	var box := AABB()
	var first := true
	for mi in _preview.find_children("*", "MeshInstance3D", true, false):
		var bb: AABB = CarModel._xf_in(mi, _preview) * (mi as MeshInstance3D).get_aabb()
		box = bb if first else box.merge(bb)
		first = false
	_car_length = maxf(4.5, maxf(absf(box.position.z), absf(box.end.z)) * 2.0)
	var width := maxf(1.7, maxf(absf(box.position.x), absf(box.end.x)) * 2.0)
	_preview.position.y = -box.position.y if not first else 0.0
	_car_width = width
	_place_camera()


## The car's shadow on the floor of the picture (v0.21, Stefano: the car looked "stuck on" the
## picture). The 3D window has a see-through background, where Godot can't blend a transparent
## shadow, so the shadow is drawn in 2D right under it: the car's footprint, turned with the
## car, is projected on screen through the 3D camera and painted as soft dark layers.
class FloorShadow:
	extends Control
	## Footprint corners on screen, and a smaller, darker core under the tyres.
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		for pts_alpha in [[outer, 0.11, 9], [inner, 0.16, 6]]:
			var pts: PackedVector2Array = pts_alpha[0]
			if pts.size() < 3:
				continue
			var c := Vector2.ZERO
			for p in pts:
				c += p
			c /= pts.size()
			for i in pts_alpha[2]:
				var k: float = 1.0 - i * 0.09
				var layer := PackedVector2Array()
				for p in pts:
					layer.append(c + (p - c) * k)
				draw_colored_polygon(layer, Color(0, 0, 0, pts_alpha[1]))


func _update_shadow() -> void:
	if not _preview or not _preview.visible:
		_shadow.outer = PackedVector2Array()
		_shadow.inner = PackedVector2Array()
		_shadow.queue_redraw()
		return
	var basis := Basis(Vector3.UP, _turn)
	for which in 2:
		var hw := _car_width * (0.9 if which == 0 else 0.55)
		var hl := _car_length * (0.68 if which == 0 else 0.48)
		var pts := PackedVector2Array()
		# A rounded box: eight points around the car.
		for corner in [Vector2(-1, -0.7), Vector2(-0.7, -1), Vector2(0.7, -1), Vector2(1, -0.7),
				Vector2(1, 0.7), Vector2(0.7, 1), Vector2(-0.7, 1), Vector2(-1, 0.7)]:
			var local := Vector3(corner.x * hw, 0.0, corner.y * hl)
			pts.append(_cam.unproject_position(basis * local))
		if which == 0:
			_shadow.outer = pts
		else:
			_shadow.inner = pts
	_shadow.queue_redraw()


## Puts the camera so the car stands on the centre of the platform of the picture, as long as
## the platform is wide (CAR_FILL), on any screen: the picture covers the screen keeping its
## shape, so the platform's place on screen comes from the same scale and crop. In TUNING the
## car is smaller and moves left, beside the tuning card.
func _place_camera() -> void:
	if not _cam:
		return
	var screen := size
	if screen.y <= 0.0:
		return
	var s := maxf(screen.x / IMAGE_SIZE.x, screen.y / IMAGE_SIZE.y)
	var crop := (screen - IMAGE_SIZE * s) * 0.5
	var at := crop + PLATFORM_CENTER * s
	var length_px := PLATFORM_WIDTH * s * CAR_FILL
	if _mode == "tune":
		# Still on the platform, smaller and to the left of the tuning card.
		at.x = minf(at.x, screen.x - 480.0 - PLATFORM_WIDTH * s * 0.33)
		length_px *= 0.72
	var f := screen.y * 0.5 / tan(deg_to_rad(CAM_FOV * 0.5))
	var dist := _car_length * f / length_px
	var pitch := deg_to_rad(CAM_PITCH)
	_cam.position = Vector3(0, dist * sin(pitch), dist * cos(pitch))
	_cam.look_at(Vector3.ZERO, Vector3.UP)
	_cam.h_offset = -(at.x - screen.x * 0.5) * dist / f
	_cam.v_offset = (at.y - screen.y * 0.5) * dist / f
	_cam.far = dist * 4.0 + 50.0


func _process(delta: float) -> void:
	for path in _pending.duplicate():
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		_pending.erase(path)
		var res := ResourceLoader.load_threaded_get(path)
		_loaded[path] = res
		if res and not _list.is_empty() and _model_file(_list[_index]) == path and not _leaving:
			_build_preview()
	# Read the next and the previous car in the background; forget the others (little RAM).
	if _pending.is_empty() and not _leaving and not _list.is_empty():
		for step in [1, -1]:
			var next := _model_file(_list[posmod(_index + step, _list.size())])
			if not _loaded.has(next):
				_pending.append(next)
				ResourceLoader.load_threaded_request(next)
				break
		if _loaded.size() > 4:
			var keep := {}
			for step in [-1, 0, 1]:
				keep[_model_file(_list[posmod(_index + step, _list.size())])] = true
			for path in _loaded.keys():
				if not keep.has(path):
					_loaded.erase(path)
					CarModel.forget(CarCatalog.model_path(CarCatalog.find(path.get_file().get_basename())))
	_turn += delta * 0.3
	if _preview:
		_preview.rotation.y = _turn
	_update_shadow()
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t / 0.5, 0.0, 1.0)
		_toast.visible = _toast_t > 0.0
	if _sell_armed > 0.0:
		_sell_armed -= delta
		if _sell_armed <= 0.0:
			_refresh()


func _say(text: String, seconds := 2.5) -> void:
	_toast.text = text
	_toast.visible = true
	_toast.modulate.a = 1.0
	_toast_t = seconds


# ---------- Buying, selling, colour, tuning ----------

func _on_action() -> void:
	var id := _id()
	if id == "":
		return
	if _mode == "shop":
		var price := CarCatalog.price(id)
		if SaveGame.money < price:
			return
		SaveGame.money -= price
		SaveGame.owned.append(id)
		SaveGame.car = id
		SaveGame.save_game()
		_say("%s è tua!" % _list[_index]["name"])
		_set_mode("mine", id)
	elif id == SaveGame.car:
		_set_mode("shop")
	else:
		SaveGame.car = id
		SaveGame.save_game()
		_say("Guiderai la %s" % _list[_index]["name"])
		_refresh()


## First tap asks to confirm (the button shows the money), the second sells.
func _on_sell() -> void:
	var id := _id()
	if not _sell.visible or id == "":
		return
	if _sell_armed <= 0.0:
		_sell_armed = 3.0
		_sell.set_caption("SICURO? +%s $" % UiKit.thousands(Tuning.sale_value(id)))
		return
	var car_name: String = _list[_index]["name"]
	var got := SaveGame.sell(id)
	if got > 0:
		_say("%s venduta: +%s $" % [car_name, UiKit.thousands(got)])
		_set_mode("mine", SaveGame.car)


func _open_colors() -> void:
	if not _owned() or _mode != "mine":
		return
	_color_panel.visible = true
	_sync_swatches()
	_refresh()


func _close_colors() -> void:
	if _color_panel and _color_panel.visible:
		SaveGame.save_game()
		_color_panel.visible = false
		_refresh()


func _sync_swatches() -> void:
	var c := SaveGame.color_of(_id())
	for s in _swatches:
		s.chosen = c.a > 0.0 and s.color.is_equal_approx(Color(c.r, c.g, c.b))
		s.queue_redraw()


func _pick_color(c: Color) -> void:
	SaveGame.colors[_id()] = c
	if _paint_mats.is_empty() and _preview:
		_paint_mats = CarModel.paint_model(_preview, _id(), c)
	for m in _paint_mats:
		m.albedo_color = c
	_sync_swatches()


func _reset_color() -> void:
	SaveGame.colors.erase(_id())
	SaveGame.save_game()
	_build_preview()
	_sync_swatches()


func _buy_part(part: int) -> void:
	var id := _id()
	var lv := SaveGame.levels_of(id)
	if lv[part] >= Tuning.LEVELS:
		return
	var cost := Tuning.cost(id, part, lv[part] + 1)
	if SaveGame.money < cost:
		return
	SaveGame.money -= cost
	lv[part] += 1
	SaveGame.tuning[id] = lv
	SaveGame.save_game()
	_say("%s: stage %d" % [Tuning.PARTS[part], lv[part]])
	_refresh()
	_info.text = "Stage montati: %d / %d" % [Tuning.points(id), Tuning.PARTS.size() * Tuning.LEVELS]


# ---------- Leaving ----------

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not _leaving:
		if _color_panel.visible:
			_close_colors()
		elif _mode != "mine":
			_set_mode("mine")
		else:
			_back()


func _back() -> void:
	if _leaving:
		return
	_leaving = true
	SaveGame.save_game()
	await get_tree().process_frame
	if _preview:
		_preview.queue_free()
		_preview = null
	for path in _pending:
		ResourceLoader.load_threaded_get(path)
	_pending.clear()
	_loaded.clear()
	CarModel.clear_cache()
	get_tree().change_scene_to_file(GARAGE_SCENE)
