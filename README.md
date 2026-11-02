# Nitro Underground

**Gioco di corse clandestine in 3D per Android, con grafica a fumetto 2.5D.**
Fatto con Godot 4 · fisica dei veicoli scritta da zero · circuiti scritti come mappe di testo.

![Nitro Underground: gara sul passo di montagna](docs/immagini/gara-montagna.jpg)

[![Godot 4.7](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org)
![GDScript](https://img.shields.io/badge/GDScript-~7.500_righe-355570)
![Android](https://img.shields.io/badge/Android-arm64-3DDC84?logo=android&logoColor=white)
![Versione](https://img.shields.io/badge/versione-0.12-ff3d8b)
![Stato](https://img.shields.io/badge/stato-prototipo_giocabile-f5a623)

📖 [Storia dello sviluppo](docs/STORIA.md) · 🛠️ [Come è costruito](docs/TECNICO.md) · 🎨 [Crediti e licenze](CREDITI.md) · 🇬🇧 [English](#english)

---

## In 30 secondi

- **Cos'è:** un racing arcade per telefono nello spirito delle gare su strada: sorpassi nel
  traffico, nitro, derapate, salti e la polizia che arriva se fai troppi danni. Nome, mondo e
  circuiti sono originali.
- **Chi l'ha fatto:** **Stefano Paglierani** ha ideato e diretto il gioco: concept, stile,
  circuiti, auto, comandi e ogni scelta di prodotto, provando ogni build sul suo telefono Android.
  Il codice è stato scritto da **Claude** (l'assistente AI di Anthropic) sulle sue indicazioni.
- **In quanto tempo:** 7 giorni, dal 27 ottobre al 2 novembre 2026: **13 versioni** dal primo prototipo
  alla v0.12, ognuna provata su telefono o PC e migliorata in base alle prove.
- **Cosa dimostra:** direzione di prodotto e game design su un progetto reale, ciclo rapido
  prova → feedback → nuova versione, uso dell'intelligenza artificiale come squadra di sviluppo,
  attenzione alle licenze degli asset e alle prestazioni su telefono.

## Screenshot (v0.11.1)

| | |
|---|---|
| ![Menu Route 66 con scelta del circuito](docs/immagini/menu-circuiti.jpg) | ![Garage con scelta dell'auto](docs/immagini/menu-auto.jpg) |
| *Menu: illustrazione originale della Route 66, scelta del circuito* | *Garage: 7 auto, ognuna con velocità e trazione proprie* |
| ![Gara sulla costa](docs/immagini/gara-costa.jpg) | ![Gara nella città di notte](docs/immagini/gara-citta.jpg) |
| *Costa: lungomare, palme e traffico* | *Città di notte: palazzi con finestre accese, neon* |
| ![Gara nel deserto](docs/immagini/gara-deserto.jpg) | ![Panorama del deserto](docs/immagini/panorama-deserto.jpg) |
| *Deserto: la Route 66 attraverso il canyon* | *Deserto: paese con motel e distributore* |
| ![Panorama della costa](docs/immagini/panorama-costa.jpg) | ![Panorama della città di notte](docs/immagini/panorama-citta.jpg) |
| *Costa: palme, mare e case bianche* | *Città di notte: skyline di torri illuminate* |

## Cosa c'è nel gioco

| | |
|---|---|
| 🏁 **4 circuiti** | Montagna (passo alpino con tornanti), Costa (riviera), Città di notte (downtown), Deserto (Route 66) |
| 🚗 **7 auto** | Velocità massime da 210 a 255 km/h, trazione anteriore, posteriore o integrale |
| ⏱️ **Gara sprint** | 3 avversari guidati dal computer, checkpoint con tempo a scalare |
| 🚓 **Polizia** | Gli incidenti alzano il livello di allerta e arrivano le volanti |
| 💥 **Fisica vera** | Corpo rigido su 4 ruote con sospensioni, salti, derapate, traffico che si urta, guardrail che si rompono |
| 🔊 **Audio** | Motore V8 sintetizzato che segue i giri, cambiate, turbo, gomme, urti, sirena |
| 🎨 **Fumetto 2.5D** | Luce a bande, contorni a inchiostro, retino, cielo pop-art sopra a modelli 3D realistici |
| 🗺️ **Circuiti in testo** | Ogni pista è un file che si legge come un navigatore: chiunque può disegnarne una |
| 📱 **Comandi touch** | Pulsanti a esagono con icone, cruscotto digitale, traiettoria ideale colorata a terra |

## Come è costruito, in breve

Il dettaglio completo, con diagrammi e numeri, è in **[docs/TECNICO.md](docs/TECNICO.md)**.

- **Fisica dell'auto scritta da zero** su `RigidBody3D` + Jolt: ruote come cilindri proiettati
  che salgono sui cordoli, sospensioni molla-smorzatore, aderenza per ruota limitata dal carico,
  cambio a 6 marce. Verificata con un banco prova automatico: **0-100 km/h in 3,5 s**, frenata da
  144 km/h in 63 m, salti **entro il 2,5% della traiettoria balistica teorica**, stessi risultati a
  30, 60 e 120 tick al secondo.
- **Un linguaggio per disegnare i circuiti** (`tracks/*.txt`): `DRITTO 520`, `TORNANTE DESTRA`,
  `CHICANE SINISTRA`... Il gioco chiude l'anello da solo e ne ricava strada, terreno, guardrail,
  traiettoria ideale, velocità in curva per l'IA e tempo dei checkpoint.
- **Stile a fumetto** fatto con shader: materiali toon applicati a tutto ciò che entra in scena e
  una passata a schermo intero (bande, inchiostro sui salti di profondità, retino, tratteggio).
- **Costruito dal codice**: le scene sono quasi vuote, strade, terreno, auto, interfaccia e
  materiali nascono dagli script. Tutto è testo leggibile e versionato.
- **Pensato per il telefono**: caricamento a passi con modelli letti in thread paralleli, modelli
  3D fusi per ridurre le chiamate di disegno (da oltre 1.000 a poche per modello), texture compresse.
- **Licenze tracciate**: oltre 120 asset gratuiti registrati con autore, link e licenza.

![Mappe dei quattro circuiti](docs/immagini/mappe-circuiti.png)

## Come è cambiato

![Evoluzione del gioco](docs/immagini/evoluzione.jpg)

Dalla città low poly vista dall'alto del primo giorno al fumetto 2.5D di oggi: ogni svolta è nata
dalle prove sul telefono. La [storia completa](docs/STORIA.md) racconta, versione per versione,
cosa è stato chiesto e come è stato costruito.

| Versione | In una riga |
|---|---|
| v0.1 | Primo prototipo giocabile sul telefono: città notturna, visuale dall'alto |
| v0.2-v0.3 | Fisica a corpo rigido, telecamera dietro l'auto, salti |
| v0.4-v0.6 | Montagna di giorno, garage, guida dalle ruote, cruscotto, guardrail distruttibili |
| v0.7-v0.9 | Audio, traffico urtabile, comandi a esagoni, stile a fumetto 2.5D |
| v0.10 | Menu Route 66, caricamento leggero, tempo a scalare |
| v0.11-v0.11.1 | Circuiti come mappe di testo, ambientazioni rifatte, Deserto, garage da 7 |
| v0.12 | Stabilizzazione: pausa, polizia più giusta, rivali più veloci, traffico che si libera da solo |

## Provarlo

**PC Windows (il modo più semplice):** scarica [`Gioca-Nitro.bat`](tools/windows/Gioca-Nitro.bat)
e [`gioca-nitro.ps1`](tools/windows/gioca-nitro.ps1) nella stessa cartella e fai doppio clic sul
`.bat`. La prima volta scarica Godot 4.7.2 e l'ultima build (ramo `prova-pc`), prepara i modelli
(5-10 minuti) e avvia il gioco.

| Tastiera | Azione |
|---|---|
| ← → oppure A D | Sterzo |
| ↑ oppure W / ↓ oppure S | Gas / Freno e retromarcia |
| Spazio | Freno a mano (derapata) |
| Shift oppure N | Nitro |

**Android:** gli APK (circa 300 MB) non sono nel repository. Si possono creare con
`GODOT=/percorso/godot tools/build_android.sh` (servono i template Android di Godot 4.7).

**Editor:** apri la cartella con **Godot 4.7** e premi Play.

## Struttura del repository

| Percorso | Contenuto |
|---|---|
| `scripts/` | Tutto il gioco: menu, gara, auto, circuiti, traffico, audio, stile, interfaccia |
| `shaders/` | Stile a fumetto, cielo, terreno, mare, facciate illuminate, vernice delle auto |
| `tracks/` | Le mappe dei circuiti in testo e la guida [`COME_FARE.md`](tracks/COME_FARE.md) |
| `assets/` | Modelli, texture e suoni, con il registro [`LICENSES.md`](assets/LICENSES.md) |
| `tests/` | Banco prova della fisica |
| `tools/` | Build Android, anteprima mappe, screenshot automatici, launcher Windows, sintesi audio |
| `docs/` | Storia, documentazione tecnica, immagini |

## Licenze

Tutti gli asset vengono da fonti gratuite (CC0 e CC BY) e sono registrati in
[`assets/LICENSES.md`](assets/LICENSES.md). Alcuni modelli di auto (marchi reali, licenze non
commerciali) sono usati solo perché questo è un prototipo senza scopo commerciale: il riepilogo
onesto è in [CREDITI.md](CREDITI.md). Il codice non ha ancora una licenza open source: tutti i
diritti sono riservati all'autore.

## Roadmap

1. ~~Documento di concept~~ ✔
2. **Prototipo giocabile su telefono** ← siamo qui (v0.1 → v0.12, fase di stabilizzazione)
3. Vertical slice: un circuito e un'auto rifiniti al livello del gioco finale
4. Produzione e pubblicazione, con sostituzione degli asset non commerciali

---

## English

**Nitro Underground** is a 3D arcade street-racing game for Android with a 2.5D comic-book look,
built with **Godot 4.7** (GDScript, Mobile/Vulkan renderer, Jolt physics). Current version:
**v0.12**, a playable prototype (stabilisation phase).

**Who made it.** **Stefano Paglierani** conceived and directed the game: concept, art direction,
circuits, cars, controls and every product decision, testing each build on his Android phone.
The code was written by **Claude** (Anthropic's AI assistant) from his direction. 13 versions were
designed, built and play-tested in 7 days (27 October - 2 November 2026).

**Highlights**
- **Custom vehicle physics** on a `RigidBody3D`: shape-cast wheels that climb kerbs,
  spring-damper suspension, load-limited tyre grip, FWD/RWD/AWD, 6-speed gearbox. Validated by an
  automated bench: 0-100 km/h in 3.5 s, ramp jumps within 2.5% of the ballistic prediction,
  frame-rate independent at 30/60/120 Hz.
- **A tiny track-description language** (`tracks/*.txt`, Italian keywords such as `DRITTO`,
  `TORNANTE`, `CHICANE`) that auto-closes the loop and generates road, terrain, guardrails, a
  racing line with a speed profile for the AI, and checkpoint times.
- **2.5D comic rendering**: toon materials applied to everything that enters the scene, plus a
  full-screen pass with cel bands, depth-based ink lines, halftone, hatching and misregistered colour plates.
- **Synthesized V8 engine audio**, crossfaded and pitched to RPM in real time.
- **Mobile-minded**: staged, threaded loading; models merged into one mesh per material
  (a 123-part model went from 1,000+ draw calls to a handful); GPU-compressed textures.
- **Rigorous asset licensing**: 120+ free assets logged with author, link and licence; the
  non-commercial exceptions are declared openly in [CREDITI.md](CREDITI.md).

Docs (in Italian): [development history](docs/STORIA.md) · [technical deep dive](docs/TECNICO.md).
The code has no open-source licence yet (all rights reserved).
