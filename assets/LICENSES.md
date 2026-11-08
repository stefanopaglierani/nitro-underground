# Registro licenze degli asset

Ogni file in `assets/` deve comparire qui, con fonte, autore, licenza alla data del download e modifiche fatte.

Tutti gli asset attuali vengono da [Poly Haven](https://polyhaven.com) e sono **CC0 1.0** (pubblico dominio): uso commerciale libero, modifiche libere, attribuzione non obbligatoria (la diamo comunque per correttezza). Licenza verificata su https://polyhaven.com/license il 2026-10-28.

## HDRI (tolti dal repository l'08/11/2026)

I cieli HDRI di Poly Haven (CC0: Modern Evening Street, Cobblestone Street Night, Modern Buildings Night, Dresden Station Night, Kloofendal 48d Partly Cloudy Pure Sky) non erano più usati dal gioco, che disegna il cielo con gli shader `comic_sky` e `night_sky`, ed erano già esclusi dall'APK. Sono stati tolti per alleggerire il repository; restano scaricabili da Poly Haven se serviranno.

## Texture PBR — `assets/materials/`

Ogni cartella contiene colore (`diff`), normal OpenGL (`nor_gl`) e ARM (occlusione, rugosità, metallo). I file `.tres` sono materiali Godot creati da noi che usano queste texture.

| Cartella | Asset | Autore | Link | Licenza | Download | Usata da |
|---|---|---|---|---|---|---|
| `asphalt_02/` | Asphalt 02 | Rob Tuytel | https://polyhaven.com/a/asphalt_02 | CC0 1.0 | 2026-10-28 | road_asphalt.tres, road_asphalt_wet.tres |
| `clean_asphalt/` | Clean Asphalt | Dimitrios Savva | https://polyhaven.com/a/clean_asphalt | CC0 1.0 | 2026-10-28 | road_asphalt_clean.tres |
| `asphalt_pit_lane/` | Asphalt Pit Lane | Dimitrios Savva | https://polyhaven.com/a/asphalt_pit_lane | CC0 1.0 | 2026-10-28 | pit_lane.tres |
| `brushed_concrete/` | Brushed Concrete | Dario Barresi, Dimitrios Savva | https://polyhaven.com/a/brushed_concrete | CC0 1.0 | 2026-10-28 | sidewalk_concrete.tres |
| `checkered_pavement_tiles/` | Checkered Pavement Tiles | Amal Kumar | https://polyhaven.com/a/checkered_pavement_tiles | CC0 1.0 | 2026-10-28 | sidewalk_tiles.tres |
| `brick_wall_10/` | Brick Wall 10 | Dimitrios Savva | https://polyhaven.com/a/brick_wall_10 | CC0 1.0 | 2026-10-28 | wall_brick.tres |
| `box_profile_metal_sheet/` | Box Profile Metal Sheet | Amal Kumar | https://polyhaven.com/a/box_profile_metal_sheet | CC0 1.0 | 2026-10-28 | wall_metal_sheet.tres |

Modifiche: nessuna ai file immagine (risoluzione 1K). `road_asphalt_wet.tres` scurisce il colore e abbassa la rugosità per simulare l'asfalto bagnato.

## Modelli 3D (oggetti di strada) — `assets/props/`

Formato glTF 2.0 (`.gltf` + `.bin` + texture 1K), importato direttamente da Godot.

| Cartella | Asset | Autore | Triangoli | Link | Licenza | Download | Modifiche |
|---|---|---|---|---|---|---|---|
| `street_lamp_02/` | Street Lamp 02 | Josh Dean | 20.338 | https://polyhaven.com/a/street_lamp_02 | CC0 1.0 | 2026-10-28 | Nessuna |
| `security_light/` | Security Light | Maximilian Schuster | 4.668 | https://polyhaven.com/a/security_light | CC0 1.0 | 2026-10-28 | Nessuna |
| `utility_box_01/` | Utility Box 01 | James Ray Cock | 4.404 | https://polyhaven.com/a/utility_box_01 | CC0 1.0 | 2026-10-28 | Nessuna |
| `utility_box_02/` | Utility Box 02 | James Ray Cock | 6.268 | https://polyhaven.com/a/utility_box_02 | CC0 1.0 | 2026-10-28 | Nessuna |
| `barrel_03/` | Barrel 03 | Serhii Khromov | 1.473 | https://polyhaven.com/a/barrel_03 | CC0 1.0 | 2026-10-28 | Nessuna |
| `concrete_road_barrier_02/` | Concrete Road Barrier 02 | Amal Kumar | 42.578 | https://polyhaven.com/a/concrete_road_barrier_02 | CC0 1.0 | 2026-10-28 | Nessuna |
| `covered_car/` | Covered Car | MP | 12.592 | https://polyhaven.com/a/covered_car | CC0 1.0 | 2026-10-28 | Nessuna |
| `wooden_crate_02/` | Wooden Crate 02 | James Ray Cock. Jurita Burger | 5.176 | https://polyhaven.com/a/wooden_crate_02 | CC0 1.0 | 2026-10-28 | Nessuna |
| `plastic_crate_02/` | Plastic Crate 02 | Fabi_G | 5.840 | https://polyhaven.com/a/plastic_crate_02 | CC0 1.0 | 2026-10-28 | Nessuna |

Nota: `street_lamp_02` (20 mila triangoli) e `concrete_road_barrier_02` (42 mila) sono pesanti per un telefono se ripetuti molte volte; prima dell'uso in massa andranno semplificati (LOD o riduzione poligoni) e la modifica andrà annotata qui.

## KayKit City Builder Bits 1.0 (tolto nella v0.14)

Il pack KayKit (CC0, Kay Lousberg) dava solo le auto low poly di riserva: è stato tolto dal repository il 05/11/2026 con le altre auto low poly.

## Percorso di montagna (Poly Haven)

| File e uso | Tipo | Asset | Autore | Link | Licenza | Download | Modifiche |
|---|---|---|---|---|---|---|---|
| `assets/materials/aerial_grass_rock/`, erba del terreno (colorata più verde nello shader) | Texture 1K | Aerial Grass Rock | Rob Tuytel | https://polyhaven.com/a/aerial_grass_rock | CC0 1.0 | 2026-10-29 | Nessuna |
| `assets/materials/aerial_beach_01/`, sabbia della spiaggia (circuito Costa) | Texture 1K | Aerial Beach 01 | Rob Tuytel | https://polyhaven.com/a/aerial_beach_01 | CC0 1.0 | 2026-10-30 | Nessuna |
| `assets/materials/rocky_terrain_02/`, terreno vicino alla strada | Texture 1K | Rocky Terrain 02 | Amal Kumar | https://polyhaven.com/a/rocky_terrain_02 | CC0 1.0 | 2026-10-29 | Nessuna |
| `assets/materials/rock_face/`, pareti di roccia | Texture 1K | Rock Face | Greg Zaal, Dario Barresi | https://polyhaven.com/a/rock_face | CC0 1.0 | 2026-10-29 | Nessuna |
| `assets/props/rock_09/`, massi a bordo strada | Modello glTF | Rock 09 | Jenelle van Heerden | https://polyhaven.com/a/rock_09 | CC0 1.0 | 2026-10-29 | Nessuna |
| `assets/props/moon_rock_02/`, massi a bordo strada | Modello glTF | Moon Rock 02 | Rico Cilliers, Greg Zaal, Jenelle van Heerden | https://polyhaven.com/a/moon_rock_02 | CC0 1.0 | 2026-10-29 | Nessuna |
| `assets/props/rock_face_01/`, roccia a bordo strada | Modello glTF | Rock Face 01 | Dario Barresi | https://polyhaven.com/a/rock_face_01 | CC0 1.0 | 2026-10-29 | Nessuna |

I pini, i guardrail e la strada della montagna sono generati dal codice (`scripts/mountain.gd`), non sono asset esterni. `clean_asphalt` (già registrato sopra) è usato anche per le banchine.

## Libreria di modelli da OpenGameArt (tolta dal repository l'08/11/2026)

Scaricati il 2026-10-29 da https://opengameart.org (dominio aperto da Stefano). Tutti i pacchetti sono marcati **CC0** sulla loro pagina OpenGameArt (verificato pagina per pagina al download). Fino all'08/11/2026 stavano in `assets/library/` (104 MB, con `.gdignore`, mai nell'APK). Su decisione di Stefano la cartella è stata tolta dal repository, come già si fa con la libreria dei modelli nuovi, che vive fuori dal repository: i due modelli già presi (tabella qui sotto) restano nel gioco. Gli elenchi qui sotto restano come registro della provenienza; i pacchetti si possono riscaricare dalle pagine indicate.

Modifiche comuni a tutti i pacchetti: tenuti solo i formati che Godot legge (glTF/GLB, FBX, OBJ). Tolti i file `.blend`, i collegamenti `.url`/`.html` e i doppioni in altri formati. Le immagini di anteprima sono state ridotte a 960 px in JPG. Le texture `.tga` sono state convertite in PNG (le diffuse e le speculari delle barriere Yughues in JPG), e i `.mtl` sono stati aggiornati di conseguenza.

| Cartella | Contenuto | Autore | Pagina | Licenza |
|---|---|---|---|---|
| `kenney_racing_kit/` | 71 pezzi di pista glTF (rettilinei, curve, barriere, gomme, bandiere, tribune, auto da corsa) | Kenney | https://opengameart.org/content/racing-kit | CC0 (`License.txt`) |
| `kenney_city_kit_roads/` | 95 pezzi GLB di strade, incroci, ponti, segnaletica, lampioni | Kenney | https://opengameart.org/content/city-kit-roads | CC0 (`License.txt`) |
| `kenney_nature_kit/` | 329 modelli glTF di natura (alberi, pini, rocce, cespugli, erba, sentieri, staccionate) | Kenney | https://opengameart.org/content/nature-kit | CC0 (`License.txt`) |
| `quaternius_textured_trees/` | 45 alberi FBX con texture (pini, betulle, aceri, alberi secchi) | Quaternius | https://opengameart.org/content/lowpoly-textured-trees | CC0 (versione pubblicata su OpenGameArt nel 2020, prima del cambio di licenza di Quaternius) |
| `emaceart_meadows/` | 276 GLB di prato: erba, fiori, cespugli, sassi, alberi | EmacEArt | https://opengameart.org/content/free-remastered-free-mid-poly-meadows | CC0 |
| `yughues_grass/` | Ciuffi d'erba realistici con texture alfa, una sottocartella per pacchetto | Yughues (Nobiax) | https://opengameart.org/content/grass-pack-01 , -02 , -03 | CC0 (`readme.txt`; l'autore chiede, senza obbligo, un link al risultato) |
| `yughues_concrete_barriers/` | 5 barriere di cemento realistiche FBX/OBJ con texture | Yughues (Nobiax) | https://opengameart.org/content/concrete-barriers | CC0 (`readme.txt`) |
| `calinou_concrete_barrier/` | Barriera di cemento OBJ con texture | Calinou | https://opengameart.org/content/concrete-barrier | CC0 |
| `lucianpavel_concrete_barrier/` | Barriera di cemento FBX (senza texture) | Lucian Pavel | https://opengameart.org/content/concrete-barrier-pbrunity-unreal | CC0 |
| `calinou_traffic_cone/` | Cono stradale OBJ con texture | Calinou | https://opengameart.org/content/traffic-cone-0 | CC0 |
| `milkandbanana_traffic_road/` | 132 GLB: coni, transenne, blocchi stradali, tombini, lampioni, idranti | MilkAndBanana | https://opengameart.org/content/traffic-road-assets | CC0 (`License.txt`) |
| `hernandack_steel_fence/` | Recinzione modulare acciaio e cemento OBJ | hernandack | https://opengameart.org/content/low-poly-steel-fence-with-concrete-modular | CC0 |
| `eracoon_landscape_v1/`, `eracoon_landscape_v2/` | 86 OBJ di paesaggio (rocce, alberi, erba, cespugli) | eracoon | https://opengameart.org/content/landscape-asset-v1 , https://opengameart.org/content/landscape-asset-v2 | CC0 (`license.txt`) |
| `elnineo_racing_circuit/` | Circuito completo FBX con texture | elnineo | https://opengameart.org/content/racing-circuit | CC0 |
| `fsp_modular_racetrack/` | 20 pezzi di pista OBJ | Keith at Fertile Soil Productions | https://opengameart.org/content/modular-racetrack-3d-models | CC0 |

