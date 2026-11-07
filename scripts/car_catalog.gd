class_name CarCatalog
extends RefCounted
## Every car in the game: garage (player and rivals), police and traffic. Licences and authors:
## assets/LICENSES.md. Each one is a glTF scaled to "len" metres; "paint" and "tail" name the
## materials repainted by the game, "hide" lists parts left out, "tris" overrides the triangle
## budget of tools/bake_cars.gd, which prepares them all in assets/cars_baked.

const CARS := [
	# Garage: the player and the rivals drive these. Only CC BY models, sellable (Stefano, 2026-11-06);
	# real-brand models get invented names and their logos hidden.
	{"id": "phoenix_455", "name": "Phoenix 455 '71", "kind": "hd", "path": "res://assets/cars_cc/phoenix_455_71.glb", "len": 4.9},
	{"id": "tiara_gt83", "name": "Tiara GT '83 Tuned", "kind": "hd", "path": "res://assets/cars_cc/tiara_gt_83_tuned.glb", "len": 4.4},
	{"id": "saba_v12", "name": "Saba V12 '95", "kind": "hd", "path": "res://assets/cars_cc/saba_v12_95.glb", "len": 4.7},
	{"id": "goblin_v12", "name": "Goblin V12", "kind": "hd", "path": "res://assets/cars_cc/goblin_v12.glb", "len": 4.6, "yaw": 180},
	{"id": "kaze_r34", "name": "Kaze R-34", "kind": "hd", "path": "res://assets/cars_cc/skyline_r34_gtr.glb", "len": 4.6},
	{"id": "nova_sx", "name": "Nova SX '90", "kind": "hd", "path": "res://assets/cars_cc/nsx_1990.glb", "len": 4.4, "hide": ["Material.016"]},
	{"id": "shiro_13", "name": "Shiro 13", "kind": "hd", "path": "res://assets/cars_cc/silvia_s13.glb", "len": 4.5, "hide": ["Object_4", "Object_8"]},
	{"id": "shiro_14", "name": "Shiro 14", "kind": "hd", "path": "res://assets/cars_cc/silvia_s14.glb", "len": 4.5},
	{"id": "petalo_roadster", "name": "Petalo Roadster", "kind": "hd", "path": "res://assets/cars_cc/miata_na.glb", "len": 3.95, "hide": ["Plane_Material_005_0"]},
	{"id": "zenith_proto", "name": "Zenith Proto", "kind": "hd", "path": "res://assets/cars_cc/nissan_z_proto.glb", "len": 4.38},
	{"id": "falco_turbo", "name": "Falco Turbo '75", "kind": "hd", "path": "res://assets/cars_cc/porsche_930.glb", "len": 4.29},
	{"id": "kraft_sport", "name": "Kraft Sport '87", "kind": "hd", "path": "res://assets/cars_cc/bmw_m3_e30.glb", "len": 4.35, "hide": ["BMW_E30_M3_EMBLEMS", "Logo_Plane"]},
	{"id": "sakura_gt", "name": "Sakura GT '78", "kind": "hd", "path": "res://assets/cars_cc/datsun_280z.glb", "len": 4.4},
	{"id": "sterrato_evo", "name": "Sterrato Evo", "kind": "hd", "path": "res://assets/cars_cc/delta_integrale.glb", "len": 3.9, "hide": ["Logo"]},
	# Police.
	{"id": "police_illinois", "name": "Polizia Illinois '90", "kind": "hd", "path": "res://assets/cars_cc/illinois_90_police.glb", "len": 5.2},
	{"id": "police_negotiator", "name": "Polizia Negotiator '80", "kind": "hd", "path": "res://assets/cars_cc/negotiator_80_police.glb", "len": 5.4},
	{"id": "police_interceptor", "name": "Polizia Interceptor '01", "kind": "hd", "path": "res://assets/cars_cc/crown_victoria_police.glb", "len": 5.4},
	{"id": "police_car", "name": "Polizia berlina", "kind": "hd", "path": "res://assets/cars_cc/police_car.glb", "len": 5.1},
	# Traffic (the city vehicles from 2026-11-06 included).
	{"id": "t_ace_11", "name": "Ace '11", "kind": "hd", "path": "res://assets/cars_cc/ace_11.glb", "len": 3.9},
	{"id": "t_sigil_07", "name": "Sigil '07", "kind": "hd", "path": "res://assets/cars_cc/sigil_07.glb", "len": 4.4, "hide": ["Sigil08_Body_Badges_Carbadges_misc_U_0"]},
	{"id": "t_shvan_92", "name": "Ambulanza Shvan '92", "kind": "hd", "path": "res://assets/cars_cc/shvan_92.glb", "len": 5.0},
	{"id": "t_lightbody_tow", "name": "Carro attrezzi Lightbody '90", "kind": "hd", "path": "res://assets/cars_cc/lightbody_90_tow.glb", "len": 6.0},
	{"id": "t_lct_3000", "name": "LCT 3000 '07", "kind": "hd", "path": "res://assets/cars_cc/lct_3000_07.glb", "len": 5.9},
	{"id": "t_town_bus", "name": "Autobus di città", "kind": "hd", "path": "res://assets/cars_cc/town_bus.glb", "len": 11.0, "yaw": 270},
	{"id": "t_carter_98", "name": "Carter '98", "kind": "hd", "path": "res://assets/cars_cc/carter_98.glb", "len": 4.8},
	{"id": "t_conquer_89", "name": "Conquer '89 Pickup", "kind": "hd", "path": "res://assets/cars_cc/conquer_89_pickup.glb", "len": 5.2},
	{"id": "t_monarch_71", "name": "Monarch '71", "kind": "hd", "path": "res://assets/cars_cc/cutlass_71.glb", "len": 5.4, "yaw": 180, "hide": ["badges_M_Badge_0", "badges 2_M_Badge_0", "badge3_M_Badge_0", "Circle_002_M_Badge_0"]},
	{"id": "t_impala_1967", "name": "Cruiser '67", "kind": "hd", "path": "res://assets/cars_traffic/impala_1967.glb", "len": 5.4},
	{"id": "t_defender_90", "name": "Ranger 90", "kind": "hd", "path": "res://assets/cars_traffic/defender_90.glb", "len": 4.0, "hide": ["Object_22", "Object_57"]},
	{"id": "t_bmw_e46", "name": "Kraft Berlina '98", "kind": "hd", "path": "res://assets/cars_traffic/bmw_e46.glb", "len": 4.47},
	{"id": "t_jeep", "name": "Trail 4x4", "kind": "hd", "path": "res://assets/cars_traffic/jeep/scene.gltf", "len": 4.2, "tris": 62000},
]


