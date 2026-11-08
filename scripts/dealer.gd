extends Control
## The dealer (v0.19, Stefano): every garage car on a turntable in a showroom, browsed with the
## arrows, with its price. Cars not owned can be bought with the money earned in the races; on a
## car the player owns, COLORE opens a classic RGB colour picker (the car changes colour live) and
## ELABORAZIONI the six tuning parts with five levels each (Tuning). Everything is kept in
## SaveGame. Opened from the garage (menu.gd), GARAGE goes back.

const GARAGE_SCENE := "res://scenes/menu.tscn"
const BACKGROUND := "res://assets/ui/dealer_bg.jpg"
const BLUE := Color(0.2, 0.5, 0.9)
const GREEN := Color(0.25, 0.8, 0.35)

var _cars: Array = []
var _index := 0
var _money_label: Label
var _rep_label: Label
var _name: Label
var _info: Label
var _status: Label
var _toast: Label
var _toast_t := 0.0
var _action: Button
var _color_button: Button
var _tune_button: Button
var _arrows: Array[Button] = []
var _color_panel: PanelContainer
var _sliders: Array[HSlider] = []
var _slider_values: Array[Label] = []
var _swatch: ColorRect
var _tune_panel: PanelContainer
var _tune_dots: Array = []  # per part: its 5 dot icons
var _tune_buttons: Array[Button] = []
var _paint_mats: Array[StandardMaterial3D] = []
var _syncing := false
var _stage: Node3D
var _cam: Camera3D
var _preview: Node3D
var _pending: Array[String] = []
var _loaded := {}
var _turn := 0.6
var _leaving := false


func _ready() -> void:
	DisplayServer.screen_set_keep_on(true)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_viewport().disable_3d = true
	SaveGame.load_game()
	_cars = CarCatalog.available()
	var show := SaveGame.car
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--dealercar="):
			show = a.substr(12)  # test aid: open on this car
	for i in _cars.size():
		if _cars[i]["id"] == show:
			_index = i

	var bg := TextureRect.new()
	bg.texture = load(BACKGROUND)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var win := UiKit.car_window(self)
	UiKit.anchor(win[0], 0.17, 0.3, 0.83, 0.93)
	_stage = win[1]
	_cam = win[2]
	_status = UiKit.label(26)
	_status.text = "Carico l'auto..."
	_status.set_anchors_preset(Control.PRESET_FULL_RECT)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	(win[0] as Control).add_child(_status)

	_build_header()
	_build_bottom()
	_build_color_panel()
	_build_tune_panel()
	_show_car()

	for a in OS.get_cmdline_user_args():
		if a.begins_with("--dealershot="):
			# Test aid: picture of the dealer (--panel=color or --panel=tune opens a panel).
			if OS.get_cmdline_user_args().has("--panel=color"):
				_open_panel(_color_panel)
			if OS.get_cmdline_user_args().has("--panel=tune"):
				_open_panel(_tune_panel)
			await get_tree().create_timer(5.0).timeout
			get_viewport().get_texture().get_image().save_png(a.substr(13))
			get_tree().quit()


# ---------- Layout ----------

func _build_header() -> void:
	var back := UiKit.button("‹ GARAGE", BLUE, 28)
	back.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back.offset_left = 20
	back.offset_top = 18
	back.offset_right = 220
	back.offset_bottom = 84
	back.pressed.connect(_back)
	add_child(back)

	var labels := UiKit.money_and_rep(self)
	_money_label = labels[0]
	_rep_label = labels[1]

	var head := VBoxContainer.new()
	UiKit.anchor(head, 0.22, 0.02, 0.78, 0.2)
	head.add_theme_constant_override("separation", -2)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(head)
	_name = UiKit.label(40, UiKit.GOLD, 12)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_name)
	_info = UiKit.label(22, Color(0.95, 0.93, 0.88))
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_info)

	for dir in [-1, 1]:
		var b := UiKit.ArrowButton.new()
		b.dir = dir
		var x := 0.1 if dir < 0 else 0.9
		UiKit.anchor(b, x, 0.55, x, 0.55)
		b.offset_left = -50
		b.offset_right = 50
		b.offset_top = -55
		b.offset_bottom = 55
		b.pressed.connect(_step.bind(dir))
		add_child(b)
		_arrows.append(b)

	_toast = UiKit.label(32, Color.WHITE, 12)
	_toast.set_anchors_preset(Control.PRESET_CENTER)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.offset_left = -500
	_toast.offset_right = 500
	_toast.offset_top = -120
	_toast.offset_bottom = -70
	_toast.visible = false
	add_child(_toast)


