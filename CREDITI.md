# Crediti e licenze

Nitro Underground è stato fatto a costo zero, usando solo asset gratuiti. Qui c'è il riepilogo;
l'elenco completo, file per file, con autore, link, licenza e modifiche, è in
[`assets/LICENSES.md`](assets/LICENSES.md).

## Chi l'ha fatto

- **Idea, direzione, scelte di gioco e prove:** Stefano Paglierani
- **Codice, shader, strumenti e build:** scritti da Claude (Anthropic) su richiesta di Stefano
- **Suoni del motore:** sintetizzati da zero con `tools/audio/make_engine_sounds.py` (CC0)
- **Illustrazione del menu Route 66:** originale, disegnata in SVG (`tools/art/route66.svg`)

## Fonti degli asset

| Fonte | Cosa | Licenza |
|---|---|---|
| [Poly Haven](https://polyhaven.com) | Cieli HDRI, texture di asfalto, roccia, erba, sabbia; lampioni, rocce, cespugli, sacchi, tavoli, bombole, copertoni | CC0 |
| [OpenGameArt](https://opengameart.org) | Kenney (piste, natura, strade), Quaternius (alberi, versione 2020), Yughues (erba, barriere) e altri | CC0 |
| [Freesound](https://freesound.org), OpenGameArt | Registrazioni di urti, cambiate, gomme, freno a mano | CC0 |
| [Sketchfab](https://sketchfab.com) | Alberi, chalet, cartelli, barriere, palazzi, palme, faro, motel, cactus, rocce; dalla v0.21 case americane, arredo urbano, distributori, magazzini, pali della luce | **CC BY 4.0** (attribuzione obbligatoria) |
| Sketchfab | Tutte le auto: garage e avversari, polizia, traffico (DanielZhabotinsky, Lexyc16, TinoD2, ollitei e altri) | CC BY 4.0 in gioco; nessuna auto NC (vedi sotto) |
| [Google Fonts](https://fonts.google.com) | Font Permanent Marker (Font Diner) delle scritte del dealer | Apache 2.0 |

Tutti gli autori Sketchfab sono citati per nome in `assets/LICENSES.md`.

## ⚠️ Cosa non si potrebbe usare in un gioco in vendita

Il gioco oggi è un **prototipo e un portfolio, senza scopo commerciale**. Alcuni asset sono stati
scelti consapevolmente solo per questa fase e andranno **sostituiti prima di qualsiasi
pubblicazione sugli store**. Stefano ha deciso così il 29 ottobre 2026.

1. **Licenze non commerciali (NC).** Dalla v0.15 (06/11/2026) **nessuna auto NC è nel gioco**:
   tutte le auto in gara sono CC BY 4.0, e il 06/11/2026 i file delle auto NC delle versioni precedenti
   (Charger 1970, Corvette Z06 e 1969, BMW M3 GTR, Supra A80, Camaro ZL1, GMC Sierra, Ford Mondeo
   Police, McLaren 600LT, Porsche 911 GT3, Raptor, RAM, Mustang) sono stati cancellati dal repository.
2. **Marchi registrati.** Dalla v0.15 le auto di marchi reali hanno nomi inventati e, dove si
   poteva, i loghi nascosti; restano però forme riconoscibili e alcuni loghi dipinti nelle texture
   (per esempio la Zenith Proto). Nomi, forme e loghi di Nissan, Honda, Mazda, Porsche, BMW, Datsun,
   Lancia, Ford, Oldsmobile, Chevrolet, Land Rover, Jeep e degli altri costruttori appartengono ai rispettivi proprietari. Usarli in un gioco in vendita richiede licenze
   dei costruttori, anche quando il modello 3D è CC BY.
3. **Riferimenti ai film.** La Skyline R34 "Brian" e la Charger "Fast And Furious Edition", ispirate
   ad auto di film famosi, sono state tolte dal gioco e dal repository il 06/11/2026.
4. **Provenienza incerta.** Dai nomi interni dei file, alcuni modelli di auto sembrano estratti da
   altri videogiochi da chi li ha caricati su Sketchfab. È un motivo in più per non usarli oltre il prototipo.
5. **Quaternius.** Gli alberi Quaternius nel repository sono la versione pubblicata su OpenGameArt
   nel 2020 con licenza CC0. Dal 28 agosto 2026 i nuovi pacchetti Quaternius non sono più CC0:
   non vanno aggiunti al repository senza ricontrollare la licenza.

Tutto il resto (CC0 e CC BY) si può usare anche in un gioco in vendita. Per i CC BY i crediti
dovranno comparire anche **nei titoli di coda del gioco**, che non ci sono ancora.

## Modelli del mondo generato

`assets/worlds/isola_gara.scn` usa i modelli elencati in [`assets/LICENSES.md`](assets/LICENSES.md),
CC BY 4.0 e CC0: i CC BY dovranno comparire nei titoli di coda come gli altri.

| Modello | Autore | Fonte | Licenza | Link |
|---|---|---|---|---|
| Real Bush | marblesstudio | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-62618c3260b142cfb7ef499d75a8d21a |
| Cliffs | bumstrum | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-14fe5023840146179c8515093e88fae0 |
| Oak tree | evolveduk | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-6468dd4d3eb240ef902b9057d9913606 |
| Coniferous Forest Assets Pack | dariiiii | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-240ce9cf0ad3474f809a59f9446e63cd |
| Pine Tree | evolveduk | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-d45218a3fab349e5b1de040f29e7b6f9 |
| Low poly vegetation for games | denoises | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-cdac82eb61ab4d83bf162b4c44b44d6d |
| Trash can | bazz4r | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-3836ff67877248c2a820e6a969984aac |
| Wooden Picnic Table | Ulan Cabanilla | Poly Haven | CC0 | https://polyhaven.com/a/wooden_picnic_table |
| Street light Lamp spotlight - 10MB | ahmagh2e | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-b3534b9033a24f0aad2e1f9527bd4ca8 |
| Jersey Barrier | emran.bayati | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-b52246c9611a42a99a03b425535a0237 |
| Road Barrier | sousinho | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-85b489ac36344ca9af98a78ecffa186f |
| Concrete fence | BlackMike | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-1ca049b5951542f094ef409f74534ae3 |
| Brick Shop Building | Lowpoly | Fridqeir | Sketchfab | 1868 |
| LP Americans House Mobile | spaceparmesan | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-bdd2465e5ff54fe09701cd55b9543b25 |
| Suburban shabby house low poly | simlion | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-f4678340de204c829e79a01f216e1be0 |
| Old Wooden House | rescue3d | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-5dcfdaa520814efa931275563ffb7391 |
| Barn with mini-shop (old age) | Dorin.Stoica | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-5e59322d38d445ada354967ef5932abf |
| Small Brick House | jimbogies | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-c9ef0a360eff405682015c8813eee41d |
| The gas pump | ivanjirons0708 | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-47e11796eae3458e955c0809bfcf47cf |
| Building | Container | Metal | yadrogames | CC BY 4.0 |
| Small Warehouse | WardsterSAW | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-c7f4c017c20943cb9e9e559822a5c402 |
| Stack Of Bricks (Game Ready / 2K PBR) | meerschaumdigital | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-1a9092ab6cb243d990fddad116f04825 |
| Old rubbish Skip | sousinho | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-2f9aa03ede3a46a0888e76fed382667f |
| Modular containers and barrells pack game ready | abbasyounis214 | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-542b68aa56ee44f49c8860fdf158f831 |
| Post Apocalytpic style Container | sousinho | Sketchfab | CC BY 4.0 | https://sketchfab.com/3d-models/none-363b36fdbae940a7bee619e17da4803a |
| Propane Tank | Slinc | Poly Haven | CC0 | https://polyhaven.com/a/propane_tank |
| Old Tyre | MP | Poly Haven | CC0 | https://polyhaven.com/a/old_tyre |

L'isola grande (`assets/worlds/isola_x5/`) ha il suo elenco in
[`assets/worlds/isola_x5/credits.md`](assets/worlds/isola_x5/credits.md).

## Regole per i nuovi asset

- Ogni nuovo file in `assets/` va registrato in `assets/LICENSES.md` nello stesso commit:
  fonte, autore, link, licenza alla data del download, modifiche.
- Preferire CC0 e CC BY. Un asset NC o di un marchio reale si aggiunge solo se Stefano lo chiede,
  e va segnalato qui nella sezione "Cosa non si potrebbe usare".
- I file grandi della libreria di lavoro (modelli non ancora usati, APK, zip originali) restano
  nella cartella del progetto, fuori dal repository.

## Il codice

Il codice non ha ancora una licenza open source: tutti i diritti sono riservati all'autore.
Si può leggere e studiare qui su GitHub, ma non riusare senza permesso.
