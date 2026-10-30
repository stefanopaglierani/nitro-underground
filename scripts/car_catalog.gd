class_name CarCatalog
extends RefCounted
## Every car the player can pick in the garage. Licences and authors: assets/LICENSES.md.
## "kind" says which builder in CarModel makes it: hd and kenney (generic glTF, scaled to "len"
## metres), rgsdev (FBX with named materials), kaykit (city kit, repainted by a shader).

const CARS := [
	{"id": "mclaren_600lt", "name": "McLaren 600LT", "kind": "hd", "path": "res://assets/cars_sketchfab/mclaren_600lt/scene.gltf", "len": 4.6, "paint": "mM_CarPaint_Max1", "tail": "mM_LightGlass_Red_Low1"},
	{"id": "ford_raptor_r", "name": "Ford F-150 Raptor R", "kind": "hd", "path": "res://assets/cars_sketchfab/2024_ford_f-150_raptor_r/scene.gltf", "len": 5.9, "paint": "RaptorPaaint", "tail": ""},
	{"id": "ram_1500_trx", "name": "RAM 1500 TRX", "kind": "hd", "path": "res://assets/cars_sketchfab/2021_ram_1500_trx/scene.gltf", "len": 5.9, "paint": "RAM_1500TRX_2021Paint_Material", "tail": "RED_GLASS"},
	{"id": "skyline_r34", "name": "Nissan Skyline GT-R R34", "kind": "hd", "path": "res://assets/cars_sketchfab/nissan-skyline-r34.glb", "len": 4.6},
	{"id": "silvia_s15", "name": "Nissan Silvia S15 Drift", "kind": "hd", "path": "res://assets/cars_sketchfab/nissan-silvia-s15-drift.glb", "len": 4.45, "paint": "CAR_BODY_PAINT"},
	{"id": "mr2_w20", "name": "Toyota MR2 W20", "kind": "hd", "path": "res://assets/cars_sketchfab/toyota-mr2-w20.glb", "len": 4.2, "paint": "body_paint"},
	{"id": "bmw_m3_e36", "name": "BMW M3 E36", "kind": "hd", "path": "res://assets/cars_sketchfab/bmw-m3-e36.glb", "len": 4.4, "paint": "yellow"},
	{"id": "mustang_gt", "name": "Ford Mustang GT 2013", "kind": "hd", "path": "res://assets/cars_sketchfab/ford-mustang-gt-2013.glb", "len": 4.8},
	{"id": "kiri_86", "name": "Kiri '86", "kind": "hd", "path": "res://assets/cars_sketchfab/kiri-86.glb", "len": 4.3, "paint": "kiri86_Bodymat"},
	{"id": "classic_muscle", "name": "Muscle car classica", "kind": "hd", "path": "res://assets/cars_sketchfab/classic-muscle-car.glb", "len": 4.9},
	{"id": "doutrive_78", "name": "Doutrive '78 pickup", "kind": "hd", "path": "res://assets/cars_sketchfab/doutrive-78-pickup.glb", "len": 5.2, "paint": "DOUTRIVE78_bodymat"},
	{"id": "eugene_mk6", "name": "Eugene MK6 '65", "kind": "hd", "path": "res://assets/cars_sketchfab/eugene-mk6-65-suv.glb", "len": 4.4},
	{"id": "furgone_francese", "name": "Furgone francese", "kind": "hd", "path": "res://assets/cars_sketchfab/furgone-francese.glb", "len": 4.6},
	{"id": "sports", "name": "Sportiva", "kind": "rgsdev"},
	{"id": "muscle", "name": "Muscle car", "kind": "rgsdev"},
	{"id": "muscle_2", "name": "Muscle car 2", "kind": "rgsdev"},
	{"id": "roadster", "name": "Roadster", "kind": "rgsdev"},
	{"id": "sedan", "name": "Berlina", "kind": "rgsdev"},
	{"id": "hatchback", "name": "Hatchback", "kind": "rgsdev"},
	{"id": "suv", "name": "SUV", "kind": "rgsdev"},
	{"id": "pickup", "name": "Pickup", "kind": "rgsdev"},
	{"id": "van", "name": "Furgone", "kind": "rgsdev"},
	{"id": "taxi", "name": "Taxi", "kind": "rgsdev"},
	{"id": "limousine", "name": "Limousine", "kind": "rgsdev"},
	{"id": "monster_truck", "name": "Monster truck", "kind": "rgsdev"},
	{"id": "ambulance", "name": "Ambulanza", "kind": "rgsdev"},
	{"id": "firetruck", "name": "Pompieri", "kind": "rgsdev"},
	{"id": "bus", "name": "Autobus", "kind": "rgsdev"},
	{"id": "truck", "name": "Camion", "kind": "rgsdev"},
	{"id": "truck_with_trailer", "name": "Camion con rimorchio", "kind": "rgsdev"},
	{"id": "police_sedan", "name": "Polizia berlina", "kind": "rgsdev"},
	{"id": "police_sports", "name": "Polizia sportiva", "kind": "rgsdev"},
	{"id": "police_muscle", "name": "Polizia muscle", "kind": "rgsdev"},
	{"id": "police_suv", "name": "Polizia SUV", "kind": "rgsdev"},
	{"id": "k_race", "name": "Kenney: da corsa", "kind": "kenney", "file": "race", "len": 4.4},
	{"id": "k_race_future", "name": "Kenney: futuristica", "kind": "kenney", "file": "race-future", "len": 4.4},
	{"id": "k_sedan_sports", "name": "Kenney: berlina sportiva", "kind": "kenney", "file": "sedan-sports", "len": 4.4},
	{"id": "k_hatchback_sports", "name": "Kenney: hatchback sportiva", "kind": "kenney", "file": "hatchback-sports", "len": 4.1},
	{"id": "k_sedan", "name": "Kenney: berlina", "kind": "kenney", "file": "sedan", "len": 4.4},
	{"id": "k_suv", "name": "Kenney: SUV", "kind": "kenney", "file": "suv", "len": 4.6},
	{"id": "k_suv_luxury", "name": "Kenney: SUV di lusso", "kind": "kenney", "file": "suv-luxury", "len": 4.8},
	{"id": "k_taxi", "name": "Kenney: taxi", "kind": "kenney", "file": "taxi", "len": 4.4},
	{"id": "k_police", "name": "Kenney: polizia", "kind": "kenney", "file": "police", "len": 4.4},
	{"id": "k_van", "name": "Kenney: furgone", "kind": "kenney", "file": "van", "len": 4.8},
	{"id": "k_delivery", "name": "Kenney: consegne", "kind": "kenney", "file": "delivery", "len": 5.2},
	{"id": "k_delivery_flat", "name": "Kenney: consegne pianale", "kind": "kenney", "file": "delivery-flat", "len": 5.2},
	{"id": "k_truck", "name": "Kenney: camion", "kind": "kenney", "file": "truck", "len": 6.0},
	{"id": "k_truck_flat", "name": "Kenney: camion pianale", "kind": "kenney", "file": "truck-flat", "len": 6.0},
	{"id": "k_garbage_truck", "name": "Kenney: nettezza urbana", "kind": "kenney", "file": "garbage-truck", "len": 7.0},
	{"id": "k_firetruck", "name": "Kenney: pompieri", "kind": "kenney", "file": "firetruck", "len": 7.0},
	{"id": "k_ambulance", "name": "Kenney: ambulanza", "kind": "kenney", "file": "ambulance", "len": 5.5},
	{"id": "k_tractor", "name": "Kenney: trattore", "kind": "kenney", "file": "tractor", "len": 4.0},
	{"id": "k_tractor_police", "name": "Kenney: trattore polizia", "kind": "kenney", "file": "tractor-police", "len": 4.0},
	{"id": "k_tractor_shovel", "name": "Kenney: ruspa", "kind": "kenney", "file": "tractor-shovel", "len": 5.0},
	{"id": "k_kart_oobi", "name": "Kenney: kart Oobi", "kind": "kenney", "file": "kart-oobi", "len": 2.6},
	{"id": "k_kart_oodi", "name": "Kenney: kart Oodi", "kind": "kenney", "file": "kart-oodi", "len": 2.6},
	{"id": "k_kart_ooli", "name": "Kenney: kart Ooli", "kind": "kenney", "file": "kart-ooli", "len": 2.6},
	{"id": "k_kart_oopi", "name": "Kenney: kart Oopi", "kind": "kenney", "file": "kart-oopi", "len": 2.6},
	{"id": "k_kart_oozi", "name": "Kenney: kart Oozi", "kind": "kenney", "file": "kart-oozi", "len": 2.6},
	{"id": "car_sedan", "name": "KayKit: berlina", "kind": "kaykit"},
	{"id": "car_hatchback", "name": "KayKit: hatchback", "kind": "kaykit"},
	{"id": "car_stationwagon", "name": "KayKit: station wagon", "kind": "kaykit"},
	{"id": "car_taxi", "name": "KayKit: taxi", "kind": "kaykit"},
	{"id": "car_police", "name": "KayKit: polizia", "kind": "kaykit"},
]


