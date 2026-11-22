class_name CarCatalog
extends RefCounted
## Every car in the game: garage (player and rivals), police and traffic. Licences and authors:
## assets/LICENSES.md. Each one is a glTF scaled to "len" metres; "paint" and "tail" name the
## materials repainted by the game, "hide" lists parts left out, "tris" overrides the triangle
## budget of tools/bake_cars.gd, which prepares them all in assets/cars_baked.

const CARS := [
	# Garage: the player and the rivals drive these. Only CC BY models, sellable (Stefano, 2026-11-06);
	# real-brand models get invented names and their logos hidden.
	{"id": "phoenix_455", "name": "Phoenix 455 '71", "kind": "hd", "path": "res://assets/cars_cc/phoenix_455_71.glb", "len": 4.9, "paint": "Phoenix445_Bodymat"},
	{"id": "tiara_gt83", "name": "Tiara GT '83 Tuned", "kind": "hd", "path": "res://assets/cars_cc/tiara_gt_83_tuned.glb", "len": 4.4, "paint": "TiaraGT83_Bodymat"},
	{"id": "saba_v12", "name": "Saba V12 '95", "kind": "hd", "path": "res://assets/cars_cc/saba_v12_95.glb", "len": 4.7, "paint": "Saba95_Bodymat"},
	{"id": "goblin_v12", "name": "Goblin V12", "kind": "hd", "path": "res://assets/cars_cc/goblin_v12.glb", "len": 4.6, "yaw": 180, "paint": "clearcoat", "paint_grow": 0.004},
	{"id": "kaze_r34", "name": "Kaze R-34", "kind": "hd", "path": "res://assets/cars_cc/skyline_r34_gtr.glb", "len": 4.6, "paint": "Material.001"},
	{"id": "nova_sx", "name": "Nova SX '90", "kind": "hd", "path": "res://assets/cars_cc/nsx_1990.glb", "len": 4.4, "hide": ["Material.016"], "paint": "Material.003"},
	{"id": "shiro_13", "name": "Shiro 13", "kind": "hd", "path": "res://assets/cars_cc/silvia_s13.glb", "len": 4.5, "hide": ["Object_4", "Object_8"], "paint": "CarPaint"},
	{"id": "shiro_14", "name": "Shiro 14", "kind": "hd", "path": "res://assets/cars_cc/silvia_s14.glb", "len": 4.5, "paint": "Material.003"},
	{"id": "petalo_roadster", "name": "Petalo Roadster", "kind": "hd", "path": "res://assets/cars_cc/miata_na.glb", "len": 3.95, "hide": ["Plane_Material_005_0"], "paint": "Material.002"},
	{"id": "zenith_proto", "name": "Zenith Proto", "kind": "hd", "path": "res://assets/cars_cc/nissan_z_proto.glb", "len": 4.38, "paint": "Material.001"},
	{"id": "falco_turbo", "name": "Falco Turbo '75", "kind": "hd", "path": "res://assets/cars_cc/porsche_930.glb", "len": 4.29, "paint": "Material.001"},
	{"id": "kraft_sport", "name": "Kraft Sport '87", "kind": "hd", "path": "res://assets/cars_cc/bmw_m3_e30.glb", "len": 4.35, "hide": ["BMW_E30_M3_EMBLEMS", "Logo_Plane"], "paint": "BMW_E30_M3_PAINT"},
	{"id": "sakura_gt", "name": "Sakura GT '78", "kind": "hd", "path": "res://assets/cars_cc/datsun_280z.glb", "len": 4.4, "paint": "280z_CarPaint"},
	{"id": "sterrato_evo", "name": "Sterrato Evo", "kind": "hd", "path": "res://assets/cars_cc/delta_integrale.glb", "len": 3.9, "hide": ["Logo"], "paint": "Paint"},
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
	# v0.28 (Stefano 22/11/2026: "nel Dealer fammi trovare TUTTE le auto a disposizione, così posso
	# fare una cernita"): the other CC BY cars of Asset-3D\Auto, on sale at the dealer to try them.
	# Only their prepared light versions (assets/cars_baked) are in the repository; the originals
	# stay in Asset-3D\Auto and are copied to assets/cars_new (ignored by git) to prepare them again.
	# Real brands get invented names here; their logos are not removed yet (see assets/LICENSES.md).
	{"id": "m10_86", "name": "Militare M10 '86", "kind": "hd", "path": "res://assets/cars_new/1986_chevrolet_m1009.glb", "len": 4.7},
	{"id": "stella_c00", "name": "Stella C '00", "kind": "hd", "path": "res://assets/cars_new/2000_mercedes_c-class_w203.glb", "len": 4.53},
	{"id": "corsaro_zl", "name": "Corsaro ZL '12", "kind": "hd", "path": "res://assets/cars_new/2012_chevrolet_camaro_zl1.glb", "len": 4.84},
	{"id": "land_explorer", "name": "Land Explorer", "kind": "hd", "path": "res://assets/cars_new/a_land_explorer.glb", "len": 4.8},
	{"id": "bokaroo_67", "name": "Bokaroo '67", "kind": "hd", "path": "res://assets/cars_new/bokaroo_67.glb", "len": 4.6},
	{"id": "buggy_dune", "name": "Buggy Dune", "kind": "hd", "path": "res://assets/cars_new/buggy_2.glb", "len": 4.0},
	{"id": "pickup_63", "name": "Pickup C10 '63", "kind": "hd", "path": "res://assets/cars_new/chevrolet_c10_pickup_1963.glb", "len": 4.9},
	{"id": "jump_buggy", "name": "Jump Buggy", "kind": "hd", "path": "res://assets/cars_new/dune_buggy_jump.glb", "len": 3.9},
	{"id": "el_alamo_78", "name": "El Alamo '78", "kind": "hd", "path": "res://assets/cars_new/el_alamo_78.glb", "len": 5.1},
	{"id": "lightbody_lifted", "name": "Lightbody Lifted '85", "kind": "hd", "path": "res://assets/cars_new/lightbody_lifted_85.glb", "len": 4.9},
	{"id": "rotore_fd", "name": "Rotore FD", "kind": "hd", "path": "res://assets/cars_new/mazda_rx_7_fd.glb", "len": 4.3},
	{"id": "stella_190", "name": "Stella 190 Evo", "kind": "hd", "path": "res://assets/cars_new/mercedes_190e_evo_1982_3d_model_free.glb", "len": 4.49},
	{"id": "stella_g", "name": "Stella G", "kind": "hd", "path": "res://assets/cars_new/mercedes_benz_g_class_w263.glb", "len": 4.82},
	{"id": "muscle_concept", "name": "Muscle Concept", "kind": "hd", "path": "res://assets/cars_new/muscle_car_concept.glb", "len": 4.8},
	{"id": "sakura_4x4", "name": "Sakura 4x4", "kind": "hd", "path": "res://assets/cars_new/nissan_4x4.glb", "len": 4.7},
	{"id": "steppa_4x4", "name": "Steppa 4x4", "kind": "hd", "path": "res://assets/cars_new/no_budget_soviet_jeep.glb", "len": 4.0},
	{"id": "offroad_racer", "name": "Off-Road Racer", "kind": "hd", "path": "res://assets/cars_new/off_road_4x4_racer_with_4_different_skins.glb", "len": 4.2},
	{"id": "rancher_50", "name": "Rancher '50 Custom", "kind": "hd", "path": "res://assets/cars_new/rancher_50_custom.glb", "len": 4.95},
	{"id": "rancher_80", "name": "Rancher '80 Lifted", "kind": "hd", "path": "res://assets/cars_new/rancher_80_lifted.glb", "len": 4.95},
	{"id": "pickup_hilo", "name": "Pickup Hilo", "kind": "hd", "path": "res://assets/cars_new/toyota_pickup_truck.glb", "len": 4.4},
]