Il 05/11/2026 (v0.14) sono state tolte dalla libreria tutte le auto low poly (Kenney Car Kit, rgsdev, Alexander123, mabaci, GGBotNet, byzmod3d, Lyricsz, tutte CC0): il gioco usa solo auto dettagliate.

Note: sono quasi tutti modelli low poly o "mid poly", non realistici. Non scaricati perché troppo pesanti per un telefono: le rocce fotogrammetriche di Yughues (120–165 MB l'una) e il Mossy Rock Environment Pack (237 MB); sono comunque CC0 e si possono prendere se servono. Non scaricato perché esiste solo in formato `.blend` (qui non c'è Blender per convertirlo): Spruce Deforestation Models (abeti, CC0).

### Modelli della libreria usati nel gioco (v0.4)

| File e uso | Preso da | Modifiche |
|---|---|---|
| `assets/props/trees/*.fbx` e texture, pini e betulle della montagna | `library/quaternius_textured_trees/` (Quaternius, CC0 su OpenGameArt) | Solo Pine_1, 2, 3, 5 e Birch_1, 3. In gioco: ingranditi da 1,7 a 2,7 volte e foglie scurite |
| `assets/props/grass/grass_01.png`, `grass_02.png`, `grass_04.png`, ciuffi d'erba a bordo strada | `library/yughues_grass/` (Yughues, CC0) | Solo la texture diffusa con alfa, rinominata. In gioco: due quadrati incrociati, colore più verde |