## Driven wheels for each car: "RWD" (rear), "FWD" (front) or "AWD" (all four).
const RWD := ["mclaren_600lt", "silvia_s15", "mr2_w20", "bmw_m3_e36", "mustang_gt", "kiri_86", "classic_muscle",
	"doutrive_78", "sports", "muscle", "muscle_2", "roadster", "police_sports", "police_muscle",
	"limousine", "truck", "truck_with_trailer", "bus", "firetruck", "k_race", "k_race_future", "k_sedan_sports",
	"k_truck", "k_truck_flat", "k_garbage_truck", "k_firetruck", "k_tractor", "k_tractor_police",
	"k_tractor_shovel", "k_kart_oobi", "k_kart_oodi", "k_kart_ooli", "k_kart_oopi", "k_kart_oozi"]
const AWD := ["skyline_r34", "ford_raptor_r", "ram_1500_trx", "suv", "pickup", "monster_truck", "police_suv", "k_suv",
	"k_suv_luxury"]


## Top speed in km/h without nitro. Cars not listed get DEFAULT_TOP_SPEED.
const DEFAULT_TOP_SPEED := 215.0
const TOP_SPEED := {
	"mclaren_600lt": 255.0, "skyline_r34": 240.0, "mustang_gt": 235.0, "bmw_m3_e36": 230.0,
	"silvia_s15": 225.0, "classic_muscle": 225.0, "kiri_86": 220.0, "mr2_w20": 220.0,
	"sports": 240.0, "k_race": 245.0, "k_race_future": 250.0, "roadster": 225.0, "muscle": 225.0,
	"muscle_2": 225.0, "k_sedan_sports": 225.0, "k_hatchback_sports": 215.0, "police_sports": 235.0,
	"ford_raptor_r": 210.0, "ram_1500_trx": 210.0, "doutrive_78": 210.0, "eugene_mk6": 210.0,
	"furgone_francese": 210.0, "monster_truck": 210.0, "charger_1970": 230.0, "skyline_r34_brian": 240.0,
	"porsche_911_gt3": 250.0, "mustang_1969": 225.0,
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


## The 20 cars in the garage, in the order the garage shows them (Stefano's pick, 2026-10-30).
## The other CARS stay in the catalog for rivals, police and traffic.
const GARAGE := [
	"mclaren_600lt", "charger_1970", "skyline_r34_brian", "porsche_911_gt3", "mustang_1969",
	"skyline_r34", "silvia_s15", "mr2_w20", "bmw_m3_e36", "mustang_gt", "kiri_86", "classic_muscle",
	"ford_raptor_r", "ram_1500_trx", "doutrive_78", "eugene_mk6",
	"sports", "muscle", "k_race", "k_race_future",
]


## Garage cars whose model files are in this build.
static func available() -> Array:
	var out := []
	for id in GARAGE:
		var c := find(id)
		if not c.is_empty() and ResourceLoader.exists(model_path(c)):
			out.append(c)
	return out


static func model_path(c: Dictionary) -> String:
	match c["kind"]:
		"hd":
			return c["path"]
		"kenney":
			return "res://assets/cars_kenney/%s.glb" % c["file"]
		"rgsdev":
			return CarModel.RGSDEV_DIR + c["id"] + ".fbx"
		_:
			return CarModel.KAYKIT_DIR + c["id"] + ".gltf"