## COLORE bottom left, the main button (buy / drive) bottom centre, ELABORAZIONI bottom right.
func _build_bottom() -> void:
	_color_button = UiKit.button("COLORE", Color(0.75, 0.3, 0.8), 30)
	_color_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_color_button.offset_left = 24
	_color_button.offset_right = 250
	_color_button.offset_top = -100
	_color_button.offset_bottom = -24
	_color_button.pressed.connect(func(): _open_panel(_color_panel))
	add_child(_color_button)

	_tune_button = UiKit.button("ELABORAZIONI", Color(0.95, 0.55, 0.1), 30)
	_tune_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_tune_button.offset_left = -300
	_tune_button.offset_right = -24
	_tune_button.offset_top = -100
	_tune_button.offset_bottom = -24
	_tune_button.pressed.connect(func(): _open_panel(_tune_panel))
	add_child(_tune_button)

	_action = UiKit.button("", GREEN, 32)
	_action.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_action.offset_left = -190
	_action.offset_right = 190
	_action.offset_top = -100
	_action.offset_bottom = -24
	_action.pressed.connect(_on_action)
	add_child(_action)


func _side_panel(left: bool, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.box(Color(0.05, 0.05, 0.07, 0.88), Color(1, 1, 1, 0.35), 14))
	if left:
		UiKit.anchor(panel, 0.0, 0.14, 0.0, 0.14)
		panel.offset_left = 20
		panel.offset_right = 400
	else:
		UiKit.anchor(panel, 1.0, 0.14, 1.0, 0.14)
		panel.offset_left = -470
		panel.offset_right = -20
	panel.visible = false
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var t := UiKit.label(30, UiKit.GOLD, 10)
	t.text = title
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var close := UiKit.button("OK", GREEN, 24)
	close.custom_minimum_size = Vector2(80, 48)
	close.pressed.connect(_close_panels)
	head.add_child(close)
	return box


## Classic RGB picker: three sliders 0-255, the colour shown beside them.
func _build_color_panel() -> void:
	var box := _side_panel(true, "COLORE")
	_color_panel = box.get_parent()
	var names := ["R", "G", "B"]
	var tints := [Color(1, 0.3, 0.3), Color(0.3, 1, 0.4), Color(0.4, 0.6, 1)]
	for i in 3:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		box.add_child(row)
		var l := UiKit.label(28, tints[i])
		l.text = names[i]
		l.custom_minimum_size = Vector2(30, 0)
		row.add_child(l)
		var s := HSlider.new()
		s.min_value = 0
		s.max_value = 255
		s.step = 1
		s.custom_minimum_size = Vector2(0, 48)
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var grab := _grabber(tints[i])
		s.add_theme_icon_override("grabber", grab)
		s.add_theme_icon_override("grabber_highlight", grab)
		var track := StyleBoxFlat.new()
		track.bg_color = Color(1, 1, 1, 0.2)
		track.set_corner_radius_all(6)
		track.content_margin_top = 6
		track.content_margin_bottom = 6
		s.add_theme_stylebox_override("slider", track)
		var fill := track.duplicate() as StyleBoxFlat
		fill.bg_color = tints[i]
		s.add_theme_stylebox_override("grabber_area", fill)
		s.add_theme_stylebox_override("grabber_area_highlight", fill)
		s.value_changed.connect(_on_color_slider)
		row.add_child(s)
		_sliders.append(s)
		var v := UiKit.label(24)
		v.custom_minimum_size = Vector2(52, 0)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(v)
		_slider_values.append(v)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	_swatch = ColorRect.new()
	_swatch.custom_minimum_size = Vector2(120, 50)
	row.add_child(_swatch)
	var reset := UiKit.button("ORIGINALE", BLUE, 22)
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset.pressed.connect(_reset_color)
	row.add_child(reset)


