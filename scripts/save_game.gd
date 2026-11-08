class_name SaveGame
extends RefCounted
## The player's progress, kept on the phone in user://partita.cfg (v0.17): the cars owned and the
## one driven (the starting car, once chosen, stays: Stefano's rule; more can be bought at the
## dealer since v0.19), the colour and the tuning of each car, money, reputation and the next race
## of the campaign. How money and reputation are earned (Stefano): see Main (PRIZE, REP_*).

const FILE := "user://partita.cfg"
## Money of a new game.
const START_MONEY := 2000

## The car the player drives.
static var car := ""
## Every car the player owns, in the order they got them.
static var owned: Array = []
## Car id -> paint colour (cars not listed keep their own).
static var colors := {}
## Car id -> levels (0..Tuning.LEVELS) of the Tuning.PARTS, in that order.
static var tuning := {}
static var money := START_MONEY
static var reputation := 0
## Position in Main.CAMPAIGN of the next race.
static var race_index := 0
static var _loaded := false


static func load_game() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(FILE) != OK:
		return
	car = cfg.get_value("garage", "car", "")
	owned = cfg.get_value("garage", "owned", [])
	if car != "" and not owned.has(car):
		owned.append(car)  # saved by v0.17-v0.18, which knew only the starting car
	colors = cfg.get_value("garage", "colors", {})
	tuning = cfg.get_value("garage", "tuning", {})
	money = cfg.get_value("player", "money", START_MONEY)
	reputation = cfg.get_value("player", "reputation", 0)
	race_index = cfg.get_value("player", "race_index", 0)
	if not cfg.has_section_key("player", "version") and money == 0:
		money = START_MONEY  # saved by v0.17, when the game still started with 0


static func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("garage", "car", car)
	cfg.set_value("garage", "owned", owned)
	cfg.set_value("garage", "colors", colors)
	cfg.set_value("garage", "tuning", tuning)
	cfg.set_value("player", "money", money)
	cfg.set_value("player", "reputation", reputation)
	cfg.set_value("player", "race_index", race_index)
	cfg.set_value("player", "version", 3)
	cfg.save(FILE)


## Paint of a car: its saved colour, or alpha 0 for "its own colours".
static func color_of(id: String) -> Color:
	return colors.get(id, Color(0, 0, 0, 0))


## Levels of the tuning parts of a car.
static func levels_of(id: String) -> Array:
	var lv: Array = tuning.get(id, [])
	while lv.size() < Tuning.PARTS.size():
		lv.append(0)
	return lv


## Forgets everything (test aid: --reset-garage).
static func reset() -> void:
	car = ""
	owned = []
	colors = {}
	tuning = {}
	money = START_MONEY
	reputation = 0
	race_index = 0
	_loaded = true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