## Auto tolte dal repository (06/11/2026)

Su richiesta di Stefano, con la v0.15 sono stati cancellati dal repository i file di tutte le auto che non si potrebbero vendere o che il gioco non usa più: la cartella `assets/cars_sketchfab/` intera (McLaren 600LT, Porsche 911 GT3, Skyline R34 "Brian", Ford F-150 Raptor R, RAM 1500 TRX, Charger 1970, Corvette Z06, BMW M3 GTR, Supra A80, Mercedes W203, Ford Mondeo Police, Mustang GT 2013 e le auto Sketchfab della v0.6) e, dal traffico, Corvette 1969, Camaro 2012, Camaro ZL1, GMC Sierra e Mercedes 190E. Restano nella cronologia git e nella cartella del PC di Stefano. Le auto low poly rgsdev, Kenney e KayKit (CC0) erano già state tolte il 05/11/2026.

## Audio delle auto — `assets/audio/`

Usati da `scripts/car_audio.gd`. Stesso set di suoni per tutte le auto.

### Suoni generati da noi (CC0)

Creati da zero con `tools/audio/make_engine_sounds.py` (nessun campione esterno), quindi rilasciati CC0 come il resto del codice audio.

| File | Cos'è |
|---|---|
| `engine_on_*.wav`, `engine_off_*.wav` | Motore V8 a 1000, 2000, 3200, 4500, 6000 e 7600 giri, con gas aperto (on) e chiuso (off). Loop senza stacco. |
| `wind.wav` | Vento e rotolamento, sale con la velocità |
| `nitro_loop.wav` | Soffio del nitro |
| `blowoff.wav` | "Pssh" della valvola del turbo quando si molla il gas o si cambia marcia |
| `pop_0..2.wav` | Scoppiettii dello scarico in rilascio |
| `starter.wav` | Motorino di avviamento |
| `siren.wav` | Sirena della polizia |

### Registrazioni scaricate

Tutte **CC0 1.0**, licenza verificata sulla pagina di ogni suono il 2026-10-30. Da Freesound abbiamo usato l'anteprima MP3 di alta qualità (stesso suono, stessa licenza). Tagli fatti con `tools/audio/slice_recordings.py`: ritaglio, mono 32 kHz, normalizzazione, dissolvenze.

| File | Suono originale | Autore | Link | Licenza | Modifiche |
|---|---|---|---|---|---|
| `crash_heavy.wav` | Car Crash | squareal | https://freesound.org/people/squareal/sounds/237375/ | CC0 1.0 | Tagliato 0,37–3,6 s |
| `crash_medium.wav` | Hood Impact | LPA134 | https://freesound.org/people/LPA134/sounds/329516/ | CC0 1.0 | Tagliato 0,13–2,0 s |
| `land_thud.wav` | Hood Impact | LPA134 | https://freesound.org/people/LPA134/sounds/329516/ | CC0 1.0 | 0,13–0,9 s, filtrato sotto 700 Hz (tonfo dell'atterraggio) |
| `crash_metal.wav` | Metal Hit 2 | dslrguide | https://freesound.org/people/dslrguide/sounds/321482/ | CC0 1.0 | Tagliato 0,13–1,3 s |
| `crash_light.wav` | Fast Collision | qubodup | https://freesound.org/people/qubodup/sounds/332056/ | CC0 1.0 | Normalizzato |
| `gear_1.wav`, `gear_2.wav` | Elantra Gear Shift | mrmccormack | https://freesound.org/people/mrmccormack/sounds/116598/ | CC0 1.0 | Due cambiate ritagliate |
| `tyre_squeal.wav` | Chrysler LHS tire squeal 03 | audible-edge | https://freesound.org/people/audible-edge/sounds/71738/ | CC0 1.0 | 8,3–9,35 s, reso un loop |
| `handbrake.wav` | Car Parking Brake (Car Sound Effects Pack) | ggbotnet | https://opengameart.org/content/car-sound-effects-pack-low-quality | CC0 1.0 | Normalizzato |

### Traffico dalla v0.14 (05/11/2026) — `assets/cars_traffic/`

Scaricati a mano da Stefano su Sketchfab (cartella "Auto-scaricate" del suo PC), tutti **CC BY 4.0**. File non modificati; in gioco sono preparati da `tools/bake_cars.gd` in `assets/cars_baked/` e le texture sono compresse a 512 px. Sono marchi reali con nomi inventati in gioco (Cruiser '67, Ranger 90, Kraft Berlina '98, Trail 4x4).

| File | Uso | Modello | Autore | Licenza | Pagina |
|---|---|---|---|---|---|
| `cars_traffic/impala_1967.glb` | traffico | Chevrolet Impala 1967 | Eques_inferno | CC BY 4.0 | https://sketchfab.com/3d-models/chevrolet-impala-1967-bce35ef0c10d41fdb3f7d8c4225144d2 |
| `cars_traffic/defender_90.glb` | traffico | Land Rover Defender 90 Lowpoly | kekis69 | CC BY 4.0 | https://sketchfab.com/3d-models/land-rover-defender-90-lowpoly-88e5f30687ec4d508cebafa876e014d6 |
| `cars_traffic/bmw_e46.glb` | traffico | Low Poly Car - BMW E46 1998 | ROH3D | CC BY 4.0 | https://sketchfab.com/3d-models/low-poly-car-bmw-e46-1998-d9bfd8126e754164b48ded833c017bbf |
| `cars_traffic/jeep/` | traffico | jeep | mortalityrexotable | CC BY 4.0 | https://sketchfab.com/3d-models/jeep-81bfdc1da40647048b2f1da045f8d090 |