func _grabber(color: Color) -> ImageTexture:
	var img := Image.create(34, 34, false, Image.FORMAT_RGBA8)
	for y in 34:
		for x in 34:
			var d := Vector2(x - 16.5, y - 16.5).length()
			if d < 16.0:
				img.set_pixel(x, y, Color.WHITE if d > 12.0 else color)
	return ImageTexture.create_from_image(img)


## Six rows: part name, five level dots, the price of the next level.
func _build_tune_panel() -> void:
	var box := _side_panel(false, "ELABORAZIONI")
	_tune_panel = box.get_parent()
	for part in Tuning.PARTS.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		box.add_child(row)
		var l := UiKit.label(24)
		l.text = Tuning.PARTS[part]
		l.custom_minimum_size = Vector2(150, 0)
		l.tooltip_text = Tuning.describe(part)
		row.add_child(l)
		var dots := []
		for k in Tuning.LEVELS:
			var d := UiKit.Icon.new()
			d.kind = "dot"
			d.custom_minimum_size = Vector2(22, 22)
			d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(d)
			dots.append(d)
		_tune_dots.append(dots)
		var b := UiKit.button("", GREEN, 20)
		b.custom_minimum_size = Vector2(130, 46)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_buy_part.bind(part))
		row.add_child(b)
		_tune_buttons.append(b)


# ---------- Showing a car ----------

func _id() -> String:
	return _cars[_index]["id"]


func _owned() -> bool:
	return SaveGame.owned.has(_id())


func _step(dir: int) -> void:
	if _leaving or _cars.size() < 2:
		return
	_close_panels()
	_index = posmod(_index + dir, _cars.size())
	_show_car()


func _show_car() -> void:
	var entry: Dictionary = _cars[_index]
	var id := _id()
	_name.text = entry["name"]
	var drive := {"RWD": "Trazione posteriore", "FWD": "Trazione anteriore", "AWD": "4 ruote motrici"}
	_info.text = "%d / %d   ·   %d km/h   ·   %s" % [_index + 1, _cars.size(), CarCatalog.top_speed(id), drive[CarCatalog.drivetrain(id)]]
	_refresh()
	var path := _model_file(entry)
	if _loaded.has(path) or ResourceLoader.has_cached(path):
		_build_preview()
		return
	if _preview:
		_preview.visible = false
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
	_color_button.visible = owned
	_tune_button.visible = owned
	if not owned:
		var price := CarCatalog.price(id)
		_action.text = "COMPRA  %s $" % UiKit.thousands(price)
		_action.disabled = SaveGame.money < price
	elif id == SaveGame.car:
		_action.text = "IN USO"
		_action.disabled = true
	else:
		_action.text = "GUIDA QUESTA"
		_action.disabled = false
	var lv := SaveGame.levels_of(id)
	for part in Tuning.PARTS.size():
		for k in Tuning.LEVELS:
			var d: UiKit.Icon = _tune_dots[part][k]
			d.kind = "dot_on" if k < lv[part] else "dot"
			d.queue_redraw()
		var b := _tune_buttons[part]
		if lv[part] >= Tuning.LEVELS:
			b.text = "MAX"
			b.disabled = true
		else:
			var cost := Tuning.cost(id, part, lv[part] + 1)
			b.text = "+ %s $" % UiKit.thousands(cost)
			b.disabled = SaveGame.money < cost


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
	UiKit.frame_car(_preview, _cam, 1.4, 1.2)


