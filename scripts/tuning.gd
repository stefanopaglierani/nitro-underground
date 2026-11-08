class_name Tuning
extends RefCounted
## Car tuning bought at the dealer (v0.19, Stefano): six parts, five levels each. Taking all six
## to the top costs about twice the price of the car; each part gets a slightly different share
## (fixed per car, so the prices never change). The effects on the player's car are applied by
## apply(), called by Car.setup; level 0 is the car as it comes.

const PARTS := ["Motore", "Centralina", "Scarico", "Nitro", "Freni", "Sospensioni"]
const LEVELS := 5
## Share of each level in the price of a part: later levels cost more.
const LEVEL_WEIGHT := [1.0, 1.5, 2.0, 2.5, 3.0]


## Price of taking `part` (index in PARTS) of car `id` from level - 1 to `level` (1..LEVELS).
static func cost(id: String, part: int, level: int) -> int:
	var total := 2.0 * CarCatalog.price(id)
	# Shares of the six parts: about one sixth each, a little more or less, fixed per car.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var shares: Array[float] = []
	var sum := 0.0
	for i in PARTS.size():
		var s := rng.randf_range(0.8, 1.2)
		shares.append(s)
		sum += s
	var weights := 0.0
	for w in LEVEL_WEIGHT:
		weights += w
	var price: float = total * shares[part] / sum * LEVEL_WEIGHT[level - 1] / weights
	return maxi(50, roundi(price / 50.0) * 50)


## What a part does, for the dealer page.
static func describe(part: int) -> String:
	match part:
		0: return "+4% spinta per livello"
		1: return "+2% spinta e +1,5% velocità max per livello"
		2: return "+2% spinta e +1% velocità max per livello"
		3: return "nitro più forte e più lunga"
		4: return "+6% frenata per livello"
		5: return "+2,5% aderenza per livello"
	return ""


## Applies the levels of car `id` (from SaveGame) to a player car already set up.
static func apply(car: Car, id: String) -> void:
	var lv := SaveGame.levels_of(id)
	var power: float = 1.0 + 0.04 * lv[0] + 0.02 * lv[1] + 0.02 * lv[2]
	var top: float = 1.0 + 0.015 * lv[1] + 0.01 * lv[2]
	car.engine_force *= power
	car.max_speed *= top
	car.nitro_force_mult += 0.06 * lv[3]
	car.nitro_drain *= 1.0 - 0.08 * lv[3]
	car.brake_force *= 1.0 + 0.06 * lv[4]
	car.grip *= 1.0 + 0.025 * lv[5]
