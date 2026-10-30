# Registro licenze degli asset

Ogni file in `assets/` deve comparire qui, con fonte, autore, licenza alla data del download e modifiche fatte.

Tutti gli asset attuali vengono da [Poly Haven](https://polyhaven.com) e sono **CC0 1.0** (pubblico dominio): uso commerciale libero, modifiche libere, attribuzione non obbligatoria (la diamo comunque per correttezza). Licenza verificata su https://polyhaven.com/license il 2026-10-28.

## HDRI (cielo notturno e riflessi) — `assets/hdri/`

| File | Asset | Autore | Link | Licenza | Download | Modifiche |
|---|---|---|---|---|---|---|
| `modern_evening_street_1k.hdr` | Modern Evening Street | Grzegorz Wronkowski | https://polyhaven.com/a/modern_evening_street | CC0 1.0 | 2026-10-28 | Nessuna (risoluzione 1K) |
| `cobblestone_street_night_1k.hdr` | Cobblestone Street Night | Greg Zaal, Jenelle van Heerden | https://polyhaven.com/a/cobblestone_street_night | CC0 1.0 | 2026-10-28 | Nessuna (risoluzione 1K) |
| `modern_buildings_night_1k.hdr` | Modern Buildings Night | Greg Zaal | https://polyhaven.com/a/modern_buildings_night | CC0 1.0 | 2026-10-28 | Nessuna (risoluzione 1K) |
| `dresden_station_night_1k.hdr` | Dresden Station Night | Greg Zaal | https://polyhaven.com/a/dresden_station_night | CC0 1.0 | 2026-10-28 | Nessuna (risoluzione 1K) |

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

## KayKit City Builder Bits 1.0 — `assets/kaykit_city_builder_bits/`

| Pack | Autore | Link | Licenza | Download | Modifiche |
|---|---|---|---|---|---|
| City Builder Bits 1.0 (solo la cartella glTF: 41 modelli + `citybits_texture.png`) | Kay Lousberg (www.kaylousberg.com) | https://github.com/KayKit-Game-Assets/KayKit-City-Builder-Bits-1.0 (commit `6397691`) | CC0 1.0 (vedi `LICENSE.txt` nella cartella) | 2026-10-28 | Nessuna |

Contiene 5 auto low poly con ruote separate (berlina, hatchback, station wagon, taxi, **polizia**), edifici, strade, lampioni, semafori, cassonetti, idranti, panchine. Stile cartoon: adatto a traffico e segnaposto. Scala circa 1/5 del reale (un'auto è lunga 0,94 m): va scalata ×5 circa quando si usa. Prima di usare la volante in gioco va controllata la livrea (niente scritte di corpi di polizia reali).


## Percorso di montagna (Poly Haven)

| File e uso | Tipo | Asset | Autore | Link | Licenza | Download | Modifiche |
|---|---|---|---|---|---|---|---|
| `assets/hdri/kloofendal_48d_partly_cloudy_puresky_2k.hdr`, cielo della montagna | HDRI 2K | Kloofendal 48d Partly Cloudy (Pure Sky) | Greg Zaal, Jarod Guest | https://polyhaven.com/a/kloofendal_48d_partly_cloudy_puresky | CC0 1.0 | 2026-10-29 | Nessuna |
| `assets/materials/aerial_grass_rock/`, erba del terreno (colorata più verde nello shader) | Texture 1K | Aerial Grass Rock | Rob Tuytel | https://polyhaven.com/a/aerial_grass_rock | CC0 1.0 | 2026-10-29 | Nessuna |
| `assets/materials/rocky_terrain_02/`, terreno vicino alla strada | Texture 1K | Rocky Terrain 02 | Amal Kumar | https://polyhaven.com/a/rocky_terrain_02 | CC0 1.0 | 2026-10-29 | Nessuna |
| `assets/materials/rock_face/`, pareti di roccia | Texture 1K | Rock Face | Greg Zaal, Dario Barresi | https://polyhaven.com/a/rock_face | CC0 1.0 | 2026-10-29 | Nessuna |
| `assets/props/rock_09/`, massi a bordo strada | Modello glTF | Rock 09 | Jenelle van Heerden | https://polyhaven.com/a/rock_09 | CC0 1.0 | 2026-10-29 | Nessuna |
| `assets/props/moon_rock_02/`, massi a bordo strada | Modello glTF | Moon Rock 02 | Rico Cilliers, Greg Zaal, Jenelle van Heerden | https://polyhaven.com/a/moon_rock_02 | CC0 1.0 | 2026-10-29 | Nessuna |
| `assets/props/rock_face_01/`, roccia a bordo strada | Modello glTF | Rock Face 01 | Dario Barresi | https://polyhaven.com/a/rock_face_01 | CC0 1.0 | 2026-10-29 | Nessuna |

I pini, i guardrail e la strada della montagna sono generati dal codice (`scripts/mountain.gd`), non sono asset esterni. `clean_asphalt` (già registrato sopra) è usato anche per le banchine.

## Libreria di modelli da OpenGameArt — `assets/library/`

Scaricati il 2026-10-29 da https://opengameart.org (dominio aperto da Stefano). Tutti i pacchetti sono marcati **CC0** sulla loro pagina OpenGameArt (verificato pagina per pagina al download). La cartella ha un file `.gdignore`: Godot non la importa e non finisce nell'APK. Per usare un modello, si copia fuori dalla libreria (per esempio in `assets/props/`) e si annota l'uso qui.

Modifiche comuni a tutti i pacchetti: tenuti solo i formati che Godot legge (glTF/GLB, FBX, OBJ). Tolti i file `.blend`, i collegamenti `.url`/`.html` e i doppioni in altri formati. Le immagini di anteprima sono state ridotte a 960 px in JPG. Le texture `.tga` sono state convertite in PNG (le diffuse e le speculari delle barriere Yughues in JPG), e i `.mtl` sono stati aggiornati di conseguenza.

| Cartella | Contenuto | Autore | Pagina | Licenza |
|---|---|---|---|---|
| `kenney_car_kit/` | 50 veicoli GLB (berline, sportive, polizia, ambulanza, camion, furgoni) e ruote | Kenney | https://opengameart.org/content/car-kit | CC0 (`License.txt`) |
| `kenney_racing_kit/` | 71 pezzi di pista glTF (rettilinei, curve, barriere, gomme, bandiere, tribune, auto da corsa) | Kenney | https://opengameart.org/content/racing-kit | CC0 (`License.txt`) |
| `kenney_city_kit_roads/` | 95 pezzi GLB di strade, incroci, ponti, segnaletica, lampioni | Kenney | https://opengameart.org/content/city-kit-roads | CC0 (`License.txt`) |
| `kenney_nature_kit/` | 329 modelli glTF di natura (alberi, pini, rocce, cespugli, erba, sentieri, staccionate) | Kenney | https://opengameart.org/content/nature-kit | CC0 (`License.txt`) |
| `rgsdev_vehicles/` | 21 veicoli FBX: berlina, hatchback, sportiva, 2 muscle, roadster, SUV, pickup, van, taxi, limousine, bus, camion, ambulanza, pompieri, monster truck e 4 volanti (berlina, sportiva, muscle, SUV) | rgsdev | https://opengameart.org/content/free-low-poly-vehicles-pack | CC0 (`License.txt`) |
| `street_racing_car/` | Auto da strada FBX con texture | Alexander123 | https://opengameart.org/content/street-racing-car | CC0 |
| `red_car/` | Auto rossa GLB con ruote separate | mabaci | https://opengameart.org/content/3d-car-model-for-unity-unreal-engine-ready-for-car-controller-%F0%9F%9A%97 | CC0 |
| `ggbotnet_psx_cars/` | 8 auto stile PSX (OBJ con texture) e ombra | GGBotNet | https://opengameart.org/content/psx-style-cars | CC0 |
| `byzmod3d_cars/` | Auto FBX (versione normale ed effetto) | byzmod3d | https://opengameart.org/content/low-poly-car-update-pack | CC0 |
| `lyricsz_cars/` | 20 auto GLB con interni e animazioni | Lyricsz | https://opengameart.org/content/ultimate-3d-car-assets-pack-w-interiors-and-animations | CC0 |
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

Note: sono quasi tutti modelli low poly o "mid poly", non realistici. Le volanti (Kenney, rgsdev) vanno controllate prima dell'uso: niente scritte o stemmi di corpi di polizia reali. Non scaricati perché troppo pesanti per un telefono: le rocce fotogrammetriche di Yughues (120–165 MB l'una) e il Mossy Rock Environment Pack (237 MB); sono comunque CC0 e si possono prendere se servono. Non scaricato perché esiste solo in formato `.blend` (qui non c'è Blender per convertirlo): Spruce Deforestation Models (abeti, CC0).

### Modelli della libreria usati nel gioco (v0.4)

| File e uso | Preso da | Modifiche |
|---|---|---|
| `assets/cars_rgsdev/*.fbx`, auto del giocatore, degli avversari, del traffico e volanti | `library/rgsdev_vehicles/` (rgsdev, CC0) | File rinominati in minuscolo. In gioco: scala 0,78, girati di 180°, materiali rifatti nel codice (vernice lucida, vetri, fari e lampeggianti luminosi) |
| `assets/props/trees/*.fbx` e texture, pini e betulle della montagna | `library/quaternius_textured_trees/` (Quaternius, CC0 su OpenGameArt) | Solo Pine_1, 2, 3, 5 e Birch_1, 3. In gioco: ingranditi da 1,7 a 2,7 volte e foglie scurite |
| `assets/props/grass/grass_01.png`, `grass_02.png`, `grass_04.png`, ciuffi d'erba a bordo strada | `library/yughues_grass/` (Yughues, CC0) | Solo la texture diffusa con alfa, rinominata. In gioco: due quadrati incrociati, colore più verde |

## Garage della v0.5

### Auto realistiche da Sketchfab — `assets/cars_sketchfab/`

Scaricate da Stefano e caricate il 2026-10-29. Licenze **non commerciali**: vanno bene finché il gioco resta un prototipo o portfolio (decisione di Stefano del 2026-10-29). Prima di un'eventuale pubblicazione sugli store vanno sostituite. I marchi (McLaren, Ford, RAM) sono dei rispettivi proprietari. Dai nomi interni dei file sembrano modelli derivati da un altro videogioco: è un motivo in più per non usarli in una versione commerciale.

| Cartella | Modello | Autore | Link | Licenza | Modifiche |
|---|---|---|---|---|---|
| `mclaren_600lt/` | McLaren 600LT | Outlaw Games™ | https://sketchfab.com/3d-models/mclaren-600lt-23d87647c2b840d99ff06215613e8788 | CC BY-NC 4.0 (`license.txt`) | Nessuna sui file; in gioco viene scalata, girata e le ruote anteriori sterzano |
| `2024_ford_f-150_raptor_r/` | 2024 Ford F-150 Raptor R | VTX | https://sketchfab.com/3d-models/2024-ford-f-150-raptor-r-9fbd01c5acfb45e7a7bbdf4c8e2c4aa8 | CC BY-NC-SA 4.0 (`license.txt`) | Come sopra. Le versioni modificate vanno condivise con la stessa licenza |
| `2021_ram_1500_trx/` | 2021 Ram 1500 TRX | Ddiaz Design | https://sketchfab.com/3d-models/2021-ram-1500-trx-372fbf37230c46eca1997841bfaf0758 | CC BY-NC-SA 4.0 (`license.txt`) | Come sopra; le ruote sono un unico oggetto e non sterzano |

Crediti richiesti: "This work is based on "McLaren 600LT" by Outlaw Games™, "2024 Ford F-150 Raptor R" by VTX and "2021 Ram 1500 TRX" by Ddiaz Design (links above), licensed under CC-BY-NC-4.0 / CC-BY-NC-SA-4.0."

### Altri veicoli del garage

| File | Preso da | Licenza |
|---|---|---|
| `assets/cars_rgsdev/*.fbx` (ora tutti i 21 veicoli) | `library/rgsdev_vehicles/` (rgsdev) | CC0 |
| `assets/cars_kenney/*.glb` e `Textures/` (25 veicoli, senza detriti, coni e ruote sciolte) | `library/kenney_car_kit/` (Kenney Car Kit 3.1) | CC0 (`License.txt`) |
| `assets/kaykit_city_builder_bits/car_*.gltf` | KayKit (vedi sopra) | CC0 |

In gioco i veicoli vengono scalati alla loro lunghezza reale e appoggiati a terra; le volanti Kenney ricevono lampeggianti fatti nel codice. L'elenco completo con i nomi mostrati nel menu è in `scripts/car_catalog.gd`.

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
