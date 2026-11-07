class_name SaveGame
extends RefCounted
## The player's progress, kept on the phone in user://partita.cfg (v0.17): the car chosen in the
## garage (once chosen it stays, Stefano's rule), money and reputation. How they are earned
## (Stefano, v0.18): see Main (PRIZE, REP_*).

const FILE := "user://partita.cfg"
## Money of a new game.
const START_MONEY := 2000

static var car := ""
static var money := START_MONEY
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
	money = cfg.get_value("player", "money", START_MONEY)
	reputation = cfg.get_value("player", "reputation", 0)
	if not cfg.has_section_key("player", "version") and money == 0:
		money = START_MONEY  # saved by v0.17, when the game still started with 0


static func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("garage", "car", car)
	cfg.set_value("player", "money", money)
	cfg.set_value("player", "reputation", reputation)
	cfg.set_value("player", "version", 2)
	cfg.save(FILE)


## Forgets everything (test aid: --reset-garage).
static func reset() -> void:
	car = ""
	money = START_MONEY
	reputation = 0
	_loaded = true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