## The cars added in v0.28 (in CARS above), in the order the dealer shows them.
const NEW := [
	"corsaro_zl", "muscle_concept", "rotore_fd", "stella_190", "stella_c00", "bokaroo_67", "el_alamo_78",
	"rancher_50", "pickup_63", "pickup_hilo", "rancher_80", "lightbody_lifted", "sakura_4x4", "stella_g",
	"land_explorer", "m10_86", "steppa_4x4", "offroad_racer", "buggy_dune", "jump_buggy",
]


## Driven wheels for each car: "RWD" (rear), "FWD" (front) or "AWD" (all four).
const RWD := ["phoenix_455", "tiara_gt83", "saba_v12", "goblin_v12", "nova_sx",
	"shiro_13", "shiro_14", "petalo_roadster", "zenith_proto", "falco_turbo", "kraft_sport", "sakura_gt",
	"police_illinois", "police_negotiator", "police_interceptor", "police_car",
	"corsaro_zl", "muscle_concept", "rotore_fd", "stella_190", "stella_c00", "bokaroo_67", "el_alamo_78",
	"rancher_50", "pickup_63", "pickup_hilo", "buggy_dune", "jump_buggy", "t_monarch_71", "t_impala_1967"]
const AWD := ["kaze_r34", "sterrato_evo", "t_defender_90", "t_jeep",
	"rancher_80", "lightbody_lifted", "sakura_4x4", "stella_g", "land_explorer", "m10_86", "steppa_4x4", "offroad_racer"]


