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

Contiene 5 auto low poly con ruote separate (berlina, hatchback, station wagon, taxi, **polizia**), edifici, strade, lampioni, semafori, cassonetti, idranti, panchine. Stile cartoon: adatto a traffico e segnaposto. Scala circa 1/5 del reale (un'auto è lunga 0,94 m): va scalata ×5 circa quando si usa. La volante non ha scritte di corpi di polizia reali.
