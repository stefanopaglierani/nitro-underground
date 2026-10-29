class_name CarCatalog
extends RefCounted
## Every car the player can pick in the garage. Licences and authors: assets/LICENSES.md.
## "kind" says which builder in CarModel makes it: hd and kenney (generic glTF, scaled to "len"
## metres), rgsdev (FBX with named materials), kaykit (city kit, repainted by a shader).

const CARS := [
	{"id": "mclaren_600lt", "name": "McLaren 600LT", "kind": "hd", "path": "res://assets/cars_sketchfab/mclaren_600lt/scene.gltf", "len": 4.6, "paint": "mM_CarPaint_Max1", "tail": "mM_LightGlass_Red_Low1"},
	{"id": "ford_raptor_r", "name": "Ford F-150 Raptor R", "kind": "hd", "path": "res://assets/cars_sketchfab/2024_ford_f-150_raptor_r/scene.gltf", "len": 5.9, "paint": "RaptorPaaint", "tail": ""},
	{"id": "ram_1500_trx", "name": "RAM 1500 TRX", "kind": "hd", "path": "res://assets/cars_sketchfab/2021_ram_1500_trx/scene.gltf", "len": 5.9, "paint": "RAM_1500TRX_2021Paint_Material", "tail": "RED_GLASS"},
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


static func find(id: String) -> Dictionary:
	for c in CARS:
		if c["id"] == id:
			return c
	return {}


## Cars whose model files are in this build.
static func available() -> Array:
	var out := []
	for c in CARS:
		if ResourceLoader.exists(model_path(c)):
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