## Top speed in km/h without nitro. Cars not listed get DEFAULT_TOP_SPEED.
const DEFAULT_TOP_SPEED := 215.0
const TOP_SPEED := {
	"phoenix_455": 230.0, "tiara_gt83": 220.0, "saba_v12": 245.0, "goblin_v12": 260.0,
	"kaze_r34": 250.0, "nova_sx": 245.0, "shiro_13": 225.0, "shiro_14": 230.0,
	"petalo_roadster": 210.0, "zenith_proto": 250.0, "falco_turbo": 245.0, "kraft_sport": 230.0,
	"sakura_gt": 220.0, "sterrato_evo": 230.0, "police_illinois": 235.0, "police_negotiator": 235.0,
	"police_interceptor": 235.0, "police_car": 235.0,
	# v0.28: first guesses by Claude from the kind of car, to be tuned with Stefano.
	"corsaro_zl": 265.0, "muscle_concept": 260.0, "rotore_fd": 250.0, "stella_190": 235.0,
	"stella_c00": 225.0, "bokaroo_67": 200.0, "el_alamo_78": 195.0, "rancher_50": 185.0,
	"pickup_63": 175.0, "pickup_hilo": 175.0, "rancher_80": 170.0, "lightbody_lifted": 170.0,
	"sakura_4x4": 170.0, "stella_g": 210.0, "land_explorer": 175.0, "m10_86": 160.0,
	"steppa_4x4": 140.0, "offroad_racer": 195.0, "buggy_dune": 185.0, "jump_buggy": 185.0,
	"t_town_bus": 120.0, "t_lightbody_tow": 150.0, "t_lct_3000": 150.0, "t_shvan_92": 170.0,
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


## Dealer price of each garage car (v0.19). The three starting cars are worth 9.000 (Stefano);
## the others are priced by Claude on their top speed, to be tuned.
const PRICE := {
	"phoenix_455": 9000, "kaze_r34": 9000, "falco_turbo": 9000,
	"petalo_roadster": 10000, "tiara_gt83": 11000, "shiro_13": 12000, "sakura_gt": 13000,
	"shiro_14": 14000, "kraft_sport": 16000, "sterrato_evo": 20000, "nova_sx": 22000,
	"saba_v12": 25000, "zenith_proto": 28000, "goblin_v12": 40000,
}


static func price(id: String) -> int:
	return PRICE.get(id, 15000)


## Every car the dealer sells (v0.28, Stefano: all the cars of the project, to pick from): the
## garage cars first, then the new ones, the traffic and the police. Cars not in PRICE cost 15.000.
static func shop() -> Array:
	return GARAGE + NEW + TRAFFIC + Car.POLICE_BODIES


## The three cars offered in the starting garage (v0.17). Placeholders, kept by Stefano.
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