## Driven wheels for each car: "RWD" (rear), "FWD" (front) or "AWD" (all four).
const RWD := ["phoenix_455", "tiara_gt83", "saba_v12", "goblin_v12", "nova_sx",
	"shiro_13", "shiro_14", "petalo_roadster", "zenith_proto", "falco_turbo", "kraft_sport", "sakura_gt",
	"police_illinois", "police_negotiator", "police_interceptor", "police_car"]
const AWD := ["kaze_r34", "sterrato_evo", "t_defender_90", "t_jeep"]


## Top speed in km/h without nitro. Cars not listed get DEFAULT_TOP_SPEED.
const DEFAULT_TOP_SPEED := 215.0
const TOP_SPEED := {
	"phoenix_455": 230.0, "tiara_gt83": 220.0, "saba_v12": 245.0, "goblin_v12": 260.0,
	"kaze_r34": 250.0, "nova_sx": 245.0, "shiro_13": 225.0, "shiro_14": 230.0,
	"petalo_roadster": 210.0, "zenith_proto": 250.0, "falco_turbo": 245.0, "kraft_sport": 230.0,
	"sakura_gt": 220.0, "sterrato_evo": 230.0, "police_illinois": 235.0, "police_negotiator": 235.0,
	"police_interceptor": 235.0, "police_car": 235.0,
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
	"t_carter_98", "t_conquer_89", "t_monarch_71", "t_impala_1967", "t_defender_90", "t_bmw_e46", "t_jeep",
	"t_ace_11", "t_sigil_07", "t_shvan_92", "t_lightbody_tow", "t_lct_3000", "t_town_bus",
]


## The cars in the garage, in the order the garage shows them (Stefano's pick). Rivals drive them too.
const GARAGE := [
	"phoenix_455", "tiara_gt83", "saba_v12", "goblin_v12", "kaze_r34", "nova_sx",
	"shiro_13", "shiro_14", "petalo_roadster", "zenith_proto", "falco_turbo", "kraft_sport",
	"sakura_gt", "sterrato_evo",
]


## The three cars offered in the starting garage (v0.17). Placeholders until Stefano picks the three.
const STARTER := ["phoenix_455", "kaze_r34", "falco_turbo"]


## Cars of the list (garage cars by default) whose model files are in this build.
static func available(ids: Array = GARAGE) -> Array:
	var out := []
	for id in ids:
		var c := find(id)
		if not c.is_empty() and (ResourceLoader.exists(CarModel.baked_path(id)) or ResourceLoader.exists(model_path(c))):
			out.append(c)
	return out


static func model_path(c: Dictionary) -> String:
	return c.get("path", "")