func _process(delta: float) -> void:
	for path in _pending.duplicate():
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		_pending.erase(path)
		var res := ResourceLoader.load_threaded_get(path)
		_loaded[path] = res
		if res and _model_file(_cars[_index]) == path and not _leaving:
			_build_preview()
	# Read the next and the previous car in the background; forget the others (little RAM).
	if _pending.is_empty() and not _leaving:
		for step in [1, -1]:
			var next := _model_file(_cars[posmod(_index + step, _cars.size())])
			if not _loaded.has(next):
				_pending.append(next)
				ResourceLoader.load_threaded_request(next)
				break
		if _loaded.size() > 4:
			var keep := {}
			for step in [-1, 0, 1]:
				keep[_model_file(_cars[posmod(_index + step, _cars.size())])] = true
			for path in _loaded.keys():
				if not keep.has(path):
					_loaded.erase(path)
					CarModel.forget(CarCatalog.model_path(CarCatalog.find(path.get_file().get_basename())))
	_turn += delta * 0.3
	if _preview:
		_preview.rotation.y = _turn
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t / 0.5, 0.0, 1.0)
		_toast.visible = _toast_t > 0.0


func _say(text: String, seconds := 2.5) -> void:
	_toast.text = text
	_toast.visible = true
	_toast.modulate.a = 1.0
	_toast_t = seconds


# ---------- Buying, colour, tuning ----------

func _on_action() -> void:
	var id := _id()
	if not _owned():
		var price := CarCatalog.price(id)
		if SaveGame.money < price:
			return
		SaveGame.money -= price
		SaveGame.owned.append(id)
		SaveGame.car = id
		SaveGame.save_game()
		_say("%s è tua!" % _cars[_index]["name"])
		_build_preview()
	else:
		SaveGame.car = id
		SaveGame.save_game()
		_say("Guiderai la %s" % _cars[_index]["name"])
	_refresh()


func _open_panel(panel: PanelContainer) -> void:
	if not _owned():
		return
	_close_panels()
	panel.visible = true
	for b in _arrows:
		b.visible = false
	if panel == _color_panel:
		_sync_sliders()


func _close_panels() -> void:
	if _color_panel.visible:
		SaveGame.save_game()
	_color_panel.visible = false
	_tune_panel.visible = false
	for b in _arrows:
		b.visible = true


## Sliders on the car's colour: the chosen one, or its paint as the model has it.
func _sync_sliders() -> void:
	var c := SaveGame.color_of(_id())
	if c.a <= 0.0:
		c = _original_color()
	_syncing = true
	for i in 3:
		_sliders[i].value = roundi(c[i] * 255.0)
		_slider_values[i].text = str(roundi(c[i] * 255.0))
	_syncing = false
	_swatch.color = Color(c.r, c.g, c.b)


func _original_color() -> Color:
	var key: String = CarCatalog.find(_id()).get("paint", "")
	if _preview:
		for n in _preview.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			for i in mi.mesh.get_surface_count():
				var m := mi.mesh.surface_get_material(i)
				if m is StandardMaterial3D and m.resource_name == key:
					return (m as StandardMaterial3D).albedo_color
	return Color.WHITE


func _on_color_slider(_v: float) -> void:
	if _syncing:
		return
	var c := Color(_sliders[0].value / 255.0, _sliders[1].value / 255.0, _sliders[2].value / 255.0)
	for i in 3:
		_slider_values[i].text = str(int(_sliders[i].value))
	_swatch.color = c
	SaveGame.colors[_id()] = c
	if _paint_mats.is_empty() and _preview:
		_paint_mats = CarModel.paint_model(_preview, _id(), c)
	for m in _paint_mats:
		m.albedo_color = c


func _reset_color() -> void:
	SaveGame.colors.erase(_id())
	SaveGame.save_game()
	_build_preview()
	_sync_sliders()


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
	_say("%s: livello %d" % [Tuning.PARTS[part], lv[part]])
	_refresh()


# ---------- Leaving ----------

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not _leaving:
		if _color_panel.visible or _tune_panel.visible:
			_close_panels()
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
