class_name SaveGame
extends RefCounted
## The player's progress, kept on the phone in user://partita.cfg (v0.17): the car chosen in the
## garage (once chosen it stays, Stefano's rule), money and reputation. Money and reputation are
## only shown for now: no race changes them yet.

const FILE := "user://partita.cfg"

static var car := ""
static var money := 0
static var reputation := 0
static var _loaded := false


static func load_game() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(FILE) != OK:
		return
	car = cfg.get_value("garage", "car", "")
	money = cfg.get_value("player", "money", 0)
	reputation = cfg.get_value("player", "reputation", 0)


static func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("garage", "car", car)
	cfg.set_value("player", "money", money)
	cfg.set_value("player", "reputation", reputation)
	cfg.save(FILE)


## Forgets everything (test aid: --reset-garage).
static func reset() -> void:
	car = ""
	money = 0
	reputation = 0
	_loaded = true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