La "Police car" di Mateusz Woliński (jeandiz, CC BY 4.0, https://sketchfab.com/3d-models/police-car-9166b13b6ae341f4bfc093edb71d74f4) è in `assets/cars_cc/police_car.glb` dal 04/11/2026.

### Auto vendibili della v0.15 (06/11/2026) — `assets/cars_cc/`

Su richiesta di Stefano il gioco usa solo auto che si potrebbero vendere: tutte **CC BY 4.0**, scaricate da Sketchfab il 06/11/2026 (elenco in `/mnt/project-files/nitro-underground/assets-auto/vendibili/CREDITI.md` e nella cartella "Auto-scaricate" del suo PC). Uso commerciale ammesso citando l'autore.
Le auto di marchi reali hanno in gioco un **nome inventato** e, dove il logo è un pezzo separato del modello, il logo è nascosto dal catalogo (`"hide"` in `scripts/car_catalog.gd`). I loghi dipinti dentro le texture e la forma riconoscibile delle carrozzerie restano: prima di una vendita vanno controllati.
In gioco ogni auto è preparata da `tools/bake_cars.gd` in `assets/cars_baked/` (girata, scalata, saldata, alleggerita). Texture compresse, 1024 px (512 per il traffico).
Scaricate ma non usate: Muscle Car Concept (ViktorKom; il modello ha porte e cofano aperti) e Mazda RX-7 FD (Lexyc16; il modello ha una posa sbagliata nel file): non sono nel repository.

| File | Nome in gioco | Modello originale | Autore | Pagina | Marchio e modifiche |
|---|---|---|---|---|---|
| `phoenix_455_71.glb` | Phoenix 455 | Phoenix 455 '71 - Low poly model | DanielZhabotinsky | https://sketchfab.com/3d-models/phoenix-455-71-low-poly-model-955edc733c6d44fabc0ad7c246a15896 | inventata |
| `tiara_gt_83_tuned.glb` | Tiara GT '83 Tuned | Tiara GT '83 Tuned - Low poly model | DanielZhabotinsky | https://sketchfab.com/3d-models/tiara-gt-83-tuned-low-poly-model-59a0eaaa2af144b2956957e7032d0221 | inventata |
| `saba_v12_95.glb` | Saba V12 '95 | Saba V12 '95 - Low poly model | DanielZhabotinsky | https://sketchfab.com/3d-models/saba-v12-95-low-poly-model-3ab977050c334c13b6abb5de078b4957 | inventata |
| `goblin_v12.glb` | Goblin V12 | Fictional supercar - V12 Goblin | ollitei | https://sketchfab.com/3d-models/fictional-supercar-v12-goblin-0a20e49ad5774d778567cb5c3f345786 | inventata |
| `skyline_r34_gtr.glb` | Kaze R-34 | Nissan Skyline R34 GT-R | Lexyc16 | https://sketchfab.com/3d-models/nissan-skyline-r34-gt-r-ff8fb2251dfa4bb9979e7022c5a6666c | Nissan |
| `nsx_1990.glb` | Nova SX '90 | Honda NSX 1990 | Lexyc16 | https://sketchfab.com/3d-models/honda-nsx-1990-1cc15628a00a4739a6b6c01128927c8d | Honda; targhe nascoste |
| `silvia_s13.glb` | Shiro 13 | 1992 Nissan Silvia S13 | lstance | https://sketchfab.com/3d-models/1992-nissan-silvia-s13-6fa8f1948f954e3b980b5e96f203815a | Nissan; scritta e stemma posteriori nascosti |
| `silvia_s14.glb` | Shiro 14 | Nissan 200SX Silvia S14 | Lexyc16 | https://sketchfab.com/3d-models/nissan-200sx-silvia-s14-f2a917a924734a89a020e7f970e55e7c | Nissan |
| `miata_na.glb` | Petalo Roadster | Mazda Miata MX-5 NA | Lexyc16 | https://sketchfab.com/3d-models/mazda-miata-mx-5-na-d51fcd44b74f4daf8012c41e0400c041 | Mazda; nascosto il pannello di sfondo che la sollevava (v0.16) |
| `nissan_z_proto.glb` | Zenith Proto | Nissan Z Proto | Lexyc16 | https://sketchfab.com/3d-models/nissan-z-proto-db9a5f7ae9d84a0fb01cac96afe3e69c | Nissan; stemmi ancora dipinti nella texture |
| `porsche_930.glb` | Falco Turbo '75 | Porsche 911 (930) Turbo 1975 | Lexyc16 | https://sketchfab.com/3d-models/porsche-911-930-turbo-1975-de1ffd344c41481892511f7fd332c136 | Porsche |
| `bmw_m3_e30.glb` | Kraft Sport '87 | [FREE] BMW M3 E30 | TinoD2 | https://sketchfab.com/3d-models/free-bmw-m3-e30-ac3c7013434e403e8faff87948caf422 | BMW; stemmi e loghi dei freni nascosti |
| `datsun_280z.glb` | Sakura GT '78 | [FREE] Datsun 280Z | TinoD2 | https://sketchfab.com/3d-models/free-datsun-280z-0789ab2ece9442de94b3c41595e0ecbd | Datsun |
| `delta_integrale.glb` | Sterrato Evo | FREE Lancia Delta HF Integrale evo 2 | begemot.988888 | https://sketchfab.com/3d-models/free-lancia-delta-hf-integrale-evo-2-85614131e0dc4613a948472aaa935fc7 | Lancia; stemma nascosto, adesivi di sponsor ancora nella texture |
| `illinois_90_police.glb` | Polizia Illinois '90 | Illinois '90 Police cruiser - Low poly model | DanielZhabotinsky | https://sketchfab.com/3d-models/illinois-90-police-cruiser-low-poly-model-dc81625478a744649b210c7f248b0b6a | inventata |
| `negotiator_80_police.glb` | Polizia Negotiator '80 | Negotiator '80 Cop Cruiser - Low poly model | DanielZhabotinsky | https://sketchfab.com/3d-models/negotiator-80-cop-cruiser-low-poly-model-945fd09f513f4d1ab19b6388a7ea7323 | inventata |
| `crown_victoria_police.glb` | Polizia Interceptor '01 | 2001 Crown Victoria Police Interceptor Game Prop | haoliu95 | https://sketchfab.com/3d-models/2001-crown-victoria-police-interceptor-game-prop-9f30d360cee343efb5a441978ddb57bd | Ford |
| `carter_98.glb` | Carter '98 (traffico) | Carter '98 - Low Poly Model | DanielZhabotinsky | https://sketchfab.com/3d-models/carter-98-low-poly-model-3af773617c7f481da2ba5d307412ce35 | inventata |
| `conquer_89_pickup.glb` | Conquer '89 Pickup (traffico) | Conquer '89 Pickup - Low poly model | DanielZhabotinsky | https://sketchfab.com/3d-models/conquer-89-pickup-low-poly-model-6c48c94be8974dc7a5932f697c0ba68f | inventata |
| `cutlass_71.glb` | Monarch '71 (traffico) | Oldsmobile Cutlass Supreme Sedan '71 | barbo-autos | https://sketchfab.com/3d-models/oldsmobile-cutlass-supreme-sedan-71-78f76d386a4341b0b71745bdc50fd5ab | Oldsmobile; stemmi nascosti |
| `ace_11.glb` | Ace '11 (traffico) | Ace '11 - Low Poly model | DanielZhabotinsky | https://sketchfab.com/3d-models/ace-11-low-poly-model-055ff8a21b8d4d279debca089e2fafcd | inventata |
| `sigil_07.glb` | Sigil '07 (traffico) | Sigil '07 - Low poly model | DanielZhabotinsky | https://sketchfab.com/3d-models/sigil-07-low-poly-model-22abe5284d4c4b55920b8462eb24a8c1 | inventata; stemmi nascosti |
| `shvan_92.glb` | Ambulanza Shvan '92 (traffico) | Shvan '92 Ambulance - Low Poly model | DanielZhabotinsky | https://sketchfab.com/3d-models/shvan-92-ambulance-low-poly-model-2856dd3c61f940909dced9a5c0379484 | inventata |
| `lightbody_90_tow.glb` | Carro attrezzi Lightbody '90 (traffico) | Lightbody '90 MD Tow Truck - Low poly model | DanielZhabotinsky | https://sketchfab.com/3d-models/lightbody-90-md-tow-truck-low-poly-model-5cba208001c64e8ea164f89e4dde91e7 | inventata |
| `lct_3000_07.glb` | LCT 3000 '07 (traffico) | LCT 3000 '07- Low poly model | DanielZhabotinsky | https://sketchfab.com/3d-models/lct-3000-07-low-poly-model-3be03b6a43aa41898c9ca806b8787052 | inventato |
| `town_bus.glb` | Autobus di città (traffico) | Generic Town Bus | own.guest | https://sketchfab.com/3d-models/generic-town-bus-14fe03d792914d51b6c6250b393c44fd | inventato; alleggerito da 55 a 25 mila triangoli |

## Paesaggio realistico (Sketchfab, CC-BY 4.0) — `assets/scenery/`

Modelli scaricati il 2026-10-30 in formato glTF dall'API di Sketchfab. Licenza **CC Attribution 4.0** (uso commerciale consentito, attribuzione obbligatoria: i crediti qui sotto vanno riportati anche nei titoli di coda del gioco). Modifiche comuni a tutti: texture ridotte a 1024 px; il gioco converte le foglie in alpha scissor e le tinge (scripts/scenery.gd).

| Cartella | Modello | Autore | Link | Modifiche |
|---|---|---|---|---|
| `pine/` | Pine Tree [Game-ready] | Wenedi | https://sketchfab.com/3d-models/pine-tree-game-ready-dc3fbd9205cf4027a4455d1f415e0478 | Bordi trasparenti delle foglie riempiti di verde (niente alone bianco) |
| `spruce/` | Spruce tree | Georgeous (intice184) | https://sketchfab.com/3d-models/spruce-tree-7a5db417827244d98827459bce0cc944 | Come sopra |
| `scots_pine/` | Pine Tree | evolveduk | https://sketchfab.com/3d-models/pine-tree-d45218a3fab349e5b1de040f29e7b6f9 | Come sopra |
| `pine_scan/` | Pine tree 01 | POLYSCAN (POLYSCAN3D) | https://sketchfab.com/3d-models/pine-tree-01-ba7c8f8e1cb549b3a3a30f1221386c8c | Come sopra |
| `alpine_chalet/` | Alpine Chalet house | Gerhald | https://sketchfab.com/3d-models/alpine-chalet-house-2ac40506a2d74e60be6e9df6657a6367 | Nessuna |
| `traffic_cone/` | Traffic cone (Game ready) | PT34 | https://sketchfab.com/3d-models/traffic-cone-game-ready-8cdac192abd044988c314eeb6377a3a0 | Nessuna (non ancora usato: i coni vengono dal pacchetto barriere) |
| `street_signs/` | Worn street signs | Nicolai Kilstrup (nkilstrup) | https://sketchfab.com/3d-models/worn-street-signs-e8a1cfe8e0254e4e8b9edaf96c23e259 | Nessuna |
| `barriers/` | Barrier & Traffic Cone Pack | Sabri Ayeş (sabriayes) | https://sketchfab.com/3d-models/barrier-traffic-cone-pack-23c4dfca76a24bf0b21894847867af2a | Nessuna |

## Ambientazioni v0.11 (Sketchfab, CC-BY 4.0) — `assets/scenery/*.glb`

Scaricati il 2026-10-31 in formato GLB dall'API di Sketchfab, non modificati. Licenza **CC Attribution 4.0**: crediti da riportare anche nei titoli di coda se il gioco viene pubblicato. Prefisso del file = circuito che li usa (`city_` Città di notte, `coast_` Costa, `desert_` Deserto). La città li mostra di notte con un materiale che accende le finestre (`shaders/city_facade.gdshader`).

| File | Modello | Autore | Pagina |
|---|---|---|---|
| `city_downtown_set.glb` | Downtown Buildings Set - Low Poly model | DanielZhabotinsky | https://sketchfab.com/3d-models/downtown-buildings-set-low-poly-model-7378e7fb9c914c39880d9913a6f4e1d6 |
| `city_midcity_set.glb` | Midcity Buildings Set - Low Poly model | DanielZhabotinsky | https://sketchfab.com/3d-models/midcity-buildings-set-low-poly-model-d5cbc471d20c4c9da31c3df656648916 |
| `city_nyc_homes.glb` | Low Poly classical New York City homes | 99.Miles | https://sketchfab.com/3d-models/low-poly-classical-new-york-city-homes-449d873dcca0409bb73b6b801ff36bed |
| `city_chicago_buildings.glb` | Realistic chicago buildings | 99.Miles | https://sketchfab.com/3d-models/realistic-chicago-buildings-c4a3993ef1e84e6d9d5a15c78da88aae |
| `city_singapore_skyscraper.glb` | Singapore Office Skyscraper [FREE] | 99.Miles | https://sketchfab.com/3d-models/singapore-office-skyscraper-free-2305f0fe03ba44229a1f768dcb48bd8f |
| `city_night_skyline.glb` | Low Poly Night City Building Skyline | 99.Miles | https://sketchfab.com/3d-models/low-poly-night-city-building-skyline-b0035b8713b048bb8ddf311ee67c28c8 |
| `city_street_lights.glb` | Various Low-Poly Street Lights | kmb_jr | https://sketchfab.com/3d-models/various-low-poly-street-lights-1173b0c4d9b0400bbeaafbee0e94ca59 |
| `city_street_props_traffic_light.glb` | Street and City Props Dumpster Traffic Light | spookyghostboo | https://sketchfab.com/3d-models/street-and-city-props-dumpster-traffic-light-27a6775c51e44bfda8e1ac8725eb3e9e |
| `coast_coconut_palm.glb` | Coconut Palm | evolveduk | https://sketchfab.com/3d-models/coconut-palm-26e787f2ff2e4c0fb004c3b0210805a3 |
| `coast_arabic_palm.glb` | Arabic Palmtree | rodrigogelmi | https://sketchfab.com/3d-models/arabic-palmtree-d76f0654b92d4cf994b528555525219b |
| `coast_lighthouse_2.glb` | lighthouse | Lora_o | https://sketchfab.com/3d-models/lighthouse-dab98033118949728804bfc5f4076b8f |
| `coast_old_pier.glb` | Old pier (Game ready) | PT34 | https://sketchfab.com/3d-models/old-pier-game-ready-3c21842960a74452a13609a584f38762 |
| `coast_rowboat.glb` | Old Rowboat | toomanydemons | https://sketchfab.com/3d-models/old-rowboat-9922d5678af84adeb1c9b479856446ca |
| `coast_wooden_boat.glb` | Wooden Boat | dadndan0091 | https://sketchfab.com/3d-models/wooden-boat-55118b23a5494e4b81eed831b9f8c871 |
| `coast_beach_umbrella.glb` | Beach Umbrella | stealth86 | https://sketchfab.com/3d-models/beach-umbrella-1014ad7c8a4c4aa8ba5e88fc6151aa4f |
| `desert_gas_station.glb` | Lowpoly Gas Station | AspectStudio | https://sketchfab.com/3d-models/lowpoly-gas-station-02a11319cb744999adddd7236a46bf8e |
| `desert_roadside_motel.glb` | Roadside Motel | novusod | https://sketchfab.com/3d-models/roadside-motel-f52cfdfa6711424289ecc9df463acede |
| `desert_mojave_motel_sign.glb` | Mojave Motel Sign | aocrisan | https://sketchfab.com/3d-models/mojave-motel-sign-c64f69ab7a6e4674826de6600f1a61d6 |
| `desert_western_bank.glb` | Old Western Bank With Interior Low Poly | elvair | https://sketchfab.com/3d-models/old-western-bank-with-interior-low-poly-e55eb272bc1440bf93e5dc10ccf73698 |
| `desert_western_watertower.glb` | Low Poly Western Watertower | staticcc | https://sketchfab.com/3d-models/low-poly-western-watertower-b62fd3f5aa4541b78065fe56565d88f8 |
| `desert_shanty.glb` | Shanty \| Mansion \| Wooden | yadrogames | https://sketchfab.com/3d-models/shanty-mansion-wooden-cf93dfd6da1640f08ebe051ba280426d |
| `desert_cactus_pack.glb` | Cactus \| Pack | yadrogames | https://sketchfab.com/3d-models/cactus-pack-588596f1601d48e6ad4cb24b31c3f33c |
| `desert_desert_rocks.glb` | Desert \| Rocks \| Stones \| Pack | yadrogames | https://sketchfab.com/3d-models/desert-rocks-stones-pack-c2208f5ccc004f1681d27de67fe75799 |
| `desert_desert_cliff.glb` | Desert Cliff 6 | WireframeArt | https://sketchfab.com/3d-models/desert-cliff-6-ed2e9c7e976e4768868481e4a5c63f6f |

La libreria completa scaricata (58 modelli, anche quelli non ancora usati) è nella cartella del progetto `nitro-underground/libreria-3d/`, con i crediti in `CREDITI.md`.

## Ambientazione v0.21 (Sketchfab CC BY 4.0 e Poly Haven CC0) — `assets/scenery/env/`

Scaricati l'8/11/2026 (libreria nei file di progetto: `libreria-3d/ambientazione-vendibile/`, numeri come nella pagina di proposta). Tutti con licenza commerciale; i CC BY 4.0 vanno citati anche nei titoli di coda. Modifiche comuni: texture ridotte a 256-1024 px (JPEG dove non c'è trasparenza) e importate compresse a 512 px; i modelli più pesanti sono stati alleggeriti (colonna Triangoli: originale → nel gioco). Li dispone `scripts/roadside.gd`. Per i tipi doppi ne è stato preso uno solo (scelta di Stefano dell'8/11/2026).

| File | N. | Modello | Autore | Fonte | Licenza | Triangoli | Link |
|---|---|---|---|---|---|---|---|
| `bush.glb` | 1 | Real Bush | marblesstudio | Sketchfab | CC BY 4.0 | 472 | https://sketchfab.com/3d-models/none-62618c3260b142cfb7ef499d75a8d21a |
| `rock_scan.glb` | 2 | Stránská rock 1 | 3dhdscan | Sketchfab | CC BY 4.0 | 84283 → 16157 | https://sketchfab.com/3d-models/none-4118802ad14243d59f34c2be3fa77cd4 |
| `cliff_rock.glb` | 3 | Free_cliff_rock | kwinto | Sketchfab | CC BY 4.0 | 41112 → 3083 | https://sketchfab.com/3d-models/none-75fb6b34dc0d46259dedc8c7cd94e7b7 |
| `cliffs.glb` | 4 | Cliffs | bumstrum | Sketchfab | CC BY 4.0 | 2436 | https://sketchfab.com/3d-models/none-14fe5023840146179c8515093e88fae0 |
| `grass_patches.glb` | 5 | Grass patches | bumstrum | Sketchfab | CC BY 4.0 | 1910 | https://sketchfab.com/3d-models/none-6952780b80594a31aab2dedf7249a47a |
| `trees_collection.glb` | 6 | Realistic Trees Collection | jungle_jim | Sketchfab | CC BY 4.0 | 127660 → 21596 | https://sketchfab.com/3d-models/none-fe67c886eebf4bcb988d7c45e69995ad |
| `oak_set.glb` | 7 | 3 English Oak Set (Quercus Robur) *Updated | Yag1z | Sketchfab | CC BY 4.0 | 28379 → 9361 | https://sketchfab.com/3d-models/none-750fac732a8c453e9dd748f1396275fa |
| `oak.glb` | 8 | Oak tree | evolveduk | Sketchfab | CC BY 4.0 | 8364 → 4017 | https://sketchfab.com/3d-models/none-6468dd4d3eb240ef902b9057d9913606 |
| `palm.glb` | 9 | Realistic Palm Tree 2 Free | NextSpring | Sketchfab | CC BY 4.0 | 60764 → 31187 | https://sketchfab.com/3d-models/none-d05c8ffb6ec64a7184c4b673e21f7224 |
| `conifer_pack.glb` | 10 | Coniferous Forest Assets Pack | dariiiii | Sketchfab | CC BY 4.0 | 58390 → 10985 | https://sketchfab.com/3d-models/none-240ce9cf0ad3474f809a59f9446e63cd |
| `pine_tree.glb` | 11 | Pine Tree | evolveduk | Sketchfab | CC BY 4.0 | 5627 | https://sketchfab.com/3d-models/none-d45218a3fab349e5b1de040f29e7b6f9 |
| `vegetation_pack.glb` | 12 | Low poly vegetation for games | denoises | Sketchfab | CC BY 4.0 | 9008 | https://sketchfab.com/3d-models/none-cdac82eb61ab4d83bf162b4c44b44d6d |
| `stump.glb` | 13 | Boubín Stump | 3dhdscan | Sketchfab | CC BY 4.0 | 23581 → 1532 | https://sketchfab.com/3d-models/none-b968b5dc462148989cb87b072885da85 |
| `shrub.glb` | 14 | Shrub 04 | Rico Cilliers | Poly Haven | CC0 | 47813 → 1394 | https://polyhaven.com/a/shrub_04 |
| `rock_face.glb` | 15 | Rock Face 01 | Dario Barresi | Poly Haven | CC0 | 20174 → 3026 | https://polyhaven.com/a/rock_face_01 |
| `rock_moss.glb` | 16 | Rock Moss Set 01 | Kless Gyzen | Poly Haven | CC0 | 63127 → 4098 | https://polyhaven.com/a/rock_moss_set_01 |
| `boulders.glb` | 17 | Namaqualand Boulders 01 | Greg Zaal, Jenelle van Heerden | Poly Haven | CC0 | 76590 → 1632 | https://polyhaven.com/a/namaqualand_boulders_01 |
| `dumpster.glb` | 19 | dumpster | YJ_ | Sketchfab | CC BY 4.0 | 11193 → 3512 | https://sketchfab.com/3d-models/none-989ea7f01b924859b3484ee27103e8d9 |
| `mailbox.glb` | 23 | Home US Mailbox 📫 | glowbox3d | Sketchfab | CC BY 4.0 | 2074 | https://sketchfab.com/3d-models/none-132c790ac74c42a0bb1a5fc7e3d43d7e |
| `parking_meter.glb` | 25 | Parking Meter Scan LOWPOLY | evan4129 | Sketchfab | CC BY 4.0 | 3537 | https://sketchfab.com/3d-models/none-c0f5e3e1c8a64ab3b64d4b077bd09210 |
| `phone_booth.glb` | 27 | Phone booth | YJ_ | Sketchfab | CC BY 4.0 | 8963 | https://sketchfab.com/3d-models/none-f52615a329da4908a42f5fae1d0f37d1 |
| `chain_fence.glb` | 30 | Modular Chain Link Fence Set | FrodoUndead | Sketchfab | CC BY 4.0 | 3100 | https://sketchfab.com/3d-models/none-bd85a8005ff0403cab2f1e9845016b8f |
| `trashbag.glb` | 33 | Trashbag | Benny Weimer | Poly Haven | CC0 | 4482 | https://polyhaven.com/a/trashbag |
| `picnic_table.glb` | 37 | Wooden Picnic Table | Ulan Cabanilla | Poly Haven | CC0 | 10210 → 3062 | https://polyhaven.com/a/wooden_picnic_table |
| `road_signs.glb` | 39 | Road Signs | FrodoUndead | Sketchfab | CC BY 4.0 | 14252 | https://sketchfab.com/3d-models/none-c39bf97110494b5db3de84165211f592 |
| `street_light.glb` | 41 | Street light Lamp spotlight - 10MB | ahmagh2e | Sketchfab | CC BY 4.0 | 14120 → 2823 | https://sketchfab.com/3d-models/none-b3534b9033a24f0aad2e1f9527bd4ca8 |
| `concrete_fence.glb` | 54 | Concrete fence | BlackMike | Sketchfab | CC BY 4.0 | 442 | https://sketchfab.com/3d-models/none-1ca049b5951542f094ef409f74534ae3 |
| `nyc_dwellings.glb` | 60 | Modern NYC Dwellings | 99.Miles | Sketchfab | CC BY 4.0 | 7042 | https://sketchfab.com/3d-models/none-8ef9555171c44ba1872a17558f589630 |
| `brick_shop.glb` | 65 | Brick Shop Building / Lowpoly | Fridqeir | Sketchfab | CC BY 4.0 | 1868 | https://sketchfab.com/3d-models/none-548d4a0e62b54efcab4483fb6d0c3611 |
| `brooklyn_twin.glb` | 66 | Brooklyn Street Twin Buildings Low Poly | B0rn2D13 | Sketchfab | CC BY 4.0 | 6708 → 5404 | https://sketchfab.com/3d-models/none-4038dd25616d420989b11c65a57fd35b |
| `old_buildings.glb` | 67 | Old Building Pack / Lowpoly | Fridqeir | Sketchfab | CC BY 4.0 | 16824 → 4199 | https://sketchfab.com/3d-models/none-081eccb97be8429c83b2e9fb407727e7 |
| `downtown_02.glb` | 68 | City Building Downtown 02 | jimbogies | Sketchfab | CC BY 4.0 | 35180 | https://sketchfab.com/3d-models/none-7fbeffa5e541493ba65a0ec27dd295ef |
| `transformer.glb` | 71 | Transformer Booth / LowPoly | S7NDRIK | Sketchfab | CC BY 4.0 | 952 | https://sketchfab.com/3d-models/none-9d9a74a55f384b6cb80f7453e951f6c8 |
| `utility_box.glb` | 75 | Utility Box 01 | James Ray Cock | Poly Haven | CC0 | 4404 | https://polyhaven.com/a/utility_box_01 |
| `house_mobile.glb` | 78 | LP Americans House Mobile | spaceparmesan | Sketchfab | CC BY 4.0 | 6067 | https://sketchfab.com/3d-models/none-bdd2465e5ff54fe09701cd55b9543b25 |
| `rural_set.glb` | 79 | Rural Buildings Set - Low Poly models | DanielZhabotinsky | Sketchfab | CC BY 4.0 | 10306 | https://sketchfab.com/3d-models/none-51ab7e74bac347a89725f1d22b928edf |
| `shabby_house.glb` | 81 | Suburban shabby house low poly | simlion | Sketchfab | CC BY 4.0 | 9991 | https://sketchfab.com/3d-models/none-f4678340de204c829e79a01f216e1be0 |
| `suburban_house.glb` | 82 | Suburban House | mbuannoart | Sketchfab | CC BY 4.0 | 8568 | https://sketchfab.com/3d-models/none-b8375c5e5e6b40639fc06492fbd95fcb |
| `wooden_house.glb` | 83 | Old Wooden House | rescue3d | Sketchfab | CC BY 4.0 | 453 | https://sketchfab.com/3d-models/none-5dcfdaa520814efa931275563ffb7391 |
| `brick_house.glb` | 85 | Small Brick House | jimbogies | Sketchfab | CC BY 4.0 | 10272 | https://sketchfab.com/3d-models/none-c9ef0a360eff405682015c8813eee41d |
| `gas_sign.glb` | 90 | Gasstation Sign - 2048px² | mark-peters | Sketchfab | CC BY 4.0 | 1370 | https://sketchfab.com/3d-models/none-11416edc56e941b7b10bcc87a6dc0ee7 |
| `gas_pump.glb` | 91 | The gas pump | ivanjirons0708 | Sketchfab | CC BY 4.0 | 6350 | https://sketchfab.com/3d-models/none-47e11796eae3458e955c0809bfcf47cf |
| `container_building.glb` | 93 | Building / Container / Metal | yadrogames | Sketchfab | CC BY 4.0 | 920 | https://sketchfab.com/3d-models/none-36380c606bae46848237e9bbe073fa3b |
| `warehouse.glb` | 94 | Small Warehouse | WardsterSAW | Sketchfab | CC BY 4.0 | 1193 → 869 | https://sketchfab.com/3d-models/none-c7f4c017c20943cb9e9e559822a5c402 |
| `industrial.glb` | 95 | Old Industrial Building | gazdahrco | Sketchfab | CC BY 4.0 | 67127 → 60730 | https://sketchfab.com/3d-models/none-0dafa7aaadfd4666bb4a32776c84b14e |
| `bricks.glb` | 97 | Stack Of Bricks (Game Ready / 2K PBR) | meerschaumdigital | Sketchfab | CC BY 4.0 | 3348 | https://sketchfab.com/3d-models/none-1a9092ab6cb243d990fddad116f04825 |
| `container.glb` | 100 | BLUE Container | Kwon_Hyuk | Sketchfab | CC BY 4.0 | 6612 | https://sketchfab.com/3d-models/none-38b62c0ba06a4d38a40204f0bdeaaa2f |
| `barrels_pack.glb` | 102 | Modular containers and barrells pack game ready | abbasyounis214 | Sketchfab | CC BY 4.0 | 2808 | https://sketchfab.com/3d-models/none-542b68aa56ee44f49c8860fdf158f831 |
| `propane.glb` | 104 | Propane Tank | Slinc | Poly Haven | CC0 | 5238 | https://polyhaven.com/a/propane_tank |
| `tyre.glb` | 105 | Old Tyre | MP | Poly Haven | CC0 | 2880 | https://polyhaven.com/a/old_tyre |
| `power_pole.glb` | 109 | Electrical Powerline Pole (Free Asset) | tiedtke | Sketchfab | CC BY 4.0 | 40006 → 3971 | https://sketchfab.com/3d-models/none-001a960897dd46c9a6a439e5fb1167f8 |

## Interfaccia — `assets/ui/`

| File | Cosa è | Fonte | Licenza | Modifiche |
|---|---|---|---|---|
| `route66_menu.jpg` | Sfondo del vecchio menù (non più usato dalla v0.17) | Disegnato da noi (`tools/art/route66.svg`) | Nostro | — |
| `circuit_*.jpg` | Immagini dei circuiti del vecchio menù | Render del gioco | Nostro | — |
| `loading_garage.jpg` | Sfondo della pagina di caricamento (garage visto dal cofano, serranda) | Immagine fornita da Stefano Paglierani il 07/11/2026 | Fornita da Stefano per il gioco (origine e diritti da confermare prima della pubblicazione) | Convertita in JPG (`tools/art/garage_images.py`) |
| `loading_door.png` | La serranda allungata fino a terra, che sale durante il caricamento | Ricavata da `loading_garage.jpg` | Come sopra | Ritagliata, lamelle ripetute |
| `garage_bg.jpg` | Sfondo del garage iniziale | Ricavata da `loading_garage.jpg` | Come sopra | Ritagliata senza il cofano |
| `title.jpg` | Pagina d'attesa (titolo, auto sulla costa) | Immagine fornita da Stefano Paglierani il 07/11/2026 | Fornita da Stefano per il gioco (origine e diritti da confermare prima della pubblicazione) | Convertita in JPG |
| `dealer_bg.jpg` | Sfondo del dealer (showroom con piatto girevole) | Immagine fornita da Stefano Paglierani l'08/11/2026 | Fornita da Stefano per il gioco (origine e diritti da confermare prima della pubblicazione) | Convertita in JPG |

## Font — `assets/fonts/`

| File | Cosa è | Fonte | Licenza | Modifiche |
|---|---|---|---|---|
| `PermanentMarker-Regular.ttf` | Font "a pennarello" delle scritte neon del dealer (v0.20) | [Permanent Marker](https://fonts.google.com/specimen/Permanent+Marker) di Font Diner, da [google/fonts](https://github.com/google/fonts/tree/main/apache/permanentmarker) (08/11/2026) | Apache 2.0 (uso commerciale permesso; testo in `PermanentMarker-LICENSE.txt`) | — |

Le icone al neon della v0.20 (garage, bomboletta, chiave e cacciavite, pezzi del tuning) sono
disegnate nel codice (`scripts/neon.gd`): nostre, nessun file.

## Icone dell'interfaccia — `assets/ui/icons/`

| File | Cosa è | Fonte | Licenza | Modifiche |
|---|---|---|---|---|
| 18 file `*.svg` (garage, dealer, race_start, map, my_cars, for_sale, tuning, paint, shop, switch_car, wallet, confirm, reset, garage_upgrade, previous, next, currency, star_currency) | Icone di garage e dealer (v0.22.1) | "Nitro UI Icon Pack v1", fornito da Stefano Paglierani l'08/11/2026 (50 icone, disegnate per il gioco) | Fornite da Stefano per il gioco (origine e diritti da confermare prima della pubblicazione) | Nessuna; importate con scala 2 |
