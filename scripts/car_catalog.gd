class_name CarCatalog
extends RefCounted
## Every car in the game: garage (player and rivals), police and traffic. Licences and authors:
## assets/LICENSES.md. Each one is a glTF scaled to "len" metres; "paint" and "tail" name the
## materials repainted by the game, "hide" lists parts left out, "tris" overrides the triangle
## budget of tools/bake_cars.gd, which prepares them all in assets/cars_baked.

const CARS := [
	# Garage: the player and the rivals drive these (Stefano's pick, 2026-11-05).
	{"id": "charger_1970", "name": "Dodge Charger R/T 1970", "kind": "hd", "path": "res://assets/cars_sketchfab/dodge_charger_1970/scene.gltf", "len": 5.3, "tail": "GlassRed"},
	{"id": "corvette_z06", "name": "Chevrolet Corvette Z06", "kind": "hd", "path": "res://assets/cars_sketchfab/corvette_z06/scene.gltf", "len": 4.46},
	{"id": "bmw_m3_gtr", "name": "BMW M3 GTR E46", "kind": "hd", "path": "res://assets/cars_sketchfab/bmw_m3_gtr.glb", "len": 4.5, "hide": ["back"], "wheel": ["material"]},
	{"id": "supra_a80", "name": "Toyota Supra A80", "kind": "hd", "path": "res://assets/cars_sketchfab/supra_a80/scene.gltf", "len": 4.52},
	{"id": "mercedes_w203", "name": "Mercedes Classe C W203", "kind": "hd", "path": "res://assets/cars_sketchfab/mercedes_w203.glb", "len": 4.53, "yaw": 270},
	# Police (2026-11-04).
	{"id": "police_mondeo", "name": "Polizia Ford Mondeo", "kind": "hd", "path": "res://assets/cars_sketchfab/police_mondeo.glb", "len": 4.85},
	{"id": "police_car", "name": "Polizia berlina", "kind": "hd", "path": "res://assets/cars_sketchfab/police_car.glb", "len": 5.1},
	# Traffic (Stefano's folder "Auto-scaricate", 2026-11-05).
	{"id": "t_corvette_1969", "name": "Corvette 1969", "kind": "hd", "path": "res://assets/cars_traffic/corvette_1969.glb", "len": 4.6},
	{"id": "t_camaro_2012", "name": "Camaro 2012", "kind": "hd", "path": "res://assets/cars_traffic/camaro_2012.glb", "len": 4.84},
	{"id": "t_camaro_zl1", "name": "Camaro ZL1", "kind": "hd", "path": "res://assets/cars_traffic/camaro_zl1.glb", "len": 4.84},
	{"id": "t_impala_1967", "name": "Impala 1967", "kind": "hd", "path": "res://assets/cars_traffic/impala_1967.glb", "len": 5.4},
	{"id": "t_gmc_sierra", "name": "GMC Sierra", "kind": "hd", "path": "res://assets/cars_traffic/gmc_sierra.glb", "len": 5.8},
	{"id": "t_defender_90", "name": "Defender 90", "kind": "hd", "path": "res://assets/cars_traffic/defender_90.glb", "len": 4.0},
	{"id": "t_bmw_e46", "name": "BMW E46", "kind": "hd", "path": "res://assets/cars_traffic/bmw_e46.glb", "len": 4.47},
	{"id": "t_mercedes_190e", "name": "Mercedes 190E", "kind": "hd", "path": "res://assets/cars_traffic/mercedes_190e.glb", "len": 4.45},
	{"id": "t_jeep", "name": "Jeep", "kind": "hd", "path": "res://assets/cars_traffic/jeep/scene.gltf", "len": 4.2, "tris": 62000},
]


## Driven wheels for each car: "RWD" (rear), "FWD" (front) or "AWD" (all four).
const RWD := ["charger_1970", "corvette_z06", "bmw_m3_gtr", "supra_a80", "mercedes_w203", "police_car"]
const AWD := ["t_defender_90", "t_jeep", "t_gmc_sierra"]


## Top speed in km/h without nitro. Cars not listed get DEFAULT_TOP_SPEED.
const DEFAULT_TOP_SPEED := 215.0
const TOP_SPEED := {
	"charger_1970": 230.0, "corvette_z06": 250.0, "bmw_m3_gtr": 245.0, "supra_a80": 245.0,
	"mercedes_w203": 225.0, "police_mondeo": 235.0, "police_car": 235.0,
}


static func top_speed(id: String) -> float:
	return TOP_SPEED.get(id, DEFAULT_TOP_SPEED)


static func drivetrain(id: String) -> String:
	if id in RWD:
		return "RWD"
	if id in AWD:
		return "AWD"
	return "FWD"


static func find(id: String) -> Dictionary:
	for c in CARS:
		if c["id"] == id:
			return c
	return {}


## Cars that drive in the traffic.
const TRAFFIC := [
	"t_corvette_1969", "t_camaro_2012", "t_camaro_zl1", "t_impala_1967", "t_gmc_sierra",
	"t_defender_90", "t_bmw_e46", "t_mercedes_190e", "t_jeep",
]


## The cars in the garage, in the order the garage shows them (Stefano's pick). Rivals drive them too.
const GARAGE := ["charger_1970", "corvette_z06", "bmw_m3_gtr", "supra_a80", "mercedes_w203"]


## Garage cars whose model files are in this build.
static func available() -> Array:
	var out := []
	for id in GARAGE:
		var c := find(id)
		if not c.is_empty() and (ResourceLoader.exists(CarModel.baked_path(id)) or ResourceLoader.exists(model_path(c))):
			out.append(c)
	return out


static func model_path(c: Dictionary) -> String:
	return c.get("path", "")
