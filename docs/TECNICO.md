# Come è costruito Nitro Underground

Questo documento spiega **come funziona il gioco dentro**: le scelte tecniche, perché sono state
fatte e come sono state verificate. È pensato per chi valuta il progetto (recruiter, sviluppatori,
game designer) e vuole capire cosa c'è dietro gli screenshot.

> Contesto: il gioco è stato ideato e diretto da Stefano Paglierani, che ha preso ogni decisione di
> prodotto e ha provato ogni build su telefono e PC. Il codice è stato scritto da Claude
> (assistente AI di Anthropic) sulle sue indicazioni. Vedi la [storia dello sviluppo](STORIA.md).

## Indice

1. [Numeri del progetto](#1-numeri-del-progetto)
2. [Architettura](#2-architettura)
3. [Fisica dell'auto](#3-fisica-dellauto)
4. [Avversari, traffico e polizia](#4-avversari-traffico-e-polizia)
5. [Circuiti scritti come mappe di testo](#5-circuiti-scritti-come-mappe-di-testo)
6. [Grafica: lo stile a fumetto 2.5D (spento dalla v0.13)](#6-grafica-lo-stile-a-fumetto-25d-spento-dalla-v013)
7. [Audio](#7-audio)
8. [Asset: fonti, licenze e ottimizzazione](#8-asset-fonti-licenze-e-ottimizzazione)
9. [Prestazioni su telefono](#9-prestazioni-su-telefono)
10. [Prove automatiche e strumenti](#10-prove-automatiche-e-strumenti)
11. [Build e distribuzione delle versioni di prova](#11-build-e-distribuzione-delle-versioni-di-prova)

---

## 1. Numeri del progetto

| | |
|---|---|
| Durata | 5 giorni, dal 27 al 31 ottobre 2026 (concept → v0.11.1) |
| Versioni provate su telefono o PC | 12 (v0.1 → v0.11.1), più varianti di prova |
| Codice | ~7.500 righe di GDScript nel gioco, ~500 di shader, ~1.000 di strumenti e test |
| Circuiti | 4 (Montagna, Costa, Città di notte, Deserto), da 1,7 a 2,8 km |
| Auto nel garage | 7, ognuna con velocità massima e trazione proprie |
| Asset di terze parti | oltre 120 voci nel registro licenze (modelli, texture, suoni), CC0 e CC BY più le eccezioni dichiarate |
| Budget | 0 €: solo strumenti e asset gratuiti |

## 2. Architettura

Il gioco è fatto con **Godot 4.7** in **GDScript**, renderer **Mobile (Vulkan)** sul PC e **Compatibility (OpenGL)** sul telefono (v0.14: con Vulkan la gara sull'A51 di Stefano andava a scatti), fisica **Jolt**.
Una scelta presa al primo giorno: quasi tutto viene **costruito dal codice**. Le scene `.tscn`
sono due file quasi vuoti (menu e gara); strade, terreno, guardrail, alberi, auto, interfaccia e
materiali nascono dagli script. Così ogni cosa è testo leggibile, versionabile e modificabile senza
aprire l'editor, che era fondamentale per un progetto sviluppato in sessioni remote.

```mermaid
flowchart LR
    Menu["menu.gd<br/>Route 66: circuito → auto → VIA!"] --> Main["main.gd<br/>regole di gara, checkpoint,<br/>tempo, polizia, telecamera"]
    Main --> Track["Track (track.gd)<br/>interfaccia comune dei circuiti"]
    Track --> Mountain["Mountain<br/>strada, terreno, guardrail,<br/>traiettoria ideale"]
    Mountain --> Coast & Night["NightCity"] & Desert
    Layout["TrackLayout<br/>tracks/*.txt"] --> Mountain
    Scenery["Scenery<br/>modelli realistici a bordo strada"] --> Mountain
    Main --> Car["Car (RigidBody3D)<br/>giocatore, avversari, polizia"]
    Car --> CarAudio["CarAudio"]
    Car --> CarModel["CarModel / CarCatalog"]
    Main --> Traffic["TrafficCar<br/>traffico urtabile"]
    Main --> Hud["Hud + Dashboard<br/>comandi touch, cruscotto"]
    Comic["ComicStyle<br/>materiali toon + passata a schermo"] -.-> Main
```

- **`Track`** è l'interfaccia che il resto del gioco conosce: punti della strada, punto più
  vicino, corsie del traffico, velocità consigliata in curva, altezza del terreno. `Mountain`
  la implementa, e `Coast`, `NightCity` e `Desert` estendono `Mountain` ridefinendo solo dei
  "ganci" (terreno, materiali, dove crescono gli alberi, cosa c'è a bordo strada). Aggiungere
  un circuito vuol dire scrivere una mappa e, se serve, una sottoclasse di poche centinaia di righe.
- **`Car`** è la stessa classe per giocatore, avversari e polizia: un controllore riempie gli
  ingressi (`in_throttle`, `in_steer`...) e la fisica fa il resto. Le auto del computer guidano
  quindi con le stesse regole del giocatore, senza scorciatoie.
- **`CarCatalog`** descrive ogni auto (modello, velocità massima, trazione, nome) e il garage.

## 3. Fisica dell'auto

`scripts/car.gd` · banco prova `tests/physics_bench.gd`

L'auto è un **`RigidBody3D`** portato da quattro ruote simulate a mano, non un `VehicleBody3D`
già pronto, per avere il controllo completo del comportamento:

- **Ruote come cilindri proiettati verso il basso** (shape cast), non semplici raggi: una ruota
  che incontra un cordolo ci sale sopra invece di sbatterci contro.
- **Sospensioni molla-smorzatore** per ruota, con estensione smorzata 1,8 volte più della
  compressione (come un ammortizzatore vero), così un atterraggio pesante non rilancia l'auto in aria.
- **Gomme con aderenza limitata dal carico** su quella ruota, spinta lungo e di traverso alla strada:
  in frenata il peso va avanti e il retro si alleggerisce, come nella realtà.
- **Trazione dalle ruote motrici**: anteriore, posteriore o integrale a seconda dell'auto
  (`front_drive` da 0 a 1). Le ruote anteriori sterzano davvero e l'auto va dove puntano.
- **Cambio automatico a 6 marce** con rapporti lunghi e forza che cala con la marcia
  (`forza ~ rapporto^0,55`), giri motore da 900 a 7.800 per cruscotto e audio.
- **Sterzo che si stringe con la velocità** (da 38° a passo d'uomo a 9° oltre 160 km/h), e il
  giocatore sterza il 30% più dolcemente degli avversari (richiesta di Stefano dopo le prove).
- **Freno a mano** che toglie parte dell'aderenza al posteriore (dal 100% al 65%) per la
  derapata, e un aiuto d'imbardata che resta attivo all'80% anche in derapata: l'auto scivola di
  traverso ma non va in testacoda (v0.22).
- **Freno con aiuto arcade** (v0.22): oltre ai freni sulle gomme, una decelerazione di 9 m/s²
  a pedale pieno che non dipende dall'aderenza. Le gomme dividono la loro presa tra frenare e
  girare, quindi in curva il solo pedale non frenava quasi niente.
- **Nitro** (v0.22): velocità massima +30%, motore 2,6 volte più forte e una spinta di 5,5 m/s²
  che non dipende dalla marcia.
- **Peso** (v0.22): le auto pesano 1.800 kg (1,5 volte prima). Motore, freni, molle,
  ammortizzatori, resistenza dell'aria e deportanza sono cresciuti dello stesso fattore, quindi la
  guida è la stessa, ma negli scontri l'auto viene spostata molto meno. Negli urti tra auto la
  spinta verso l'alto è limitata a 1 m/s e il rollio a 1,5 rad/s, e mentre l'auto sale in aria
  c'è 0,8 g di gravità in più: niente più voli di diversi metri.
- **Salti**: in aria lo sterzo non fa nulla (un'auto non ha contro cosa girare); l'auto si
  raddrizza da sola. Vengono contati decollo, rotazioni e qualità dell'atterraggio.

**Verifica con numeri, non a sensazione.** Il banco prova guida un'auto di riferimento su un
terreno di test, misura e stampa tutto in JSON. Va lanciato a 30, 60 e 120 tick al secondo per
controllare che la fisica non cambi col frame rate. Risultati a 60 tick (v0.22):

| Prova | Risultato |
|---|---|
| 0-100 km/h | 3,55 s |
| Frenata da 144 km/h | 33,4 m in 1,7 s (v0.21: 62,9 m in 3,2 s) |
| Velocità massima (auto di riferimento) | 212,6 km/h |
| Nitro: velocità dopo 3 s da fermo | 146 km/h (v0.21: 91 km/h) |
| Derapata col freno a mano | angolo massimo 38°, esce a 95 km/h (v0.21: 84°, 38 km/h) |
| Curva stretta a 59 km/h / curva veloce a 101 km/h | 1,85 g / 2,09 g laterali |
| Salto da rampa a 15° a 90 km/h | 15,3 m (v0.21: 19,7 m; più corto apposta, gravità in salita) |
| Salto da rampa a 25° a 107 km/h | 33,5 m (v0.21: 45,1 m) |
| Inclinazione all'atterraggio | 1,1-3,0° (atterraggio pulito, auto dritta dopo 4 s) |
| Cordolo da 15 cm a 40 e 90 km/h | superato in entrambi i casi |
| Caduta da 8 m | rimbalzo 0,1 m, ferma in 0,2 s, resta dritta |
| Urto frontale contro un muro a 156 km/h | ferma in mezzo secondo |

La stessa prova a frame rate diversi dà risultati quasi identici, quindi la guida non cambia tra
un telefono lento e uno veloce:

| Tick al secondo | 0-100 km/h | Frenata da 144 km/h | Velocità massima | Salto a 25° |
|---|---|---|---|---|
| 30 | 3,60 s | 33,4 m | 212,7 km/h | 33,9 m |
| 60 | 3,55 s | 33,4 m | 212,6 km/h | 33,5 m |
| 120 | 3,52 s | 33,3 m | 212,8 km/h | 33,8 m |

## 4. Avversari, traffico e polizia

- **Avversari** (`car.gd`, `mountain.gd`): seguono la **traiettoria ideale** del circuito e
  frenano prima delle curve leggendo la velocità consigliata. Quando c'è traffico davanti
  calcolano uno spostamento laterale per sorpassarlo dal lato libero, poi tornano sulla linea.
  Dopo un urto perdono aderenza per un attimo (`_knocked`), così uno scontro li scompone davvero.
  Prendono le curve al 92% della velocità consigliata e, se non raggiungono il punto successivo
  del percorso per 8 secondi, vengono rimessi su quel punto.
- **Traffico** (`traffic.gd`): 24 auto civili (12 sul telefono) che sono **corpi rigidi con il peso di un'auto**.
  Mentre guidano, una spinta limitata le tiene in corsia alla loro velocità: un colpo più forte di
  quella spinta le sposta, uno molto forte le fa girare e sbandare sotto gravità. Qualsiasi urto da
  un'auto in gara le ferma per 3 secondi; poi ripartono da sole, aggirando di lato l'auto che le
  blocca, e tornano in corsia. Se sono ribaltate, fuori dalla vista dei piloti tornano in corsia. Livelli di collisione separati evitano che il traffico
  si comporti come una massa infinita (in Jolt le collisioni sono "a senso unico").
- **Polizia** (`main.gd`): chiamata dopo 20 secondi di gara; gli incidenti alzano un livello di
  allerta e più è alto, più volanti compaiono. Ogni volante insegue la prima auto in gara che
  incontra e passa al giocatore quando lui le passa entro 35 m. Arresto se il giocatore resta sotto
  i 5 km/h accanto a una volante per 5 secondi; seminata se resta oltre 110 m per 10 secondi.
- **Pausa** (`main.gd`, `hud.gd`): pulsante MENU, tasto Indietro di Android e gioco in secondo
  piano fermano l'albero della scena (`get_tree().paused`); solo l'interfaccia resta attiva.
- **Tempo a scalare**: per ogni tratto tra due checkpoint il gioco calcola il tempo ideale sulla
  traiettoria ideale e concede `tempo ideale × 1,55 + 4 s`. Un tratto pieno di tornanti dà più
  tempo di un rettilineo, e il tempo avanzato si somma al tratto dopo.
- **Mondo chiuso**: dalla v0.13.1 non ci sono più guardrail; un'auto che resta fuori strada per
  3 secondi, o cade dalla montagna,
  viene rimessa in strada.

## 5. Circuiti scritti come mappe di testo

`scripts/track_layout.gd` · mappe in `tracks/*.txt` · guida per non programmatori in [`tracks/COME_FARE.md`](../tracks/COME_FARE.md)

Stefano voleva circuiti più vari **e poterli disegnare lui senza programmare**. La soluzione è un
piccolo linguaggio in italiano che si legge come un navigatore, un pezzo di strada per riga:

```text
# ROUTE 66 - mappa del circuito "Deserto"
PARTENZA
DRITTO 520            # il lunghissimo rettilineo della Route 66
DESTRA 60 220         # curvone velocissimo
SALITA 4
ESSE SINISTRA 45 70   # dentro il canyon
TORNANTE DESTRA 24    # tornante in fondo al canyon
GOMITO SINISTRA       # entrata in paese
...
```

![Le mappe dei quattro circuiti disegnate da tools/map_preview.gd](immagini/mappe-circuiti.png)

*Montagna (2,8 km), Costa (2,0 km), Città di notte (2,2 km), Deserto (1,7 km), disegnati dalle loro
mappe di testo. Il colore indica l'altitudine, dal giallo (punto più basso) al rosso (più alto); il quadrato bianco è la partenza.*

Dalla mappa al circuito giocabile:

```mermaid
flowchart LR
    A["tracks/deserto.txt"] --> B["TrackLayout<br/>legge i comandi,<br/>chiude l'anello"]
    B --> C["linea centrale<br/>un punto ogni 2 m<br/>+ pendenza"]
    C --> D["strada, banchine,<br/>segnaletica"]
    C --> E["terreno a blocchi<br/>raccordato alla strada"]
    C --> G["traiettoria ideale<br/>+ velocità per tratto"]
    G --> H["IA avversari,<br/>tempo dei checkpoint,<br/>linea colorata a terra"]
```

- **Chiusura automatica dell'anello**: le curve vengono ritoccate perché sommino a un giro
  completo e i rettilinei allungati o accorciati di poco perché la fine incontri la partenza.
  Chi scrive la mappa non deve fare conti.
- **Traiettoria ideale**: una fascia "tirata" dentro la carreggiata con 220 passaggi di
  rilassamento (prima larghi per dare forma alla curva, poi fini per lisciarla), così allarga prima
  della curva, tocca l'interno e riallarga. La velocità lungo la linea viene dal raggio di curvatura
  (`v = √(μ·g·r)`), poi da un passaggio all'indietro con la frenata e uno in avanti con
  l'accelerazione, ripetuti due volte perché il giro si chiuda. Sull'asfalto diventa una linea
  tratteggiata verde (accelera), gialla (molla) o rossa (frena).
- **Controllo della mappa**: `tools/map_preview.gd` disegna la mappa in PNG e misura la distanza
  minima tra tratti di strada diversi (sotto ~33 m si sovrapporrebbero), così un errore si vede
  prima di avviare il gioco.

### Mondi generati (v0.23)

`scripts/baked_world.gd` è un circuito che non costruisce nulla: apre un file già pronto
(`assets/worlds/isola_gara.scn`) con terreno, strade, villaggi, oggetti e collisioni. Il file
contiene anche i dati `terrain_data`, tra cui il percorso e le altezze delle strade: la prima è la
gara. Il gioco non usa il codice degli strumenti che lo hanno creato.

## 6. Grafica: lo stile a fumetto 2.5D (spento dalla v0.13)

`scripts/comic_style.gd` · `shaders/stylize.gdshader` e altri 12 shader

> **Dalla v0.13 (4 novembre 2026) questo stile è spento** (`ComicStyle.ENABLED = false`): sul
> telefono di Stefano il gioco si bloccava al caricamento e lui ha deciso di tornare alla grafica
> realistica, partendo dalle impostazioni di base di Godot. La descrizione qui sotto resta come
> documentazione di come funzionava.

Dopo aver provato uno stile realistico, uno anime e uno a fumetto, Stefano ha scelto il **fumetto
2.5D** (in stile film d'animazione recenti) come unico stile. Il gioco resta 3D, ma viene
"disegnato":

- **Materiali toon**: ogni materiale che entra in scena, anche aggiunto dopo (auto, detriti,
  l'auto del garage), viene convertito in luce a bande con ombre nette.
- **Contorno a inchiostro** sulle auto.
- **Passata a schermo intero** (`stylize.gdshader`): colori appiattiti in bande, linee
  d'inchiostro dove la profondità salta, retino a puntini nelle ombre, tratteggio nelle zone più
  scure, e lastre di colore rosse e blu leggermente sfasate che crescono con la distanza al posto
  della sfocatura (effetto "stampa fuori registro").
- **Cielo pop-art** dipinto da shader, **linee di velocità** ad alta velocità e col nitro.
- **Ambientazioni realistiche disegnate**: alberi, palazzi, palme, motel sono modelli 3D
  realistici (CC BY) che passano dentro lo stile, così il risultato è ricco ma coerente.
- **Città di notte luminosa**: finestre accese da uno shader di facciata, pozze di luce sull'asfalto,
  neon e 8 luci vere che seguono la telecamera (la prima città notturna era stata scartata perché troppo buia).
- **Menu Route 66**: illustrazione originale disegnata in SVG (`tools/art/route66.svg`) e
  trasformata in immagine con Chromium.

## 7. Audio

`scripts/car_audio.gd` · `tools/audio/make_engine_sounds.py`

- **Motore V8 sintetizzato da zero** in Python: 6 registrazioni ad anello a 1.000, 2.000, 3.200,
  4.500, 6.000 e 7.600 giri, ognuna a gas aperto e a gas chiuso. Nessun campione esterno, quindi
  nessun problema di licenza.
- **Miscelazione in tempo reale**: a ogni fotogramma i due anelli più vicini ai giri attuali
  vengono dissolti l'uno nell'altro e intonati ai giri esatti, e le versioni gas aperto/chiuso
  vengono miscelate secondo l'acceleratore. Verificato registrando un video della partita: la
  frequenza degli scoppi segue i giri.
- **Eventi**: cambiata con soffio del turbo, scoppiettii in rilascio, gomme che stridono in frenata
  e in derapata, nitro, vento, urti di tre intensità, tonfo dell'atterraggio, sirena. Le
  registrazioni sono CC0 (Freesound, OpenGameArt), tagliate e normalizzate con uno script.
- Le altre auto sono suoni 3D posizionati e si spengono oltre una certa distanza, per risparmiare
  calcolo sul telefono. Un limitatore sul bus principale evita la distorsione.

## 8. Asset: fonti, licenze e ottimizzazione

- **Budget zero e licenze tracciate**: ogni file in `assets/` è registrato in
  [`assets/LICENSES.md`](../assets/LICENSES.md) con fonte, autore, link, licenza alla data del
  download e modifiche. Le eccezioni non commerciali sono dichiarate in [`CREDITI.md`](../CREDITI.md).
- **Fonti**: Poly Haven (cieli, texture PBR), Kenney, OpenGameArt, Freesound (CC0) e
  Sketchfab (CC BY). Dalla v0.14 tutte le auto sono modelli Sketchfab
  dettagliati; dalla v0.15 solo CC BY (vendibili), con nomi inventati e i loghi separati nascosti
  dal catalogo (`"hide"`).
- **`Scenery`**: ogni modello viene scalato all'altezza reale, appoggiato a terra e **fuso in una
  sola mesh con una superficie per materiale**. Un modello fatto di 123 pezzi passava da oltre
  1.000 chiamate di disegno a una manciata.
- **Texture** dei nuovi paesaggi compresse per la GPU (VRAM) e limitate a 512-1024 px.
- **`Roadside`** (v0.21, `scripts/roadside.gd`): ogni circuito ha un "kit" di modelli d'ambiente
  (`assets/scenery/env/`) con numero di copie, altezza e distanza dalla strada. Le copie sono
  sparse lungo il tracciato dove c'è posto (griglia di occupazione che conosce anche le collisioni
  già presenti), disegnate come MultiMesh raggruppate in quadrati di 128 m, con distanza di
  visibilità proporzionale all'altezza e senza ombre per piante e oggetti piccoli. Prima di entrare
  nel progetto i modelli passano da `gltf-transform` (semplificazione con meshoptimizer, texture
  ridotte e in JPEG). Il palo della luce viene diviso in palo e cavi, e i cavi sono tesi da un palo
  al successivo. `tools/piece_grid.gd` mostra i pezzi di un pacchetto numerati, per sceglierli.
- **Libreria separata**: i modelli scaricati ma non usati restano fuori dall'APK grazie ai filtri
  di esportazione (`export_presets.cfg`), e la libreria completa vive fuori dal repository.

## 9. Prestazioni su telefono

Il bersaglio è un telefono Android di fascia media, e alcune scelte vengono da problemi veri
segnalati da Stefano:

- **Blocco al 69% del caricamento (v0.10)**: risolto costruendo solo il circuito scelto invece di
  tutto, caricando i modelli delle auto **in thread paralleli** mentre si costruisce il livello,
  spegnendo il 3D durante la costruzione e correggendo due cause trovate nel codice: un cielo che
  ricalcolava la mappa dei riflessi a ogni fotogramma e un panorama 2K inutilizzato che finiva nell'APK.
- **Barra di caricamento sempre visibile**, perché il giocatore deve capire se il gioco lavora o è bloccato.
- **Memoria**: tornando al menu i modelli delle auto della gara vengono liberati.
- **Auto pre-cotte (v0.14)**: `tools/bake_cars.gd` prepara ogni auto sul computer di sviluppo
  (girata, scalata, ruote separate in quattro perni, pezzi saldati per materiale, triangoli ridotti
  con il generatore di LOD di Godot fino a circa 45 mila in garage e 18 mila nel traffico, v0.16) e la salva
  in `assets/cars_baked/<id>.res` (`BakedCar`). Il telefono carica solo quel file: la preparazione
  passa da 50-350 ms a circa 10 ms per auto nel banco prova, e i modelli originali restano fuori
  dall'APK. Il menu tiene in memoria l'auto in mostra, la precedente e la successiva, e legge queste ultime in sottofondo.
  Dopo aver cambiato o aggiunto un'auto nel catalogo va rilanciato lo strumento.
- **Auto lontane leggere (v0.16)**: dalla v0.14 anche avversari, polizia e 24 mezzi del traffico
  sono modelli dettagliati, e il telefono è tornato a scattare. Ogni auto pre-cotta ha ora anche una
  copia da circa 4.000 triangoli in un solo pezzo (ruote comprese, per materiale); con le
  `visibility_range` di Godot oltre 25 m si vede quella, senza ombra, mentre l'auto del giocatore resta
  sempre dettagliata. Tetti da vicino: 45 mila triangoli in garage, 30 mila polizia, 18 mila traffico.
- **Terreno a blocchi** (32×32 celle) e alberi disegnati con MultiMesh; guardrail raggruppati in
  pochi corpi fisici, così la rottura di un tratto ricostruisce solo un pezzo piccolo.
- **Profilo telefono (v0.22, `scripts/perf.gd`)**: la v0.21 sul Galaxy A51 scattava molto. Sul
  telefono, o sul PC con `-- --mobile`, il 3D è calcolato al 62% della risoluzione, senza MSAA e
  senza glow. L'ombra del sole è una sola mappa fino a 45 m. La vista arriva a metà distanza con
  nebbia lineare. Decorazioni, alberi ed erba sono la metà e spariscono al 60% della distanza. Il
  traffico è di 12 auto, il faro del giocatore è acceso solo di notte e i lampioni accesi in
  città sono 3 invece di 8 (nel renderer Compatibility ogni luce ridisegna ciò che illumina).
  Nelle stesse inquadrature i triangoli calano del 25-39% e le chiamate di disegno del 21-32%.
- **Misure**: lo strumento di screenshot stampa triangoli e chiamate di disegno per inquadratura,
  per controllare il costo di ogni ambientazione prima della prova sul telefono.

## 10. Prove automatiche e strumenti

| Strumento | A cosa serve |
|---|---|
| `tests/physics_bench.gd` | Banco prova della fisica (tabella sopra), risultati in JSON |
| `--autotest` | L'auto del giocatore corre da sola l'intera gara con seme fisso e stampa un registro; con `--shots=` salva screenshot |
| `tools/map_preview.gd` | Disegna le mappe e controlla le distanze minime |
| `tools/shot.gd` | Screenshot di un circuito da punti scelti, con statistiche di rendering |
| `tools/pack_sheet.gd`, `inspect_glb.gd` | Mostrano i pezzi dentro un pacchetto di modelli |
| `tools/air_test.gd` | Prove del comportamento in volo |

Ogni versione è stata controllata con questi strumenti prima di essere consegnata, e poi provata
da Stefano sul telefono: le sue impressioni sono la base della versione successiva.

## 11. Build e distribuzione delle versioni di prova

- **APK Android** costruiti in un container cloud senza Android SDK ufficiale: Godot esporta
  l'APK con i template ufficiali e la firma viene fatta da un piccolo firmatario Java basato su
  `apksig`. Solo arm64, per tenere l'APK sotto i ~310 MB nonostante i modelli dettagliati.
- **Prova su PC senza installare niente**: `tools/windows/Gioca-Nitro.bat` scarica Godot e
  l'ultima build dal ramo `prova-pc`, la importa e la avvia; riscarica solo quando il ramo cambia.
  È nato perché spostare ogni volta un APK di 300 MB sul telefono era la parte più scomoda delle prove.
- **Pull request per ogni versione**, con descrizione in italiano di cosa cambia e come è stato verificato.
